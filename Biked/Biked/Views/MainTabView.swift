import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var favoritesViewModel = FavoritesViewModel()
    @State private var appSettings = AppSettings.shared
    
    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Buscar", systemImage: "magnifyingglass")
                }
            
            ExploreView()
                .tabItem {
                    Label("Explorar", systemImage: "bicycle")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Favoritos", systemImage: "heart")
                }
        }
        .onAppear {
            favoritesViewModel.setContext(modelContext)
        }
        .environment(favoritesViewModel)
        .environment(appSettings)
        .tint(AppTheme.Colors.primary)
        .preferredColorScheme(.dark) // Enforce Dark Mode for Premium Feel
    }
}
