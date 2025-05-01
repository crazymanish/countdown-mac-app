import SwiftUI

extension LinearGradient {
    static var appGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                .red, .orange, .yellow, .green, .blue, .indigo, .purple
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}