import SwiftUI

struct ExploreView: View {
    @State private var viewModel = ExploreViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                AppTheme.Gradients.oceanBeep
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Category Filter
                        Picker("Categoría", selection: $viewModel.selectedCategory) {
                            Text("Todas").tag("TODAS")
                            Text("Carretera").tag("CARRETERA")
                            Text("Triatlón/TT").tag("TT/TRIATLON")
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Grid or List of Bikes
                        if viewModel.isLoading && viewModel.bikes.isEmpty {
                            ProgressView("Cargando catálogo...")
                                .tint(.white)
                                .foregroundColor(.white)
                                .padding(.top, 100)
                        } else if let error = viewModel.errorMessage {
                            VStack(spacing: 15) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.orange)
                                Text(error)
                                    .multilineTextAlignment(.center)
                                Button("Reintentar") {
                                    Task { await viewModel.fetchBikes() }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.top, 100)
                            .padding(.horizontal)
                        } else {
                            LazyVStack(spacing: 15) {
                                ForEach(viewModel.filteredBikes) { bike in
                                    NavigationLink(destination: BikeDetailView(bike: bike)) {
                                        ExploreBikeCard(bike: bike)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Explorar")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if viewModel.bikes.isEmpty {
                    Task { await viewModel.fetchBikes() }
                }
            }
        }
    }
}

struct ExploreBikeCard: View {
    let bike: Bike
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Image Background
            BikeImageView(url: bike.mainImage, brand: bike.brand, contentMode: .fill)
                .frame(height: 220)
                .clipped()
            
            // Gradient Overlay for Text Readability
            AppTheme.Gradients.darkOverlay
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(bike.brand.uppercased())
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(AppTheme.Colors.accent)
                        .kerning(1.5)
                    
                    if bike.isNew {
                        Text("NEW")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.Colors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                Text(bike.model)
                    .font(AppTheme.Fonts.titleMedium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(bike.category)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(20)
        }
        .background(Color.black)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
