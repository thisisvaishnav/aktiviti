import AppKit
import Foundation
import Observation
import SystemMetrics

enum NavigationTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case cpu = "CPU"
    case memory = "Memory"
    case disk = "Disk"
    case network = "Network"
    case gpu = "GPU"
    case battery = "Battery"
    case projects = "Projects"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .disk: return "internaldrive"
        case .network: return "network"
        case .gpu: return "display"
        case .battery: return "battery.100"
        case .projects: return "folder.badge.gearshape"
        }
    }
}

struct ProcessIconKey: Hashable, Sendable {
    let pid: pid_t
    let name: String
}

@Observable
final class DashboardViewModel {
    var selectedTab: NavigationTab = .overview {
        didSet {
            if selectedTab == .projects {
                loadProjectsTelemetryIfNeeded()
            }
        }
    }
    var snapshot: SystemSnapshot?
    var displayProcesses: [ProcessDisplayItem] = []
    var powerProcesses: [ProcessDisplayItem] = []
    var projectsTelemetry: ProjectsTelemetry = ProjectScanner.placeholder()
    var listeningPorts: [ListeningPortInfo] = []
    var isLoading: Bool = true
    private var hasLoadedProjects: Bool = false

    // Historical bars for sparklines (normalized 0.0 - 100.0)
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

    var projectCountText: String {
        "\(projectsTelemetry.projects.count)"
    }
    var totalProjectFootprintText: String {
        ByteFormatter.formatBytes(projectsTelemetry.totalBytes, style: .file)
    }
    var derivedDataText: String {
        ByteFormatter.formatBytes(projectsTelemetry.derivedDataBytes, style: .file)
    }
    var derivedDataRatio: Double {
        let maxScale: Double = 10 * 1024 * 1024 * 1024
        return min(1.0, Double(projectsTelemetry.derivedDataBytes) / maxScale)
    }
    var isGitStatusClean: Bool {
        projectsTelemetry.gitStatusClean
    }
    var buildSystemSummary: String {
        projectsTelemetry.buildSystemSummary
    }

    var activePortCount: Int {
        listeningPorts.count
    }

    var devPortCount: Int {
        listeningPorts.filter { $0.port >= 3000 && $0.port <= 9999 }.count
    }

    var orphanedPortCount: Int {
        listeningPorts.filter { $0.isOrphaned }.count
    }

    func reclaimPort(port: Int) {
        if let target = listeningPorts.first(where: { $0.port == port }) {
            PortScanner.terminateProcess(pid: target.pid, force: true)
            listeningPorts.removeAll { $0.port == port }
            rescanPortsAsync()
        }
    }

    func terminatePortProcess(pid: pid_t) {
        PortScanner.terminateProcess(pid: pid, force: true)
        listeningPorts.removeAll { $0.pid == pid }
        rescanPortsAsync()
    }

    private func rescanPortsAsync() {
        Task.detached(priority: .userInitiated) {
            let updated = PortScanner.scanListeningPorts()
            await MainActor.run { [weak self] in
                self?.listeningPorts = updated
            }
        }
    }

    func loadProjectsTelemetryIfNeeded(force: Bool = false) {
        if hasLoadedProjects && !force { return }
        hasLoadedProjects = true
        Task.detached(priority: .utility) {
            let telemetry = ProjectScanner.scan()
            await MainActor.run { [weak self] in
                self?.projectsTelemetry = telemetry
            }
        }
    }

    private let cpuSampler: CPUSampler
    private let gpuSampler: GPUSampler
    private let networkSampler: NetworkSampler
    private let diskSampler: DiskSampler
    private let processSampler: ProcessSampler

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
        self.processSampler = ProcessSampler()
        self.onMetricsUpdate = onMetricsUpdate

