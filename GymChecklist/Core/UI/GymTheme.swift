import SwiftUI

/// Small semantic palette shared by the three product surfaces. The lime/mint
/// accent stays restrained: it signals selection, completion, and primary
/// actions while system surfaces continue to adapt to Light and Dark mode.
enum GymTheme {
    static let accent = Color(red: 0.37, green: 0.77, blue: 0.54)
    static let accentSoft = accent.opacity(0.16)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevatedSurface = Color(uiColor: .tertiarySystemGroupedBackground)
    static let separator = Color(uiColor: .separator)
    static let destructive = Color.red
}

struct GymCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(GymTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

extension View {
    func gymCard() -> some View { modifier(GymCard()) }
}
