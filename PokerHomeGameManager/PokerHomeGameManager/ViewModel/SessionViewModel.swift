import Foundation
import Combine

// Cached per-player stats to avoid repeated Core Data fetches during rendering
struct PlayerStats {
    let hasBuyIn: Bool
    let buyInCount: Int
    let collected: Decimal
    let collectedByCash: Decimal
    let collectedByUPI: Decimal
    let outstanding: Decimal
}

class SessionViewModel: ObservableObject {
    // MARK: - Form Fields
    @Published var playerCount: String = ""
    @Published var smallBlind: String = ""
    @Published var bigBlind: String = ""
    @Published var buyInAmount: String = ""
    @Published var sessionDate: Date?
    @Published var venue: String = ""

    // MARK: - Validation Errors
    @Published var smallBlindError: String = ""
    @Published var bigBlindError: String = ""
    @Published var buyInError: String = ""
    @Published var generalError: String = ""

    // MARK: - Active Session State
    @Published var activeSession: Session?
    @Published var sessionSummary: SessionSummary?
    @Published var activePlayers: [Player] = []
    @Published var checkedOutPlayers: [Player] = []
    @Published var playerStatsCache: [UUID: PlayerStats] = [:]

    // MARK: - Services
    let sessionService: SessionServiceProtocol
    let playerService: PlayerServiceProtocol
    let transactionService: TransactionServiceProtocol

    init(sessionService: SessionServiceProtocol,
         playerService: PlayerServiceProtocol,
         transactionService: TransactionServiceProtocol) {
        self.sessionService = sessionService
        self.playerService = playerService
        self.transactionService = transactionService
        self.activeSession = sessionService.getActiveSession()
        if let session = activeSession { refreshSessionData(session) }
    }

    // MARK: - Cached Player Stats (no Core Data fetch during render)

    func stats(for player: Player) -> PlayerStats {
        if let id = player.id, let cached = playerStatsCache[id] { return cached }
        return PlayerStats(hasBuyIn: false, buyInCount: 0, collected: 0, collectedByCash: 0, collectedByUPI: 0, outstanding: 0)
    }

    // MARK: - Session Creation

    func createSession() {
        clearErrors()
        guard let sb = Decimal(string: smallBlind), sb > 0 else { smallBlindError = "Small blind must be positive"; return }
        guard let bb = Decimal(string: bigBlind), bb > 0 else { bigBlindError = "Big blind must be positive"; return }
        if bb <= sb { bigBlindError = "Big blind must exceed small blind"; return }
        guard let buyIn = Decimal(string: buyInAmount), buyIn > 0 else { buyInError = "Buy-in must be positive"; return }
        do {
            let session = try sessionService.createSession(
                playerCount: Int(playerCount) ?? 0, smallBlind: sb, bigBlind: bb, buyInAmount: buyIn,
                date: sessionDate,
                venue: venue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : venue.trimmingCharacters(in: .whitespacesAndNewlines))
            activeSession = session
            refreshSessionData(session)
        } catch { generalError = "Failed to create session." }
    }

    func addPlayer(name: String, upiHandle: String?) {
        guard let session = activeSession else { generalError = "No active session"; return }
        do {
            _ = try playerService.addPlayer(to: session, name: name, upiHandle: upiHandle)
            refreshSessionData(session)
        } catch { generalError = "Failed to add player." }
    }

    func collectBuyIn(player: Player, method: PaymentMethod, collected: Bool) {
        guard let session = activeSession else { return }
        let amount = (session.buyInAmount as? Decimal) ?? 0
        do {
            _ = try transactionService.recordBuyIn(for: player, amount: amount, method: method, collected: collected)
            refreshSessionData(session)
        } catch { generalError = "Failed to record buy-in." }
    }

    func collectReBuyIn(player: Player, method: PaymentMethod, collected: Bool) {
        guard let session = activeSession else { return }
        let amount = (session.buyInAmount as? Decimal) ?? 0
        do {
            _ = try transactionService.recordReBuyIn(for: player, amount: amount, method: method, collected: collected)
            refreshSessionData(session)
        } catch { generalError = "Failed to record re-buy-in." }
    }

    func checkoutPlayer(player: Player, chipCount: Decimal, settlementAmount: Decimal, method: PaymentMethod, completed: Bool) {
        guard let session = activeSession else { return }
        do {
            // Store the chip count for settlement tracking
            try playerService.setFinalChipCount(player, chipCount: chipCount)

            // Mark all pending buy-in/re-buy-in transactions as collected
            let transactions = transactionService.getTransactions(for: player)
            for txn in transactions {
                if (txn.type == "buyIn" || txn.type == "reBuyIn") && !txn.collected {
                    try transactionService.markTransactionComplete(txn)
                }
            }

            _ = try transactionService.recordSettlement(for: player, amount: settlementAmount, method: method, completed: completed)
            try playerService.checkoutPlayer(player, settlementAmount: settlementAmount)
            player.settlementCompleted = completed
            refreshSessionData(session)
        } catch { generalError = "Failed to checkout player." }
    }

    func refreshSession() {
        activeSession = sessionService.getActiveSession()
        if let session = activeSession { refreshSessionData(session) }
        else { activePlayers = []; checkedOutPlayers = []; sessionSummary = nil; playerStatsCache = [:] }
    }

    private func refreshSessionData(_ session: Session) {
        activePlayers = playerService.getActivePlayers(in: session)
        checkedOutPlayers = playerService.getCheckedOutPlayers(in: session)
        sessionSummary = sessionService.getSessionSummary(session)
        rebuildStatsCache()
    }

    private func rebuildStatsCache() {
        var cache: [UUID: PlayerStats] = [:]
        let allPlayers = activePlayers + checkedOutPlayers
        for player in allPlayers {
            guard let id = player.id else { continue }
            let txns = transactionService.getTransactions(for: player)
            let buyInTxns = txns.filter { $0.type == "buyIn" || $0.type == "reBuyIn" }
            let hasBuyIn = txns.contains { $0.type == "buyIn" }
            let buyInCount = buyInTxns.count
            var cash: Decimal = 0, upi: Decimal = 0, outstanding: Decimal = 0
            for t in buyInTxns {
                let amt = (t.amount as? Decimal) ?? 0
                if t.collected {
                    if t.paymentMethod == "cash" { cash += amt } else { upi += amt }
                } else { outstanding += amt }
            }
            cache[id] = PlayerStats(hasBuyIn: hasBuyIn, buyInCount: buyInCount,
                                     collected: cash + upi, collectedByCash: cash,
                                     collectedByUPI: upi, outstanding: outstanding)
        }
        playerStatsCache = cache
    }

    private func clearErrors() {
        smallBlindError = ""; bigBlindError = ""; buyInError = ""; generalError = ""
    }
}
