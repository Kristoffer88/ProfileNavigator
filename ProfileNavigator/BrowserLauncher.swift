import Foundation

enum BrowserLauncher {
    static func open(url: URL, profile: Profile) {
        guard let executableURL = browserExecutableURL(for: profile.browserApp) else {
            NSLog("BrowserLauncher: could not find an executable for %@", profile.browserApp)
            return
        }

        // Invoke Chromium directly instead of using `open -n`. A running browser
        // forwards this request to the selected profile without starting a new app instance.
        let task = Process()
        task.executableURL = executableURL
        task.arguments = [
            "--profile-directory=\(profile.directoryName)",
            url.absoluteString
        ]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
        } catch {
            NSLog("BrowserLauncher: failed to open %@ — %@", url.absoluteString, error.localizedDescription)
        }
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
