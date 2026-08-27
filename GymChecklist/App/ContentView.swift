import Foundation
import SwiftUI
import UIKit

@MainActor
struct ContentView: View {
    @StateObject private var authenticationViewModel: AuthenticationViewModel

    init() {
        _authenticationViewModel = StateObject(
            wrappedValue: AuthenticationViewModel(
                service: AuthenticationServiceFactory.makeDefault(),
                analytics: AnalyticsTrackerFactory.makeDefault()
            )
        )
    }

    var body: some View {
        Group {
            if authenticationViewModel.isResolving {
                ProgressView()
            } else if let user = authenticationViewModel.currentUser {
                AuthenticatedContentView(
                    userID: user.id,
                    onLogout: authenticationViewModel.signOut,
                    onDeleteAccount: authenticationViewModel.deleteAccount,
                    requiresAppleTokenRevocationForAccountDeletion: authenticationViewModel.requiresAppleTokenRevocationForAccountDeletion,
                    requiresGoogleReauthenticationForAccountDeletion: authenticationViewModel.requiresGoogleReauthenticationForAccountDeletion,
                    onDeleteAccountWithAppleReauthentication: authenticationViewModel.deleteAccountWithAppleReauthentication,
                    onDeleteAccountWithGoogleReauthentication: authenticationViewModel.deleteAccountWithGoogleReauthentication,
                    onAppleAccountDeletionVerificationFailure: authenticationViewModel.handleAppleAccountDeletionVerificationFailure,
                    authenticationError: authenticationViewModel.errorMessage
                )
                    .id(user.id.rawValue)
            } else {
                RegistrationView(viewModel: authenticationViewModel)
            }
        }
    }

    fileprivate static func testDate(named environmentKey: String) -> LocalDate? {
        guard let raw = ProcessInfo.processInfo.environment[environmentKey] else { return nil }
        let values = raw.split(separator: "-").compactMap { Int($0) }
        guard values.count == 3, (1...12).contains(values[1]), (1...31).contains(values[2]) else { return nil }
        return LocalDate(year: values[0], month: values[1], day: values[2])
    }

    fileprivate static var testReferenceDate: LocalDate? {
        testDate(named: "UITEST_REFERENCE_DATE")
    }

    fileprivate static var testInitialSelectedDate: LocalDate? {
#if DEBUG
        guard FirebaseBootstrap.isRunningTests() else { return nil }
        return testDate(named: "UITEST_INITIAL_SELECTED_DATE")
#else
        nil
#endif
    }

    fileprivate static func localCurrentDate(calendar: Calendar) -> LocalDate {
        testReferenceDate ?? LocalDate(date: Date(), calendar: calendar)
    }

