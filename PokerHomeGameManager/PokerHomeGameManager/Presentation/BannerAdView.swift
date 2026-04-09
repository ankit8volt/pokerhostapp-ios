import SwiftUI

struct BannerAdView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.pokerGreen.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.pokerGold.opacity(0.3), lineWidth: 1)
                )
            Text("♠️ Ad Space ♦️")
                .font(.caption)
                .foregroundColor(.pokerChip.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
    }
}
