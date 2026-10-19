import SwiftUI

struct CompareBikesView: View {
    let availableBikes: [Bike]
    @Environment(\.dismiss) private var dismiss
    
    @State private var bikeA: Bike
    @State private var bikeB: Bike
    @State private var selectedSizeA: String
    @State private var selectedSizeB: String
    
    init(availableBikes: [Bike], initialBikeA: Bike? = nil, initialBikeB: Bike? = nil) {
        self.availableBikes = availableBikes
        let first = initialBikeA ?? availableBikes.first ?? Bike.placeholder
        let second = initialBikeB ?? (availableBikes.count > 1 ? availableBikes[1] : first)
        
        _bikeA = State(initialValue: first)
        _bikeB = State(initialValue: second)
        _selectedSizeA = State(initialValue: first.geometry.first?.size ?? "")
        _selectedSizeB = State(initialValue: second.geometry.first?.size ?? "")
    }
    
    var geoA: Geometry? {
        bikeA.geometry.first(where: { $0.size == selectedSizeA }) ?? bikeA.geometry.first
    }
    
    var geoB: Geometry? {
        bikeB.geometry.first(where: { $0.size == selectedSizeB }) ?? bikeB.geometry.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Gradients.oceanBeep
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title & subtitle
                        VStack(spacing: 4) {
                            Text("Comparador de Geometría")
                                .font(AppTheme.Fonts.titleLarge)
                                .foregroundColor(.white)
                            Text("Compara dos modelos cara a cara en milímetros")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 10)
                        
                        // Bike Selection Cards (Side-by-Side)
                        HStack(spacing: 12) {
                            BikeSelectColumn(
                                title: "Bici A",
                                bike: $bikeA,
                                selectedSize: $selectedSizeA,
                                allBikes: availableBikes
                            )
                            
                            BikeSelectColumn(
                                title: "Bici B",
                                bike: $bikeB,
                                selectedSize: $selectedSizeB,
                                allBikes: availableBikes
                            )
                        }
                        .padding(.horizontal)
                        
                        // Biomechanical Verdict Banner
                        if let gA = geoA, let gB = geoB {
                            verdictBanner(gA: gA, gB: gB)
                                .padding(.horizontal)
                        }
                        
                        // Detailed Metric Comparison Table
                        if let gA = geoA, let gB = geoB {
                            comparisonTable(gA: gA, gB: gB)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.accent)
                }
            }
        }
    }
    
    private func verdictBanner(gA: Geometry, gB: Geometry) -> some View {
        let stackDiff = Int(gB.stack - gA.stack)
        let reachDiff = Int(gB.reach - gA.reach)
        
        let stackText = stackDiff > 0
            ? "\(bikeB.model) tiene +\(stackDiff)mm de Stack (posición más erguida)"
            : (stackDiff < 0 ? "\(bikeB.model) tiene \(stackDiff)mm de Stack (posición más agresiva)" : "Mismo Stack vertical")
        
        let reachText = reachDiff > 0
            ? "y +\(reachDiff)mm de Reach (más alargada)"
            : (reachDiff < 0 ? "y \(reachDiff)mm de Reach (más compacta)" : "y alcance idéntico")
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(AppTheme.Colors.accent)
                Text("VEREDICTO GEOMÉTRICO")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.accent)
                    .kerning(1)
            }
            Text("\(stackText) \(reachText) que \(bikeA.model).")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.95))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.Colors.accent.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func comparisonTable(gA: Geometry, gB: Geometry) -> some View {
        VStack(spacing: 12) {
            Text("TABLA DE COMPARACIÓN")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.5)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                MetricRow(
                    metric: "Stack",
                    valA: "\(Int(gA.stack)) mm",
                    valB: "\(Int(gB.stack)) mm",
                    diff: Int(gB.stack - gA.stack)
                )
                MetricRow(
                    metric: "Reach",
                    valA: "\(Int(gA.reach)) mm",
                    valB: "\(Int(gB.reach)) mm",
                    diff: Int(gB.reach - gA.reach)
                )
                
                let strA = gA.reach > 0 ? gA.stack / gA.reach : 0
                let strB = gB.reach > 0 ? gB.stack / gB.reach : 0
                MetricRow(
                    metric: "Ratio STR",
                    valA: String(format: "%.2f", strA),
                    valB: String(format: "%.2f", strB),
                    diff: nil
                )
                
                MetricRow(
                    metric: "Disciplina",
                    valA: bikeA.category,
                    valB: bikeB.category,
                    diff: nil
                )
                
                MetricRow(
                    metric: "Precio Base",
                    valA: bikeA.builds.first?.formattedPrice ?? "-",
                    valB: bikeB.builds.first?.formattedPrice ?? "-",
                    diff: nil
                )
            }
            .padding(14)
            .background(Color.black.opacity(0.4))
            .cornerRadius(16)
        }
    }
}

private struct BikeSelectColumn: View {
    let title: String
    @Binding var bike: Bike
    @Binding var selectedSize: String
    let allBikes: [Bike]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.accent)
            
            // Thumbnail
            BikeImageView(url: bike.mainImage, brand: bike.brand, contentMode: .fit)
                .frame(height: 90)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
            
            // Bike Picker
            Menu {
                ForEach(allBikes) { b in
                    Button("\(b.brand) \(b.model)") {
                        bike = b
                        selectedSize = b.geometry.first?.size ?? ""
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bike.brand)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        Text(bike.model)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .padding(8)
                .background(Color.white.opacity(0.08))
                .cornerRadius(8)
            }
            
            // Size Picker
            HStack {
                Text("Talla:")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Picker("Talla", selection: $selectedSize) {
                    ForEach(bike.geometry, id: \.size) { g in
                        Text(g.size).tag(g.size)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppTheme.Colors.accent)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .cornerRadius(16)
    }
}

private struct MetricRow: View {
    let metric: String
    let valA: String
    let valB: String
    let diff: Int?
    
    var body: some View {
        HStack {
            Text(metric)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Text(valA)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 70, alignment: .center)
            
            if let d = diff {
                Text(d == 0 ? "=" : (d > 0 ? "+\(d)" : "\(d)"))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(d == 0 ? .gray : (d > 0 ? .cyan : .orange))
                    .frame(width: 40, alignment: .center)
            } else {
                Spacer().frame(width: 40)
            }
            
            Text(valB)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 70, alignment: .center)
        }
        .padding(.vertical, 4)
    }
}

private extension Bike {
    static var placeholder: Bike {
        Bike(
            id: "placeholder",
            brand: "Trek",
            model: "Madone SLR Gen 7",
            year: 2024,
            category: "ROAD",
            description: "",
            officialUrl: nil,
            geometry: [Geometry(size: "54", stackMm: 540, reachMm: 386, topTubeMm: nil, seatTubeMm: nil)],
            builds: [],
            dateAdded: nil
        )
    }
}
