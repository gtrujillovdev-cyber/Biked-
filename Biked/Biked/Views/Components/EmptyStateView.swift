import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.accent.opacity(0.8))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(AppTheme.Fonts.headline)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(AppTheme.Fonts.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTheme.Fonts.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(AppTheme.Gradients.primary)
                        .cornerRadius(25)
                        .shadow(color: AppTheme.Colors.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 10)
            }
        }
        .padding(.vertical, 50)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.02))
        .cornerRadius(30)
        .padding()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        EmptyStateView(
            title: "No se encontraron resultados",
            message: "Prueba con otros valores de Stack y Reach o amplia la tolerancia.",
            systemImage: "bicycle.circle"
        )
    }
}
