import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @Environment(AppSettings.self) private var settings
    @State private var isInputExpanded = true

    // Binding directo al ViewModel para evitar dos fuentes de verdad
    private var useBiometricsBinding: Binding<Bool> {
        Binding(
            get: { viewModel.searchMode == .biometric },
            set: { viewModel.searchMode = $0 ? .biometric : .geometric }
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                AppTheme.Gradients.oceanBeep
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Branding Header
                        VStack(spacing: 4) {
                            if UIImage(named: "biked_logo") != nil {
                                Image("biked_logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 36)
                            } else {
                                Image(systemName: "bicycle.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 36)
                                    .foregroundColor(AppTheme.Colors.accent)
                            }
                            
                            Text("Encuentra tu Bici Ideal")
                                .font(AppTheme.Fonts.headline)
                                .foregroundStyle(.white.opacity(0.7))
                                .kerning(1.0)
                        }
                        .padding(.top, 10) // Reduced padding for better fit under Dynamic Island/StatusBar
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                        
                        // Collapsible Inputs
                        VStack(spacing: 15) {
                            if isInputExpanded {
                                // Category Selector
                                Picker("Disciplina", selection: $viewModel.selectedCategory) {
                                    Text("Carretera").tag("CARRETERA")
                                    Text("Triatlón/TT").tag("TT/TRIATLON")
                                }
                                .pickerStyle(.segmented)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(15)
                                .padding(.horizontal)
                                .onChange(of: viewModel.selectedCategory) {
                                    Haptics.selection()
                                }
                                
                                // Mode Toggle — vinculado directamente al ViewModel (una sola fuente de verdad)
                                Toggle(isOn: useBiometricsBinding) {
                                    Text(viewModel.searchMode == .biometric ? "Modo Biométrico" : "Modo Geometría")
                                        .font(AppTheme.Fonts.headline)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(15)
                                .padding(.horizontal)
                                .onChange(of: viewModel.searchMode) {
                                    Haptics.selection()
                                }
                                
                                // Input Cards
                                VStack(spacing: 15) {
                                    if viewModel.searchMode == .biometric {
                                        biometricInputs
                                    } else {
                                        geometryInputs
                                    }
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                                .padding(.horizontal)
                                .animation(.easeInOut, value: viewModel.searchMode == .biometric)
                                
                                // Search Button
                                Button(action: {
                                    // searchMode ya está sincronizado con el toggle mediante el Binding
                                    Haptics.impact(style: .medium)
                                    Task {
                                        await viewModel.search()
                                        // Siempre colapsamos tras buscar — así el empty state es visible
                                        withAnimation {
                                            isInputExpanded = false
                                        }
                                        if !viewModel.searchResults.isEmpty {
                                            Haptics.notification(type: .success)
                                        } else if viewModel.errorMessage != nil {
                                            Haptics.notification(type: .error)
                                        }
                                    }
                                }) {
                                    HStack {
                                        if viewModel.isSearching {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Text("Buscar Bicicletas")
                                                .font(AppTheme.Fonts.headline)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.Gradients.primary)
                                    .cornerRadius(15)
                                    .shadow(color: AppTheme.Colors.primary.opacity(0.5), radius: 10, x: 0, y: 5)
                                }
                                .padding(.horizontal)
                                .padding(.top, 10)
                                .accessibilityLabel("Buscar bicicletas")
                                .accessibilityHint("Inicia la búsqueda con los parámetros ingresados")
                                .disabled(viewModel.isSearching)
                                .buttonStyle(.premiumScale)
                            } else {
                                // Collapsed State - "Modify Search" Button
                                Button(action: {
                                    Haptics.selection()
                                    withAnimation {
                                        isInputExpanded = true
                                    }
                                }) {
                                    Label("Modificar Búsqueda", systemImage: "slider.horizontal.3")
                                        .font(AppTheme.Fonts.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(15)
                                }
                                .padding(.horizontal)
                                .buttonStyle(.premiumScale)
                            }
                        }
                        
                        // Error Message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        // Results Section
                        if !viewModel.searchResults.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Resultados Recomendados")
                                    .font(AppTheme.Fonts.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.searchResults) { result in
                                    NavigationLink(destination: BikeDetailView(bike: result.bike, matchedGeometry: result.matchedGeometry)) {
                                        BikeMatchCard(result: result)
                                    }
                                }
                            }
                        // !isInputExpanded garantiza que el usuario ya buscó (los inputs se colapsan siempre tras buscar)
                        } else if !viewModel.isSearching && !isInputExpanded && viewModel.errorMessage == nil {
                            // Empty State
                            EmptyStateView(
                                title: "Sin resultados",
                                message: "No encontramos bicis con esa geometría. Prueba a aumentar la tolerancia o cambiar los valores.",
                                systemImage: "bicycle.circle",
                                actionTitle: "Modificar Búsqueda"
                            ) {
                                withAnimation {
                                    isInputExpanded = true
                                }
                            }
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(false)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Unidades", selection: Bindable(settings).unitSystem) {
                            ForEach(AppSettings.UnitSystem.allCases) { system in
                                Text(system.rawValue).tag(system)
                            }
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    // Sub-views for inputs
    var geometryInputs: some View {
        Group {
            InputRow(label: "Stack (\(settings.unitSystem.geometryUnit))", value: $viewModel.userStack)
            InputRow(label: "Reach (\(settings.unitSystem.geometryUnit))", value: $viewModel.userReach)
        }
    }
    
    var biometricInputs: some View {
        Group {
            InputRow(label: "Altura (\(settings.unitSystem.heightUnit))", value: $viewModel.userHeight)
            InputRow(label: "Entrepierna (\(settings.unitSystem.heightUnit))", value: $viewModel.userInseam)
            
            DisclosureGroup {
                VStack(spacing: 10) {
                    InputRow(label: "Tronco (\(settings.unitSystem.heightUnit))", value: $viewModel.userTrunk)
                    InputRow(label: "Brazo (\(settings.unitSystem.heightUnit))", value: $viewModel.userArm)
                }
                .padding(.top, 5)
            } label: {
                Text("Medidas Avanzadas")
                    .font(AppTheme.Fonts.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .accentColor(.white.opacity(0.6))
            .padding(.top, 5)
            
            // Only show estimate if we have valid inputs
            if let targetStack = viewModel.targetStack, let targetReach = viewModel.targetReach {
                 VStack(spacing: 5) {
                    Text("Geometría Estimada:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Stack: \(Int(targetStack))\(settings.unitSystem.geometryUnit) | Reach: \(Int(targetReach))\(settings.unitSystem.geometryUnit)")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.top, 10)
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
                .keyboardType(.decimalPad)
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
        HStack(spacing: 15) {
            // Bike Thumbnail
            BikeImageView(url: result.bike.mainImage, brand: result.bike.brand, contentMode: .fill)
                .frame(width: 90, height: 70)
                .cornerRadius(12)
                .clipped()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
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
                
                Text("Talla: \(result.matchedGeometry.size)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 2)
            }
            
            Spacer()
            
            VStack {
                Text("\(Int(result.confidenceScore))%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(scoreColor)
                Text("Match")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                if result.bike.officialUrl != nil {
                    Image(systemName: "cart.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.top, 4)
                }
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
