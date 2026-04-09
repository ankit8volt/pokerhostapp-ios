import Foundation
import CoreData

class TransactionService: TransactionServiceProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func recordBuyIn(for player: Player, amount: Decimal, method: PaymentMethod, collected: Bool) throws -> Transaction {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.type = "buyIn"
        transaction.amount = amount as NSDecimalNumber
        transaction.paymentMethod = method == .cash ? "cash" : "upi"
        transaction.collected = collected
        transaction.timestamp = Date()
        transaction.player = player

        try context.save()
        return transaction
    }

    func recordReBuyIn(for player: Player, amount: Decimal, method: PaymentMethod, collected: Bool) throws -> Transaction {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.type = "reBuyIn"
        transaction.amount = amount as NSDecimalNumber
        transaction.paymentMethod = method == .cash ? "cash" : "upi"
        transaction.collected = collected
        transaction.timestamp = Date()
        transaction.player = player

        try context.save()
        return transaction
    }

    func recordSettlement(for player: Player, amount: Decimal, method: PaymentMethod, completed: Bool) throws -> Transaction {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.type = amount >= 0 ? "settlementPayout" : "settlementCollect"
        transaction.amount = amount as NSDecimalNumber
        transaction.paymentMethod = method == .cash ? "cash" : "upi"
        transaction.collected = completed
        transaction.timestamp = Date()
        transaction.player = player

        try context.save()
        return transaction
    }

    func markTransactionComplete(_ transaction: Transaction) throws {
        transaction.collected = true
        try context.save()
    }

    func getTransactions(for player: Player) -> [Transaction] {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.predicate = NSPredicate(format: "player == %@", player)
        return (try? context.fetch(request)) ?? []
    }

    func getOutstandingBalance(for player: Player) -> Decimal {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.predicate = NSPredicate(format: "player == %@ AND (type == %@ OR type == %@) AND collected == NO", player, "buyIn", "reBuyIn")
        let transactions = (try? context.fetch(request)) ?? []
        return transactions.reduce(Decimal.zero) { $0 + ((($1.amount) as? Decimal) ?? Decimal.zero) }
    }

    func getTotalCollected(for session: Session) -> Decimal {
        let players = (session.players as? Set<Player>) ?? []
        var total: Decimal = 0
        for player in players {
            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            request.predicate = NSPredicate(format: "player == %@ AND (type == %@ OR type == %@) AND collected == YES", player, "buyIn", "reBuyIn")
            let transactions = (try? context.fetch(request)) ?? []
            total += transactions.reduce(Decimal.zero) { $0 + ((($1.amount) as? Decimal) ?? Decimal.zero) }
        }
        return total
    }

    func getTotalOutstanding(for session: Session) -> Decimal {
        let players = (session.players as? Set<Player>) ?? []
        var total: Decimal = 0
        for player in players {
            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            request.predicate = NSPredicate(format: "player == %@ AND (type == %@ OR type == %@) AND collected == NO", player, "buyIn", "reBuyIn")
            let transactions = (try? context.fetch(request)) ?? []
            total += transactions.reduce(Decimal.zero) { $0 + ((($1.amount) as? Decimal) ?? Decimal.zero) }
        }
        return total
    }
}
