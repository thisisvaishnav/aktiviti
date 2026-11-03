import Foundation

enum ByteFormatter {
    private static let storageFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        return formatter
    }()

    private static let memoryFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        return formatter
    }()

    static func formatStorage(_ bytes: Int64) -> String {
        storageFormatter.string(fromByteCount: bytes)
    }

    static func formatMemory(_ bytes: UInt64) -> String {
        memoryFormatter.string(fromByteCount: Int64(bytes))
    }

    static func formatMemory(_ bytes: Int64) -> String {
        memoryFormatter.string(fromByteCount: bytes)
    }

    static func formatBytes(_ bytes: UInt64, style: ByteCountFormatter.CountStyle = .file) -> String {
        if style == .memory {
            return memoryFormatter.string(fromByteCount: Int64(bytes))
        } else {
            return storageFormatter.string(fromByteCount: Int64(bytes))
        }
    }

    static func formatRate(_ bytesPerSec: Double) -> String {
        if bytesPerSec >= 1_000_000_000 {
            return String(format: "%.1f GB/s", bytesPerSec / 1_000_000_000.0)
        } else if bytesPerSec >= 1_000_000 {
            return String(format: "%.1f MB/s", bytesPerSec / 1_000_000.0)
        } else if bytesPerSec >= 1_000 {
            return String(format: "%.0f kB/s", bytesPerSec / 1_000.0)
        } else {
            return String(format: "%.0f B/s", bytesPerSec)
        }
    }

    static func formatTransferRate(_ bytesPerSec: UInt64) -> String {
        formatRate(Double(bytesPerSec))
    }

    static func formatWatts(_ watts: Double) -> String {
        if watts >= 1.0 {
            return String(format: "%.1f W", watts)
        } else {
            return String(format: "%.0f mW", watts * 1000.0)
        }
    }

    static func formatMilliwatts(_ mw: Double) -> String {
        if mw >= 1000.0 {
            return String(format: "%.1f W", mw / 1000.0)
        } else {
            return String(format: "%.0f mW", mw)
        }
    }
}
