import AppKit
import SwiftUI
import SystemMetrics

struct ProcessRowView: View {
    let process: ProcessMetrics

    var body: some View {
        HStack(spacing: 10) {
            let appIcon = NSRunningApplication(processIdentifier: process.pid)?.icon
                ?? NSWorkspace.shared.icon(for: .application)
            Image(nsImage: appIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)

            Text(process.name)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Text(ByteFormatter.formatMemory(process.bytes))
                .font(.body)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
