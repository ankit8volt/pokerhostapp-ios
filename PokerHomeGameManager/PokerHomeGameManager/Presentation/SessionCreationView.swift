import SwiftUI

struct SessionCreationView: View {
    @StateObject private var viewModel: SessionViewModel
    var onSessionCreated: () -> Void

    init(sessionService: SessionServiceProtocol,
         playerService: PlayerServiceProtocol,
         transactionService: TransactionServiceProtocol,
         onSessionCreated: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: SessionViewModel(
            sessionService: sessionService,
            playerService: playerService,
            transactionService: transactionService
        ))
        self.onSessionCreated = onSessionCreated
    }

    var body: some View {
        List {
            Section {
                TextField("Number of Players (optional)", text: $viewModel.playerCount)
                    .keyboardType(.numberPad)

                TextField("Small Blind (₹)", text: $viewModel.smallBlind)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("session_small_blind_field")
                if !viewModel.smallBlindError.isEmpty {
                    Text(viewModel.smallBlindError).font(.caption).foregroundColor(.pokerRed)
                }

                TextField("Big Blind (₹)", text: $viewModel.bigBlind)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("session_big_blind_field")
                if !viewModel.bigBlindError.isEmpty {
                    Text(viewModel.bigBlindError).font(.caption).foregroundColor(.pokerRed)
                }

                TextField("Buy-In Amount (₹)", text: $viewModel.buyInAmount)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("session_buyin_field")
                if !viewModel.buyInError.isEmpty {
                    Text(viewModel.buyInError).font(.caption).foregroundColor(.pokerRed)
                }
            } header: {
                Text("Game Settings").foregroundColor(.pokerGold)
            }

            Section {
                DatePicker("Date", selection: Binding(
                    get: { viewModel.sessionDate ?? Date() },
                    set: { viewModel.sessionDate = $0 }
                ), displayedComponents: .date)

                TextField("Venue / Location", text: $viewModel.venue)
            } header: {
                Text("Optional Details").foregroundColor(.pokerGold)
            }

            if !viewModel.generalError.isEmpty {
                Section {
                    Text(viewModel.generalError).foregroundColor(.pokerRed)
                }
            }

            Section {
                Button {
                    viewModel.createSession()
                } label: {
                    HStack {
                        Spacer()
                        Text("🎰  Create Session").font(.headline).foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.pokerGold)
                .accessibilityIdentifier("session_create_button")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.pokerDarkGreen)
        .navigationTitle("New Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.pokerDarkGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: viewModel.activeSession) { _, newValue in
            if newValue != nil { onSessionCreated() }
        }
    }
}
