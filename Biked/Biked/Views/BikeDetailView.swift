import SwiftUI

struct BikeDetailView: View {
    let bike: Bike
    var matchedGeometry: Geometry? // Option to show matched geometry
    
    @Environment(FavoritesViewModel.self) private var favoritesViewModel
    @Environment(AppSettings.self) private var settings
    @State private var selectedBuild: BikeBuild?
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.Gradients.electric
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Immersive Header Image
                    let buildImages = (selectedBuild ?? bike.builds.first)?.images ?? []
                    if buildImages.isEmpty {
                        BikeImageView(url: bike.mainImage, brand: bike.brand, contentMode: .fit)
                            .frame(height: 300)
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, AppTheme.Colors.backgroundData.opacity(0.8)]),
                                    startPoint: .center,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        TabView {
                            ForEach(buildImages, id: \.self) { imageUrl in
                                BikeImageView(url: bike.resolveImageURL(imageUrl), brand: bike.brand, contentMode: .fit)
                                    .clipped()
                            }
                        }
                        .tabViewStyle(PageTabViewStyle())
                        .frame(height: 300)
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, AppTheme.Colors.backgroundData.opacity(0.8)]),
                                startPoint: .center,
                                endPoint: .bottom
                            )
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Title & Price
                        HStack(alignment: .top) {
                            VStack(alignment: .leading) {
                                Text(bike.brand.uppercased())
                                    .font(AppTheme.Fonts.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppTheme.Colors.accent)
                                
                                Text(bike.model)
                                    .font(AppTheme.Fonts.titleLarge)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Text(selectedBuild?.formattedPrice ?? bike.priceRange)
                                .font(AppTheme.Fonts.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.Colors.primary)
                                .cornerRadius(8)
                        }
                        
                        // Official Link Button
                        if let urlString = bike.officialUrl, let url = URL(string: urlString) {
                            Link(destination: url) {
                                HStack {
                                    Text("EXPLORAR EN WEB OFICIAL")
                                        .fontWeight(.black)
                                        .font(.subheadline)
                                    Image(systemName: "arrow.up.right.square.fill")
                                }
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(AppTheme.Gradients.primary)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .buttonStyle(PremiumScaleButtonStyle())
                            .accessibilityLabel("Comprar en sitio web oficial")
                            .accessibilityHint("Abre el sitio web de la marca en el navegador")
                            .padding(.vertical, 10)
                        }
                        
                        Divider().background(Color.white.opacity(0.15))
                        
                        // Favorite Button (Prominent)
                        Button(action: {
                            Haptics.impact(style: .medium)
                            favoritesViewModel.toggleFavorite(bikeId: bike.id)
                        }) {
                            HStack {
                                Image(systemName: favoritesViewModel.isFavorite(bikeId: bike.id) ? "heart.fill" : "heart")
                                    .foregroundColor(favoritesViewModel.isFavorite(bikeId: bike.id) ? .red : .white)
                                Text(favoritesViewModel.isFavorite(bikeId: bike.id) ? "Guardado en Favoritos" : "Añadir a mi Garaje")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PremiumScaleButtonStyle())
                        .accessibilityLabel(favoritesViewModel.isFavorite(bikeId: bike.id) ? "Eliminar de favoritos" : "Añadir a favoritos")
                        
                        // Build Selector
                        if bike.builds.count > 1 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Opciones de Montaje")
                                    .font(AppTheme.Fonts.headline)
                                    .foregroundColor(.white)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(bike.builds) { build in
                                            BuildButton(
                                                title: build.name,
                                                isSelected: selectedBuild?.id == build.id
                                            ) {
                                                Haptics.selection()
                                                withAnimation(.spring()) {
                                                    selectedBuild = build
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.top, 10)
                        }
                        
                        // Specs Grid (...)
                        if let specs = (selectedBuild ?? bike.builds.first)?.specs {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Especificaciones")
                                    .font(AppTheme.Fonts.headline)
                                    .foregroundColor(.white)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                    SpecItem(icon: "gear", title: "Grupo", value: specs.groupset)
                                    SpecItem(icon: "circle.circle", title: "Ruedas", value: specs.wheelset)
                                    SpecItem(icon: "bolt", title: "Potenciómetro", value: specs.powerMeter)
                                }
                            }
                        }
                        
                        // Geometry Table
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Geometría (Stack / Reach)")
                                .font(AppTheme.Fonts.headline)
                                .foregroundColor(.white)
                            
                            ForEach(bike.geometry, id: \.size) { geo in
                                let isMatch = matchedGeometry?.size == geo.size
                                HStack {
                                    Text("Talla \(geo.size)")
                                        .font(.subheadline)
                                        .fontWeight(isMatch ? .bold : .regular)
                                        .foregroundColor(.white)
                                        .frame(width: 80, alignment: .leading)
                                    
                                    if isMatch {
                                        Text("RECOMENDADO")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(4)
                                    }
                                    
                                    Spacer()
                                    
                                    let stackDisplay = settings.unitSystem == .metric ? "\(Int(geo.stack))mm" : String(format: "%.1fin", settings.convertFromMm(geo.stack))
                                    let reachDisplay = settings.unitSystem == .metric ? "\(Int(geo.reach))mm" : String(format: "%.1fin", settings.convertFromMm(geo.reach))
                                    
                                    Text("\(stackDisplay) / \(reachDisplay)")
                                        .font(.subheadline)
                                        .fontWeight(isMatch ? .bold : .regular)
                                        .foregroundColor(isMatch ? .white : .gray)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal)
                                .background(isMatch ? AppTheme.Colors.primary.opacity(0.3) : Color.white.opacity(0.05))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isMatch ? AppTheme.Colors.primary : Color.clear, lineWidth: 1)
                                )
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(AppTheme.Colors.backgroundData) // Dark background for content
                    .cornerRadius(30, corners: [.topLeft, .topRight])
                    .offset(y: -30) // Overlap the image slightly
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    favoritesViewModel.toggleFavorite(bikeId: bike.id)
                }) {
                    Image(systemName: favoritesViewModel.isFavorite(bikeId: bike.id) ? "heart.fill" : "heart")
                        .foregroundColor(favoritesViewModel.isFavorite(bikeId: bike.id) ? .red : .white)
                }
            }
        }
        .onAppear {
            if selectedBuild == nil {
                selectedBuild = bike.builds.first
            }
        }
    }
}

// Helpers
struct BuildButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? AppTheme.Colors.primary : Color.white.opacity(0.1))
                .foregroundColor(.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1)
                )
        }
    }
}

struct SpecItem: View {
    let icon: String // SF Symbol name
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppTheme.Colors.accent)
                .font(.system(size: 20))
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// Extension for partial corner radius (if not available in standard library for this iOS version, we can use a shape or just standard cornerRadius)
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
