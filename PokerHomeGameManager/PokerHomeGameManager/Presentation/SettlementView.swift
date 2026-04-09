import SwiftUI

struct SettlementView: View {
    @StateObject private var viewModel: SettlementViewModel
    let session: Session
    var onSessionEnded: () -> Void

    init(session: Session,
         sessionService: SessionServiceProtocol,
         playerService: PlayerServiceProtocol,
         transactionService: TransactionServiceProtocol,
         upiService: UPIServiceProtocol,
         onSessionEnded: @escaping () -> Void) {
        self.session = session
        self.onSessionEnded = onSessionEnded
        _viewModel = StateObject(wrappedValue: SettlementViewModel(
            sessionService: sessionService,
            playerService: playerService,
            transactionService: transactionService,
            upiService: upiService
        ))
    }

    var body: some View {
        List {
            Section {
                ForEach(viewModel.activePlayers, id: \.id) { player in
                    ChipCountRow(player: player, viewModel: viewModel)
                        .listRowBackground(Color.pokerCardWhite)
                }
            } header: {
                Text("Enter Final Chip Counts").foregroundColor(.pokerGold)
            }

            Section {
                Button {
                    withAnimation { viewModel.calculateSettlements() }
                } label: {
                    HStack {
                        Spacer()
                        Text("📊  Calculate Settlements").font(.headline).foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.pokerGold)
            }

            if !viewModel.settlements.isEmpty {
                Section {
                    ForEach(viewModel.settlements, id: \.player.id) { settlement in
                        SettlementRow(settlement: settlement, viewModel: viewModel)
                            .listRowBackground(Color.pokerCardWhite)
                    }
                } header: {
                    Text("Settlement Summary").foregroundColor(.pokerGold)
                }
            }

            if !viewModel.errorMessage.isEmpty {
                Section {
                    Text(viewModel.errorMessage).foregroundColor(.pokerRed)
                        .listRowBackground(Color.pokerCardWhite)
                }
            }

            Section {
                Button {
                    viewModel.endSession()
                } label: {
                    HStack {
                        Spacer()
                        Text("🔒  Close Session").font(.headline).foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.pokerRed)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.pokerDarkGreen)
        .navigationTitle("Settlement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.pokerDarkGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .scrollDismissesKeyboard(.interactively)
        .onAppear { viewModel.loadPlayers(session: session) }
        .alert("Incomplete Settlements", isPresented: $viewModel.showIncompleteWarning) {
            Button("Close Anyway", role: .destructive) {
                viewModel.endSessionWithPendingSettlements()
                onSessionEnded()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Some settlements are still pending. Close the session anyway?")
        }
    }
}

private struct ChipCountRow: View {
    let player: Player
    @ObservedObject var viewModel: SettlementViewModel
    @State private var chipText = ""

    var body: some View {
        HStack {
            Image(systemName: "person.fill").foregroundColor(.pokerGold)
            Text(player.name ?? "Unknown").font(.subheadline)
            Spacer()
            TextField("Chips", text: $chipText)
                .keyboardType(.decimalPad)
                .frame(width: 100)
                .multilineTextAlignment(.trailing)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .onChange(of: chipText) { _, newValue in
                    if let val = Decimal(string: newValue) {
                        viewModel.setChipCount(player: player, count: val)
                    }
                }
        }
    }
}

private struct SettlementRow: View {
    let settlement: PlayerSettlement
    @ObservedObject var viewModel: SettlementViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(settlement.player.name ?? "Unknown").font(.subheadline.bold())
                Spacer()
                if settlement.isCompleted {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                } else if settlement.netAmount != 0 {
                    Image(systemName: "clock.fill").foregroundColor(.orange)
                }
            }

            // Show breakdown: chips, outstanding, net
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Chips: ₹\(settlement.finalChipCount)")
                    Spacer()
                    Text("Buy-Ins: ₹\(settlement.totalBuyInAmount)")
                }
                if settlement.outstandingBalance > 0 {
                    Text("Outstanding: -₹\(settlement.outstandingBalance)")
                        .foregroundColor(.pokerRed)
                }
            }
            .font(.caption).foregroundColor(.secondary)

            // Net = chipCount - outstandingBalance
            if settlement.netAmount > 0 {
                Text("Host pays player: ₹\(settlement.netAmount)")
                    .font(.subheadline.bold()).foregroundColor(.green)
            } else if settlement.netAmount < 0 {
                Text("Player owes host: ₹\(absDecimal(settlement.netAmount))")
                    .font(.subheadline.bold()).foregroundColor(.pokerRed)
            } else {
                Text("Even — no settlement needed").font(.subheadline).foregroundColor(.secondary)
            }

            if !settlement.isCompleted && settlement.netAmount != 0 {
                HStack(spacing: 10) {
                    Button("💵 Cash") {
                        withAnimation { viewModel.confirmSettlement(player: settlement.player, method: .cash) }
                    }
                    .font(.caption).padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.pokerGreen.opacity(0.15)).foregroundColor(.pokerGreen).cornerRadius(8)

                    Button("📱 UPI") {
                        withAnimation { viewModel.confirmSettlement(player: settlement.player, method: .upi) }
                    }
                    .font(.caption).padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.blue.opacity(0.15)).foregroundColor(.blue).cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private func absDecimal(_ value: Decimal) -> Decimal {
    value < 0 ? -value : value
}
