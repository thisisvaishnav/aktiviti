import Foundation
import IOKit

/// Snapshot of GPU metrics.
public struct GPUMetrics: Sendable, Equatable {
    public let deviceName: String
    public let utilization: Double
    public let inUseMemoryBytes: UInt64
    public let allocatedMemoryBytes: UInt64
    public let averageUtilization: Double
    public let peakUtilization: Double
    public let coreCount: Int

    public init(
        deviceName: String,
        utilization: Double,
        inUseMemoryBytes: UInt64,
        allocatedMemoryBytes: UInt64,
        averageUtilization: Double,
        peakUtilization: Double,
        coreCount: Int = 0
    ) {
        self.deviceName = deviceName
        self.utilization = utilization
        self.inUseMemoryBytes = inUseMemoryBytes
        self.allocatedMemoryBytes = allocatedMemoryBytes
        self.averageUtilization = averageUtilization
        self.peakUtilization = peakUtilization
        self.coreCount = coreCount
    }
}

/// Reads GPU utilization and hardware model.
public final class GPUSampler: @unchecked Sendable {
    private let lock = NSLock()
    private var samples: [Double] = []
    private var peak: Double = 0.0
    private let cachedDeviceName: String

    public init() {
        self.cachedDeviceName = Self.readDeviceName()
    }

    public func sample() -> GPUMetrics {
        lock.lock()
        defer { lock.unlock() }

        var currentUtil: Double = 0.0
        var inUseMem: UInt64 = 0
        var allocMem: UInt64 = 0
        var coreCount = 0

        let matching = IOServiceMatching("IOAccelerator")
        var iterator: io_iterator_t = 0
        if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == kIOReturnSuccess {
            var service = IOIteratorNext(iterator)
            while service != 0 {
                var props: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == kIOReturnSuccess,
                   let dict = props?.takeRetainedValue() as? [String: Any] {
                    if let c = dict["gpu-core-count"] as? Int {
                        coreCount = max(coreCount, c)
                    }
                    if let stats = dict["PerformanceStatistics"] as? [String: Any] {
                        if let util = stats["Device Utilization %"] as? NSNumber {
                            currentUtil = max(currentUtil, util.doubleValue)
                        }
                        if let mem = stats["In use system memory"] as? NSNumber {
                            inUseMem = max(inUseMem, mem.uint64Value)
                        }
                        if let alloc = stats["Alloc system memory"] as? NSNumber {
                            allocMem = max(allocMem, alloc.uint64Value)
                        }
                    }
                }
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }

        samples.append(currentUtil)
        if samples.count > 60 {
            samples.removeFirst(samples.count - 60)
        }
        let avg = samples.isEmpty ? currentUtil : (samples.reduce(0.0, +) / Double(samples.count))
        peak = max(peak, currentUtil)

        return GPUMetrics(
            deviceName: cachedDeviceName,
            utilization: currentUtil,
            inUseMemoryBytes: inUseMem,
            allocatedMemoryBytes: allocMem,
            averageUtilization: avg,
            peakUtilization: peak,
            coreCount: coreCount
        )
    }

    private static func readDeviceName() -> String {
        var size: Int = 0
        if sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0) == 0, size > 0 {
            var brand = [CChar](repeating: 0, count: size)
            if sysctlbyname("machdep.cpu.brand_string", &brand, &size, nil, 0) == 0 {
                let name = String(cString: brand).trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty {
                    return name
                }
            }
        }
        return "Apple Silicon GPU"
    }
}
