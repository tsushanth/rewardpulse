import XCTest
@testable import RewardPulse

final class RewardPulseTests: XCTestCase {
    func testUserProfileDefaults() {
        let profile = UserProfile(id: "test-id", countryCode: "US")
        XCTAssertEqual(profile.lifetimeEarningsCents, 0)
        XCTAssertFalse(profile.onboardingCompleted)
        XCTAssertFalse(profile.isPremium)
        XCTAssertEqual(profile.minimumPayoutCents, 500)
    }
}
