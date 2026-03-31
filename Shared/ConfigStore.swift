import Foundation

struct Config: Codable {
    var defaultProfileId: String?
    var rules: [String: String]?             // host → profile id
    var blocklist: [String]?                 // hosts to never show picker for
    var visibleProfileIds: [String]?         // nil = show all
    var displayNameOverrides: [String: String]?  // profile id → custom name

    init() {
        defaultProfileId = nil
        rules = nil
        visibleProfileIds = nil
        displayNameOverrides = nil
    }
}

class ConfigStore {
    static let shared = ConfigStore()

    private let configURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
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
        var c = config
        if c.blocklist == nil { c.blocklist = [] }
        if !c.blocklist!.contains(host) { c.blocklist!.append(host) }
        config = c
    }

    func removeFromBlocklist(host: String) {
        var c = config
        c.blocklist?.removeAll { $0 == host }
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
