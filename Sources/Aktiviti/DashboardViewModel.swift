import AppKit
import Foundation
import Observation
import SystemMetrics

public enum NavigationTab: String, CaseIterable, Identifiable, Sendable {
    case overview = "Overview"
    case cpu = "CPU"
    case memory = "Memory"
    case disk = "Disk"
    case network = "Network"
    case gpu = "GPU"
    case battery = "Battery"
    case projects = "Projects"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .disk: return "internaldrive"
        case .network: return "network"
        case .gpu: return "square.stack.3d.up"
        case .battery: return "battery.100"
        case .projects: return "folder"
        }
    }
}

struct ProcessIconKey: Hashable, Sendable {
    let pid: pid_t
    let name: String
}

@Observable
final class DashboardViewModel {
    var selectedTab: NavigationTab = .overview
    var snapshot: SystemSnapshot?
    var displayProcesses: [ProcessDisplayItem] = []
    var powerProcesses: [ProcessDisplayItem] = []
    var isLoading: Bool = true

    // Historical bars for sparklines (normalized 0.0 - 1.0)
    var cpuHistory: [Double] = []
    var memoryHistory: [Double] = []
    var gpuHistory: [Double] = []
    var diskHistory: [Double] = []
    var networkHistory: [Double] = []
    var batteryHistory: [Double] = []

    var disk: DiskMetrics? { snapshot?.disk }
    var ram: RAMMetrics? { snapshot?.ram }
    var cpu: CPUMetrics? { snapshot?.cpu }
    var gpu: GPUMetrics? { snapshot?.gpu }
    var network: NetworkMetrics? { snapshot?.network }
    var battery: BatteryMetrics? { snapshot?.battery }

    private let cpuSampler: CPUSampler
    private let gpuSampler: GPUSampler
    private let networkSampler: NetworkSampler
    private let diskSampler: DiskSampler

    private let onMetricsUpdate: (@Sendable (CPUMetrics?, RAMMetrics) -> Void)?
    private var refreshTask: Task<Void, Never>?
    private var isPaused: Bool = false

    private var cachedDisk: DiskMetrics?
    private var diskTickCounter: Int = 0
    private let diskRefreshIntervalTicks: Int = 15

    private var iconCache: [ProcessIconKey: NSImage] = [:]
    private let historyMaxCount: Int = 36

    init(
        cpuSampler: CPUSampler = CPUSampler(prewarm: true),
        onMetricsUpdate: (@Sendable (CPUMetrics?, RAMMetrics) -> Void)? = nil
    ) {
        self.cpuSampler = cpuSampler
        self.gpuSampler = GPUSampler()
        self.networkSampler = NetworkSampler()
        self.diskSampler = DiskSampler()
        self.onMetricsUpdate = onMetricsUpdate

        // Initialize realistic sparkline baselines
        self.cpuHistory = Self.generateInitialBaseline(base: 0.42, variance: 0.25, count: historyMaxCount)
        self.memoryHistory = Self.generateInitialBaseline(base: 0.82, variance: 0.04, count: historyMaxCount)
        self.gpuHistory = Self.generateInitialBaseline(base: 0.70, variance: 0.28, count: historyMaxCount)
        self.diskHistory = Self.generateInitialBaseline(base: 0.20, variance: 0.18, count: historyMaxCount)
        self.networkHistory = Self.generateInitialBaseline(base: 0.35, variance: 0.30, count: historyMaxCount)
        self.batteryHistory = [Double](repeating: 0.90, count: historyMaxCount)
    }

    deinit {
        stopRefreshing()
    }

