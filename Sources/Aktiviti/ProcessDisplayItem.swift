import AppKit
import Foundation

/// Presentation model for a process row with pre-resolved icon, avoiding main-thread resolution during UI render.
public struct ProcessDisplayItem: Identifiable, @unchecked Sendable, Equatable {
    public let pid: pid_t
    public let name: String
    public let bytes: UInt64
    public let icon: NSImage

    public var id: pid_t { pid }

    public init(pid: pid_t, name: String, bytes: UInt64, icon: NSImage) {
        self.pid = pid
        self.name = name
        self.bytes = bytes
        self.icon = icon
    }

    public static func == (lhs: ProcessDisplayItem, rhs: ProcessDisplayItem) -> Bool {
        lhs.pid == rhs.pid && lhs.name == rhs.name && lhs.bytes == rhs.bytes
    }
}
