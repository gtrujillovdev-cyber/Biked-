import SwiftUI
import Observation

@Observable
@MainActor
class ExploreViewModel {
    var bikes: [Bike] = []
    var isLoading = false
    var errorMessage: String?
    var selectedCategory: String = "TODAS"
    
    var filteredBikes: [Bike] {
        if selectedCategory == "TODAS" {
            return bikes
        } else if selectedCategory == "CARRETERA" {
            return bikes.filter { $0.category == "ROAD" }
        } else if selectedCategory == "TT/TRIATLON" {
            return bikes.filter { $0.category == "TT" }
        } else {
            return bikes.filter { $0.category == selectedCategory }
        }
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
