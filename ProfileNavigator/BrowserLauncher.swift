import Foundation

enum BrowserLauncher {
    static func open(url: URL, profile: Profile) {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [
            "-n",
            "-a", profile.browserApp,
            "--args",
            "--profile-directory=\(profile.directoryName)",
            url.absoluteString
        ]
        do {
            try task.run()
        } catch {
            NSLog("BrowserLauncher: failed to open %@ — %@", url.absoluteString, error.localizedDescription)
        }
    }
}
