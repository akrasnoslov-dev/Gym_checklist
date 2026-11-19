import Combine
import AuthenticationServices
import GoogleSignInSwift
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var settings: UserSettings
    @Published private(set) var measurements: [BodyWeightMeasurement]
    @Published private(set) var errorMessage: String?
    @Published private(set) var persistenceIssue: PersistenceIssue?

    private let repository: UserSettingsRepository
    private let bodyWeightRepository: BodyWeightRepository
    @Published private(set) var currentDate: LocalDate
    private var observation: UserSettingsObservation?
    private var bodyWeightObservation: BodyWeightObservation?
    private var settingsFailureObservation: PersistenceFailureObservation?
    private var bodyWeightFailureObservation: PersistenceFailureObservation?
    private var persistenceIssues = PersistenceIssueQueue()

    init(
        repository: UserSettingsRepository,
        bodyWeightRepository: BodyWeightRepository? = nil,
        currentDate: LocalDate? = nil
    ) {
        self.repository = repository
        self.currentDate = currentDate ?? LocalDate(date: Date(), calendar: .autoupdatingCurrent)
        let resolvedBodyWeightRepository = bodyWeightRepository ?? InMemoryBodyWeightRepository(userID: repository.userID)
        self.bodyWeightRepository = resolvedBodyWeightRepository
        settings = repository.settings
        measurements = resolvedBodyWeightRepository.measurements
        persistenceIssue = nil
        observation = repository.observeSettings { [weak self] settings in
            self?.settings = settings
            self?.errorMessage = nil
        }
        bodyWeightObservation = resolvedBodyWeightRepository.observeMeasurements { [weak self] measurements in
            self?.measurements = measurements
        }
        settingsFailureObservation = repository.observePersistenceFailures { [weak self] failure in
            self?.handleSettingsPersistenceFailure(failure)
        }
        bodyWeightFailureObservation = resolvedBodyWeightRepository.observePersistenceFailures { [weak self] failure in
            self?.handleBodyWeightPersistenceFailure(failure)
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
        var attempted = settings
        attempted.appearance = appearance
        do {
            try repository.saveAppearance(appearance)
        } catch {
            handleSettingsPersistenceFailure(.saveRejected(attempted))
        }
    }

    func selectWeightUnit(_ weightUnit: WeightUnit) {
        guard weightUnit != settings.weightUnit else { return }
        var attempted = settings
        attempted.weightUnit = weightUnit
        do {
            try repository.saveWeightUnit(weightUnit)
        } catch {
            handleSettingsPersistenceFailure(.saveRejected(attempted))
        }
    }

    var currentWeightInKilograms: Double? {
        measurements
            .filter { BodyWeightMeasurement.isOnOrBefore($0, date: currentDate) }
            .sorted { BodyWeightMeasurement.isMoreRecent($0, than: $1) }
            .first?
            .weightInKilograms
    }

    var bmi: Double? { settings.profile.bmi(weightInKilograms: currentWeightInKilograms) }

    /// Called when the app becomes active or receives a significant time
    /// change so local-date BMI applicability never remains stuck yesterday.
    func refreshCurrentDate(_ date: LocalDate? = nil) {
        let refreshed = date ?? LocalDate(date: Date(), calendar: .autoupdatingCurrent)
        guard refreshed != currentDate else { return }
        currentDate = refreshed
    }

    func saveProfile(_ profile: UserProfile) throws {
        guard profile.heightCentimeters.map({
            $0.isFinite && $0 > 0 && $0 <= PersistedValueLimits.maximumHeightCentimeters
        }) ?? true else {
            throw BodyWeightRepositoryError.invalidMeasurement
        }
        var updated = settings
        updated.profile = profile
        try repository.save(updated)
    }

    func saveMeasurement(_ measurement: BodyWeightMeasurement) throws {
        try bodyWeightRepository.save(measurement)
    }

    func deleteMeasurement(_ measurement: BodyWeightMeasurement) throws {
        try bodyWeightRepository.deleteMeasurement(id: measurement.id)
    }

    func retryPersistenceIssue() {
        let action = persistenceIssues.advance()
        persistenceIssue = persistenceIssues.presentedIssue
        action?()
    }

    func dismissPersistenceIssue() {
        _ = persistenceIssues.advance()
        persistenceIssue = persistenceIssues.presentedIssue
    }

    private func handleSettingsPersistenceFailure(_ failure: UserSettingsPersistenceFailure) {
        switch failure {
        case let .saveRejected(attempted):
            presentPersistenceIssue(
                documentKey: "settings",
                title: "Settings weren’t saved",
                message: "The last confirmed settings are shown. Retry to save your changes.",
                retryTitle: "Retry Save"
            ) { [weak self] in
                guard let self else { return }
                do { try self.repository.save(attempted) }
                catch { self.handleSettingsPersistenceFailure(.saveRejected(attempted)) }
            }
        case let .saveUnconfirmedAfterRestart(attempted):
            presentPersistenceIssue(
                documentKey: "settings",
                title: "Offline settings need review",
                message: "Current cloud settings are shown. Save your offline settings again only if you want to replace them.",
                retryTitle: "Save Offline Settings",
                secondaryTitle: "Remind Me Later"
            ) { [weak self] in
                guard let self else { return }
                do { try self.repository.save(attempted) }
                catch { self.handleSettingsPersistenceFailure(.saveRejected(attempted)) }
            }
        }
    }

    private func handleBodyWeightPersistenceFailure(_ failure: BodyWeightPersistenceFailure) {
        switch failure {
        case let .saveRejected(measurement):
            presentPersistenceIssue(
                documentKey: "bodyWeight:\(measurement.id.rawValue)",
                title: "Body weight wasn’t saved",
                message: "Your entry is ready to retry.",
                retryTitle: "Retry Save"
            ) { [weak self] in
                guard let self else { return }
                do { try self.bodyWeightRepository.save(measurement) }
                catch { self.handleBodyWeightPersistenceFailure(.saveRejected(measurement)) }
            }
        case let .deleteRejected(measurement):
            presentPersistenceIssue(
                documentKey: "bodyWeight:\(measurement.id.rawValue)",
                title: "Measurement wasn’t deleted",
                message: "The measurement was restored. Retry to delete it.",
                retryTitle: "Retry Delete"
            ) { [weak self] in
                guard let self else { return }
                guard self.measurements.contains(where: { $0.id == measurement.id }) else { return }
                do {
                    try self.bodyWeightRepository.deleteMeasurement(id: measurement.id)
                } catch {
                    self.handleBodyWeightPersistenceFailure(.deleteRejected(measurement))
                }
            }
        case let .saveUnconfirmedAfterRestart(measurement):
            presentPersistenceIssue(
                documentKey: "bodyWeight:\(measurement.id.rawValue)",
                title: "Offline body weight needs review",
                message: "The cloud value is shown. Save your offline entry again only if you want to replace it.",
                retryTitle: "Save Offline Entry",
                secondaryTitle: "Remind Me Later"
            ) { [weak self] in
                guard let self else { return }
                do { try self.bodyWeightRepository.save(measurement) }
                catch { self.handleBodyWeightPersistenceFailure(.saveRejected(measurement)) }
            }
        case let .deleteUnconfirmedAfterRestart(measurement):
            presentPersistenceIssue(
                documentKey: "bodyWeight:\(measurement.id.rawValue)",
                title: "Measurement deletion needs review",
                message: "The measurement is present in the cloud. Delete it again only if you still want it removed.",
                retryTitle: "Delete Again",
                secondaryTitle: "Remind Me Later"
            ) { [weak self] in
                guard let self else { return }
                guard self.measurements.contains(where: { $0.id == measurement.id }) else { return }
                do {
                    try self.bodyWeightRepository.deleteMeasurement(id: measurement.id)
                } catch {
                    self.handleBodyWeightPersistenceFailure(.deleteRejected(measurement))
                }
            }
        case .historyUnavailable:
            presentPersistenceIssue(
                documentKey: "bodyWeightHistory",
                title: "Body weight history isn’t up to date",
                message: "Saved measurements couldn’t be loaded. Retry to reconnect.",
                retryTitle: "Retry",
                secondaryTitle: "Not Now"
            ) { [weak self] in
                self?.bodyWeightRepository.restartListening()
            }
        }
    }

    private func presentPersistenceIssue(
        documentKey: String,
        title: String,
        message: String,
        retryTitle: String,
        secondaryTitle: String = "Keep Current Version",
        retry: @escaping @MainActor () -> Void
    ) {
        persistenceIssues.enqueue(
            documentKey: documentKey,
            issue: PersistenceIssue(
                title: title,
                message: message,
                retryTitle: retryTitle,
                secondaryTitle: secondaryTitle
            ),
            retry: retry
        )
        persistenceIssue = persistenceIssues.presentedIssue
    }

    deinit {
        MainActor.assumeIsolated {
            observation?.cancel()
            bodyWeightObservation?.cancel()
            settingsFailureObservation?.cancel()
            bodyWeightFailureObservation?.cancel()
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let accountEmail: String?
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
    @State private var isProfileEditorPresented = false
    @State private var isBodyWeightEditorPresented = false
    @AccessibilityFocusState private var isErrorFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: GymTheme.spacing24) {
                    Text("Settings")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(GymTheme.textPrimary)

                    VStack(alignment: .leading, spacing: GymTheme.spacing8) {
                        GymSectionHeader(title: "Health / profile")
                        settingsGroup {
                            settingsNavigationRow(title: "Profile", identifier: "settingsProfile") {
                                isProfileEditorPresented = true
                            }
                            .accessibilityValue(profileSummary)
                            Divider().overlay(GymTheme.separator)
                            settingsNavigationRow(title: "Body weight", identifier: "settingsBodyWeight") {
                                isBodyWeightEditorPresented = true
                            }
                            .accessibilityValue(weightSummary)
                        }
                    }

                    VStack(alignment: .leading, spacing: GymTheme.spacing8) {
                        GymSectionHeader(title: "Preferences")
                        settingsGroup {
                            PreferenceRow(title: "Appearance") {
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
                            }
                            .padding(GymTheme.spacing16)

                            Divider().overlay(GymTheme.separator)

                            PreferenceRow(title: "Weight unit") {
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
                            .padding(GymTheme.spacing16)
                        }

                        if let settingsError = viewModel.errorMessage {
                            Label(settingsError, systemImage: "exclamationmark.circle")
                                .font(.footnote)
                                .foregroundStyle(GymTheme.destructive)
                                .accessibilityLabel("Error: \(settingsError)")
                                .accessibilityFocused($isErrorFocused)
                                .accessibilityIdentifier("settingsAppearanceError")
                        }
                    }

                    VStack(alignment: .leading, spacing: GymTheme.spacing8) {
                        GymSectionHeader(title: "Account")
                        settingsGroup {
                            HStack {
                                Text(accountEmail ?? "Your account")
                                    .foregroundStyle(GymTheme.textPrimary)
                                    .accessibilityIdentifier("settingsAccountSummary")
                                Spacer()
                                Text("Signed in")
                                    .font(.subheadline)
                                    .foregroundStyle(GymTheme.textSecondary)
                            }
                            .padding(GymTheme.spacing16)

                            Divider().overlay(GymTheme.separator)

                            Button(action: onLogout) {
                                HStack {
                                    Text("Log out")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(GymTheme.textSecondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(GymTheme.textPrimary)
                            .padding(.horizontal, GymTheme.spacing16)
                            .accessibilityIdentifier("authLogout")
                        }
                    }

                    VStack(alignment: .leading, spacing: GymTheme.spacing8) {
                        GymSectionHeader(title: "Danger zone")
                        Button {
                            isDeleteAccountConfirmationPresented = true
                        } label: {
                            HStack {
                                Text(isDeletingAccount ? "Deleting account…" : "Delete account")
                                Spacer()
                                if isDeletingAccount {
                                    // GYM-35: the Cloud Function can take a few seconds.
                                    ProgressView()
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .padding(.horizontal, GymTheme.spacing16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(GymTheme.destructive)
                        .background(
                            GymTheme.surfaceGrouped,
                            in: RoundedRectangle(cornerRadius: GymTheme.groupRadius, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: GymTheme.groupRadius, style: .continuous)
                                .stroke(GymTheme.destructive.opacity(0.55), lineWidth: 1)
                        }
                        .disabled(isDeletingAccount)
                        .accessibilityIdentifier("accountDelete")
                    }

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .font(.footnote)
                            .foregroundStyle(GymTheme.destructive)
                            .accessibilityLabel("Error: \(errorMessage)")
                            .accessibilityFocused($isErrorFocused)
                            .accessibilityIdentifier("authLogoutError")
                    }
                }
                .padding(.horizontal, GymTheme.screenEdge)
                .padding(.vertical, GymTheme.spacing20)
            }
            .contentMargins(.bottom, GymTheme.tabBarClearance, for: .scrollContent)
            .gymPageBackground()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .accessibilityIdentifier("settingsScreen")
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
                Text("This permanently deletes your workouts, custom exercises, settings, and account. This can't be undone.")
            }
            .sheet(isPresented: $isProfileEditorPresented) {
                ProfileEditorSheet(
                    profile: viewModel.settings.profile,
                    onSave: viewModel.saveProfile
                )
            }
            .sheet(isPresented: $isBodyWeightEditorPresented) {
                BodyWeightHistorySheet(
                    userID: viewModel.settings.userID,
                    unit: viewModel.settings.weightUnit,
                    measurements: viewModel.measurements,
                    onSave: viewModel.saveMeasurement,
                    onDelete: viewModel.deleteMeasurement
                )
            }
            .sheet(isPresented: $isAppleAccountDeletionReauthenticationPresented) {
                accountDeletionVerificationSheet(
                    provider: "Apple",
                    onCancel: { isAppleAccountDeletionReauthenticationPresented = false }
                ) {
                    appleDeletionButton
                }
            }
            .sheet(isPresented: $isGoogleAccountDeletionReauthenticationPresented) {
                accountDeletionVerificationSheet(
                    provider: "Google",
                    onCancel: { isGoogleAccountDeletionReauthenticationPresented = false }
                ) {
                    googleDeletionButton
                }
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                if newValue != nil { isErrorFocused = true }
            }
            .onChange(of: errorMessage) { _, newValue in
                if newValue != nil { isErrorFocused = true }
            }
        }
    }

    private func settingsGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            GymTheme.surfaceGrouped,
            in: RoundedRectangle(cornerRadius: GymTheme.groupRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: GymTheme.groupRadius, style: .continuous)
                .stroke(GymTheme.borderSubtle, lineWidth: 1)
        }
    }

    private func settingsNavigationRow(
        title: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(GymTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(GymTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, GymTheme.spacing16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    private var profileSummary: String {
        var values: [String] = []
        if let age = viewModel.settings.profile.age(on: LocalDate(date: Date()), calendar: .autoupdatingCurrent) {
            values.append("Age \(age)")
        }
        if let height = viewModel.settings.profile.heightCentimeters {
            values.append("\(height.formatted(.number.precision(.fractionLength(0)))) cm")
        }
        if let bmi = viewModel.bmi {
            values.append("BMI \(bmi.formatted(.number.precision(.fractionLength(1))))")
        }
        return values.isEmpty ? "Add your details" : values.joined(separator: " - ")
    }

    private var weightSummary: String {
        guard let weight = viewModel.currentWeightInKilograms else { return "Log your first measurement" }
        let display = viewModel.settings.weightUnit.displayWeight(fromCanonicalKilograms: weight)
        return "\(display.formatted(.number.precision(.fractionLength(0...2)))) \(viewModel.settings.weightUnit.rawValue) - \(viewModel.measurements.count) saved"
    }

    /// GYM-35: one verification sheet for Apple and Google, with the title shown
    /// once, theme tokens, and a visible progress state while deleting.
    private func accountDeletionVerificationSheet<VerifyButton: View>(
        provider: String,
        onCancel: @escaping () -> Void,
        @ViewBuilder verifyButton: () -> VerifyButton
    ) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: GymTheme.spacing20) {
                Text("For security, verify the same \(provider) account before permanently deleting your data.")
                    .foregroundStyle(GymTheme.textSecondary)
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .foregroundStyle(GymTheme.destructive)
                        .accessibilityLabel("Error: \(errorMessage)")
                        .accessibilityIdentifier("accountDeleteVerificationError")
                }
                verifyButton()
                if isDeletingAccount {
                    accountDeletionProgress
                }
                Spacer()
            }
            .padding(GymTheme.spacing16)
            .navigationTitle("Verify with \(provider)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .disabled(isDeletingAccount)
                }
            }
        }
        .interactiveDismissDisabled(isDeletingAccount)
    }

    private var accountDeletionProgress: some View {
        HStack(spacing: GymTheme.spacing8) {
            ProgressView()
            Text("Deleting your account…")
                .foregroundStyle(GymTheme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("accountDeleteProgress")
    }

    @ViewBuilder
    private var appleDeletionButton: some View {
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

private struct ProfileEditorSheet: View {
    let profile: UserProfile
    let onSave: (UserProfile) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var sex: Sex?
    @State private var dateOfBirth: Date
    @State private var hasDateOfBirth: Bool
    @State private var heightText: String
    @State private var showsValidationError = false
    @State private var showsSaveError = false

    init(profile: UserProfile, onSave: @escaping (UserProfile) throws -> Void) {
        self.profile = profile
        self.onSave = onSave
        _sex = State(initialValue: profile.sex)
        _dateOfBirth = State(initialValue: profile.dateOfBirth?.date(in: .autoupdatingCurrent) ?? Date())
        _hasDateOfBirth = State(initialValue: profile.dateOfBirth != nil)
        _heightText = State(initialValue: profile.heightCentimeters.map { $0.formatted(.number.precision(.fractionLength(0...1))) } ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GymTheme.spacing20) {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Sex")
                            Spacer()
                            Picker("Sex", selection: $sex) {
                                Text("Not set").tag(Sex?.none)
                                ForEach(Sex.allCases, id: \.self) { value in
                                    Text(value.title).tag(Sex?.some(value))
                                }
                            }
                            .labelsHidden()
                            .accessibilityIdentifier("profileSex")
                        }
                        .frame(minHeight: 50)
                        .padding(.horizontal, GymTheme.spacing16)

                        Divider().overlay(GymTheme.separator)

                        Toggle("Date of birth", isOn: $hasDateOfBirth)
                            .tint(GymTheme.accentFill)
                            .frame(minHeight: 50)
                            .padding(.horizontal, GymTheme.spacing16)
                            .accessibilityIdentifier("profileDateOfBirthEnabled")

                        if hasDateOfBirth {
                            Divider().overlay(GymTheme.separator)
                            DatePicker(
                                "Date of birth",
                                selection: $dateOfBirth,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .frame(minHeight: 50)
                            .padding(.horizontal, GymTheme.spacing16)
                            .accessibilityIdentifier("profileDateOfBirth")
                        }

                        Divider().overlay(GymTheme.separator)

                        HStack {
                            Text("Height")
                            Spacer()
                            TextField("cm", text: $heightText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .accessibilityIdentifier("profileHeight")
                            Text("cm")
                                .foregroundStyle(GymTheme.textSecondary)
                        }
                        .frame(minHeight: 50)
                        .padding(.horizontal, GymTheme.spacing16)
                    }
                    .background(
                        GymTheme.surfaceGrouped,
                        in: RoundedRectangle(cornerRadius: GymTheme.groupRadius, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: GymTheme.groupRadius, style: .continuous)
                            .stroke(GymTheme.borderSubtle, lineWidth: 1)
                    }

                    Button("Save", action: saveProfile)
                        .buttonStyle(GymPrimaryButtonStyle())
                        .accessibilityIdentifier("profileSave")

                    Text("Your profile is used to present your details and calculate BMI when a body weight is available. BMI is not medical advice.")
                        .font(.footnote)
                        .foregroundStyle(GymTheme.textSecondary)
                }
                .padding(GymTheme.spacing16)
            }
            .gymPageBackground()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(GymTheme.accentForeground)
                }
            }
            .alert("Check your profile", isPresented: $showsValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Height must be a positive number.")
            }
            .alert("Profile wasn’t saved", isPresented: $showsSaveError) {
                Button("Retry Save", action: saveProfile)
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("Your profile details are still here. Try saving again.")
            }
        }
    }

    private func saveProfile() {
        let height = Double(heightText.replacingOccurrences(of: ",", with: "."))
        guard heightText.isEmpty || (height?.isFinite == true && height! > 0) else {
            showsValidationError = true
            return
        }
        do {
            try onSave(UserProfile(
                sex: sex,
                dateOfBirth: hasDateOfBirth ? LocalDate(date: dateOfBirth) : nil,
                heightCentimeters: height
            ))
            dismiss()
        } catch {
            if let repositoryError = error as? BodyWeightRepositoryError,
               repositoryError == .invalidMeasurement {
                showsValidationError = true
            } else {
                showsSaveError = true
            }
        }
    }
}
private struct BodyWeightHistorySheet: View {
    let userID: UserID
    let unit: WeightUnit
    let measurements: [BodyWeightMeasurement]
    let onSave: (BodyWeightMeasurement) throws -> Void
    let onDelete: (BodyWeightMeasurement) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var weightText = ""
    @State private var measurementDate = Date()
    @State private var editingMeasurement: BodyWeightMeasurement?
    @State private var showsValidationError = false
    @State private var showsSaveError = false
    @State private var showsDeleteError = false
    @State private var pendingDeletion: BodyWeightMeasurement?

