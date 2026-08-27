import Combine
import AuthenticationServices
import GoogleSignInSwift
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
    let onDeleteAccount: () async -> Bool
    let requiresAppleTokenRevocationForAccountDeletion: Bool
    let requiresGoogleReauthenticationForAccountDeletion: Bool
    let onDeleteAccountWithAppleReauthentication: (String, String, String) async -> Bool
    let onDeleteAccountWithGoogleReauthentication: () async -> Bool
    let onAppleAccountDeletionVerificationFailure: () -> Void
    let errorMessage: String?
    @State private var isDeleteAccountConfirmationPresented = false
    @State private var isAppleAccountDeletionReauthenticationPresented = false
    @State private var isGoogleAccountDeletionReauthenticationPresented = false
    @State private var isDeletingAccount = false
    @State private var appleDeletionNonce: String?
    @AccessibilityFocusState private var isErrorFocused: Bool

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
                        Label(settingsError, systemImage: "exclamationmark.circle")
                            .foregroundStyle(.red)
                            .accessibilityLabel("Error: \(settingsError)")
                            .accessibilityFocused($isErrorFocused)
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
                    Button("Delete account", role: .destructive) {
                        isDeleteAccountConfirmationPresented = true
                    }
                    .disabled(isDeletingAccount)
                    .accessibilityIdentifier("accountDelete")
                }
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(.red)
                            .accessibilityLabel("Error: \(errorMessage)")
                            .accessibilityFocused($isErrorFocused)
                            .accessibilityIdentifier("authLogoutError")
                    }
                }
            }
            .navigationTitle("Settings")
            .accessibilityIdentifier("settingsPlaceholder")
            .alert("Delete account?", isPresented: $isDeleteAccountConfirmationPresented) {
                Button("Cancel", role: .cancel) {}
                Button("Delete account", role: .destructive) {
                    Task {
                        if requiresAppleTokenRevocationForAccountDeletion {
                            isAppleAccountDeletionReauthenticationPresented = true
                        } else if requiresGoogleReauthenticationForAccountDeletion {
                            isGoogleAccountDeletionReauthenticationPresented = true
                        } else {
                            isDeletingAccount = true
                            _ = await onDeleteAccount()
                            isDeletingAccount = false
                        }
                    }
                }
            } message: {
                Text("This permanently deletes your workouts, custom exercises, settings, and account. This can’t be undone.")
            }
            .sheet(isPresented: $isAppleAccountDeletionReauthenticationPresented) {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Verify with Apple")
                            .font(.title2.bold())
                        Text("For security, verify the same Apple account before permanently deleting your data.")
                            .foregroundStyle(.secondary)
                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.circle")
                                .foregroundStyle(.red)
                                .accessibilityLabel("Error: \(errorMessage)")
                                .accessibilityIdentifier("accountDeleteVerificationError")
                        }
                        appleDeletionButton
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Delete account")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { isAppleAccountDeletionReauthenticationPresented = false }
                        }
                    }
                }
                .interactiveDismissDisabled(isDeletingAccount)
            }
            .sheet(isPresented: $isGoogleAccountDeletionReauthenticationPresented) {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Verify with Google")
                            .font(.title2.bold())
                        Text("For security, verify the same Google account before permanently deleting your data.")
                            .foregroundStyle(.secondary)
                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.circle")
                                .foregroundStyle(.red)
                                .accessibilityLabel("Error: \(errorMessage)")
                                .accessibilityIdentifier("accountDeleteVerificationError")
                        }
                        googleDeletionButton
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Delete account")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { isGoogleAccountDeletionReauthenticationPresented = false }
                        }
                    }
                }
                .interactiveDismissDisabled(isDeletingAccount)
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                if newValue != nil { isErrorFocused = true }
            }
            .onChange(of: errorMessage) { _, newValue in
                if newValue != nil { isErrorFocused = true }
            }
        }
    }

    @ViewBuilder
    private var appleDeletionButton: some View {
#if DEBUG || MVP_DEMO
        if DemoMode.isEnabled || FirebaseBootstrap.isRunningTests() {
            Button("Verify with Apple") {
                Task {
                    isDeletingAccount = true
                    let didDelete = await onDeleteAccountWithAppleReauthentication("ui-test-token", "ui-test-nonce", "ui-test-code")
                    isDeletingAccount = false
                    if didDelete { isAppleAccountDeletionReauthenticationPresented = false }
                }
            }
            .disabled(isDeletingAccount)
            .accessibilityIdentifier("accountDeleteVerifyApple")
        } else {
            nativeAppleDeletionButton
        }
#else
        nativeAppleDeletionButton
#endif
    }

    private var nativeAppleDeletionButton: some View {
        SignInWithAppleButton(.continue) { request in
            appleDeletionNonce = AppleSignInRequest.configure(request)
        } onCompletion: { result in
            Task {
                guard case .success(let authorization) = result else {
                    appleDeletionNonce = nil
                    return
                }
                guard let nonce = appleDeletionNonce,
                      let token = AppleSignInRequest.identityToken(from: authorization),
                      let code = AppleSignInRequest.authorizationCode(from: authorization) else {
                    onAppleAccountDeletionVerificationFailure()
                    appleDeletionNonce = nil
                    return
                }
                isDeletingAccount = true
                let didDelete = await onDeleteAccountWithAppleReauthentication(token, nonce, code)
                isDeletingAccount = false
                if didDelete { isAppleAccountDeletionReauthenticationPresented = false }
                appleDeletionNonce = nil
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(minHeight: 44)
        .disabled(isDeletingAccount)
        .accessibilityIdentifier("accountDeleteVerifyApple")
    }

    @ViewBuilder
    private var googleDeletionButton: some View {
#if DEBUG || MVP_DEMO
        if DemoMode.isEnabled || FirebaseBootstrap.isRunningTests() {
            Button("Verify with Google") {
                Task {
                    isDeletingAccount = true
                    let didDelete = await onDeleteAccountWithGoogleReauthentication()
                    isDeletingAccount = false
                    if didDelete { isGoogleAccountDeletionReauthenticationPresented = false }
                }
            }
            .disabled(isDeletingAccount)
            .accessibilityIdentifier("accountDeleteVerifyGoogle")
        } else {
            nativeGoogleDeletionButton
        }
#else
        nativeGoogleDeletionButton
#endif
    }

    private var nativeGoogleDeletionButton: some View {
        GoogleSignInButton {
            Task {
                isDeletingAccount = true
                let didDelete = await onDeleteAccountWithGoogleReauthentication()
                isDeletingAccount = false
                if didDelete { isGoogleAccountDeletionReauthenticationPresented = false }
            }
        }
        .frame(minHeight: 44)
        .disabled(isDeletingAccount)
        .accessibilityIdentifier("accountDeleteVerifyGoogle")
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
