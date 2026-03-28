import SwiftUI

private let profileRowHeight: CGFloat = 40
private let ruleRowHeight: CGFloat = 36

struct SettingsView: View {
    @ObservedObject var vm: SettingsViewModel

    var body: some View {
        VStack(spacing: 0) {
            // ── Profiles ──────────────────────────────────────────
            SectionHeader(title: "Visible Profiles") {
                Menu {
                    ForEach(vm.addableProfiles) { p in
                        Button(vm.displayName(for: p)) { vm.add(p) }
                    }
                    if vm.addableProfiles.isEmpty {
                        Text("All profiles visible").foregroundStyle(.secondary)
                    }
                } label: {
                    Image(systemName: "plus").frame(width: 24, height: 24)
                }
                .menuStyle(.borderlessButton)
                .disabled(vm.addableProfiles.isEmpty)
            }

            List(selection: $vm.profileSelection) {
                ForEach(vm.visibleProfiles) { profile in
                    ProfileRow(profile: profile, vm: vm)
                        .tag(profile.id)
                }
                .onMove { vm.move(from: $0, to: $1) }
            }
            .listStyle(.inset)
            .frame(height: max(80, CGFloat(vm.visibleProfiles.count) * profileRowHeight + 4))

            SectionFooter(hint: "⌘↑↓ reorder   Space default   ↩ rename") {
                if let id = vm.profileSelection,
                   let profile = vm.visibleProfiles.first(where: { $0.id == id }) {
                    Button("Remove") { vm.remove(profile); vm.profileSelection = nil }
                        .foregroundColor(.red).buttonStyle(.plain).font(.callout)
                }
            }

            Divider().padding(.vertical, 8)

            // ── Rules ─────────────────────────────────────────────
            SectionHeader(title: "Domain Rules") { EmptyView() }

            List(selection: $vm.ruleSelection) {
                if vm.rules.isEmpty {
                    Text("No remembered rules.")
                        .foregroundStyle(.secondary).font(.callout)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(vm.rules) { rule in
                        RuleRow(domain: rule.domain, profileName: vm.profileName(for: rule.profileId))
                            .tag(rule.domain)
                    }
                }
            }
            .listStyle(.inset)
            .frame(height: max(50, CGFloat(max(vm.rules.count, 1)) * ruleRowHeight + 4))

            SectionFooter(hint: "⌫ to remove") {
                if let domain = vm.ruleSelection,
                   let rule = vm.rules.first(where: { $0.domain == domain }) {
                    Button("Remove") { vm.removeRule(rule); vm.ruleSelection = nil }
                        .foregroundColor(.red).buttonStyle(.plain).font(.callout)
                }
            }
        }
        .padding(16)
        .frame(width: 480)
        .safeAreaInset(edge: .bottom) {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
            Text("Version \(version)")
                .font(.caption2).foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 16).padding(.bottom, 10)
        }
        .onDeleteCommand {
            if let id = vm.profileSelection,
               let p = vm.visibleProfiles.first(where: { $0.id == id }) {
                vm.remove(p); vm.profileSelection = nil
            } else if let domain = vm.ruleSelection,
                      let rule = vm.rules.first(where: { $0.domain == domain }) {
                vm.removeRule(rule); vm.ruleSelection = nil
            }
        }
    }
}

// MARK: - Profile row

private struct ProfileRow: View {
    let profile: Profile
    @ObservedObject var vm: SettingsViewModel

    @State private var editText = ""
    @FocusState private var fieldFocused: Bool

    private var isEditing: Bool { vm.editingProfileId == profile.id }
    private var displayName: String { vm.displayName(for: profile) }
    private var isDefault: Bool { vm.defaultProfileId == profile.id }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary).font(.caption).frame(width: 16)

            if isEditing {
                TextField("", text: $editText)
                    .textFieldStyle(.roundedBorder)
                    .focused($fieldFocused)
                    .onSubmit { commit() }
                    .onExitCommand { vm.editingProfileId = nil }
            } else {
                Text(displayName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // simultaneousGesture lets double-click fire alongside List's single-click selection
                    .simultaneousGesture(TapGesture(count: 2).onEnded { beginEdit() })

                Text(profile.browserApp)
                    .font(.caption).foregroundStyle(.secondary)

                Button(action: { vm.setDefault(profile) }) {
                    Image(systemName: isDefault ? "star.fill" : "star")
                        .foregroundStyle(isDefault ? Color.yellow : Color.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
        .onChange(of: isEditing) { editing in
            if editing {
                editText = displayName
                // Defer focus assignment until TextField is in the view hierarchy
                DispatchQueue.main.async { fieldFocused = true }
            }
        }
        .contextMenu {
            Button("Rename") { beginEdit() }
            Button(isDefault ? "Default ✓" : "Set as Default") { vm.setDefault(profile) }
        }
    }

    private func beginEdit() {
        editText = displayName
        vm.editingProfileId = profile.id
    }

    private func commit() {
        vm.setDisplayName(editText, for: profile)
        vm.editingProfileId = nil
    }
}

// MARK: - Rule row

private struct RuleRow: View {
    let domain: String
    let profileName: String

    var body: some View {
        HStack {
            Text(domain).frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "arrow.right").foregroundStyle(.secondary).font(.caption)
            Text(profileName).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Layout helpers

private struct SectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
            Spacer()
            trailing()
        }
        .padding(.bottom, 4)
    }
}

private struct SectionFooter<Leading: View>: View {
    let hint: String
    @ViewBuilder let leading: () -> Leading

    var body: some View {
        HStack {
            leading()
            Spacer()
            Text(hint).font(.caption2).foregroundStyle(.tertiary)
        }
        .frame(height: 24).padding(.top, 4)
    }
}
