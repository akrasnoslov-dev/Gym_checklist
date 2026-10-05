import SwiftUI
import UIKit

/// Semantic palette and spacing derived from the frozen Phase 8 prototype.
/// Callers use roles so Light/Dark remain adaptive without duplicating values.
enum GymTheme {
    static let surfaceBase = semanticColor(light: rgb(245, 245, 247), dark: .black)
    static let surfaceGrouped = semanticColor(light: .white, dark: rgb(28, 28, 30))
    static let surfaceElevated = semanticColor(light: rgb(247, 247, 249), dark: rgb(44, 44, 46))
    static let textPrimary = semanticColor(light: rgb(23, 23, 26), dark: rgb(244, 244, 246))
    static let textSecondary = semanticColor(light: rgb(109, 109, 115), dark: rgb(166, 166, 171))
    static let separator = semanticColor(light: rgb(216, 216, 220), dark: rgb(69, 69, 73))
    static let borderSubtle = semanticColor(light: rgb(227, 227, 231), dark: rgb(52, 52, 56))
    static let destructive = semanticColor(light: rgb(186, 26, 26), dark: rgb(255, 180, 171))
    static let scrim = semanticColor(
        light: UIColor.black.withAlphaComponent(0.28),
        dark: UIColor.black.withAlphaComponent(0.48)
    )

    // Frozen green/lime/mint accent family.
    static let accentFill = semanticColor(light: rgb(13, 102, 59), dark: rgb(32, 126, 76))
    static let accentForeground = semanticColor(light: rgb(13, 102, 59), dark: rgb(112, 216, 155))
    static let accentSoft = semanticColor(light: rgb(226, 241, 233), dark: rgb(25, 61, 42))

    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let groupRadius: CGFloat = 14

    // Compatibility aliases for existing callers.
    static let accent = accentFill
    static let surface = surfaceGrouped
    static let elevatedSurface = surfaceElevated
    static let mutedText = textSecondary
    static let cardBorder = borderSubtle

    private static func semanticColor(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    private static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> UIColor {
        UIColor(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: 1
        )
    }
}

struct GymCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(GymTheme.spacing16)
            .background(
                GymTheme.surfaceGrouped,
                in: RoundedRectangle(cornerRadius: GymTheme.groupRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: GymTheme.groupRadius, style: .continuous)
                    .stroke(GymTheme.borderSubtle, lineWidth: 1)
            }
    }
}

struct GymSectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(GymTheme.textSecondary)
            .tracking(0.5)
    }
}

struct GymPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, GymTheme.spacing16)
            .background(
                GymTheme.accentFill.opacity(configuration.isPressed ? 0.82 : 1),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
    }
}

struct GymSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(GymTheme.accentForeground)
            .frame(maxWidth: .infinity, minHeight: 46)
            .padding(.horizontal, GymTheme.spacing16)
            .background(
                GymTheme.surfaceGrouped.opacity(configuration.isPressed ? 0.82 : 1),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(GymTheme.borderSubtle, lineWidth: 1)
            }
    }
}

extension View {
    func gymCard() -> some View { modifier(GymCard()) }

    func gymPageBackground() -> some View {
        background(GymTheme.surfaceBase.ignoresSafeArea())
    }
}
