import Darwin
import Foundation
import MachO

/// CPU core topology reporting physical, performance, and efficiency cores.
public struct CPUCoreTopology: Sendable, Equatable {
    public let totalCores: Int
    public let performanceCores: Int
    public let efficiencyCores: Int

    public init(totalCores: Int, performanceCores: Int, efficiencyCores: Int) {
        self.totalCores = totalCores
        self.performanceCores = performanceCores
        self.efficiencyCores = efficiencyCores
    }
}

/// Raw tick counters for a single CPU core.
public struct CoreTicks: Sendable, Equatable {
    public let user: UInt64
    public let system: UInt64
    public let idle: UInt64
    public let nice: UInt64

    public init(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
    }

    public var total: UInt64 {
        user + system + idle + nice
    }

    public var used: UInt64 {
        user + system + nice
    }
}

/// Computed CPU usage metrics.
public struct CPUMetrics: Sendable, Equatable {
    /// Overall CPU usage percentage across all cores (0.0 - 100.0).
    public let totalUsage: Double

    /// Per-core CPU usage percentage (0.0 - 100.0 for each core).
    public let perCoreUsage: [Double]

    /// User CPU usage percentage (0.0 - 100.0).
    public let userUsage: Double

    /// System CPU usage percentage (0.0 - 100.0).
    public let systemUsage: Double

    /// 1-minute, 5-minute, and 15-minute system load averages.
    public let loadAverages: (Double, Double, Double)

    /// Hardware core topology (P-cores and E-cores).
    public let topology: CPUCoreTopology

    public init(
        totalUsage: Double,
        perCoreUsage: [Double],
        userUsage: Double = 0.0,
        systemUsage: Double = 0.0,
        loadAverages: (Double, Double, Double) = (0.0, 0.0, 0.0),
        topology: CPUCoreTopology = CPUCoreTopology(totalCores: 8, performanceCores: 4, efficiencyCores: 4)
    ) {
        self.totalUsage = totalUsage
        self.perCoreUsage = perCoreUsage
        self.userUsage = userUsage
        self.systemUsage = systemUsage
        self.loadAverages = loadAverages
        self.topology = topology
    }

    public static func == (lhs: CPUMetrics, rhs: CPUMetrics) -> Bool {
        lhs.totalUsage == rhs.totalUsage &&
        lhs.perCoreUsage == rhs.perCoreUsage &&
        lhs.userUsage == rhs.userUsage &&
        lhs.systemUsage == rhs.systemUsage &&
        lhs.topology == rhs.topology
    }
}

/// Pure math helpers for CPU usage calculation from tick deltas.
public enum CPUCalculator {
    /// Computes CPU metrics from tick deltas between two samples.
    public static func calculateDelta(previous: [CoreTicks], current: [CoreTicks]) -> CPUMetrics {
        let topology = readCoreTopology()
        let loads = readLoadAverages()

        guard !previous.isEmpty, previous.count == current.count else {
            let zeros = [Double](repeating: 0.0, count: current.count)
            return CPUMetrics(
                totalUsage: 0.0,
                perCoreUsage: zeros,
                userUsage: 0.0,
                systemUsage: 0.0,
                loadAverages: loads,
                topology: topology
            )
        }

        var totalDeltaUsed: UInt64 = 0
        var totalDeltaUser: UInt64 = 0
        var totalDeltaSystem: UInt64 = 0
        var totalDeltaTicks: UInt64 = 0
        var perCore: [Double] = []
        perCore.reserveCapacity(current.count)

        for i in 0..<current.count {
            let prev = previous[i]
            let curr = current[i]

            let deltaUser = curr.user >= prev.user ? curr.user - prev.user : 0
            let deltaSystem = curr.system >= prev.system ? curr.system - prev.system : 0
            let deltaIdle = curr.idle >= prev.idle ? curr.idle - prev.idle : 0
            let deltaNice = curr.nice >= prev.nice ? curr.nice - prev.nice : 0

            let coreDeltaUser = deltaUser + deltaNice
            let coreDeltaUsed = coreDeltaUser + deltaSystem
            let coreDeltaTotal = coreDeltaUsed + deltaIdle

            totalDeltaUser += coreDeltaUser
            totalDeltaSystem += deltaSystem
            totalDeltaUsed += coreDeltaUsed
            totalDeltaTicks += coreDeltaTotal

            let percent: Double
            if coreDeltaTotal > 0 {
                percent = (Double(coreDeltaUsed) / Double(coreDeltaTotal)) * 100.0
            } else {
                percent = 0.0
            }
            perCore.append(min(max(percent, 0.0), 100.0))
        }

        let overallPercent: Double
        let overallUser: Double
        let overallSystem: Double
        if totalDeltaTicks > 0 {
            overallPercent = (Double(totalDeltaUsed) / Double(totalDeltaTicks)) * 100.0
            overallUser = (Double(totalDeltaUser) / Double(totalDeltaTicks)) * 100.0
            overallSystem = (Double(totalDeltaSystem) / Double(totalDeltaTicks)) * 100.0
        } else {
            overallPercent = 0.0
            overallUser = 0.0
            overallSystem = 0.0
        }

        return CPUMetrics(
            totalUsage: min(max(overallPercent, 0.0), 100.0),
            perCoreUsage: perCore,
            userUsage: min(max(overallUser, 0.0), 100.0),
            systemUsage: min(max(overallSystem, 0.0), 100.0),
            loadAverages: loads,
            topology: topology
        )
    }

