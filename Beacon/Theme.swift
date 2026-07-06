import SwiftUI

/// Beacon's identity: neutral slate backdrop, with the signature visual being
/// a bulb glyph whose glow color and radius interpolate from warm incandescent
/// amber (fresh) to cool dim slate-blue (near end of life). Deliberately
/// distinct from every sibling app's palette (charcoal/volt-yellow Volt,
/// cream/ink-navy "luxury editorial" apps, brown/sage apps).
enum BNTheme {
    static let backdrop = Color(red: 0.114, green: 0.122, blue: 0.137)   // neutral slate
    static let surface = Color(red: 0.157, green: 0.165, blue: 0.180)
    static let surfaceRaised = Color(red: 0.204, green: 0.212, blue: 0.227)
    static let ink = Color(red: 0.945, green: 0.945, blue: 0.941)
    static let inkFaded = Color(red: 0.945, green: 0.945, blue: 0.941).opacity(0.56)
    static let rule = Color.white.opacity(0.10)

    // Fresh (life just started): warm incandescent amber glow.
    static let freshGlow = Color(red: 1.0, green: 0.737, blue: 0.318)
    static let freshCore = Color(red: 1.0, green: 0.882, blue: 0.612)
    // Aging midpoint: neutral warm-white.
    static let midGlow = Color(red: 0.945, green: 0.831, blue: 0.647)
    // Near end of life: cool dim slate-blue glow.
    static let coolGlow = Color(red: 0.427, green: 0.573, blue: 0.749)
    static let coolCore = Color(red: 0.294, green: 0.373, blue: 0.475)
    // Expired: flat, dark, glowless.
    static let expired = Color(red: 0.290, green: 0.302, blue: 0.322)

    static let warning = Color(red: 0.910, green: 0.510, blue: 0.290)
    static let danger = Color(red: 0.851, green: 0.353, blue: 0.322)

    static let displayFont = Font.system(size: 48, weight: .bold, design: .rounded)
    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)

    /// Interpolates from freshGlow -> midGlow -> coolGlow -> expired based on
    /// percent of life consumed (0 = brand new, 1 = fully expired).
    static func glowColor(percentUsed: Double) -> Color {
        let p = min(1, max(0, percentUsed))
        if p >= 1.0 { return expired }
        if p < 0.5 {
            return lerp(freshGlow, midGlow, p / 0.5)
        } else {
            return lerp(midGlow, coolGlow, (p - 0.5) / 0.5)
        }
    }

    static func coreColor(percentUsed: Double) -> Color {
        let p = min(1, max(0, percentUsed))
        if p >= 1.0 { return expired }
        return lerp(freshCore, coolCore, p)
    }

    /// Glow radius shrinks continuously as life is consumed: bright wide halo
    /// when fresh, down to almost nothing near expiry.
    static func glowRadius(percentUsed: Double) -> CGFloat {
        let p = min(1, max(0, percentUsed))
        return CGFloat(28 * (1 - p) + 2)
    }

    static func glowOpacity(percentUsed: Double) -> Double {
        let p = min(1, max(0, percentUsed))
        return max(0.08, 0.95 * (1 - p))
    }

    private static func lerp(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let t = min(1, max(0, t))
        let ac = UIColor(a).rgba
        let bc = UIColor(b).rgba
        return Color(
            red: ac.r + (bc.r - ac.r) * t,
            green: ac.g + (bc.g - ac.g) * t,
            blue: ac.b + (bc.b - ac.b) * t
        )
    }
}

private extension UIColor {
    var rgba: (r: Double, g: Double, b: Double, a: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

enum Haptics {
    static var enabled: Bool = true

    static func light() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
