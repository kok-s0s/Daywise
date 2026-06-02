import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum DaywiseTheme {
    static let accent = Color(hex: "#00E5FF")
    static let pageBackground = Color(hex: "#050506")
    static let surface = Color(hex: "#101114")
    static let elevatedSurface = Color(hex: "#15171C")
    static let softSurface = Color(hex: "#1B1D22")
    static let border = Color.white.opacity(0.10)
    static let glow = Color(hex: "#00E5FF").opacity(0.28)
    static let shadow = Color.black.opacity(0.34)
    static let cardRadius: CGFloat = 8
}
