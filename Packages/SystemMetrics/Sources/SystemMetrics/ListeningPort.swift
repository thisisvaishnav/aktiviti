import Darwin
import Foundation

/// Represents a listening network port and its associated process.
public struct ListeningPortInfo: Identifiable, Sendable, Equatable {
    public let id: String
    public let pid: pid_t
    public let port: Int
    public let processName: String
    public let workingDirectory: String?
    public let commandLine: String?
    public let memoryBytes: UInt64
    public let isLocalhostOnly: Bool
    public let isOrphaned: Bool
    public let serviceName: String

    public init(
        pid: pid_t,
        port: Int,
        processName: String,
        workingDirectory: String? = nil,
        commandLine: String? = nil,
        memoryBytes: UInt64 = 0,
        isLocalhostOnly: Bool = false,
        isOrphaned: Bool = false,
        serviceName: String? = nil
    ) {
        self.id = "\(pid):\(port)"
        self.pid = pid
        self.port = port
        self.processName = processName
        self.workingDirectory = workingDirectory
        self.commandLine = commandLine
        self.memoryBytes = memoryBytes
        self.isLocalhostOnly = isLocalhostOnly
        self.isOrphaned = isOrphaned
        self.serviceName = serviceName ?? PortScanner.serviceName(for: port)
    }
}

/// Discovers active listening TCP ports, maps them to running processes & working directories,
/// and allows one-click termination of zombie or rogue dev servers.
public enum PortScanner {

    /// Returns human-friendly dev service name for common development ports.
    public static func serviceName(for port: Int) -> String {
        switch port {
        case 3000: return "React / Next.js"
        case 3001: return "Dev Server"
        case 4200: return "Angular"
        case 5000: return "Flask / AirPlay"
        case 5173: return "Vite"
        case 5174: return "Vite Dev"
        case 5432: return "PostgreSQL"
        case 6379: return "Redis"
        case 8000: return "Django / FastAPI"
        case 8080: return "HTTP / Webpack"
        case 8888: return "Jupyter Notebook"
        case 9000: return "PHP-FPM / Sonar"
        case 11434: return "Ollama (Local AI)"
        case 27017: return "MongoDB"
        default:
            if port >= 3000 && port <= 9999 {
                return "Dev Service"
            }
            return "TCP Service"
        }
    }

    /// Scans all system processes for open TCP listening sockets using native Darwin libproc APIs.
    public static func scanListeningPorts() -> [ListeningPortInfo] {
        let bytesNeeded = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard bytesNeeded > 0 else { return [] }

        let pidCapacity = Int(bytesNeeded) / MemoryLayout<pid_t>.size
        var pids = [pid_t](repeating: 0, count: pidCapacity)
        let actualBytes = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard actualBytes > 0 else { return [] }

        let count = min(pidCapacity, Int(actualBytes) / MemoryLayout<pid_t>.size)

        var results: [ListeningPortInfo] = []
        var seen = Set<String>()

        var nameBuffer = [CChar](repeating: 0, count: 256)

        for i in 0..<count {
            let pid = pids[i]
            guard pid > 0 else { continue }

            let fdsNeeded = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, nil, 0)
            guard fdsNeeded > 0 else { continue }

            let fdCount = Int(fdsNeeded) / MemoryLayout<proc_fdinfo>.size
            var fdInfos = [proc_fdinfo](repeating: proc_fdinfo(), count: fdCount)
            let actualFdBytes = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, &fdInfos, Int32(fdInfos.count * MemoryLayout<proc_fdinfo>.size))
            guard actualFdBytes > 0 else { continue }