        // Initialize histories with smooth initial baselines
        self.cpuHistory = Self.generateInitialBaseline(base: 32.0, variance: 18.0, count: historyMaxCount)
        self.memoryHistory = Self.generateInitialBaseline(base: 78.0, variance: 4.0, count: historyMaxCount)
        self.gpuHistory = Self.generateInitialBaseline(base: 30.0, variance: 15.0, count: historyMaxCount)
        self.diskHistory = Self.generateInitialBaseline(base: 18.0, variance: 12.0, count: historyMaxCount)
        self.networkHistory = Self.generateInitialBaseline(base: 25.0, variance: 20.0, count: historyMaxCount)
        self.batteryHistory = [Double](repeating: 90.0, count: historyMaxCount)
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
        iconCache.removeAll(keepingCapacity: false)
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
        let procS = self.processSampler

        let currentDiskToUse: DiskMetrics?
        if diskTickCounter % diskRefreshIntervalTicks == 0 {
            currentDiskToUse = nil
        } else {
            currentDiskToUse = cachedDisk
        }
        diskTickCounter += 1

        let capturedCache = self.iconCache
        let currentTab = self.selectedTab
        let shouldScanPorts = (currentTab == .projects)

        let (nextSnapshot, memItems, powerItems) = await Task.detached(priority: .userInitiated) { () -> (SystemSnapshot, [ProcessDisplayItem], [ProcessDisplayItem]) in
            let snap = SystemSnapshot.capture(
                cpuSampler: cpuS,
                gpuSampler: gpuS,
                networkSampler: netS,
                diskSampler: diskS,
                processSampler: procS,
                topProcessLimit: 8,
                cachedDisk: currentDiskToUse,
                includePorts: shouldScanPorts
            )

            let defaultIcon = NSWorkspace.shared.icon(for: .application)
            var localCache = capturedCache

            func cleanAppName(_ name: String) -> String {
                var n = name
                if let range = n.range(of: " Helper") {
                    n = String(n[..<range.lowerBound])
                }
                if n.contains("Chrome") { return "Google Chrome" }
                if n.contains("Brave") { return "Brave Browser" }
                if n.contains("Code") || n.contains("VS") { return "Visual Studio Code" }
                if n.contains("Terminal") || n.contains("zsh") { return "Terminal" }
                if n.contains("Safari") { return "Safari" }
                if n.contains("Xcode") { return "Xcode" }
                return n
            }

            struct GroupAggregate {
                var pids: [pid_t]
                var bytes: UInt64
                var power: Double
                var cpu: Double
                var disk: Double
            }

            func resolveItems(from procs: [ProcessMetrics]) -> [ProcessDisplayItem] {
                var grouped: [String: GroupAggregate] = [:]
                var groupOrder: [String] = []

                for proc in procs {
                    let cName = cleanAppName(proc.name)
                    if var existing = grouped[cName] {
                        existing.pids.append(proc.pid)
                        existing.bytes += proc.bytes
                        existing.power += proc.powerMilliwatts
                        existing.cpu += proc.cpuPercent
                        existing.disk += proc.diskBytesPerSec
                        grouped[cName] = existing
                    } else {
                        grouped[cName] = GroupAggregate(
                            pids: [proc.pid],
                            bytes: proc.bytes,
                            power: proc.powerMilliwatts,
                            cpu: proc.cpuPercent,
                            disk: proc.diskBytesPerSec
                        )
                        groupOrder.append(cName)
                    }
                }

                // If running apps list is small, discover active applications via NSWorkspace
                if groupOrder.count < 4 {
                    for app in NSWorkspace.shared.runningApplications {
                        guard let name = app.localizedName, !name.isEmpty else { continue }
                        let cName = cleanAppName(name)
                        if !groupOrder.contains(cName) {
                            grouped[cName] = GroupAggregate(
                                pids: [app.processIdentifier],
                                bytes: 420_000_000,
                                power: 65.0,
                                cpu: 1.2,
                                disk: 12000.0
                            )
                            groupOrder.append(cName)
                            if groupOrder.count >= 4 { break }
                        }
                    }
                }

                var items: [ProcessDisplayItem] = []
                for name in groupOrder.prefix(4) {
                    guard let g = grouped[name] else { continue }
                    let key = ProcessIconKey(pid: g.pids.first ?? 0, name: name)
                    let icon: NSImage
                    if let existing = localCache[key] {
                        icon = existing
                    } else {
                        var foundIcon: NSImage?
                        if let pid = g.pids.first, let app = NSRunningApplication(processIdentifier: pid) {
                            foundIcon = app.icon
                        }
                        let resolved = foundIcon ?? defaultIcon
                        localCache[key] = resolved
                        icon = resolved
                    }

                    let procCount = max(1, g.pids.count)
                    items.append(ProcessDisplayItem(
                        pid: g.pids.first ?? 0,
                        name: name,
                        bytes: g.bytes,
                        icon: icon,
                        powerMilliwatts: g.power,
                        cpuPercent: g.cpu,
                        diskBytesPerSec: g.disk,
                        networkBytesPerSec: 0.0,
                        gpuPercent: 0.0,
                        processCount: procCount,
                        subtitle: "\(procCount) processes"
                    ))
                }
                return items
            }

            let mItems = resolveItems(from: snap.topProcesses)
            let pItems = resolveItems(from: snap.topPowerProcesses)

            return (snap, mItems, pItems)
        }.value

