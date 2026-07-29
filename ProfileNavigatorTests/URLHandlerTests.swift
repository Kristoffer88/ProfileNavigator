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
}
