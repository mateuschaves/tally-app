import SwiftUI

/// A dotted baseline rule used as a flexible leader between a label and its value
/// (the report's `border-bottom: 1px dotted`).
struct DottedLeader: View {
    let color: Color
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let y = geo.size.height - 3
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: geo.size.width, y: y))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1, dash: [1, 3]))
        }
        .frame(height: 14)
        .frame(maxWidth: .infinity)
    }
}
