import Foundation

/// A unified, sendable snapshot of system metrics.
public struct SystemSnapshot: Sendable, Equatable {
    /// CPU usage metrics if available (requires tick delta or previous sample).
    public let cpu: CPUMetrics?

    /// Memory / RAM metrics.
    public let ram: RAMMetrics

    /// Disk space and I/O metrics for "/".
    public let disk: DiskMetrics

    /// GPU metrics.
    public let gpu: GPUMetrics?

    /// Network metrics.
    public let network: NetworkMetrics?

    /// Battery and power metrics.
    public let battery: BatteryMetrics?

    /// Top memory-consuming processes sorted descending by physical footprint.
    public let topProcesses: [ProcessMetrics]

    /// Top power-consuming processes.
    public let topPowerProcesses: [ProcessMetrics]

    /// Active listening TCP ports and dev servers.
    public let listeningPorts: [ListeningPortInfo]

    public init(
        cpu: CPUMetrics?,
        ram: RAMMetrics,
        disk: DiskMetrics,
        topProcesses: [ProcessMetrics],
        gpu: GPUMetrics? = nil,
        network: NetworkMetrics? = nil,
        battery: BatteryMetrics? = nil,
        topPowerProcesses: [ProcessMetrics] = [],
        listeningPorts: [ListeningPortInfo] = []
    ) {
        self.cpu = cpu
        self.ram = ram
        self.disk = disk
        self.gpu = gpu
        self.network = network
        self.battery = battery
        self.topProcesses = topProcesses
        self.topPowerProcesses = topPowerProcesses
        self.listeningPorts = listeningPorts
    }

    /// Captures a one-shot snapshot of system metrics.
    public static func capture(
        cpuSampler: CPUSampler? = nil,
        gpuSampler: GPUSampler? = nil,
        networkSampler: NetworkSampler? = nil,
        diskSampler: DiskSampler? = nil,
        processSampler: ProcessSampler? = nil,
        topProcessLimit: Int = 10,
        cachedDisk: DiskMetrics? = nil,
        includePorts: Bool = false
    ) -> SystemSnapshot {
        let cpu = cpuSampler?.sample()
        let ram = RAMReader.read()
        let disk = diskSampler?.sample(cachedBase: cachedDisk) ?? cachedDisk ?? DiskReader.read()
        let gpu = gpuSampler?.sample()
        let network = networkSampler?.sample()
        let battery = BatteryReader.read()
        
        let processes: [ProcessMetrics]
        let powerProcs: [ProcessMetrics]
        if let ps = processSampler {
            let res = ps.sample(limit: topProcessLimit)
            processes = res.memory
            powerProcs = res.power
        } else {
            processes = ProcessReader.readTopProcesses(limit: topProcessLimit)
            powerProcs = ProcessReader.readTopPowerProcesses(limit: 5)
        }

        let ports = includePorts ? PortScanner.scanListeningPorts() : []

        return SystemSnapshot(
            cpu: cpu,
            ram: ram,
            disk: disk,
            topProcesses: processes,
            gpu: gpu,
            network: network,
            battery: battery,
            topPowerProcesses: powerProcs,
            listeningPorts: ports
        )
    }

    /// Captures a one-shot snapshot, taking an active CPU measurement over the given duration.
    public static func capture(
        samplingCPUFor samplingInterval: TimeInterval,
        topProcessLimit: Int = 10,
        cachedDisk: DiskMetrics? = nil,
        includePorts: Bool = false
    ) -> SystemSnapshot {
        let sampler = CPUSampler()
        let cpu = sampler.sample(afterDelay: samplingInterval)
        let ram = RAMReader.read()
        let disk = cachedDisk ?? DiskReader.read()
        let processes = ProcessReader.readTopProcesses(limit: topProcessLimit)
        let powerProcs = ProcessReader.readTopPowerProcesses(limit: 5)
        let ports = includePorts ? PortScanner.scanListeningPorts() : []

        return SystemSnapshot(
            cpu: cpu,
            ram: ram,
            disk: disk,
            topProcesses: processes,
            topPowerProcesses: powerProcs,
            listeningPorts: ports
        )
    }
}
