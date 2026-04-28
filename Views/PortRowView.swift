import SwiftUI

struct PortRowView: View {
    let port: PortInfo
    let onKill: () -> Void
    let onForceKill: () -> Void
    let onCopy: () -> Void
    let onOpen: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            // Port number - prominent, monospaced
            Text("\(port.port)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
                .frame(width: 56, alignment: .trailing)

            // Process info
            VStack(alignment: .leading, spacing: 1) {
                Text(port.processName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                Text("\(port.pid) · \(port.displayAddress)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .padding(.leading, 10)

            Spacer()

            // Action buttons - hidden by default, appear on hover
            HStack(spacing: 2) {
                ActionButton(icon: "safari", tooltip: "Open in browser") { onOpen() }
                ActionButton(icon: "doc.on.doc", tooltip: "Copy port") { onCopy() }
                ActionButton(icon: "xmark", tooltip: "Kill process", isDestructive: true) { onKill() }
            }
            .opacity(isHovered ? 1 : 0)
            .offset(x: isHovered ? 0 : 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary.opacity(isHovered ? 1 : 0))
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Open in Browser") { onOpen() }
            Button("Copy Port Number") { onCopy() }
            Divider()
            Button("Kill Process (SIGTERM)") { onKill() }
            Button("Force Kill (SIGKILL)", role: .destructive) { onForceKill() }
        }
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let icon: String
    let tooltip: String
    var isDestructive = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isDestructive ? .red.opacity(0.7) : .secondary)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(isPressed ? (isDestructive ? Color.red.opacity(0.15) : Color.primary.opacity(0.08)) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
