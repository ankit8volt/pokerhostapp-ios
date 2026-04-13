import SwiftUI

struct TransactionHistoryView: View {
    let session: Session
    let sessionService: SessionServiceProtocol
    let transactionService: TransactionServiceProtocol
    let playerService: PlayerServiceProtocol

    @State private var transactions: [TransactionRow] = []

    var body: some View {
        List {
            if transactions.isEmpty {
                Section {
                    Text("No transactions yet").foregroundColor(.secondary)
                        .listRowBackground(Color.pokerCardWhite)
                }
            } else {
                Section {
                    ForEach(transactions) { txn in
                        transactionRowView(txn)
                            .listRowBackground(Color.pokerCardWhite)
                    }
                } header: {
                    Text("\(transactions.count) transactions").foregroundColor(.pokerGold)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.pokerDarkGreen)
        .navigationTitle("📋 Transaction Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.pokerDarkGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { loadTransactions() }
    }

    @ViewBuilder
    private func transactionRowView(_ txn: TransactionRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(txn.playerName).font(.subheadline.bold())
                Spacer()
                Text("₹\(txn.amount)").font(.subheadline.bold())
                    .foregroundColor(txn.type == "settlementPayout" ? .orange : .pokerGreen)
            }
            HStack {
                Text(txn.typeIcon + " " + txn.typeLabel)
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
                Text(txn.methodIcon)
                    .font(.caption)
                Text(txn.statusIcon)
                    .font(.caption)
            }
            HStack {
                Text(txn.relativeTime).font(.caption2).foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }

    private func loadTransactions() {
        let activePlayers = playerService.getActivePlayers(in: session)
        let checkedOutPlayers = playerService.getCheckedOutPlayers(in: session)
        let allPlayers = activePlayers + checkedOutPlayers

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated

        var rows: [TransactionRow] = []
        for player in allPlayers {
            let txns = transactionService.getTransactions(for: player)
            for txn in txns {
                let amount = (txn.amount as? Decimal) ?? 0
                let type = txn.type ?? "unknown"
                let method = txn.paymentMethod ?? "cash"
                let timestamp = txn.timestamp ?? Date()

                let (icon, label) = typeDisplay(type)
                let methodIcon = method == "upi" ? "📱 UPI" : "💵 Cash"
                let statusIcon = txn.collected ? "✅ Collected" : "⏳ Pending"
                let relative = formatter.localizedString(for: timestamp, relativeTo: Date())

                rows.append(TransactionRow(
                    id: txn.id ?? UUID(),
                    playerName: player.name ?? "Unknown",
                    type: type,
                    typeIcon: icon,
                    typeLabel: label,
                    amount: amount,
                    methodIcon: methodIcon,
                    statusIcon: statusIcon,
                    relativeTime: relative,
                    timestamp: timestamp))
            }
        }
        transactions = rows.sorted { $0.timestamp > $1.timestamp }
    }

    private func typeDisplay(_ type: String) -> (String, String) {
        switch type {
        case "buyIn": return ("💰", "Buy-In")
        case "reBuyIn": return ("🔄", "Re-Buy")
        case "settlementPayout": return ("💸", "Settlement")
        case "settlementCollect": return ("💸", "Settlement")
        default: return ("🚪", "Checkout")
        }
    }
}

private struct TransactionRow: Identifiable {
    let id: UUID
    let playerName: String
    let type: String
    let typeIcon: String
    let typeLabel: String
    let amount: Decimal
    let methodIcon: String
    let statusIcon: String
    let relativeTime: String
    let timestamp: Date
}
