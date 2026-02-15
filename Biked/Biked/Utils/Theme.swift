import SwiftUI

struct AppTheme {
    struct Colors {
        // Core Backgrounds
        static let backgroundData = Color("BackgroundData") // We'll make this adaptive in Assets later, but for now we can likely use system
        static let background = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        
        // Premium Accents
        static let primary = Color.blue
        static let accent = Color.cyan
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        
        // Specific UI Elements
        static let cardBackground = Color(UIColor.systemGray6)
    }
    
    struct Gradients {
        static let primary = LinearGradient(
            gradient: Gradient(colors: [Color.blue, Color.purple]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let darkOverlay = LinearGradient(
            gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let oceanBeep = LinearGradient(
            gradient: Gradient(colors: [Color(hex: "0f2027"), Color(hex: "203a43"), Color(hex: "2c5364")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let electric = LinearGradient(
            gradient: Gradient(colors: [Color(hex: "434343"), Color(hex: "000000")]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    struct Fonts {
        static let titleLarge = Font.system(size: 34, weight: .bold, design: .rounded)
        static let headline = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let subheadline = Font.system(size: 16, weight: .medium, design: .default)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
