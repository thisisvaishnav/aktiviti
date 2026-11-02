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
    /// Internal lightweight value type for fast sorting without heap allocations or ARC overhead.
    private struct RawProcessRecord {
        let pid: pid_t
        let bytes: UInt64
    }

    /// Reads all running processes, skips failures, and returns the top `limit` sorted by footprint descending.
    /// Defers process name resolution and String allocations strictly to the top `limit` processes.
    public static func readTopProcesses(limit: Int = 10) -> [ProcessMetrics] {
        guard limit > 0 else { return [] }

        let bytesNeeded = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard bytesNeeded > 0 else { return [] }

        let pidCapacity = Int(bytesNeeded) / MemoryLayout<pid_t>.size
        var pids = [pid_t](repeating: 0, count: pidCapacity)
        let actualBytes = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard actualBytes > 0 else { return [] }

        let count = min(pidCapacity, Int(actualBytes) / MemoryLayout<pid_t>.size)

        var rusage = rusage_info_v4()
        let rusagePtr = withUnsafeMutablePointer(to: &rusage) {
            UnsafeMutableRawPointer($0).bindMemory(to: rusage_info_t?.self, capacity: 1)
        }

        // 1. Collect raw (pid, bytes) records with zero heap allocations / refcounting in the scan loop
        var rawRecords: [RawProcessRecord] = []
        rawRecords.reserveCapacity(min(count, 512))

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

            rawRecords.append(RawProcessRecord(pid: pid, bytes: footprint))
        }

        // 2. Sort primitive numeric pairs in-place (much faster than sorting structs with String pointers)
        rawRecords.sort { $0.bytes > $1.bytes }

        // 3. Resolve names and allocate Strings ONLY for the top candidates
        var results: [ProcessMetrics] = []
        results.reserveCapacity(min(limit, rawRecords.count))

        var nameBuffer = [CChar](repeating: 0, count: 256)

        for record in rawRecords {
            if results.count >= limit {
                break
            }

            nameBuffer[0] = 0
            let nameLen = proc_name(record.pid, &nameBuffer, UInt32(nameBuffer.count))
            guard nameLen > 0 else { continue }

            let name = String(cString: nameBuffer)
            results.append(ProcessMetrics(pid: record.pid, name: name, bytes: record.bytes))
        }

        return results
    }
}
