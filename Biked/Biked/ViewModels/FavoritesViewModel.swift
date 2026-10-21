import Foundation
import SwiftUI
import Combine
import SwiftData

@Observable
@MainActor
class FavoritesViewModel {
    var favoriteBikes: [Bike] = []

    // Cache de todas las bicis para no hacer una petición de red en cada toggle de favorito
    private var allBikesCache: [Bike] = []
    private var modelContext: ModelContext?
    private let apiService: BikeAPIService
    
    init(apiService: BikeAPIService = .shared) {
        self.apiService = apiService
    }
    
    func setContext(_ context: ModelContext) {
        self.modelContext = context
        Task { await loadFavoriteBikes() }
    }
    
    func toggleFavorite(bikeId: String) {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<FavoriteBike>(predicate: #Predicate { $0.bikeId == bikeId })
        let existing = try? context.fetch(descriptor)
        
        if let favorite = existing?.first {
            context.delete(favorite)
        } else {
            let newFavorite = FavoriteBike(bikeId: bikeId)
            context.insert(newFavorite)
        }
        
        try? context.save()
        Task { await loadFavoriteBikes() }
    }
    
    func isFavorite(bikeId: String) -> Bool {
        guard let context = modelContext else { return false }
        let descriptor = FetchDescriptor<FavoriteBike>(predicate: #Predicate { $0.bikeId == bikeId })
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
    }
    
    func removeFavorite(bikeId: String) {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<FavoriteBike>(predicate: #Predicate { $0.bikeId == bikeId })
        // Solo eliminamos si existe — nunca añade accidentalmente
        guard let existing = try? context.fetch(descriptor), let favorite = existing.first else { return }
        context.delete(favorite)
        try? context.save()
        Task { await loadFavoriteBikes() }
    }
    
    func loadFavoriteBikes() async {
        guard let context = modelContext else { return }

        do {
            let descriptor = FetchDescriptor<FavoriteBike>()
            let favorites = try context.fetch(descriptor)
            let favoriteIDs = Set(favorites.map { $0.bikeId })

            // Solo pedimos red si aún no tenemos las bicis en cache
            if allBikesCache.isEmpty {
                allBikesCache = try await apiService.fetchBikes()
            }

            self.favoriteBikes = allBikesCache.filter { favoriteIDs.contains($0.id) }
        } catch {
            print("Error loading favorite bikes: \(error)")
        }
    }
}
