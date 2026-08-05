import Cocoa

struct DomainRule: Identifiable {
    let domain: String
    let profileId: String
    var id: String { domain }
}

enum SettingsTab: Hashable {
    case profiles
    case rules
    case neverAsk
}

class SettingsViewModel: ObservableObject {
    @Published var selectedTab: SettingsTab = .profiles
    @Published var visibleProfiles: [Profile] = []
    @Published var defaultProfileId: String?
    @Published var rules: [DomainRule] = []
    @Published var blockedHosts: [String] = []
    @Published var useProfileSymbolInMenuBar = false
    // Selection and edit state owned here so NSWindow keyDown can drive them
    @Published var profileSelection: Profile.ID?
    @Published var ruleSelection: String?
    @Published var blocklistSelection: String?
    @Published var editingProfileId: Profile.ID?

    private(set) var allDetectedProfiles: [Profile] = []

    var addableProfiles: [Profile] {
        let visibleIds = Set(visibleProfiles.map(\.id))
        return allDetectedProfiles.filter { !visibleIds.contains($0.id) }
    }

    var canRemoveVisibleProfile: Bool { visibleProfiles.count > 1 }

    init() { reload() }

    func reload() {
        allDetectedProfiles = ProfileDetector.detect()
        let config = ConfigStore.shared.config
        defaultProfileId = config.defaultProfileId
        useProfileSymbolInMenuBar = config.useProfileSymbolInMenuBar ?? false

        if let ids = config.visibleProfileIds {
            visibleProfiles = ids.compactMap { id in allDetectedProfiles.first(where: { $0.id == id }) }
        } else {
            visibleProfiles = allDetectedProfiles
        }

        rules = (config.rules ?? [:])
            .map { DomainRule(domain: $0.key, profileId: $0.value) }
            .sorted { $0.domain < $1.domain }
        blockedHosts = (config.blocklist ?? []).sorted()
    }

    // MARK: - Display names

    func displayName(for profile: Profile) -> String {
        ConfigStore.shared.config.displayNameOverrides?[profile.id] ?? profile.name
    }

    func setDisplayName(_ name: String, for profile: Profile) {
        var c = ConfigStore.shared.config
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed == profile.name {
            c.displayNameOverrides?.removeValue(forKey: profile.id)
        } else {
            if c.displayNameOverrides == nil { c.displayNameOverrides = [:] }
            c.displayNameOverrides![profile.id] = trimmed
        }
        ConfigStore.shared.config = c
        objectWillChange.send()
        refreshStatusMenu()
    }

    // MARK: - Profiles

    func move(from source: IndexSet, to dest: Int) {
        visibleProfiles.move(fromOffsets: source, toOffset: dest)
        saveVisibleProfiles()
    }

    func moveUp(_ profile: Profile) {
        guard let idx = visibleProfiles.firstIndex(where: { $0.id == profile.id }), idx > 0 else { return }
        visibleProfiles.swapAt(idx, idx - 1)
        saveVisibleProfiles()
    }

    func moveDown(_ profile: Profile) {
        guard let idx = visibleProfiles.firstIndex(where: { $0.id == profile.id }),
              idx < visibleProfiles.count - 1 else { return }
        visibleProfiles.swapAt(idx, idx + 1)
        saveVisibleProfiles()
    }

    func remove(_ profile: Profile) {
        guard canRemoveVisibleProfile else { return }
        visibleProfiles.removeAll { $0.id == profile.id }
        saveVisibleProfiles()
    }

    func add(_ profile: Profile) {
        visibleProfiles.append(profile)
        saveVisibleProfiles()
    }

    func setDefault(_ profile: Profile) {
        defaultProfileId = profile.id
        ConfigStore.shared.setDefault(profileId: profile.id)
        refreshStatusMenu()
    }

    func setUseProfileSymbolInMenuBar(_ enabled: Bool) {
        useProfileSymbolInMenuBar = enabled
        ConfigStore.shared.setUseProfileSymbolInMenuBar(enabled)
        (NSApp.delegate as? AppDelegate)?.statusBar?.refreshAppearance()
    }

    private func saveVisibleProfiles() {
        var c = ConfigStore.shared.config
        c.visibleProfileIds = visibleProfiles.map(\.id)
        ConfigStore.shared.config = c
        refreshStatusMenu()
    }

    // MARK: - Rules

    func setRuleProfile(_ rule: DomainRule, profileId: String) {
        ConfigStore.shared.setRule(host: rule.domain, profileId: profileId)
        if let idx = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[idx] = DomainRule(domain: rule.domain, profileId: profileId)
        }
        refreshStatusMenu()
    }

    func removeRule(_ rule: DomainRule) {
        ConfigStore.shared.removeRule(host: rule.domain)
        rules.removeAll { $0.id == rule.id }
        refreshStatusMenu()
    }

    func removeBlockedHost(_ host: String) {
        ConfigStore.shared.removeFromBlocklist(host: host)
        blockedHosts.removeAll { $0 == host }
        refreshStatusMenu()
    }

    // MARK: - Display name for a rule's target profile

    func profileName(for profileId: String) -> String {
        let profile = allDetectedProfiles.first(where: { $0.id == profileId })
        return profile.map { displayName(for: $0) } ?? profileId
    }

    private func refreshStatusMenu() {
        (NSApp.delegate as? AppDelegate)?.statusBar?.rebuildMenu()
    }
}
