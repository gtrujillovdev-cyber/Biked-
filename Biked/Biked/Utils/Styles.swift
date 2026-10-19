import SwiftUI

// Global Button Style for Premium Feedback
struct PremiumScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Extension to easily apply the style
extension ButtonStyle where Self == PremiumScaleButtonStyle {
    static var premiumScale: PremiumScaleButtonStyle {
        PremiumScaleButtonStyle()
    }
}
