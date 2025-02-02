import SwiftUI

struct LargeButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    let isDisabled: Bool

    func makeBody(configuration: Self.Configuration) -> some View {
        let currentForegroundColor
            = isDisabled || configuration.isPressed
            ? foregroundColor.opacity(0.3)
            : foregroundColor
        return configuration.label
            .padding()
            .foregroundColor(currentForegroundColor)
            .background(isDisabled || configuration.isPressed ? backgroundColor.opacity(0.3) : backgroundColor)
            .font(Font.system(size: 19, weight: .semibold))
            .clipShape(Capsule())
    }
}
