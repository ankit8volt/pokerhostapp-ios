import Foundation
import CoreData

protocol PlayerServiceProtocol {
    func addPlayer(to session: Session, name: String, upiHandle: String?) throws -> Player
    func checkoutPlayer(_ player: Player, settlementAmount: Decimal) throws
    func getActivePlayers(in session: Session) -> [Player]
    func getCheckedOutPlayers(in session: Session) -> [Player]
    func setFinalChipCount(_ player: Player, chipCount: Decimal) throws
}
