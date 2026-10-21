import Foundation

actor BikeAPIService {
    static let shared = BikeAPIService()
    
    // In-memory cache for instant navigation and UI responsiveness
    private var cachedBikes: [Bike] = []
    private var hasAttemptedCloudSync = false

    func fetchBikes(forceRefresh: Bool = false) async throws -> [Bike] {
        // 1. If in-memory cache is populated and no force refresh requested, return immediately
        if !cachedBikes.isEmpty && !forceRefresh {
            return cachedBikes
        }
        
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("bikes_cache.json")
        
        // 2. Local-First: Prefer persisted disk cache (newer synced data) with bundle as fallback
        if cachedBikes.isEmpty {
            if let diskBikes = loadDiskCache(from: cacheURL), !diskBikes.isEmpty {
                cachedBikes = diskBikes
            } else if let localBikes = loadLocalBundleData() {
                cachedBikes = localBikes
            }
        }
        
        // 3. Attempt cloud sync (Supabase) with a strict timeout if not already attempted or force refreshed
        if !hasAttemptedCloudSync || forceRefresh {
            hasAttemptedCloudSync = true
            do {
                let cloudBikes = try await withTimeout(seconds: 3.0) {
                    try await SupabaseService.shared.fetchBikes()
                }
                if !cloudBikes.isEmpty {
                    self.cachedBikes = cloudBikes
                    if let encoded = try? JSONEncoder().encode(cloudBikes) {
                        try? encoded.write(to: cacheURL)
                    }
                }
            } catch {
                print("Supabase unreachable or timed out (\(error.localizedDescription)). Using local data.")
            }
        }
        
        return cachedBikes
    }
    
    private func loadLocalBundleData() -> [Bike]? {
        guard let bundleUrl = Bundle.main.url(forResource: "bikes", withExtension: "json") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: bundleUrl)
            return try JSONDecoder().decode([Bike].self, from: data)
        } catch {
            print("Error decoding bundled bikes.json: \(error)")
            return nil
        }
    }
    
    private func loadDiskCache(from url: URL) -> [Bike]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([Bike].self, from: data)
    }
    
    private func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @Sendable @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw URLError(.timedOut)
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

