import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var pastSessions: [Session] = []
    @Published var hasActiveSession: Bool = false

    private let sessionService: SessionServiceProtocol
    private let hostService: HostServiceProtocol

    init(sessionService: SessionServiceProtocol, hostService: HostServiceProtocol) {
        self.sessionService = sessionService
        self.hostService = hostService
        refresh()
    }

    func refresh() {
        pastSessions = sessionService.getPastSessions()
        hasActiveSession = sessionService.getActiveSession() != nil
    }

    func getActiveSession() -> Session? {
        return sessionService.getActiveSession()
    }

    func hostName() -> String {
        return hostService.getHost()?.name ?? "Host"
    }
}
