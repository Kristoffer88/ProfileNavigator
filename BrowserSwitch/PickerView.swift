import SwiftUI

struct PickerView: View {
    let url: URL
    @ObservedObject var state: PickerState

    var displayURL: String {
        if url.scheme == "file" { return url.path }
        let host = url.host ?? url.absoluteString
        let path = url.path
        guard !path.isEmpty, path != "/" else { return host }
        return host + path
    }

    var body: some View {
        VStack(spacing: 0) {
            // URL strip
            HStack(spacing: 6) {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(displayURL)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            // Profile list
            VStack(spacing: 2) {
                ForEach(Array(state.profiles.enumerated()), id: \.element.id) { index, profile in
                    ProfileRow(
                        profile: profile,
                        index: index,
                        isSelected: state.selectedIndex == index
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        state.selectedIndex = index
                        state.confirm()
                    }
                }
            }
            .padding(8)

            Divider()

            // Remember mode footer
            HStack(spacing: 6) {
                ForEach(RememberMode.allCases, id: \.self) { mode in
                    RememberModeButton(mode: mode, isSelected: state.rememberMode == mode) {
                        state.rememberMode = mode
                    }
                }

                Spacer()

                Group {
                    hintKey("↑↓") + Text(" navigate  ")
                    hintKey("R") + Text(" remember  ")
                    hintKey("Esc") + Text(" cancel")
                }
                .font(.caption2)
                .foregroundColor(Color.secondary.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
        .frame(width: 340)
    }

    private func hintKey(_ label: String) -> Text {
        Text(label).fontWeight(.medium)
    }
}

private struct RememberModeButton: View {
    let mode: RememberMode
    let isSelected: Bool
    let action: () -> Void

    var label: String {
        switch mode {
        case .site:  return "This site"
        case .page:  return "This page"
        case .never: return "Just once"
        case .block: return "Never"
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
                )
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileRow: View {
    let profile: Profile
    let index: Int
    let isSelected: Bool

    var shortcutLabel: String { "\(index + 1)" }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(profile.name)
                    .fontWeight(isSelected ? .semibold : .regular)
                Text(profile.browserApp)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Number badge
            Text(shortcutLabel)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(isSelected ? .accentColor : Color.secondary.opacity(0.5))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        )
    }
}
