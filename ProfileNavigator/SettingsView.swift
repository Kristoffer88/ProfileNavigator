import SwiftUI

private let settingsWidth: CGFloat = 680
private let settingsHeight: CGFloat = 520
private let profileRowHeight: CGFloat = 40

struct SettingsView: View {
    @ObservedObject var vm: SettingsViewModel

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $vm.selectedTab) {
                ProfilesSettingsPane(vm: vm)
                    .tabItem { Label("Profiles", systemImage: "person.2") }
                    .tag(SettingsTab.profiles)

                RulesSettingsPane(vm: vm)
                    .tabItem { Label("Rules", systemImage: "link") }
                    .tag(SettingsTab.rules)

                NeverAskSettingsPane(vm: vm)
                    .tabItem { Label("Never Ask", systemImage: "hand.raised") }
                    .tag(SettingsTab.neverAsk)
            }
            .padding(20)

            Divider()

            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
            HStack {
                Text("Profile Navigator")
                Spacer()
                Text("Version \(version)")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .frame(width: settingsWidth, height: settingsHeight)
        .onDeleteCommand { deleteCurrentSelection() }
    }

    private func deleteCurrentSelection() {
        switch vm.selectedTab {
        case .profiles:
            if let id = vm.profileSelection,
               let profile = vm.visibleProfiles.first(where: { $0.id == id }) {
                vm.remove(profile)
                vm.profileSelection = nil
            }
        case .rules:
            if let domain = vm.ruleSelection,
               let rule = vm.rules.first(where: { $0.domain == domain }) {
                vm.removeRule(rule)
                vm.ruleSelection = nil
            }
        case .neverAsk:
            if let host = vm.blocklistSelection {
                vm.removeBlockedHost(host)
                vm.blocklistSelection = nil
            }
        }
    }
}

// MARK: - Profiles

private struct ProfilesSettingsPane: View {
    @ObservedObject var vm: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsIntro(
                title: "Visible Profiles",
                text: "Choose which browser profiles appear in the picker. Drag to reorder; the starred profile is selected by default."
            )

            HStack {
                Menu {
                    ForEach(vm.addableProfiles) { profile in
                        Button(vm.displayName(for: profile)) { vm.add(profile) }
                    }
                    if vm.addableProfiles.isEmpty {
                        Text("All profiles are visible").foregroundStyle(.secondary)
                    }
                } label: {
                    Label("Add Profile", systemImage: "plus")
                }
                .disabled(vm.addableProfiles.isEmpty)

                Button(role: .destructive) {
                    removeSelectedProfile()
                } label: {
                    Label("Remove", systemImage: "minus")
                }
                .disabled(vm.profileSelection == nil)

                Spacer()

                Text("⌘↑/⌘↓ reorder · Space default · Return rename")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Toggle("Use profile symbol in the menu bar", isOn: Binding(
                get: { vm.useProfileSymbolInMenuBar },
                set: { vm.setUseProfileSymbolInMenuBar($0) }
            ))
            .help("Off by default. When enabled, the macOS menu bar status item uses a profile-themed symbol instead of the browser symbol.")

            List(selection: $vm.profileSelection) {
                ForEach(vm.visibleProfiles) { profile in
                    ProfileRow(profile: profile, vm: vm)
                        .tag(profile.id)
                }
                .onMove { vm.move(from: $0, to: $1) }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .frame(height: max(120, CGFloat(max(vm.visibleProfiles.count, 1)) * profileRowHeight + 16))

            Spacer()
        }
    }

    private func removeSelectedProfile() {
        guard let id = vm.profileSelection,
              let profile = vm.visibleProfiles.first(where: { $0.id == id }) else { return }
        vm.remove(profile)
        vm.profileSelection = nil
    }
}

private struct ProfileRow: View {
    let profile: Profile
    @ObservedObject var vm: SettingsViewModel

    @State private var editText = ""
    @FocusState private var fieldFocused: Bool

    private var isEditing: Bool { vm.editingProfileId == profile.id }
    private var displayName: String { vm.displayName(for: profile) }
    private var isDefault: Bool { vm.defaultProfileId == profile.id }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
                .font(.caption)
                .frame(width: 18)

            if isEditing {
                TextField("Profile name", text: $editText)
                    .textFieldStyle(.roundedBorder)
                    .focused($fieldFocused)
                    .onSubmit { commit() }
                    .onExitCommand { vm.editingProfileId = nil }
            } else {
                Text(displayName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .simultaneousGesture(TapGesture(count: 2).onEnded { beginEdit() })

                Text(profile.browserApp)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Button(action: { vm.setDefault(profile) }) {
                    Image(systemName: isDefault ? "star.fill" : "star")
                        .foregroundStyle(isDefault ? Color.yellow : Color.secondary)
                }
                .buttonStyle(.plain)
                .help(isDefault ? "Default profile" : "Set as default")
            }
        }
        .padding(.vertical, 3)
        .onChange(of: isEditing) { editing in
            if editing {
                editText = displayName
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

// MARK: - Rules

private struct RulesSettingsPane: View {
    @ObservedObject var vm: SettingsViewModel
    @State private var searchText = ""

    private var filteredRules: [DomainRule] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return vm.rules }
        return vm.rules.filter { rule in
            rule.domain.lowercased().contains(query)
            || vm.profileName(for: rule.profileId).lowercased().contains(query)
        }
    }

    private var profileChoices: [Profile] {
        vm.visibleProfiles
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsIntro(
                title: "Remembered Rules",
                text: "Rules tell Profile Navigator to open matching domains or file paths with a specific profile."
            )

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search domains, paths, or profiles", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                if !searchText.isEmpty {
                    Button("Clear") { searchText = "" }
                        .buttonStyle(.borderless)
                }
            }

