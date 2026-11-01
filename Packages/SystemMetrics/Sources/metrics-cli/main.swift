import Foundation
import SystemMetrics

func formatBytes(_ bytes: UInt64) -> String {
    let gb = Double(bytes) / 1_073_741_824.0
    if gb >= 1.0 {
        return String(format: "%.2f GB", gb)
    }
    let mb = Double(bytes) / 1_048_576.0
    return String(format: "%.1f MB", mb)
}

func formatBytes(_ bytes: Int64) -> String {
    formatBytes(UInt64(max(0, bytes)))
}

func padRight(_ string: String, toLength length: Int) -> String {
    if string.count >= length {
        return string
    }
    return string + String(repeating: " ", count: length - string.count)
}

print("=== System Metrics CLI ===")
print("Sampling CPU ticks baseline...")
let cpuSampler = CPUSampler()
_ = cpuSampler.sample()

print("Waiting 1 second for CPU delta...")
Thread.sleep(forTimeInterval: 1.0)

let snapshot = SystemSnapshot.capture(cpuSampler: cpuSampler, topProcessLimit: 10)

print("\n--- CPU Usage ---")
if let cpu = snapshot.cpu {
    print(String(format: "Total CPU Usage: %.1f%%", cpu.totalUsage))
    print("Per-core breakdown:")
    for (index, corePercent) in cpu.perCoreUsage.enumerated() {
        print(String(format: "  Core %2d: %5.1f%%", index, corePercent))
    }
} else {
    print("CPU data unavailable")
}

print("\n--- RAM Usage ---")
let ram = snapshot.ram
print("Total Memory:      \(formatBytes(ram.totalBytes))")
print(String(format: "Used Memory:       %@ (%.1f%%)", formatBytes(ram.usedBytes), ram.usedPercent))
print("Free Memory:       \(formatBytes(ram.freeBytes))")
print("Compressed Memory: \(formatBytes(ram.compressedBytes))")
print("Memory Pressure:   \(ram.pressureLevel.rawValue)")

print("\n--- Disk Usage (/) ---")
let disk = snapshot.disk
print("Total Capacity:    \(formatBytes(disk.totalBytes))")
print(String(format: "Used Space:        %@ (%.1f%%)", formatBytes(disk.usedBytes), disk.usedPercent))
print("Available Space:   \(formatBytes(disk.availableBytes))")

print("\n--- Top 10 Processes by Memory Footprint ---")
let hRank = padRight("Rank", toLength: 6)
let hPid = padRight("PID", toLength: 8)
let hName = padRight("Process Name", toLength: 32)
let hMem = "Physical Footprint"
print("\(hRank)  \(hPid)  \(hName)  \(hMem)")
print(String(repeating: "-", count: 68))

for (index, proc) in snapshot.topProcesses.enumerated() {
    let rankStr = String(format: "#%d", index + 1)
    let nameSnippet = proc.name.count > 32 ? String(proc.name.prefix(29)) + "..." : proc.name
    let rankCol = padRight(rankStr, toLength: 6)
    let pidCol = padRight(String(proc.pid), toLength: 8)
    let nameCol = padRight(nameSnippet, toLength: 32)
    let memCol = formatBytes(proc.bytes)
    print("\(rankCol)  \(pidCol)  \(nameCol)  \(memCol)")
}
print("==========================")
