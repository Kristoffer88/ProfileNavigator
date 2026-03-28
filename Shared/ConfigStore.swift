import Foundation

struct Config: Codable {
    var defaultProfileId: String?
    var rules: [String: String]              // host → profile id
    var visibleProfileIds: [String]?         // nil = show all
    var displayNameOverrides: [String: String]?  // profile id → custom name

    init() {
        defaultProfileId = nil
        rules = [:]
        visibleProfileIds = nil
        displayNameOverrides = nil
    }
}

class ConfigStore {
    static let shared = ConfigStore()

    private let configURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("ProfileNavigator")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.json")
    }()

    var config: Config {
        get {
            guard let data = try? Data(contentsOf: configURL),
                  let decoded = try? JSONDecoder().decode(Config.self, from: data) else {
                return Config()
            }
            return decoded
        }
        set {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            if let data = try? encoder.encode(newValue) {
                try? data.write(to: configURL)
            }
        }
    }

    func setRule(host: String, profileId: String) {
        var c = config
        c.rules[host] = profileId
        config = c
    }

    func removeRule(host: String) {
        var c = config
        c.rules.removeValue(forKey: host)
        config = c
    }

    func setDefault(profileId: String?) {
        var c = config
        c.defaultProfileId = profileId
        config = c
    }

    func setVisibleProfiles(_ ids: [String]?) {
        var c = config
        c.visibleProfileIds = ids
        config = c
    }
}
