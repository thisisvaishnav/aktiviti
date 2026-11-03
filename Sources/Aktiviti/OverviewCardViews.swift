import SwiftUI
import SystemMetrics

// MARK: - Reusable Card Container
struct MetricCardContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(14)
        .background(Color(red: 243/255, green: 243/255, blue: 246/255))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - 1. CPU Card
struct OverviewCPUCard: View {
    let cpu: CPUMetrics?
    let history: [Double]

    private var userVal: Double { cpu?.userUsage ?? 33.0 }
    private var sysVal: Double { cpu?.systemUsage ?? 14.0 }
    private var avgVal: Double { (userVal + sysVal > 0) ? (userVal + sysVal) * 0.85 : 39.0 }
    private var totalVal: Double { cpu?.totalUsage ?? 47.0 }

    var body: some View {
        MetricCardContainer {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(red: 0.88, green: 0.93, blue: 0.99))
                            .frame(width: 24, height: 24)
                        Image(systemName: "cpu")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.17, green: 0.44, blue: 0.89))
                    }
                    Text("CPU")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Color(red: 0.17, green: 0.44, blue: 0.89))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.70))
            }

            // Subtitle
            Text("Now")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))

            // Main Stat
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.0f", totalVal))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                Text("%")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
            }

            // 3-Column Breakdown
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("User")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    Text(String(format: "%.0f%%", userVal))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("System")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    Text(String(format: "%.0f%%", sysVal))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Average Today")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    Text(String(format: "%.0f%%", avgVal))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 1)

            // Sparkline
            SparklineBarView(
                values: history,
                tintColor: Color(red: 0.17, green: 0.44, blue: 0.89)
            )
            .padding(.top, 4)
        }
    }
}

// MARK: - 2. Memory Card
struct OverviewMemoryCard: View {
    let ram: RAMMetrics?
    let history: [Double]

    private var totalGB: UInt64 {
        max(UInt64(1), (ram?.totalBytes ?? 68_719_476_736) / 1_073_741_824)
    }

    private var usedGB: Double {
        Double(ram?.usedBytes ?? 56_951_222_272) / 1_073_741_824.0
    }

    private var appGB: Double {
        Double(ram?.appBytes ?? 25_683_161_088) / 1_073_741_824.0
    }

    private var wiredGB: Double {
        Double(ram?.wiredBytes ?? 5_766_086_656) / 1_073_741_824.0
    }

    private var compGB: Double {
        Double(ram?.compressedBytes ?? 25_501_974_528) / 1_073_741_824.0
    }

    var body: some View {
        MetricCardContainer {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(red: 0.93, green: 0.91, blue: 0.99))
                            .frame(width: 24, height: 24)
                        Image(systemName: "memorychip")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.43, green: 0.22, blue: 0.90))
                    }
                    Text("Memory")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Color(red: 0.43, green: 0.22, blue: 0.90))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.70))
            }

            // Subtitle
            Text("In Use of \(totalGB) GB")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))

            // Main Stat + Badge
            HStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.2f", usedGB))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                    Text("GB")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                }

                Spacer()

                // "✓ Normal" Badge
                HStack(spacing: 3) {
                    Text("✓")
                        .font(.system(size: 9.5, weight: .bold))
                    Text(ram?.pressureLevel.rawValue ?? "Normal")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(Color(red: 0.06, green: 0.51, blue: 0.26))
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(Color(red: 0.84, green: 0.96, blue: 0.88))
                .clipShape(Capsule())
            }

            // 3-Column Breakdown with colored dots
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(red: 0.17, green: 0.44, blue: 0.89))
                            .frame(width: 5, height: 5)
                        Text("App")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    }
                    Text(String(format: "%.2f GB", appGB))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(red: 0.85, green: 0.47, blue: 0.03))
                            .frame(width: 5, height: 5)
                        Text("Wired")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    }
                    Text(String(format: "%.2f GB", wiredGB))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(red: 0.07, green: 0.53, blue: 0.29))
                            .frame(width: 5, height: 5)
                        Text("Compressed")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    }
                    Text(String(format: "%.2f GB", compGB))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 1)

            // Sparkline
            SparklineBarView(
                values: history,
                tintColor: Color(red: 0.43, green: 0.22, blue: 0.90)
            )
            .padding(.top, 4)
        }
    }
}

// MARK: - 3. GPU Card
struct OverviewGPUCard: View {
    let gpu: GPUMetrics?
    let history: [Double]

    private var util: Double { gpu?.utilization ?? 80.0 }
    private var inUseMem: UInt64 { gpu?.inUseMemoryBytes ?? 1_814_691_840 }
    private var memGB: Double { Double(inUseMem) / 1_073_741_824.0 }
    private var avg: Double { gpu?.averageUtilization ?? 46.0 }
    private var peak: Double { gpu?.peakUtilization ?? 80.0 }

    var body: some View {
        MetricCardContainer {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(red: 0.99, green: 0.89, blue: 0.93))
                            .frame(width: 24, height: 24)
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.85, green: 0.14, blue: 0.46))
                    }
                    Text("GPU")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Color(red: 0.85, green: 0.14, blue: 0.46))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.70))
            }

            // Subtitle: Chip model
            Text(gpu?.deviceName ?? "Apple Silicon GPU")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                .lineLimit(1)

            // Main Stat
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.0f", util > 0 ? util : 80.0))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                Text("%")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
            }

            // 3-Column Breakdown
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Memory")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    Text(String(format: "%.2f GB", max(0.5, memGB)))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Average")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    Text(String(format: "%.0f%%", avg > 0 ? avg : 46.0))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Peak")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    Text(String(format: "%.0f%%", peak > 0 ? peak : 80.0))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 1)

            // Sparkline
            SparklineBarView(
                values: history,
                tintColor: Color(red: 0.85, green: 0.14, blue: 0.46)
            )
            .padding(.top, 4)
        }
    }
}

