import XCTest
import CoreData
@testable import PokerHomeGameManager

final class PlayerServiceTests: XCTestCase {
    var coreDataStack: CoreDataStack!
    var sessionService: SessionService!
    var playerService: PlayerService!
    var session: Session!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
        let context = coreDataStack.viewContext
        sessionService = SessionService(context: context)
        playerService = PlayerService(context: context)
        session = try! sessionService.createSession(
            playerCount: 6, smallBlind: 5, bigBlind: 10, buyInAmount: 500, date: nil, venue: nil
        )
    }

    override func tearDown() {
        session = nil
        playerService = nil
        sessionService = nil
        coreDataStack = nil
        super.tearDown()
    }

    // MARK: - Add player with valid name

    func testAddPlayer_validName_createdWithActiveStatus() throws {
        let player = try playerService.addPlayer(to: session, name: "Alice", upiHandle: "alice@upi")

        XCTAssertEqual(player.name, "Alice")
        XCTAssertEqual(player.upiHandle, "alice@upi")
        XCTAssertEqual(player.status, "active")
        XCTAssertNotNil(player.id)
        XCTAssertEqual(player.finalChipCount as? Decimal, 0)
        XCTAssertEqual(player.settlementAmount as? Decimal, 0)
        XCTAssertFalse(player.settlementCompleted)
    }

    func testAddPlayer_trimmedName() throws {
        let player = try playerService.addPlayer(to: session, name: "  Bob  ", upiHandle: nil)
        XCTAssertEqual(player.name, "Bob")
    }

    // MARK: - Add player with empty name

    func testAddPlayer_emptyName_throwsError() {
        XCTAssertThrowsError(try playerService.addPlayer(to: session, name: "", upiHandle: nil)) { error in
            XCTAssertEqual(error as? ValidationError, .invalidPlayerName)
        }
    }

    func testAddPlayer_whitespaceName_throwsError() {
        XCTAssertThrowsError(try playerService.addPlayer(to: session, name: "   ", upiHandle: nil)) { error in
            XCTAssertEqual(error as? ValidationError, .invalidPlayerName)
        }
    }

    // MARK: - getActivePlayers

    func testGetActivePlayers_returnsOnlyActivePlayers() throws {
        let alice = try playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)
        let bob = try playerService.addPlayer(to: session, name: "Bob", upiHandle: nil)

        try playerService.checkoutPlayer(bob, settlementAmount: 100)

        let activePlayers = playerService.getActivePlayers(in: session)
        XCTAssertEqual(activePlayers.count, 1)
        XCTAssertEqual(activePlayers.first?.name, alice.name)
    }

    // MARK: - getCheckedOutPlayers

    func testGetCheckedOutPlayers_returnsOnlyCheckedOutPlayers() throws {
        _ = try playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)
        let bob = try playerService.addPlayer(to: session, name: "Bob", upiHandle: nil)

        try playerService.checkoutPlayer(bob, settlementAmount: 100)

        let checkedOut = playerService.getCheckedOutPlayers(in: session)
        XCTAssertEqual(checkedOut.count, 1)
        XCTAssertEqual(checkedOut.first?.name, "Bob")
    }

    // MARK: - checkoutPlayer

    func testCheckoutPlayer_changesStatusToCheckedOut() throws {
        let player = try playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)
        XCTAssertEqual(player.status, "active")

        try playerService.checkoutPlayer(player, settlementAmount: 250)

        XCTAssertEqual(player.status, "checkedOut")
        XCTAssertEqual(player.settlementAmount as? Decimal, 250)
    }

    // MARK: - setFinalChipCount

    func testSetFinalChipCount_updatesValue() throws {
        let player = try playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)
        XCTAssertEqual(player.finalChipCount as? Decimal, 0)

        try playerService.setFinalChipCount(player, chipCount: 1200)

        XCTAssertEqual(player.finalChipCount as? Decimal, 1200)
    }

    func testSetFinalChipCount_zeroValue() throws {
        let player = try playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)
        try playerService.setFinalChipCount(player, chipCount: 500)
        try playerService.setFinalChipCount(player, chipCount: 0)

        XCTAssertEqual(player.finalChipCount as? Decimal, 0)
    }
}
