import SwiftUI

struct BikeDetailView: View {
    let bike: Bike
    var matchedGeometry: Geometry? // Option to show matched geometry
    
    @State private var selectedBuild: BikeBuild?
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.Gradients.electric
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Immersive Header Image
                    if let build = selectedBuild ?? bike.builds.first {
                        TabView {
                            ForEach(build.images, id: \.self) { imageUrl in
                                AsyncImage(url: URL(string: imageUrl)) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                                        Color.gray.opacity(0.3)
                                    }
                                }
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
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        // Build Selector
                        if bike.builds.count > 1 {
                            VStack(alignment: .leading) {
                                Text("Selecciona Montaje")
                                    .font(AppTheme.Fonts.headline)
                                    .foregroundColor(.white)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(bike.builds) { build in
                                            BuildButton(
                                                title: build.name,
                                                isSelected: selectedBuild?.id == build.id
                                            ) {
                                                withAnimation {
                                                    selectedBuild = build
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Specs Grid
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
                        
                        // Geometry Table (Simplified for now)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Geometría (Stack / Reach)")
                                .font(AppTheme.Fonts.headline)
                                .foregroundColor(.white)
                            
                            ForEach(bike.geometry, id: \.size) { geo in
                                HStack {
                                    Text("Talla \(geo.size)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .frame(width: 80, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(geo.stack))mm / \(Int(geo.reach))mm")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
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
