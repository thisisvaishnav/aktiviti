import Foundation

/// A unified, sendable snapshot of system metrics.
public struct SystemSnapshot: Sendable, Equatable {
    /// CPU usage metrics if available (requires tick delta or previous sample).
    public let cpu: CPUMetrics?

    /// Memory / RAM metrics.
    public let ram: RAMMetrics

    /// Disk space metrics for "/".
    public let disk: DiskMetrics

    /// Top memory-consuming processes sorted descending by physical footprint.
    public let topProcesses: [ProcessMetrics]

    public init(
        cpu: CPUMetrics?,
        ram: RAMMetrics,
        disk: DiskMetrics,
        topProcesses: [ProcessMetrics]
    ) {
        self.cpu = cpu
        self.ram = ram
        self.disk = disk
        self.topProcesses = topProcesses
    }

    /// Captures a one-shot snapshot of system metrics.
    /// - Parameters:
    ///   - cpuSampler: Optional CPUSampler instance to read CPU tick deltas.
    ///   - topProcessLimit: Maximum number of top memory processes to return (default: 10).
    ///   - cachedDisk: Optional pre-existing DiskMetrics to avoid redundant disk I/O when polling frequently.
    public static func capture(
        cpuSampler: CPUSampler? = nil,
        topProcessLimit: Int = 10,
        cachedDisk: DiskMetrics? = nil
    ) -> SystemSnapshot {
        let cpu = cpuSampler?.sample()
        let ram = RAMReader.read()
        let disk = cachedDisk ?? DiskReader.read()
        let processes = ProcessReader.readTopProcesses(limit: topProcessLimit)

        return SystemSnapshot(
            cpu: cpu,
            ram: ram,
            disk: disk,
            topProcesses: processes
        )
    }

    /// Captures a one-shot snapshot, taking an active CPU measurement over the given duration.
    /// - Parameters:
    ///   - samplingInterval: Duration in seconds to measure CPU activity (e.g. 1.0).
    ///   - topProcessLimit: Maximum number of top memory processes to return (default: 10).
    ///   - cachedDisk: Optional pre-existing DiskMetrics to avoid redundant disk I/O when polling frequently.
    public static func capture(
        samplingCPUFor samplingInterval: TimeInterval,
        topProcessLimit: Int = 10,
        cachedDisk: DiskMetrics? = nil
    ) -> SystemSnapshot {
        let sampler = CPUSampler()
        let cpu = sampler.sample(afterDelay: samplingInterval)
        let ram = RAMReader.read()
        let disk = cachedDisk ?? DiskReader.read()
        let processes = ProcessReader.readTopProcesses(limit: topProcessLimit)

        return SystemSnapshot(
            cpu: cpu,
            ram: ram,
            disk: disk,
            topProcesses: processes
        )
    }
}
