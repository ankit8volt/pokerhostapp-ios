import SwiftUI

// MARK: - Celebration Overlay (confetti + checkmark animation)

struct CelebrationOverlay: View {
    let message: String
    let icon: String
    var onComplete: () -> Void

    @State private var showCheck = false
    @State private var showText = false
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 1.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture { onComplete() }

            // Confetti particles
            ForEach(confettiPieces) { piece in
                Text(piece.emoji)
                    .font(.system(size: piece.size))
                    .position(piece.position)
                    .opacity(piece.opacity)
            }

            VStack(spacing: 20) {
                // Animated ring
                ZStack {
                    Circle()
                        .stroke(Color.pokerGold.opacity(0.3), lineWidth: 4)
                        .frame(width: 100, height: 100)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Checkmark / icon
                    Text(icon)
                        .font(.system(size: 50))
                        .scaleEffect(showCheck ? 1.0 : 0.1)
                        .opacity(showCheck ? 1.0 : 0)
                }

                Text(message)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 10)
            }
        }
        .onAppear { startAnimation() }
    }

    private func startAnimation() {
        // Haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Spawn confetti
        let emojis = ["♠️", "♥️", "♣️", "♦️", "🎰", "💰", "🃏", "⭐️"]
        let screenW = UIScreen.main.bounds.width
        let screenH = UIScreen.main.bounds.height

        for i in 0..<30 {
            let piece = ConfettiPiece(
                emoji: emojis[i % emojis.count],
                size: CGFloat.random(in: 16...28),
                position: CGPoint(x: CGFloat.random(in: 20...screenW - 20), y: -30),
                opacity: 1.0
            )
            confettiPieces.append(piece)
        }

        // Animate confetti falling
        for i in confettiPieces.indices {
            let delay = Double.random(in: 0...0.5)
            let targetY = CGFloat.random(in: screenH * 0.3...screenH * 0.85)
            let targetX = confettiPieces[i].position.x + CGFloat.random(in: -40...40)

            withAnimation(.easeOut(duration: 1.2).delay(delay)) {
                confettiPieces[i].position = CGPoint(x: targetX, y: targetY)
            }
            withAnimation(.easeIn(duration: 0.5).delay(delay + 1.5)) {
                confettiPieces[i].opacity = 0
            }
        }

        // Ring pulse
        withAnimation(.easeOut(duration: 0.6)) {
            ringScale = 1.5
        }
        withAnimation(.easeIn(duration: 0.4).delay(0.6)) {
            ringOpacity = 0
        }

        // Checkmark bounce
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.2)) {
            showCheck = true
        }

        // Text fade in
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            showText = true
        }

        // Auto dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onComplete()
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let emoji: String
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}
