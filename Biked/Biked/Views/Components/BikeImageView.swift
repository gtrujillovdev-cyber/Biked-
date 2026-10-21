import SwiftUI

struct BikeImageView: View {
    let url: URL?
    var brand: String? = nil
    var contentMode: ContentMode = .fit
    var showStudioEffects: Bool = true
    
    var body: some View {
        ZStack {
            if showStudioEffects {
                // Studio Spotlight Background Glow
                RadialGradient(
                    colors: [
                        AppTheme.Colors.accent.opacity(0.14),
                        Color.white.opacity(0.02),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 160
                )
            }
            
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                
                bikeContent
                
                if showStudioEffects && url != nil {
                    // Elliptical Ground Shadow under tires
                    Ellipse()
                        .fill(Color.black.opacity(0.45))
                        .frame(maxWidth: 240, maxHeight: 12)
                        .blur(radius: 6)
                        .padding(.top, -6)
                }
                
                Spacer(minLength: 0)
            }
        }
    }
    
    @ViewBuilder
    private var bikeContent: some View {
        if let url = url {
            if url.isFileURL {
                // Local file: instant synchronous load
                if let uiImage = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .transition(.opacity)
                } else {
                    placeholderView
                }
            } else {
                // Remote URL: AsyncImage with proper phase handling
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                            .transition(.opacity)
                    case .failure:
                        placeholderView
                    case .empty:
                        ZStack {
                            Color.white.opacity(0.04)
                            ProgressView()
                                .tint(AppTheme.Colors.accent)
                        }
                    @unknown default:
                        placeholderView
                    }
                }
            }
        } else {
            placeholderView
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            // Elegant Studio Blueprint Background
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.14, blue: 0.18),
                    Color(red: 0.05, green: 0.07, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle Grid Overlay
            VStack(spacing: 14) {
                Divider().background(Color.white.opacity(0.04))
                Divider().background(Color.white.opacity(0.04))
                Divider().background(Color.white.opacity(0.04))
            }
            
            VStack(spacing: 8) {
                Image(systemName: "bicycle")
                    .font(.system(size: 38, weight: .light))
                    .foregroundColor(AppTheme.Colors.accent.opacity(0.75))
                    .shadow(color: AppTheme.Colors.accent.opacity(0.4), radius: 8, x: 0, y: 0)
                
                if let brand = brand, !brand.isEmpty {
                    Text(brand.uppercased())
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white.opacity(0.6))
                        .kerning(2.0)
                }
                
                Text("ESTUDIO GEOMÉTRICO")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(AppTheme.Colors.accent.opacity(0.5))
                    .kerning(1.2)
            }
            .padding()
        }
    }
}
