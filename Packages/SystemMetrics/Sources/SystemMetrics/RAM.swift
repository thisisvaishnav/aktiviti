import Darwin
import Foundation
import MachO

/// System memory pressure level reported by macOS kernel.
public enum MemoryPressureLevel: String, Sendable, CaseIterable {
    case normal = "Normal"
    case warning = "Warning"
    case critical = "Critical"
    case unknown = "Unknown"

    public init(rawValue: Int32) {
        switch rawValue {
        case 1:
            self = .normal
        case 2:
            self = .warning
        case 4:
            self = .critical
        default:
            self = .unknown
        }
    }
}

/// Snapshot of system RAM usage.
public struct RAMMetrics: Sendable, Equatable {
    public let totalBytes: UInt64
    public let usedBytes: UInt64
    public let freeBytes: UInt64
    public let compressedBytes: UInt64
    public let pressureLevel: MemoryPressureLevel

    public init(
        totalBytes: UInt64,
        usedBytes: UInt64,
        freeBytes: UInt64,
        compressedBytes: UInt64,
        pressureLevel: MemoryPressureLevel
    ) {
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.freeBytes = freeBytes
        self.compressedBytes = compressedBytes
        self.pressureLevel = pressureLevel
    }

    /// Used memory as a percentage of total physical memory (0.0 - 100.0).
    public var usedPercent: Double {
        totalBytes > 0 ? (Double(usedBytes) / Double(totalBytes)) * 100.0 : 0.0
    }
}

/// Pure math helpers for RAM metric calculation.
public enum RAMCalculator {
    public static func calculate(
        activePages: UInt64,
        wiredPages: UInt64,
        compressorPages: UInt64,
        freePages: UInt64,
        pageSize: UInt64,
        totalBytes: UInt64,
        pressureRawValue: Int32
    ) -> RAMMetrics {
        let used = (activePages + wiredPages + compressorPages) * pageSize
        let free = freePages * pageSize
        let compressed = compressorPages * pageSize
        let pressure = MemoryPressureLevel(rawValue: pressureRawValue)

        return RAMMetrics(
            totalBytes: totalBytes,
            usedBytes: used,
            freeBytes: free,
            compressedBytes: compressed,
            pressureLevel: pressure
        )
    }
}

/// Reads live RAM metrics from host_statistics64 and sysctl.
public enum RAMReader {
    public static func read() -> RAMMetrics {
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &vmStats) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let totalBytes = ProcessInfo.processInfo.physicalMemory

        let activePages = result == KERN_SUCCESS ? UInt64(vmStats.active_count) : 0
        let wiredPages = result == KERN_SUCCESS ? UInt64(vmStats.wire_count) : 0
        let compressorPages = result == KERN_SUCCESS ? UInt64(vmStats.compressor_page_count) : 0
        let freePages = result == KERN_SUCCESS ? UInt64(vmStats.free_count) : 0

        var pressureLevel: Int32 = 0
        var pressureSize = MemoryLayout<Int32>.size
        let sysctlResult = sysctlbyname("kern.memorystatus_vm_pressure_level", &pressureLevel, &pressureSize, nil, 0)
        let pressureValue = sysctlResult == 0 ? pressureLevel : 0

        return RAMCalculator.calculate(
            activePages: activePages,
            wiredPages: wiredPages,
            compressorPages: compressorPages,
            freePages: freePages,
            pageSize: pageSize,
            totalBytes: totalBytes,
            pressureRawValue: pressureValue
        )
    }
}
