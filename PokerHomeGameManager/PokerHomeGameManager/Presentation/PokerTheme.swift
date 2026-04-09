import SwiftUI

// MARK: - Poker Color Palette

extension Color {
    static let pokerGreen = Color(red: 0.05, green: 0.35, blue: 0.15)
    static let pokerDarkGreen = Color(red: 0.02, green: 0.22, blue: 0.10)
    static let pokerFelt = Color(red: 0.08, green: 0.42, blue: 0.20)
    static let pokerGold = Color(red: 0.85, green: 0.65, blue: 0.13)
    static let pokerRed = Color(red: 0.80, green: 0.15, blue: 0.15)
    static let pokerChip = Color(red: 0.95, green: 0.90, blue: 0.75)
    static let pokerCardWhite = Color(red: 0.97, green: 0.96, blue: 0.93)
}

// MARK: - Card Style Modifier

struct PokerCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.pokerCardWhite)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

extension View {
    func pokerCard() -> some View {
        modifier(PokerCardStyle())
    }
}

// MARK: - Poker Button Style

struct PokerButtonStyle: ButtonStyle {
    var color: Color = .pokerGold

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
