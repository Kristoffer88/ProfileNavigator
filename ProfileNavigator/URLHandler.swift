import Cocoa

class URLHandler {
    static let shared = URLHandler()

    private var pickerController: PickerWindowController?

    func handle(url: URL) {
        let url = Self.unwrapSafeLinks(url) ?? url
        let config = ConfigStore.shared.config
        let host = url.host ?? ""
        if !host.isEmpty && (config.blocklist ?? []).contains(host) {
            let profiles = ProfileDetector.visible()
            let defaultId = config.defaultProfileId
            if let profile = profiles.first(where: { $0.id == defaultId }) ?? profiles.first {
                BrowserLauncher.open(url: url, profile: profile)
            }
            return
        }

        let rules = config.rules ?? [:]

        // For file:// URLs, check path then parent directory; for http(s), check host+path then host
        let ruleKey: String
        if url.scheme == "file" {
            let path = url.path
            let dir = url.deletingLastPathComponent().path
            ruleKey = rules[path] != nil ? path : dir
        } else {
            let hostPath = host + url.path
            ruleKey = rules[hostPath] != nil ? hostPath : host
        }

        if let profileId = rules[ruleKey] {
            let profiles = ProfileDetector.visible()
            if let profile = profiles.first(where: { $0.id == profileId }) {
                BrowserLauncher.open(url: url, profile: profile)
                return
            }
            // Rule points to a profile that no longer exists — fall through to picker
        }

        showPicker(for: url)
    }

    // MARK: - SafeLinks unwrapping

    /// Extracts the real destination URL from Microsoft SafeLinks wrappers.
    /// Teams: statics.teams.cdn.office.net/.../atp-safelinks.html?url=<encoded>
    /// Outlook: *.safelinks.protection.outlook.com/?url=<encoded>
    static func unwrapSafeLinks(_ url: URL) -> URL? {
        guard let host = url.host?.lowercased() else { return nil }

        let isSafeLink =
            host.hasSuffix(".safelinks.protection.outlook.com") ||
            (host.contains("teams.cdn.office.net") && url.path.contains("safelinks"))

        guard isSafeLink,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let encoded = components.queryItems?.first(where: { $0.name == "url" })?.value,
              let decoded = URL(string: encoded)
        else { return nil }

        return decoded
    }

    private func showPicker(for url: URL) {
        let profiles = ProfileDetector.visible()
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
}
