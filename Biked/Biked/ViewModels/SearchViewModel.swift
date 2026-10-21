import Foundation
import SwiftUI
import Combine

@Observable
@MainActor
class SearchViewModel {
    enum SearchMode {
        case biometric
        case geometric
    }
    
    enum RidingPosture: String, CaseIterable, Identifiable {
        case aero = "Aero / Racing"
        case sport = "Equilibrada"
        case comfort = "Gran Fondo"
        
        var id: String { rawValue }
        
        var shortName: String {
            switch self {
            case .aero: return "Aero"
            case .sport: return "Sport"
            case .comfort: return "Confort"
            }
        }
        
        var iconName: String {
            switch self {
            case .aero: return "flame.fill"
            case .sport: return "figure.outdoor.cycle"
            case .comfort: return "heart.fill"
            }
        }
        
        var description: String {
            switch self {
            case .aero: return "Máxima penetración aerodinámica (cuadro más bajo y alargado)"
            case .sport: return "Equilibrio polivalente entre rendimiento y ergonomía"
            case .comfort: return "Posición más erguida, ideal para tiradas largas y confort lumbar"
            }
        }
        
        var roadStackFactor: Double {
            switch self {
            case .aero: return 0.67
            case .sport: return 0.69
            case .comfort: return 0.715
            }
        }
        
        var roadReachFactor: Double {
            switch self {
            case .aero: return 0.235
            case .sport: return 0.225
            case .comfort: return 0.215
            }
        }
        
        var ttStackFactor: Double {
            switch self {
            case .aero: return 0.63
            case .sport: return 0.65
            case .comfort: return 0.675
            }
        }
        
        var ttReachFactor: Double {
            switch self {
            case .aero: return 0.245
            case .sport: return 0.235
            case .comfort: return 0.225
            }
        }
    }
    
    var searchMode: SearchMode = .biometric
    var selectedPosture: RidingPosture = .sport
    
    // Geometric Inputs
    var userStack: String = ""
    var userReach: String = ""
    var tolerance: Double = 18.0
    
    // Biometric Inputs
    var userHeight: String
    var userInseam: String
    var userTrunk: String = ""
    var userArm: String = ""
    
    // Category Filter: "CARRETERA" (Endurance/Aero/All-Rounder) vs "TT/TRIATLON"
    var selectedCategory: String = "CARRETERA"
    
    var searchResults: [MatchingResult] = []
    var isSearching: Bool = false
    var errorMessage: String?
    
    // Computed property que calcula la estimación una sola vez para ambas dimensiones
    // Evita llamar a estimateTargetGeometry() dos veces por render cycle
    var targetGeometry: (stack: Double?, reach: Double?) {
        if searchMode == .geometric {
            guard let s = Double(userStack.replacingOccurrences(of: ",", with: ".")),
                  let r = Double(userReach.replacingOccurrences(of: ",", with: ".")) else {
                return (nil, nil)
            }
            return (settings.convertToMm(s), settings.convertToMm(r))
        } else {
            return estimateTargetGeometry()
        }
    }

    var targetStack: Double? { targetGeometry.stack }
    var targetReach: Double? { targetGeometry.reach }
    
    private let apiService: BikeAPIService
    let settings: AppSettings
    
    init(apiService: BikeAPIService = .shared, settings: AppSettings = .shared) {
        self.apiService = apiService
        self.settings = settings
        if settings.unitSystem == .imperial {
            self.userHeight = "70"
            self.userInseam = "32.5"
        } else {
            self.userHeight = "178"
            self.userInseam = "83"
        }
    }
    
    func syncUnits(previousUnit: AppSettings.UnitSystem, newUnit: AppSettings.UnitSystem) {
        guard previousUnit != newUnit else { return }
        
        func convertLength(_ str: String) -> String {
            guard let val = Double(str.replacingOccurrences(of: ",", with: ".")) else { return str }
            if newUnit == .imperial {
                let inches = val / 2.54
                return String(format: "%.1f", inches)
            } else {
                let cm = val * 2.54
                return String(format: "%.0f", cm)
            }
        }
        
        func convertGeo(_ str: String) -> String {
            guard let val = Double(str.replacingOccurrences(of: ",", with: ".")) else { return str }
            if newUnit == .imperial {
                let inches = val / 25.4
                return String(format: "%.1f", inches)
            } else {
                let mm = val * 25.4
                return String(format: "%.0f", mm)
            }
        }
        
        if !userHeight.isEmpty { userHeight = convertLength(userHeight) }
        if !userInseam.isEmpty { userInseam = convertLength(userInseam) }
        if !userTrunk.isEmpty { userTrunk = convertLength(userTrunk) }
        if !userArm.isEmpty { userArm = convertLength(userArm) }
        if !userStack.isEmpty { userStack = convertGeo(userStack) }
        if !userReach.isEmpty { userReach = convertGeo(userReach) }
    }
    
