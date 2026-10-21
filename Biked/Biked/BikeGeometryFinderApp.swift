import SwiftUI
import SwiftData

@main
struct BikeGeometryFinderApp: App {
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                } else {
                    MainTabView()
                }
            }
            .task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation(.easeInOut(duration: 0.8)) {
                    showSplash = false
                }
            }
        }
        .modelContainer(for: FavoriteBike.self)
    }
}
