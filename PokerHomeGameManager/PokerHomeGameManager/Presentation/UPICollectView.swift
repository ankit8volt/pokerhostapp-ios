import SwiftUI

struct UPICollectView: View {
    let playerName: String
    let amount: Decimal
    let hostUPI: String
    let hostName: String
    let isReBuy: Bool
    var onCollected: (Bool) -> Void

    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var qrImage: UIImage?
    @State private var shareUrl = ""
    @State private var showShareSheet = false
    @State private var showConfirmAlert = false

    private let apiService = UPIAPIService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pokerDarkGreen.ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView().tint(.pokerGold).scaleEffect(1.5)
                        Text("Generating payment link...")
                            .foregroundColor(.pokerChip)
                    }
                } else if !errorMessage.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40)).foregroundColor(.orange)
                        Text(errorMessage)
                            .foregroundColor(.pokerChip).multilineTextAlignment(.center)
                        Button("Retry") { loadUPIData() }
                            .foregroundColor(.pokerGold)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            Text(isReBuy ? "Re-Buy-In Payment" : "Buy-In Payment")
                                .font(.title2.bold()).foregroundColor(.pokerGold)
                            Text("₹\(amount)")
                                .font(.system(size: 36, weight: .bold)).foregroundColor(.white)
                            Text("for \(playerName)")
                                .font(.subheadline).foregroundColor(.pokerChip.opacity(0.7))

                            // QR Code
                            if let qrImage = qrImage {
                                VStack(spacing: 8) {
                                    Text("Scan to Pay")
                                        .font(.caption).foregroundColor(.pokerChip.opacity(0.6))
                                    Image(uiImage: qrImage)
                                        .resizable().interpolation(.none).scaledToFit()
                                        .frame(width: 220, height: 220)
                                        .background(Color.white).cornerRadius(12)
                                        .shadow(color: .black.opacity(0.3), radius: 8)
                                }
                            }

                            // Share URL
                            if !shareUrl.isEmpty {
                                VStack(spacing: 8) {
                                    Text("Payment Link")
                                        .font(.caption).foregroundColor(.pokerChip.opacity(0.6))
                                    Text(shareUrl)
                                        .font(.caption2).foregroundColor(.pokerChip)
                                        .multilineTextAlignment(.center)
                                        .padding(12)
                                        .background(Color.pokerGreen.opacity(0.3)).cornerRadius(8)
                                        .padding(.horizontal)

                                    // Share button
                                    Button {
                                        showShareSheet = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Share Payment Link")
                                        }
                                        .font(.headline).foregroundColor(.black)
                                        .padding(.horizontal, 24).padding(.vertical, 14)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.pokerGold).cornerRadius(12)
                                    }
                                    .padding(.horizontal)

                                    // Done button — smaller, triggers confirmation
                                    Button {
                                        showConfirmAlert = true
                                    } label: {
                                        Text("Done")
                                            .font(.subheadline.bold()).foregroundColor(.pokerGold)
                                            .padding(.horizontal, 32).padding(.vertical, 10)
                                            .background(Color.pokerGreen.opacity(0.3)).cornerRadius(10)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.vertical, 24)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onCollected(false) }
                        .foregroundColor(.pokerGold)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if !shareUrl.isEmpty {
                    ShareSheetView(items: [shareUrl])
                }
            }
            .alert("Payment Collection", isPresented: $showConfirmAlert) {
                Button("✅ Collected") {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    onCollected(true)
                }
                Button("⏳ Not Yet") {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                    onCollected(false)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Has ₹\(amount) been collected from \(playerName)?")
            }
            .environment(\.colorScheme, .light)
            .tint(.primary)
        }
        .onAppear { loadUPIData() }
    }

    private func loadUPIData() {
        isLoading = true
        errorMessage = ""
        let txnRef = "txn-\(UUID().uuidString.prefix(8))"
        let note = "Poker \(isReBuy ? "Re-Buy" : "Buy-In") - \(playerName)"

        Task {
            do {
                let response = try await apiService.generateUPILinks(
                    pa: hostUPI, pn: hostName, am: amount, tn: note, tr: txnRef)
                await MainActor.run {
                    shareUrl = response.shareUrl
                    qrImage = decodeBase64Image(response.qrCodeDataUrl)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed: \(error.localizedDescription)"
                    print("[UPI API] Error: \(error)")
                    isLoading = false
                }
            }
        }
    }

    private func decodeBase64Image(_ dataUrl: String) -> UIImage? {
        let base64String: String
        if dataUrl.contains(",") {
            base64String = String(dataUrl.split(separator: ",").last ?? "")
        } else {
            base64String = dataUrl
        }
        guard let data = Data(base64Encoded: base64String) else { return nil }
        return UIImage(data: data)
    }
}

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
