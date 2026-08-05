import Cocoa

class URLHandler {
    static let shared = URLHandler()

    private var pickerController: PickerWindowController?

    func handle(url: URL) {
        let url = Self.unwrapSafeLinks(url) ?? url
        let config = ConfigStore.shared.config
        let host = url.host?.lowercased() ?? ""
        if Self.isBlocked(host: host, blocklist: config.blocklist ?? []) {
            let profiles = ProfileDetector.detect()
            let defaultId = config.defaultProfileId
            if let profile = profiles.first(where: { $0.id == defaultId }) ?? profiles.first {
                open(url: url, profile: profile)
            } else {
                presentNoProfilesAlert()
            }
            return
        }

        let rules = config.rules ?? [:]
        if let ruleKey = Self.ruleKey(for: url, rules: rules),
           let profileId = rules[ruleKey] {
            // Visibility controls the picker, not whether an existing rule can launch its target.
            let profiles = ProfileDetector.detect()
            if let profile = profiles.first(where: { $0.id == profileId }) {
                open(url: url, profile: profile)
                return
            }
            // Rule points to a profile that no longer exists — fall through to picker
        }

        showPicker(for: url)
    }

    static func ruleKey(for url: URL, rules: [String: String]) -> String? {
        if url.scheme?.lowercased() == "file" {
            let path = url.path
            let directory = url.deletingLastPathComponent().path
            if rules[path] != nil { return path }
            return rules[directory] != nil ? directory : nil
        }

        guard let host = url.host?.lowercased(), !host.isEmpty else { return nil }
        let hostPath = host + url.path
        if rules[hostPath] != nil { return hostPath }
        return rules[host] != nil ? host : nil
    }

    static func isBlocked(host: String, blocklist: [String]) -> Bool {
        guard !host.isEmpty else { return false }
        return blocklist.contains { $0.caseInsensitiveCompare(host) == .orderedSame }
    }

    // MARK: - SafeLinks unwrapping

    /// Extracts the real destination URL from Microsoft SafeLinks wrappers.
    /// Teams: statics.teams.cdn.office.net/.../atp-safelinks.html?url=<encoded>
    /// Outlook: *.safelinks.protection.outlook.com/?url=<encoded>
    static func unwrapSafeLinks(_ url: URL) -> URL? {
        guard let host = url.host?.lowercased() else { return nil }

        let isOutlookSafeLink =
            host == "safelinks.protection.outlook.com" ||
            host.hasSuffix(".safelinks.protection.outlook.com")
        let isTeamsSafeLink =
            (host == "teams.cdn.office.net" || host.hasSuffix(".teams.cdn.office.net")) &&
            url.path.contains("safelinks")
        let isSafeLink = isOutlookSafeLink || isTeamsSafeLink

        guard isSafeLink,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let encoded = components.queryItems?.first(where: { $0.name == "url" })?.value,
              let decoded = URL(string: encoded),
              let scheme = decoded.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return nil }

        return decoded
    }

    private func showPicker(for url: URL) {
        pickerController?.close()
        let profiles = ProfileDetector.visible()
        guard !profiles.isEmpty else {
            presentNoProfilesAlert()
            return
        }
        let defaultId = ConfigStore.shared.config.defaultProfileId
        let defaultProfile = profiles.first(where: { $0.id == defaultId }) ?? profiles.first

        pickerController = PickerWindowController(
            url: url,
            profiles: profiles,
            defaultProfile: defaultProfile
        )
        pickerController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func open(url: URL, profile: Profile) {
        if case .failure(let error) = BrowserLauncher.open(url: url, profile: profile) {
            presentAlert(message: "Could Not Open Link", informativeText: error.localizedDescription)
        }
    }

    private func presentNoProfilesAlert() {
        presentAlert(
            message: "No Browser Profiles Found",
            informativeText: "Install or open a supported Chromium browser, then try the link again."
        )
    }

    private func presentAlert(message: String, informativeText: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informativeText
        alert.alertStyle = .warning
        alert.runModal()
    }
}
