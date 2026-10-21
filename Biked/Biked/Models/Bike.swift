import Foundation

struct BikeSpecs: Codable, Hashable {
    let groupset: String
    let wheelset: String
    let powerMeter: String
    
    enum CodingKeys: String, CodingKey {
        case groupset, wheelset
        case powerMeter = "power_meter"
    }
}

struct BikeBuild: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let color: String
    let priceEur: Double
    let images: [URL]
    let specs: BikeSpecs
    let inventory: [String: Int] // Map size -> quantity
    
    enum CodingKeys: String, CodingKey {
        case id, name, color, images, specs, inventory
        case priceEur = "price_eur"
    }
    
    var formattedPrice: String {
        return "€\(Int(priceEur))"
    }
}

struct Bike: Identifiable, Codable, Hashable {
    let id: String
    let brand: String
    let model: String
    let year: Int
    let category: String
    let description: String
    let officialUrl: String?
    let geometry: [Geometry]
    let builds: [BikeBuild]
    
    // Computed helper to get a representative image (first build, first image)
    var mainImage: URL? {
        if let url = builds.first?.images.first, let resolved = resolveImageURL(url) {
            return resolved
        }
        // Fallback: Check if an asset exists in Bundle matching bike.id (e.g. "trek-madone-slr.png")
        if let localURL = Bundle.main.url(forResource: id, withExtension: "png") {
            return localURL
        }
        return nil
    }
    
    func resolveImageURL(_ url: URL) -> URL? {
        let filename = url.lastPathComponent
        
        // 1. Check if the asset exists locally in the Bundle
        if let localURL = Bundle.main.url(forResource: filename, withExtension: nil) {
            return localURL
        }
        
        // Handle cases where the extension might be separate
        if let nameOnly = filename.components(separatedBy: ".").first,
           let ext = filename.components(separatedBy: ".").last,
           let localURL = Bundle.main.url(forResource: nameOnly, withExtension: ext) {
            return localURL
        }
        
        // 2. If it's a full remote URL (GitHub or other), return as is
        // (Ensuring it's not a relative URL mistaken for a full one)
        if url.scheme?.hasPrefix("http") == true {
            return url
        }
        
        // 3. Fallback: Reconstruct Supabase Public Storage URL
        // Used for paths coming from the database that might not have the full domain
        let publicStorageBase = SupabaseConfig.storageBaseURL.absoluteString
        
        // If the URL string itself already contains 'bike-images', we might just need the base domain
        let urlString = url.absoluteString
        if urlString.contains("bike-images") {
            if urlString.starts(with: "http") {
                return url
            } else {
                // Prepend base if it's just the path
                let path = urlString.components(separatedBy: "bike-images/").last ?? filename
                return URL(string: publicStorageBase + path)
            }
        }
        
        // Default Supabase attempt
        return URL(string: publicStorageBase + filename)
    }
    
    let dateAdded: String?
    
    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    enum CodingKeys: String, CodingKey {
        case id, brand, model, year, category, description, geometry, builds
        case officialUrl = "official_url"
        case dateAdded = "dateAdded"
    }
    
    var isNew: Bool {
        guard let dateString = dateAdded,
              let date = Bike.isoDateFormatter.date(from: dateString) else { return false }
        
        // Consider it new if added in the last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return date > thirtyDaysAgo
    }
    
    var priceRange: String {
        let prices = builds.map { $0.priceEur }
        guard let minPrice = prices.min(), let maxPrice = prices.max() else { return "N/A" }
        
        if minPrice != maxPrice {
            return "€\(Int(minPrice)) - €\(Int(maxPrice))"
        } else {
            return "€\(Int(minPrice))"
        }
    }
}
