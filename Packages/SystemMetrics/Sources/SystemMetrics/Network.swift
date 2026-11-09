import Darwin
import Foundation
import CoreWLAN

/// Snapshot of network metrics.
public struct NetworkMetrics: Sendable, Equatable {
    public let downloadRateBytesPerSec: Double
    public let uploadRateBytesPerSec: Double
    public let totalInBytes: UInt64
    public let totalOutBytes: UInt64
    public let todayBytes: UInt64
    public let last7DaysBytes: UInt64
    public let activeInterfaceName: String
    public let linkSpeedMbps: Double?
    public let wifiBandString: String?

    public init(
        downloadRateBytesPerSec: Double,
        uploadRateBytesPerSec: Double,
        totalInBytes: UInt64,
        totalOutBytes: UInt64,
        todayBytes: UInt64,
        last7DaysBytes: UInt64,
        activeInterfaceName: String = "en0",
        linkSpeedMbps: Double? = nil,
        wifiBandString: String? = nil
    ) {
        self.downloadRateBytesPerSec = downloadRateBytesPerSec
        self.uploadRateBytesPerSec = uploadRateBytesPerSec
        self.totalInBytes = totalInBytes
        self.totalOutBytes = totalOutBytes
        self.todayBytes = todayBytes
        self.last7DaysBytes = last7DaysBytes
        self.activeInterfaceName = activeInterfaceName
        self.linkSpeedMbps = linkSpeedMbps
        self.wifiBandString = wifiBandString
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

    // Caching Wi-Fi details avoids expensive CoreWLAN IPC on every single tick
    private var cachedWiFiDetails: (Double?, String?) = (nil, nil)
    private var wiFiTickCounter: Int = 0
    private var lastWiFiInterface: String = ""

    public init() {
        let (inBytes, outBytes, _) = Self.readRawTotals()
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
        let (currentIn, currentOut, primaryIface) = Self.readRawTotals()

        // Periodically refresh Wi-Fi parameters every 15 ticks (30s) or on interface change
        if wiFiTickCounter % 15 == 0 || primaryIface != lastWiFiInterface || cachedWiFiDetails == (nil, nil) {
            cachedWiFiDetails = Self.readWiFiDetails(primaryIface: primaryIface)
            lastWiFiInterface = primaryIface
        }
        wiFiTickCounter += 1

        let (linkSpeed, bandStr) = cachedWiFiDetails

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
                todayBytes: currentIn,
                last7DaysBytes: currentIn + currentOut,
                activeInterfaceName: primaryIface,
                linkSpeedMbps: linkSpeed,
                wifiBandString: bandStr
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

        return NetworkMetrics(
            downloadRateBytesPerSec: downloadRate,
            uploadRateBytesPerSec: uploadRate,
            totalInBytes: currentIn,
            totalOutBytes: currentOut,
            todayBytes: currentIn + currentOut,
            last7DaysBytes: (currentIn + currentOut) * 2,
            activeInterfaceName: primaryIface,
            linkSpeedMbps: linkSpeed,
            wifiBandString: bandStr
        )
    }

    private static func readRawTotals() -> (UInt64, UInt64, String) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else {
            return (0, 0, "en0")
        }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        var topIface = "en0"
        var maxBytes: UInt64 = 0

        while let cur = ptr {
            if cur.pointee.ifa_addr != nil && cur.pointee.ifa_addr.pointee.sa_family == AF_LINK {
                let name = String(cString: cur.pointee.ifa_name)
                // Real physical/wireless interfaces
                if !name.hasPrefix("lo"), let ifaData = cur.pointee.ifa_data {
                    let data = ifaData.assumingMemoryBound(to: if_data.self)
                    let ibytes = UInt64(data.pointee.ifi_ibytes)
                    let obytes = UInt64(data.pointee.ifi_obytes)
                    totalIn += ibytes
                    totalOut += obytes
                    if ibytes + obytes > maxBytes {
                        maxBytes = ibytes + obytes
                        topIface = name
                    }
                }
            }
            ptr = cur.pointee.ifa_next
        }
        return (totalIn, totalOut, topIface)
    }

    private static func readWiFiDetails(primaryIface: String) -> (Double?, String?) {
        guard let iface = CWWiFiClient.shared().interface() else {
            return (nil, nil)
        }
        let speed = iface.transmitRate() > 0 ? iface.transmitRate() : nil
        var bandStr: String? = nil
        if let chan = iface.wlanChannel() {
            switch chan.channelBand {
            case .band2GHz: bandStr = "2.4 GHz"
            case .band5GHz: bandStr = "5 GHz"
            case .band6GHz: bandStr = "6 GHz"
            default: bandStr = nil
            }
        }
        return (speed, bandStr)
    }
}
