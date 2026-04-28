import SwiftUI

struct PortGroupHeaderView: View {
    let group: PortGroup
    let count: Int

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: group.icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(group.color)
            Text(group.rawValue)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
            Text("\(count)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.quaternary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 3)
    }
}