    fileprivate static func seedTodayWorkoutForUITests(
        in repository: InMemoryWorkoutRepository,
        on date: LocalDate
    ) {
        if ProcessInfo.processInfo.environment["UITEST_SEED_HISTORY_WORKOUT"] == "1" {
            seedHistoryWorkoutForUITests(in: repository, currentDate: date)
            return
        }
        if ProcessInfo.processInfo.environment["UITEST_SEED_COMPLETION_WORKOUT"] == "1" {
            seedCompletionWorkoutForUITests(in: repository, on: date)
            return
        }
        guard ProcessInfo.processInfo.environment["UITEST_SEED_TODAY_WORKOUT"] == "1" else {
            seedRestDayProgramForUITests(in: repository, on: date)
            return
        }
        var workout = repository.createEmptyWorkout(on: date, at: .distantPast).workout
        let longWorkoutSets = (0..<16).map { index in
            let suffix = String(format: "%012d", 301 + index)
            guard let id = UUID(uuidString: "90000000-0000-4000-8000-\(suffix)") else {
                preconditionFailure("Invalid UI-test workout set identifier")
            }
            return WorkoutSet(
                id: WorkoutSetID(rawValue: id),
                order: index,
                reps: 10,
                weight: 20,
                timeSeconds: 0
            )
        }
        workout.exercises = [
            WorkoutExercise(
                id: WorkoutExerciseID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000001")!),
                exerciseID: SystemExerciseCatalog.all[0].id,
                customName: nil,
                order: 0,
                isSkipped: false,
                sets: [
                    WorkoutSet(id: WorkoutSetID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000101")!), order: 0, reps: 8, weight: 60, timeSeconds: 0),
                    WorkoutSet(id: WorkoutSetID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000102")!), order: 1, reps: 10, weight: 65, timeSeconds: 0)
                ]
            ),
            WorkoutExercise(
                id: WorkoutExerciseID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000002")!),
                exerciseID: SystemExerciseCatalog.all[6].id,
                customName: nil,
                order: 1,
                isSkipped: false,
                sets: [WorkoutSet(id: WorkoutSetID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000201")!), order: 0, reps: 12, weight: 0, timeSeconds: 0)]
            ),
            WorkoutExercise(
                id: WorkoutExerciseID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000003")!),
                exerciseID: SystemExerciseCatalog.all[14].id,
                customName: nil,
                order: 2,
                isSkipped: false,
                sets: longWorkoutSets
            )
        ]
        if ProcessInfo.processInfo.environment["UITEST_SEED_COMPLETED_WORKOUT"] == "1" {
            for exerciseIndex in workout.exercises.indices {
                for setIndex in workout.exercises[exerciseIndex].sets.indices {
                    workout.exercises[exerciseIndex].sets[setIndex].complete(at: .distantPast)
                }
            }
        }
        do {
            try repository.save(workout)
        } catch {
            preconditionFailure("Could not seed the UI-test workout: \(error)")
        }
    }

    fileprivate static func seedRestDayProgramForUITests(
        in repository: InMemoryWorkoutRepository,
        on currentDate: LocalDate
    ) {
        guard ProcessInfo.processInfo.environment["UITEST_SEED_REST_DAY_PROGRAM"] == "1" else { return }
        let programDate = LocalDate(year: 2026, month: 8, day: 15)
        precondition(currentDate == LocalDate(year: 2026, month: 8, day: 14), "Rest-day UI test requires its fixed reference date")
        _ = repository.createEmptyWorkout(on: programDate, at: .distantPast)
    }

    fileprivate static func seedCompletionWorkoutForUITests(
        in repository: InMemoryWorkoutRepository,
        on date: LocalDate
    ) {
        var workout = repository.createEmptyWorkout(on: date, at: .distantPast).workout
        workout.exercises = [
            WorkoutExercise(
                id: WorkoutExerciseID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000001")!),
                exerciseID: SystemExerciseCatalog.all[0].id,
                customName: nil,
                order: 0,
                isSkipped: false,
                sets: [WorkoutSet(id: WorkoutSetID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000101")!), order: 0, reps: 8, weight: 60, timeSeconds: 0)]
            ),
            WorkoutExercise(
                id: WorkoutExerciseID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000002")!),
                exerciseID: SystemExerciseCatalog.all[6].id,
                customName: nil,
                order: 1,
                isSkipped: false,
                sets: [WorkoutSet(id: WorkoutSetID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000201")!), order: 0, reps: 12, weight: 0, timeSeconds: 0)]
            )
        ]
        do {
            try repository.save(workout)
        } catch {
            preconditionFailure("Could not seed the UI-test completion workout: \(error)")
        }
    }

    fileprivate static func seedHistoryWorkoutForUITests(
        in repository: InMemoryWorkoutRepository,
        currentDate: LocalDate
    ) {
        precondition(currentDate == LocalDate(year: 2026, month: 8, day: 14), "History UI test requires its fixed reference date")
        let historyDate = LocalDate(year: 2026, month: 8, day: 7)
        var workout = repository.createEmptyWorkout(on: historyDate, at: .distantPast).workout
        var completedSet = WorkoutSet(
            id: WorkoutSetID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000401")!),
            order: 0,
            reps: 8,
            weight: 60,
            timeSeconds: 0
        )
        completedSet.complete(at: .distantPast)
        completedSet.editActual(reps: 7, weight: 65, timeSeconds: 0)
        workout.exercises = [
            WorkoutExercise(
                id: WorkoutExerciseID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000004")!),
                exerciseID: SystemExerciseCatalog.all[0].id,
                customName: nil,
                order: 0,
                isSkipped: false,
                sets: [
                    completedSet,
                    WorkoutSet(
                        id: WorkoutSetID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000402")!),
                        order: 1,
                        reps: 12,
                        weight: 0,
                        timeSeconds: 0
                    )
                ]
            ),
            WorkoutExercise(
                id: WorkoutExerciseID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000005")!),
                exerciseID: SystemExerciseCatalog.all[6].id,
                customName: nil,
                order: 1,
                isSkipped: true,
                sets: [WorkoutSet(
                    id: WorkoutSetID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000403")!),
                    order: 0,
                    reps: 10,
                    weight: 20,
                    timeSeconds: 0
                )]
            )
        ]
        do {
            try repository.save(workout)
        } catch {
            preconditionFailure("Could not seed the UI-test history workout: \(error)")
        }
    }
}

@MainActor
private struct AuthenticatedContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = AppTab.today
    @StateObject private var workoutViewModel: WorkoutViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    private let onLogout: () -> Void
    private let onDeleteAccount: () async -> Bool
    private let requiresAppleTokenRevocationForAccountDeletion: Bool
    private let requiresGoogleReauthenticationForAccountDeletion: Bool
    private let onDeleteAccountWithAppleReauthentication: (String, String, String) async -> Bool
    private let onDeleteAccountWithGoogleReauthentication: () async -> Bool
    private let onAppleAccountDeletionVerificationFailure: () -> Void
    private let authenticationError: String?

    init(
        userID: UserID,
        onLogout: @escaping () -> Void,
        onDeleteAccount: @escaping () async -> Bool,
        requiresAppleTokenRevocationForAccountDeletion: Bool,
        requiresGoogleReauthenticationForAccountDeletion: Bool,
        onDeleteAccountWithAppleReauthentication: @escaping (String, String, String) async -> Bool,
        onDeleteAccountWithGoogleReauthentication: @escaping () async -> Bool,
        onAppleAccountDeletionVerificationFailure: @escaping () -> Void,
        authenticationError: String?
    ) {
        self.onLogout = onLogout
        self.onDeleteAccount = onDeleteAccount
        self.requiresAppleTokenRevocationForAccountDeletion = requiresAppleTokenRevocationForAccountDeletion
        self.requiresGoogleReauthenticationForAccountDeletion = requiresGoogleReauthenticationForAccountDeletion
        self.onDeleteAccountWithAppleReauthentication = onDeleteAccountWithAppleReauthentication
        self.onDeleteAccountWithGoogleReauthentication = onDeleteAccountWithGoogleReauthentication
        self.onAppleAccountDeletionVerificationFailure = onAppleAccountDeletionVerificationFailure
        self.authenticationError = authenticationError
        let calendar = Calendar.autoupdatingCurrent
        let currentDateProvider = { ContentView.localCurrentDate(calendar: calendar) }
        let today = currentDateProvider()
        let initialSelectedDate = ContentView.testInitialSelectedDate ?? today
        let repository: WorkoutRepository
        let customExerciseRepository: CustomExerciseRepository?
        let settingsRepository: UserSettingsRepository?
        if DemoMode.isEnabled || FirebaseBootstrap.isRunningTests() {
            let inMemoryRepository = InMemoryWorkoutRepository(userID: userID)
            if !DemoMode.isEnabled, userID.rawValue == "ui-test-user" {
                ContentView.seedTodayWorkoutForUITests(in: inMemoryRepository, on: today)
            }
            repository = inMemoryRepository
            customExerciseRepository = DemoMode.isEnabled
                ? InMemoryCustomExerciseRepository(userID: userID)
                : nil
            settingsRepository = InMemoryUserSettingsRepository(userID: userID)
        } else {
            repository = FirestoreWorkoutRepository(currentUserID: { userID })
            customExerciseRepository = FirestoreCustomExerciseRepository(currentUserID: { userID })
            settingsRepository = FirestoreUserSettingsRepository(currentUserID: { userID })
        }
#if DEBUG
        if let inMemoryRepository = repository as? InMemoryWorkoutRepository {
            if ProcessInfo.processInfo.environment["UITEST_FAIL_NEXT_TODAY_SAVE"] == "1" {
                inMemoryRepository.armNextSaveFailureForTesting()
            }
            if let rawFailureDelay = ProcessInfo.processInfo.environment["UITEST_FAIL_TODAY_SAVE_AFTER"],
               let failureDelay = Int(rawFailureDelay), failureDelay >= 0 {
                inMemoryRepository.armSaveFailureForTesting(afterSuccessfulSaves: failureDelay)
            }
        }
#endif
        _workoutViewModel = StateObject(wrappedValue: WorkoutViewModel(
            repository: repository,
            initialDate: initialSelectedDate,
            currentDate: today,
            calendar: calendar,
            customExerciseRepository: customExerciseRepository,
            analytics: AnalyticsTrackerFactory.makeDefault(),
            currentDateProvider: currentDateProvider,
        ))
        guard let settingsRepository else {
            preconditionFailure("Authenticated content requires a user settings repository")
        }
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(repository: settingsRepository))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(
                viewModel: workoutViewModel,
                currentDate: workoutViewModel.currentDate,
                calendar: workoutViewModel.calendar,
                weightUnit: settingsViewModel.settings.weightUnit,
                onOpenProgram: openProgramForToday
            )
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle")
                }
                .tag(AppTab.today)

            ProgramView(
                viewModel: workoutViewModel,
                weightUnit: settingsViewModel.settings.weightUnit
            )
                .tabItem {
                    Label("Program", systemImage: "calendar")
                }
                .tag(AppTab.program)

            SettingsView(
                viewModel: settingsViewModel,
                onLogout: onLogout,
                onDeleteAccount: onDeleteAccount,
                requiresAppleTokenRevocationForAccountDeletion: requiresAppleTokenRevocationForAccountDeletion,
                requiresGoogleReauthenticationForAccountDeletion: requiresGoogleReauthenticationForAccountDeletion,
                onDeleteAccountWithAppleReauthentication: onDeleteAccountWithAppleReauthentication,
                onDeleteAccountWithGoogleReauthentication: onDeleteAccountWithGoogleReauthentication,
                onAppleAccountDeletionVerificationFailure: onAppleAccountDeletionVerificationFailure,
                errorMessage: authenticationError
            )
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
            .tag(AppTab.settings)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            workoutViewModel.refreshCurrentDate()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            workoutViewModel.refreshCurrentDate()
        }
        .preferredColorScheme(settingsViewModel.preferredColorScheme)
        .accessibilityIdentifier("authenticatedContent")
        .accessibilityValue(settingsViewModel.settings.appearance.rawValue)
    }

    private func openProgramForToday() {
        workoutViewModel.select(workoutViewModel.currentDate)
        selectedTab = .program
    }
}


private enum AppTab: String {
    case today
    case program
    case settings
}

#Preview {
    ContentView()
}
