import SwiftUI

struct ContentView: View {
    @State private var isRegistered: Bool
    @State private var showCelebration = false

    private let hostService: HostServiceProtocol
    private let sessionService: SessionServiceProtocol
    private let playerService: PlayerServiceProtocol
    private let transactionService: TransactionServiceProtocol
    private let upiService: UPIServiceProtocol

    init() {
        let context = CoreDataStack.shared.viewContext
        let host = HostService(context: context)
        let session = SessionService(context: context)
        let player = PlayerService(context: context)
        let transaction = TransactionService(context: context)
        let upi = UPIService()

        self.hostService = host
        self.sessionService = session
        self.playerService = player
        self.transactionService = transaction
        self.upiService = upi
        _isRegistered = State(initialValue: host.isRegistered())
    }

    var body: some View {
        ZStack {
            NavigationStack {
                Group {
                    if isRegistered {
                        HomeView(
                            sessionService: sessionService,
                            playerService: playerService,
                            transactionService: transactionService,
                            hostService: hostService,
                            upiService: upiService
                        )
                        .transition(.opacity)
                    } else {
                        RegistrationView(hostService: hostService)
                            .onReceive(NotificationCenter.default.publisher(for: .hostRegistered)) { _ in
                                showCelebration = true
                            }
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: isRegistered)
            }
            .tint(.pokerGold)

            if showCelebration {
                CelebrationOverlay(message: "Welcome to Poker Home! 🎉", icon: "🃏") {
                    showCelebration = false
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isRegistered = true
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }
}

extension Notification.Name {
    static let hostRegistered = Notification.Name("hostRegistered")
}
