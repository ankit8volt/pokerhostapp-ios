import Foundation
import CoreData

protocol TransactionServiceProtocol {
    func recordBuyIn(for player: Player, amount: Decimal, method: PaymentMethod, collected: Bool) throws -> Transaction
    func recordReBuyIn(for player: Player, amount: Decimal, method: PaymentMethod, collected: Bool) throws -> Transaction
    func recordSettlement(for player: Player, amount: Decimal, method: PaymentMethod, completed: Bool) throws -> Transaction
    func markTransactionComplete(_ transaction: Transaction) throws
    func getTransactions(for player: Player) -> [Transaction]
    func getOutstandingBalance(for player: Player) -> Decimal
    func getTotalCollected(for session: Session) -> Decimal
    func getTotalOutstanding(for session: Session) -> Decimal
}
