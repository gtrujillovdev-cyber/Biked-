import SwiftUI

struct BikeImageView: View {
    let url: URL?
    var brand: String? = nil
    var contentMode: ContentMode = .fill
    
    var body: some View {
        ZStack {
            if let url = url {
                if url.isFileURL {
                    // Local file: instant synchronous load
                    if let uiImage = UIImage(contentsOfFile: url.path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
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
    }
    
    private var placeholderView: some View {
        ZStack {
            // Elegant dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.14, blue: 0.18),
                    Color(red: 0.06, green: 0.08, blue: 0.11)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Image(systemName: "bicycle")
                    .font(.system(size: 38, weight: .light))
                    .foregroundColor(AppTheme.Colors.accent.opacity(0.6))
                
                if let brand = brand, !brand.isEmpty {
                    Text(brand.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .kerning(1.5)
                }
            }
            .padding()
        }
    }
}