            Table(filteredRules, selection: $vm.ruleSelection) {
                TableColumn("Domain or Path") { rule in
                    Text(rule.domain)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(rule.domain)
                }
                .width(min: 260, ideal: 390)

                TableColumn("Profile") { rule in
                    Picker("Profile", selection: ruleProfileBinding(rule)) {
                        ForEach(profileChoices) { profile in
                            Text(vm.displayName(for: profile)).tag(profile.id)
                        }
                    }
                    .labelsHidden()
                    .controlSize(.small)
                    .frame(maxWidth: 160, alignment: .leading)
                    .help("Change profile for this rule")
                }
                .width(min: 130, ideal: 160, max: 190)

                TableColumn("") { rule in
                    Button(role: .destructive) {
                        remove(rule)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Delete rule")
                }
                .width(36)
            }
            .tableStyle(.bordered(alternatesRowBackgrounds: true))
            .overlay {
                if vm.rules.isEmpty {
                    EmptyStateView(
                        title: "No Remembered Rules",
                        systemImage: "link",
                        message: "Pick “This site” or “This page” when opening a link to create one."
                    )
                } else if filteredRules.isEmpty {
                    EmptyStateView(
                        title: "No Matches",
                        systemImage: "magnifyingglass",
                        message: "Try a different search term."
                    )
                }
            }

            HStack {
                Button(role: .destructive) {
                    removeSelectedRule()
                } label: {
                    Label("Delete Selected Rule", systemImage: "trash")
                }
                .disabled(vm.ruleSelection == nil)
                .keyboardShortcut(.delete, modifiers: [])

                Spacer()

                Text("Change profiles in the Profile column. Select a row and press Delete to remove it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func ruleProfileBinding(_ rule: DomainRule) -> Binding<String> {
        Binding(
            get: {
                vm.rules.first(where: { $0.id == rule.id })?.profileId ?? rule.profileId
            },
            set: { newProfileId in
                vm.setRuleProfile(rule, profileId: newProfileId)
            }
        )
    }

    private func remove(_ rule: DomainRule) {
        vm.removeRule(rule)
        if vm.ruleSelection == rule.domain { vm.ruleSelection = nil }
    }

    private func removeSelectedRule() {
        guard let domain = vm.ruleSelection,
              let rule = vm.rules.first(where: { $0.domain == domain }) else { return }
        remove(rule)
    }
}

// MARK: - Never Ask

private struct NeverAskSettingsPane: View {
    @ObservedObject var vm: SettingsViewModel
    @State private var searchText = ""

    private var blockedRows: [BlockedHostRow] {
        let rows = vm.blockedHosts.map(BlockedHostRow.init)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return rows }
        return rows.filter { $0.host.lowercased().contains(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsIntro(
                title: "Never Ask",
                text: "Hosts in this list bypass the picker. Remove a host if you want Profile Navigator to ask again."
            )

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search hosts", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                if !searchText.isEmpty {
                    Button("Clear") { searchText = "" }
                        .buttonStyle(.borderless)
                }
            }

            Table(blockedRows, selection: $vm.blocklistSelection) {
                TableColumn("Host") { row in
                    Text(row.host)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(row.host)
                }

                TableColumn("") { row in
                    Button(role: .destructive) {
                        remove(row.host)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Remove host")
                }
                .width(36)
            }
            .tableStyle(.bordered(alternatesRowBackgrounds: true))
            .overlay {
                if vm.blockedHosts.isEmpty {
                    EmptyStateView(
                        title: "No Blocked Hosts",
                        systemImage: "hand.raised",
                        message: "Use “Never” in the picker to add a host here."
                    )
                } else if blockedRows.isEmpty {
                    EmptyStateView(
                        title: "No Matches",
                        systemImage: "magnifyingglass",
                        message: "Try a different search term."
                    )
                }
            }

            HStack {
                Button(role: .destructive) {
                    removeSelectedHost()
                } label: {
                    Label("Remove Selected Host", systemImage: "trash")
                }
                .disabled(vm.blocklistSelection == nil)
                .keyboardShortcut(.delete, modifiers: [])

                Spacer()
            }
        }
    }

    private func remove(_ host: String) {
        vm.removeBlockedHost(host)
        if vm.blocklistSelection == host { vm.blocklistSelection = nil }
    }

    private func removeSelectedHost() {
        guard let host = vm.blocklistSelection else { return }
        remove(host)
    }
}

private struct BlockedHostRow: Identifiable {
    let host: String
    var id: String { host }

    init(_ host: String) {
        self.host = host
    }
}

// MARK: - Shared UI

private struct SettingsIntro: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .padding()
    }
}
