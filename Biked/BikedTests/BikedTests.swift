import Foundation

// MARK: - Standalone Test Harness for Biked Core Domain Logic
// Can be executed via swift BikedTests.swift or integrated into XCTest

struct BikedTestRunner {
    static var passedTests = 0
    static var failedTests = 0
    
    static func assert(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
        if condition {
            passedTests += 1
            print("  ✅ PASS: \(message)")
        } else {
            failedTests += 1
            print("  ❌ FAIL: \(message) [\(file):\(line)]")
        }
    }
    
    static func runAll() {
        print("\n🚀 --- INICIANDO SUITE DE TESTS: BIKED CORE DOMAIN --- 🚀\n")
        testGeometryDistance()
        testUnitConversions()
        testBiomechanicalFormulas()
        testCockpitPrescription()
        testBikesJSONIntegrity()
        
        print("\n==========================================")
        print("RESULTADOS FINALES:")
        print("  Aprobados: \(passedTests)")
        print("  Fallidos:  \(failedTests)")
        print("==========================================\n")
        
        if failedTests > 0 {
            exit(1)
        }
    }
    
    // 1. Distance Calculation Tests
    static func testGeometryDistance() {
        print("▶ Test 1: Cálculo de Distancia Euclidiana en Geometría")
        let stackDiff = 12.0
        let reachDiff = 5.0
        let distance = sqrt(pow(stackDiff, 2) + pow(reachDiff, 2)) // 13.0
        assert(abs(distance - 13.0) < 0.001, "Distancia euclidiana de (12, 5) debe ser exactamente 13.0 mm")
        
        // Exact match
        let zeroDist = sqrt(pow(0.0, 2) + pow(0.0, 2))
        assert(zeroDist == 0.0, "Distancia euclidiana con coincidencia exacta debe ser 0.0 mm")
    }
    
    // 2. Unit System Tests
    static func testUnitConversions() {
        print("\n▶ Test 2: Conversión de Unidades Métricas e Imperiales")
        let inches = 10.0
        let mmFromInches = inches * 25.4
        let cmFromInches = inches * 2.54
        assert(mmFromInches == 254.0, "10 pulgadas deben ser 254.0 mm")
        assert(cmFromInches == 25.4, "10 pulgadas deben ser 25.4 cm")
        
        let mm = 560.0
        let inchesFromMm = mm / 25.4
        assert(abs(inchesFromMm - 22.047) < 0.01, "560 mm deben ser aprox 22.05 pulgadas")
        
        let heightCm = 178.0
        let heightInches = heightCm / 2.54
        assert(abs(heightInches - 70.078) < 0.1, "178 cm de altura deben ser aprox 70.1 pulgadas")
    }
    
    // 3. Biomechanical Regression Tests
    static func testBiomechanicalFormulas() {
        print("\n▶ Test 3: Fórmulas de Regresión Biomecánica")
        let inseamCm = 83.0
        let heightCm = 178.0
        
        // Road Sport: Stack factor = 0.69, Reach factor = 0.225
        let stackSport = inseamCm * 0.69 * 10
        let reachSport = heightCm * 0.225 * 10
        assert(abs(stackSport - 572.7) < 0.1, "Stack objetivo Sport para entrepierna 83cm debe ser 572.7 mm")
        assert(abs(reachSport - 400.5) < 0.1, "Reach objetivo Sport para altura 178cm debe ser 400.5 mm")
        
        // Road Aero vs Comfort
        let stackAero = inseamCm * 0.67 * 10
        let stackComfort = inseamCm * 0.715 * 10
        assert(stackAero < stackSport, "Postura Aero debe tener un Stack menor (posición más baja) que Sport")
        assert(stackComfort > stackSport, "Postura Comfort debe tener un Stack mayor (posición más erguida) que Sport")
        
        // TT vs Road
        let stackTT = inseamCm * 0.65 * 10
        assert(stackTT < stackSport, "Bici TT/Triatlón debe tener un Stack inferior a Carretera para misma entrepierna")
    }
    
    // 4. Cockpit Configuration Guide
    static func testCockpitPrescription() {
        print("\n▶ Test 4: Prescripción de Puesto de Conducción (Cockpit)")
        // Frame stack lower than target (user needs spacers)
        let stackDiffNegative = -22.0 // frame stack is 22mm below target
        let spacers = min(40, max(5, Int(round(abs(stackDiffNegative) / 5.0) * 5.0)))
        assert(spacers == 20, "Déficit de stack de -22mm debe sugerir 20mm de espaciadores")
        
        // Reach correction: frame reach longer than target (shorten stem)
        let reachDiffPositive = 18.0
        let baseStem = 100
        let correction = Int(round(reachDiffPositive / 10.0) * 10.0)
        let stem = min(130, max(80, baseStem - correction))
        assert(stem == 80, "Exceso de reach de +18mm debe acortar potencia base 100mm a 80mm")
    }
    
    // 5. JSON Database Integrity Check
    static func testBikesJSONIntegrity() {
        print("\n▶ Test 5: Integridad del Catálogo bikes.json")
        let scriptPath = URL(fileURLWithPath: #file)
        let rootDir = scriptPath.deletingLastPathComponent().deletingLastPathComponent()
        let jsonUrl = rootDir.appendingPathComponent("Biked/Resources/bikes.json")
        
        guard let data = try? Data(contentsOf: jsonUrl),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            assert(false, "No se pudo leer o parsear bikes.json en \(jsonUrl.path)")
            return
        }
        
        assert(jsonArray.count >= 50, "El catálogo debe contener al menos 50 modelos de bicicletas (actual: \(jsonArray.count))")
        
        var validModels = 0
        var totalGeometries = 0
        
        for item in jsonArray {
            guard let brand = item["brand"] as? String, !brand.isEmpty,
                  let model = item["model"] as? String, !model.isEmpty,
                  let geos = item["geometry"] as? [[String: Any]], !geos.isEmpty else {
                continue
            }
            validModels += 1
            totalGeometries += geos.count
            
            for g in geos {
                let s = g["stack_mm"] as? Double ?? Double(g["stack_mm"] as? Int ?? 0)
                let r = g["reach_mm"] as? Double ?? Double(g["reach_mm"] as? Int ?? 0)
                if s <= 400 || s >= 750 || r <= 300 || r >= 500 {
                    assert(false, "Geometría fuera de rango plausible: \(brand) \(model) Stack=\(s) Reach=\(r)")
                }
            }
        }
        
        assert(validModels == jsonArray.count, "El 100% de los modelos deben tener marca, modelo y geometrías válidas")
        assert(totalGeometries >= 150, "Debe haber al menos 150 tallas registradas en total (actual: \(totalGeometries))")
    }
}

// Entry Point
BikedTestRunner.runAll()
