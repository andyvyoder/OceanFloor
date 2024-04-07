
import SwiftUI

extension Color {
    // An nicer way to extract rgb values from a Color.
    func getRGB() -> (red: Float, green: Float, blue: Float) {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Float(red), Float(green), Float(blue))
    }
}
