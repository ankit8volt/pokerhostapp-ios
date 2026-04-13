import SwiftUI

enum PlayerAction: Identifiable {
    case collect(player: Player, isReBuy: Bool)
    case checkout(player: Player)

    var id: String {
        switch self {
        case .collect(let p, let r): return "collect-\(p.id?.uuidString ?? "")-\(r)"
        case .checkout(let p): return "checkout-\(p.id?.uuidString ?? "")"
        }
    }
}

struct ActiveSessionView: View {
    @StateObject private var viewModel: SessionViewModel
    @State private var showSettlement = false
    @State private var showAddPlayer = false
    @State private var activeAction: PlayerAction?

    private let upiService: UPIServiceProtocol
    var onSessionEnded: () -> Void

    init(sessionService: SessionServiceProtocol,
         playerService: PlayerServiceProtocol,
         transactionService: TransactionServiceProtocol,
         upiService: UPIServiceProtocol,
         onSessionEnded: @escaping () -> Void) {
        self.upiService = upiService
        self.onSessionEnded = onSessionEnded
        _viewModel = StateObject(wrappedValue: SessionViewModel(
            sessionService: sessionService,
            playerService: playerService,
            transactionService: transactionService))
    }

    var body: some View {
        List {
            // Compact Session Summary
            if let s = viewModel.sessionSummary {
                Section {
                    let activeCount = viewModel.activePlayers.count
                    let checkedOutCount = viewModel.checkedOutPlayers.count
                    HStack(spacing: 0) {
                        StatBox(label: "Active", value: "\(activeCount)")
                        StatBox(label: "Buy-Ins", value: "\(s.totalBuyIns)")
                        StatBox(label: "💵", value: "₹\(s.collectedByCash)")
                        StatBox(label: "📱", value: "₹\(s.collectedByUPI)")
                    }
                    let totalAmount = s.totalCollected + s.totalOutstanding
                    if totalAmount > 0 {
                        VStack(spacing: 4) {
                            HStack {
                                Text("Total: ₹\(totalAmount)").font(.caption.bold())
                                if checkedOutCount > 0 {
                                    Spacer()
                                    Text("\(checkedOutCount) checked out").font(.caption2).foregroundColor(.orange)
                                }
                            }
                            HStack {
                                Text("Collected: ₹\(s.totalCollected)").font(.caption2).foregroundColor(.pokerGreen)
                                Spacer()
                                if s.totalOutstanding > 0 {
                                    Text("Pending: ₹\(s.totalOutstanding)").font(.caption2).foregroundColor(.pokerRed)
                                }
                            }
                            if s.totalSettledPayouts > 0 {
                                HStack {
                                    Text("Settled payouts: ₹\(s.totalSettledPayouts)").font(.caption2).foregroundColor(.orange)
                                    Spacer()
                                    let inHand = s.totalCollected - s.totalSettledPayouts
                                    Text("In hand: ₹\(inHand)").font(.caption2.bold()).foregroundColor(.pokerGreen)
                                }
                            }
                        }
                        .listRowBackground(Color.pokerCardWhite)
                    }
                }
            }

            // Players
            Section {
                if viewModel.activePlayers.isEmpty {
                    Text("No players yet — tap + below").foregroundColor(.secondary).listRowBackground(Color.pokerCardWhite)
                } else {
                    ForEach(viewModel.activePlayers, id: \.id) { player in
                        PlayerRow(player: player, viewModel: viewModel,
                                  onCollect: { isReBuy in activeAction = .collect(player: player, isReBuy: isReBuy) },
                                  onCheckout: { activeAction = .checkout(player: player) })
                            .listRowBackground(Color.pokerCardWhite)
                    }
                }
                // Add Player button
                Button { showAddPlayer = true } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill").foregroundColor(.pokerGreen)
                        Text("Add Player").foregroundColor(.pokerGreen)
                    }
                }
                .buttonStyle(.borderless)
                .listRowBackground(Color.pokerCardWhite)
                .accessibilityIdentifier("session_add_player_button")
            } header: { Text("Players (\(viewModel.activePlayers.count))").foregroundColor(.pokerGold) }

