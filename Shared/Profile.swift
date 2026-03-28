import Foundation

struct Profile: Codable, Identifiable, Hashable {
    let directoryName: String  // "Default", "Profile 1", "Profile 2"
    let name: String           // Display name from Local State
    let browserApp: String     // "Google Chrome", "Brave Browser", etc.

    var id: String { "\(browserApp)|\(directoryName)" }
}
