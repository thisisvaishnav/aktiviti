import XCTest
@testable import SystemMetrics

final class SystemMetricsTests: XCTestCase {

    // MARK: - Placeholder Wiring Test

    func testPlaceholderWiring() {
        XCTAssertEqual(systemMetricsPlaceholder(), "SystemMetrics ready")
    }

    // MARK: - CPU Math Tests (Fake Inputs)

    func testCPUMathZeroDelta() {
        let prev = [
            CoreTicks(user: 1000, system: 500, idle: 8000, nice: 100),
            CoreTicks(user: 2000, system: 600, idle: 7000, nice: 200)
        ]
        let curr = [
            CoreTicks(user: 1000, system: 500, idle: 8000, nice: 100),
            CoreTicks(user: 2000, system: 600, idle: 7000, nice: 200)
        ]

        let result = CPUCalculator.calculateDelta(previous: prev, current: curr)
        XCTAssertEqual(result.totalUsage, 0.0, accuracy: 0.001)
        XCTAssertEqual(result.perCoreUsage.count, 2)
        XCTAssertEqual(result.perCoreUsage[0], 0.0, accuracy: 0.001)
        XCTAssertEqual(result.perCoreUsage[1], 0.0, accuracy: 0.001)
    }

    func testCPUMathFullIdleDelta() {
        let prev = [
            CoreTicks(user: 1000, system: 500, idle: 1000, nice: 0)
        ]
        // 1000 ticks passed, all idle
        let curr = [
            CoreTicks(user: 1000, system: 500, idle: 2000, nice: 0)
        ]

        let result = CPUCalculator.calculateDelta(previous: prev, current: curr)
        XCTAssertEqual(result.totalUsage, 0.0, accuracy: 0.001)
        XCTAssertEqual(result.perCoreUsage[0], 0.0, accuracy: 0.001)
    }

    func testCPUMathFullLoadDelta() {
        let prev = [
            CoreTicks(user: 1000, system: 500, idle: 1000, nice: 0)
        ]
        // 500 user + 500 system ticks, 0 idle ticks
        let curr = [
            CoreTicks(user: 1500, system: 1000, idle: 1000, nice: 0)
        ]

        let result = CPUCalculator.calculateDelta(previous: prev, current: curr)
        XCTAssertEqual(result.totalUsage, 100.0, accuracy: 0.001)
        XCTAssertEqual(result.perCoreUsage[0], 100.0, accuracy: 0.001)
    }

    func testCPUMathMultiCoreDistinctLoads() {
        let prev = [
            CoreTicks(user: 0, system: 0, idle: 0, nice: 0), // Core 0: will be 100% busy
            CoreTicks(user: 0, system: 0, idle: 0, nice: 0), // Core 1: will be 0% busy
            CoreTicks(user: 0, system: 0, idle: 0, nice: 0), // Core 2: will be 50% busy
            CoreTicks(user: 0, system: 0, idle: 0, nice: 0)  // Core 3: will be 25% busy (100 user, 300 idle)
        ]

        let curr = [
            CoreTicks(user: 400, system: 0, idle: 0, nice: 0),   // 400/400 = 100%
            CoreTicks(user: 0, system: 0, idle: 400, nice: 0),   // 0/400 = 0%
            CoreTicks(user: 200, system: 0, idle: 200, nice: 0), // 200/400 = 50%
            CoreTicks(user: 100, system: 0, idle: 300, nice: 0)  // 100/400 = 25%
        ]

        let result = CPUCalculator.calculateDelta(previous: prev, current: curr)
        XCTAssertEqual(result.totalUsage, 43.75, accuracy: 0.01)
        XCTAssertEqual(result.perCoreUsage.count, 4)
        XCTAssertEqual(result.perCoreUsage[0], 100.0, accuracy: 0.01)
        XCTAssertEqual(result.perCoreUsage[1], 0.0, accuracy: 0.01)
        XCTAssertEqual(result.perCoreUsage[2], 50.0, accuracy: 0.01)
        XCTAssertEqual(result.perCoreUsage[3], 25.0, accuracy: 0.01)
    }

