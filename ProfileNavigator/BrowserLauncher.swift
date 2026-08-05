import Foundation

enum BrowserLauncher {
    enum LaunchError: LocalizedError {
        case browserNotFound(String)
        case processFailed(String, Error)

        var errorDescription: String? {
            switch self {
            case .browserNotFound(let appName):
                return "\(appName) could not be found in /Applications or ~/Applications."
            case .processFailed(let appName, let error):
                return "\(appName) could not be opened: \(error.localizedDescription)"
            }
        }
    }

    static func open(url: URL, profile: Profile) -> Result<Void, LaunchError> {
        guard let executableURL = browserExecutableURL(for: profile.browserApp) else {
            NSLog("BrowserLauncher: could not find an executable for %@", profile.browserApp)
            return .failure(.browserNotFound(profile.browserApp))
        }

        // Invoke Chromium directly instead of using `open -n`. A running browser
        // forwards this request to the selected profile without starting a new app instance.
        let task = Process()
        task.executableURL = executableURL
        task.arguments = arguments(url: url, profile: profile)
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            return .success(())
        } catch {
            NSLog("BrowserLauncher: failed to open %@ — %@", url.absoluteString, error.localizedDescription)
            return .failure(.processFailed(profile.browserApp, error))
        }
    }

    static func arguments(url: URL, profile: Profile) -> [String] {
        [
            "--profile-directory=\(profile.directoryName)",
            url.absoluteString
        ]
    }

    private static func browserExecutableURL(for appName: String) -> URL? {
        let applicationsDirectories = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications", isDirectory: true)
        ]

        for directory in applicationsDirectories {
            let appURL = directory.appendingPathComponent("\(appName).app", isDirectory: true)
            if let executableURL = Bundle(url: appURL)?.executableURL {
                return executableURL
            }
        }

        return nil
    }
}
