import XCTest
@testable import ProfileNavigator

final class URLHandlerTests: XCTestCase {
    func testUnwrapsOutlookSafeLink() throws {
        let wrapped = try XCTUnwrap(URL(string:
            "https://tenant.safelinks.protection.outlook.com/?url=https%3A%2F%2Fexample.com%2Fdocument"
        ))

        XCTAssertEqual(
            URLHandler.unwrapSafeLinks(wrapped)?.absoluteString,
            "https://example.com/document"
        )
    }

    func testUnwrapsTeamsSafeLink() throws {
        let wrapped = try XCTUnwrap(URL(string:
            "https://statics.teams.cdn.office.net/evergreen-assets/safelinks/atp-safelinks.html?url=https%3A%2F%2Fexample.com%2Fteam"
        ))

        XCTAssertEqual(
            URLHandler.unwrapSafeLinks(wrapped)?.absoluteString,
            "https://example.com/team"
        )
    }

    func testDoesNotTrustLookalikeTeamsHost() throws {
        let wrapped = try XCTUnwrap(URL(string:
            "https://teams.cdn.office.net.attacker.example/safelinks?url=https%3A%2F%2Fexample.com"
        ))

        XCTAssertNil(URLHandler.unwrapSafeLinks(wrapped))
    }

    func testDoesNotUnwrapSafeLinkToUnsupportedScheme() throws {
        let wrapped = try XCTUnwrap(URL(string:
            "https://tenant.safelinks.protection.outlook.com/?url=file%3A%2F%2F%2Fetc%2Fhosts"
        ))

        XCTAssertNil(URLHandler.unwrapSafeLinks(wrapped))
    }

    func testRuleKeyPrefersPageRuleOverSiteRule() throws {
        let url = try XCTUnwrap(URL(string: "https://Example.com/docs/start?ignored=true"))
        let rules = [
            "example.com": "site-profile",
            "example.com/docs/start": "page-profile"
        ]

        XCTAssertEqual(URLHandler.ruleKey(for: url, rules: rules), "example.com/docs/start")
    }

    func testRuleKeyMatchesParentDirectoryForFile() {
        let url = URL(fileURLWithPath: "/Users/example/Documents/page.html")
        let rules = ["/Users/example/Documents": "work-profile"]

        XCTAssertEqual(URLHandler.ruleKey(for: url, rules: rules), "/Users/example/Documents")
    }

    func testBlocklistComparisonIsCaseInsensitive() {
        XCTAssertTrue(URLHandler.isBlocked(host: "example.com", blocklist: ["Example.COM"]))
        XCTAssertFalse(URLHandler.isBlocked(host: "", blocklist: ["example.com"]))
    }

    func testNilProfileFilterShowsAllProfiles() {
        let profiles = makeProfiles()

        XCTAssertEqual(
            ProfileDetector.filtered(profiles, visibleProfileIds: nil),
            profiles
        )
    }

    func testEmptyProfileFilterShowsNoProfiles() {
        XCTAssertEqual(
            ProfileDetector.filtered(makeProfiles(), visibleProfileIds: []),
            []
        )
    }

    func testProfileFilterPreservesConfiguredOrderAndAppliesNames() {
        let profiles = makeProfiles()
        let result = ProfileDetector.filtered(
            profiles,
            visibleProfileIds: [profiles[1].id, profiles[0].id],
            displayNameOverrides: [profiles[1].id: "Personal"]
        )

        XCTAssertEqual(result.map(\.id), [profiles[1].id, profiles[0].id])
        XCTAssertEqual(result.first?.name, "Personal")
    }

    func testBrowserArgumentsKeepProfileDirectoryAndURLSeparate() throws {
        let profile = Profile(
            directoryName: "Profile 2",
            name: "Work",
            browserApp: "Google Chrome"
        )
        let url = try XCTUnwrap(URL(string: "https://example.com/a%20path"))

        XCTAssertEqual(
            BrowserLauncher.arguments(url: url, profile: profile),
            ["--profile-directory=Profile 2", "https://example.com/a%20path"]
        )
    }

    private func makeProfiles() -> [Profile] {
        [
            Profile(directoryName: "Default", name: "Work", browserApp: "Google Chrome"),
            Profile(directoryName: "Profile 1", name: "Home", browserApp: "Google Chrome")
        ]
    }
}
