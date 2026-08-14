import SwiftUI

struct SettingsView: View {
    var body: some View {
        Label("Settings", systemImage: "gearshape")
            .font(.title)
            .accessibilityIdentifier("settingsPlaceholder")
    }
}