            // Checked Out
            if !viewModel.checkedOutPlayers.isEmpty {
                Section {
                    ForEach(viewModel.checkedOutPlayers, id: \.id) { player in
                        let ps = viewModel.stats(for: player)
                        HStack {
                            Image(systemName: "person.fill").foregroundColor(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name ?? "Unknown").font(.subheadline)
                                if ps.outstanding > 0 {
                                    Text("Pending: ₹\(ps.outstanding)").font(.caption2).foregroundColor(.pokerRed)
                                }
                            }
                            Spacer()
                            Text("Checked Out").font(.caption2).foregroundColor(.orange)
                        }
                        .listRowBackground(Color.pokerCardWhite)
                    }
                } header: { Text("Checked Out").foregroundColor(.orange) }
            }

            if !viewModel.generalError.isEmpty {
                Section { Text(viewModel.generalError).foregroundColor(.pokerRed).listRowBackground(Color.pokerCardWhite) }
            }

            Section {
                Button {
                    showSettlement = true
                } label: {
                    HStack { Spacer(); Text("🏁  End Session / Settle").font(.headline).foregroundColor(.black); Spacer() }
                        .padding(.vertical, 8).background(Color.orange).cornerRadius(10)
                }
                .listRowBackground(Color.pokerCardWhite)
                .accessibilityIdentifier("session_end_button")
            }

            Section { BannerAdView().listRowBackground(Color.clear).listRowInsets(EdgeInsets()) }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.pokerDarkGreen)
        .navigationTitle("Active Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.pokerDarkGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .scrollDismissesKeyboard(.interactively)
        .onAppear { viewModel.refreshSession() }
        .navigationDestination(isPresented: $showSettlement) {
            if let session = viewModel.activeSession {
                SettlementView(session: session, sessionService: viewModel.sessionService,
                               playerService: viewModel.playerService, transactionService: viewModel.transactionService,
                               upiService: upiService, onSessionEnded: onSessionEnded)
            }
        }
        .sheet(item: $activeAction) { action in
            Group {
                switch action {
                case .collect(let player, let isReBuy):
                    CollectFlowView(player: player, isReBuy: isReBuy, viewModel: viewModel, upiService: upiService) {
                        activeAction = nil
                        viewModel.refreshSession()
                    }
                case .checkout(let player):
                    CheckoutFlowView(player: player, viewModel: viewModel, upiService: upiService) {
                        activeAction = nil
                        viewModel.refreshSession()
                    }
                }
            }
            .tint(.primary)
        }
        .onChange(of: activeAction == nil) { _, isNil in
            if isNil { viewModel.refreshSession() }
        }
        .sheet(isPresented: $showAddPlayer) {
            AddPlayerSheet(viewModel: viewModel, isPresented: $showAddPlayer)
                .tint(.primary)
        }
        .onChange(of: showAddPlayer) { _, showing in
            if !showing { viewModel.refreshSession() }
        }
    }
}

// MARK: - Stat Box
private struct StatBox: View {
    let label: String; let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.headline).foregroundColor(.pokerGreen)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity)
    }
}

// MARK: - Add Player Sheet (half card with name dedup)
private struct AddPlayerSheet: View {
    @ObservedObject var viewModel: SessionViewModel
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var upiHandle = ""
    @State private var error = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Add Player").font(.title3.bold()).foregroundColor(.primary)

                TextField("Player Name", text: $name)
                    .padding(12).background(Color(.systemGray6)).cornerRadius(10)
                    .accessibilityIdentifier("add_player_name_field")
                TextField("UPI Handle (optional)", text: $upiHandle)
                    .autocapitalization(.none).keyboardType(.emailAddress)
                    .padding(12).background(Color(.systemGray6)).cornerRadius(10)
                    .accessibilityIdentifier("add_player_upi_field")

                if !error.isEmpty {
                    Text(error).font(.caption).foregroundColor(.pokerRed)
                }

