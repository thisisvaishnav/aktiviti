import Foundation

/// Snapshot of disk space metrics for a filesystem path.
public struct DiskMetrics: Sendable, Equatable {
    public let totalBytes: Int64
    public let availableBytes: Int64
    public let usedBytes: Int64

    public init(totalBytes: Int64, availableBytes: Int64, usedBytes: Int64) {
        self.totalBytes = totalBytes
        self.availableBytes = availableBytes
        self.usedBytes = usedBytes
    }

    /// Used disk space as a percentage of total capacity (0.0 - 100.0).
    public var usedPercent: Double {
        totalBytes > 0 ? (Double(usedBytes) / Double(totalBytes)) * 100.0 : 0.0
    }
}

/// Reads filesystem space metrics using URLResourceValues.
public enum DiskReader {
    public static func read(path: String = "/") -> DiskMetrics {
        let url = URL(fileURLWithPath: path)
        let values = try? url.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ])

        let total = Int64(values?.volumeTotalCapacity ?? 0)
        let available = values?.volumeAvailableCapacityForImportantUsage ?? 0
        let used = max(0, total - available)

        return DiskMetrics(
            totalBytes: total,
            availableBytes: available,
            usedBytes: used
        )
    }
}
