import SwiftUI

/// Ultra-premium 9:16 Instagram / WhatsApp Story card designed for high-resolution rendering
struct FitStoryCardView: View {
    let result: MatchingResult
    let posture: String?
    
    init(result: MatchingResult, posture: String?) {
        self.result = result
        self.posture = posture
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header Branding
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("BIKED")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .kerning(4)
                        .foregroundColor(AppTheme.Colors.accent)
                    Text("INFORME DE AJUSTE BIOMÉCANICO")
                        .font(.system(size: 9, weight: .heavy))
                        .kerning(1.5)
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                
                // Match percentage badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                    Text("\(Int(result.confidenceScore))% MATCH")
                        .font(.system(size: 11, weight: .black))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(result.fitStatus.color.opacity(0.2))
                .foregroundColor(result.fitStatus.color)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(result.fitStatus.color.opacity(0.5), lineWidth: 1)
                )
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            
            // Bike Title & Size
            VStack(spacing: 3) {
                Text(result.bike.brand.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .kerning(2)
                    .foregroundColor(AppTheme.Colors.accent)
                Text(result.bike.model)
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text("Talla Óptima: \(result.matchedSize)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 16)
            
            // Bike Studio Photo
            ZStack {
                // Ambient Radial Glow
                RadialGradient(
                    colors: [
                        AppTheme.Colors.accent.opacity(0.25),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 160
                )
                .frame(height: 170)
                
                // Elliptical floor shadow
                Ellipse()
                    .fill(Color.black.opacity(0.45))
                    .frame(width: 240, height: 18)
                    .blur(radius: 8)
                    .offset(y: 65)
                
                // Studio Bike Image
                if let url = result.bike.mainImage {
                    if let image = UIImage(contentsOfFile: url.path) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 10)
                    } else {
                        AsyncImage(url: url) { phase in
                            if let img = phase.image {
                                img.resizable()
                                    .aspectRatio(16/9, contentMode: .fit)
                            } else {
                                Image(systemName: "bicycle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                        .frame(height: 160)
                        .padding(.horizontal, 10)
                    }
                }
            }
            .frame(height: 170)
            
            // Biomechanical Target vs Actual Comparison Grid
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    StoryMetricPill(
                        title: "Stack Cuadro",
                        actual: "\(Int(result.matchedGeometry.stack)) mm",
                        target: "\(Int(result.userStack)) mm",
                        diff: result.stackDifference
                    )
                    StoryMetricPill(
                        title: "Reach Cuadro",
                        actual: "\(Int(result.matchedGeometry.reach)) mm",
                        target: "\(Int(result.userReach)) mm",
                        diff: result.reachDifference
                    )
                }
                
                HStack(spacing: 8) {
                    StoryStatBox(
                        icon: "gauge.medium",
                        label: "Ratio STR",
                        value: String(format: "%.2f", result.strRatio),
                        subtitle: result.strRatio < 1.4 ? "Aero" : (result.strRatio < 1.5 ? "Equilibrado" : "Confort")
                    )
                    StoryStatBox(
                        icon: "square.stack.3d.up",
                        label: "Espaciadores",
                        value: "~\(result.recommendedSpacersMm) mm",
                        subtitle: "Bajo potencia"
                    )
                    StoryStatBox(
                        icon: "arrow.left.and.right",
                        label: "Potencia",
                        value: "\(result.recommendedStemLengthMm) mm",
                        subtitle: "Longitud"
                    )
                }
            }
            .padding(.horizontal, 22)
            
            // Prescription Verdict
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: result.fitStatus.iconName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(result.fitStatus.color)
                    .padding(8)
                    .background(result.fitStatus.color.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.fitStatus.rawValue)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text(result.fitSummary)
                        .font(.system(size: 10.5))
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(3)
                        .lineSpacing(2)
                }
                Spacer()
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, 22)
            
            Spacer()
            
            // Footer & Watermark
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "figure.outdoor.cycle")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.accent)
                    Text(posture != nil ? "Modo \(posture!)" : "Ajuste Personalizado")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                Text("biked.app")
                    .font(.system(size: 10, weight: .black))
                    .kerning(1.5)
                    .foregroundColor(AppTheme.Colors.accent)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
        }
        .frame(width: 360, height: 640)
        .background(
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.08)
                LinearGradient(
                    colors: [
                        Color(red: 0.09, green: 0.11, blue: 0.15),
                        Color(red: 0.03, green: 0.04, blue: 0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.accent.opacity(0.6),
                            Color.white.opacity(0.1),
                            AppTheme.Colors.accent.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}

private struct StoryMetricPill: View {
    let title: String
    let actual: String
    let target: String
    let diff: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 8.5, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
            
            HStack(alignment: .firstTextBaseline) {
                Text(actual)
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.white)
                
                Spacer()
                
                let diffInt = Int(diff)
                Text(diffInt >= 0 ? "+\(diffInt)mm" : "\(diffInt)mm")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(abs(diff) <= 8 ? .green : (abs(diff) <= 20 ? .cyan : .orange))
            }
            
            Text("Diana: \(target)")
                .font(.system(size: 8.5))
                .foregroundColor(.white.opacity(0.45))
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }
}

private struct StoryStatBox: View {
    let icon: String
    let label: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.Colors.accent)
            Text(value)
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}

#if canImport(UIKit)
import UIKit

@MainActor
enum FitStoryRenderer {
    static func renderImage(result: MatchingResult, posture: String?) -> UIImage? {
        let card = FitStoryCardView(result: result, posture: posture)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0 // 1080x1920 Retina resolution
        return renderer.uiImage
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    
    init(activityItems: [Any], applicationActivities: [UIActivity]? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
