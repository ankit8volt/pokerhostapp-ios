import SwiftUI

// MARK: - Celebration Overlay (confetti + checkmark animation)
struct CelebrationView: View {
    let message: String
    let subtitle: String
    var onComplete: () -> Void

    @State private var showCheck = false
    @State private var checkScale: CGFloat = 0.1
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 1.0
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.pokerDarkGreen.opacity(0.95).ignoresSafeArea()

            // Confetti
            ForEach(confettiParticles) { p in
                Text(p.emoji)
                    .font(.system(size: p.size))
                    .position(p.position)
                    .opacity(p.opacity)
                    .rotationEffect(.degrees(p.rotation))
            }

            VStack(spacing: 24) {
                Spacer()

                // Animated ring + checkmark
                ZStack {
                    Circle()
                        .stroke(Color.pokerGold, lineWidth: 4)
                        .frame(width: 120, height: 120)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.pokerGold)
                        .scaleEffect(checkScale)
                }

                Text(message)
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .opacity(textOpacity)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.pokerChip.opacity(0.7))
                    .opacity(textOpacity)

                Spacer()
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
        for i in 0..<30 {
            let p = ConfettiParticle(
                id: i,
                emoji: emojis.randomElement()!,
                size: CGFloat.random(in: 16...32),
                position: CGPoint(x: CGFloat.random(in: 20...350), y: -20),
                targetY: CGFloat.random(in: 200...800),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            confettiParticles.append(p)
        }

        // Animate confetti falling
        for i in confettiParticles.indices {
            let delay = Double.random(in: 0...0.5)
            withAnimation(.easeIn(duration: Double.random(in: 0.8...1.5)).delay(delay)) {
                confettiParticles[i].position.y = confettiParticles[i].targetY
                confettiParticles[i].rotation += Double.random(in: 180...720)
            }
            withAnimation(.easeOut(duration: 0.5).delay(delay + 1.2)) {
                confettiParticles[i].opacity = 0
            }
        }

        // Checkmark pop
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.1)) {
            checkScale = 1.0
        }

        // Ring expand + fade
        withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
            ringScale = 2.0
            ringOpacity = 0
        }

        // Text fade in
        withAnimation(.easeIn(duration: 0.4).delay(0.4)) {
            textOpacity = 1.0
        }

        // Second haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }

        // Auto dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onComplete()
        }
    }
}

// MARK: - Confetti Particle
struct ConfettiParticle: Identifiable {
    let id: Int
    let emoji: String
    let size: CGFloat
    var position: CGPoint
    let targetY: CGFloat
    var rotation: Double
    var opacity: Double
}

// MARK: - Success Toast (smaller, for profile updates)
struct SuccessToast: View {
    let message: String
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
            Text(message)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color.pokerGreen.opacity(0.9))
        .cornerRadius(25)
        .shadow(color: .black.opacity(0.3), radius: 10)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            let g = UINotificationFeedbackGenerator()
            g.notificationOccurred(.success)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