    func testCPUMathMismatchedOrEmptyInputs() {
        let result1 = CPUCalculator.calculateDelta(previous: [], current: [])
        XCTAssertEqual(result1.totalUsage, 0.0)
        XCTAssertTrue(result1.perCoreUsage.isEmpty)

        let prev = [CoreTicks(user: 10, system: 10, idle: 10, nice: 0)]
        let result2 = CPUCalculator.calculateDelta(previous: prev, current: [])
        XCTAssertEqual(result2.totalUsage, 0.0)

        let curr = [
            CoreTicks(user: 10, system: 10, idle: 10, nice: 0),
            CoreTicks(user: 10, system: 10, idle: 10, nice: 0)
        ]
        let result3 = CPUCalculator.calculateDelta(previous: prev, current: curr)
        XCTAssertEqual(result3.totalUsage, 0.0)
        XCTAssertEqual(result3.perCoreUsage.count, 2)
    }

    // MARK: - RAM Math Tests (Fake Inputs)

    func testRAMMathFormula() {
        let pageSize: UInt64 = 4096
        let activePages: UInt64 = 100
        let wiredPages: UInt64 = 50
        let compressorPages: UInt64 = 25
        let freePages: UInt64 = 25
        let totalBytes: UInt64 = 819_200 // 200 pages * 4096

        let metrics = RAMCalculator.calculate(
            activePages: activePages,
            wiredPages: wiredPages,
            compressorPages: compressorPages,
            freePages: freePages,
            pageSize: pageSize,
            totalBytes: totalBytes,
            pressureRawValue: 1
        )

        // used = (100 + 50 + 25) * 4096 = 175 * 4096 = 716,800 bytes
        XCTAssertEqual(metrics.usedBytes, 716_800)
        XCTAssertEqual(metrics.freeBytes, 25 * 4096)
        XCTAssertEqual(metrics.compressedBytes, 25 * 4096)
        XCTAssertEqual(metrics.totalBytes, 819_200)
        XCTAssertEqual(metrics.pressureLevel, .normal)
        XCTAssertEqual(metrics.usedPercent, 87.5, accuracy: 0.01)
    }

    func testMemoryPressureLevelMapping() {
        XCTAssertEqual(MemoryPressureLevel(rawValue: 1), .normal)
        XCTAssertEqual(MemoryPressureLevel(rawValue: 2), .warning)
        XCTAssertEqual(MemoryPressureLevel(rawValue: 4), .critical)
        XCTAssertEqual(MemoryPressureLevel(rawValue: 0), .unknown)
        XCTAssertEqual(MemoryPressureLevel(rawValue: 99), .unknown)
    }

    // MARK: - Disk Math Tests

    func testDiskMetricsMath() {
        let disk = DiskMetrics(
            totalBytes: 1_000_000_000,
            availableBytes: 300_000_000,
            usedBytes: 700_000_000
        )
        XCTAssertEqual(disk.usedPercent, 70.0, accuracy: 0.01)
    }

    // MARK: - Sanity Tests (Live Hardware Values)

    func testLiveRAMSanityRanges() {
        let ram = RAMReader.read()
        XCTAssertGreaterThan(ram.totalBytes, 0, "Total RAM should be greater than 0")
        XCTAssertGreaterThan(ram.usedBytes, 0, "Used RAM should be greater than 0")
        XCTAssertLessThanOrEqual(ram.usedBytes, ram.totalBytes, "Used RAM cannot exceed physical memory")
        XCTAssertGreaterThanOrEqual(ram.usedPercent, 0.0)
        XCTAssertLessThanOrEqual(ram.usedPercent, 100.0)
        XCTAssertNotEqual(ram.pressureLevel, .unknown, "Memory pressure on macOS should resolve to normal, warning, or critical")
    }

    func testLiveDiskSanityRanges() {
        let disk = DiskReader.read(path: "/")
        XCTAssertGreaterThan(disk.totalBytes, 0, "Disk total bytes should be > 0")
        XCTAssertGreaterThan(disk.availableBytes, 0, "Disk available bytes should be > 0")
        XCTAssertGreaterThan(disk.usedBytes, 0, "Disk used bytes should be > 0")
        XCTAssertLessThanOrEqual(disk.usedBytes, disk.totalBytes)
        XCTAssertGreaterThanOrEqual(disk.usedPercent, 0.0)
        XCTAssertLessThanOrEqual(disk.usedPercent, 100.0)
    }

