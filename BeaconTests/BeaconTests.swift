import XCTest
@testable import Beacon

final class BeaconTests: XCTestCase {
    func testPercentUsedZeroRightAfterInstall() {
        let item = TrackedItem(name: "Test", category: .bulb, installDate: Date(), expectedLifeDays: 90)
        XCTAssertEqual(item.percentUsed, 0, accuracy: 0.01)
        XCTAssertFalse(item.isNearingEnd)
        XCTAssertFalse(item.isExpired)
    }

    func testPercentUsedAtHalfLife() {
        let installed = Calendar.current.date(byAdding: .day, value: -45, to: Date())!
        let item = TrackedItem(name: "Test", category: .bulb, installDate: installed, expectedLifeDays: 90)
        XCTAssertEqual(item.percentUsed, 0.5, accuracy: 0.05)
        XCTAssertFalse(item.isNearingEnd)
    }

    func testNearingEndThreshold() {
        let installed = Calendar.current.date(byAdding: .day, value: -70, to: Date())!
        let item = TrackedItem(name: "Test", category: .bulb, installDate: installed, expectedLifeDays: 90)
        XCTAssertTrue(item.isNearingEnd)
        XCTAssertFalse(item.isExpired)
    }

    func testExpiredAfterExpectedLife() {
        let installed = Calendar.current.date(byAdding: .day, value: -100, to: Date())!
        let item = TrackedItem(name: "Test", category: .bulb, installDate: installed, expectedLifeDays: 90)
        XCTAssertTrue(item.isExpired)
        XCTAssertEqual(item.percentUsed, 1.0, accuracy: 0.01)
    }

    func testReplacingResetsPercentUsed() {
        var item = TrackedItem(name: "Test", category: .bulb,
                                installDate: Calendar.current.date(byAdding: .day, value: -100, to: Date())!,
                                expectedLifeDays: 90)
        XCTAssertTrue(item.isExpired)
        item.replace()
        XCTAssertEqual(item.percentUsed, 0, accuracy: 0.01)
    }

    @MainActor
    func testStoreAddItemRespectsFreeLimit() {
        let store = BeaconStore()
        for item in store.items { store.deleteItem(item.id) }
        XCTAssertTrue(store.addItem(name: "A", category: .bulb, detail: "", installDate: Date(), expectedLifeDays: 90, isPro: false))
        XCTAssertTrue(store.addItem(name: "B", category: .bulb, detail: "", installDate: Date(), expectedLifeDays: 90, isPro: false))
        XCTAssertTrue(store.addItem(name: "C", category: .bulb, detail: "", installDate: Date(), expectedLifeDays: 90, isPro: false))
        XCTAssertFalse(store.addItem(name: "D", category: .bulb, detail: "", installDate: Date(), expectedLifeDays: 90, isPro: false))
        XCTAssertTrue(store.addItem(name: "D", category: .bulb, detail: "", installDate: Date(), expectedLifeDays: 90, isPro: true))
    }

    @MainActor
    func testReplaceItemResetsInstallDate() {
        let store = BeaconStore()
        for item in store.items { store.deleteItem(item.id) }
        store.addItem(name: "Filter", category: .airFilter, detail: "", installDate: Calendar.current.date(byAdding: .day, value: -100, to: Date())!, expectedLifeDays: 90, isPro: false)
        let item = store.items[0]
        XCTAssertTrue(item.isExpired)
        store.replaceItem(item.id)
        XCTAssertFalse(store.items[0].isExpired)
    }

    func testGlowColorInterpolatesAcrossRange() {
        let fresh = BNTheme.glowColor(percentUsed: 0)
        let cool = BNTheme.glowColor(percentUsed: 0.9)
        let expired = BNTheme.glowColor(percentUsed: 1.0)
        XCTAssertNotEqual(fresh, cool)
        XCTAssertEqual(expired, BNTheme.expired)
    }

    func testGlowRadiusShrinksAsUsageIncreases() {
        let freshRadius = BNTheme.glowRadius(percentUsed: 0)
        let midRadius = BNTheme.glowRadius(percentUsed: 0.5)
        let expiredRadius = BNTheme.glowRadius(percentUsed: 1.0)
        XCTAssertGreaterThan(freshRadius, midRadius)
        XCTAssertGreaterThan(midRadius, expiredRadius)
    }
}
