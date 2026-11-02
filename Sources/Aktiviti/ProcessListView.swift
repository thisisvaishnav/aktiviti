import SwiftUI
import SystemMetrics

struct ProcessListView: View {
    let processes: [ProcessMetrics]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Top RAM users")
                .font(.headline)
                .padding(.horizontal, 16)

            if processes.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    if isLoading {
                        ProgressView("Loading processes...")
                            .controlSize(.small)
                    } else {
                        Image(systemName: "cpu")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        Text("No Processes Available")
                            .font(.headline)
                        Text("Unable to retrieve top RAM processes.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List(processes, id: \.pid) { process in
                    ProcessRowView(process: process)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }
}
