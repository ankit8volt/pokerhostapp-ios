import XCTest
import CoreData
@testable import PokerHomeGameManager

final class TransactionServiceTests: XCTestCase {
    var coreDataStack: CoreDataStack!
    var sessionService: SessionService!
    var playerService: PlayerService!
    var transactionService: TransactionService!
    var session: Session!
    var player: Player!

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
        player = try! playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)
    }

    override func tearDown() {
        player = nil
        session = nil
        transactionService = nil
        playerService = nil
        sessionService = nil
        coreDataStack = nil
        super.tearDown()
    }

    // MARK: - recordBuyIn

    func testRecordBuyIn_createsTransactionWithTypeBuyIn() throws {
        let txn = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: true)

        XCTAssertEqual(txn.type, "buyIn")
        XCTAssertEqual(txn.amount as? Decimal, 500)
        XCTAssertEqual(txn.paymentMethod, "cash")
        XCTAssertTrue(txn.collected)
        XCTAssertNotNil(txn.id)
        XCTAssertNotNil(txn.timestamp)
    }

    // MARK: - recordReBuyIn

    func testRecordReBuyIn_createsTransactionWithTypeReBuyIn() throws {
        let txn = try transactionService.recordReBuyIn(for: player, amount: 300, method: .upi, collected: true)

        XCTAssertEqual(txn.type, "reBuyIn")
        XCTAssertEqual(txn.amount as? Decimal, 300)
        XCTAssertEqual(txn.paymentMethod, "upi")
        XCTAssertTrue(txn.collected)
    }

    // MARK: - collected flag

    func testRecordBuyIn_collectedTrue_flagIsTrue() throws {
        let txn = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: true)
        XCTAssertTrue(txn.collected)
    }

    func testRecordBuyIn_collectedFalse_flagIsFalse() throws {
        let txn = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: false)
        XCTAssertFalse(txn.collected)
    }

    // MARK: - getOutstandingBalance

    func testGetOutstandingBalance_sumsOnlyUncollectedBuyInAndReBuyIn() throws {
        _ = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: true)
        _ = try transactionService.recordReBuyIn(for: player, amount: 300, method: .cash, collected: false)
        _ = try transactionService.recordReBuyIn(for: player, amount: 200, method: .upi, collected: false)

        let outstanding = transactionService.getOutstandingBalance(for: player)
        XCTAssertEqual(outstanding, 500) // 300 + 200
    }

    func testGetOutstandingBalance_excludesCollectedTransactions() throws {
        _ = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: true)
        _ = try transactionService.recordReBuyIn(for: player, amount: 300, method: .cash, collected: true)

        let outstanding = transactionService.getOutstandingBalance(for: player)
        XCTAssertEqual(outstanding, 0)
    }

    // MARK: - getTotalCollected

    func testGetTotalCollected_sumsOnlyCollectedAmountsAcrossSession() throws {
        let player2 = try playerService.addPlayer(to: session, name: "Bob", upiHandle: nil)

        _ = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: true)
        _ = try transactionService.recordReBuyIn(for: player, amount: 300, method: .cash, collected: false)
        _ = try transactionService.recordBuyIn(for: player2, amount: 500, method: .upi, collected: true)

        let totalCollected = transactionService.getTotalCollected(for: session)
        XCTAssertEqual(totalCollected, 1000) // 500 + 500
    }

    // MARK: - getTotalOutstanding

    func testGetTotalOutstanding_sumsOnlyUncollectedAmountsAcrossSession() throws {
        let player2 = try playerService.addPlayer(to: session, name: "Bob", upiHandle: nil)

        _ = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: true)
        _ = try transactionService.recordReBuyIn(for: player, amount: 300, method: .cash, collected: false)
        _ = try transactionService.recordBuyIn(for: player2, amount: 500, method: .upi, collected: false)

        let totalOutstanding = transactionService.getTotalOutstanding(for: session)
        XCTAssertEqual(totalOutstanding, 800) // 300 + 500
    }

    // MARK: - markTransactionComplete

    func testMarkTransactionComplete_setsCollectedTrue() throws {
        let txn = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: false)
        XCTAssertFalse(txn.collected)

        try transactionService.markTransactionComplete(txn)
        XCTAssertTrue(txn.collected)
    }

    func testMarkTransactionComplete_reducesOutstandingBalance() throws {
        let txn = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: false)
        XCTAssertEqual(transactionService.getOutstandingBalance(for: player), 500)

        try transactionService.markTransactionComplete(txn)
        XCTAssertEqual(transactionService.getOutstandingBalance(for: player), 0)
    }

    // MARK: - Cancel scenario: no transaction recorded, balance stays zero

    func testNoTransactionRecorded_balanceStaysZero() {
        let outstanding = transactionService.getOutstandingBalance(for: player)
        XCTAssertEqual(outstanding, 0)

        let totalCollected = transactionService.getTotalCollected(for: session)
        XCTAssertEqual(totalCollected, 0)

        let totalOutstanding = transactionService.getTotalOutstanding(for: session)
        XCTAssertEqual(totalOutstanding, 0)
    }
}
