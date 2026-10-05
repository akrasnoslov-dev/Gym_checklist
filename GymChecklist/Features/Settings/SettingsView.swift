import Combine
import AuthenticationServices
import GoogleSignInSwift
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var settings: UserSettings
    @Published private(set) var measurements: [BodyWeightMeasurement]
    @Published private(set) var errorMessage: String?
    @Published private(set) var bodyWeightDeletionFailed = false

    private let repository: UserSettingsRepository
    private let bodyWeightRepository: BodyWeightRepository
    @Published private(set) var currentDate: LocalDate
    private var observation: UserSettingsObservation?
    private var bodyWeightObservation: BodyWeightObservation?

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
        observation = repository.observeSettings { [weak self] settings in
            self?.settings = settings
            self?.errorMessage = nil
        }
        bodyWeightObservation = resolvedBodyWeightRepository.observeMeasurements { [weak self] measurements in
            self?.measurements = measurements
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
            errorMessage = "Couldn't save appearance. Try again."
        }
    }

    func selectWeightUnit(_ weightUnit: WeightUnit) {
        guard weightUnit != settings.weightUnit else { return }
        do {
            try repository.saveWeightUnit(weightUnit)
        } catch {
            errorMessage = "Couldn't save weight unit. Try again."
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
        guard profile.heightCentimeters.map({ $0.isFinite && $0 > 0 }) ?? true else {
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
        bodyWeightDeletionFailed = false
        try bodyWeightRepository.deleteMeasurement(id: measurement.id) { [weak self] in
            self?.bodyWeightDeletionFailed = true
        }
    }

    func acknowledgeBodyWeightDeletionFailure() { bodyWeightDeletionFailed = false }

    deinit { MainActor.assumeIsolated { observation?.cancel(); bodyWeightObservation?.cancel() } }
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
                            HStack(spacing: GymTheme.spacing12) {
                                Text("Appearance")
                                    .font(.body.weight(.semibold))
                                Spacer()
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
                                .frame(width: 190)
                                .accessibilityIdentifier("settingsAppearance")
                                .accessibilityValue(viewModel.settings.appearance.rawValue)
                            }
                            .padding(GymTheme.spacing16)

                            Divider().overlay(GymTheme.separator)

                            HStack(spacing: GymTheme.spacing12) {
                                Text("Weight unit")
                                    .font(.body.weight(.semibold))
                                Spacer()
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
                                .frame(width: 112)
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
                                Text("Delete account")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
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
                .padding(.horizontal, GymTheme.spacing16)
                .padding(.vertical, GymTheme.spacing20)
            }
            .gymPageBackground()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
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
                    onDelete: viewModel.deleteMeasurement,
                    deleteFailed: viewModel.bodyWeightDeletionFailed,
                    onDeleteFailureAcknowledged: viewModel.acknowledgeBodyWeightDeletionFailure
                )
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
            showsValidationError = true
        }
    }
}
private struct BodyWeightHistorySheet: View {
    let userID: UserID
    let unit: WeightUnit
    let measurements: [BodyWeightMeasurement]
    let onSave: (BodyWeightMeasurement) throws -> Void
    let onDelete: (BodyWeightMeasurement) throws -> Void
    let deleteFailed: Bool
    let onDeleteFailureAcknowledged: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var weightText = ""
    @State private var measurementDate = Date()
    @State private var editingMeasurement: BodyWeightMeasurement?
    @State private var showsValidationError = false
    @State private var showsDeleteError = false

    private var deleteFailureAlertBinding: Binding<Bool> {
        Binding(
            get: { showsDeleteError || deleteFailed },
            set: { isPresented in
                showsDeleteError = isPresented
                if !isPresented { onDeleteFailureAcknowledged() }
            }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Weight (\(unit.rawValue))", text: $weightText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("bodyWeightInput")
                    DatePicker("Date", selection: $measurementDate, displayedComponents: .date)
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
                }

                Section("Recent measurements") {
                    if measurements.isEmpty {
                        Text("No body-weight measurements yet.")
                            .foregroundStyle(GymTheme.textSecondary)
                    }

                    ForEach(measurements) { measurement in
                        Button {
                            editingMeasurement = measurement
                            weightText = unit.displayWeight(fromCanonicalKilograms: measurement.weightInKilograms)
                                .formatted(.number.precision(.fractionLength(0...2)))
                            measurementDate = measurement.localDate.date(in: .autoupdatingCurrent) ?? measurement.measuredAt
                        } label: {
                            HStack(spacing: GymTheme.spacing12) {
                                Text("\(unit.displayWeight(fromCanonicalKilograms: measurement.weightInKilograms).formatted(.number.precision(.fractionLength(0...2)))) \(unit.rawValue)")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(GymTheme.textPrimary)
                                Spacer()
                                Text(measurementDateLabel(measurement) + " · Edit")
                                    .foregroundStyle(GymTheme.accentForeground)
                            }
                            .frame(minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("bodyWeightMeasurement")
                        .swipeActions {
                            Button(role: .destructive) {
                                do {
                                    try onDelete(measurement)
                                    if editingMeasurement?.id == measurement.id {
                                        clearEditor()
                                    }
                                } catch {
                                    showsDeleteError = true
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
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
                Text("Weight must be greater than zero.")
            }
            .alert("Couldn't delete measurement", isPresented: deleteFailureAlertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Try again. Your saved measurement is still available.")
            }
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
        guard let value = Double(weightText.replacingOccurrences(of: ",", with: ".")), value.isFinite, value > 0 else {
            showsValidationError = true
            return
        }
        let now = Date()
        let existing = editingMeasurement
        let measurement = BodyWeightMeasurement(
            id: existing?.id ?? .init(), userID: userID,
            localDate: LocalDate(date: measurementDate),
            weightInKilograms: unit.canonicalKilograms(fromDisplayWeight: value),
            measuredAt: existing?.measuredAt ?? now, updatedAt: now
        )
        do {
            try onSave(measurement)
            clearEditor()
        } catch { showsValidationError = true }
    }

    private func clearEditor() {
        editingMeasurement = nil
        weightText = ""
        measurementDate = Date()
    }
}
