import Foundation
import Combine

class SettlementViewModel: ObservableObject {
    // MARK: - Published State
    @Published var activePlayers: [Player] = []
    @Published var settlements: [PlayerSettlement] = []
    @Published var allSettlementsComplete: Bool = false
    @Published var errorMessage: String = ""
    @Published var showIncompleteWarning: Bool = false

    // MARK: - Services
    private let sessionService: SessionServiceProtocol
    private let playerService: PlayerServiceProtocol
    private let transactionService: TransactionServiceProtocol
    private let upiService: UPIServiceProtocol

    private var currentSession: Session?

    init(sessionService: SessionServiceProtocol,
         playerService: PlayerServiceProtocol,
         transactionService: TransactionServiceProtocol,
         upiService: UPIServiceProtocol) {
        self.sessionService = sessionService
        self.playerService = playerService
        self.transactionService = transactionService
        self.upiService = upiService
    }

    // MARK: - Load Players

    func loadPlayers(session: Session) {
        currentSession = session
        activePlayers = playerService.getActivePlayers(in: session)
    }

    // MARK: - Set Chip Count

    func setChipCount(player: Player, count: Decimal) {
        do {
            try playerService.setFinalChipCount(player, chipCount: count)
            if let session = currentSession {
                activePlayers = playerService.getActivePlayers(in: session)
            }
        } catch {
            errorMessage = "Failed to set chip count."
        }
    }

    // MARK: - Calculate Settlements

    func calculateSettlements() {
        settlements = SettlementCalculator.calculateSettlements(
            players: activePlayers,
            transactionService: transactionService
        )
        updateCompletionStatus()
    }

    // MARK: - Confirm Settlement

    func confirmSettlement(player: Player, method: PaymentMethod) {
        guard let index = settlements.firstIndex(where: { $0.player.id == player.id }) else {
            errorMessage = "Player not found in settlements."
            return
        }

        let settlement = settlements[index]

        do {
            _ = try transactionService.recordSettlement(
                for: player,
                amount: settlement.netAmount,
                method: method,
                completed: true
            )
            player.settlementCompleted = true
            player.settlementAmount = settlement.netAmount as NSDecimalNumber
            settlements[index].isCompleted = true
            updateCompletionStatus()
        } catch {
            errorMessage = "Failed to record settlement."
        }
    }

    // MARK: - End Session

    func endSession() {
        guard let session = currentSession else {
            errorMessage = "No active session."
            return
        }

        let hasIncomplete = settlements.contains { !$0.isCompleted && $0.netAmount != 0 }

        if hasIncomplete {
            showIncompleteWarning = true
            return
        }

        finalizeSession(session)
    }

    /// Force-close the session even with pending settlements.
    func endSessionWithPendingSettlements() {
        guard let session = currentSession else {
            errorMessage = "No active session."
            return
        }
        showIncompleteWarning = false
        finalizeSession(session)
    }

    // MARK: - Private Helpers

    private func finalizeSession(_ session: Session) {
        do {
            try sessionService.endSession(session)
            currentSession = nil
        } catch {
            errorMessage = "Failed to end session."
        }
    }

    private func updateCompletionStatus() {
        allSettlementsComplete = !settlements.isEmpty && settlements.allSatisfy { $0.isCompleted || $0.netAmount == 0 }
    }
}
