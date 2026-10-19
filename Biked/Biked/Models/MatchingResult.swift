import Foundation

struct MatchingResult: Identifiable, Hashable {
    let id = UUID()
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
    // Usa la misma distancia euclidiana que el ordenado, así el % es coherente con la posición en la lista
    var confidenceScore: Double {
        max(0, 100 - distance)
    }
}
