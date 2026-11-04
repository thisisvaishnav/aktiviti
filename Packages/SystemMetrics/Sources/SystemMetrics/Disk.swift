import Foundation
import IOKit

/// Snapshot of disk space and I/O metrics for a filesystem path.
public struct DiskMetrics: Sendable, Equatable {
    public let totalBytes: Int64
    public let availableBytes: Int64
    public let usedBytes: Int64
    public let readRateBytesPerSec: Double
    public let writeRateBytesPerSec: Double
    public let writtenTodayBytes: UInt64
    public let totalWrittenBytes: UInt64
    public let totalReadBytes: UInt64
    public let volumeName: String
    public let volumeFormat: String

    public init(
        totalBytes: Int64,
        availableBytes: Int64,
        usedBytes: Int64,
        readRateBytesPerSec: Double = 0.0,
        writeRateBytesPerSec: Double = 0.0,
        writtenTodayBytes: UInt64 = 0,
        totalWrittenBytes: UInt64 = 0,
        totalReadBytes: UInt64 = 0,
        volumeName: String = "Macintosh HD",
        volumeFormat: String = "APFS"
    ) {
        self.totalBytes = totalBytes
        self.availableBytes = availableBytes
        self.usedBytes = usedBytes
        self.readRateBytesPerSec = readRateBytesPerSec
        self.writeRateBytesPerSec = writeRateBytesPerSec
        self.writtenTodayBytes = writtenTodayBytes
        self.totalWrittenBytes = totalWrittenBytes
        self.totalReadBytes = totalReadBytes
        self.volumeName = volumeName
        self.volumeFormat = volumeFormat
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
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeNameKey,
            .volumeLocalizedFormatDescriptionKey
        ])

        let total = Int64(values?.volumeTotalCapacity ?? 0)
        let available = values?.volumeAvailableCapacityForImportantUsage ?? 0
        let used = max(0, total - available)
        let volName = values?.volumeName ?? "Macintosh HD"
        let volFmt = values?.volumeLocalizedFormatDescription ?? "APFS"

        return DiskMetrics(
            totalBytes: total,
            availableBytes: available,
            usedBytes: used,
            volumeName: volName,
            volumeFormat: volFmt
        )
    }
}

/// Sampler for live disk read/write throughput via IOMedia statistics.
public final class DiskSampler: @unchecked Sendable {
    private let lock = NSLock()
    private var previousTime: Date?
    private var previousRead: UInt64 = 0
    private var previousWrite: UInt64 = 0

    public init() {
        let (r, w) = Self.readRawBlockIO()
        self.previousTime = Date()
        self.previousRead = r
        self.previousWrite = w
    }

    public func sample(path: String = "/") -> DiskMetrics {
        lock.lock()
        defer { lock.unlock() }

        let base = DiskReader.read(path: path)
        let now = Date()
        let (currentRead, currentWrite) = Self.readRawBlockIO()

        guard let prevTime = previousTime else {
            previousTime = now
            previousRead = currentRead
            previousWrite = currentWrite
            return DiskMetrics(
                totalBytes: base.totalBytes,
                availableBytes: base.availableBytes,
                usedBytes: base.usedBytes,
                readRateBytesPerSec: 0.0,
                writeRateBytesPerSec: 0.0,
                writtenTodayBytes: currentWrite,
                totalWrittenBytes: currentWrite,
                totalReadBytes: currentRead,
                volumeName: base.volumeName,
                volumeFormat: base.volumeFormat
            )
        }

        let elapsed = max(now.timeIntervalSince(prevTime), 0.001)
        let deltaRead = currentRead >= previousRead ? currentRead - previousRead : 0
        let deltaWrite = currentWrite >= previousWrite ? currentWrite - previousWrite : 0

        let readRate = Double(deltaRead) / elapsed
        let writeRate = Double(deltaWrite) / elapsed

        previousTime = now
        previousRead = currentRead
        previousWrite = currentWrite

        return DiskMetrics(
            totalBytes: base.totalBytes,
            availableBytes: base.availableBytes,
            usedBytes: base.usedBytes,
            readRateBytesPerSec: readRate,
            writeRateBytesPerSec: writeRate,
            writtenTodayBytes: currentWrite,
            totalWrittenBytes: currentWrite,
            totalReadBytes: currentRead,
            volumeName: base.volumeName,
            volumeFormat: base.volumeFormat
        )
    }

    private static func readRawBlockIO() -> (UInt64, UInt64) {
        let matching = IOServiceMatching("IOMedia")
        var iterator: io_iterator_t = 0
        var totalRead: UInt64 = 0
        var totalWritten: UInt64 = 0
        if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == kIOReturnSuccess {
            var service = IOIteratorNext(iterator)
            while service != 0 {
                var props: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == kIOReturnSuccess,
                   let dict = props?.takeRetainedValue() as? [String: Any],
                   let stats = dict["Statistics"] as? [String: Any] {
                    if let r = stats["Bytes read from block device"] as? NSNumber {
                        totalRead += r.uint64Value
                    }
                    if let w = stats["Bytes written to block device"] as? NSNumber {
                        totalWritten += w.uint64Value
                    }
                }
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
        return (totalRead, totalWritten)
    }
}
