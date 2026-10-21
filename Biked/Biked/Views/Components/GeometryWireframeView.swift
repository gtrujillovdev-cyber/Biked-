import SwiftUI

struct GeometryWireframeView: View {
    let geoA: Geometry
    let geoB: Geometry
    let nameA: String
    let nameB: String
    let sizeA: String
    let sizeB: String
    
    @State private var showGrid: Bool = true
    @State private var showDeltas: Bool = true
    
    private let colorA = Color(red: 0.0, green: 0.88, blue: 1.0) // Neon Cyan
    private let colorB = Color(red: 1.0, green: 0.20, blue: 0.60) // Neon Magenta
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.2.layers.3d")
                            .foregroundColor(AppTheme.Colors.accent)
                        Text("DIAGRAMA VECTORIAL SUPERPUESTO")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .kerning(1.2)
                    }
                    Text("Superposición de cuadros con eje pedalier (BB) común")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Toggle Grid Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDeltas.toggle()
                    }
                }) {
                    Image(systemName: showDeltas ? "ruler.fill" : "ruler")
                        .font(.caption)
                        .foregroundColor(showDeltas ? AppTheme.Colors.accent : .gray)
                        .padding(6)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            
            // Vector Canvas
            ZStack {
                // Background CAD Blueprint Grid
                blueprintGrid
                
                Canvas { context, size in
                    drawFrames(in: &context, size: size)
                }
                .frame(height: 220)
                .padding(.horizontal, 10)
            }
            .background(Color(red: 0.04, green: 0.06, blue: 0.09))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 12)
            
            // Legend
            HStack(spacing: 10) {
                legendItem(
                    color: colorA,
                    title: nameA,
                    size: sizeA,
                    stack: Int(geoA.stack),
                    reach: Int(geoA.reach)
                )
                
                legendItem(
                    color: colorB,
                    title: nameB,
                    size: sizeB,
                    stack: Int(geoB.stack),
                    reach: Int(geoB.reach)
                )
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color.black.opacity(0.45))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
    
    private var blueprintGrid: some View {
        GeometryReader { proxy in
            Path { path in
                let step: CGFloat = 20
                for x in stride(from: 0, to: proxy.size.width, by: step) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                }
                for y in stride(from: 0, to: proxy.size.height, by: step) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                }
            }
            .stroke(Color.white.opacity(0.03), lineWidth: 1)
        }
    }
    
    private func drawFrames(in context: inout GraphicsContext, size: CGSize) {
        // BB Origin in canvas coordinates (e.g. 30% from left, 75% from top)
        let bbX = size.width * 0.32
        let bbY = size.height * 0.72
        
        // Scale mm to screen points
        // Typical Stack ~540mm, Reach ~390mm
        let scale: CGFloat = size.height / 780.0
        
        // Helper to convert (Reach, Stack) to canvas point
        func pointFor(reach: Double, stack: Double) -> CGPoint {
            CGPoint(
                x: bbX + CGFloat(reach) * scale,
                y: bbY - CGFloat(stack) * scale
            )
        }
        
        // 1. Draw Ground line & Wheels (700c outer diameter ~680mm -> radius ~340mm)
        let wheelRadius: CGFloat = 340.0 * scale
        let groundY = bbY + (70.0 * scale) // BB drop ~70mm
        
        var groundPath = Path()
        groundPath.move(to: CGPoint(x: 10, y: groundY))
        groundPath.addLine(to: CGPoint(x: size.width - 10, y: groundY))
        context.stroke(groundPath, with: .color(Color.white.opacity(0.1)), lineWidth: 1)
        
        // Wheelbase estimation: Rear axle ~410mm back, Front axle ~590mm forward
        let rearAxle = CGPoint(x: bbX - (410.0 * scale), y: groundY - wheelRadius)
        let frontAxle = CGPoint(x: bbX + (590.0 * scale), y: groundY - wheelRadius)
        
        // Draw Wheel Outlines
        for axle in [rearAxle, frontAxle] {
            let wheelRect = CGRect(
                x: axle.x - wheelRadius,
                y: axle.y - wheelRadius,
                width: wheelRadius * 2,
                height: wheelRadius * 2
            )
            context.stroke(Path(ellipseIn: wheelRect), with: .color(Color.white.opacity(0.06)), lineWidth: 1)
        }
        
        // 2. Draw Frame A (Cyan)
        let headTubeA = pointFor(reach: geoA.reach, stack: geoA.stack)
        drawSingleFrame(
            in: &context,
            bb: CGPoint(x: bbX, y: bbY),
            headTube: headTubeA,
            rearAxle: rearAxle,
            frontAxle: frontAxle,
            color: colorA,
            scale: scale
        )
        
        // 3. Draw Frame B (Magenta)
        let headTubeB = pointFor(reach: geoB.reach, stack: geoB.stack)
        drawSingleFrame(
            in: &context,
            bb: CGPoint(x: bbX, y: bbY),
            headTube: headTubeB,
            rearAxle: rearAxle,
            frontAxle: frontAxle,
            color: colorB,
            scale: scale
        )
        
        // 4. Draw Delta Vector between Head Tube A & B
        if showDeltas {
            var deltaPath = Path()
            deltaPath.move(to: headTubeA)
            deltaPath.addLine(to: headTubeB)
            context.stroke(
                deltaPath,
                with: .color(Color.yellow),
                style: StrokeStyle(lineWidth: 2, dash: [4, 3])
            )
            
            // Markers on Head Tubes
            context.fill(Path(ellipseIn: CGRect(x: headTubeA.x - 4, y: headTubeA.y - 4, width: 8, height: 8)), with: .color(colorA))
            context.fill(Path(ellipseIn: CGRect(x: headTubeB.x - 4, y: headTubeB.y - 4, width: 8, height: 8)), with: .color(colorB))
            
            // Delta text
            let dS = Int(geoB.stack - geoA.stack)
            let dR = Int(geoB.reach - geoA.reach)
            let dSStr = dS >= 0 ? "+\(dS)" : "\(dS)"
            let dRStr = dR >= 0 ? "+\(dR)" : "\(dR)"
            
            let midX = (headTubeA.x + headTubeB.x) / 2
            let midY = min(headTubeA.y, headTubeB.y) - 14
            
            let text = Text("ΔS:\(dSStr) ΔR:\(dRStr)")
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(.yellow)
            context.draw(text, at: CGPoint(x: midX, y: midY))
        }
        
        // 5. Draw BB Pivot point
        let bbRect = CGRect(x: bbX - 5, y: bbY - 5, width: 10, height: 10)
        context.fill(Path(ellipseIn: bbRect), with: .color(.white))
        context.stroke(Path(ellipseIn: bbRect), with: .color(AppTheme.Colors.accent), lineWidth: 2)
    }
    
    private func drawSingleFrame(
        in context: inout GraphicsContext,
        bb: CGPoint,
        headTube: CGPoint,
        rearAxle: CGPoint,
        frontAxle: CGPoint,
        color: Color,
        scale: CGFloat
    ) {
        // Saddle Cluster (~73.5 degrees seat tube angle, length ~520mm)
        let seatTubeAngleRad: Double = 73.5 * .pi / 180.0
        let seatTubeLen: CGFloat = 520.0 * scale
        let saddleCluster = CGPoint(
            x: bb.x - (cos(seatTubeAngleRad) * seatTubeLen),
            y: bb.y - (sin(seatTubeAngleRad) * seatTubeLen)
        )
        
        var framePath = Path()
        // Seat tube
        framePath.move(to: bb)
        framePath.addLine(to: saddleCluster)
        
        // Down tube (BB to Head tube bottom)
        let headTubeBottom = CGPoint(x: headTube.x - 6, y: headTube.y + 24)
        framePath.move(to: bb)
        framePath.addLine(to: headTubeBottom)
        
        // Head tube
        let headTubeTop = CGPoint(x: headTube.x + 4, y: headTube.y - 12)
        framePath.move(to: headTubeBottom)
        framePath.addLine(to: headTubeTop)
        
        // Top tube
        framePath.move(to: saddleCluster)
        framePath.addLine(to: headTubeTop)
        
        // Chainstay (BB to Rear Axle)
        framePath.move(to: bb)
        framePath.addLine(to: rearAxle)
        
        // Seatstay (Saddle Cluster to Rear Axle)
        framePath.move(to: saddleCluster)
        framePath.addLine(to: rearAxle)
        
        // Fork (Head tube bottom to Front Axle)
        framePath.move(to: headTubeBottom)
        framePath.addLine(to: frontAxle)
        
        context.stroke(
            framePath,
            with: .color(color.opacity(0.85)),
            style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
        )
    }
    
    private func legendItem(color: Color, title: String, size: String, stack: Int, reach: Int) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .shadow(color: color.opacity(0.8), radius: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(title) (\(size))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("S: \(stack)mm • R: \(reach)mm")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
