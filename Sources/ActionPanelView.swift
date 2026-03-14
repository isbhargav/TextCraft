import SwiftUI

struct ActionPanelView: View {
    let onSelect: (AIAction) -> Void

    private var standardActions: [AIAction] {
        AIAction.allCases.filter { $0 != .custom }
    }

    var body: some View {
        VStack(spacing: 2) {
            ForEach(standardActions) { action in
                ActionButton(action: action) {
                    onSelect(action)
                }
            }

            Divider()
                .padding(.horizontal, 8)

            ActionButton(action: .custom) {
                onSelect(.custom)
            }
        }
        .padding(6)
        .frame(width: 220)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
        .fixedSize()
    }
}

struct ActionButton: View {
    let action: AIAction
    let onClick: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 10) {
                Image(systemName: action.icon)
                    .frame(width: 20)
                    .foregroundStyle(.secondary)
                Text(action.rawValue)
                    .font(.system(size: 13))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
