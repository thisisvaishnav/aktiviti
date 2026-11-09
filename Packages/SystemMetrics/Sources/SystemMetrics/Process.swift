import Darwin
import Foundation

/// Plain struct representing a process, its physical memory footprint, and power estimate.
public struct ProcessMetrics: Sendable, Equatable {
    public let pid: pid_t
    public let name: String
    public let bytes: UInt64
    public let powerMilliwatts: Double
    public let cpuPercent: Double
    public let diskBytesPerSec: Double

    public init(
        pid: pid_t,
        name: String,
        bytes: UInt64,
        powerMilliwatts: Double = 0.0,
        cpuPercent: Double = 0.0,
        diskBytesPerSec: Double = 0.0
    ) {
        self.pid = pid
        self.name = name
        self.bytes = bytes
        self.powerMilliwatts = powerMilliwatts
        self.cpuPercent = cpuPercent
        self.diskBytesPerSec = diskBytesPerSec
    }
}

/// Discovers running processes and queries memory footprint, CPU time, and disk I/O using libproc.
public final class ProcessSampler: @unchecked Sendable {
    private struct RawProcessRecord {
        let pid: pid_t
        let bytes: UInt64
        let powerMilliwatts: Double
        let cpuPercent: Double
        let diskBytesPerSec: Double
    }

    private let lock = NSLock()
    private var prevTimes: [pid_t: (cpuTime: UInt64, diskBytes: UInt64)] = [:]
    private var prevTimestamp: Date?

    public init() {}

    public func sample(limit: Int = 12) -> (memory: [ProcessMetrics], power: [ProcessMetrics]) {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        let elapsed = max(now.timeIntervalSince(prevTimestamp ?? now), 0.001)
        let isFirst = prevTimestamp == nil
        prevTimestamp = now

        let bytesNeeded = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard bytesNeeded > 0 else { return ([], []) }

        let pidCapacity = Int(bytesNeeded) / MemoryLayout<pid_t>.size
        var pids = [pid_t](repeating: 0, count: pidCapacity)
        let actualBytes = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard actualBytes > 0 else { return ([], []) }

        let count = min(pidCapacity, Int(actualBytes) / MemoryLayout<pid_t>.size)

        var rusage = rusage_info_v4()
        let rusagePtr = withUnsafeMutablePointer(to: &rusage) {
            UnsafeMutableRawPointer($0).bindMemory(to: rusage_info_t?.self, capacity: 1)
        }

        var rawRecords: [RawProcessRecord] = []
        rawRecords.reserveCapacity(min(count, 512))
        var newTimes: [pid_t: (cpuTime: UInt64, diskBytes: UInt64)] = [:]
        newTimes.reserveCapacity(count)

        for i in 0..<count {
            let pid = pids[i]
            if pid <= 0 { continue }
            if proc_pid_rusage(pid, RUSAGE_INFO_V4, rusagePtr) != 0 { continue }

            let footprint = rusage.ri_phys_footprint
            if footprint == 0 { continue }

            let cpuTime = rusage.ri_user_time + rusage.ri_system_time
            let diskBytes = rusage.ri_diskio_bytesread + rusage.ri_diskio_byteswritten
            newTimes[pid] = (cpuTime, diskBytes)

            var cpuPct = 0.0
            var diskRate = 0.0
            if let prev = prevTimes[pid] {
                let dCpu = cpuTime >= prev.cpuTime ? cpuTime - prev.cpuTime : 0
                cpuPct = (Double(dCpu) / 1_000_000_000.0 / elapsed) * 100.0
                let dDisk = diskBytes >= prev.diskBytes ? diskBytes - prev.diskBytes : 0
                diskRate = Double(dDisk) / elapsed
            } else if isFirst {
                // Approximate baseline on initial startup
                cpuPct = min(25.0, max(0.5, Double(footprint) / (1024.0 * 1024.0 * 1024.0) * 8.0))
            }

            let powerEst = (cpuPct * 80.0) + (Double(footprint) / (1024.0 * 1024.0 * 1024.0) * 120.0)

            rawRecords.append(RawProcessRecord(
                pid: pid,
                bytes: footprint,
                powerMilliwatts: powerEst,
                cpuPercent: cpuPct,
                diskBytesPerSec: diskRate
            ))
        }

        prevTimes = newTimes

        // Sort lightweight records to identify only the top candidates
        var byMemory = rawRecords
        byMemory.sort { $0.bytes > $1.bytes }
        let topMem = Array(byMemory.prefix(limit))

        var byPower = rawRecords
        byPower.sort { ($0.cpuPercent + $0.powerMilliwatts) > ($1.cpuPercent + $1.powerMilliwatts) }
        let topPower = Array(byPower.prefix(limit))

        // Resolve process names lazily only for the top candidate PIDs
        // avoids hundreds of proc_name syscalls and String allocations on non-top daemons
        var nameBuffer = [CChar](repeating: 0, count: 256)
        var resolvedNames: [pid_t: String] = [:]
        resolvedNames.reserveCapacity(limit * 2)

        for raw in (topMem + topPower) {
            if resolvedNames[raw.pid] == nil {
                nameBuffer[0] = 0
                let nameLen = proc_name(raw.pid, &nameBuffer, UInt32(nameBuffer.count))
                if nameLen > 0 {
                    resolvedNames[raw.pid] = String(cString: nameBuffer)
                } else {
                    resolvedNames[raw.pid] = "Process \(raw.pid)"
                }
            }
        }

        let memoryMetrics = topMem.map { raw in
            ProcessMetrics(
                pid: raw.pid,
                name: resolvedNames[raw.pid] ?? "Process \(raw.pid)",
                bytes: raw.bytes,
                powerMilliwatts: raw.powerMilliwatts,
                cpuPercent: raw.cpuPercent,
                diskBytesPerSec: raw.diskBytesPerSec
            )
        }

        let powerMetrics = topPower.map { raw in
            ProcessMetrics(
                pid: raw.pid,
                name: resolvedNames[raw.pid] ?? "Process \(raw.pid)",
                bytes: raw.bytes,
                powerMilliwatts: raw.powerMilliwatts,
                cpuPercent: raw.cpuPercent,
                diskBytesPerSec: raw.diskBytesPerSec
            )
        }

        return (memory: memoryMetrics, power: powerMetrics)
    }
}

/// Discovers running processes and queries memory footprint and power usage using libproc.
public enum ProcessReader {
    public static func readTopProcesses(limit: Int = 10) -> [ProcessMetrics] {
        guard limit > 0 else { return [] }
        let sampler = ProcessSampler()
        return sampler.sample(limit: limit).memory
    }

    public static func readTopPowerProcesses(limit: Int = 5) -> [ProcessMetrics] {
        guard limit > 0 else { return [] }
        let sampler = ProcessSampler()
        return sampler.sample(limit: limit).power
    }
}
