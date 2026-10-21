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
                    VStack(spacing: 16) {
                        // Category Filter
                        Picker("Categoría", selection: $viewModel.selectedCategory) {
                            Text("Todas").tag("TODAS")
                            Text("Carretera").tag("CARRETERA")
                            Text("Triatlón/TT").tag("TT/TRIATLON")
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 4)
                        
                        // Brand Chips Carousel
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.allBrands, id: \.self) { brand in
                                    let isSelected = viewModel.selectedBrand == brand
                                    Button(action: {
                                        Haptics.selection()
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.selectedBrand = brand
                                        }
                                    }) {
                                        Text(brand)
                                            .font(.caption.bold())
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(
                                                isSelected ? AppTheme.Colors.accent : Color.white.opacity(0.08)
                                            )
                                            .foregroundColor(isSelected ? .black : .white.opacity(0.85))
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Active Results Count & Active Filter Indicator
                        HStack {
                            Text("\(viewModel.filteredBikes.count) BICICLETAS ENCONTRADAS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                                .kerning(1.2)
                            Spacer()
                            Text(viewModel.sortOption.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.Colors.accent)
                        }
                        .padding(.horizontal)
                        .padding(.top, 2)
                        
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
                        } else if viewModel.filteredBikes.isEmpty {
                            EmptyStateView(
                                title: "No encontramos bicicletas",
                                message: "Prueba a cambiar el filtro de marca o el término de búsqueda.",
                                systemImage: "bicycle",
                                actionTitle: "Restablecer Filtros"
                            ) {
                                withAnimation {
                                    viewModel.selectedBrand = "Todas"
                                    viewModel.selectedCategory = "TODAS"
                                    viewModel.searchText = ""
                                }
                            }
                            .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.filteredBikes) { bike in
                                    NavigationLink(destination: BikeDetailView(bike: bike)) {
                                        ExploreBikeCard(bike: bike)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 90)
                }
                .refreshable {
                    Haptics.impact(style: .light)
                    await viewModel.fetchBikes(forceRefresh: true)
                }
            }
            .navigationTitle("Explorar")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Buscar por marca, modelo..."
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Ordenar por", selection: $viewModel.sortOption) {
                            ForEach(ExploreViewModel.SortOption.allCases) { opt in
                                Label(opt.rawValue, systemImage: opt.icon).tag(opt)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
            }
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
        VStack(spacing: 0) {
            // Studio Bike Image Showcase
            ZStack(alignment: .topTrailing) {
                BikeImageView(url: bike.mainImage, brand: bike.brand, contentMode: .fit)
                    .frame(height: 190)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                
                // Badges top right
                HStack(spacing: 6) {
                    if bike.isNew {
                        Text("NEW")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AppTheme.Colors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    
                    Text("\(bike.year)")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white.opacity(0.85))
                        .cornerRadius(6)
                }
                .padding(12)
            }
            
            // Card Content Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bike.brand.uppercased())
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(AppTheme.Colors.accent)
                            .kerning(1.5)
                        
                        Text(bike.model)
                            .font(AppTheme.Fonts.titleMedium)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text(bike.priceRange)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                }
                
                // Specs Pill Bar
                HStack(spacing: 8) {
                    Text(bike.category)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.Colors.accent.opacity(0.18))
                        .foregroundColor(AppTheme.Colors.accent)
                        .cornerRadius(4)
                    
                    Text("\(bike.geometry.count) tallas")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    if let firstGeo = bike.geometry.first, firstGeo.reach > 0 {
                        let str = firstGeo.stack / firstGeo.reach
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        Text(String(format: "STR %.2f", str))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    if bike.officialUrl != nil {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .padding(16)
            .background(Color(red: 0.08, green: 0.10, blue: 0.13))
        }
        .background(Color(red: 0.05, green: 0.06, blue: 0.08))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
