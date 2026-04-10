import XCTest
import CoreData
@testable import PokerHomeGameManager

final class SessionSummaryTests: XCTestCase {
    var coreDataStack: CoreDataStack!
    var sessionService: SessionService!
    var playerService: PlayerService!
    var transactionService: TransactionService!
    var session: Session!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
        let context = coreDataStack.viewContext
        sessionService = SessionService(context: context)
        playerService = PlayerService(context: context)
        transactionService = TransactionService(context: context)
        session = try! sessionService.createSession(
            playerCount: 6, smallBlind: 5, bigBlind: 10, buyInAmount: 500, date: nil, venue: nil
        )
    }

    override func tearDown() {
        session = nil
        transactionService = nil
        playerService = nil
        sessionService = nil
        coreDataStack = nil
        super.tearDown()
    }

    // MARK: - totalCollected splits correctly between cash and UPI

    func testSummary_totalCollectedSplitsCorrectly() throws {
        let player = try playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)

        _ = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: true)
        _ = try transactionService.recordReBuyIn(for: player, amount: 300, method: .upi, collected: true)

        let summary = sessionService.getSessionSummary(session)

        XCTAssertEqual(summary.totalCollected, 800)
        XCTAssertEqual(summary.collectedByCash, 500)
        XCTAssertEqual(summary.collectedByUPI, 300)
        XCTAssertEqual(summary.collectedByCash + summary.collectedByUPI, summary.totalCollected)
    }

    // MARK: - collectedByCash only counts cash method

    func testSummary_collectedByCash_onlyCountsCashMethod() throws {
        let player = try playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)

        _ = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: true)
        _ = try transactionService.recordReBuyIn(for: player, amount: 300, method: .upi, collected: true)
        _ = try transactionService.recordReBuyIn(for: player, amount: 200, method: .cash, collected: true)

        let summary = sessionService.getSessionSummary(session)

        XCTAssertEqual(summary.collectedByCash, 700) // 500 + 200
    }

    // MARK: - collectedByUPI only counts UPI method

    func testSummary_collectedByUPI_onlyCountsUPIMethod() throws {
        let player = try playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)

        _ = try transactionService.recordBuyIn(for: player, amount: 500, method: .upi, collected: true)
        _ = try transactionService.recordReBuyIn(for: player, amount: 300, method: .cash, collected: true)
        _ = try transactionService.recordReBuyIn(for: player, amount: 200, method: .upi, collected: true)

        let summary = sessionService.getSessionSummary(session)

        XCTAssertEqual(summary.collectedByUPI, 700) // 500 + 200
    }

    // MARK: - totalOutstanding only counts uncollected

    func testSummary_totalOutstanding_onlyCountsUncollected() throws {
        let player = try playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)

        _ = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: true)
        _ = try transactionService.recordReBuyIn(for: player, amount: 300, method: .cash, collected: false)
        _ = try transactionService.recordReBuyIn(for: player, amount: 200, method: .upi, collected: false)

        let summary = sessionService.getSessionSummary(session)

        XCTAssertEqual(summary.totalOutstanding, 500) // 300 + 200
        XCTAssertEqual(summary.totalCollected, 500)
    }

    // MARK: - totalBuyIns counts both buyIn and reBuyIn types

    func testSummary_totalBuyIns_countsBothTypes() throws {
        let player = try playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)

        _ = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: true)
        _ = try transactionService.recordReBuyIn(for: player, amount: 300, method: .cash, collected: true)
        _ = try transactionService.recordReBuyIn(for: player, amount: 200, method: .upi, collected: false)

        let summary = sessionService.getSessionSummary(session)

        XCTAssertEqual(summary.totalBuyIns, 3)
    }

    func testSummary_totalBuyIns_excludesSettlementTransactions() throws {
        let player = try playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)

        _ = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: true)
        _ = try transactionService.recordSettlement(for: player, amount: 200, method: .cash, completed: true)

        let summary = sessionService.getSessionSummary(session)

        // Only the buyIn counts, not the settlement
        XCTAssertEqual(summary.totalBuyIns, 1)
    }

    // MARK: - Per-player breakdown matches individual player transactions

    func testSummary_perPlayerBreakdown_matchesIndividualTransactions() throws {
        let alice = try playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)
        let bob = try playerService.addPlayer(to: session, name: "Bob", upiHandle: nil)

        // Alice: 500 cash collected + 300 upi outstanding
        _ = try transactionService.recordBuyIn(for: alice, amount: 500, method: .cash, collected: true)
        _ = try transactionService.recordReBuyIn(for: alice, amount: 300, method: .upi, collected: false)

        // Bob: 500 upi collected + 200 cash collected
        _ = try transactionService.recordBuyIn(for: bob, amount: 500, method: .upi, collected: true)
        _ = try transactionService.recordReBuyIn(for: bob, amount: 200, method: .cash, collected: true)

        let summary = sessionService.getSessionSummary(session)

        XCTAssertEqual(summary.playerCount, 2)
        XCTAssertEqual(summary.perPlayerBreakdown.count, 2)

        let aliceBreakdown = summary.perPlayerBreakdown.first { $0.playerName == "Alice" }!
        XCTAssertEqual(aliceBreakdown.buyInCount, 2)
        XCTAssertEqual(aliceBreakdown.amountCollected, 500)
        XCTAssertEqual(aliceBreakdown.collectedByCash, 500)
        XCTAssertEqual(aliceBreakdown.collectedByUPI, 0)
        XCTAssertEqual(aliceBreakdown.outstandingBalance, 300)

        let bobBreakdown = summary.perPlayerBreakdown.first { $0.playerName == "Bob" }!
        XCTAssertEqual(bobBreakdown.buyInCount, 2)
        XCTAssertEqual(bobBreakdown.amountCollected, 700)
        XCTAssertEqual(bobBreakdown.collectedByCash, 200)
        XCTAssertEqual(bobBreakdown.collectedByUPI, 500)
        XCTAssertEqual(bobBreakdown.outstandingBalance, 0)

        // Verify totals match sum of breakdowns
        let totalCollectedFromBreakdowns = summary.perPlayerBreakdown.reduce(Decimal.zero) { $0 + $1.amountCollected }
        XCTAssertEqual(summary.totalCollected, totalCollectedFromBreakdowns)

        let totalOutstandingFromBreakdowns = summary.perPlayerBreakdown.reduce(Decimal.zero) { $0 + $1.outstandingBalance }
        XCTAssertEqual(summary.totalOutstanding, totalOutstandingFromBreakdowns)
    }

    // MARK: - Empty session summary

    func testSummary_emptySession_allZeros() {
        let summary = sessionService.getSessionSummary(session)

        XCTAssertEqual(summary.totalCollected, 0)
        XCTAssertEqual(summary.collectedByCash, 0)
        XCTAssertEqual(summary.collectedByUPI, 0)
        XCTAssertEqual(summary.totalOutstanding, 0)
        XCTAssertEqual(summary.totalBuyIns, 0)
        XCTAssertEqual(summary.playerCount, 0)
        XCTAssertTrue(summary.perPlayerBreakdown.isEmpty)
    }
}
