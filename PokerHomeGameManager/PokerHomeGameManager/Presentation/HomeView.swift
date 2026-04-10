import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var showCreateSession = false
    @State private var showActiveSession = false
    @State private var showHistory = false
    @State private var showProfile = false
    @State private var appear = false

    let sessionService: SessionServiceProtocol
    let playerService: PlayerServiceProtocol
    let transactionService: TransactionServiceProtocol
    let hostService: HostServiceProtocol
    let upiService: UPIServiceProtocol

    init(sessionService: SessionServiceProtocol,
         playerService: PlayerServiceProtocol,
         transactionService: TransactionServiceProtocol,
         hostService: HostServiceProtocol,
         upiService: UPIServiceProtocol) {
        self.sessionService = sessionService
        self.playerService = playerService
        self.transactionService = transactionService
        self.hostService = hostService
        self.upiService = upiService
        _viewModel = StateObject(wrappedValue: HomeViewModel(
            sessionService: sessionService, hostService: hostService))
    }

    var body: some View {
        List {
            // Header
            Section {
                VStack(spacing: 6) {
                    Text("♠️ Stackr")
                        .font(.largeTitle.bold())
                        .foregroundColor(.pokerGold)
                    Text("Welcome, \(viewModel.hostName())")
                        .font(.subheadline)
                        .foregroundColor(.pokerChip.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.pokerDarkGreen)
            }

            // Main Action
            Section {
                if viewModel.hasActiveSession {
                    Button("♣️  Resume Session") {
                        showActiveSession = true
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .listRowBackground(Color.pokerGold)
                    .accessibilityIdentifier("home_resume_session_button")
                } else {
                    Button("🃏  Start New Session") {
                        showCreateSession = true
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .listRowBackground(Color.pokerGold)
                    .accessibilityIdentifier("home_start_session_button")
                }
            }

            // Past Sessions
            Section {
                if viewModel.pastSessions.isEmpty {
                    Text("No past sessions yet. Start your first game!")
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.pokerCardWhite)
                } else {
                    ForEach(viewModel.pastSessions.prefix(5), id: \.id) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.venue ?? "No venue")
                                    .font(.subheadline.bold())
                                if let date = session.sessionDate {
                                    Text(date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .listRowBackground(Color.pokerCardWhite)
                    }
                }

                Button("View All History") {
                    showHistory = true
                }
                .font(.subheadline)
                .foregroundColor(.pokerGold)
                .listRowBackground(Color.pokerCardWhite)
            } header: {
                Text("Recent Sessions").foregroundColor(.pokerGold)
            }

            // Profile
            Section {
                Button {
                    showProfile = true
                } label: {
                    HStack {
                        Image(systemName: "person.circle")
                        Text("Profile Settings")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.pokerChip)
                }
                .listRowBackground(Color.pokerGreen.opacity(0.6))
                .accessibilityIdentifier("home_profile_button")
            }

            // Ad
            Section {
                BannerAdView()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.pokerDarkGreen)
        .navigationTitle("Stackr")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.pokerDarkGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { viewModel.refresh() }
        .navigationDestination(isPresented: $showCreateSession) {
            SessionCreationView(
                sessionService: sessionService,
                playerService: playerService,
                transactionService: transactionService,
                onSessionCreated: {
                    showCreateSession = false
                    showActiveSession = true
                    viewModel.refresh()
                }
            )
        }
        .navigationDestination(isPresented: $showActiveSession) {
            ActiveSessionView(
                sessionService: sessionService,
                playerService: playerService,
                transactionService: transactionService,
                upiService: upiService,
                onSessionEnded: {
                    showActiveSession = false
                    viewModel.refresh()
                }
            )
        }
        .navigationDestination(isPresented: $showHistory) {
            SessionHistoryView(sessionService: sessionService)
        }
        .navigationDestination(isPresented: $showProfile) {
            ProfileSettingsView(hostService: hostService)
        }
    }
}
