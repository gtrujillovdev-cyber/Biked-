import SwiftUI

struct SplashView: View {
    @State private var logoOpacity: Double = 0.0
    @State private var bgScale: CGFloat = 1.1
    @State private var textOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Base background color to avoid "gray" screen
            Color(red: 0.05, green: 0.05, blue: 0.05)
                .ignoresSafeArea()
            
            // Minimalist Background Image (Lifestyle)
            Image("splash_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .scaleEffect(bgScale)
                .ignoresSafeArea()
                .opacity(0.8) // Blend with base color
                .overlay { 
                    if UIImage(named: "splash_bg") == nil {
                        AppTheme.Gradients.oceanBeep.ignoresSafeArea()
                    }
                }
            
            // Subtle Dark Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.4), .clear, .black.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Minimalist Bold Logo
                // Minimalist Bold Logo
                if UIImage(named: "biked_logo") != nil {
                    Image("biked_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220)
                        .opacity(logoOpacity)
                } else {
                    // Fallback to Icon
                    Image(systemName: "bicycle.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .foregroundColor(AppTheme.Colors.accent)
                        .opacity(logoOpacity)
                }
                
                // Text fallback in case image is missing from bundle
                if logoOpacity > 0 {
                    Text("BIKED")
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(.white)
                        .kerning(4)
                        .opacity(logoOpacity * 0.2) // Subtle secondary layer
                        .offset(y: -20)
                }
                
                Spacer()
                
                // Signature and Indicator
                VStack(spacing: 16) {
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 50, height: 1)
                    
                    Text("Developed by Gtv")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.white)
                        .kerning(2)
                        .opacity(textOpacity)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Trigger animations after a tiny delay to ensure view is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeIn(duration: 1.2)) {
                    logoOpacity = 1.0
                }
                withAnimation(.easeIn(duration: 1.5).delay(0.5)) {
                    textOpacity = 0.8
                }
                withAnimation(.linear(duration: 5.0)) {
                    bgScale = 1.0
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
