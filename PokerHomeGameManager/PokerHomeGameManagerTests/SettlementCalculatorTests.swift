import XCTest
import CoreData
@testable import PokerHomeGameManager

final class SettlementCalculatorTests: XCTestCase {
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

    // MARK: - Settlement = chipCount - outstandingBalance (NOT chipCount - totalBuyIn)

    func testSettlement_equalsChipCountMinusOutstandingBalance() throws {
        let player = try playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)

        // Buy-in 500 collected, re-buy 300 outstanding
        _ = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: true)
        _ = try transactionService.recordReBuyIn(for: player, amount: 300, method: .cash, collected: false)

        try playerService.setFinalChipCount(player, chipCount: 1000)

        let settlements = SettlementCalculator.calculateSettlements(
            players: [player], transactionService: transactionService
        )

        XCTAssertEqual(settlements.count, 1)
        let s = settlements[0]
        // net = chipCount(1000) - outstanding(300) = 700, NOT chipCount(1000) - totalBuyIn(800) = 200
        XCTAssertEqual(s.netAmount, 700)
        XCTAssertEqual(s.outstandingBalance, 300)
        XCTAssertEqual(s.totalBuyInAmount, 800)
        XCTAssertEqual(s.finalChipCount, 1000)
    }

    // MARK: - Positive net = host owes player

    func testPositiveNet_hostOwesPlayer() throws {
        let player = try playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)
        _ = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: false)
        try playerService.setFinalChipCount(player, chipCount: 800)

        let settlements = SettlementCalculator.calculateSettlements(
            players: [player], transactionService: transactionService
        )

        // net = 800 - 500 = 300 (positive → host owes player)
        XCTAssertEqual(settlements[0].netAmount, 300)
        XCTAssertGreaterThan(settlements[0].netAmount, 0)
    }

    // MARK: - Negative net = player owes host

    func testNegativeNet_playerOwesHost() throws {
        let player = try playerService.addPlayer(to: session, name: "Bob", upiHandle: nil)
        _ = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: false)
        try playerService.setFinalChipCount(player, chipCount: 200)

        let settlements = SettlementCalculator.calculateSettlements(
            players: [player], transactionService: transactionService
        )

        // net = 200 - 500 = -300 (negative → player owes host)
        XCTAssertEqual(settlements[0].netAmount, -300)
        XCTAssertLessThan(settlements[0].netAmount, 0)
    }

    // MARK: - Zero net = even

    func testZeroNet_even() throws {
        let player = try playerService.addPlayer(to: session, name: "Charlie", upiHandle: nil)
        _ = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: false)
        try playerService.setFinalChipCount(player, chipCount: 500)

        let settlements = SettlementCalculator.calculateSettlements(
            players: [player], transactionService: transactionService
        )

        XCTAssertEqual(settlements[0].netAmount, 0)
    }

    // MARK: - Multiple buy-ins and re-buy-ins, some collected some outstanding

    func testMultipleBuyIns_mixedCollectedAndOutstanding() throws {
        let player = try playerService.addPlayer(to: session, name: "Dave", upiHandle: nil)

        // Buy-in 500 collected
        _ = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: true)
        // Re-buy 300 outstanding
        _ = try transactionService.recordReBuyIn(for: player, amount: 300, method: .cash, collected: false)
        // Re-buy 200 collected
        _ = try transactionService.recordReBuyIn(for: player, amount: 200, method: .upi, collected: true)
        // Re-buy 400 outstanding
        _ = try transactionService.recordReBuyIn(for: player, amount: 400, method: .cash, collected: false)

        try playerService.setFinalChipCount(player, chipCount: 1500)

        let settlements = SettlementCalculator.calculateSettlements(
            players: [player], transactionService: transactionService
        )

        let s = settlements[0]
        // totalBuyIn = 500 + 300 + 200 + 400 = 1400
        XCTAssertEqual(s.totalBuyInAmount, 1400)
        // outstanding = 300 + 400 = 700
        XCTAssertEqual(s.outstandingBalance, 700)
        // net = 1500 - 700 = 800
        XCTAssertEqual(s.netAmount, 800)
        XCTAssertEqual(s.finalChipCount, 1500)
    }

    // MARK: - Settlement with zero outstanding → net equals chip count

    func testZeroOutstanding_netEqualsChipCount() throws {
        let player = try playerService.addPlayer(to: session, name: "Eve", upiHandle: nil)

        // All buy-ins collected
        _ = try transactionService.recordBuyIn(for: player, amount: 500, method: .cash, collected: true)
        _ = try transactionService.recordReBuyIn(for: player, amount: 300, method: .upi, collected: true)

        try playerService.setFinalChipCount(player, chipCount: 900)

        let settlements = SettlementCalculator.calculateSettlements(
            players: [player], transactionService: transactionService
        )

        let s = settlements[0]
        XCTAssertEqual(s.outstandingBalance, 0)
        // net = chipCount - 0 = chipCount
        XCTAssertEqual(s.netAmount, 900)
        XCTAssertEqual(s.netAmount, s.finalChipCount)
    }

    // MARK: - Multiple players settlement

    func testMultiplePlayersSettlement() throws {
        let alice = try playerService.addPlayer(to: session, name: "Alice", upiHandle: nil)
        let bob = try playerService.addPlayer(to: session, name: "Bob", upiHandle: nil)

        _ = try transactionService.recordBuyIn(for: alice, amount: 500, method: .cash, collected: false)
        _ = try transactionService.recordBuyIn(for: bob, amount: 500, method: .cash, collected: false)

        try playerService.setFinalChipCount(alice, chipCount: 700)
        try playerService.setFinalChipCount(bob, chipCount: 300)

        let settlements = SettlementCalculator.calculateSettlements(
            players: [alice, bob], transactionService: transactionService
        )

        XCTAssertEqual(settlements.count, 2)

        let aliceSettlement = settlements.first { $0.player.name == "Alice" }!
        let bobSettlement = settlements.first { $0.player.name == "Bob" }!

        // Alice: 700 - 500 = 200 (host owes)
        XCTAssertEqual(aliceSettlement.netAmount, 200)
        // Bob: 300 - 500 = -200 (player owes)
        XCTAssertEqual(bobSettlement.netAmount, -200)
    }
}
