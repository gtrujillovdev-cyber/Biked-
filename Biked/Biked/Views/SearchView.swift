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
                                    NavigationLink(destination: BikeDetailView(
                                        bike: result.bike,
                                        matchedGeometry: result.matchedGeometry,
                                        matchingResult: result,
                                        postureName: viewModel.searchMode == .biometric ? viewModel.selectedPosture.rawValue : nil
                                    )) {
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
                    .padding(.bottom, 90)
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
                        
                        Picker("Apariencia", selection: Bindable(settings).appearance) {
                            ForEach(AppSettings.AppAppearance.allCases) { app in
                                Text(app.rawValue).tag(app)
                            }
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.white)
                    }
                }
            }
            .onChange(of: settings.unitSystem) { oldValue, newValue in
                viewModel.syncUnits(previousUnit: oldValue, newUnit: newValue)
            }
        }
    }
    
    // Sub-views for inputs
    var geometryInputs: some View {
        Group {
            let stackPlaceholder = settings.unitSystem == .metric ? "Ej. 560" : "Ej. 22"
            let reachPlaceholder = settings.unitSystem == .metric ? "Ej. 385" : "Ej. 15"
            InputRow(label: "Stack (\(settings.unitSystem.geometryUnit))", placeholder: stackPlaceholder, value: $viewModel.userStack)
            InputRow(label: "Reach (\(settings.unitSystem.geometryUnit))", placeholder: reachPlaceholder, value: $viewModel.userReach)
        }
    }
    
    var biometricInputs: some View {
        Group {
            let heightPlaceholder = settings.unitSystem == .metric ? "Ej. 178" : "Ej. 70"
            let inseamPlaceholder = settings.unitSystem == .metric ? "Ej. 83" : "Ej. 32.5"
            let trunkPlaceholder = settings.unitSystem == .metric ? "Ej. 62" : "Ej. 24.5"
            let armPlaceholder = settings.unitSystem == .metric ? "Ej. 65" : "Ej. 25.5"
            
            InputRow(label: "Altura (\(settings.unitSystem.heightUnit))", placeholder: heightPlaceholder, value: $viewModel.userHeight)
            InputRow(label: "Entrepierna (\(settings.unitSystem.heightUnit))", placeholder: inseamPlaceholder, value: $viewModel.userInseam)
            
            // Posture / Riding Style Selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Estilo de Posición")
                    .font(AppTheme.Fonts.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 8) {
                    ForEach(SearchViewModel.RidingPosture.allCases) { posture in
                        Button(action: {
                            Haptics.selection()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedPosture = posture
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: posture.iconName)
                                    .font(.system(size: 14))
                                Text(posture.shortName)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedPosture == posture
                                ? AppTheme.Colors.primary
                                : Color.white.opacity(0.06)
                            )
                            .foregroundColor(
                                viewModel.selectedPosture == posture
                                ? .white
                                : .white.opacity(0.6)
                            )
                            .cornerRadius(10)
                        }
                    }
                }
                
                Text(viewModel.selectedPosture.description)
                    .font(.caption2)
                    .foregroundColor(AppTheme.Colors.accent.opacity(0.85))
                    .padding(.horizontal, 2)
            }
            .padding(.top, 4)
            
            DisclosureGroup {
                VStack(spacing: 10) {
                    InputRow(label: "Tronco (\(settings.unitSystem.heightUnit))", placeholder: trunkPlaceholder, value: $viewModel.userTrunk)
                    InputRow(label: "Brazo (\(settings.unitSystem.heightUnit))", placeholder: armPlaceholder, value: $viewModel.userArm)
                }
                .padding(.top, 5)
            } label: {
                Text("Medidas Avanzadas (Opcional)")
                    .font(AppTheme.Fonts.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .accentColor(.white.opacity(0.6))
            .padding(.top, 5)
            
            // Only show estimate if we have valid inputs
            if let targetStack = viewModel.targetStack, let targetReach = viewModel.targetReach {
                let stackDisplay = settings.unitSystem == .metric ? "\(Int(targetStack))mm" : String(format: "%.1fin", settings.convertFromMm(targetStack))
                let reachDisplay = settings.unitSystem == .metric ? "\(Int(targetReach))mm" : String(format: "%.1fin", settings.convertFromMm(targetReach))
                
                VStack(spacing: 5) {
                    Text("Geometría Estimada (\(viewModel.selectedPosture.shortName)):")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Stack: \(stackDisplay) | Reach: \(reachDisplay)")
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
    var placeholder: String = "0"
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(AppTheme.Fonts.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            TextField(placeholder, text: $value)
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
        VStack(spacing: 8) {
            topRow
            deltaBar
        }
        .padding(12)
        .background(Color.black.opacity(0.45))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(result.fitStatus.color.opacity(0.35), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private var topRow: some View {
        HStack(spacing: 14) {
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
                Text("\(result.bike.brand) \(result.bike.model)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(result.bike.category)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.Colors.accent.opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(AppTheme.Colors.accent)
                    
                    Text("Talla: \(result.matchedGeometry.size)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.95))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                }
                
                // Fit status badge
                HStack(spacing: 4) {
                    Image(systemName: result.fitStatus.iconName)
                        .font(.system(size: 10, weight: .bold))
                    Text(result.fitStatus.rawValue)
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(result.fitStatus.color)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(result.confidenceScore))%")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(result.fitStatus.color)
                
                Text("Ajuste")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                if result.bike.officialUrl != nil {
                    Image(systemName: "cart.fill")
                        .font(.caption2)
                        .foregroundColor(.green.opacity(0.8))
                        .padding(.top, 2)
                }
            }
        }
    }
    
    private var deltaBar: some View {
        let dStack = Int(round(result.stackDifference))
        let dReach = Int(round(result.reachDifference))
        let stackColor: Color = abs(dStack) <= 15 ? .green : (abs(dStack) <= 25 ? .yellow : .orange)
        let reachColor: Color = abs(dReach) <= 10 ? .green : (abs(dReach) <= 18 ? .yellow : .orange)
        let dStackStr = dStack >= 0 ? "+\(dStack)" : "\(dStack)"
        let dReachStr = dReach >= 0 ? "+\(dReach)" : "\(dReach)"
        
        return HStack {
            Text("ΔS: \(dStackStr)mm")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(stackColor)
            
            Text("•")
                .foregroundColor(.white.opacity(0.3))
            
            Text("ΔR: \(dReachStr)mm")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(reachColor)
            
            Spacer()
            
            Text("STR \(String(format: "%.2f", result.strRatio)) (\(result.strCategory))")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
    }
}
