import Foundation
import SwiftUI

enum FitStatus: String, CaseIterable {
    case optimal = "Fit Óptimo"
    case compatible = "Compatible"
    case demanding = "Ajuste Exigente"
    
    var color: Color {
        switch self {
        case .optimal: return Color(red: 0.18, green: 0.80, blue: 0.44)
        case .compatible: return Color(red: 0.0, green: 0.82, blue: 0.93)
        case .demanding: return Color(red: 0.95, green: 0.61, blue: 0.07)
        }
    }
    
    var iconName: String {
        switch self {
        case .optimal: return "checkmark.seal.fill"
        case .compatible: return "slider.horizontal.3"
        case .demanding: return "exclamationmark.triangle.fill"
        }
    }
}

struct MatchingResult: Identifiable, Hashable {
    var id: String { "\(bike.id)-\(matchedGeometry.size)" }
    let bike: Bike
    let matchedGeometry: Geometry
    let userStack: Double
    let userReach: Double
    let distance: Double
    
    var stackDifference: Double {
        matchedGeometry.stack - userStack
    }
    
    var reachDifference: Double {
        matchedGeometry.reach - userReach
    }
    
    // Computed properties for easy access
    var bikeName: String { bike.model }
    var brand: String { bike.brand }
    var matchedSize: String { matchedGeometry.size }
    
    // Confidence Score (0-100%, higher is better)
    var confidenceScore: Double {
        let maxTolerance: Double = 30.0
        let score = (1.0 - (distance / maxTolerance)) * 100.0
        return max(0.0, min(100.0, score))
    }
    
    // Fit classification based on biomechanical tolerances
    var fitStatus: FitStatus {
        if distance <= 8.0 {
            return .optimal
        } else if distance <= 20.0 {
            return .compatible
        } else {
            return .demanding
        }
    }
    
    // Stack-to-Reach Ratio (STR) of the frame
    var strRatio: Double {
        guard matchedGeometry.reach > 0 else { return 0 }
        return matchedGeometry.stack / matchedGeometry.reach
    }
    
    var strCategory: String {
        if strRatio < 1.45 {
            return "Aero / Muy Agresiva"
        } else if strRatio <= 1.54 {
            return "Equilibrada / Racing"
        } else {
            return "Gran Fondo / Confort"
        }
    }
    
    // Concrete adjustment recommendations
    var recommendedSpacersMm: Int {
        // If frame stack is lower than target, spacers bridge the gap (typically 5mm to 35mm)
        if stackDifference < 0 {
            return min(40, max(5, Int(round(abs(stackDifference) / 5.0) * 5.0)))
        } else {
            return 5 // Minimal headset cap / spacer
        }
    }
    
    var recommendedStemLengthMm: Int {
        // Baseline 100mm stem: if frame reach is shorter than target, lengthen stem; if longer, shorten stem
        let baseStem = 100
        let reachCorrection = Int(round(reachDifference / 10.0) * 10.0)
        let stem = baseStem - reachCorrection
        return min(130, max(80, stem))
    }
    
    var fitSummary: String {
        switch fitStatus {
        case .optimal:
            return "Ajuste casi nativo. La geometría del cuadro coincide con tu morfología sin necesidad de adaptaciones complejas."
        case .compatible:
            let spacerText = stackDifference < -3 ? "\(recommendedSpacersMm)mm de espaciadores" : "espaciadores mínimos"
            return "Ajuste muy viable. Se recomienda configurar con \(spacerText) y potencia de \(recommendedStemLengthMm)mm."
        case .demanding:
            return "Geometría límite. Requiere ajustes notables en potencia o tija para alcanzar tu posición diana."
        }
    }
}
