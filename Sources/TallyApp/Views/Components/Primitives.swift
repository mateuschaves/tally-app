import SwiftUI

/// Small filled dot used for projects/priorities. `background: <color>`.
struct Dot: View {
    let color: Color
    var size: CGFloat = 6
    var body: some View {
        Circle().fill(color).frame(width: size, height: size)
    }
}

/// The pulsing "AGORA" dot — `@keyframes fluxoPulse` (opacity 1 → 0.25 → 1, 2.4s).
struct PulseDot: View {
    let color: Color
    var size: CGFloat = 6
    @State private var dim = false
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .opacity(dim ? 0.25 : 1)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: dim)
            .onAppear { dim = true }
    }
}

/// Thin progress bar (`height: 3; border-radius: 2`).
struct ProgressBar: View {
    let percent: Int
    let fill: Color
    let track: Color
    var height: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(fill)
                    .frame(width: max(0, geo.size.width * CGFloat(min(100, max(0, percent))) / 100))
            }
        }
        .frame(height: height)
    }
}

/// The check mark drawn in the prototype's SVG (`M2 6.5 4.7 9 10 3.2` in a 12×12 box).
struct CheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x / 12 * rect.width, y: rect.minY + y / 12 * rect.height)
        }
        var path = Path()
        path.move(to: point(2, 6.5))
        path.addLine(to: point(4.7, 9))
        path.addLine(to: point(10, 3.2))
        return path
    }
}

/// Right-pointing play triangle for the "start now" ring
/// (`M2.3 1.3 8.5 5 2.3 8.7 Z` in a 10×10 box).
struct PlayTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x / 10 * rect.width, y: rect.minY + y / 10 * rect.height)
        }
        var path = Path()
        path.move(to: point(2.3, 1.3))
        path.addLine(to: point(8.5, 5))
        path.addLine(to: point(2.3, 8.7))
        path.closeSubpath()
        return path
    }
}

/// The "×" of the traffic-light close button (`M2 2 L8 8 M8 2 L2 8`, 10×10 box).
struct CloseXShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x / 10 * rect.width, y: rect.minY + y / 10 * rect.height)
        }
        var path = Path()
        path.move(to: point(2, 2)); path.addLine(to: point(8, 8))
        path.move(to: point(8, 2)); path.addLine(to: point(2, 8))
        return path
    }
}

/// A section label like "AGORA" / "A SEGUIR" / "IMPEDIDAS".
struct SectionLabel: View {
    let text: String
    var color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 10.5, weight: .bold))
            .tracking(0.9) // ~0.09em at 10.5px
            .foregroundColor(color)
    }
}
