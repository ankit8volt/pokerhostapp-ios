import XCTest
import CoreData
@testable import PokerHomeGameManager

final class SessionServiceTests: XCTestCase {
    var coreDataStack: CoreDataStack!
    var sessionService: SessionService!
    var playerService: PlayerService!
    var transactionService: TransactionService!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
        let context = coreDataStack.viewContext
        sessionService = SessionService(context: context)
        playerService = PlayerService(context: context)
        transactionService = TransactionService(context: context)
    }

    override func tearDown() {
        transactionService = nil
        playerService = nil
        sessionService = nil
        coreDataStack = nil
        super.tearDown()
    }

    // MARK: - Create session with valid params

    func testCreateSession_validParams_createdWithIsActiveAndTimestamp() throws {
        let beforeCreation = Date()
        let session = try sessionService.createSession(
            playerCount: 6, smallBlind: 5, bigBlind: 10, buyInAmount: 500, date: nil, venue: "Home"
        )

        XCTAssertTrue(session.isActive)
        XCTAssertNotNil(session.startTimestamp)
        XCTAssertNotNil(session.id)
        XCTAssertNil(session.endTimestamp)
        XCTAssertEqual(session.smallBlind as? Decimal, 5)
        XCTAssertEqual(session.bigBlind as? Decimal, 10)
        XCTAssertEqual(session.buyInAmount as? Decimal, 500)
        XCTAssertEqual(session.venue, "Home")
        XCTAssertGreaterThanOrEqual(session.startTimestamp!, beforeCreation)
    }

    // MARK: - Negative small blind

    func testCreateSession_negativeSmallBlind_throwsError() {
        XCTAssertThrowsError(try sessionService.createSession(
            playerCount: 6, smallBlind: -5, bigBlind: 10, buyInAmount: 500, date: nil, venue: nil
        )) { error in
            guard case ValidationError.invalidSessionParameters(let msg) = error else {
                return XCTFail("Expected invalidSessionParameters")
            }
            XCTAssertTrue(msg.lowercased().contains("small blind"))
        }
    }

    func testCreateSession_zeroSmallBlind_throwsError() {
        XCTAssertThrowsError(try sessionService.createSession(
            playerCount: 6, smallBlind: 0, bigBlind: 10, buyInAmount: 500, date: nil, venue: nil
        ))
    }

    // MARK: - Big blind <= small blind

    func testCreateSession_bigBlindEqualToSmallBlind_throwsError() {
        XCTAssertThrowsError(try sessionService.createSession(
            playerCount: 6, smallBlind: 10, bigBlind: 10, buyInAmount: 500, date: nil, venue: nil
        )) { error in
            guard case ValidationError.invalidSessionParameters(let msg) = error else {
                return XCTFail("Expected invalidSessionParameters")
            }
            XCTAssertTrue(msg.lowercased().contains("big blind"))
        }
    }

    func testCreateSession_bigBlindLessThanSmallBlind_throwsError() {
        XCTAssertThrowsError(try sessionService.createSession(
            playerCount: 6, smallBlind: 10, bigBlind: 5, buyInAmount: 500, date: nil, venue: nil
        ))
    }

    // MARK: - Negative buy-in

    func testCreateSession_negativeBuyIn_throwsError() {
        XCTAssertThrowsError(try sessionService.createSession(
            playerCount: 6, smallBlind: 5, bigBlind: 10, buyInAmount: -100, date: nil, venue: nil
        )) { error in
            guard case ValidationError.invalidSessionParameters(let msg) = error else {
                return XCTFail("Expected invalidSessionParameters")
            }
            XCTAssertTrue(msg.lowercased().contains("buy-in"))
        }
    }

    func testCreateSession_zeroBuyIn_throwsError() {
        XCTAssertThrowsError(try sessionService.createSession(
            playerCount: 6, smallBlind: 5, bigBlind: 10, buyInAmount: 0, date: nil, venue: nil
        ))
    }

    // MARK: - End session

    func testEndSession_setsIsActiveFalseAndEndTimestamp() throws {
        let session = try sessionService.createSession(
            playerCount: 6, smallBlind: 5, bigBlind: 10, buyInAmount: 500, date: nil, venue: nil
        )
        XCTAssertTrue(session.isActive)
        XCTAssertNil(session.endTimestamp)

        try sessionService.endSession(session)

        XCTAssertFalse(session.isActive)
        XCTAssertNotNil(session.endTimestamp)
    }

    // MARK: - getActiveSession

    func testGetActiveSession_returnsActiveSession() throws {
        XCTAssertNil(sessionService.getActiveSession())

        let session = try sessionService.createSession(
            playerCount: 6, smallBlind: 5, bigBlind: 10, buyInAmount: 500, date: nil, venue: nil
        )

        let active = sessionService.getActiveSession()
        XCTAssertNotNil(active)
        XCTAssertEqual(active?.id, session.id)
    }

    func testGetActiveSession_returnsNilAfterEnding() throws {
        let session = try sessionService.createSession(
            playerCount: 6, smallBlind: 5, bigBlind: 10, buyInAmount: 500, date: nil, venue: nil
        )
        try sessionService.endSession(session)

        XCTAssertNil(sessionService.getActiveSession())
    }

    // MARK: - getPastSessions

    func testGetPastSessions_returnsEndedSessionsOrderedByDate() throws {
        let session1 = try sessionService.createSession(
            playerCount: 4, smallBlind: 5, bigBlind: 10, buyInAmount: 500, date: nil, venue: "A"
        )
        try sessionService.endSession(session1)

        // Small delay to ensure different timestamps
        let session2 = try sessionService.createSession(
            playerCount: 6, smallBlind: 10, bigBlind: 20, buyInAmount: 1000, date: nil, venue: "B"
        )
        try sessionService.endSession(session2)

        let pastSessions = sessionService.getPastSessions()
        XCTAssertEqual(pastSessions.count, 2)
        // Ordered by startTimestamp descending
        XCTAssertEqual(pastSessions.first?.venue, "B")
        XCTAssertEqual(pastSessions.last?.venue, "A")
    }

    func testGetPastSessions_doesNotIncludeActiveSessions() throws {
        _ = try sessionService.createSession(
            playerCount: 6, smallBlind: 5, bigBlind: 10, buyInAmount: 500, date: nil, venue: nil
        )

        let pastSessions = sessionService.getPastSessions()
        XCTAssertTrue(pastSessions.isEmpty)
    }

    // MARK: - getSessionSummary

    func testGetSessionSummary_computesCorrectTotals() throws {
        let session = try sessionService.createSession(
            playerCount: 6, smallBlind: 5, bigBlind: 10, buyInAmount: 500, date: nil, venue: nil
        )

        let player1 = try playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)
        let player2 = try playerService.addPlayer(to: session, name: "Bob", upiHandle: nil)

        // Player1: 500 collected cash + 500 outstanding
        _ = try transactionService.recordBuyIn(for: player1, amount: 500, method: .cash, collected: true)
        _ = try transactionService.recordReBuyIn(for: player1, amount: 500, method: .cash, collected: false)

        // Player2: 500 collected UPI
        _ = try transactionService.recordBuyIn(for: player2, amount: 500, method: .upi, collected: true)

        let summary = sessionService.getSessionSummary(session)

        XCTAssertEqual(summary.playerCount, 2)
        XCTAssertEqual(summary.totalBuyIns, 3)
        XCTAssertEqual(summary.totalCollected, 1000) // 500 + 500
        XCTAssertEqual(summary.totalOutstanding, 500)
        XCTAssertEqual(summary.collectedByCash, 500)
        XCTAssertEqual(summary.collectedByUPI, 500)
    }
}
