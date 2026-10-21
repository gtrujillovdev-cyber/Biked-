import SwiftUI

struct BikeDetailView: View {
    let bike: Bike
    var matchedGeometry: Geometry? = nil
    var matchingResult: MatchingResult? = nil
    var postureName: String? = nil
    
    @Environment(FavoritesViewModel.self) private var favoritesViewModel
    @Environment(AppSettings.self) private var settings
    @State private var selectedBuild: BikeBuild?
    @State private var showCompareSheet = false
    @State private var allBikesCache: [Bike] = []
    
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
                                HStack(spacing: 8) {
                                    Image(systemName: "safari.fill")
                                        .font(.subheadline)
                                    Text("VER EN WEB OFICIAL DE \(bike.brand.uppercased())")
                                        .fontWeight(.heavy)
                                        .font(.caption)
                                        .kerning(0.8)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption.bold())
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(AppTheme.Gradients.primary)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: AppTheme.Colors.primary.opacity(0.35), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(PremiumScaleButtonStyle())
                            .accessibilityLabel("Ver en sitio web oficial de \(bike.brand)")
                            .accessibilityHint("Abre el catálogo oficial del fabricante en el navegador")
                            .padding(.vertical, 4)
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
                        
                        // Biomechanical Fit Prescription Section (if matched)
                        if let result = matchingResult {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Diagnóstico de Ajuste Biomecánico")
                                    .font(AppTheme.Fonts.headline)
                                    .foregroundColor(.white)
                                
                                FitReportCardView(result: result, posture: postureName)
                                
                                // Share Sheet Button
                                ShareLink(
                                    item: "🚴 Prescripción Biomecánica Biked:\n\nModelo: \(bike.brand) \(bike.model)\nTalla Óptima: \(result.matchedSize)\nCompatibilidad: \(Int(result.confidenceScore))% (\(result.fitStatus.rawValue))\n\n• Stack Cuadro: \(Int(result.matchedGeometry.stack))mm (Tu diana: \(Int(result.userStack))mm)\n• Reach Cuadro: \(Int(result.matchedGeometry.reach))mm (Tu diana: \(Int(result.userReach))mm)\n• Espaciadores recomendados: ~\(result.recommendedSpacersMm)mm\n• Potencia sugerida: \(result.recommendedStemLengthMm)mm\n\n\(result.fitSummary)\n\nGenerado con Biked App."
                                ) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Compartir Prescripción Biomecánica")
                                            .font(AppTheme.Fonts.subheadline)
                                            .fontWeight(.bold)
                                    }
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(AppTheme.Colors.accent.opacity(0.15))
                                    .foregroundColor(AppTheme.Colors.accent)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(AppTheme.Colors.accent.opacity(0.4), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PremiumScaleButtonStyle())
                            }
                            .padding(.top, 6)
                        }
                        
                        // Compare Button
                        Button(action: {
                            Haptics.impact(style: .medium)
                            Task {
                                if allBikesCache.isEmpty {
                                    allBikesCache = (try? await BikeAPIService.shared.fetchBikes()) ?? []
                                }
                                showCompareSheet = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.left.arrow.right")
                                Text("Comparar Geometría con Otra Bici")
                                    .font(AppTheme.Fonts.subheadline)
                                    .fontWeight(.bold)
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.06))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PremiumScaleButtonStyle())
                        .sheet(isPresented: $showCompareSheet) {
                            CompareBikesView(availableBikes: allBikesCache.isEmpty ? [bike] : allBikesCache, initialBikeA: bike)
                        }
                        
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
                                let str = geo.reach > 0 ? geo.stack / geo.reach : 0
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text("Talla \(geo.size)")
                                                .font(.subheadline)
                                                .fontWeight(isMatch ? .bold : .medium)
                                                .foregroundColor(.white)
                                            
                                            if isMatch {
                                                Text("RECOMENDADO")
                                                    .font(.system(size: 8, weight: .black))
                                                    .padding(.horizontal, 5)
                                                    .padding(.vertical, 2)
                                                    .background(Color.green)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(4)
                                            }
                                        }
                                        
                                        Text("STR: \(String(format: "%.2f", str))")
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    let stackDisplay = settings.unitSystem == .metric ? "\(Int(geo.stack))mm" : String(format: "%.1fin", settings.convertFromMm(geo.stack))
                                    let reachDisplay = settings.unitSystem == .metric ? "\(Int(geo.reach))mm" : String(format: "%.1fin", settings.convertFromMm(geo.reach))
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(stackDisplay) / \(reachDisplay)")
                                            .font(.subheadline)
                                            .fontWeight(isMatch ? .bold : .regular)
                                            .foregroundColor(isMatch ? .white : .white.opacity(0.8))
                                        Text("Stack / Reach")
                                            .font(.system(size: 9))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(isMatch ? AppTheme.Colors.primary.opacity(0.25) : Color.white.opacity(0.04))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
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
