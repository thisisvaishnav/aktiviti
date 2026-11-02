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
}
