import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: PortListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }

            // Refresh interval
            VStack(alignment: .leading, spacing: 6) {
                Text("Refresh Interval")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Picker("", selection: $viewModel.refreshInterval) {
                    Text("2s").tag(2.0)
                    Text("5s").tag(5.0)
                    Text("10s").tag(10.0)
                    Text("30s").tag(30.0)
                    Text("Off").tag(Double.infinity)
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.refreshInterval) { _ in
                    viewModel.restartAutoRefresh()
                }
            }

            // Exclude system ports
            Toggle(isOn: $viewModel.excludeSystemPorts) {
                Text("Hide system ports")
                    .font(.system(size: 12))
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            // Excluded ports
            VStack(alignment: .leading, spacing: 6) {
                Text("Excluded Ports")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("22, 80, 443", text: excludedPortsText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .controlSize(.small)
            }
        }
        .padding(20)
        .frame(width: 280)
    }

    private var excludedPortsText: Binding<String> {
        Binding(
            get: {
                viewModel.excludedPorts.sorted().map(String.init).joined(separator: ", ")
            },
            set: {
                viewModel.excludedPorts = Set(
                    $0.split(separator: ",")
                        .compactMap { UInt16($0.trimmingCharacters(in: .whitespaces)) }
                )
            }
        )
    }
}
