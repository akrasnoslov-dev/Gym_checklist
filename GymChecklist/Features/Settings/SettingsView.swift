import SwiftUI

struct SettingsView: View {
    let onLogout: () -> Void
    let errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Button("Log out", role: .destructive, action: onLogout)
                        .accessibilityIdentifier("authLogout")
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("authLogoutError")
                    }
                }
            }
            .navigationTitle("Settings")
            .accessibilityIdentifier("settingsPlaceholder")
        }
    }
}
