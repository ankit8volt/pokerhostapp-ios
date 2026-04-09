import Foundation
import CoreData

struct PlayerSettlement {
    let player: Player
    let totalBuyInAmount: Decimal
    let outstandingBalance: Decimal
    let finalChipCount: Decimal
    let netAmount: Decimal
    var isCompleted: Bool
}

struct SettlementCalculator {
    /// Calculates settlement amounts for each player.
    /// Chip count = actual INR value of chips the player holds.
    /// netAmount = chipCount - outstandingBalance
    /// Positive = host owes player, Negative = player owes host.
    static func calculateSettlements(players: [Player], transactionService: TransactionServiceProtocol) -> [PlayerSettlement] {
        return players.map { player in
            let transactions = transactionService.getTransactions(for: player)
            let totalBuyIn = transactions
                .filter { $0.type == "buyIn" || $0.type == "reBuyIn" }
                .reduce(Decimal.zero) { $0 + (($1.amount as? Decimal) ?? Decimal.zero) }

            let outstanding = transactionService.getOutstandingBalance(for: player)
            let finalChips = (player.finalChipCount as? Decimal) ?? Decimal.zero
            let net = finalChips - outstanding

            return PlayerSettlement(
                player: player,
                totalBuyInAmount: totalBuyIn,
                outstandingBalance: outstanding,
                finalChipCount: finalChips,
                netAmount: net,
                isCompleted: false
            )
        }
    }
}
