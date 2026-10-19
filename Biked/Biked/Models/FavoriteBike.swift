import Foundation
import SwiftData

@Model
final class FavoriteBike {
    @Attribute(.unique) var bikeId: String
    var dateAdded: Date
    
    init(bikeId: String, dateAdded: Date = Date()) {
        self.bikeId = bikeId
        self.dateAdded = dateAdded
    }
}
