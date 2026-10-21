import SwiftUI
import Observation

@Observable
@MainActor
class ExploreViewModel {
    enum SortOption: String, CaseIterable, Identifiable {
        case name = "Nombre (A-Z)"
        case newest = "Año más reciente"
        case priceAsc = "Precio (Menor a Mayor)"
        case priceDesc = "Precio (Mayor a Menor)"
        case strAggressive = "Más Aero / Agresiva (STR bajo)"
        case strComfort = "Más Confort (STR alto)"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .name: return "textformat"
            case .newest: return "sparkles"
            case .priceAsc: return "arrow.up.circle"
            case .priceDesc: return "arrow.down.circle"
            case .strAggressive: return "flame"
            case .strComfort: return "heart"
            }
        }
    }
    
    var bikes: [Bike] = []
    var isLoading = false
    var errorMessage: String?
    var selectedCategory: String = "TODAS"
    var selectedBrand: String = "Todas"
    var searchText: String = ""
    var sortOption: SortOption = .name
    
    var allBrands: [String] {
        let brands = Set(bikes.map { $0.brand })
        return ["Todas"] + Array(brands).sorted()
    }
    
    var filteredBikes: [Bike] {
        var result = bikes
        
        // 1. Category Filter
        if selectedCategory == "CARRETERA" {
            result = result.filter { $0.category == "ROAD" }
        } else if selectedCategory == "TT/TRIATLON" {
            result = result.filter { $0.category == "TT" }
        } else if selectedCategory != "TODAS" {
            result = result.filter { $0.category == selectedCategory }
        }
        
        // 2. Brand Filter
        if selectedBrand != "Todas" {
            result = result.filter { $0.brand.caseInsensitiveCompare(selectedBrand) == .orderedSame }
        }
        
        // 3. Search Text Filter
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { bike in
                bike.brand.lowercased().contains(query) ||
                bike.model.lowercased().contains(query) ||
                bike.category.lowercased().contains(query) ||
                bike.description.lowercased().contains(query)
            }
        }
        
        // 4. Sorting
        switch sortOption {
        case .name:
            result.sort { "\($0.brand) \($0.model)" < "\($1.brand) \($1.model)" }
        case .newest:
            result.sort { $0.year > $1.year }
        case .priceAsc:
            result.sort {
                let p0 = $0.builds.first?.priceEur ?? 0
                let p1 = $1.builds.first?.priceEur ?? 0
                return p0 < p1
            }
        case .priceDesc:
            result.sort {
                let p0 = $0.builds.first?.priceEur ?? 0
                let p1 = $1.builds.first?.priceEur ?? 0
                return p0 > p1
            }
        case .strAggressive:
            result.sort { b1, b2 in
                let str1 = (b1.geometry.first?.reach ?? 1) > 0 ? (b1.geometry.first?.stack ?? 0) / (b1.geometry.first?.reach ?? 1) : 999
                let str2 = (b2.geometry.first?.reach ?? 1) > 0 ? (b2.geometry.first?.stack ?? 0) / (b2.geometry.first?.reach ?? 1) : 999
                return str1 < str2
            }
        case .strComfort:
            result.sort { b1, b2 in
                let str1 = (b1.geometry.first?.reach ?? 1) > 0 ? (b1.geometry.first?.stack ?? 0) / (b1.geometry.first?.reach ?? 1) : 0
                let str2 = (b2.geometry.first?.reach ?? 1) > 0 ? (b2.geometry.first?.stack ?? 0) / (b2.geometry.first?.reach ?? 1) : 0
                return str1 > str2
            }
        }
        
        return result
    }
    
    func fetchBikes(forceRefresh: Bool = false) async {
        isLoading = true
        errorMessage = nil
        
        do {
            bikes = try await BikeAPIService.shared.fetchBikes(forceRefresh: forceRefresh)
        } catch {
            if bikes.isEmpty {
                errorMessage = "No se pudieron cargar las bicicletas. Verifica tu conexión."
            }
            print("Error loading bikes: \(error)")
        }
        
        isLoading = false
    }
}
