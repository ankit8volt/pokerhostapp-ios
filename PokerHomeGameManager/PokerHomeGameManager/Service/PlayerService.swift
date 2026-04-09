import Foundation
import CoreData

class PlayerService: PlayerServiceProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func addPlayer(to session: Session, name: String, upiHandle: String?) throws -> Player {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.invalidPlayerName
        }

        let player = Player(context: context)
        player.id = UUID()  
        player.name = trimmedName
        player.upiHandle = upiHandle?.trimmingCharacters(in: .whitespacesAndNewlines)
        player.status = "active"
        player.finalChipCount = 0
        player.settlementAmount = 0
        player.settlementCompleted = false
        player.session = session

        try context.save()
        return player
    }

    func checkoutPlayer(_ player: Player, settlementAmount: Decimal) throws {
        player.status = "checkedOut"
        player.settlementAmount = settlementAmount as NSDecimalNumber
        try context.save()
    }

    func getActivePlayers(in session: Session) -> [Player] {
        let request: NSFetchRequest<Player> = Player.fetchRequest()
        request.predicate = NSPredicate(format: "session == %@ AND status == %@", session, "active")
        return (try? context.fetch(request)) ?? []
    }

    func getCheckedOutPlayers(in session: Session) -> [Player] {
        let request: NSFetchRequest<Player> = Player.fetchRequest()
        request.predicate = NSPredicate(format: "session == %@ AND status == %@", session, "checkedOut")
        return (try? context.fetch(request)) ?? []
    }

    func setFinalChipCount(_ player: Player, chipCount: Decimal) throws {
        player.finalChipCount = chipCount as NSDecimalNumber
        try context.save()
    }
}