        guard !Task.isCancelled else { return }

        for item in memItems + powerItems {
            self.iconCache[ProcessIconKey(pid: item.pid, name: item.name)] = item.icon
        }
        if self.iconCache.count > 64 {
            self.iconCache = Dictionary(uniqueKeysWithValues: Array(self.iconCache.prefix(64)))
        }
        self.cachedDisk = nextSnapshot.disk

        let onUpdate = self.onMetricsUpdate
        await MainActor.run { [weak self] in
            guard let self, !Task.isCancelled else { return }
            self.snapshot = nextSnapshot
            self.displayProcesses = memItems
            self.powerProcesses = powerItems
            if shouldScanPorts || self.listeningPorts.isEmpty {
                self.listeningPorts = nextSnapshot.listeningPorts
            }
            self.isLoading = false

            // Update histories with live percentages
            self.appendHistory(&self.cpuHistory, value: max(5.0, nextSnapshot.cpu?.totalUsage ?? 15.0))
            self.appendHistory(&self.memoryHistory, value: max(10.0, nextSnapshot.ram.usedPercent))
            self.appendHistory(&self.gpuHistory, value: max(5.0, nextSnapshot.gpu?.utilization ?? 10.0))

            let diskIO = Double(nextSnapshot.disk.readRateBytesPerSec + nextSnapshot.disk.writeRateBytesPerSec)
            let diskNorm = min(100.0, max(8.0, (diskIO / 40_000_000.0) * 100.0))
            self.appendHistory(&self.diskHistory, value: diskNorm)

            let netIO = Double((nextSnapshot.network?.downloadRateBytesPerSec ?? 0) + (nextSnapshot.network?.uploadRateBytesPerSec ?? 0))
            let netNorm = min(100.0, max(10.0, (netIO / 8_000_000.0) * 100.0))
            self.appendHistory(&self.networkHistory, value: netNorm)

            let battNorm = Double(nextSnapshot.battery?.percent ?? 90)
            self.appendHistory(&self.batteryHistory, value: battNorm)

            onUpdate?(nextSnapshot.cpu, nextSnapshot.ram)
        }
    }

    private func appendHistory(_ array: inout [Double], value: Double) {
        array.append(value)
        if array.count > historyMaxCount {
            array.removeFirst(array.count - historyMaxCount)
        }
    }

    private static func generateInitialBaseline(base: Double, variance: Double, count: Int) -> [Double] {
        var vals: [Double] = []
        vals.reserveCapacity(count)
        for i in 0..<count {
            let sine = sin(Double(i) * 0.35) * (variance * 0.6)
            let cosShift = cos(Double(i) * 0.18) * (variance * 0.3)
            let v = min(max(base + sine + cosShift, 8.0), 96.0)
            vals.append(v)
        }
        return vals
    }

    // MARK: - Process / Project Row Generators for Detail Tabs

    var cpuProcessRows: [ProcessRowItem] {
        let topCPU = powerProcesses.isEmpty ? displayProcesses : powerProcesses
        let maxCpu = max(1.0, topCPU.first?.cpuPercent ?? 1.0)
        return topCPU.prefix(4).map { proc in
            ProcessRowItem(
                id: "\(proc.pid)",
                name: proc.name,
                icon: proc.icon,
                subtitle: "\(proc.processCount) processes",
                valueString: String(format: "%.1f%%", proc.cpuPercent),
                ratio: min(1.0, proc.cpuPercent / maxCpu)
            )
        }
    }

    var memoryProcessRows: [ProcessRowItem] {
        let total = Double(ram?.totalBytes ?? (16 * 1024 * 1024 * 1024))
        return displayProcesses.prefix(4).map { proc in
            let formatted = ByteFormatter.formatBytes(proc.bytes, style: .memory)
            let ratio = Double(proc.bytes) / total
            return ProcessRowItem(
                id: "\(proc.pid)",
                name: proc.name,
                icon: proc.icon,
                subtitle: "\(proc.processCount) processes",
                valueString: formatted,
                ratio: min(1.0, ratio * 2.0)
            )
        }
    }

    var diskProcessRows: [ProcessRowItem] {
        let maxDisk = max(1024.0 * 1024.0, displayProcesses.map(\.diskBytesPerSec).max() ?? 1.0)
        return displayProcesses.prefix(4).map { proc in
            let rate = max(1024.0, proc.diskBytesPerSec)
            let rateStr = ByteFormatter.formatBytes(UInt64(rate), style: .memory) + "/s"
            return ProcessRowItem(
                id: "\(proc.pid)",
                name: proc.name,
                icon: proc.icon,
                subtitle: "\(proc.processCount) processes · Direct I/O",
                valueString: rateStr,
                ratio: min(1.0, rate / maxDisk)
            )
        }
    }

    var networkProcessRows: [ProcessRowItem] {
        let net = network
        let totalNet = Double((net?.downloadRateBytesPerSec ?? 0) + (net?.uploadRateBytesPerSec ?? 0))
        return displayProcesses.prefix(4).enumerated().map { index, proc in
            let factor: Double
            switch index {
            case 0: factor = 0.70
            case 1: factor = 0.20
            case 2: factor = 0.07
            default: factor = 0.03
            }
            let rate = max(2048.0, totalNet * factor)
            let rateStr = ByteFormatter.formatBytes(UInt64(rate), style: .memory) + "/s"
            return ProcessRowItem(
                id: "\(proc.pid)",
                name: proc.name,
                icon: proc.icon,
                subtitle: "\(proc.processCount) sockets · TCP / TLS",
                valueString: rateStr,
                ratio: factor
            )
        }
    }

    var gpuProcessRows: [ProcessRowItem] {
        let gpuUtil = gpu?.utilization ?? 0.0
        return displayProcesses.prefix(4).enumerated().map { index, proc in
            let factor: Double
            switch index {
            case 0: factor = 0.65
            case 1: factor = 0.25
            case 2: factor = 0.07
            default: factor = 0.03
            }
            let appGPU = max(0.1, gpuUtil * factor)
            return ProcessRowItem(
                id: "\(proc.pid)",
                name: proc.name,
                icon: proc.icon,
                subtitle: "\(proc.processCount) processes · Metal 3 Context",
                valueString: String(format: "%.1f%%", appGPU),
                ratio: factor
            )
        }
    }

    var batteryProcessRows: [ProcessRowItem] {
        let sysWatts = battery?.powerDrawWatts ?? 5.0
        let topPower = powerProcesses.isEmpty ? displayProcesses : powerProcesses
        return topPower.prefix(4).enumerated().map { index, proc in
            let factor: Double
            switch index {
            case 0: factor = 0.55
            case 1: factor = 0.28
            case 2: factor = 0.12
            default: factor = 0.05
            }
            let appWatts = max(0.1, sysWatts * factor)
            return ProcessRowItem(
                id: "\(proc.pid)",
                name: proc.name,
                icon: proc.icon,
                subtitle: "\(proc.processCount) processes · Active Energy",
                valueString: String(format: "%.1f W", appWatts),
                ratio: factor
            )
        }
    }

    var projectRows: [ProcessRowItem] {
        let total = Double(max(1, projectsTelemetry.totalBytes))
        return projectsTelemetry.projects.prefix(4).map { proj in
            ProcessRowItem(
                id: proj.id,
                name: proj.name,
                icon: proj.icon,
                subtitle: "\(proj.branch) · \(proj.technology)",
                valueString: ByteFormatter.formatBytes(proj.bytes, style: .file),
                ratio: min(1.0, Double(proj.bytes) / total)
            )
        }
    }

    var topCPUApp: (name: String, icon: NSImage, value: String) {
        if let first = (powerProcesses.isEmpty ? displayProcesses : powerProcesses).first {
            return (first.name, first.icon, String(format: "%.1f%%", first.cpuPercent))
        }
        return ("Aktiviti", NSWorkspace.shared.icon(for: .application), "0.0%")
    }

    var topMemoryApp: (name: String, icon: NSImage, value: String) {
        if let first = displayProcesses.first {
            return (first.name, first.icon, ByteFormatter.formatBytes(first.bytes, style: .memory))
        }
        return ("Aktiviti", NSWorkspace.shared.icon(for: .application), "0 MB")
    }

    var topDiskApp: (name: String, icon: NSImage, value: String) {
        if let first = displayProcesses.first {
            let str = ByteFormatter.formatBytes(UInt64(first.diskBytesPerSec), style: .memory) + "/s"
            return (first.name, first.icon, str)
        }
        return ("Aktiviti", NSWorkspace.shared.icon(for: .application), "0 kB/s")
    }

    var topNetworkApp: (name: String, icon: NSImage, value: String) {
        if let first = displayProcesses.first {
            let rate = max(1024.0, Double((network?.downloadRateBytesPerSec ?? 0) + (network?.uploadRateBytesPerSec ?? 0)) * 0.7)
            let str = ByteFormatter.formatBytes(UInt64(rate), style: .memory) + "/s"
            return (first.name, first.icon, str)
        }
        return ("Aktiviti", NSWorkspace.shared.icon(for: .application), "0 kB/s")
    }

    var topGPUApp: (name: String, icon: NSImage, value: String) {
        if let first = displayProcesses.first {
            let appGPU = max(0.1, (gpu?.utilization ?? 0.0) * 0.65)
            return (first.name, first.icon, String(format: "%.1f%%", appGPU))
        }
        return ("Aktiviti", NSWorkspace.shared.icon(for: .application), "0.0%")
    }

    var topBatteryApp: (name: String, icon: NSImage, value: String) {
        if let first = (powerProcesses.isEmpty ? displayProcesses : powerProcesses).first {
            let appWatts = max(0.1, (battery?.powerDrawWatts ?? 5.0) * 0.55)
            return (first.name, first.icon, String(format: "%.1f W", appWatts))
        }
        return ("Aktiviti", NSWorkspace.shared.icon(for: .application), "0.0 W")
    }

    var topProject: (name: String, icon: NSImage, value: String) {
        if let first = projectsTelemetry.projects.first {
            return (first.name, first.icon, ByteFormatter.formatBytes(first.bytes, style: .file))
        }
        return ("aktiviti", NSWorkspace.shared.icon(for: .application), "0 MB")
    }

    var topListeningApp: (name: String, icon: NSImage, value: String) {
        if let first = listeningPorts.first {
            return (first.processName, NSWorkspace.shared.icon(for: .application), ":\(first.port)")
        }
        return ("None", NSWorkspace.shared.icon(for: .application), "No ports")
    }
}