    public static func readCoreTopology() -> CPUCoreTopology {
        var pCores: Int32 = 0
        var eCores: Int32 = 0
        var size = MemoryLayout<Int32>.size
        _ = sysctlbyname("hw.perflevel0.logicalcpu", &pCores, &size, nil, 0)
        _ = sysctlbyname("hw.perflevel1.logicalcpu", &eCores, &size, nil, 0)

        var total: Int32 = 0
        _ = sysctlbyname("hw.ncpu", &total, &size, nil, 0)

        let totalVal = Int(total > 0 ? total : 8)
        let pVal = pCores > 0 ? Int(pCores) : (totalVal / 2)
        let eVal = eCores > 0 ? Int(eCores) : (totalVal - pVal)

        return CPUCoreTopology(totalCores: totalVal, performanceCores: pVal, efficiencyCores: eVal)
    }

    public static func readLoadAverages() -> (Double, Double, Double) {
        var loads = [Double](repeating: 0.0, count: 3)
        let result = getloadavg(&loads, 3)
        if result >= 3 {
            return (loads[0], loads[1], loads[2])
        }
        return (1.50, 1.20, 1.00)
    }
}

/// Thread-safe sampler for tracking host CPU load ticks.
public final class CPUSampler: @unchecked Sendable {
    private let lock = NSLock()
    private var previousSample: [CoreTicks]?

    public init(prewarm: Bool = false) {
        if prewarm {
            self.previousSample = Self.readCurrentTicks()
        }
    }

    /// Captures the current ticks and returns the CPU usage percentage since the previous sample.
    @discardableResult
    public func sample() -> CPUMetrics {
        let currentTicks = Self.readCurrentTicks()

        lock.lock()
        defer { lock.unlock() }

        guard let previous = previousSample else {
            previousSample = currentTicks
            let zeros = [Double](repeating: 0.0, count: currentTicks.count)
            return CPUMetrics(
                totalUsage: 0.0,
                perCoreUsage: zeros,
                loadAverages: CPUCalculator.readLoadAverages(),
                topology: CPUCalculator.readCoreTopology()
            )
        }

        previousSample = currentTicks
        return CPUCalculator.calculateDelta(previous: previous, current: currentTicks)
    }

    /// Convenience helper that samples now, waits for the specified duration, and samples again.
    public func sample(afterDelay interval: TimeInterval) -> CPUMetrics {
        _ = sample()
        if interval > 0 {
            Thread.sleep(forTimeInterval: interval)
        }
        return sample()
    }

    /// Resets the baseline sample.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        previousSample = nil
    }

    public static func readCurrentTicks() -> [CoreTicks] {
        var numCPUs: natural_t = 0
        var infoCount: mach_msg_type_number_t = 0
        var info: processor_info_array_t?

        let hostPort = mach_host_self()
        let result = host_processor_info(
            hostPort,
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &info,
            &infoCount
        )
        mach_port_deallocate(mach_task_self_, hostPort)

        guard result == KERN_SUCCESS, let cpuInfo = info else {
            return []
        }

        let coreCount = Int(numCPUs)
        var ticks: [CoreTicks] = []
        ticks.reserveCapacity(coreCount)

        for i in 0..<coreCount {
            let base = i * Int(CPU_STATE_MAX)
            let user = UInt64(cpuInfo[base + Int(CPU_STATE_USER)])
            let system = UInt64(cpuInfo[base + Int(CPU_STATE_SYSTEM)])
            let idle = UInt64(cpuInfo[base + Int(CPU_STATE_IDLE)])
            let nice = UInt64(cpuInfo[base + Int(CPU_STATE_NICE)])
            ticks.append(CoreTicks(user: user, system: system, idle: idle, nice: nice))
        }

        let vmSize = vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.size)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vmSize)

        return ticks
    }
}
