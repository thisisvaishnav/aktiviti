import SwiftUI
import SystemMetrics

struct MemoryPressureBadge: View {
    let level: MemoryPressureLevel

    var color: Color {
        switch level {
        case .normal:
            return .green
        case .warning:
            return .yellow
        case .critical:
            return .red
        case .unknown:
            return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(level.rawValue)
                .font(.caption2.weight(.medium))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct MemoryCardView: View {
    let ram: RAMMetrics?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Memory", systemImage: "memorychip")
                    .font(.headline)
                Spacer()
                if let ram {
                    MemoryPressureBadge(level: ram.pressureLevel)
                }
            }

            if let ram {
                HStack {
                    Text("\(ByteFormatter.formatMemory(ram.usedBytes)) / \(ByteFormatter.formatMemory(ram.totalBytes))")
                        .font(.body.weight(.medium))
                        .monospacedDigit()
                    Spacer()
                    Text("Compressed: \(ByteFormatter.formatMemory(ram.compressedBytes))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                ProgressView(value: min(max(ram.usedPercent / 100.0, 0), 1.0))
                    .progressViewStyle(.linear)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
