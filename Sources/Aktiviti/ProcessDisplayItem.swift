import AppKit
import Foundation

/// Presentation model for a process row with pre-resolved icon, avoiding main-thread resolution during UI render.
public struct ProcessDisplayItem: Identifiable, @unchecked Sendable, Equatable {
    public let pid: pid_t
    public let name: String
    public let bytes: UInt64
    public let icon: NSImage
    public let powerMilliwatts: Double
    public let cpuPercent: Double
    public let diskBytesPerSec: Double
    public let networkBytesPerSec: Double
    public let gpuPercent: Double
    public let processCount: Int
    public let subtitle: String

    public var id: pid_t { pid }

    public init(
        pid: pid_t,
        name: String,
        bytes: UInt64,
        icon: NSImage,
        powerMilliwatts: Double = 0.0,
        cpuPercent: Double = 0.0,
        diskBytesPerSec: Double = 0.0,
        networkBytesPerSec: Double = 0.0,
        gpuPercent: Double = 0.0,
        processCount: Int = 1,
        subtitle: String = ""
    ) {
        self.pid = pid
        self.name = name
        self.bytes = bytes
        self.icon = icon
        self.powerMilliwatts = powerMilliwatts
        self.cpuPercent = cpuPercent
        self.diskBytesPerSec = diskBytesPerSec
        self.networkBytesPerSec = networkBytesPerSec
        self.gpuPercent = gpuPercent
        self.processCount = processCount
        self.subtitle = subtitle
    }

    public static func == (lhs: ProcessDisplayItem, rhs: ProcessDisplayItem) -> Bool {
        lhs.pid == rhs.pid && lhs.name == rhs.name && lhs.bytes == rhs.bytes && lhs.cpuPercent == rhs.cpuPercent
    }
}
