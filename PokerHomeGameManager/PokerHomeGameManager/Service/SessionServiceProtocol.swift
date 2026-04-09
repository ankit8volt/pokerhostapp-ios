import Foundation
import CoreData

protocol SessionServiceProtocol {
    func createSession(playerCount: Int, smallBlind: Decimal, bigBlind: Decimal, buyInAmount: Decimal, date: Date?, venue: String?) throws -> Session
    func endSession(_ session: Session) throws
    func getActiveSession() -> Session?
    func getPastSessions() -> [Session]
    func getSessionSummary(_ session: Session) -> SessionSummary
}