    /// Only a synchronous delete error is shown here; provider rejections that
    /// arrive later go through the Settings persistence banner.
    private var deleteFailureAlertBinding: Binding<Bool> { $showsDeleteError }
    private var deletionConfirmationBinding: Binding<Bool> {
        Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } })
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Weight (\(unit.rawValue))", text: $weightText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("bodyWeightInput")
                    // GYM-33: a future date would be hidden from the current
                    // weight and BMI, so it cannot be chosen.
                    DatePicker("Date", selection: $measurementDate, in: ...Date(), displayedComponents: .date)
                        .accessibilityIdentifier("bodyWeightDate")
                }

                Section {
                    Button(editingMeasurement == nil ? "Log body weight" : "Update body weight") {
                        saveMeasurement()
                    }
                    .buttonStyle(GymPrimaryButtonStyle())
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .accessibilityIdentifier("bodyWeightSave")
                    if editingMeasurement != nil {
                        Button("Cancel editing", action: clearEditor)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(GymTheme.accentForeground)
                            .listRowBackground(Color.clear)
                            .accessibilityIdentifier("bodyWeightCancelEdit")
                    }
                }

                Section("Recent measurements") {
                    if measurements.isEmpty {
                        Text("No body-weight measurements yet.")
                            .foregroundStyle(GymTheme.textSecondary)
                    }

                    ForEach(measurements) { measurement in
                        // GYM-33: the whole row is one edit button.
                        Button {
                            beginEditing(measurement)
                        } label: {
                            HStack(spacing: GymTheme.spacing12) {
                                Text(weightLabel(measurement))
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(GymTheme.textPrimary)
                                Spacer(minLength: GymTheme.spacing12)
                                Text(measurementDateLabel(measurement))
                                    .foregroundStyle(GymTheme.textSecondary)
                                Image(systemName: "pencil")
                                    .foregroundStyle(GymTheme.accentForeground)
                                    .accessibilityHidden(true)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            editingMeasurement?.id == measurement.id ? GymTheme.accentForeground.opacity(0.12) : nil
                        )
                        .accessibilityLabel(weightLabel(measurement))
                        .accessibilityValue(measurementDateLabel(measurement))
                        .accessibilityHint("Edit measurement")
                        .accessibilityIdentifier("bodyWeightMeasurement")
                        .swipeActions {
                            Button(role: .destructive) {
                                pendingDeletion = measurement
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .accessibilityIdentifier("bodyWeightDelete")
                            .tint(GymTheme.swipeDestructive)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(GymTheme.surfaceBase)
            .navigationTitle("Body weight")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(GymTheme.accentForeground)
                }
            }
            .alert("Enter a valid weight", isPresented: $showsValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enter a weight above zero and up to \(maximumWeightText) \(unit.rawValue), dated today or earlier.")
            }
            .alert("Delete this measurement?", isPresented: deletionConfirmationBinding, presenting: pendingDeletion) { measurement in
                Button("Delete", role: .destructive) {
                    pendingDeletion = nil
                    delete(measurement)
                }
                .accessibilityIdentifier("bodyWeightConfirmDelete")
                Button("Cancel", role: .cancel) { pendingDeletion = nil }
            } message: { measurement in
                Text("\(weightLabel(measurement)) · \(measurementDateLabel(measurement))")
            }
            .alert("Body weight wasn’t saved", isPresented: $showsSaveError) {
                Button("Retry Save", action: saveMeasurement)
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("Your entry is still here. Try saving again.")
            }
            .alert("Couldn't delete measurement", isPresented: deleteFailureAlertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Try again. Your saved measurement is still available.")
            }
        }
    }

    private func beginEditing(_ measurement: BodyWeightMeasurement) {
        editingMeasurement = measurement
        weightText = DecimalInputText.text(for: unit.displayWeight(fromCanonicalKilograms: measurement.weightInKilograms))
        measurementDate = measurement.localDate.date(in: .autoupdatingCurrent) ?? measurement.measuredAt
    }

    private func weightLabel(_ measurement: BodyWeightMeasurement) -> String {
        let text = DecimalInputText.text(for: unit.displayWeight(fromCanonicalKilograms: measurement.weightInKilograms))
        return "\(text.isEmpty ? "0" : text) \(unit.rawValue)"
    }

    private var maximumWeightText: String {
        DecimalInputText.text(for: unit.displayWeight(fromCanonicalKilograms: PersistedValueLimits.maximumBodyWeightKilograms))
    }

    private func delete(_ measurement: BodyWeightMeasurement) {
        do {
            try onDelete(measurement)
            if editingMeasurement?.id == measurement.id {
                clearEditor()
            }
        } catch {
            showsDeleteError = true
        }
    }

    private func measurementDateLabel(_ measurement: BodyWeightMeasurement) -> String {
        guard let date = measurement.localDate.date(in: .autoupdatingCurrent) else {
            return measurement.localDate.description
        }
        if Calendar.autoupdatingCurrent.isDateInToday(date) {
            return "Today"
        }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }
    private func saveMeasurement() {
        let existing = editingMeasurement
        // GYM-29: an unchanged weight keeps its exact stored value instead of
        // drifting through display rounding.
        let initialText = existing.map {
            DecimalInputText.text(for: unit.displayWeight(fromCanonicalKilograms: $0.weightInKilograms))
        }
        let kilograms: Double?
        if let existing, weightText == initialText {
            kilograms = existing.weightInKilograms
        } else {
            kilograms = DecimalInputText.value(from: weightText).map { unit.canonicalKilograms(fromDisplayWeight: $0) }
        }
        let localDate = LocalDate(date: measurementDate)
        guard let kilograms, PersistedValueLimits.isValidBodyWeight(kilograms),
              localDate <= LocalDate(date: Date()) else {
            showsValidationError = true
            return
        }
        let now = Date()
        let measurement = BodyWeightMeasurement(
            id: existing?.id ?? .init(), userID: userID,
            localDate: localDate,
            weightInKilograms: kilograms,
            measuredAt: existing?.measuredAt ?? now, updatedAt: now
        )
        do {
            try onSave(measurement)
            clearEditor()
        } catch {
            if let repositoryError = error as? BodyWeightRepositoryError,
               repositoryError == .invalidMeasurement {
                showsValidationError = true
            } else {
                showsSaveError = true
            }
        }
    }

    private func clearEditor() {
        editingMeasurement = nil
        weightText = ""
        measurementDate = Date()
    }
}

/// A settings row with a title and a segmented control. At accessibility text
/// sizes the control moves under the title and takes the full width instead of
/// truncating its segments (GYM-32).
private struct PreferenceRow<Control: View>: View {
    let title: String
    @ViewBuilder let control: () -> Control
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: GymTheme.spacing8) {
                Text(title)
                    .font(.body.weight(.semibold))
                control()
            }
        } else {
            HStack(spacing: GymTheme.spacing12) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .layoutPriority(1)
                Spacer(minLength: GymTheme.spacing12)
                control()
                    .fixedSize()
            }
        }
    }
}
