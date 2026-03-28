import Foundation

private struct BrowserSource {
    let appName: String
    let dataPath: String  // relative to ~/Library/Application Support/
}

private let knownBrowsers: [BrowserSource] = [
    BrowserSource(appName: "Google Chrome",       dataPath: "Google/Chrome"),
    BrowserSource(appName: "Google Chrome Dev",   dataPath: "Google/Chrome Dev"),
    BrowserSource(appName: "Google Chrome Canary",dataPath: "Google/Chrome Canary"),
    BrowserSource(appName: "Brave Browser",       dataPath: "BraveSoftware/Brave-Browser"),
    BrowserSource(appName: "Microsoft Edge",      dataPath: "Microsoft Edge"),
    BrowserSource(appName: "Chromium",            dataPath: "Chromium"),
    BrowserSource(appName: "Vivaldi",             dataPath: "Vivaldi"),
    BrowserSource(appName: "Arc",                 dataPath: "Arc"),
]

enum ProfileDetector {
    /// Returns only profiles allowed by config (or all if no filter is set).
    static func visible() -> [Profile] {
        let all = detect()
        let config = ConfigStore.shared.config
        let overrides = config.displayNameOverrides ?? [:]

        func applyOverride(_ p: Profile) -> Profile {
            guard let name = overrides[p.id] else { return p }
            return Profile(directoryName: p.directoryName, name: name, browserApp: p.browserApp)
        }

        guard let ids = config.visibleProfileIds, !ids.isEmpty else {
            return all.map(applyOverride)
        }
        return ids.compactMap { id in all.first(where: { $0.id == id }).map(applyOverride) }
    }

    static func detect() -> [Profile] {
        let support = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support")

        var profiles: [Profile] = []

        let homeApps = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications").path

        for browser in knownBrowsers {
            let appName = "\(browser.appName).app"
            guard FileManager.default.fileExists(atPath: "/Applications/\(appName)")
                || FileManager.default.fileExists(atPath: "\(homeApps)/\(appName)") else { continue }

            let localState = support
                .appendingPathComponent(browser.dataPath)
                .appendingPathComponent("Local State")

            guard let data = try? Data(contentsOf: localState),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let profileSection = json["profile"] as? [String: Any],
                  let infoCache = profileSection["info_cache"] as? [String: [String: Any]] else {
                continue
            }

            for (dirName, info) in infoCache {
                let displayName = info["name"] as? String ?? dirName
                profiles.append(Profile(
                    directoryName: dirName,
                    name: displayName,
                    browserApp: browser.appName
                ))
            }
        }

        // Sort: by browser name, then by directory (Default first, then Profile 1, 2…)
        return profiles.sorted {
            if $0.browserApp != $1.browserApp { return $0.browserApp < $1.browserApp }
            if $0.directoryName == "Default" { return true }
            if $1.directoryName == "Default" { return false }
            return $0.directoryName < $1.directoryName
        }
    }
}