                Button {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { error = "Name is required"; return }

                    // Dedup check
                    let existing = viewModel.activePlayers.map { ($0.name ?? "").lowercased() }
                    let checkedOut = viewModel.checkedOutPlayers.map { ($0.name ?? "").lowercased() }
                    if existing.contains(trimmed.lowercased()) || checkedOut.contains(trimmed.lowercased()) {
                        error = "A player named \"\(trimmed)\" already exists in this session"
                        return
                    }

                    let upi = upiHandle.trimmingCharacters(in: .whitespacesAndNewlines)
                    viewModel.addPlayer(name: trimmed, upiHandle: upi.isEmpty ? nil : upi)
                    let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.success)
                    isPresented = false
                } label: {
                    HStack { Spacer(); Text("➕ Add Player").font(.headline).foregroundColor(.black); Spacer() }
                        .padding(.vertical, 12).background(Color.pokerGold).cornerRadius(12)
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("add_player_submit_button")

                Spacer()
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Player Row
private struct PlayerRow: View {
    let player: Player
    @ObservedObject var viewModel: SessionViewModel
    var onCollect: (Bool) -> Void
    var onCheckout: () -> Void

    var body: some View {
        let s = viewModel.stats(for: player)

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "person.fill").foregroundColor(.pokerGold)
                Text(player.name ?? "Unknown").font(.subheadline.bold())
                Spacer()
                if s.buyInCount > 0 {
                    Text("\(s.buyInCount) buy-in\(s.buyInCount > 1 ? "s" : "")")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }

            if let upi = player.upiHandle, !upi.isEmpty {
                Text(upi).font(.caption).foregroundColor(.secondary)
            }

            if s.collected > 0 || s.outstanding > 0 {
                HStack(spacing: 6) {
                    if s.collectedByCash > 0 { Text("💵₹\(s.collectedByCash)").font(.caption2).foregroundColor(.green) }
                    if s.collectedByUPI > 0 { Text("📱₹\(s.collectedByUPI)").font(.caption2).foregroundColor(.blue) }
                    if s.outstanding > 0 { Text("⏳₹\(s.outstanding)").font(.caption2).foregroundColor(.pokerRed) }
                }
            }

            HStack(spacing: 10) {
                if !s.hasBuyIn {
                    Button {
                        onCollect(false)
                    } label: {
                        Text("💰 Buy-In").font(.caption)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.pokerGreen.opacity(0.15)).foregroundColor(.pokerGreen).cornerRadius(8)
                    }
                    .buttonStyle(.borderless)
                } else {
                    Button {
                        onCollect(true)
                    } label: {
                        Text("🔄 Re-Buy").font(.caption)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.pokerGold.opacity(0.15)).foregroundColor(.pokerGold).cornerRadius(8)
                    }
                    .buttonStyle(.borderless)

                    Button {
                        onCheckout()
                    } label: {
                        Text("🚪 Checkout").font(.caption)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.orange.opacity(0.15)).foregroundColor(.orange).cornerRadius(8)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Collect Flow (Cash/UPI choice + confirmation)
private struct CollectFlowView: View {
    let player: Player
    let isReBuy: Bool
    @ObservedObject var viewModel: SessionViewModel
    let upiService: UPIServiceProtocol
    var onDismiss: () -> Void

    @State private var showCashAlert = false
    @State private var showUPICollect = false

    private var amountText: String {
        if let session = viewModel.activeSession {
            let amount = (session.buyInAmount as? Decimal) ?? 0
            return "\(amount)"
        }
        return "0"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(isReBuy ? "Re-Buy-In" : "Buy-In")
                    .font(.title2.bold()).foregroundColor(.primary)

                Text(player.name ?? "Unknown").font(.headline)

                if let session = viewModel.activeSession {
                    let amount = (session.buyInAmount as? Decimal) ?? 0
                    Text("Amount: ₹\(amount)").font(.title3)
                }

                Text("Choose payment method:").font(.subheadline).foregroundColor(.secondary)

                HStack(spacing: 20) {
                    Button("💵 Cash") { showCashAlert = true }
                        .font(.headline).padding().frame(maxWidth: .infinity)
                        .background(Color.pokerGreen.opacity(0.2)).cornerRadius(12)

                    Button("📱 UPI") { showUPICollect = true }
                        .font(.headline).padding().frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.2)).cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 30)
            .background(Color.pokerCardWhite.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
            .alert("Cash Collection", isPresented: $showCashAlert) {
                Button("✅ Collected") {
                    recordAndDismiss(method: .cash, collected: true)
                }
                Button("⏳ Not Yet") {
                    recordAndDismiss(method: .cash, collected: false)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Has ₹\(amountText) cash been collected from \(player.name ?? "player")?")
            }
            .environment(\.colorScheme, .light)
            .fullScreenCover(isPresented: $showUPICollect) {
                if let session = viewModel.activeSession {
                    let amount = (session.buyInAmount as? Decimal) ?? 0
                    let hostService = HostService(context: CoreDataStack.shared.viewContext)
                    let host = hostService.getHost()
                    UPICollectView(
                        playerName: player.name ?? "Unknown",
                        amount: amount,
                        hostUPI: host?.upiHandle ?? "",
                        hostName: host?.name ?? "Host",
                        isReBuy: isReBuy,
                        onCollected: { collected in
                            showUPICollect = false
                            if let collected = collected {
                                recordAndDismiss(method: .upi, collected: collected)
                            }
                            // nil = cancelled, don't record anything
                        }
                    )
                }
            }
        }
    }

    private func recordAndDismiss(method: PaymentMethod, collected: Bool) {
        if isReBuy {
            viewModel.collectReBuyIn(player: player, method: method, collected: collected)
        } else {
            viewModel.collectBuyIn(player: player, method: method, collected: collected)
        }
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(collected ? .success : .warning)
        onDismiss()
    }
}


// MARK: - Checkout Flow (Requirement 6)
private struct CheckoutFlowView: View {
    let player: Player
    @ObservedObject var viewModel: SessionViewModel
    let upiService: UPIServiceProtocol
    var onDismiss: () -> Void

    enum CheckoutStep { case enterChips, showSettlement, upiPayment, confirm, done }

    @State private var step: CheckoutStep = .enterChips
    @State private var chipCountText = ""
    @State private var chipCount: Decimal = 0
    @State private var settlementAmount: Decimal = 0
    @State private var selectedMethod: PaymentMethod?
    @State private var showCashConfirm = false
    // UPI API state
    @State private var upiLoading = false
    @State private var upiIntentUrl = ""
    @State private var upiError = ""

    private let apiService = UPIAPIService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("🚪 Player Checkout").font(.title2.bold()).foregroundColor(.primary)
                Text(player.name ?? "Unknown").font(.headline)

                let s = viewModel.stats(for: player)
                VStack(spacing: 4) {
                    Text("Buy-ins: \(s.buyInCount)  •  Collected: ₹\(s.collected)")
                    if s.outstanding > 0 {
                        Text("Outstanding: ₹\(s.outstanding)").foregroundColor(.pokerRed)
                    }
                }
                .font(.caption).foregroundColor(.secondary)

                Divider().padding(.horizontal)

                switch step {
                case .enterChips:
                    VStack(spacing: 12) {
                        Text("Enter chip count (₹)").font(.subheadline)
                        Text("How many chips does the player have?")
                            .font(.caption).foregroundColor(.secondary)
                        TextField("Chip count", text: $chipCountText)
                            .keyboardType(.decimalPad)
                            .padding().background(Color(.systemGray6)).cornerRadius(10)
                            .padding(.horizontal)

                        Button("Calculate Settlement") {
                            guard let chips = Decimal(string: chipCountText) else { return }
                            chipCount = chips
                            settlementAmount = chips - viewModel.stats(for: player).outstanding
                            step = .showSettlement
                        }
                        .font(.headline).padding().frame(maxWidth: .infinity)
                        .background(chipCountText.isEmpty ? Color.gray.opacity(0.3) : Color.pokerGold)
                        .foregroundColor(.black).cornerRadius(12).padding(.horizontal)
                        .disabled(chipCountText.isEmpty || Decimal(string: chipCountText) == nil)
                    }

                case .showSettlement:
                    VStack(spacing: 12) {
                        VStack(spacing: 4) {
                            HStack {
                                Text("Chips:").foregroundColor(.secondary)
                                Spacer()
                                Text("₹\(chipCount)")
                            }
                            let outstandingBal = viewModel.stats(for: player).outstanding
                            if outstandingBal > 0 {
                                HStack {
                                    Text("Outstanding:").foregroundColor(.secondary)
                                    Spacer()
                                    Text("-₹\(outstandingBal)").foregroundColor(.pokerRed)
                                }
                            }
                            Divider()
                            HStack {
                                Text("Net Settlement:").font(.headline)
                                Spacer()
                                Text("₹\(settlementAmount)")
                                    .font(.headline)
                                    .foregroundColor(settlementAmount > 0 ? .green : settlementAmount < 0 ? .pokerRed : .secondary)
                            }
                        }
                        .font(.subheadline)
                        .padding().background(Color(.systemGray6)).cornerRadius(10)
                        .padding(.horizontal)

                        if settlementAmount > 0 {
                            Text("Host pays player ₹\(settlementAmount)").font(.caption).foregroundColor(.green)
                        } else if settlementAmount < 0 {
                            Text("Player owes host ₹\(absDecimal(settlementAmount))").font(.caption).foregroundColor(.pokerRed)
                        } else {
                            Text("Even — no payment needed").font(.caption).foregroundColor(.secondary)
                        }

                        if settlementAmount == 0 {
                            Button("✅ Checkout (Even)") {
                                viewModel.checkoutPlayer(player: player, settlementAmount: 0, method: .cash, completed: true)
                                let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.success)
                                step = .done
                            }
                            .font(.headline).padding().frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.8)).foregroundColor(.black).cornerRadius(12).padding(.horizontal)
                        } else {
                            let hasUPI = player.upiHandle != nil && !(player.upiHandle?.isEmpty ?? true)
                            Text("Choose payment method:").font(.caption).foregroundColor(.secondary)
                            HStack(spacing: 16) {
                                Button("💵 Cash") {
                                    selectedMethod = .cash
                                    showCashConfirm = true
                                }
                                .font(.headline).padding().frame(maxWidth: .infinity)
                                .background(Color.pokerGreen.opacity(0.2)).cornerRadius(12)

                                Button("📱 UPI") {
                                    selectedMethod = .upi
                                    generateUPILink()
                                }
                                .font(.headline).padding().frame(maxWidth: .infinity)
                                .background(hasUPI ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .foregroundColor(hasUPI ? .blue : .gray)
                                .cornerRadius(12)
                                .disabled(!hasUPI)
                            }
                            .padding(.horizontal)
                            if !hasUPI {
                                Text("UPI unavailable — no UPI handle").font(.caption2).foregroundColor(.secondary)
                            }
                        }
                    }

                case .upiPayment:
                    VStack(spacing: 16) {
                        if upiLoading {
                            ProgressView().tint(.pokerGold)
                            Text("Generating payment link...").font(.caption).foregroundColor(.secondary)
                        } else if !upiError.isEmpty {
                            Text(upiError).font(.caption).foregroundColor(.pokerRed)
                            Button("Retry") { generateUPILink() }
                                .font(.subheadline).foregroundColor(.primary)
                        } else {
                            Text("Settlement: ₹\(settlementAmount)").font(.title3.bold())
                            Text("Pay to: \(player.upiHandle ?? "")").font(.caption).foregroundColor(.secondary)

                            Button {
                                if let url = URL(string: upiIntentUrl) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                    Text("Proceed to Pay")
                                }
                                .font(.headline).foregroundColor(.black)
                                .padding(.horizontal, 24).padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(Color.pokerGold).cornerRadius(12)
                            }
                            .padding(.horizontal)

                            Button("Done") {
                                step = .confirm
                            }
                            .font(.subheadline.bold()).foregroundColor(.primary)
                            .padding(.horizontal, 32).padding(.vertical, 10)
                            .background(Color(.systemGray5)).cornerRadius(10)
                        }
                    }

                case .confirm:
                    VStack(spacing: 16) {
                        Text("Settlement: ₹\(settlementAmount)").font(.title3.bold())
                        Text("Method: \(selectedMethod == .cash ? "Cash" : "UPI")").font(.subheadline)

                        HStack(spacing: 16) {
                            Button("✅ Done") {
                                viewModel.checkoutPlayer(player: player, settlementAmount: settlementAmount, method: selectedMethod ?? .cash, completed: true)
                                let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.success)
                                step = .done
                            }
                            .font(.subheadline.bold()).padding().frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.2)).cornerRadius(12)

                            Button("⏳ Pending") {
                                viewModel.checkoutPlayer(player: player, settlementAmount: settlementAmount, method: selectedMethod ?? .cash, completed: false)
                                let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.warning)
                                step = .done
                            }
                            .font(.subheadline.bold()).padding().frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.2)).cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                case .done:
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 50)).foregroundColor(.green)
                        Text("Player checked out!").font(.headline)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { onDismiss() }
                    }
                }

                Spacer()
            }
            .padding(.top, 24)
            .background(Color.pokerCardWhite.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
            .alert("Cash Settlement", isPresented: $showCashConfirm) {
                Button("✅ Settled") {
                    viewModel.checkoutPlayer(player: player, settlementAmount: settlementAmount, method: .cash, completed: true)
                    let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.success)
                    step = .done
                }
                Button("⏳ Not Yet") {
                    viewModel.checkoutPlayer(player: player, settlementAmount: settlementAmount, method: .cash, completed: false)
                    let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.warning)
                    step = .done
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Has ₹\(settlementAmount) been settled via cash?")
            }
            .environment(\.colorScheme, .light)
        }
    }

    private func generateUPILink() {
        guard let upi = player.upiHandle, !upi.isEmpty else { return }
        upiLoading = true
        upiError = ""
        step = .upiPayment

        let amt = settlementAmount > 0 ? settlementAmount : absDecimal(settlementAmount)
        let note = "Poker payout - \(player.name ?? "")"
        let txnRef = "payout-\(UUID().uuidString.prefix(8))"

        Task {
            do {
                let response = try await apiService.generateUPILinks(
                    pa: upi, pn: player.name ?? "", am: amt, tn: note, tr: txnRef)
                await MainActor.run {
                    upiIntentUrl = response.upiIntentUrl
                    upiLoading = false
                }
            } catch {
                await MainActor.run {
                    upiError = "Failed to generate link. Check internet."
                    upiLoading = false
                }
            }
        }
    }
}

private func absDecimal(_ value: Decimal) -> Decimal {
    value < 0 ? -value : value
}
