import AppKit
import SwiftUI

struct ProcessRowView: View {
    let process: ProcessDisplayItem

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: process.icon)
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
