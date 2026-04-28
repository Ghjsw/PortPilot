import SwiftUI

struct PortListView: View {
    @ObservedObject var viewModel: PortListViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBarView(text: $viewModel.searchText)
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Port list
            if viewModel.groupedPorts.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(viewModel.groupedPorts, id: \.0.id) { group, ports in
                            Section {
                                ForEach(ports) { port in
                                    PortRowView(
                                        port: port,
                                        onKill: { viewModel.confirmKill(port) },
                                        onForceKill: { viewModel.killPort(port, force: true) },
                                        onCopy: { viewModel.copyPortNumber(port.port) },
                                        onOpen: { viewModel.openInBrowser(port.port) }
                                    )
                                }
                            } header: {
                                PortGroupHeaderView(group: group, count: ports.count)
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                }
            }

            // Error message
            if let error = viewModel.errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                    Text(error)
                        .font(.system(size: 10))
                }
                .foregroundStyle(.red.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
            }

            // Bottom bar
            VStack(spacing: 0) {
                Divider()
                BottomBarView(
                    isRefreshing: viewModel.isRefreshing,
                    onRefresh: { viewModel.refreshPorts() },
                    onKillAll: { viewModel.killAllPorts() },
                    onSettings: { viewModel.showSettings = true },
                    onQuit: { NSApp.terminate(nil) }
                )
            }
        }
        .frame(
            minWidth: Constants.Defaults.popoverWidth,
            idealWidth: Constants.Defaults.popoverWidth,
            minHeight: 400,
            idealHeight: Constants.Defaults.popoverHeight
        )
        .alert("Kill Process", isPresented: $viewModel.showKillConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.portToKill = nil
            }
            Button("Kill (SIGTERM)", role: .destructive) {
                viewModel.executeConfirmedKill()
            }
            Button("Force Kill (SIGKILL)", role: .destructive) {
                if let port = viewModel.portToKill {
                    viewModel.killPort(port, force: true)
                }
            }
        } message: {
            if let port = viewModel.portToKill {
                Text("Kill \(port.processName) (PID: \(port.pid)) on port \(port.port)?")
            }
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView(viewModel: viewModel)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "network")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.quaternary)
            Text(viewModel.isRefreshing ? "Scanning..." : "No listening ports")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