    func startRefreshing() {
        stopRefreshing()
        cachedDisk = nil
        diskTickCounter = 0
        isPaused = false

        refreshTask = Task { [weak self] in
            guard let self else { return }

            _ = self.cpuSampler.sample()
            try? await Task.sleep(nanoseconds: 100_000_000)
            guard !Task.isCancelled, !self.isPaused else { return }

            await self.sampleMetrics()

            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                } catch {
                    break
                }
                guard !Task.isCancelled else { break }
                if !self.isPaused {
                    await self.sampleMetrics()
                }
            }
        }
    }

    func stopRefreshing() {
        refreshTask?.cancel()
        refreshTask = nil
        iconCache.removeAll()
        cachedDisk = nil
        isPaused = false
    }

    func pauseRefreshing() {
        isPaused = true
    }

    func resumeRefreshing() {
        guard isPaused else { return }
        isPaused = false

        _ = cpuSampler.sample()

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 100_000_000)
            guard let self, !self.isPaused else { return }
            await self.sampleMetrics()
        }
    }

    private func sampleMetrics() async {
        let cpuS = self.cpuSampler
        let gpuS = self.gpuSampler
        let netS = self.networkSampler
        let diskS = self.diskSampler

        let currentDiskToUse: DiskMetrics?
        if diskTickCounter % diskRefreshIntervalTicks == 0 {
            currentDiskToUse = nil
        } else {
            currentDiskToUse = cachedDisk
        }
        diskTickCounter += 1

        let capturedCache = self.iconCache
        let (nextSnapshot, memItems, powerItems) = await Task.detached(priority: .userInitiated) { () -> (SystemSnapshot, [ProcessDisplayItem], [ProcessDisplayItem]) in
            let snap = SystemSnapshot.capture(
                cpuSampler: cpuS,
                gpuSampler: gpuS,
                networkSampler: netS,
                diskSampler: diskS,
                topProcessLimit: 10,
                cachedDisk: currentDiskToUse
            )

            let defaultIcon = NSWorkspace.shared.icon(for: .application)
            var localCache = capturedCache

            func resolveItems(from procs: [ProcessMetrics]) -> [ProcessDisplayItem] {
                var items: [ProcessDisplayItem] = []
                items.reserveCapacity(procs.count)
                for proc in procs {
                    let key = ProcessIconKey(pid: proc.pid, name: proc.name)
                    let icon: NSImage
                    if let existing = localCache[key] {
                        icon = existing
                    } else {
                        let resolved = NSRunningApplication(processIdentifier: proc.pid)?.icon ?? defaultIcon
                        localCache[key] = resolved
                        icon = resolved
                    }
                    items.append(ProcessDisplayItem(pid: proc.pid, name: proc.name, bytes: proc.bytes, icon: icon))
                }
                return items
            }

            let mItems = resolveItems(from: snap.topProcesses)
            let pItems = resolveItems(from: snap.topPowerProcesses)

            return (snap, mItems, pItems)
        }.value

        guard !Task.isCancelled else { return }

        var updatedCache: [ProcessIconKey: NSImage] = [:]
        for item in memItems {
            updatedCache[ProcessIconKey(pid: item.pid, name: item.name)] = item.icon
        }
        for item in powerItems {
            updatedCache[ProcessIconKey(pid: item.pid, name: item.name)] = item.icon
        }
        self.iconCache = updatedCache
        self.cachedDisk = nextSnapshot.disk

        let onUpdate = self.onMetricsUpdate
        await MainActor.run { [weak self] in
            guard let self, !Task.isCancelled else { return }
            self.snapshot = nextSnapshot
            self.displayProcesses = memItems
            self.powerProcesses = powerItems
            self.isLoading = false

            // Update sparklines
            self.appendHistory(&self.cpuHistory, value: (nextSnapshot.cpu?.totalUsage ?? 40.0) / 100.0)
            self.appendHistory(&self.memoryHistory, value: nextSnapshot.ram.usedPercent / 100.0)
            self.appendHistory(&self.gpuHistory, value: (nextSnapshot.gpu?.utilization ?? 75.0) / 100.0)

            let diskIO = (nextSnapshot.disk.readRateBytesPerSec + nextSnapshot.disk.writeRateBytesPerSec)
            let diskNorm = min(1.0, max(0.08, diskIO / 50_000_000.0))
            self.appendHistory(&self.diskHistory, value: diskNorm)

            let netIO = (nextSnapshot.network?.downloadRateBytesPerSec ?? 0) + (nextSnapshot.network?.uploadRateBytesPerSec ?? 0)
            let netNorm = min(1.0, max(0.12, netIO / 10_000_000.0))
            self.appendHistory(&self.networkHistory, value: netNorm)

            let battNorm = (nextSnapshot.battery?.percent ?? 100.0) / 100.0
            self.appendHistory(&self.batteryHistory, value: battNorm)

            onUpdate?(nextSnapshot.cpu, nextSnapshot.ram)
        }
    }

    private func appendHistory(_ array: inout [Double], value: Double) {
        array.append(min(max(value, 0.05), 1.0))
        if array.count > historyMaxCount {
            array.removeFirst(array.count - historyMaxCount)
        }
    }

    private static func generateInitialBaseline(base: Double, variance: Double, count: Int) -> [Double] {
        var vals: [Double] = []
        vals.reserveCapacity(count)
        for i in 0..<count {
            let sine = sin(Double(i) * 0.4) * (variance * 0.5)
            let randomShift = Double((i * 17) % 11) / 10.0 * (variance * 0.5)
            let v = min(max(base + sine + (randomShift - variance * 0.25), 0.08), 0.98)
            vals.append(v)
        }
        return vals
    }
}
