import Darwin

/// Plain struct representing a process and its physical memory footprint.
public struct ProcessMetrics: Sendable, Equatable {
    public let pid: pid_t
    public let name: String
    public let bytes: UInt64

    public init(pid: pid_t, name: String, bytes: UInt64) {
        self.pid = pid
        self.name = name
        self.bytes = bytes
    }
}

/// Discovers running processes and queries memory footprint using libproc.
public enum ProcessReader {
    /// Reads all running processes, skips failures, and returns the top `limit` sorted by footprint descending.
    public static func readTopProcesses(limit: Int = 10) -> [ProcessMetrics] {
        guard limit > 0 else { return [] }

        let bytesNeeded = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard bytesNeeded > 0 else { return [] }

        let pidCapacity = Int(bytesNeeded) / MemoryLayout<pid_t>.size
        var pids = [pid_t](repeating: 0, count: pidCapacity)
        let actualBytes = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard actualBytes > 0 else { return [] }

        let count = min(pidCapacity, Int(actualBytes) / MemoryLayout<pid_t>.size)

        // Reuse buffers across all iterations; avoid Foundation objects in the loop
        var rusage = rusage_info_v4()
        var nameBuffer = [CChar](repeating: 0, count: 256)

        let rusagePtr = withUnsafeMutablePointer(to: &rusage) {
            UnsafeMutableRawPointer($0).bindMemory(to: rusage_info_t?.self, capacity: 1)
        }

        var results: [ProcessMetrics] = []
        results.reserveCapacity(min(count, 512))

        for i in 0..<count {
            let pid = pids[i]
            if pid <= 0 { continue }

            if proc_pid_rusage(pid, RUSAGE_INFO_V4, rusagePtr) != 0 {
                continue
            }

            let footprint = rusage.ri_phys_footprint
            if footprint == 0 {
                continue
            }

            nameBuffer[0] = 0
            let nameLen = proc_name(pid, &nameBuffer, UInt32(nameBuffer.count))
            if nameLen <= 0 {
                continue
            }

            let name = String(cString: nameBuffer)
            results.append(ProcessMetrics(pid: pid, name: name, bytes: footprint))
        }

        results.sort { $0.bytes > $1.bytes }

        if results.count > limit {
            return Array(results.prefix(limit))
        }
        return results
    }
}
