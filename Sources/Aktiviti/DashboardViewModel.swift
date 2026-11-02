import Foundation
import Observation
import SystemMetrics

@Observable
final class DashboardViewModel {
    var snapshot: SystemSnapshot?
    var isLoading: Bool = true

    var disk: DiskMetrics? { snapshot?.disk }
    var ram: RAMMetrics? { snapshot?.ram }
    var cpu: CPUMetrics? { snapshot?.cpu }
    var topProcesses: [ProcessMetrics] { snapshot?.topProcesses ?? [] }

    private let cpuSampler: CPUSampler
    private var refreshTask: Task<Void, Never>?

    init() {
        self.cpuSampler = CPUSampler(prewarm: true)
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
                await self.sampleMetrics()
            }
        }
    }

    func stopRefreshing() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func sampleMetrics() async {
        let sampler = self.cpuSampler
        let nextSnapshot = await Task.detached(priority: .userInitiated) {
            SystemSnapshot.capture(cpuSampler: sampler, topProcessLimit: 10)
        }.value

        guard !Task.isCancelled else { return }

        await MainActor.run { [weak self] in
            guard let self, !Task.isCancelled else { return }
            self.snapshot = nextSnapshot
            self.isLoading = false
        }
    }
}
