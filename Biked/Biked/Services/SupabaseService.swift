import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    
    private let client = SupabaseClient(
        supabaseURL: SupabaseConfig.url,
        supabaseKey: SupabaseConfig.apiKey
    )
    
    private init() {}
    
    // Fetch all bikes with their builds and geometries
    func fetchBikes() async throws -> [Bike] {
        // We match our local Bike model structure
        // Note: For now, we will use a simplified fetch that mirrors the JSON
        // but eventually we can use the relational schema designed in DATABASE_SCHEMA.sql
        
        let response: [Bike] = try await client
            .from("bikes_view") // We'll create a view to simplify the initial work
            .select()
            .execute()
            .value
        
        return response
    }
}
