import Cocoa

class URLHandler {
    static let shared = URLHandler()

    private var pickerController: PickerWindowController?

    func handle(url: URL) {
        let host = url.host ?? ""
        let path = url.path
        let rules = ConfigStore.shared.config.rules ?? [:]

        // Check page-level rule first (host + path), then host-level
        let ruleKey = rules[host + path] != nil ? host + path : host
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
