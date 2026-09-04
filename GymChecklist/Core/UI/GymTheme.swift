import SwiftUI
import UIKit

/// Small semantic palette shared by the three product surfaces. The lime/mint
/// accent stays restrained: it signals selection, completion, and primary
/// actions while system surfaces continue to adapt to Light and Dark mode.
enum GymTheme {
    /// Dark enough for white text on a primary control in either appearance.
    static let accent = Color(red: 0.05, green: 0.40, blue: 0.23)
    /// Keeps the mint character for icons and selection outlines while using a
    /// contrast-safe green on light surfaces.
    static let accentForeground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.37, green: 0.77, blue: 0.54, alpha: 1)
            : UIColor(red: 0.05, green: 0.40, blue: 0.23, alpha: 1)
    })
    static let accentSoft = accentForeground.opacity(0.16)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevatedSurface = Color(uiColor: .tertiarySystemGroupedBackground)
    static let separator = Color(uiColor: .separator)
    static let destructive = Color.red
    static let mutedText = Color.secondary
    static let cardBorder = Color.primary.opacity(0.08)
}

struct GymCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(GymTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(GymTheme.cardBorder, lineWidth: 1)
            }
    }
}

struct GymSectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(GymTheme.mutedText)
            .tracking(0.5)
    }
}

extension View {
    func gymCard() -> some View { modifier(GymCard()) }
}
