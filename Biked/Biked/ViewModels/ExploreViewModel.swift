import SwiftUI
import Observation

@Observable
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
        } else {
            return bikes.filter { $0.category == "TT" }
        }
    }
    
    func fetchBikes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            bikes = try await BikeAPIService.shared.fetchBikes()
        } catch {
            errorMessage = "No se pudieron cargar las bicicletas. Verifica tu conexión."
            print("Error loading bikes: \(error)")
        }
        
        isLoading = false
    }
}