            for fd in fdInfos where fd.proc_fdtype == PROX_FDTYPE_SOCKET {
                var sockInfo = socket_fdinfo()
                let readBytes = proc_pidfdinfo(pid, fd.proc_fd, PROC_PIDFDSOCKETINFO, &sockInfo, Int32(MemoryLayout<socket_fdinfo>.size))
                guard readBytes == MemoryLayout<socket_fdinfo>.size else { continue }

                let family = sockInfo.psi.soi_family
                guard family == AF_INET || family == AF_INET6 else { continue }

                // Inspect TCP protocol info inside soi_proto union
                withUnsafeBytes(of: sockInfo.psi.soi_proto) { raw in
                    // in_sockinfo has foreign port at 0, local port at 4 (network byte order)
                    let lportRaw = raw.load(fromByteOffset: 4, as: Int32.self)
                    let lport = Int(UInt16(bigEndian: UInt16(truncatingIfNeeded: lportRaw)))
                    guard lport > 0 else { return }

                    // tcpsi_state is right after in_sockinfo (1 = TSI_S_LISTEN)
                    let state = raw.load(fromByteOffset: MemoryLayout<in_sockinfo>.size, as: Int32.self)
                    guard state == 1 else { return }

                    let key = "\(pid):\(lport)"
                    guard !seen.contains(key) else { return }
                    seen.insert(key)

                    // Get process name
                    nameBuffer[0] = 0
                    let nameLen = proc_name(pid, &nameBuffer, UInt32(nameBuffer.count))
                    let name = nameLen > 0 ? String(cString: nameBuffer) : "Process \(pid)"

                    // Check if localhost only (127.0.0.1 or ::1)
                    var isLocalhost = false
                    if family == AF_INET {
                        // IPv4 address check in in_sockinfo (offset 12 is insi_laddr)
                        let laddr = raw.load(fromByteOffset: 16, as: UInt32.self)
                        let hostOrder = UInt32(bigEndian: laddr)
                        isLocalhost = (hostOrder & 0xFF000000) == 0x7F000000
                    }

                    // Process memory footprint
                    var rusage = rusage_info_v4()
                    let rusagePtr = withUnsafeMutablePointer(to: &rusage) {
                        UnsafeMutableRawPointer($0).bindMemory(to: rusage_info_t?.self, capacity: 1)
                    }
                    var memBytes: UInt64 = 0
                    if proc_pid_rusage(pid, RUSAGE_INFO_V4, rusagePtr) == 0 {
                        memBytes = rusage.ri_phys_footprint
                    }

                    // Working directory
                    var cwd: String? = nil
                    var vpi = proc_vnodepathinfo()
                    if proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &vpi, Int32(MemoryLayout<proc_vnodepathinfo>.size)) > 0 {
                        withUnsafePointer(to: &vpi.pvi_cdir.vip_path) { ptr in
                            ptr.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) { cstr in
                                let path = String(cString: cstr)
                                if !path.isEmpty && path != "/" {
                                    cwd = path
                                }
                            }
                        }
                    }

                    // Parent PID & orphan check
                    var bsd = proc_bsdinfo()
                    var isOrphan = false
                    if proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bsd, Int32(MemoryLayout<proc_bsdinfo>.size)) > 0 {
                        // In macOS, orphaned background processes are reparented to launchd (PID 1)
                        if bsd.pbi_ppid == 1 && (name.contains("node") || name.contains("python") || name.contains("vite") || name.contains("ruby") || name.contains("cargo")) {
                            isOrphan = true
                        }
                    }

                    results.append(ListeningPortInfo(
                        pid: pid,
                        port: lport,
                        processName: name,
                        workingDirectory: cwd,
                        commandLine: getCommandLine(pid: pid),
                        memoryBytes: memBytes,
                        isLocalhostOnly: isLocalhost,
                        isOrphaned: isOrphan
                    ))
                }
            }
        }

        // Sort by port ascending, prioritizing common dev ports first
        return results.sorted {
            let p1IsDev = ($0.port >= 3000 && $0.port <= 9999)
            let p2IsDev = ($1.port >= 3000 && $1.port <= 9999)
            if p1IsDev != p2IsDev {
                return p1IsDev
            }
            return $0.port < $1.port
        }
    }

    /// Safely terminates a process by PID. Never allows terminating system PIDs (0 or 1).
    @discardableResult
    public static func terminateProcess(pid: pid_t, force: Bool = false) -> Bool {
        guard pid > 1 else { return false }
        let sig = force ? SIGKILL : SIGTERM
        return Darwin.kill(pid, sig) == 0
    }

    /// Reads command-line arguments using sysctl KERN_PROCARGS2.
    private static func getCommandLine(pid: pid_t) -> String? {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > 0 else {
            return nil
        }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buffer, &size, nil, 0) == 0 else {
            return nil
        }

        return buffer.withUnsafeBytes { raw in
            let argc = raw.load(as: Int32.self)
            guard argc > 0 else { return nil }

            var offset = 4
            // Skip executable path (null terminated)
            while offset < size && raw[offset] != 0 { offset += 1 }
            // Skip trailing null bytes
            while offset < size && raw[offset] == 0 { offset += 1 }

            var args: [String] = []
            for _ in 0..<argc {
                guard offset < size else { break }
                let start = offset
                while offset < size && raw[offset] != 0 { offset += 1 }
                if let str = String(bytes: raw[start..<offset], encoding: .utf8) {
                    args.append(str)
                }
                offset += 1
            }
            return args.isEmpty ? nil : args.joined(separator: " ")
        }
    }
}
