import XCTest

final class BuyInFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    @discardableResult
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    /// Ensures we're on the home screen. If on registration, performs registration first.
    private func ensureOnHomeScreen() {
        let startButton = app.buttons["home_start_session_button"]
        let resumeButton = app.buttons["home_resume_session_button"]

        if startButton.waitForExistence(timeout: 3) || resumeButton.waitForExistence(timeout: 2) {
            return
        }

        let nameField = app.textFields["registration_name_field"]
        if nameField.waitForExistence(timeout: 3) {
            nameField.tap()
            nameField.typeText("BuyIn Test Host")

            let phoneField = app.textFields["registration_phone_field"]
            phoneField.tap()
            phoneField.typeText("8888888888")

            let upiField = app.textFields["registration_upi_field"]
            upiField.tap()
            upiField.typeText("buyinhost@upi")

            let registerButton = app.buttons["registration_register_button"]
            registerButton.tap()

            _ = startButton.waitForExistence(timeout: 10) || resumeButton.waitForExistence(timeout: 2)
        }
    }

    /// Creates a session and adds a player, returning to the active session screen.
    private func createSessionAndAddPlayer(playerName: String = "TestPlayer") {
        ensureOnHomeScreen()

        // Start or resume session
        let startButton = app.buttons["home_start_session_button"]
        let resumeButton = app.buttons["home_resume_session_button"]

        if resumeButton.exists {
            resumeButton.tap()
        } else if startButton.exists {
            startButton.tap()

            // Fill session creation form
            let sbField = app.textFields["session_small_blind_field"]
            XCTAssertTrue(waitForElement(sbField))
            sbField.tap()
            sbField.typeText("10")

            let bbField = app.textFields["session_big_blind_field"]
            bbField.tap()
            bbField.typeText("20")

            let buyInField = app.textFields["session_buyin_field"]
            buyInField.tap()
            buyInField.typeText("500")

            let createButton = app.buttons["session_create_button"]
            createButton.tap()
        }

        // Wait for active session
        let addPlayerButton = app.buttons["session_add_player_button"]
        XCTAssertTrue(waitForElement(addPlayerButton, timeout: 5))

        // Check if player already exists
        let existingPlayer = app.staticTexts[playerName]
        if existingPlayer.exists {
            return // Player already added
        }

        // Add player
        addPlayerButton.tap()
        let nameField = app.textFields["add_player_name_field"]
        XCTAssertTrue(waitForElement(nameField, timeout: 5))
        nameField.tap()
        nameField.typeText(playerName)

        let submitButton = app.buttons["add_player_submit_button"]
        submitButton.tap()

        // Wait for player to appear
        XCTAssertTrue(waitForElement(app.staticTexts[playerName], timeout: 5))
    }

    // MARK: - Tests

    /// Test that tapping Buy-In → Cash → Collected updates the player's buy-in count.
    func testCashBuyIn_collected_updatesPlayerStats() throws {
        createSessionAndAddPlayer(playerName: "CashPlayer")

        // Find the Buy-In button for the player
        let buyInButton = app.buttons["💰 Buy-In"]
        XCTAssertTrue(waitForElement(buyInButton, timeout: 5), "Buy-In button should be visible for new player")

        buyInButton.tap()

        // The collect flow sheet should appear with Cash/UPI options
        let cashButton = app.buttons["💵 Cash"]
        XCTAssertTrue(waitForElement(cashButton, timeout: 5), "Cash payment option should appear")
        cashButton.tap()

        // Cash collection alert should appear — tap "Collected"
        let collectedButton = app.buttons["✅ Collected"]
        XCTAssertTrue(waitForElement(collectedButton, timeout: 5), "Collected confirmation should appear")
        collectedButton.tap()

        // Verify buy-in count is updated (should show "1 buy-in")
        let buyInCount = app.staticTexts["1 buy-in"]
        XCTAssertTrue(waitForElement(buyInCount, timeout: 5),
                       "Player should show '1 buy-in' after successful cash buy-in collection")
    }

    /// Test that tapping Buy-In → Cash → Not Yet shows outstanding amount.
    func testCashBuyIn_notYet_showsOutstanding() throws {
        createSessionAndAddPlayer(playerName: "PendingPlayer")

        let buyInButton = app.buttons["💰 Buy-In"]
        XCTAssertTrue(waitForElement(buyInButton, timeout: 5), "Buy-In button should be visible")

        buyInButton.tap()

        let cashButton = app.buttons["💵 Cash"]
        XCTAssertTrue(waitForElement(cashButton, timeout: 5))
        cashButton.tap()

        // Tap "Not Yet" to mark as outstanding
        let notYetButton = app.buttons["⏳ Not Yet"]
        XCTAssertTrue(waitForElement(notYetButton, timeout: 5), "Not Yet option should appear")
        notYetButton.tap()

        // Verify outstanding indicator appears (⏳ with amount)
        // The player row should show the outstanding emoji indicator
        let outstandingIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "⏳"))
        XCTAssertTrue(outstandingIndicator.firstMatch.waitForExistence(timeout: 5),
                       "Outstanding indicator should appear when buy-in is not yet collected")
    }

    /// Test that after initial buy-in, the Buy-In button is replaced by Re-Buy.
    func testAfterBuyIn_onlyReBuyShown() throws {
        createSessionAndAddPlayer(playerName: "ReBuyPlayer")

        // Perform initial buy-in
        let buyInButton = app.buttons["💰 Buy-In"]
        XCTAssertTrue(waitForElement(buyInButton, timeout: 5))
        buyInButton.tap()

        let cashButton = app.buttons["💵 Cash"]
        XCTAssertTrue(waitForElement(cashButton, timeout: 5))
        cashButton.tap()

        let collectedButton = app.buttons["✅ Collected"]
        XCTAssertTrue(waitForElement(collectedButton, timeout: 5))
        collectedButton.tap()

        // After buy-in, verify Buy-In button is gone and Re-Buy is shown
        let reBuyButton = app.buttons["🔄 Re-Buy"]
        XCTAssertTrue(waitForElement(reBuyButton, timeout: 5),
                       "Re-Buy button should appear after initial buy-in")

        // The original Buy-In button should no longer exist
        let originalBuyIn = app.buttons["💰 Buy-In"]
        XCTAssertFalse(originalBuyIn.exists,
                        "Buy-In button should be replaced by Re-Buy after initial buy-in")
    }

    /// Test that Re-Buy flow works after initial buy-in.
    func testReBuy_afterInitialBuyIn_incrementsCount() throws {
        createSessionAndAddPlayer(playerName: "MultiBuyPlayer")

        // Perform initial buy-in
        let buyInButton = app.buttons["💰 Buy-In"]
        if waitForElement(buyInButton, timeout: 3) {
            buyInButton.tap()

            let cashButton = app.buttons["💵 Cash"]
            XCTAssertTrue(waitForElement(cashButton, timeout: 5))
            cashButton.tap()

            let collectedButton = app.buttons["✅ Collected"]
            XCTAssertTrue(waitForElement(collectedButton, timeout: 5))
            collectedButton.tap()
        }

        // Now perform re-buy
        let reBuyButton = app.buttons["🔄 Re-Buy"]
        XCTAssertTrue(waitForElement(reBuyButton, timeout: 5), "Re-Buy button should be visible")
        reBuyButton.tap()

        let cashButton2 = app.buttons["💵 Cash"]
        XCTAssertTrue(waitForElement(cashButton2, timeout: 5))
        cashButton2.tap()

        let collectedButton2 = app.buttons["✅ Collected"]
        XCTAssertTrue(waitForElement(collectedButton2, timeout: 5))
        collectedButton2.tap()

        // Verify buy-in count increased to 2
        let buyInCount = app.staticTexts["2 buy-ins"]
        XCTAssertTrue(waitForElement(buyInCount, timeout: 5),
                       "Player should show '2 buy-ins' after initial buy-in + re-buy")
    }

    /// Test that Checkout button appears after buy-in alongside Re-Buy.
    func testCheckoutButton_appearsAfterBuyIn() throws {
        createSessionAndAddPlayer(playerName: "CheckoutTestPlayer")

        // Perform initial buy-in
        let buyInButton = app.buttons["💰 Buy-In"]
        if waitForElement(buyInButton, timeout: 3) {
            buyInButton.tap()

            let cashButton = app.buttons["💵 Cash"]
            XCTAssertTrue(waitForElement(cashButton, timeout: 5))
            cashButton.tap()

            let collectedButton = app.buttons["✅ Collected"]
            XCTAssertTrue(waitForElement(collectedButton, timeout: 5))
            collectedButton.tap()
        }

        // Verify both Re-Buy and Checkout buttons are visible
        let reBuyButton = app.buttons["🔄 Re-Buy"]
        let checkoutButton = app.buttons["🚪 Checkout"]

        XCTAssertTrue(waitForElement(reBuyButton, timeout: 5), "Re-Buy button should be visible after buy-in")
        XCTAssertTrue(checkoutButton.exists, "Checkout button should be visible after buy-in")
    }
}
