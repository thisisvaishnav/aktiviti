import SwiftUI
import SystemMetrics

struct StorageCardView: View {
    let disk: DiskMetrics?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Storage", systemImage: "internaldrive")
                    .font(.headline)
                Spacer()
                if let disk {
                    Text("\(ByteFormatter.formatStorage(disk.usedBytes)) used of \(ByteFormatter.formatStorage(disk.totalBytes))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let disk {
                ProgressView(value: min(max(disk.usedPercent / 100.0, 0), 1.0))
                    .progressViewStyle(.linear)

                HStack {
                    Text("Used: \(ByteFormatter.formatStorage(disk.usedBytes))")
                    Spacer()
                    Text("Free: \(ByteFormatter.formatStorage(disk.availableBytes))")
                    Spacer()
                    Text("Total: \(ByteFormatter.formatStorage(disk.totalBytes))")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
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
