import Darwin
import Foundation
import MachO

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

    public init(totalUsage: Double, perCoreUsage: [Double]) {
        self.totalUsage = totalUsage
        self.perCoreUsage = perCoreUsage
    }
}

/// Pure math helpers for CPU usage calculation from tick deltas.
public enum CPUCalculator {
    /// Computes CPU metrics from tick deltas between two samples.
    public static func calculateDelta(previous: [CoreTicks], current: [CoreTicks]) -> CPUMetrics {
        guard !previous.isEmpty, previous.count == current.count else {
            let zeros = [Double](repeating: 0.0, count: current.count)
            return CPUMetrics(totalUsage: 0.0, perCoreUsage: zeros)
        }

        var totalDeltaUsed: UInt64 = 0
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

            let coreDeltaUsed = deltaUser + deltaSystem + deltaNice
            let coreDeltaTotal = coreDeltaUsed + deltaIdle

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
        if totalDeltaTicks > 0 {
            overallPercent = (Double(totalDeltaUsed) / Double(totalDeltaTicks)) * 100.0
        } else {
            overallPercent = 0.0
        }

        return CPUMetrics(
            totalUsage: min(max(overallPercent, 0.0), 100.0),
            perCoreUsage: perCore
        )
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
    /// If no previous sample exists, returns 0.0% usage and stores the sample as the baseline.
    @discardableResult
    public func sample() -> CPUMetrics {
        let currentTicks = Self.readCurrentTicks()

        lock.lock()
        defer { lock.unlock() }

        guard let previous = previousSample else {
            previousSample = currentTicks
            let zeros = [Double](repeating: 0.0, count: currentTicks.count)
            return CPUMetrics(totalUsage: 0.0, perCoreUsage: zeros)
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
        previousSample = nil
        lock.unlock()
    }

    /// Reads raw CPU ticks from Darwin host_processor_info and frees the buffer with vm_deallocate.
    public static func readCurrentTicks() -> [CoreTicks] {
        var processorCount: natural_t = 0
        var processorInfo: processor_info_array_t?
        var processorInfoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &processorInfo,
            &processorInfoCount
        )

        guard result == KERN_SUCCESS, let info = processorInfo else {
            return []
        }

        defer {
            let size = vm_size_t(processorInfoCount) * vm_size_t(MemoryLayout<natural_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), size)
        }

        let coreCount = Int(processorCount)
        var ticks: [CoreTicks] = []
        ticks.reserveCapacity(coreCount)

        for core in 0..<coreCount {
            let base = core * Int(CPU_STATE_MAX)
            let user = UInt64(info[base + Int(CPU_STATE_USER)])
            let system = UInt64(info[base + Int(CPU_STATE_SYSTEM)])
            let idle = UInt64(info[base + Int(CPU_STATE_IDLE)])
            let nice = UInt64(info[base + Int(CPU_STATE_NICE)])

            ticks.append(CoreTicks(user: user, system: system, idle: idle, nice: nice))
        }

        return ticks
    }
}
