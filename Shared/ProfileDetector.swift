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
    /// Returns only profiles allowed by config. A nil filter means all profiles;
    /// an empty filter intentionally means no profiles.
    static func visible() -> [Profile] {
        let config = ConfigStore.shared.config
        return filtered(
            detect(),
            visibleProfileIds: config.visibleProfileIds,
            displayNameOverrides: config.displayNameOverrides ?? [:]
        )
    }

    static func filtered(
        _ profiles: [Profile],
        visibleProfileIds: [String]?,
        displayNameOverrides: [String: String] = [:]
    ) -> [Profile] {
        func applyingOverride(to profile: Profile) -> Profile {
            guard let name = displayNameOverrides[profile.id] else { return profile }
            return Profile(
                directoryName: profile.directoryName,
                name: name,
                browserApp: profile.browserApp
            )
        }

        guard let ids = visibleProfileIds else {
            return profiles.map(applyingOverride)
        }
        return ids.compactMap { id in
            profiles.first(where: { $0.id == id }).map(applyingOverride)
        }
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