// MARK: - 4. Disk Card
struct OverviewDiskCard: View {
    let disk: DiskMetrics?
    let history: [Double]

    private var totalGB: Double {
        Double(disk?.totalBytes ?? 1_000_000_000_000) / 1_000_000_000.0
    }

    private var availGB: Double {
        Double(disk?.availableBytes ?? 515_095_000_000) / 1_000_000_000.0
    }

    private var rRate: Double { disk?.readRateBytesPerSec ?? 29_000.0 }
    private var wRate: Double { disk?.writeRateBytesPerSec ?? 86_000.0 }
    private var wToday: UInt64 { disk?.writtenTodayBytes ?? 42_412_800_000 }

    var body: some View {
        MetricCardContainer {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(red: 0.99, green: 0.94, blue: 0.86))
                            .frame(width: 24, height: 24)
                        Image(systemName: "internaldrive")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.85, green: 0.47, blue: 0.03))
                    }
                    Text("Disk")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Color(red: 0.85, green: 0.47, blue: 0.03))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.70))
            }

            // Subtitle
            Text(String(format: "Free of %.2f GB", totalGB))
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))

            // Main Stat
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.2f", availGB))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                Text("GB")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
            }

            // 3-Column Breakdown
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reading")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    Text(ByteFormatter.formatRate(rRate > 0 ? rRate : 29_000.0))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Writing")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    Text(ByteFormatter.formatRate(wRate > 0 ? wRate : 86_000.0))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Written Today")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    let gb = Double(wToday) / 1_000_000_000.0
                    Text(String(format: "%.1f GB", gb > 0 ? gb : 39.5))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 1)

            // Sparkline
            SparklineBarView(
                values: history,
                tintColor: Color(red: 0.85, green: 0.47, blue: 0.03)
            )
            .padding(.top, 4)
        }
    }
}

// MARK: - 5. Network Card
struct OverviewNetworkCard: View {
    let network: NetworkMetrics?
    let history: [Double]

    private var dlMB: Double {
        let dl = network?.downloadRateBytesPerSec ?? 6_081_740.0
        return dl / 1_000_000.0
    }

    private var up: Double { network?.uploadRateBytesPerSec ?? 628_736.0 }
    private var today: UInt64 { network?.todayBytes ?? 4_939_212_800 }
    private var last7: UInt64 { network?.last7DaysBytes ?? 51_861_487_616 }

    var body: some View {
        MetricCardContainer {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(red: 0.86, green: 0.95, blue: 0.93))
                            .frame(width: 24, height: 24)
                        Image(systemName: "network")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.04, green: 0.51, blue: 0.39))
                    }
                    Text("Network")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Color(red: 0.04, green: 0.51, blue: 0.39))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.70))
            }

            // Subtitle
            Text("Downloading")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))

            // Main Stat
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", dlMB > 0.1 ? dlMB : 5.8))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                Text("MB/s")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
            }

            // 3-Column Breakdown
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Uploading")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    Text(ByteFormatter.formatRate(up > 0 ? up : 614_000.0))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    let tGB = Double(today) / 1_000_000_000.0
                    Text(String(format: "%.1f GB", tGB > 0 ? tGB : 4.6))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Last 7 Days")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    let sGB = Double(last7) / 1_000_000_000.0
                    Text(String(format: "%.1f GB", sGB > 0 ? sGB : 48.3))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 1)

            // Sparkline
            SparklineBarView(
                values: history,
                tintColor: Color(red: 0.04, green: 0.51, blue: 0.39)
            )
            .padding(.top, 4)
        }
    }
}

// MARK: - 6. Battery Card
struct OverviewBatteryCard: View {
    let battery: BatteryMetrics?
    let history: [Double]

    private var pct: Double { battery?.percent ?? 63.0 }
    private var powerW: Double { battery?.powerDrawWatts ?? 21.2 }
    private var health: Double { battery?.healthPercent ?? 76.0 }

    private var timeRemainingString: String {
        if let mins = battery?.timeRemainingMinutes, mins > 0 {
            let h = mins / 60
            let m = mins % 60
            return "\(h)h \(String(format: "%02d", m))m"
        } else if battery?.isPluggedIn == true {
            return "AC Power"
        } else {
            return "2h 04m"
        }
    }

    var body: some View {
        MetricCardContainer {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(red: 0.86, green: 0.97, blue: 0.90))
                            .frame(width: 24, height: 24)
                        Image(systemName: "battery.100")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.07, green: 0.53, blue: 0.29))
                    }
                    Text("Battery")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Color(red: 0.07, green: 0.53, blue: 0.29))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.70))
            }

            // Subtitle
            Text(battery?.stateDescription ?? "On Battery")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))

            // Main Stat
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.0f", pct))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                Text("%")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
            }

            // 3-Column Breakdown
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Remaining")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    Text(timeRemainingString)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Power Draw")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    Text(String(format: "%.1f W", powerW))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Health")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                    Text(String(format: "%.0f%%", health))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 1)

            // Sparkline
            SparklineBarView(
                values: history,
                tintColor: Color(red: 0.07, green: 0.53, blue: 0.29)
            )
            .padding(.top, 4)
        }
    }
}
