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
        do {
            try repository.saveAppearance(appearance)
        } catch {
            errorMessage = "Couldn’t save appearance. Try again."
        }
    }

    func selectWeightUnit(_ weightUnit: WeightUnit) {
        guard weightUnit != settings.weightUnit else { return }
        do {
            try repository.saveWeightUnit(weightUnit)
        } catch {
            errorMessage = "Couldn’t save weight unit. Try again."
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

                Section("Weight unit") {
                    Picker(
                        "Weight unit",
                        selection: Binding(
                            get: { viewModel.settings.weightUnit },
                            set: viewModel.selectWeightUnit
                        )
                    ) {
                        ForEach(WeightUnit.allCases, id: \.self) { weightUnit in
                            Text(weightUnit.title)
                                .tag(weightUnit)
                                .accessibilityIdentifier("settingsWeightUnit\(weightUnit.accessibilitySuffix)")
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("settingsWeightUnit")
                    .accessibilityValue(viewModel.settings.weightUnit.rawValue)
                }

                Section("Account") {
                    Text("Signed in")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("settingsAccountSummary")
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

private extension WeightUnit {
    var title: String { rawValue }

    var accessibilitySuffix: String {
        switch self {
        case .kilograms: "Kg"
        case .pounds: "Lb"
        }
    }
}
