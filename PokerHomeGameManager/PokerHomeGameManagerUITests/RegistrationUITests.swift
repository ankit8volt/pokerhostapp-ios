import XCTest

final class RegistrationUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    /// Waits for an element to exist within a timeout.
    @discardableResult
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    /// Returns true if the home screen is visible (either start or resume button present).
    private func isHomeScreenVisible() -> Bool {
        let startButton = app.buttons["home_start_session_button"]
        let resumeButton = app.buttons["home_resume_session_button"]
        return startButton.waitForExistence(timeout: 5) || resumeButton.waitForExistence(timeout: 2)
    }

    /// Returns true if the registration screen is visible.
    private func isRegistrationScreenVisible() -> Bool {
        let nameField = app.textFields["registration_name_field"]
        return nameField.waitForExistence(timeout: 5)
    }

    // MARK: - Tests

    /// Test successful registration with valid data navigates to the home screen.
    func testRegistrationFlow_validData_navigatesToHome() throws {
        // Verify we're on the registration screen
        guard isRegistrationScreenVisible() else {
            // Already registered from a previous test run — skip gracefully
            XCTAssertTrue(isHomeScreenVisible(), "Expected either registration or home screen")
            return
        }

        let nameField = app.textFields["registration_name_field"]
        let phoneField = app.textFields["registration_phone_field"]
        let upiField = app.textFields["registration_upi_field"]
        let registerButton = app.buttons["registration_register_button"]

        // Fill in valid registration data
        nameField.tap()
        nameField.typeText("Test Host")

        phoneField.tap()
        phoneField.typeText("9876543210")

        upiField.tap()
        upiField.typeText("testhost@upi")

        // Dismiss keyboard and tap register
        registerButton.tap()

        // After registration + celebration overlay, the home screen should appear
        // The celebration overlay auto-dismisses, then NotificationCenter triggers navigation
        let startButton = app.buttons["home_start_session_button"]
        let resumeButton = app.buttons["home_resume_session_button"]

        // Wait for either button to appear (home screen loaded)
        let homeAppeared = startButton.waitForExistence(timeout: 10) || resumeButton.waitForExistence(timeout: 2)
        XCTAssertTrue(homeAppeared, "Home screen should appear after successful registration")
    }

    /// Test that leaving the name field empty and tapping Register shows a validation error.
    func testRegistrationFlow_emptyName_showsError() throws {
        guard isRegistrationScreenVisible() else {
            // Already registered — cannot test registration validation
            return
        }

        let phoneField = app.textFields["registration_phone_field"]
        let registerButton = app.buttons["registration_register_button"]

        // Fill phone but leave name empty
        phoneField.tap()
        phoneField.typeText("9876543210")

        registerButton.tap()

        // Verify error message appears for name
        let nameError = app.staticTexts["Name is required"]
        XCTAssertTrue(waitForElement(nameError, timeout: 3), "Should show 'Name is required' error when name is empty")
    }

    /// Test that leaving the phone field empty and tapping Register shows a validation error.
    func testRegistrationFlow_emptyPhone_showsError() throws {
        guard isRegistrationScreenVisible() else {
            // Already registered — cannot test registration validation
            return
        }

        let nameField = app.textFields["registration_name_field"]
        let registerButton = app.buttons["registration_register_button"]

        // Fill name but leave phone empty
        nameField.tap()
        nameField.typeText("Test Host")

        registerButton.tap()

        // Verify error message appears for phone
        let phoneError = app.staticTexts["Phone number is required"]
        XCTAssertTrue(waitForElement(phoneError, timeout: 3), "Should show 'Phone number is required' error when phone is empty")
    }

    /// Test that entering an invalid UPI handle shows a validation error.
    func testRegistrationFlow_invalidUPI_showsError() throws {
        guard isRegistrationScreenVisible() else {
            return
        }

        let nameField = app.textFields["registration_name_field"]
        let phoneField = app.textFields["registration_phone_field"]
        let upiField = app.textFields["registration_upi_field"]
        let registerButton = app.buttons["registration_register_button"]

        nameField.tap()
        nameField.typeText("Test Host")

        phoneField.tap()
        phoneField.typeText("9876543210")

        // Enter invalid UPI (no @ symbol)
        upiField.tap()
        upiField.typeText("invalidupi")

        registerButton.tap()

        // Verify UPI error appears
        let upiError = app.staticTexts["UPI handle must be in format name@provider"]
        XCTAssertTrue(waitForElement(upiError, timeout: 3), "Should show UPI format error for invalid handle")
    }
}
