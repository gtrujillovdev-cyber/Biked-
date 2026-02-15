import SwiftUI

struct ExploreView: View {
    @State private var bikes: [Bike] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                AppTheme.Gradients.oceanBeep
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title
                        Text("Explorar Modelos")
                            .font(AppTheme.Fonts.titleLarge)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 20)
                        
                        // Grid or List of Bikes
                        LazyVStack(spacing: 15) {
                            ForEach(bikes) { bike in
                                NavigationLink(destination: BikeDetailView(bike: bike)) {
                                    ExploreBikeCard(bike: bike)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadBikes()
            }
        }
    }
    
    func loadBikes() {
        // In a real app, use ViewModel. For now, referencing static/service data
        Task {
            do {
                bikes = try await BikeAPIService.shared.fetchBikes()
            } catch {
                print("Error loading bikes: \(error)")
            }
        }
    }
}

struct ExploreBikeCard: View {
    let bike: Bike
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Image Background
            AsyncImage(url: URL(string: bike.builds.first?.images.first ?? "")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .frame(height: 200)
            .clipped()
            
            // Gradient Overlay for Text Readability
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(bike.brand.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.accent)
                
                Text(bike.model)
                    .font(AppTheme.Fonts.headline)
                    .foregroundColor(.white)
                
                Text(bike.category)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .background(Color.black)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
