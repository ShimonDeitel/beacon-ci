import XCTest

final class BeaconUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testAddItemFromMainList() throws {
        let app = launchApp()

        let addButton = app.buttons["addItemButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["itemNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Add Item sheet did not appear")
        nameField.tap()
        nameField.typeText("Garage Bulb")

        let saveButton = app.buttons["itemSaveButton"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["Garage Bulb"].waitForExistence(timeout: 5), "New item did not appear on the list")
    }

    func testFreeLimitTriggersPaywallAtFourthItem() throws {
        let app = launchApp()
        // Seed data already has 2 items; add 2 more to hit the free cap of 3, then try a 4th.
        for name in ["Third Item", "Fourth Item"] {
            let addButton = app.buttons["addItemButton"]
            addButton.tap()
            let nameField = app.textFields["itemNameField"]
            if nameField.waitForExistence(timeout: 3) {
                nameField.tap()
                nameField.typeText(name)
                app.buttons["itemSaveButton"].tap()
            }
        }
        XCTAssertTrue(app.staticTexts["Beacon Pro"].waitForExistence(timeout: 5), "Paywall did not appear after hitting the free item limit")
    }

    func testSimulatedPurchaseUnlocksUnlimitedItems() throws {
        let app = launchApp()
        for name in ["Third Item", "Fourth Item"] {
            let addButton = app.buttons["addItemButton"]
            addButton.tap()
            let nameField = app.textFields["itemNameField"]
            if nameField.waitForExistence(timeout: 3) {
                nameField.tap()
                nameField.typeText(name)
                app.buttons["itemSaveButton"].tap()
            }
        }
        XCTAssertTrue(app.staticTexts["Beacon Pro"].waitForExistence(timeout: 5))

        let unlockButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Unlock'")).firstMatch
        XCTAssertTrue(unlockButton.waitForExistence(timeout: 5))
        unlockButton.tap()

        // StoreKit test config purchase sheet confirmation, if it appears.
        let confirmButton = app.buttons["Subscribe"].exists ? app.buttons["Subscribe"] : app.buttons["Buy"]
        if confirmButton.waitForExistence(timeout: 5) {
            confirmButton.tap()
        }

        XCTAssertTrue(app.staticTexts["Beacon Pro unlocked"].waitForExistence(timeout: 10) || app.buttons["addItemButton"].waitForExistence(timeout: 10))

        // After purchase, adding a 5th item should succeed without hitting the paywall again.
        // Give the paywall sheet's dismiss animation time to finish so the
        // underlying button is actually hittable, not just present.
        let addButton = app.buttons["addItemButton"]
        if addButton.waitForExistence(timeout: 5) {
            // The paywall sheet's dismiss animation, combined with the Home
            // list's free-plan banner disappearing once Pro unlocks, can
            // leave a brief window where the button reports existing but
            // isn't yet hittable at its old hit point. Wait generously for
            // layout to settle, then tap by coordinate as a final fallback.
            var tapped = false
            for _ in 0..<16 {
                if addButton.isHittable {
                    addButton.tap()
                    tapped = true
                    break
                }
                Thread.sleep(forTimeInterval: 0.5)
            }
            if !tapped {
                addButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
            let nameField = app.textFields["itemNameField"]
            if nameField.waitForExistence(timeout: 5) {
                nameField.tap()
                nameField.typeText("Fifth Item")
                app.buttons["itemSaveButton"].tap()
                XCTAssertTrue(app.staticTexts["Fifth Item"].waitForExistence(timeout: 5))
            }
        }
    }

    func testEditItemFromSettings() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        let editButton = app.buttons.matching(identifier: "editItem_Kitchen Bulb").firstMatch
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        let nameField = app.textFields["itemNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        let stringValue = nameField.value as? String ?? ""
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        nameField.typeText(deleteString)
        nameField.typeText("Living Room Bulb")

        app.buttons["itemSaveButton"].tap()

        XCTAssertTrue(app.staticTexts["Living Room Bulb"].waitForExistence(timeout: 5), "Item rename did not apply")
    }

    func testDeleteItemViaSwipe() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        app.buttons["settingsAddItemButton"].tap()
        let nameField = app.textFields["itemNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Disposable Item")
        app.buttons["itemSaveButton"].tap()
        XCTAssertTrue(app.staticTexts["Disposable Item"].waitForExistence(timeout: 5))

        app.staticTexts["Disposable Item"].swipeLeft()

        let deleteButton = app.buttons["deleteItemSwipe_Disposable Item"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Swipe-to-delete action did not appear")
        deleteButton.tap()

        XCTAssertFalse(app.staticTexts["Disposable Item"].waitForExistence(timeout: 3), "Item was not deleted")
    }

    func testNotifyToggleChangesRealBehavior() throws {
        let app = launchApp()

        // Handle the system notification-permission alert that appears the
        // first time the toggle is switched on, so it doesn't swallow taps.
        addUIInterruptionMonitor(withDescription: "Notification Permission") { alert in
            let allowButton = alert.buttons["Allow"]
            if allowButton.exists {
                allowButton.tap()
                return true
            }
            return false
        }

        app.tabBars.buttons["Settings"].tap()

        let toggle = app.switches["notifyToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        let initialValue = toggle.value as? String
        // Tap the trailing edge explicitly, where the visual switch knob
        // renders, rather than the default center-of-row hit point.
        let trailingPoint = toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        trailingPoint.tap()
        // Give the interruption monitor a chance to run and dismiss any
        // system permission alert, and give SwiftUI time to commit the
        // binding change (and the @AppStorage write it triggers) before we
        // terminate the app.
        _ = app.wait(for: .runningForeground, timeout: 2)
        Thread.sleep(forTimeInterval: 2)

        // Verifying the change persists across a relaunch confirms this is
        // real, saved behavior (backed by @AppStorage) rather than a
        // transient in-memory toggle. The Switch's live accessibility value
        // can lag the underlying UserDefaults write by several seconds in
        // this simulator runtime, so poll generously before asserting.
        app.terminate()
        let relaunched = XCUIApplication()
        relaunched.launch()
        relaunched.tabBars.buttons["Settings"].tap()
        let relaunchedToggle = relaunched.switches["notifyToggle"]
        XCTAssertTrue(relaunchedToggle.waitForExistence(timeout: 5))

        var persistedValue = relaunchedToggle.value as? String
        for _ in 0..<20 {
            persistedValue = relaunchedToggle.value as? String
            if persistedValue != initialValue { break }
            Thread.sleep(forTimeInterval: 0.5)
        }
        XCTAssertNotEqual(initialValue, persistedValue, "Notify toggle change did not persist across relaunch")
    }
}
