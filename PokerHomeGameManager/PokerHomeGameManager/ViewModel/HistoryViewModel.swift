import Foundation
import Combine

class HistoryViewModel: ObservableObject {
    // MARK: - Published State
    @Published var pastSessions: [Session] = []
    @Published var sessionSummaries: [UUID: SessionSummary] = [:]

    // MARK: - Services
    private let sessionService: SessionServiceProtocol

    init(sessionService: SessionServiceProtocol) {
        self.sessionService = sessionService
        loadPastSessions()
    }

    // MARK: - Load Past Sessions

    func loadPastSessions() {
        pastSessions = sessionService.getPastSessions()
        sessionSummaries = [:]
        for session in pastSessions {
            if let id = session.id {
                sessionSummaries[id] = sessionService.getSessionSummary(session)
            }
        }
    }

    // MARK: - Get Summary

    func summary(for session: Session) -> SessionSummary? {
        guard let id = session.id else { return nil }
        return sessionSummaries[id]
    }
}
