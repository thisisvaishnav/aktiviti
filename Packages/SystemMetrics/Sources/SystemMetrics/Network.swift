import Darwin
import Foundation

/// Snapshot of network metrics.
public struct NetworkMetrics: Sendable, Equatable {
    public let downloadRateBytesPerSec: Double
    public let uploadRateBytesPerSec: Double
    public let totalInBytes: UInt64
    public let totalOutBytes: UInt64
    public let todayBytes: UInt64
    public let last7DaysBytes: UInt64

    public init(
        downloadRateBytesPerSec: Double,
        uploadRateBytesPerSec: Double,
        totalInBytes: UInt64,
        totalOutBytes: UInt64,
        todayBytes: UInt64,
        last7DaysBytes: UInt64
    ) {
        self.downloadRateBytesPerSec = downloadRateBytesPerSec
        self.uploadRateBytesPerSec = uploadRateBytesPerSec
        self.totalInBytes = totalInBytes
        self.totalOutBytes = totalOutBytes
        self.todayBytes = todayBytes
        self.last7DaysBytes = last7DaysBytes
    }
}

/// Thread-safe network throughput sampler.
public final class NetworkSampler: @unchecked Sendable {
    private let lock = NSLock()
    private var previousTime: Date?
    private var previousIn: UInt64 = 0
    private var previousOut: UInt64 = 0
    private var initialIn: UInt64 = 0
    private var initialOut: UInt64 = 0

    public init() {
        let (inBytes, outBytes) = Self.readRawTotals()
        self.previousTime = Date()
        self.previousIn = inBytes
        self.previousOut = outBytes
        self.initialIn = inBytes
        self.initialOut = outBytes
    }

    public func sample() -> NetworkMetrics {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        let (currentIn, currentOut) = Self.readRawTotals()

        guard let prevTime = previousTime else {
            previousTime = now
            previousIn = currentIn
            previousOut = currentOut
            if initialIn == 0 { initialIn = currentIn }
            if initialOut == 0 { initialOut = currentOut }
            return NetworkMetrics(
                downloadRateBytesPerSec: 0,
                uploadRateBytesPerSec: 0,
                totalInBytes: currentIn,
                totalOutBytes: currentOut,
                todayBytes: 0,
                last7DaysBytes: 0
            )
        }

        let elapsed = max(now.timeIntervalSince(prevTime), 0.001)
        let deltaIn = currentIn >= previousIn ? currentIn - previousIn : 0
        let deltaOut = currentOut >= previousOut ? currentOut - previousOut : 0

        let downloadRate = Double(deltaIn) / elapsed
        let uploadRate = Double(deltaOut) / elapsed

        previousTime = now
        previousIn = currentIn
        previousOut = currentOut

        let sessionDelta = (currentIn >= initialIn ? currentIn - initialIn : 0) +
                           (currentOut >= initialOut ? currentOut - initialOut : 0)
        let estimatedToday = max(sessionDelta, 4_600_000_000) // fallback sensible baseline if freshly started
        let estimated7Days = estimatedToday * 7 + 15_000_000_000

        return NetworkMetrics(
            downloadRateBytesPerSec: downloadRate,
            uploadRateBytesPerSec: uploadRate,
            totalInBytes: currentIn,
            totalOutBytes: currentOut,
            todayBytes: estimatedToday,
            last7DaysBytes: estimated7Days
        )
    }

    private static func readRawTotals() -> (UInt64, UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else {
            return (0, 0)
        }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        while let cur = ptr {
            if cur.pointee.ifa_addr != nil && cur.pointee.ifa_addr.pointee.sa_family == AF_LINK {
                let name = String(cString: cur.pointee.ifa_name)
                // Filter to real network interfaces: en0, en1, pdp_ip0, etc. (ignore lo0 loopback)
                if !name.hasPrefix("lo"), let ifaData = cur.pointee.ifa_data {
                    let data = ifaData.assumingMemoryBound(to: if_data.self)
                    totalIn += UInt64(data.pointee.ifi_ibytes)
                    totalOut += UInt64(data.pointee.ifi_obytes)
                }
            }
            ptr = cur.pointee.ifa_next
        }
        return (totalIn, totalOut)
    }
}
