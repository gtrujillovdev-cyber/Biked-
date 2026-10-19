import SwiftUI

struct FitReportCardView: View {
    let result: MatchingResult
    let posture: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BIKED")
                        .font(.system(size: 14, weight: .black))
                        .kerning(3)
                        .foregroundColor(AppTheme.Colors.accent)
                    Text("INFORME DE AJUSTE BIOMÉCANICO")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .kerning(1)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: result.fitStatus.iconName)
                    Text(result.fitStatus.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(result.fitStatus.color.opacity(0.2))
                .foregroundColor(result.fitStatus.color)
                .cornerRadius(12)
            }
            
            Divider().background(Color.white.opacity(0.15))
            
            // Bike Model & Match Score
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.bike.brand.uppercased())
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundColor(AppTheme.Colors.accent)
                    Text(result.bike.model)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Talla Recomendada: \(result.matchedSize)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(result.confidenceScore))%")
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(result.fitStatus.color)
                    Text("Compatibilidad")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // Geometry Diff Grid
            HStack(spacing: 12) {
                MetricComparisonBox(
                    label: "Stack",
                    target: result.userStack,
                    actual: result.matchedGeometry.stack,
                    diff: result.stackDifference
                )
                MetricComparisonBox(
                    label: "Reach",
                    target: result.userReach,
                    actual: result.matchedGeometry.reach,
                    diff: result.reachDifference
                )
            }
            
            // Cockpit Configuration Guide
            VStack(alignment: .leading, spacing: 8) {
                Text("CONFIGURACIÓN DE PUESTO DE CONDUCCIÓN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .kerning(1)
                
                HStack(spacing: 10) {
                    CockpitPill(
                        icon: "square.stack.3d.up",
                        title: "Espaciadores",
                        value: "~\(result.recommendedSpacersMm) mm"
                    )
                    CockpitPill(
                        icon: "arrow.left.and.right",
                        title: "Potencia",
                        value: "\(result.recommendedStemLengthMm) mm"
                    )
                    CockpitPill(
                        icon: "gauge.medium",
                        title: "Ratio STR",
                        value: String(format: "%.2f", result.strRatio)
                    )
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)
            
            // Natural Language Summary
            Text(result.fitSummary)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(3)
                .padding(.top, 2)
            
            // Footer
            HStack {
                Text(posture != nil ? "Modo: \(posture!)" : "Ajuste Personalizado")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                Spacer()
                Text("biked.app")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.accent.opacity(0.8))
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.12, blue: 0.16),
                    Color(red: 0.05, green: 0.06, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct MetricComparisonBox: View {
    let label: String
    let target: Double
    let actual: Double
    let diff: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            
            HStack(alignment: .firstTextBaseline) {
                Text("\(Int(actual))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("mm")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Spacer()
                
                let diffInt = Int(diff)
                Text(diffInt >= 0 ? "+\(diffInt)mm" : "\(diffInt)mm")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(abs(diff) <= 8 ? .green : (abs(diff) <= 20 ? .cyan : .orange))
            }
            
            Text("Objetivo: \(Int(target))mm")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }
}

private struct CockpitPill: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.Colors.accent)
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 8))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}
