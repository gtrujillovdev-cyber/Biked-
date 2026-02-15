import SwiftUI
import Combine

struct FavoritesView: View {
    @State private var viewModel = FavoritesViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.Gradients.oceanBeep
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Favoritos")
                            .font(AppTheme.Fonts.titleLarge)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 20)
                        
                        if viewModel.favoriteBikes.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "heart.slash")
                                    .font(.system(size: 60))
                                    .foregroundColor(AppTheme.Colors.accent.opacity(0.5))
                                    .padding(.top, 50)
                                
                                Text("No tienes favoritos aún")
                                    .font(AppTheme.Fonts.headline)
                                    .foregroundColor(.white)
                                
                                Text("Tus bicicletas guardadas aparecerán aquí")
                                    .font(AppTheme.Fonts.subheadline)
                                    .foregroundColor(.gray)
                            }
                        } else {
                            LazyVStack(spacing: 15) {
                                ForEach(viewModel.favoriteBikes) { bike in
                                    NavigationLink(destination: BikeDetailView(bike: bike)) {
                                        ExploreBikeCard(bike: bike) // Reuse the card from ExploreView
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.removeFavorite(bikeId: bike.id)
                                        } label: {
                                            Label("Eliminar", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadFavorites()
            }
        }
    }
}
