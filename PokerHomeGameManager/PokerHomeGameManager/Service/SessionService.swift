import Foundation
import CoreData

class SessionService: SessionServiceProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func createSession(playerCount: Int, smallBlind: Decimal, bigBlind: Decimal, buyInAmount: Decimal, date: Date?, venue: String?) throws -> Session {
        if smallBlind <= 0 {
            throw ValidationError.invalidSessionParameters("Small blind must be positive")
        }
        if bigBlind <= 0 {
            throw ValidationError.invalidSessionParameters("Big blind must be positive")
        }
        if bigBlind <= smallBlind {
            throw ValidationError.invalidSessionParameters("Big blind must exceed small blind")
        }
        if buyInAmount <= 0 {
            throw ValidationError.invalidSessionParameters("Buy-in amount must be positive")
        }

        let session = Session(context: context)
        session.id = UUID()
        session.smallBlind = smallBlind as NSDecimalNumber
        session.bigBlind = bigBlind as NSDecimalNumber
        session.buyInAmount = buyInAmount as NSDecimalNumber
        session.startTimestamp = Date()
        session.sessionDate = date
        session.venue = venue
        session.isActive = true

        try context.save()
        return session
    }

    func endSession(_ session: Session) throws {
        session.isActive = false
        session.endTimestamp = Date()
        try context.save()
    }

    func getActiveSession() -> Session? {
        let request: NSFetchRequest<Session> = Session.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    func getPastSessions() -> [Session] {
        let request: NSFetchRequest<Session> = Session.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "startTimestamp", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    func getSessionSummary(_ session: Session) -> SessionSummary {
        let players = (session.players as? Set<Player>) ?? []

        var totalCollected: Decimal = 0
        var totalCash: Decimal = 0
        var totalUPI: Decimal = 0
        var totalOutstanding: Decimal = 0
        var totalSettledPayouts: Decimal = 0
        var totalBuyIns: Int = 0
        var breakdowns: [PlayerBreakdown] = []

        for player in players {
            let transactions = (player.transactions as? Set<Transaction>) ?? []
            var playerCollected: Decimal = 0
            var playerCash: Decimal = 0
            var playerUPI: Decimal = 0
            var playerOutstanding: Decimal = 0
            var buyInCount: Int = 0

            for transaction in transactions {
                let amount = (transaction.amount as? Decimal) ?? 0
                let type = transaction.type ?? ""
                let method = transaction.paymentMethod ?? ""

                if type == "buyIn" || type == "reBuyIn" {
                    buyInCount += 1
                    if transaction.collected {
                        playerCollected += amount
                        if method == "cash" { playerCash += amount }
                        else { playerUPI += amount }
                    } else {
                        playerOutstanding += amount
                    }
                }
            }

            // For checked-out players, settled = their chip count (what they walked away with)
            if player.status == "checkedOut" {
                let chipCount = (player.finalChipCount as? Decimal) ?? 0
                totalSettledPayouts += chipCount
            }

            totalCollected += playerCollected
            totalCash += playerCash
            totalUPI += playerUPI
            totalOutstanding += playerOutstanding
            totalBuyIns += buyInCount

            breakdowns.append(PlayerBreakdown(
                playerName: player.name ?? "",
                buyInCount: buyInCount,
                amountCollected: playerCollected,
                collectedByCash: playerCash,
                collectedByUPI: playerUPI,
                outstandingBalance: playerOutstanding
            ))
        }

        return SessionSummary(
            totalCollected: totalCollected,
            collectedByCash: totalCash,
            collectedByUPI: totalUPI,
            totalOutstanding: totalOutstanding,
            totalSettledPayouts: totalSettledPayouts,
            totalBuyIns: totalBuyIns,
            playerCount: players.count,
            perPlayerBreakdown: breakdowns
        )
    }
}