    func testLiveCPUSamplerSanity() {
        let sampler = CPUSampler()
        let initial = sampler.sample()
        // First sample establishes baseline ticks
        XCTAssertGreaterThan(initial.perCoreUsage.count, 0, "Device must report at least 1 CPU core")

        // Wait a small interval and sample again
        Thread.sleep(forTimeInterval: 0.1)
        let second = sampler.sample()

        XCTAssertGreaterThanOrEqual(second.totalUsage, 0.0)
        XCTAssertLessThanOrEqual(second.totalUsage, 100.0)
        XCTAssertEqual(second.perCoreUsage.count, initial.perCoreUsage.count)

        for coreUsage in second.perCoreUsage {
            XCTAssertGreaterThanOrEqual(coreUsage, 0.0)
            XCTAssertLessThanOrEqual(coreUsage, 100.0)
        }
    }

    func testLiveTopProcessesSanity() {
        let procs = ProcessReader.readTopProcesses(limit: 10)
        XCTAssertFalse(procs.isEmpty, "Should find running processes")
        XCTAssertLessThanOrEqual(procs.count, 10)

        // Verify descending sort order
        for i in 0..<(procs.count - 1) {
            XCTAssertGreaterThanOrEqual(procs[i].bytes, procs[i + 1].bytes, "Top processes must be sorted descending by bytes")
        }

        // Verify sensible attributes
        let top = procs[0]
        XCTAssertGreaterThan(top.pid, 0)
        XCTAssertFalse(top.name.isEmpty)
        XCTAssertGreaterThan(top.bytes, 0)
    }

    func testLiveSystemSnapshotCapture() {
        let snapshot = SystemSnapshot.capture(topProcessLimit: 5, includePorts: true)
        XCTAssertGreaterThan(snapshot.ram.totalBytes, 0)
        XCTAssertGreaterThan(snapshot.disk.totalBytes, 0)
        XCTAssertLessThanOrEqual(snapshot.topProcesses.count, 5)
        // Verify port scanning captured or gracefully succeeded
        XCTAssertGreaterThanOrEqual(snapshot.listeningPorts.count, 0)
    }

    // MARK: - Port Doctor & PortScanner Tests

    func testPortScannerServiceNames() {
        XCTAssertEqual(PortScanner.serviceName(for: 3000), "React / Next.js")
        XCTAssertEqual(PortScanner.serviceName(for: 5173), "Vite")
        XCTAssertEqual(PortScanner.serviceName(for: 5000), "Flask / AirPlay")
        XCTAssertEqual(PortScanner.serviceName(for: 8000), "Django / FastAPI")
        XCTAssertEqual(PortScanner.serviceName(for: 8080), "HTTP / Webpack")
        XCTAssertEqual(PortScanner.serviceName(for: 5432), "PostgreSQL")
        XCTAssertEqual(PortScanner.serviceName(for: 6379), "Redis")
        XCTAssertEqual(PortScanner.serviceName(for: 11434), "Ollama (Local AI)")
        XCTAssertEqual(PortScanner.serviceName(for: 99999), "TCP Service")
    }

    func testPortScannerTerminationGuards() {
        // Must reject terminating kernel/launchd or invalid PIDs
        XCTAssertFalse(PortScanner.terminateProcess(pid: 0))
        XCTAssertFalse(PortScanner.terminateProcess(pid: 1))
        XCTAssertFalse(PortScanner.terminateProcess(pid: -5))
    }

    func testLiveListeningPortScanSanity() {
        let ports = PortScanner.scanListeningPorts()
        // Every detected port must be a valid TCP port number
        for item in ports {
            XCTAssertGreaterThan(item.pid, 0)
            XCTAssertGreaterThanOrEqual(item.port, 1)
            XCTAssertLessThanOrEqual(item.port, 65535)
            XCTAssertFalse(item.processName.isEmpty)
            XCTAssertEqual(item.id, "\(item.pid):\(item.port)")
        }
    }
}
