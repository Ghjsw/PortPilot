import SwiftUI

struct BottomBarView: View {
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onKillAll: () -> Void
    let onSettings: () -> Void
    let onQuit: () -> Void

    @State private var isHoveringKillAll = false
    @State private var isHoveringQuit = false

    var body: some View {
        HStack(spacing: 0) {
            // Left: Refresh
            Button(action: onRefresh) {
                HStack(spacing: 4) {
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.4)
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .medium))
                    }
                    Text("Refresh")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("r", modifiers: .command)

            Spacer()

            // Center: Kill All
            Button(action: onKillAll) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                    Text("Kill All")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(isHoveringKillAll ? .red : Color(nsColor: .tertiaryLabelColor))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(isHoveringKillAll ? Color.red.opacity(0.1) : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .keyboardShortcut("k", modifiers: .command)
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.15)) {
                    isHoveringKillAll = hovering
                }
            }

            Spacer()

            // Right: Settings + Quit
            HStack(spacing: 14) {
                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(",", modifiers: .command)

                Button(action: onQuit) {
                    Image(systemName: "power")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isHoveringQuit ? .red : Color(nsColor: .tertiaryLabelColor))
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q", modifiers: .command)
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.15)) {
                        isHoveringQuit = hovering
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}
