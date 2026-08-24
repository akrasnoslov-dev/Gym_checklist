import Combine
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var settings: UserSettings
    @Published private(set) var errorMessage: String?

    private let repository: UserSettingsRepository
    private var observation: UserSettingsObservation?

    init(repository: UserSettingsRepository) {
        self.repository = repository
        settings = repository.settings
        observation = repository.observeSettings { [weak self] settings in
            self?.settings = settings
            self?.errorMessage = nil
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch settings.appearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    func selectAppearance(_ appearance: Appearance) {
        guard appearance != settings.appearance else { return }
        var updated = settings
        updated.appearance = appearance
        do {
            try repository.save(updated)
        } catch {
            errorMessage = "Couldn’t save appearance. Try again."
        }
    }

    deinit { MainActor.assumeIsolated { observation?.cancel() } }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onLogout: () -> Void
    let errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Picker(
                        "Appearance",
                        selection: Binding(
                            get: { viewModel.settings.appearance },
                            set: viewModel.selectAppearance
                        )
                    ) {
                        ForEach(Appearance.allCases, id: \.self) { appearance in
                            Text(appearance.title)
                                .tag(appearance)
                                .accessibilityIdentifier("settingsAppearance\(appearance.accessibilitySuffix)")
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("settingsAppearance")
                    .accessibilityValue(viewModel.settings.appearance.rawValue)

                    if let settingsError = viewModel.errorMessage {
                        Text(settingsError)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("settingsAppearanceError")
                    }
                }

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

private extension Appearance {
    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var accessibilitySuffix: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}
