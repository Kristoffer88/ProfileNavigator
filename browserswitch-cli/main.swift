import Foundation

func printUsage() {
    print("""
    profilenavigator — manage Profile Navigator profiles and rules

    Usage:
      profilenavigator profiles                    List all detected profiles
      profilenavigator default get                 Show current default profile
      profilenavigator default set <id>            Set default profile
      profilenavigator rules list                  List remembered domain rules
      profilenavigator rules remove <host>         Remove a domain rule
      profilenavigator filter list                 Show visible profiles filter
      profilenavigator filter set <id> [<id>...]   Show only these profiles in picker
      profilenavigator filter clear                Show all profiles (remove filter)
    """)
}

let args = Array(CommandLine.arguments.dropFirst())

guard let command = args.first else {
    printUsage()
    exit(1)
}

let store = ConfigStore.shared

switch command {

case "profiles":
    let profiles = ProfileDetector.detect()
    if profiles.isEmpty {
        print("No profiles found. Make sure Chrome (or Brave/Edge) is installed.")
    } else {
        let defaultId = store.config.defaultProfileId
        for p in profiles {
            let marker = p.id == defaultId ? "* " : "  "
            print("\(marker)[\(p.id)]  \(p.name)  (\(p.browserApp))")
        }
    }

case "default":
    let sub = args.dropFirst().first
    switch sub {
    case "get":
        print(store.config.defaultProfileId ?? "(none)")
    case "set":
        guard let id = args.dropFirst(2).first else {
            print("Usage: profilenavigator default set <profile-id>")
            exit(1)
        }
        store.setDefault(profileId: id)
        print("Default set to: \(id)")
    default:
        printUsage()
        exit(1)
    }

case "rules":
    let sub = args.dropFirst().first
    switch sub {
    case "list":
        let rules = store.config.rules ?? [:]
        if rules.isEmpty {
            print("No remembered rules.")
        } else {
            for (host, profileId) in rules.sorted(by: { $0.key < $1.key }) {
                print("  \(host)  →  \(profileId)")
            }
        }
    case "remove":
        guard let host = args.dropFirst(2).first else {
            print("Usage: profilenavigator rules remove <host>")
            exit(1)
        }
        store.removeRule(host: host)
        print("Removed rule for: \(host)")
    default:
        printUsage()
        exit(1)
    }

case "filter":
    let sub = args.dropFirst().first
    switch sub {
    case "list":
        if let ids = store.config.visibleProfileIds, !ids.isEmpty {
            print("Visible profiles:")
            for id in ids { print("  \(id)") }
        } else {
            print("No filter set — all profiles visible.")
        }
    case "set":
        let ids = Array(args.dropFirst(2))
        guard !ids.isEmpty else {
            print("Usage: profilenavigator filter set <id> [<id>...]")
            exit(1)
        }
        store.setVisibleProfiles(ids)
        print("Filter set to \(ids.count) profile(s).")
    case "clear":
        store.setVisibleProfiles(nil)
        print("Filter cleared — all profiles will be visible.")
    default:
        printUsage()
        exit(1)
    }

default:
    printUsage()
    exit(1)
}
