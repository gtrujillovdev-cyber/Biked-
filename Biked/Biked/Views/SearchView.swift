import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var useBiometrics = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                AppTheme.Gradients.oceanBeep
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        Text("Encuentra tu\nBici Ideal")
                            .font(AppTheme.Fonts.titleLarge)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        
                        // Mode Toggle
                        Toggle(isOn: $useBiometrics) {
                            Text(useBiometrics ? "Modo Biométrico" : "Modo Geometría")
                                .font(AppTheme.Fonts.headline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // Input Cards
                        VStack(spacing: 15) {
                            if useBiometrics {
                                biometricInputs
                            } else {
                                geometryInputs
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .animation(.easeInOut, value: useBiometrics)
                        
                        // Search Button
                        Button(action: {
                            viewModel.searchBikes(useBiometrics: useBiometrics)
                        }) {
                            Text("Buscar Bicicletas")
                                .font(AppTheme.Fonts.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.Gradients.primary)
                                .cornerRadius(15)
                                .shadow(color: AppTheme.Colors.primary.opacity(0.5), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Results Section
                        if !viewModel.matchedBikes.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Resultados Recomendados")
                                    .font(AppTheme.Fonts.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.matchedBikes) { result in
                                    NavigationLink(destination: BikeDetailView(bike: result.bike)) {
                                        BikeMatchCard(result: result)
                                    }
                                }
                            }
                            .padding(.top)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // Sub-views for inputs remain largely similar but styled
    var geometryInputs: some View {
        Group {
            InputRow(label: "Stack (mm)", value: $viewModel.targetStack)
            InputRow(label: "Reach (mm)", value: $viewModel.targetReach)
        }
    }
    
    var biometricInputs: some View {
        Group {
            InputRow(label: "Altura (cm)", value: $viewModel.riderHeight)
            InputRow(label: "Entrepierna (cm)", value: $viewModel.riderInseam)
            
            if let estimated = viewModel.estimatedGeometry {
                VStack(spacing: 5) {
                    Text("Geometría Estimada:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Stack: \(Int(estimated.stack))mm | Reach: \(Int(estimated.reach))mm")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.top, 5)
            }
        }
    }
}

// Helper View for Input Rows
struct InputRow: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(AppTheme.Fonts.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            TextField("0", text: $value)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// Helper for Result Card
struct BikeMatchCard: View {
    let result: MatchingResult
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: result.bike.builds.first?.images.first ?? "")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: 80, height: 80)
            .cornerRadius(10)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.bike.brand + " " + result.bike.model)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(result.bike.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppTheme.Colors.accent.opacity(0.2))
                    .cornerRadius(4)
                    .foregroundColor(AppTheme.Colors.accent)
            }
            
            Spacer()
            
            VStack {
                Text("\(Int(result.confidenceScore))%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(scoreColor)
                Text("Match")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    var scoreColor: Color {
        if result.confidenceScore >= 90 { return .green }
        if result.confidenceScore >= 75 { return .yellow }
        return .orange
    }
}
