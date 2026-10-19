import SwiftUI
import Combine

struct FavoritesView: View {
    @Environment(FavoritesViewModel.self) private var viewModel
    @State private var showingCompare = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.Gradients.oceanBeep
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Favoritos")
                                .font(AppTheme.Fonts.titleLarge)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if viewModel.favoriteBikes.count >= 2 {
                                Button(action: { showingCompare = true }) {
                                    Label("Comparar", systemImage: "arrow.left.arrow.right")
                                        .font(.caption.bold())
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(AppTheme.Colors.accent)
                                        .cornerRadius(20)
                                }
                            }
                        }
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
                    .padding(.bottom, 90)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingCompare) {
                CompareBikesView(availableBikes: viewModel.favoriteBikes)
            }
            .onAppear {
                Task { await viewModel.loadFavoriteBikes() }
            }
        }
    }
}
