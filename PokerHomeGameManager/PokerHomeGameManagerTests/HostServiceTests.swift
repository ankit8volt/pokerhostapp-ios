import XCTest
import CoreData
@testable import PokerHomeGameManager

final class HostServiceTests: XCTestCase {
    var coreDataStack: CoreDataStack!
    var hostService: HostService!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
        hostService = HostService(context: coreDataStack.viewContext)
    }

    override func tearDown() {
        hostService = nil
        coreDataStack = nil
        super.tearDown()
    }

    // MARK: - Register with valid data

    func testRegisterWithValidData_createsAndRetrievesHost() throws {
        let host = try hostService.registerHost(name: "Alice", city: "Mumbai", phone: "9876543210", upiHandle: "alice@upi")

        XCTAssertEqual(host.name, "Alice")
        XCTAssertEqual(host.city, "Mumbai")
        XCTAssertEqual(host.phone, "9876543210")
        XCTAssertEqual(host.upiHandle, "alice@upi")
        XCTAssertNotNil(host.id)
        XCTAssertNotNil(host.createdAt)

        let retrieved = hostService.getHost()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.name, "Alice")
        XCTAssertEqual(retrieved?.phone, "9876543210")
    }

    // MARK: - Register with empty name

    func testRegisterWithEmptyName_throwsValidationError() {
        XCTAssertThrowsError(try hostService.registerHost(name: "", city: "Mumbai", phone: "9876543210", upiHandle: nil)) { error in
            guard let validationError = error as? ValidationError else {
                return XCTFail("Expected ValidationError")
            }
            XCTAssertEqual(validationError, .missingRequiredFields(["name"]))
        }
    }

    func testRegisterWithWhitespaceName_throwsValidationError() {
        XCTAssertThrowsError(try hostService.registerHost(name: "   ", city: "Mumbai", phone: "9876543210", upiHandle: nil)) { error in
            guard let validationError = error as? ValidationError else {
                return XCTFail("Expected ValidationError")
            }
            XCTAssertEqual(validationError, .missingRequiredFields(["name"]))
        }
    }

    // MARK: - Register with empty phone

    func testRegisterWithEmptyPhone_throwsValidationError() {
        XCTAssertThrowsError(try hostService.registerHost(name: "Alice", city: "Mumbai", phone: "", upiHandle: nil)) { error in
            guard let validationError = error as? ValidationError else {
                return XCTFail("Expected ValidationError")
            }
            XCTAssertEqual(validationError, .missingRequiredFields(["phone"]))
        }
    }

    func testRegisterWithEmptyNameAndPhone_throwsBothFields() {
        XCTAssertThrowsError(try hostService.registerHost(name: "", city: "Mumbai", phone: "", upiHandle: nil)) { error in
            guard let validationError = error as? ValidationError else {
                return XCTFail("Expected ValidationError")
            }
            XCTAssertEqual(validationError, .missingRequiredFields(["name", "phone"]))
        }
    }

    // MARK: - Update host

    func testUpdateHost_valuesChangeCorrectly() throws {
        _ = try hostService.registerHost(name: "Alice", city: "Mumbai", phone: "9876543210", upiHandle: "alice@upi")

        let updated = try hostService.updateHost(name: "Bob", city: "Delhi", phone: "1234567890", upiHandle: "bob@upi")

        XCTAssertEqual(updated.name, "Bob")
        XCTAssertEqual(updated.city, "Delhi")
        XCTAssertEqual(updated.phone, "1234567890")
        XCTAssertEqual(updated.upiHandle, "bob@upi")

        let retrieved = hostService.getHost()
        XCTAssertEqual(retrieved?.name, "Bob")
        XCTAssertEqual(retrieved?.city, "Delhi")
    }

    func testUpdateHost_partialUpdate() throws {
        _ = try hostService.registerHost(name: "Alice", city: "Mumbai", phone: "9876543210", upiHandle: "alice@upi")

        let updated = try hostService.updateHost(name: "Bob", city: nil, phone: nil, upiHandle: nil)

        XCTAssertEqual(updated.name, "Bob")
        XCTAssertEqual(updated.city, "Mumbai")
        XCTAssertEqual(updated.phone, "9876543210")
        XCTAssertNil(updated.upiHandle)
    }

    // MARK: - isRegistered

    func testIsRegistered_returnsTrueAfterRegistration() throws {
        XCTAssertFalse(hostService.isRegistered())

        _ = try hostService.registerHost(name: "Alice", city: "Mumbai", phone: "9876543210", upiHandle: nil)

        XCTAssertTrue(hostService.isRegistered())
    }

    // MARK: - getHost returns nil before registration

    func testGetHost_returnsNilBeforeRegistration() {
        XCTAssertNil(hostService.getHost())
    }
}
