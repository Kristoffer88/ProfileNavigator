import Foundation

struct Config: Codable {
    var defaultProfileId: String?
    var rules: [String: String]?             // host → profile id
    var blocklist: [String]?                 // hosts to never show picker for
    var visibleProfileIds: [String]?         // nil = show all
    var displayNameOverrides: [String: String]?  // profile id → custom name
    var useProfileSymbolInMenuBar: Bool?         // nil/false = use browser symbol

    init() {
        defaultProfileId = nil
        rules = nil
        blocklist = nil
        visibleProfileIds = nil
        displayNameOverrides = nil
        useProfileSymbolInMenuBar = nil
    }
}

class ConfigStore {
    static let shared = ConfigStore()

    private let configURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        let dir = support.appendingPathComponent("ProfileNavigator")
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            NSLog("ConfigStore: could not create config directory — %@", error.localizedDescription)
        }
        return dir.appendingPathComponent("config.json")
    }()

    var config: Config {
        get {
            guard FileManager.default.fileExists(atPath: configURL.path) else { return Config() }
            do {
                let data = try Data(contentsOf: configURL)
                return try JSONDecoder().decode(Config.self, from: data)
            } catch {
                NSLog("ConfigStore: could not load config — %@", error.localizedDescription)
                return Config()
            }
        }
        set {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            do {
                let data = try encoder.encode(newValue)
                try data.write(to: configURL, options: .atomic)
            } catch {
                NSLog("ConfigStore: could not save config — %@", error.localizedDescription)
            }
        }
    }

    func setRule(host: String, profileId: String) {
        var c = config
        if c.rules == nil { c.rules = [:] }
        c.rules![host] = profileId
        config = c
    }

    func removeRule(host: String) {
        var c = config
        c.rules?.removeValue(forKey: host)
        config = c
    }

    func addToBlocklist(host: String) {
        let host = host.lowercased()
        var c = config
        if c.blocklist == nil { c.blocklist = [] }
        if !c.blocklist!.contains(where: { $0.caseInsensitiveCompare(host) == .orderedSame }) {
            c.blocklist!.append(host)
        }
        config = c
    }

    func removeFromBlocklist(host: String) {
        let host = host.lowercased()
        var c = config
        c.blocklist?.removeAll { $0.caseInsensitiveCompare(host) == .orderedSame }
        config = c
    }

    func setDefault(profileId: String?) {
        var c = config
        c.defaultProfileId = profileId
        config = c
    }

    func setUseProfileSymbolInMenuBar(_ enabled: Bool) {
        var c = config
        c.useProfileSymbolInMenuBar = enabled
        config = c
    }

    func setVisibleProfiles(_ ids: [String]?) {
        var c = config
        c.visibleProfileIds = ids
        config = c
    }
}
