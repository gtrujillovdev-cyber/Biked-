import SwiftUI
import Combine

@Observable
class AppSettings {
    static let shared = AppSettings()
    
    enum UnitSystem: String, CaseIterable, Identifiable {
        case metric = "Métrico"
        case imperial = "Imperial"
        
        var id: String { self.rawValue }
        
        var heightUnit: String {
            switch self {
            case .metric: return "cm"
            case .imperial: return "in"
            }
        }
        
        var geometryUnit: String {
            switch self {
            case .metric: return "mm"
            case .imperial: return "in"
            }
        }
    }
    
    enum AppAppearance: String, CaseIterable, Identifiable {
        case dark = "Oscuro"
        case light = "Claro"
        case system = "Sistema"
        
        var id: String { self.rawValue }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .dark: return .dark
            case .light: return .light
            case .system: return nil
            }
        }
    }
    
    var unitSystem: UnitSystem = .metric {
        didSet {
            UserDefaults.standard.set(unitSystem.rawValue, forKey: "unitSystem")
        }
    }
    
    var appearance: AppAppearance = .dark {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: "appAppearance")
        }
    }
    
    init() {
        if let stored = UserDefaults.standard.string(forKey: "unitSystem"),
           let system = UnitSystem(rawValue: stored) {
            self.unitSystem = system
        }
        if let storedAppearance = UserDefaults.standard.string(forKey: "appAppearance"),
           let app = AppAppearance(rawValue: storedAppearance) {
            self.appearance = app
        }
    }
    
    // Conversion Helpers
    func convertToMm(_ value: Double) -> Double {
        if unitSystem == .metric { return value }
        return value * 25.4
    }
    
    func convertFromMm(_ value: Double) -> Double {
        if unitSystem == .metric { return value }
        return value / 25.4
    }
    
    func convertToCm(_ value: Double) -> Double {
        if unitSystem == .metric { return value }
        return value * 2.54
    }
    
    func convertFromCm(_ value: Double) -> Double {
        if unitSystem == .metric { return value }
        return value / 2.54
    }
}