    func search() async {
        let stack: Double
        let reach: Double
        
        // Helper to sanitize input (replace comma with dot)
        func sanitize(_ input: String) -> Double? {
            return Double(input.replacingOccurrences(of: ",", with: "."))
        }

        // Determine target Stack/Reach based on mode
        switch searchMode {
        case .geometric:
            guard let s = sanitize(userStack), let r = sanitize(userReach) else {
                errorMessage = "Introduzca valores válidos para Stack y Reach (ej. 550 o 550.5)"
                return
            }
            // El input del usuario está en sus unidades (mm o pulgadas), convertimos a mm
            stack = settings.convertToMm(s)
            reach = settings.convertToMm(r)

        case .biometric:
            guard let h = sanitize(userHeight), let i = sanitize(userInseam) else {
                errorMessage = "Introduzca su altura y entrepierna (ej. 175 o 175,5)"
                return
            }

            // Convertimos la entrada del usuario a cm para las fórmulas biométricas
            let heightCm = settings.convertToCm(h)
            let inseamCm = settings.convertToCm(i)
            let trunkCm = sanitize(userTrunk).map { settings.convertToCm($0) }
            let armCm = sanitize(userArm).map { settings.convertToCm($0) }

            let targets = estimateTargetGeometry(height: heightCm, inseam: inseamCm, trunk: trunkCm, arm: armCm)
            guard let s = targets.stack, let r = targets.reach else {
                errorMessage = "No se pudo estimar la geometría."
                return
            }
            // estimateTargetGeometry ya devuelve mm (multiplica por 10 internamente)
            // NO aplicar convertToMm aquí o se duplicaría la conversión en modo imperial
            stack = s
            reach = r
        }

        let finalStack = stack
        let finalReach = reach
        
        isSearching = true
        errorMessage = nil
        searchResults = []
        
        do {
            let bikes = try await apiService.fetchBikes()
            
            // Filter bikes based on selected category (Road vs TT)
            let filteredBikes = bikes.filter { bike in
                if selectedCategory == "CARRETERA" {
                    return bike.category == "ROAD"
                } else if selectedCategory == "TT/TRIATLON" {
                    return bike.category == "TT"
                } else {
                    return bike.category == selectedCategory
                }
            }
            
            searchResults = findMatches(for: filteredBikes, userStack: finalStack, userReach: finalReach, tolerance: tolerance)
        } catch {
            errorMessage = "Error al cargar bicicletas: \(error.localizedDescription)"
        }
        
        isSearching = false
    }
    
    // Simple Estimation Logic
    // Based on standard endurance road bike regression
    // Stack ~= 0.69 * Inseam
    // Reach ~= Height * 0.38 + Adjustment (approx)
    // Refinement:
    // Reach is often related to Trunk + Arm length, but Height is a decent proxy.
    // Ratio Reach/Height ~ 0.22 - 0.24 for Endurance geometry
    private func estimateTargetGeometry(height: Double? = nil, inseam: Double? = nil, trunk: Double? = nil, arm: Double? = nil) -> (stack: Double?, reach: Double?) {
        // Si los parámetros vienen de search(), ya están en cm (convertidos antes de llamar)
        // Si no vienen parámetros (llamada desde targetStack/targetReach para el preview),
        // los leemos de los strings del usuario y aplicamos la conversión de unidades aquí
        let h = height ?? Double(userHeight.replacingOccurrences(of: ",", with: ".")).map { settings.convertToCm($0) }
        let i = inseam ?? Double(userInseam.replacingOccurrences(of: ",", with: ".")).map { settings.convertToCm($0) }
        let t = trunk ?? Double(userTrunk.replacingOccurrences(of: ",", with: ".")).map { settings.convertToCm($0) }
        let a = arm ?? Double(userArm.replacingOccurrences(of: ",", with: ".")).map { settings.convertToCm($0) }
        
        guard let validInseam = i else {
            return (nil, nil)
        }
        
        let isTT = selectedCategory == "TT/TRIATLON"
        let stackFactor = isTT ? selectedPosture.ttStackFactor : selectedPosture.roadStackFactor
        let estimatedStack = validInseam * stackFactor * 10
        
        // Reach Estimation logic
        var estimatedReach: Double? = nil
        
        if let validTrunk = t, let validArm = a {
            // Advanced formula: (Trunk + Arm) * posture factor
            let trunkArmFactor: Double
            if isTT {
                trunkArmFactor = selectedPosture == .aero ? 0.485 : (selectedPosture == .sport ? 0.465 : 0.445)
            } else {
                trunkArmFactor = selectedPosture == .aero ? 0.465 : (selectedPosture == .sport ? 0.445 : 0.425)
            }
            estimatedReach = (validTrunk + validArm) * trunkArmFactor * 10
        } else if let validHeight = h {
            let reachFactor = isTT ? selectedPosture.ttReachFactor : selectedPosture.roadReachFactor
            estimatedReach = validHeight * reachFactor * 10
        }
        
        return (estimatedStack, estimatedReach)
    }
    
    private func findMatches(for bikes: [Bike], userStack: Double, userReach: Double, tolerance: Double) -> [MatchingResult] {
        var matches: [MatchingResult] = []
        
        for bike in bikes {
            // Find the best geometry for this bike
            // bike.geometry is the new array name
            let bestMatch = bike.geometry.min(by: { 
                $0.distance(to: userStack, targetReach: userReach) < $1.distance(to: userStack, targetReach: userReach)
            })
            
            if let best = bestMatch {
                let distance = best.distance(to: userStack, targetReach: userReach)

                // Solo incluimos bicicletas cuya mejor talla esté dentro de la tolerancia del usuario
                // La distancia es euclidiana en mm: sqrt(stackDiff² + reachDiff²)
                guard distance <= tolerance else { continue }

                let match = MatchingResult(
                    bike: bike,
                    matchedGeometry: best,
                    userStack: userStack,
                    userReach: userReach,
                    distance: distance
                )
                matches.append(match)
            }
        }
        
        return matches.sorted(by: { $0.distance < $1.distance })
    }
}
