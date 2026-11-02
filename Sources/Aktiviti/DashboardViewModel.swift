import AppKit
import Foundation
import Observation
import SystemMetrics

@Observable
final class DashboardViewModel {
    var snapshot: SystemSnapshot?
    var displayProcesses: [ProcessDisplayItem] = []
    var isLoading: Bool = true

    var disk: DiskMetrics? { snapshot?.disk }
    var ram: RAMMetrics? { snapshot?.ram }
    var cpu: CPUMetrics? { snapshot?.cpu }
    var topProcesses: [ProcessMetrics] { snapshot?.topProcesses ?? [] }

    private let cpuSampler: CPUSampler
    private let onMetricsUpdate: (@Sendable (CPUMetrics?, RAMMetrics) -> Void)?
    private var refreshTask: Task<Void, Never>?
    private var isPaused: Bool = false

    // Optimization 2: Decoupled Disk Sampling (every 30 seconds / 15 cycles)
    private var cachedDisk: DiskMetrics?
    private var diskTickCounter: Int = 0
    private let diskRefreshIntervalTicks: Int = 15

    // Optimization 3: In-Memory Icon Cache
    private var iconCache: [pid_t: NSImage] = [:]

    init(
        cpuSampler: CPUSampler = CPUSampler(prewarm: true),
        onMetricsUpdate: (@Sendable (CPUMetrics?, RAMMetrics) -> Void)? = nil
    ) {
        self.cpuSampler = cpuSampler
        self.onMetricsUpdate = onMetricsUpdate
    }

    deinit {
        stopRefreshing()
    }

    func startRefreshing() {
        stopRefreshing()
        refreshTask = Task { [weak self] in
            // Small initial pause to gather initial CPU tick delta
            try? await Task.sleep(nanoseconds: 100_000_000)
            guard !Task.isCancelled, let self else { return }

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
    }

    func pauseRefreshing() {
        isPaused = true
    }

    func resumeRefreshing() {
        guard isPaused else { return }
        isPaused = false
        Task { [weak self] in
            await self?.sampleMetrics()
        }
    }

    private func sampleMetrics() async {
        let sampler = self.cpuSampler

        // Optimization 2: Re-query disk only on initial load or every 15 cycles (30s)
        let currentDiskToUse: DiskMetrics?
        if diskTickCounter % diskRefreshIntervalTicks == 0 {
            currentDiskToUse = nil // Trigger fresh read in SystemSnapshot.capture
        } else {
            currentDiskToUse = cachedDisk
        }
        diskTickCounter += 1

        let capturedCache = self.iconCache
        let (nextSnapshot, displayItems) = await Task.detached(priority: .userInitiated) { () -> (SystemSnapshot, [ProcessDisplayItem]) in
            let snap = SystemSnapshot.capture(
                cpuSampler: sampler,
                topProcessLimit: 10,
                cachedDisk: currentDiskToUse
            )

            let defaultIcon = NSWorkspace.shared.icon(for: .application)
            var localCache = capturedCache
            var items: [ProcessDisplayItem] = []
            items.reserveCapacity(snap.topProcesses.count)

            for proc in snap.topProcesses {
                let icon: NSImage
                if let existing = localCache[proc.pid] {
                    icon = existing
                } else {
                    let resolved = NSRunningApplication(processIdentifier: proc.pid)?.icon ?? defaultIcon
                    localCache[proc.pid] = resolved
                    icon = resolved
                }
                items.append(ProcessDisplayItem(pid: proc.pid, name: proc.name, bytes: proc.bytes, icon: icon))
            }

            return (snap, items)
        }.value

        guard !Task.isCancelled else { return }

        // Update local icon cache with currently active items to prevent unbounded growth
        var updatedCache: [pid_t: NSImage] = [:]
        for item in displayItems {
            updatedCache[item.pid] = item.icon
        }
        self.iconCache = updatedCache
        self.cachedDisk = nextSnapshot.disk

        let onUpdate = self.onMetricsUpdate
        await MainActor.run { [weak self] in
            guard let self, !Task.isCancelled else { return }
            self.snapshot = nextSnapshot
            self.displayProcesses = displayItems
            self.isLoading = false
            onUpdate?(nextSnapshot.cpu, nextSnapshot.ram)
        }
    }
}
