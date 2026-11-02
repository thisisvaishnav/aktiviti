import SwiftUI
import SystemMetrics

struct CPUCardView: View {
    let cpu: CPUMetrics?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("CPU", systemImage: "cpu")
                    .font(.headline)
                Spacer()
                if let cpu {
                    Text(String(format: "%.1f%%", cpu.totalUsage))
                        .font(.body.weight(.medium))
                        .monospacedDigit()
                }
            }

            if let cpu {
                ProgressView(value: min(max(cpu.totalUsage / 100.0, 0), 1.0))
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
