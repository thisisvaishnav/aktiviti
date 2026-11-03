import SwiftUI

/// Ultra-smooth cubic spline area chart with gradient fill and subtle guide lines.
struct SmoothAreaChartView: View {
    let data: [Double]
    let tintColor: Color
    var maxValue: Double? = nil
    var showGrid: Bool = true

    init(data: [Double], tintColor: Color, maxValue: Double? = nil, showGrid: Bool = true) {
        self.data = data
        self.tintColor = tintColor
        self.maxValue = maxValue
        self.showGrid = showGrid
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                if showGrid {
                    VStack(spacing: 0) {
                        Spacer()
                        guideLine(w: w)
                        Spacer()
                        guideLine(w: w)
                        Spacer()
                        guideLine(w: w)
                        Spacer()
                    }
                }

                if data.count >= 2 {
                    let pts = calculatePoints(width: w, height: h)

                    // Gradient filled area
                    areaPath(for: pts, height: h)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tintColor.opacity(0.35),
                                    tintColor.opacity(0.15),
                                    tintColor.opacity(0.01)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Spline line stroke
                    splinePath(for: pts)
                        .stroke(
                            tintColor,
                            style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
                        )
                }
            }
        }
    }

    private func guideLine(w: CGFloat) -> some View {
        Rectangle()
            .fill(Color(red: 228/255, green: 228/255, blue: 233/255))
            .frame(width: w, height: 1)
    }

    private func calculatePoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard data.count >= 2 else { return [] }

        let peak = maxValue ?? max(1.0, data.max() ?? 100.0)
        let step = width / CGFloat(max(1, data.count - 1))
        let topPadding = height * 0.10
        let bottomY = height * 0.92
        let chartRange = bottomY - topPadding

        return data.enumerated().map { index, val in
            let ratio = max(0.0, min(val / peak, 1.0))
            let x = CGFloat(index) * step
            let y = bottomY - (CGFloat(ratio) * chartRange)
            return CGPoint(x: x, y: y)
        }
    }

    private func splinePath(for pts: [CGPoint]) -> Path {
        var path = Path()
        guard pts.count >= 2 else { return path }

        path.move(to: pts[0])
        if pts.count == 2 {
            path.addLine(to: pts[1])
            return path
        }

        for i in 0..<(pts.count - 1) {
            let p0 = i > 0 ? pts[i - 1] : pts[i]
            let p1 = pts[i]
            let p2 = pts[i + 1]
            let p3 = i < pts.count - 2 ? pts[i + 2] : p2

            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6.0,
                y: p1.y + (p2.y - p0.y) / 6.0
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6.0,
                y: p2.y - (p3.y - p1.y) / 6.0
            )
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }

        return path
    }

    private func areaPath(for pts: [CGPoint], height: CGFloat) -> Path {
        var path = splinePath(for: pts)
        guard pts.count >= 2, let last = pts.last, let first = pts.first else { return path }

        path.addLine(to: CGPoint(x: last.x, y: height))
        path.addLine(to: CGPoint(x: first.x, y: height))
        path.closeSubpath()
        return path
    }
}
