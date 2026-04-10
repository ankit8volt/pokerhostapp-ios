import XCTest

final class SessionFlowUITests: XCTestCase {

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
            return // Already on home screen
        }

        // Might be on registration screen — register first
        let nameField = app.textFields["registration_name_field"]
        if nameField.waitForExistence(timeout: 3) {
            nameField.tap()
            nameField.typeText("UI Test Host")

            let phoneField = app.textFields["registration_phone_field"]
            phoneField.tap()
            phoneField.typeText("9999999999")

            let registerButton = app.buttons["registration_register_button"]
            registerButton.tap()

            // Wait for home screen after celebration
            _ = startButton.waitForExistence(timeout: 10) || resumeButton.waitForExistence(timeout: 2)
        }
    }

    /// Navigates to session creation from home screen.
    private func navigateToSessionCreation() {
        ensureOnHomeScreen()
        let startButton = app.buttons["home_start_session_button"]
        if startButton.waitForExistence(timeout: 3) {
            startButton.tap()
        }
    }

    /// Creates a session with the given parameters and returns to active session.
    private func createSession(smallBlind: String = "10", bigBlind: String = "20", buyIn: String = "500") {
        navigateToSessionCreation()

        let sbField = app.textFields["session_small_blind_field"]
        let bbField = app.textFields["session_big_blind_field"]
        let buyInField = app.textFields["session_buyin_field"]
        let createButton = app.buttons["session_create_button"]

        XCTAssertTrue(waitForElement(sbField), "Small blind field should be visible")

        sbField.tap()
        sbField.typeText(smallBlind)

        bbField.tap()
        bbField.typeText(bigBlind)

        buyInField.tap()
        buyInField.typeText(buyIn)

        createButton.tap()
    }

    // MARK: - Tests

    /// Test creating a session with valid data navigates to the active session screen.
    func testCreateSession_validData_navigatesToActiveSession() throws {
        createSession(smallBlind: "10", bigBlind: "20", buyIn: "500")

        // Verify active session screen appears
        let addPlayerButton = app.buttons["session_add_player_button"]
        XCTAssertTrue(waitForElement(addPlayerButton, timeout: 5),
                       "Active session screen should appear with Add Player button after creating session")

        let endButton = app.buttons["session_end_button"]
        XCTAssertTrue(endButton.exists, "End Session button should be visible on active session screen")
    }

    /// Test that entering big blind less than or equal to small blind shows an error.
    func testCreateSession_invalidBlinds_showsError() throws {
        navigateToSessionCreation()

        let sbField = app.textFields["session_small_blind_field"]
        let bbField = app.textFields["session_big_blind_field"]
        let buyInField = app.textFields["session_buyin_field"]
        let createButton = app.buttons["session_create_button"]

        XCTAssertTrue(waitForElement(sbField), "Small blind field should be visible")

        // Enter big blind <= small blind
        sbField.tap()
        sbField.typeText("50")

        bbField.tap()
        bbField.typeText("25")

        buyInField.tap()
        buyInField.typeText("500")

        createButton.tap()

        // Verify error message appears
        let errorText = app.staticTexts["Big blind must exceed small blind"]
        XCTAssertTrue(waitForElement(errorText, timeout: 3),
                       "Should show error when big blind does not exceed small blind")
    }

    /// Test adding a player with a valid name makes them appear in the player list.
    func testAddPlayer_validName_appearsInList() throws {
        createSession()

        let addPlayerButton = app.buttons["session_add_player_button"]
        XCTAssertTrue(waitForElement(addPlayerButton, timeout: 5), "Add Player button should exist")

        addPlayerButton.tap()

        // Wait for the add player sheet
        let playerNameField = app.textFields["add_player_name_field"]
        XCTAssertTrue(waitForElement(playerNameField, timeout: 5), "Add player sheet should appear")

        playerNameField.tap()
        playerNameField.typeText("Alice")

        let upiField = app.textFields["add_player_upi_field"]
        upiField.tap()
        upiField.typeText("alice@upi")

        let submitButton = app.buttons["add_player_submit_button"]
        submitButton.tap()

        // Verify the player appears in the list
        let playerName = app.staticTexts["Alice"]
        XCTAssertTrue(waitForElement(playerName, timeout: 5),
                       "Player 'Alice' should appear in the active session player list")
    }

    /// Test adding a player with a duplicate name shows an error.
    func testAddPlayer_duplicateName_showsError() throws {
        createSession()

        let addPlayerButton = app.buttons["session_add_player_button"]
        XCTAssertTrue(waitForElement(addPlayerButton, timeout: 5))

        // Add first player
        addPlayerButton.tap()
        let playerNameField = app.textFields["add_player_name_field"]
        XCTAssertTrue(waitForElement(playerNameField, timeout: 5))
        playerNameField.tap()
        playerNameField.typeText("Bob")

        let submitButton = app.buttons["add_player_submit_button"]
        submitButton.tap()

        // Wait for sheet to dismiss and player to appear
        let bobText = app.staticTexts["Bob"]
        XCTAssertTrue(waitForElement(bobText, timeout: 5))

        // Try to add the same player again
        addPlayerButton.tap()
        let playerNameField2 = app.textFields["add_player_name_field"]
        XCTAssertTrue(waitForElement(playerNameField2, timeout: 5))
        playerNameField2.tap()
        playerNameField2.typeText("Bob")

        let submitButton2 = app.buttons["add_player_submit_button"]
        submitButton2.tap()

        // Verify duplicate error appears
        let duplicateError = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "already exists"))
        XCTAssertTrue(duplicateError.firstMatch.waitForExistence(timeout: 3),
                       "Should show error when adding a player with a duplicate name")
    }

    /// Test that the End Session button navigates to the settlement screen.
    func testEndSession_navigatesToSettlement() throws {
        createSession()

        // Add a player first (settlement requires players)
        let addPlayerButton = app.buttons["session_add_player_button"]
        XCTAssertTrue(waitForElement(addPlayerButton, timeout: 5))
        addPlayerButton.tap()

        let playerNameField = app.textFields["add_player_name_field"]
        XCTAssertTrue(waitForElement(playerNameField, timeout: 5))
        playerNameField.tap()
        playerNameField.typeText("Charlie")

        let submitButton = app.buttons["add_player_submit_button"]
        submitButton.tap()

        // Wait for sheet to dismiss
        let charlieText = app.staticTexts["Charlie"]
        XCTAssertTrue(waitForElement(charlieText, timeout: 5))

        // Tap End Session
        let endButton = app.buttons["session_end_button"]
        XCTAssertTrue(endButton.exists, "End Session button should be visible")
        endButton.tap()

        // Verify settlement screen appears
        let settlementTitle = app.navigationBars["Settlement"]
        XCTAssertTrue(waitForElement(settlementTitle, timeout: 5),
                       "Settlement screen should appear after tapping End Session")
    }

    /// Test that the profile settings button navigates to the profile screen.
    func testProfileButton_navigatesToProfile() throws {
        ensureOnHomeScreen()

        let profileButton = app.buttons["home_profile_button"]
        XCTAssertTrue(waitForElement(profileButton, timeout: 3), "Profile button should be visible on home screen")
        profileButton.tap()

        // Verify profile screen appears
        let profileTitle = app.navigationBars["Profile"]
        let profileSettingsText = app.staticTexts["Profile Settings"]
        let appeared = waitForElement(profileTitle, timeout: 5) || waitForElement(profileSettingsText, timeout: 2)
        XCTAssertTrue(appeared, "Profile screen should appear after tapping profile button")
    }
}
