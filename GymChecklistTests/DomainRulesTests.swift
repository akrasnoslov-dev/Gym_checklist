import XCTest
@testable import GymChecklist

final class DomainModelsTests: XCTestCase {
    func testModelsRoundTripWithExplicitOrderAndSkippedState() throws {
        let userID = UserID(rawValue: "user")
        let exerciseID = ExerciseID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        let set = WorkoutSet(id: WorkoutSetID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!), order: 3, reps: 8, weight: 60, timeSeconds: 0)
        let workoutExercise = WorkoutExercise(id: WorkoutExerciseID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!), exerciseID: exerciseID, customName: nil, order: 2, isSkipped: true, sets: [set])
        let workout = Workout(id: WorkoutID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!), userID: userID, localDate: LocalDate(year: 2026, month: 8, day: 14), exercises: [workoutExercise], createdAt: Date(timeIntervalSince1970: 1), updatedAt: Date(timeIntervalSince1970: 2))
        let exercise = Exercise(id: exerciseID, name: "Squat", category: "Legs", isSystem: true, createdByUserID: nil)
        let settings = UserSettings(userID: userID, appearance: .dark, weightUnit: .pounds)

        XCTAssertEqual(try roundTrip(workout), workout)
        XCTAssertEqual(try roundTrip(exercise), exercise)
        XCTAssertEqual(try roundTrip(settings), settings)
        XCTAssertEqual(workout.exercises.first?.order, 2)
        XCTAssertEqual(workout.exercises.first?.sets.first?.order, 3)
        XCTAssertEqual(workout.dateKey, WorkoutDateKey(userID: userID, localDate: workout.localDate))
    }

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))
    }
}

final class FirestoreWorkoutSnapshotAvailabilityTests: XCTestCase {
    func testEmptySuccessfulCachedSnapshotIsUsable() {
        let availability = FirestoreWorkoutSnapshotAvailability.successfulSnapshot(discardedEntryCount: 0)

        XCTAssertTrue(availability.hasUsableSnapshot)
        XCTAssertEqual(availability.loadState, .available)
    }

    func testMalformedEntriesKeepCachedWorkoutUsableButUnavailable() {
        let availability = FirestoreWorkoutSnapshotAvailability.successfulSnapshot(discardedEntryCount: 1)

        XCTAssertTrue(availability.hasUsableSnapshot)
        XCTAssertEqual(availability.loadState, .unavailable(hasUsableSnapshot: true))
    }
}

final class LocalDateTests: XCTestCase {
    func testInstantResolvesAcrossDayBoundaryInTwoTimeZones() {
        let instant = ISO8601DateFormatter().date(from: "2026-08-14T00:30:00Z")!
        XCTAssertEqual(LocalDate(date: instant, calendar: calendar("Europe/Copenhagen")), LocalDate(year: 2026, month: 8, day: 14))
        XCTAssertEqual(LocalDate(date: instant, calendar: calendar("America/Los_Angeles")), LocalDate(year: 2026, month: 8, day: 13))
    }

    func testStoredFridayIsTimezoneIndependentAndNavigatesWeeks() throws {
        let friday = LocalDate(year: 2026, month: 8, day: 14)
        let decoded = try JSONDecoder().decode(LocalDate.self, from: JSONEncoder().encode(friday))
        XCTAssertEqual(decoded, friday)
        XCTAssertEqual(decoded.description, "2026-08-14")
        XCTAssertEqual(friday.adding(weeks: 1, calendar: calendar("Europe/Copenhagen")), LocalDate(year: 2026, month: 8, day: 21))
        XCTAssertEqual(LocalDate(year: 2026, month: 12, day: 28).adding(weeks: 1, calendar: calendar("America/Los_Angeles")), LocalDate(year: 2027, month: 1, day: 4))
    }

    func testInvalidEncodedDateIsRejected() {
        let invalid = Data(#"{"year":2026,"month":2,"day":30}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(LocalDate.self, from: invalid))
    }

    private func calendar(_ identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }
}

final class SetDisplayFormatterTests: XCTestCase {
    func testCompactDisplayRules() {
        XCTAssertEqual(SetDisplayFormatter(unit: .kilograms).string(reps: 8, weightInKilograms: 60, timeSeconds: 0), "8 reps × 60 kg")
        XCTAssertEqual(SetDisplayFormatter(unit: .pounds).string(reps: 8, weightInKilograms: 60, timeSeconds: 0), "8 reps × 132.28 lb")
        XCTAssertEqual(SetDisplayFormatter(unit: .kilograms).string(reps: 12, weightInKilograms: 0, timeSeconds: 0), "12 reps")
        XCTAssertEqual(SetDisplayFormatter(unit: .kilograms).string(reps: 1, weightInKilograms: 0, timeSeconds: 45), "45 sec")
        XCTAssertEqual(SetDisplayFormatter(unit: .kilograms).string(reps: 8, weightInKilograms: 60, timeSeconds: 45), "8 reps × 60 kg × 45 sec")
        XCTAssertFalse(SetDisplayFormatter(unit: .kilograms).string(reps: 12, weightInKilograms: 0, timeSeconds: 0).contains("0 kg"))
    }

    func testWeightUnitsConvertAtTheDisplayBoundaryWithoutChangingCanonicalWeight() {
        let canonicalKilograms = 60.0
        let pounds = WeightUnit.pounds.displayWeight(fromCanonicalKilograms: canonicalKilograms)

        XCTAssertEqual(WeightUnit.kilograms.displayWeight(fromCanonicalKilograms: canonicalKilograms), canonicalKilograms)
        XCTAssertEqual(pounds, 132.277_357_311, accuracy: 0.000_000_001)
        XCTAssertEqual(WeightUnit.pounds.canonicalKilograms(fromDisplayWeight: pounds), canonicalKilograms, accuracy: 0.000_000_001)
        XCTAssertEqual(WeightUnit.pounds.displayWeight(fromCanonicalKilograms: 0), 0)
        XCTAssertEqual(WeightUnit.pounds.canonicalKilograms(fromDisplayWeight: 0), 0)
    }
}

final class WorkoutSetSemanticsTests: XCTestCase {
    func testCompleteEditUndoAndRecompleteTransitions() {
        let firstCompletion = Date(timeIntervalSince1970: 100)
        var set = WorkoutSet(order: 0, reps: 8, weight: 60, timeSeconds: 0)
        set.complete(at: firstCompletion)
        XCTAssertTrue(set.isCompleted)
        XCTAssertEqual(set.actualReps, 8)
        XCTAssertEqual(set.actualWeight, 60)
        XCTAssertEqual(set.actualTimeSeconds, 0)
        XCTAssertEqual(set.completedAt, firstCompletion)

        set.editPlan(reps: 10, weight: 62.5, timeSeconds: 0)
        XCTAssertEqual(set.displayedReps, 8, "Plan edits must not overwrite completed actuals")
        set.editActual(reps: 9, weight: 61, timeSeconds: 0)
        XCTAssertTrue(set.isCompleted)
        XCTAssertEqual(set.displayedReps, 9)
        XCTAssertEqual(set.reps, 10)

        set.undoCompletion()
        XCTAssertFalse(set.isCompleted)
        XCTAssertNil(set.actualReps)
        XCTAssertNil(set.actualWeight)
        XCTAssertNil(set.actualTimeSeconds)
        XCTAssertNil(set.completedAt)
        XCTAssertEqual(set.displayedReps, 10)

        set.complete(at: Date(timeIntervalSince1970: 200))
        XCTAssertEqual(set.actualReps, 10)
        XCTAssertEqual(set.actualWeight, 62.5)
    }

    func testActualEditDoesNothingWhileIncomplete() {
        var set = WorkoutSet(order: 0, reps: 5)
        set.editActual(reps: 9, weight: 10, timeSeconds: 20)
        XCTAssertNil(set.actualReps)
    }

    func testInvalidCompletedEncodingIsRejected() throws {
        let set = WorkoutSet(order: 0, reps: 5)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(set)) as? [String: Any])
        object["isCompleted"] = true
        XCTAssertThrowsError(try JSONDecoder().decode(WorkoutSet.self, from: JSONSerialization.data(withJSONObject: object)))
    }

    func testInvalidIncompleteEncodingWithActualValuesIsRejected() throws {
        var set = WorkoutSet(order: 0, reps: 5)
        set.complete(at: .distantPast)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(set)) as? [String: Any])
        object["isCompleted"] = false
        XCTAssertThrowsError(try JSONDecoder().decode(WorkoutSet.self, from: JSONSerialization.data(withJSONObject: object)))
    }
}

final class WorkoutStatusTests: XCTestCase {
    func testStatusTruthTable() {
        XCTAssertEqual(workout(exercises: []).completionStatus, .planned)
        XCTAssertEqual(workout(exercises: [exercise(completed: [])]).completionStatus, .planned)
        XCTAssertEqual(workout(exercises: [exercise(completed: [false, false])]).completionStatus, .planned)
        XCTAssertEqual(workout(exercises: [exercise(completed: [true, false])]).completionStatus, .partial)
        XCTAssertEqual(workout(exercises: [exercise(completed: [true, true])]).completionStatus, .completed)
        XCTAssertEqual(workout(exercises: [exercise(completed: [false], skipped: true)]).completionStatus, .completed)
        XCTAssertEqual(workout(exercises: [exercise(completed: [false], skipped: true), exercise(completed: [false])]).completionStatus, .planned)
        XCTAssertEqual(workout(exercises: [exercise(completed: [true]), exercise(completed: [])]).completionStatus, .partial)
        XCTAssertEqual(workout(exercises: [exercise(completed: [true]), exercise(completed: [], skipped: true)]).completionStatus, .completed)
    }

    func testPastPlannedWorkoutIsIncomplete() {
        let past = workout(exercises: [exercise(completed: [false])], date: LocalDate(year: 2026, month: 8, day: 13))
        XCTAssertEqual(past.calendarStatus(asOf: LocalDate(year: 2026, month: 8, day: 14)), .incomplete)
    }

    func testWorkoutDatesAreUniquePerUser() throws {
        let first = workout(exercises: [])
        var duplicate = first
        duplicate.id = WorkoutID()
        XCTAssertThrowsError(try WorkoutScheduleRules.validateUniqueDates(in: [first, duplicate]))

        duplicate.userID = UserID(rawValue: "another-user")
        XCTAssertNoThrow(try WorkoutScheduleRules.validateUniqueDates(in: [first, duplicate]))
    }

    private func workout(exercises: [WorkoutExercise], date: LocalDate = LocalDate(year: 2026, month: 8, day: 14)) -> Workout {
        Workout(id: WorkoutID(), userID: UserID(rawValue: "user"), localDate: date, exercises: exercises, createdAt: .distantPast, updatedAt: .distantPast)
    }

    private func exercise(completed: [Bool], skipped: Bool = false) -> WorkoutExercise {
        var sets = completed.enumerated().map { WorkoutSet(order: $0.offset, reps: 8) }
        for index in sets.indices where completed[index] { sets[index].complete(at: .distantPast) }
        return WorkoutExercise(id: WorkoutExerciseID(), exerciseID: ExerciseID(), customName: nil, order: 0, isSkipped: skipped, sets: sets)
    }
}

@MainActor
final class AuthenticationViewModelTests: XCTestCase {
    func testInvalidRegistrationInputDoesNotCallService() async {
        let service = TestAuthenticationService()
        let viewModel = AuthenticationViewModel(service: service)

        let registered = await viewModel.register(
            email: "not-an-email",
            password: "password",
            confirmation: "password"
        )

        XCTAssertFalse(registered)
        XCTAssertEqual(service.registrationCalls, 0)
        XCTAssertEqual(viewModel.errorMessage, "Enter a valid email address.")
    }

    func testPasswordMismatchDoesNotCallService() async {
        let service = TestAuthenticationService()
        let viewModel = AuthenticationViewModel(service: service)

        let registered = await viewModel.register(
            email: "member@example.com",
            password: "password",
            confirmation: "different"
        )

        XCTAssertFalse(registered)
        XCTAssertEqual(service.registrationCalls, 0)
        XCTAssertEqual(viewModel.errorMessage, "Passwords do not match.")
    }

    func testShortPasswordDoesNotCallService() async {
        let service = TestAuthenticationService()
        let viewModel = AuthenticationViewModel(service: service)

        let registered = await viewModel.register(
            email: "member@example.com",
            password: "short",
            confirmation: "short"
        )

        XCTAssertFalse(registered)
        XCTAssertEqual(service.registrationCalls, 0)
        XCTAssertEqual(viewModel.errorMessage, "Use a password with at least 6 characters.")
    }

    func testSuccessfulRegistrationPublishesAuthenticatedUser() async {
        let expectedUser = AuthenticatedUser(id: UserID(rawValue: "new-user"))
        let service = TestAuthenticationService(result: .success(expectedUser))
        let viewModel = AuthenticationViewModel(service: service)

        let registered = await viewModel.register(
            email: "member@example.com",
            password: "password",
            confirmation: "password"
        )

        XCTAssertTrue(registered)
        XCTAssertEqual(service.registrationCalls, 1)
        XCTAssertEqual(viewModel.currentUser, expectedUser)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSubmitting)
    }

    func testRegistrationAndSignInLogOnlySuccessfulTransitions() async {
        let analytics = AnalyticsRecorder()
        let registration = AuthenticationViewModel(service: TestAuthenticationService(), analytics: analytics)
        _ = await registration.register(email: "member@example.com", password: "password", confirmation: "password")
        _ = await registration.signIn(email: "invalid", password: "password")

        let signIn = AuthenticationViewModel(service: TestAuthenticationService(), analytics: analytics)
        _ = await signIn.signIn(email: "member@example.com", password: "password")

        _ = await signIn.signInWithApple(identityToken: "token", rawNonce: "nonce")
        _ = await signIn.signInWithGoogle()

        XCTAssertEqual(analytics.events, [.signUp, .login, .login, .login])
    }

    func testAppleSignInCancellationDoesNotShowErrorOrLogAnalytics() async {
        let analytics = AnalyticsRecorder()
        let service = TestAuthenticationService(appleResult: .failure(.signInCancelled))
        let viewModel = AuthenticationViewModel(service: service, analytics: analytics)

        let signedIn = await viewModel.signInWithApple(identityToken: "token", rawNonce: "nonce")

        XCTAssertFalse(signedIn)
        XCTAssertEqual(service.appleSignInCalls, 1)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(analytics.events.isEmpty)
    }

    func testGoogleSignInCancellationDoesNotShowErrorOrLogAnalytics() async {
        let analytics = AnalyticsRecorder()
        let service = TestAuthenticationService(googleResult: .failure(.signInCancelled))
        let viewModel = AuthenticationViewModel(service: service, analytics: analytics)

        let signedIn = await viewModel.signInWithGoogle()

        XCTAssertFalse(signedIn)
        XCTAssertEqual(service.googleSignInCalls, 1)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(analytics.events.isEmpty)
    }

    func testGoogleSignInFailureUsesNeutralErrorAndDoesNotLogAnalytics() async {
        let analytics = AnalyticsRecorder()
        let service = TestAuthenticationService(googleResult: .failure(.unavailable))
        let viewModel = AuthenticationViewModel(service: service, analytics: analytics)

        let signedIn = await viewModel.signInWithGoogle()

        XCTAssertFalse(signedIn)
        XCTAssertEqual(service.googleSignInCalls, 1)
        XCTAssertEqual(viewModel.errorMessage, "We could not sign you in with Google. Please try again.")
        XCTAssertTrue(analytics.events.isEmpty)
    }

    func testRegistrationFailureUsesSanitizedMessage() async {
        let service = TestAuthenticationService(result: .failure(RegistrationError.emailAlreadyInUse))
        let viewModel = AuthenticationViewModel(service: service)

        let registered = await viewModel.register(
            email: "member@example.com",
            password: "password",
            confirmation: "password"
        )

        XCTAssertFalse(registered)
        XCTAssertEqual(viewModel.errorMessage, "An account already uses this email.")
        XCTAssertFalse(viewModel.isSubmitting)
    }

    func testSignInValidatesInputAndPublishesUser() async {
        let expectedUser = AuthenticatedUser(id: UserID(rawValue: "returning-user"))
        let service = TestAuthenticationService(result: .success(expectedUser))
        let viewModel = AuthenticationViewModel(service: service)

        let invalidEmailResult = await viewModel.signIn(email: "not-an-email", password: "password")
        XCTAssertFalse(invalidEmailResult)
        XCTAssertEqual(service.registrationCalls, 0)
        XCTAssertEqual(viewModel.errorMessage, "Enter a valid email address.")

        let validSignInResult = await viewModel.signIn(email: "member@example.com", password: "password")
        XCTAssertTrue(validSignInResult)
        XCTAssertEqual(viewModel.currentUser, expectedUser)
        XCTAssertFalse(viewModel.isSubmitting)
    }

    func testSignInRejectsEmptyPasswordAndUsesGenericCredentialError() async {
        let service = TestAuthenticationService(result: .failure(.invalidCredentials))
        let viewModel = AuthenticationViewModel(service: service)

        let emptyPasswordResult = await viewModel.signIn(email: "member@example.com", password: "")
        XCTAssertFalse(emptyPasswordResult)
        XCTAssertEqual(service.registrationCalls, 0)
        XCTAssertEqual(viewModel.errorMessage, "Enter your password.")

        let invalidCredentialsResult = await viewModel.signIn(email: "member@example.com", password: "password")
        XCTAssertFalse(invalidCredentialsResult)
        XCTAssertEqual(viewModel.errorMessage, "Email or password is incorrect.")
    }

    func testLogoutPublishesUnauthenticatedState() async {
        let service = TestAuthenticationService(
            result: .success(AuthenticatedUser(id: UserID(rawValue: "member"))),
            notifiesOnSignOut: false
        )
        let viewModel = AuthenticationViewModel(service: service)
        _ = await viewModel.signIn(email: "member@example.com", password: "password")

        viewModel.signOut()

        XCTAssertNil(viewModel.currentUser)
    }

    func testDelayedAuthenticationResolutionKeepsContentUnavailableUntilUserArrives() {
        let service = TestAuthenticationService(deliversInitialObservation: false)
        let viewModel = AuthenticationViewModel(service: service)

        XCTAssertTrue(viewModel.isResolving)
        XCTAssertNil(viewModel.currentUser)

        let user = AuthenticatedUser(id: UserID(rawValue: "resolved-user"))
        service.emitAuthentication(user)

        XCTAssertFalse(viewModel.isResolving)
        XCTAssertEqual(viewModel.currentUser, user)
    }

    func testSessionChangeClearsTransientAuthFeedback() async {
        let service = TestAuthenticationService()
        let viewModel = AuthenticationViewModel(service: service)

        _ = await viewModel.sendPasswordReset(email: "member@example.com")
        _ = await viewModel.signIn(email: "invalid", password: "password")
        XCTAssertNotNil(viewModel.passwordResetMessage)
        XCTAssertNotNil(viewModel.errorMessage)

        service.emitAuthentication(AuthenticatedUser(id: UserID(rawValue: "different-user")))

        XCTAssertNil(viewModel.passwordResetMessage)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testPasswordResetValidatesAndKeepsSessionUnchanged() async {
        let service = TestAuthenticationService()
        let viewModel = AuthenticationViewModel(service: service)
        let invalidResetResult = await viewModel.sendPasswordReset(email: "bad")
        XCTAssertFalse(invalidResetResult)
        XCTAssertEqual(service.resetCalls, 0)
        let validResetResult = await viewModel.sendPasswordReset(email: " member@example.com ")
        XCTAssertTrue(validResetResult)
        XCTAssertEqual(service.resetCalls, 1)
        XCTAssertNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.passwordResetMessage, "If an account matches this email, we’ll send reset instructions.")
    }

    func testAccountDeletionClearsTheSessionOnlyAfterSuccess() async {
        let user = AuthenticatedUser(id: UserID(rawValue: "member"))
        let service = TestAuthenticationService(deleteAccountResult: .success(()))
        let viewModel = AuthenticationViewModel(service: service)
        service.emitAuthentication(user)

        let deleted = await viewModel.deleteAccount()

        XCTAssertTrue(deleted)
        XCTAssertEqual(service.deleteAccountCalls, 1)
        XCTAssertNil(viewModel.currentUser)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testAccountDeletionFailureKeepsTheSessionAndShowsNeutralError() async {
        let user = AuthenticatedUser(id: UserID(rawValue: "member"))
        let service = TestAuthenticationService(deleteAccountResult: .failure(.unavailable))
        let viewModel = AuthenticationViewModel(service: service)
        service.emitAuthentication(user)

        let deleted = await viewModel.deleteAccount()

        XCTAssertFalse(deleted)
        XCTAssertEqual(service.deleteAccountCalls, 1)
        XCTAssertEqual(viewModel.currentUser, user)
        XCTAssertEqual(viewModel.errorMessage, "Couldn’t delete your account. You’re still signed in. Try again.")
    }

    func testAccountDeletionRequiresRecentAuthenticationAndKeepsTheSession() async {
        let user = AuthenticatedUser(id: UserID(rawValue: "member"))
        let service = TestAuthenticationService(deleteAccountResult: .failure(.requiresRecentAuthentication))
        let viewModel = AuthenticationViewModel(service: service)
        service.emitAuthentication(user)

        let deleted = await viewModel.deleteAccount()

        XCTAssertFalse(deleted)
        XCTAssertEqual(service.deleteAccountCalls, 1)
        XCTAssertEqual(viewModel.currentUser, user)
        XCTAssertEqual(viewModel.errorMessage, "For security, sign in again and then retry account deletion.")
    }

    func testAppleAccountDeletionUsesReauthenticationPathBeforeClearingTheSession() async {
        let user = AuthenticatedUser(id: UserID(rawValue: "member"))
        let service = TestAuthenticationService(requiresAppleTokenRevocation: true)
        let viewModel = AuthenticationViewModel(service: service)
        service.emitAuthentication(user)

        let deleted = await viewModel.deleteAccountWithAppleReauthentication(
            identityToken: "fresh-token",
            rawNonce: "fresh-nonce",
            authorizationCode: "fresh-code"
        )

        XCTAssertTrue(deleted)
        XCTAssertEqual(service.appleAccountDeletionCalls, 1)
        XCTAssertEqual(service.deleteAccountCalls, 1)
        XCTAssertNil(viewModel.currentUser)
    }

    func testGoogleAccountDeletionUsesReauthenticationPathBeforeClearingTheSession() async {
        let user = AuthenticatedUser(id: UserID(rawValue: "member"))
        let service = TestAuthenticationService(requiresGoogleReauthentication: true)
        let viewModel = AuthenticationViewModel(service: service)
        service.emitAuthentication(user)

        let deleted = await viewModel.deleteAccountWithGoogleReauthentication()

        XCTAssertTrue(deleted)
        XCTAssertTrue(viewModel.requiresGoogleReauthenticationForAccountDeletion)
        XCTAssertEqual(service.googleAccountDeletionCalls, 1)
        XCTAssertEqual(service.deleteAccountCalls, 1)
        XCTAssertNil(viewModel.currentUser)
    }
}

@MainActor
private final class TestAuthenticationService: AuthenticationService {
    @MainActor
    private final class Observation: AuthenticationObservation {
        private var handler: (() -> Void)?
        init(_ handler: @escaping () -> Void) { self.handler = handler }
        func cancel() { handler?(); handler = nil }
    }

    private let result: Result<AuthenticatedUser, RegistrationError>
    private let deliversInitialObservation: Bool
    private let notifiesOnSignOut: Bool
    private let appleResult: Result<AuthenticatedUser, RegistrationError>?
    private let googleResult: Result<AuthenticatedUser, RegistrationError>?
    private let deleteAccountResult: Result<Void, AccountDeletionError>
    private let requiresAppleTokenRevocation: Bool
    private let requiresGoogleReauthentication: Bool
    private var observers: [UUID: @MainActor (AuthenticatedUser?) -> Void] = [:]
    private(set) var currentUser: AuthenticatedUser?
    private(set) var registrationCalls = 0
    private(set) var resetCalls = 0
    private(set) var appleSignInCalls = 0
    private(set) var googleSignInCalls = 0
    private(set) var deleteAccountCalls = 0
    private(set) var appleAccountDeletionCalls = 0
    private(set) var googleAccountDeletionCalls = 0

    init(
        result: Result<AuthenticatedUser, RegistrationError> = .success(AuthenticatedUser(id: UserID(rawValue: "test-user"))),
        deliversInitialObservation: Bool = true,
        notifiesOnSignOut: Bool = true,
        appleResult: Result<AuthenticatedUser, RegistrationError>? = nil,
        googleResult: Result<AuthenticatedUser, RegistrationError>? = nil,
        deleteAccountResult: Result<Void, AccountDeletionError> = .success(()),
        requiresAppleTokenRevocation: Bool = false,
        requiresGoogleReauthentication: Bool = false
    ) {
        self.result = result
        self.deliversInitialObservation = deliversInitialObservation
        self.notifiesOnSignOut = notifiesOnSignOut
        self.appleResult = appleResult
        self.googleResult = googleResult
        self.deleteAccountResult = deleteAccountResult
        self.requiresAppleTokenRevocation = requiresAppleTokenRevocation
        self.requiresGoogleReauthentication = requiresGoogleReauthentication
    }

    func observeAuthentication(_ observer: @escaping @MainActor (AuthenticatedUser?) -> Void) -> AuthenticationObservation {
        let id = UUID()
        observers[id] = observer
        if deliversInitialObservation {
            observer(currentUser)
        }
        return Observation { [weak self] in self?.observers.removeValue(forKey: id) }
    }

    var requiresAppleTokenRevocationForAccountDeletion: Bool {
        requiresAppleTokenRevocation
    }

    var requiresGoogleReauthenticationForAccountDeletion: Bool {
        requiresGoogleReauthentication
    }

    func emitAuthentication(_ user: AuthenticatedUser?) {
        currentUser = user
        observers.values.forEach { $0(user) }
    }

    func register(email: String, password: String) async throws -> AuthenticatedUser {
        registrationCalls += 1
        let user = try result.get()
        currentUser = user
        observers.values.forEach { $0(user) }
        return user
    }

    func signIn(email: String, password: String) async throws -> AuthenticatedUser {
        try await register(email: email, password: password)
    }

    func signInWithApple(identityToken: String, rawNonce: String) async throws -> AuthenticatedUser {
        appleSignInCalls += 1
        let user = try (appleResult ?? result).get()
        currentUser = user
        observers.values.forEach { $0(user) }
        return user
    }

    func signInWithGoogle() async throws -> AuthenticatedUser {
        googleSignInCalls += 1
        let user = try (googleResult ?? result).get()
        currentUser = user
        observers.values.forEach { $0(user) }
        return user
    }

    func deleteAccount() async throws {
        deleteAccountCalls += 1
        try deleteAccountResult.get()
        currentUser = nil
        observers.values.forEach { $0(nil) }
    }

    func deleteAccountWithAppleReauthentication(
        identityToken: String,
        rawNonce: String,
        authorizationCode: String
    ) async throws {
        appleAccountDeletionCalls += 1
        guard !identityToken.isEmpty, !rawNonce.isEmpty, !authorizationCode.isEmpty else {
            throw AccountDeletionError.unavailable
        }
        try await deleteAccount()
    }

    func deleteAccountWithGoogleReauthentication() async throws {
        googleAccountDeletionCalls += 1
        guard requiresGoogleReauthentication else { throw AccountDeletionError.unavailable }
        try await deleteAccount()
    }

    func signOut() throws {
        currentUser = nil
        if notifiesOnSignOut {
            observers.values.forEach { $0(nil) }
        }
    }

    func sendPasswordReset(email: String) async throws { resetCalls += 1 }
}

private final class AnalyticsRecorder: AnalyticsTracking {
    private(set) var events: [AnalyticsEvent] = []
    func log(_ event: AnalyticsEvent) { events.append(event) }
}

final class TodayContentStateTests: XCTestCase {
    func testResolveDistinguishesNoProgramRestDayAndCurrentWorkout() {
        let currentDate = LocalDate(year: 2026, month: 8, day: 14)
        let otherDateWorkout = Workout(
            id: WorkoutID(),
            userID: UserID(rawValue: "user"),
            localDate: LocalDate(year: 2026, month: 8, day: 15),
            exercises: [],
            createdAt: .distantPast,
            updatedAt: .distantPast
        )
        let currentDateWorkout = Workout(
            id: WorkoutID(),
            userID: UserID(rawValue: "user"),
            localDate: currentDate,
            exercises: [WorkoutExercise(
                id: WorkoutExerciseID(),
                exerciseID: ExerciseID(),
                customName: nil,
                order: 0,
                isSkipped: true,
                sets: [WorkoutSet(order: 0, reps: 8)]
            )],
            createdAt: .distantPast,
            updatedAt: .distantPast
        )

        XCTAssertEqual(TodayContentState.resolve(workouts: [], currentDate: currentDate), .noProgram)
        XCTAssertEqual(TodayContentState.resolve(workouts: [otherDateWorkout], currentDate: currentDate), .restDay)
        XCTAssertEqual(
            TodayContentState.resolve(workouts: [otherDateWorkout, currentDateWorkout], currentDate: currentDate),
            .activeWorkout
        )
        XCTAssertEqual(
            TodayContentState.resolve(workouts: [], currentDate: currentDate, loadState: .loading),
            .loading
        )
        XCTAssertEqual(
            TodayContentState.resolve(
                workouts: [],
                currentDate: currentDate,
                loadState: .unavailable(hasUsableSnapshot: false)
            ),
            .unavailable
        )
        XCTAssertEqual(
            TodayContentState.resolve(
                workouts: [otherDateWorkout],
                currentDate: currentDate,
                loadState: .unavailable(hasUsableSnapshot: true)
            ),
            .restDay
        )
    }
}

final class WorkoutCompletionTriggerTests: XCTestCase {
    func testPresentsOnlyForTransitionsIntoCompletedState() {
        XCTAssertTrue(WorkoutCompletionTrigger.shouldPresent(before: .partial, after: .completed))
        XCTAssertTrue(WorkoutCompletionTrigger.shouldPresent(before: .planned, after: .completed))
        XCTAssertTrue(WorkoutCompletionTrigger.shouldPresent(before: .incomplete, after: .completed))
        XCTAssertFalse(WorkoutCompletionTrigger.shouldPresent(before: .completed, after: .completed))
        XCTAssertFalse(WorkoutCompletionTrigger.shouldPresent(before: .completed, after: .partial))
        XCTAssertFalse(WorkoutCompletionTrigger.shouldPresent(before: .partial, after: .partial))
    }
}

final class FirebaseBootstrapTests: XCTestCase {
    func testTestProcessDetectionAllowsConfigFreeXCTestLaunches() {
        XCTAssertTrue(FirebaseBootstrap.isRunningTests(environment: ["XCTestConfigurationFilePath": "/tmp/test.xctest"]))
        XCTAssertTrue(FirebaseBootstrap.isRunningTests(environment: ["UITESTING": "1"]))
        XCTAssertFalse(FirebaseBootstrap.isRunningTests(environment: [:]))
    }

    func testOnlyConfiguredOrTestProcessesComposeFirebaseServices() {
        XCTAssertTrue(GymChecklistApp.canComposeFirebaseServices(status: .configured, isRunningTests: false))
        XCTAssertTrue(GymChecklistApp.canComposeFirebaseServices(status: .missingConfiguration, isRunningTests: true))
        XCTAssertFalse(GymChecklistApp.canComposeFirebaseServices(status: .missingConfiguration, isRunningTests: false))
        XCTAssertFalse(GymChecklistApp.canComposeFirebaseServices(status: .invalidConfiguration, isRunningTests: false))
    }
}

final class FirestoreMappingTests: XCTestCase {
    private let userID = UserID(rawValue: "user-a")
    private let date = LocalDate(year: 2028, month: 2, day: 29)

    func testWorkoutMappingsPreserveCanonicalDateOrderingAndActualValues() throws {
        let workoutID = WorkoutID(rawValue: UUID(uuidString: "10000000-0000-4000-8000-000000000001")!)
        let exerciseID = WorkoutExerciseID(rawValue: UUID(uuidString: "10000000-0000-4000-8000-000000000002")!)
        let domainExerciseID = ExerciseID(rawValue: UUID(uuidString: "10000000-0000-4000-8000-000000000003")!)
        let setID = WorkoutSetID(rawValue: UUID(uuidString: "10000000-0000-4000-8000-000000000004")!)
        var set = WorkoutSet(id: setID, order: 9, reps: 8, weight: 60, timeSeconds: 0)
        set.complete(at: Date(timeIntervalSince1970: 123))
        set.editActual(reps: 7, weight: 61, timeSeconds: 5)
        let exercise = WorkoutExercise(id: exerciseID, exerciseID: domainExerciseID, customName: nil, order: 7, isSkipped: true, sets: [set])
        let workout = Workout(id: workoutID, userID: userID, localDate: date, exercises: [exercise], createdAt: .distantPast, updatedAt: Date(timeIntervalSince1970: 456))

        let decodedSet = try FirestoreWorkoutSetDocument(set: set).workoutSet()
        let decodedExercise = try FirestoreWorkoutExerciseDocument(exercise: exercise).workoutExercise(sets: [decodedSet])
        let decodedWorkout = try FirestoreWorkoutDocument(workout: workout).workout(userID: userID, documentDate: date, exercises: [decodedExercise])

        XCTAssertEqual(decodedWorkout, workout)
        XCTAssertEqual(decodedWorkout.exercises[0].order, 7)
        XCTAssertEqual(decodedWorkout.exercises[0].sets[0].order, 9)
        XCTAssertEqual(FirestoreDocumentPath.workout(userID: userID, date: date), "users/user-a/workouts/2028-02-29")
    }

    func testMappingsRejectMalformedDateAndIncompleteCompletionState() {
        let invalidDate = FirestoreWorkoutDocument(id: UUID().uuidString, localDate: "2028-02-30", createdAt: .distantPast, updatedAt: .distantPast)
        XCTAssertThrowsError(try invalidDate.workout(userID: userID, documentDate: date, exercises: []))

        let missingActual = FirestoreWorkoutSetDocument(id: UUID().uuidString, order: 0, reps: 8, weight: 60, timeSeconds: 0, isCompleted: true, actualReps: nil, actualWeight: 60, actualTimeSeconds: 0, completedAt: .distantPast)
        XCTAssertThrowsError(try missingActual.workoutSet())

        let negativeWeight = FirestoreWorkoutSetDocument(id: UUID().uuidString, order: 0, reps: 8, weight: -1, timeSeconds: 0, isCompleted: false, actualReps: nil, actualWeight: nil, actualTimeSeconds: nil, completedAt: nil)
        XCTAssertThrowsError(try negativeWeight.workoutSet())
    }

    func testSnapshotDecoderKeepsValidWorkoutsWhenOneEntryIsMalformed() {
        let validDate = LocalDate(year: 2028, month: 2, day: 29)
        let validWorkout = Workout(
            id: WorkoutID(),
            userID: userID,
            localDate: validDate,
            exercises: [],
            createdAt: .distantPast,
            updatedAt: .distantPast
        )

        let decoded = FirestoreWorkoutSnapshotDecoder.decode([
            FirestoreWorkoutSnapshotEntry(documentDate: nil, payload: nil),
            FirestoreWorkoutSnapshotEntry(
                documentDate: validDate,
                payload: FirestoreWorkoutPayload(workout: validWorkout)
            )
        ], userID: userID)

        XCTAssertEqual(decoded.workouts, [validWorkout])
        XCTAssertEqual(decoded.discardedEntryCount, 1)
    }

    func testSnapshotDecoderPreservesCachedWorkoutForMalformedDocumentOnTheSameDate() {
        let cachedDate = LocalDate(year: 2026, month: 8, day: 14)
        let validDate = LocalDate(year: 2026, month: 8, day: 15)
        let cachedWorkout = Workout(
            id: WorkoutID(),
            userID: userID,
            localDate: cachedDate,
            exercises: [],
            createdAt: .distantPast,
            updatedAt: .distantPast
        )
        let validWorkout = Workout(
            id: WorkoutID(),
            userID: userID,
            localDate: validDate,
            exercises: [],
            createdAt: .distantPast,
            updatedAt: .distantPast
        )

        let decoded = FirestoreWorkoutSnapshotDecoder.decode([
            FirestoreWorkoutSnapshotEntry(documentDate: cachedDate, payload: nil),
            FirestoreWorkoutSnapshotEntry(
                documentDate: validDate,
                payload: FirestoreWorkoutPayload(workout: validWorkout)
            )
        ], userID: userID)

        XCTAssertEqual(decoded.discardedDocumentDates, [cachedDate])
        XCTAssertEqual(
            decoded.workoutsPreservingCachedEntries([cachedWorkout]),
            [cachedWorkout, validWorkout]
        )
    }

    func testCustomExerciseAndSettingsMappingsStayUserScoped() throws {
        let exercise = Exercise(id: ExerciseID(), name: "Cable Press", category: "Chest", isSystem: false, createdByUserID: userID)
        XCTAssertEqual(try FirestoreCustomExerciseDocument(exercise: exercise).exercise(userID: userID), exercise)
        XCTAssertThrowsError(try FirestoreCustomExerciseDocument(exercise: SystemExerciseCatalog.all[0]))
        XCTAssertEqual(
            FirestoreDocumentPath.customExercise(userID: userID, exerciseID: exercise.id),
            "users/user-a/customExercises/\(exercise.id.rawValue.uuidString)"
        )

        for appearance in Appearance.allCases {
            let settings = UserSettings(userID: userID, appearance: appearance, weightUnit: .pounds)
            XCTAssertEqual(FirestoreUserSettingsDocument(settings: settings).settings(userID: userID), settings)
        }
        let legacySettings = try JSONDecoder().decode(
            FirestoreUserSettingsDocument.self,
            from: Data(#"{"weightUnit":"lb"}"#.utf8)
        )
        XCTAssertEqual(legacySettings.settings(userID: userID), UserSettings(userID: userID, appearance: .system, weightUnit: .pounds))
        XCTAssertEqual(FirestoreDocumentPath.settings(userID: userID), "users/user-a/settings/default")
    }
}

@MainActor
final class UserDataRepositoryTests: XCTestCase {
    func testWorkoutRepositoryPublishesItsLocalSnapshotAfterMutation() {
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "owner"))
        let recorder = SnapshotRecorder()
        let observation = repository.observeWorkouts { workouts, state in
            recorder.snapshots.append(workouts)
            XCTAssertEqual(state, .available)
        }

        _ = repository.createEmptyWorkout(on: LocalDate(year: 2026, month: 8, day: 14), at: .distantPast)

        XCTAssertEqual(recorder.snapshots.count, 2)
        XCTAssertTrue(recorder.snapshots[0].isEmpty)
        XCTAssertEqual(recorder.snapshots[1].count, 1)
        observation.cancel()
        _ = repository.createEmptyWorkout(on: LocalDate(year: 2026, month: 8, day: 15), at: .distantPast)
        XCTAssertEqual(recorder.snapshots.count, 2)
    }

    func testInMemoryCustomExercisesAndSettingsRejectAnotherOwner() throws {
        let owner = UserID(rawValue: "owner")
        let other = UserID(rawValue: "other")
        let exercises = InMemoryCustomExerciseRepository(userID: owner)
        let custom = Exercise(id: ExerciseID(), name: "Sled Push", category: nil, isSystem: false, createdByUserID: owner)
        try exercises.save(custom)
        XCTAssertEqual(exercises.customExercises, [custom])
        XCTAssertThrowsError(try exercises.save(Exercise(id: ExerciseID(), name: "Other", category: nil, isSystem: false, createdByUserID: other)))
        let systemExercise = Exercise(id: ExerciseID(), name: "System", category: nil, isSystem: true, createdByUserID: owner)
        XCTAssertThrowsError(try exercises.save(systemExercise)) { error in
            XCTAssertEqual(error as? CustomExerciseRepositoryError, .systemExerciseCannotBePersisted)
        }

        let settings = InMemoryUserSettingsRepository(userID: owner)
        try settings.save(UserSettings(userID: owner, appearance: .light, weightUnit: .kilograms))
        XCTAssertThrowsError(try settings.save(UserSettings(userID: other)))
    }

    func testInMemoryCustomExerciseRepositoryPublishesCachedSnapshotsAndCancels() throws {
        let owner = UserID(rawValue: "owner")
        let repository = InMemoryCustomExerciseRepository(userID: owner)
        let recorder = CustomExerciseSnapshotRecorder()
        let observation = repository.observeCustomExercises { recorder.snapshots.append($0) }
        let custom = Exercise(id: ExerciseID(), name: "Sled Push", category: nil, isSystem: false, createdByUserID: owner)

        try repository.save(custom)
        XCTAssertEqual(recorder.snapshots, [[], [custom]])

        observation.cancel()
        try repository.deleteCustomExercise(id: custom.id)
        XCTAssertEqual(recorder.snapshots, [[], [custom]])
    }

    func testInMemorySettingsUseDefaultsPublishOptimisticallyAndCancel() throws {
        let owner = UserID(rawValue: "owner")
        let repository = InMemoryUserSettingsRepository(userID: owner)
        let recorder = SettingsSnapshotRecorder()
        let observation = repository.observeSettings { recorder.snapshots.append($0) }
        let updated = UserSettings(userID: owner, appearance: .dark, weightUnit: .pounds)

        XCTAssertEqual(repository.settings, UserSettings(userID: owner))
        try repository.save(updated)
        XCTAssertEqual(recorder.snapshots, [UserSettings(userID: owner), updated])

        observation.cancel()
        try repository.save(UserSettings(userID: owner, appearance: .light, weightUnit: .kilograms))
        XCTAssertEqual(recorder.snapshots, [UserSettings(userID: owner), updated])
    }

    func testSettingsViewModelAppliesAllAppearanceChoicesAndObservedUpdates() throws {
        let owner = UserID(rawValue: "owner")
        let repository = InMemoryUserSettingsRepository(
            userID: owner,
            settings: UserSettings(userID: owner, appearance: .system, weightUnit: .pounds)
        )
        let viewModel = SettingsViewModel(repository: repository)

        XCTAssertNil(viewModel.preferredColorScheme)
        for appearance in Appearance.allCases {
            viewModel.selectAppearance(appearance)
            XCTAssertEqual(repository.settings.appearance, appearance)
            XCTAssertEqual(viewModel.settings.appearance, appearance)
            XCTAssertEqual(viewModel.settings.weightUnit, .pounds)
        }
        XCTAssertEqual(viewModel.preferredColorScheme, .dark)

        try repository.save(UserSettings(userID: owner, appearance: .light, weightUnit: .kilograms))
        XCTAssertEqual(viewModel.settings.appearance, .light)
        XCTAssertEqual(viewModel.settings.weightUnit, .kilograms)
        XCTAssertEqual(viewModel.preferredColorScheme, .light)
    }

    func testSettingsViewModelPersistsWeightUnitWithoutChangingAppearance() throws {
        let owner = UserID(rawValue: "owner")
        let repository = InMemoryUserSettingsRepository(
            userID: owner,
            settings: UserSettings(userID: owner, appearance: .dark, weightUnit: .kilograms)
        )
        let viewModel = SettingsViewModel(repository: repository)

        viewModel.selectWeightUnit(.pounds)

        XCTAssertEqual(repository.settings, UserSettings(userID: owner, appearance: .dark, weightUnit: .pounds))
        XCTAssertEqual(viewModel.settings, repository.settings)
        try repository.saveAppearance(.light)
        XCTAssertEqual(viewModel.settings, UserSettings(userID: owner, appearance: .light, weightUnit: .pounds))
    }

    func testUnitSwitchDoesNotMutateStoredPlannedOrActualWeights() throws {
        let owner = UserID(rawValue: "owner")
        let repository = InMemoryUserSettingsRepository(userID: owner)
        var set = WorkoutSet(order: 0, reps: 8, weight: 60, timeSeconds: 0)
        set.complete(at: .distantPast)
        set.editActual(reps: 7, weight: 61, timeSeconds: 0)
        let original = set

        try repository.saveWeightUnit(.pounds)
        try repository.saveWeightUnit(.kilograms)

        XCTAssertEqual(set, original)
        XCTAssertEqual(set.weight, 60)
        XCTAssertEqual(set.actualWeight, 61)
    }

    func testWorkoutViewModelCombinesBundledAndPersistedCustomExercises() throws {
        let userID = UserID(rawValue: "owner")
        let workouts = InMemoryWorkoutRepository(userID: userID)
        let customExercises = InMemoryCustomExerciseRepository(userID: userID)
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let viewModel = WorkoutViewModel(
            repository: workouts,
            initialDate: date,
            currentDate: date,
            customExerciseRepository: customExercises
        )

        let created = try viewModel.createCustomExercise(name: "  Bench   Anchor ")
        XCTAssertEqual(customExercises.customExercises, [created])
        XCTAssertEqual(viewModel.searchExercises("bench").map(\.name), ["Bench Press", "Close-Grip Bench Press", "Bench Anchor"])

        let restoredSession = WorkoutViewModel(
            repository: workouts,
            initialDate: date,
            currentDate: date,
            customExerciseRepository: customExercises
        )
        XCTAssertEqual(restoredSession.searchExercises("anchor"), [created])
    }
}

private final class SnapshotRecorder {
    var snapshots: [[Workout]] = []
}

private final class CustomExerciseSnapshotRecorder {
    var snapshots: [[Exercise]] = []
}

private final class SettingsSnapshotRecorder {
    var snapshots: [UserSettings] = []
}

final class SystemExerciseCatalogTests: XCTestCase {
    func testCatalogCoversApprovedCategoriesWithStableSystemExercises() throws {
        let exercises = SystemExerciseCatalog.all
        let expectedCategories: Set<String> = [
            "Chest", "Back", "Legs", "Shoulders", "Biceps", "Triceps", "Core", "Cardio/Other"
        ]

        XCTAssertFalse(exercises.isEmpty)
        XCTAssertEqual(exercises.count, 34)
        XCTAssertEqual(Set(exercises.compactMap(\.category)), expectedCategories)
        XCTAssertTrue(exercises.allSatisfy(\.isSystem))
        XCTAssertTrue(exercises.allSatisfy { $0.createdByUserID == nil })
        XCTAssertTrue(exercises.allSatisfy { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        XCTAssertEqual(Set(exercises.map(\.id)).count, exercises.count)
        XCTAssertEqual(Set(exercises.map { $0.name.lowercased() }).count, exercises.count)

        let expectedIDs = Set((1...34).map { ordinal in
            let suffix = String(format: "%012d", ordinal)
            return ExerciseID(rawValue: UUID(uuidString: "00000000-0000-4000-8000-\(suffix)")!)
        })
        XCTAssertEqual(Set(exercises.map(\.id)), expectedIDs)

        let benchPress = try XCTUnwrap(exercises.first { $0.name == "Bench Press" })
        XCTAssertEqual(benchPress.id, ExerciseID(rawValue: UUID(uuidString: "00000000-0000-4000-8000-000000000001")!))
    }

    func testSearchIsTrimmedCaseInsensitiveAndDeterministic() {
        let lowercaseIDs = SystemExerciseCatalog.search("bench").map(\.id)
        let mixedCaseIDs = SystemExerciseCatalog.search("  bEnCh  ").map(\.id)

        XCTAssertEqual(mixedCaseIDs, lowercaseIDs)
        XCTAssertEqual(SystemExerciseCatalog.search("BENCH").map(\.name), ["Bench Press", "Close-Grip Bench Press"])
        XCTAssertEqual(SystemExerciseCatalog.search("cable row").map(\.name), ["Seated Cable Row"])
    }

    func testEmptyQueryReturnsAllAndUnknownQueryReturnsNothing() {
        XCTAssertEqual(SystemExerciseCatalog.search(""), SystemExerciseCatalog.all)
        XCTAssertEqual(SystemExerciseCatalog.search("   \n"), SystemExerciseCatalog.all)
        XCTAssertTrue(SystemExerciseCatalog.search("not a bundled exercise").isEmpty)
    }
}

final class LocalExerciseLibraryTests: XCTestCase {
    func testCreatesOwnedCustomExerciseWithNormalizedInput() throws {
        let userID = UserID(rawValue: "user-a")
        var library = LocalExerciseLibrary(userID: userID)

        let result = try library.createCustomExercise(
            name: "  Single   Arm   Cable Row  ",
            category: "  Back   Accessory  "
        )

        XCTAssertTrue(result.wasCreated)
        XCTAssertEqual(result.exercise.name, "Single Arm Cable Row")
        XCTAssertEqual(result.exercise.category, "Back Accessory")
        XCTAssertFalse(result.exercise.isSystem)
        XCTAssertEqual(result.exercise.createdByUserID, userID)
        XCTAssertEqual(library.customExercises, [result.exercise])
        XCTAssertEqual(library.search("single ARM").map(\.id), [result.exercise.id])
    }

    func testRejectsEmptyNameAndNormalizesBlankCategory() throws {
        var library = LocalExerciseLibrary(userID: UserID(rawValue: "user"))

        XCTAssertThrowsError(try library.createCustomExercise(name: "  \n  ")) { error in
            XCTAssertEqual(error as? LocalExerciseLibraryError, .emptyName)
        }
        XCTAssertTrue(library.customExercises.isEmpty)

        let created = try library.createCustomExercise(name: "Sled Push", category: "   ")
        XCTAssertNil(created.exercise.category)
    }

    func testExactDuplicatesReuseVisibleExerciseWhileSimilarNamesRemainAllowed() throws {
        var library = LocalExerciseLibrary(userID: UserID(rawValue: "user"))

        let systemResult = try library.createCustomExercise(name: "  BENCH   press ")
        XCTAssertFalse(systemResult.wasCreated)
        XCTAssertTrue(systemResult.exercise.isSystem)
        XCTAssertTrue(library.customExercises.isEmpty)

        let first = try library.createCustomExercise(name: "Café Raise")
        let duplicate = try library.createCustomExercise(name: " cafe   RAISE ", category: "Other")
        XCTAssertTrue(first.wasCreated)
        XCTAssertFalse(duplicate.wasCreated)
        XCTAssertEqual(duplicate.exercise.id, first.exercise.id)
        XCTAssertEqual(library.customExercises.count, 1)

        let similar = try library.createCustomExercise(name: "Café Raise Machine")
        XCTAssertTrue(similar.wasCreated)
        XCTAssertEqual(library.customExercises.count, 2)
    }

    func testCombinedSearchIsDeterministicAndLibrariesAreOwnerScoped() throws {
        var firstLibrary = LocalExerciseLibrary(userID: UserID(rawValue: "user-a"))
        var secondLibrary = LocalExerciseLibrary(userID: UserID(rawValue: "user-b"))
        let custom = try firstLibrary.createCustomExercise(name: "Bench Press Machine")
        _ = try secondLibrary.createCustomExercise(name: "Private Bench Variation")

        XCTAssertEqual(
            firstLibrary.search("  BENCH ").map(\.name),
            ["Bench Press", "Close-Grip Bench Press", "Bench Press Machine"]
        )
        XCTAssertEqual(firstLibrary.search("").last?.id, custom.exercise.id)
        XCTAssertEqual(firstLibrary.search("   \n"), firstLibrary.allExercises)
        XCTAssertTrue(firstLibrary.search("private bench").isEmpty)
        XCTAssertTrue(firstLibrary.search("not an exercise").isEmpty)
        XCTAssertEqual(secondLibrary.customExercises.first?.createdByUserID, UserID(rawValue: "user-b"))
    }
}

final class ProgramCalendarStateTests: XCTestCase {
    func testWeekContainsSevenConcreteConsecutiveDatesAcrossMonthBoundary() {
        let state = ProgramCalendarState(
            selectedDate: LocalDate(year: 2026, month: 8, day: 14),
            calendar: mondayCalendar("Europe/Copenhagen")
        )

        XCTAssertEqual(state.weekDates, (10...16).map { LocalDate(year: 2026, month: 8, day: $0) })
        XCTAssertEqual(Set(state.weekDates).count, 7)

        let boundary = ProgramCalendarState(
            selectedDate: LocalDate(year: 2027, month: 1, day: 1),
            calendar: mondayCalendar("America/Los_Angeles")
        )
        XCTAssertEqual(boundary.weekDates.first, LocalDate(year: 2026, month: 12, day: 28))
        XCTAssertEqual(boundary.weekDates.last, LocalDate(year: 2027, month: 1, day: 3))
    }

    func testWeekNavigationPreservesSelectedWeekdayWithoutRangeLimit() {
        var state = ProgramCalendarState(
            selectedDate: LocalDate(year: 2026, month: 8, day: 14),
            calendar: mondayCalendar("Europe/Copenhagen")
        )

        state.moveWeek(by: 1)
        XCTAssertEqual(state.selectedDate, LocalDate(year: 2026, month: 8, day: 21))
        XCTAssertTrue(state.weekDates.contains(state.selectedDate))

        state.moveWeek(by: 11)
        XCTAssertEqual(state.selectedDate, LocalDate(year: 2026, month: 11, day: 6))
        XCTAssertTrue(state.weekDates.contains(state.selectedDate))

        state.moveWeek(by: -20)
        XCTAssertEqual(state.selectedDate, LocalDate(year: 2026, month: 6, day: 19))
        XCTAssertTrue(state.weekDates.contains(state.selectedDate))
    }

    func testSelectionDrivesWorkoutAndEmptyContent() throws {
        let workoutDate = LocalDate(year: 2026, month: 8, day: 12)
        let workout = makeWorkout(date: workoutDate, completed: [false])
        var state = ProgramCalendarState(
            selectedDate: LocalDate(year: 2026, month: 8, day: 14),
            currentDate: LocalDate(year: 2026, month: 8, day: 14),
            calendar: mondayCalendar("Europe/Copenhagen"),
            workouts: [workout]
        )

        XCTAssertEqual(state.selectedDayState, .empty)
        XCTAssertNil(state.selectedWorkout)
        state.select(workoutDate)
        XCTAssertEqual(state.selectedWorkout?.id, workout.id)
        XCTAssertEqual(state.selectedDayState, .workout(.incomplete))
    }

    func testAllWorkoutCalendarStatesUseDomainRules() {
        let current = LocalDate(year: 2026, month: 8, day: 14)
        let workouts = [
            makeWorkout(date: LocalDate(year: 2026, month: 8, day: 10), completed: [false]),
            makeWorkout(date: LocalDate(year: 2026, month: 8, day: 11), completed: [true, false]),
            makeWorkout(date: LocalDate(year: 2026, month: 8, day: 12), completed: [true]),
            makeWorkout(date: current, completed: [false])
        ]
        let state = ProgramCalendarState(
            selectedDate: current,
            currentDate: current,
            calendar: mondayCalendar("Europe/Copenhagen"),
            workouts: workouts
        )

        XCTAssertEqual(state.dayState(for: LocalDate(year: 2026, month: 8, day: 9)), .empty)
        XCTAssertEqual(state.dayState(for: LocalDate(year: 2026, month: 8, day: 10)), .workout(.incomplete))
        XCTAssertEqual(state.dayState(for: LocalDate(year: 2026, month: 8, day: 11)), .workout(.partial))
        XCTAssertEqual(state.dayState(for: LocalDate(year: 2026, month: 8, day: 12)), .workout(.completed))
        XCTAssertEqual(state.dayState(for: current), .workout(.planned))
        XCTAssertEqual(ProgramDayState.empty.label, "Empty")
        XCTAssertEqual(ProgramDayState.workout(.partial).systemImage, "circle.lefthalf.filled")
    }

    private func mondayCalendar(_ timeZone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: timeZone)!
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }

    private func makeWorkout(date: LocalDate, completed: [Bool]) -> Workout {
        var sets = completed.enumerated().map { WorkoutSet(order: $0.offset, reps: 8) }
        for index in sets.indices where completed[index] { sets[index].complete(at: .distantPast) }
        let exercise = WorkoutExercise(
            id: WorkoutExerciseID(), exerciseID: ExerciseID(), customName: nil,
            order: 0, isSkipped: false, sets: sets
        )
        return Workout(
            id: WorkoutID(), userID: UserID(rawValue: "user"), localDate: date,
            exercises: [exercise], createdAt: .distantPast, updatedAt: .distantPast
        )
    }
}

@MainActor
final class InMemoryWorkoutRepositoryTests: XCTestCase {
    func testCreateIsOwnerScopedEmptyAndImmediatelyReadable() {
        let userID = UserID(rawValue: "user-a")
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let timestamp = Date(timeIntervalSince1970: 1234)
        let fixedID = WorkoutID(rawValue: UUID(uuidString: "10000000-0000-4000-8000-000000000001")!)
        let repository = InMemoryWorkoutRepository(userID: userID, makeWorkoutID: { fixedID })

        let result = repository.createEmptyWorkout(on: date, at: timestamp)

        XCTAssertTrue(result.wasCreated)
        XCTAssertEqual(result.workout.id, fixedID)
        XCTAssertEqual(result.workout.userID, userID)
        XCTAssertEqual(result.workout.localDate, date)
        XCTAssertTrue(result.workout.exercises.isEmpty)
        XCTAssertEqual(result.workout.createdAt, timestamp)
        XCTAssertEqual(result.workout.updatedAt, timestamp)
        XCTAssertEqual(repository.workout(on: date), result.workout)
        XCTAssertNil(repository.workout(on: LocalDate(year: 2026, month: 8, day: 13)))
        XCTAssertNil(repository.workout(on: LocalDate(year: 2026, month: 8, day: 15)))
    }

    func testDuplicateCreateReturnsExistingWithoutConsumingAnotherIdentity() {
        let firstID = WorkoutID(rawValue: UUID(uuidString: "10000000-0000-4000-8000-000000000001")!)
        let secondID = WorkoutID(rawValue: UUID(uuidString: "10000000-0000-4000-8000-000000000002")!)
        var ids = [firstID, secondID]
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"), makeWorkoutID: { ids.removeFirst() })
        let date = LocalDate(year: 2026, month: 8, day: 14)

        let created = repository.createEmptyWorkout(on: date, at: Date(timeIntervalSince1970: 1))
        let existing = repository.createEmptyWorkout(on: date, at: Date(timeIntervalSince1970: 2))

        XCTAssertTrue(created.wasCreated)
        XCTAssertFalse(existing.wasCreated)
        XCTAssertEqual(existing.workout, created.workout)
        XCTAssertEqual(repository.workouts.count, 1)
        XCTAssertEqual(ids, [secondID])
    }

    func testDifferentDatesAndOwnersRemainIndependent() {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let first = InMemoryWorkoutRepository(userID: UserID(rawValue: "user-a"))
        let second = InMemoryWorkoutRepository(userID: UserID(rawValue: "user-b"))

        let firstWorkout = first.createEmptyWorkout(on: date, at: .distantPast).workout
        let nextWorkout = first.createEmptyWorkout(
            on: LocalDate(year: 2026, month: 8, day: 15), at: .distantPast
        ).workout
        let secondWorkout = second.createEmptyWorkout(on: date, at: .distantPast).workout

        XCTAssertNotEqual(firstWorkout.id, nextWorkout.id)
        XCTAssertEqual(first.workouts.count, 2)
        XCTAssertEqual(second.workouts, [secondWorkout])
        XCTAssertEqual(secondWorkout.userID, UserID(rawValue: "user-b"))
        XCTAssertEqual(first.workout(on: date)?.userID, UserID(rawValue: "user-a"))
    }

    func testSaveUpdatesSameIdentityAndRejectsOwnerOrDateCollisions() throws {
        let userID = UserID(rawValue: "user")
        let repository = InMemoryWorkoutRepository(userID: userID)
        let firstDate = LocalDate(year: 2026, month: 8, day: 14)
        let secondDate = LocalDate(year: 2026, month: 8, day: 15)
        let original = repository.createEmptyWorkout(on: firstDate, at: Date(timeIntervalSince1970: 1)).workout
        let occupied = repository.createEmptyWorkout(on: secondDate, at: Date(timeIntervalSince1970: 2)).workout

        var updated = original
        updated.updatedAt = Date(timeIntervalSince1970: 3)
        try repository.save(updated)
        XCTAssertEqual(repository.workout(on: firstDate)?.createdAt, original.createdAt)
        XCTAssertEqual(repository.workout(on: firstDate)?.updatedAt, updated.updatedAt)

        var intruder = occupied
        intruder.userID = UserID(rawValue: "another-user")
        XCTAssertThrowsError(try repository.save(intruder)) { error in
            XCTAssertEqual(error as? WorkoutRepositoryError, .ownerMismatch)
        }

        var collision = occupied
        collision.id = WorkoutID()
        XCTAssertThrowsError(try repository.save(collision)) { error in
            XCTAssertEqual(error as? WorkoutRepositoryError, .duplicateDate(collision.dateKey))
        }

        var moved = original
        moved.localDate = LocalDate(year: 2026, month: 8, day: 16)
        XCTAssertThrowsError(try repository.save(moved)) { error in
            XCTAssertEqual(error as? WorkoutRepositoryError, .identityConflict)
        }
    }
}

@MainActor
final class WorkoutViewModelTests: XCTestCase {
    func testCreateSelectedWorkoutRefreshesProgramWithoutChangingSelection() {
        let calendar = mondayCalendar()
        let selected = LocalDate(year: 2026, month: 8, day: 14)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: selected,
            currentDate: selected,
            calendar: calendar,
            now: { Date(timeIntervalSince1970: 1234) }
        )

        XCTAssertEqual(viewModel.calendarState.selectedDayState, .empty)
        viewModel.createSelectedWorkout()

        XCTAssertEqual(viewModel.selectedDate, selected)
        XCTAssertEqual(viewModel.calendarState.selectedDayState, .workout(.planned))
        XCTAssertTrue(viewModel.calendarState.selectedWorkout?.exercises.isEmpty == true)
        XCTAssertEqual(repository.workouts.count, 1)
        XCTAssertEqual(
            viewModel.calendarState.dayState(for: LocalDate(year: 2026, month: 8, day: 13)),
            .empty
        )

        viewModel.createSelectedWorkout()
        XCTAssertEqual(repository.workouts.count, 1)
    }

    func testCreateSelectedWorkoutDoesNotCreateHistoricalWorkout() {
        let currentDate = LocalDate(year: 2026, month: 8, day: 14)
        let historicalDate = LocalDate(year: 2026, month: 8, day: 13)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: historicalDate,
            currentDate: currentDate,
            calendar: mondayCalendar()
        )

        viewModel.createSelectedWorkout()

        XCTAssertFalse(viewModel.hasWorkout(on: historicalDate))
        XCTAssertTrue(viewModel.workouts.isEmpty)
    }

    func testWorkoutAvailabilityPropagatesWithoutHidingCachedToday() throws {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let userID = UserID(rawValue: "user")
        let repository = ControllableWorkoutRepository(userID: userID)
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: date,
            currentDate: date,
            calendar: mondayCalendar()
        )

        XCTAssertEqual(viewModel.workoutLoadState, .loading)
        XCTAssertEqual(
            TodayContentState.resolve(
                workouts: viewModel.workouts,
                currentDate: date,
                loadState: viewModel.workoutLoadState
            ),
            .loading
        )

        repository.publish([], state: .unavailable(hasUsableSnapshot: false))
        XCTAssertEqual(viewModel.workoutLoadState, .unavailable(hasUsableSnapshot: false))
        XCTAssertEqual(
            TodayContentState.resolve(
                workouts: viewModel.workouts,
                currentDate: date,
                loadState: viewModel.workoutLoadState
            ),
            .unavailable
        )

        let exerciseID = WorkoutExerciseID()
        let setID = WorkoutSetID()
        let cachedWorkout = Workout(
            id: WorkoutID(),
            userID: userID,
            localDate: date,
            exercises: [WorkoutExercise(
                id: exerciseID,
                exerciseID: SystemExerciseCatalog.all[0].id,
                customName: nil,
                order: 0,
                isSkipped: false,
                sets: [WorkoutSet(id: setID, order: 0, reps: 8, weight: 60, timeSeconds: 0)]
            )],
            createdAt: .distantPast,
            updatedAt: .distantPast
        )
        repository.publish([cachedWorkout], state: .unavailable(hasUsableSnapshot: true))

        XCTAssertEqual(viewModel.workoutLoadState, .unavailable(hasUsableSnapshot: true))
        XCTAssertEqual(viewModel.workout(on: date), cachedWorkout)
        XCTAssertEqual(
            TodayContentState.resolve(
                workouts: viewModel.workouts,
                currentDate: date,
                loadState: viewModel.workoutLoadState
            ),
            .activeWorkout
        )

        try viewModel.toggleCompletion(of: setID, in: exerciseID, on: date)
        XCTAssertTrue(try XCTUnwrap(repository.workout(on: date)?.exercises.first?.sets.first).isCompleted)
        XCTAssertEqual(viewModel.workoutLoadState, .unavailable(hasUsableSnapshot: true))

        repository.publish([cachedWorkout], state: .available)
        XCTAssertEqual(viewModel.workoutLoadState, .available)
    }

    func testAnalyticsLogsOnlySuccessfulPlanningMutations() throws {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        let analytics = AnalyticsRecorder()
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: date,
            currentDate: date,
            calendar: mondayCalendar(),
            analytics: analytics
        )

        viewModel.createSelectedWorkout()
        viewModel.createSelectedWorkout()
        let custom = try viewModel.createCustomExercise(name: "Nordic Hop")
        _ = try viewModel.createCustomExercise(name: "  NORDIC hop ")
        try viewModel.addExercise(SystemExerciseCatalog.all[0], to: date)
        try viewModel.addExercise(custom, to: date)
        try viewModel.copyWorkout(from: date, to: LocalDate(year: 2026, month: 8, day: 15))
        _ = try viewModel.repeatWorkout(from: date, through: LocalDate(year: 2026, month: 8, day: 28))

        XCTAssertEqual(analytics.events, [
            .workoutCreated,
            .customExerciseCreated,
            .exerciseAdded,
            .exerciseAdded,
            .workoutCopied,
            .workoutRepeatCreated
        ])
    }

    func testAnalyticsLogsTodayAndHistoricalActualTransitionsAfterSuccessfulSaves() throws {
        let currentDate = LocalDate(year: 2026, month: 8, day: 14)
        let historicalDate = LocalDate(year: 2026, month: 8, day: 7)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        let analytics = AnalyticsRecorder()
        var todayWorkout = repository.createEmptyWorkout(on: currentDate, at: .distantPast).workout
        let todayExerciseID = WorkoutExerciseID()
        let todaySetID = WorkoutSetID()
        todayWorkout.exercises = [WorkoutExercise(
            id: todayExerciseID,
            exerciseID: SystemExerciseCatalog.all[0].id,
            customName: nil,
            order: 0,
            isSkipped: false,
            sets: [WorkoutSet(id: todaySetID, order: 0, reps: 8, weight: 60, timeSeconds: 0)]
        )]
        try repository.save(todayWorkout)
        var historicalWorkout = repository.createEmptyWorkout(on: historicalDate, at: .distantPast).workout
        let historicalExerciseID = WorkoutExerciseID()
        let historicalSetID = WorkoutSetID()
        var historicalSet = WorkoutSet(id: historicalSetID, order: 0, reps: 8, weight: 60, timeSeconds: 0)
        historicalSet.complete(at: .distantPast)
        historicalWorkout.exercises = [WorkoutExercise(
            id: historicalExerciseID,
            exerciseID: SystemExerciseCatalog.all[1].id,
            customName: nil,
            order: 0,
            isSkipped: false,
            sets: [historicalSet]
        )]
        try repository.save(historicalWorkout)
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: currentDate,
            currentDate: currentDate,
            calendar: mondayCalendar(),
            analytics: analytics
        )

        try viewModel.toggleCompletion(of: todaySetID, in: todayExerciseID, on: currentDate)
        try viewModel.editTodaySet(todaySetID, in: todayExerciseID, on: currentDate, reps: 7, weight: 55, timeSeconds: 0)
        try viewModel.toggleCompletion(of: todaySetID, in: todayExerciseID, on: currentDate)
        try viewModel.skipTodayExercise(todayExerciseID, on: currentDate)
        try viewModel.editHistoricalActual(historicalSetID, in: historicalExerciseID, on: historicalDate, reps: 6, weight: 50, timeSeconds: 0)

        XCTAssertEqual(analytics.events, [
            .setCompleted,
            .workoutCompleted,
            .setActualEdited,
            .setUncompleted,
            .exerciseSkipped,
            .workoutCompleted,
            .setActualEdited
        ])
    }

    func testActiveZeroSetExercisePreventsCompletionUntilExplicitlySkipped() throws {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        let analytics = AnalyticsRecorder()
        var workout = repository.createEmptyWorkout(on: date, at: .distantPast).workout
        let setExerciseID = WorkoutExerciseID()
        let zeroSetExerciseID = WorkoutExerciseID()
        let setID = WorkoutSetID()
        workout.exercises = [
            WorkoutExercise(
                id: setExerciseID,
                exerciseID: SystemExerciseCatalog.all[0].id,
                customName: nil,
                order: 0,
                isSkipped: false,
                sets: [WorkoutSet(id: setID, order: 0, reps: 8, weight: 60, timeSeconds: 0)]
            ),
            WorkoutExercise(
                id: zeroSetExerciseID,
                exerciseID: SystemExerciseCatalog.all[1].id,
                customName: nil,
                order: 1,
                isSkipped: false,
                sets: []
            )
        ]
        try repository.save(workout)
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: date,
            currentDate: date,
            calendar: mondayCalendar(),
            analytics: analytics
        )

        try viewModel.toggleCompletion(of: setID, in: setExerciseID, on: date)
        XCTAssertEqual(viewModel.workout(on: date)?.completionStatus, .partial)
        XCTAssertEqual(analytics.events, [.setCompleted])

        try viewModel.skipTodayExercise(zeroSetExerciseID, on: date)
        XCTAssertEqual(viewModel.workout(on: date)?.completionStatus, .completed)
        XCTAssertEqual(analytics.events, [.setCompleted, .exerciseSkipped, .workoutCompleted])
    }

    func testSearchCreateAndReuseCustomExercisesFromLongLivedLibrary() throws {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: date,
            currentDate: date,
            calendar: mondayCalendar()
        )

        let custom = try viewModel.createCustomExercise(name: "  Nordic   Hop  ")
        XCTAssertEqual(custom.name, "Nordic Hop")
        XCTAssertEqual(custom.createdByUserID, repository.userID)
        XCTAssertEqual(viewModel.searchExercises("nOrDiC").map(\.id), [custom.id])
        XCTAssertEqual(viewModel.searchExercises("").prefix(SystemExerciseCatalog.all.count), SystemExerciseCatalog.all.prefix(SystemExerciseCatalog.all.count))

        let reusedCustom = try viewModel.createCustomExercise(name: " NORDIC hop ")
        XCTAssertEqual(reusedCustom.id, custom.id)
        XCTAssertEqual(viewModel.exerciseLibrary.customExercises.count, 1)

        let reusedSystem = try viewModel.createCustomExercise(name: " bench   PRESS ")
        XCTAssertTrue(reusedSystem.isSystem)
        XCTAssertTrue(viewModel.exerciseLibrary.customExercises.count == 1)
    }

    func testAddingSystemAndCustomExercisesPersistsOrderedWorkoutEntries() throws {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let timestamp = Date(timeIntervalSince1970: 4567)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        _ = repository.createEmptyWorkout(on: date, at: .distantPast)
        let firstID = WorkoutExerciseID(rawValue: UUID(uuidString: "20000000-0000-4000-8000-000000000001")!)
        let secondID = WorkoutExerciseID(rawValue: UUID(uuidString: "20000000-0000-4000-8000-000000000002")!)
        var entryIDs = [firstID, secondID]
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: date,
            currentDate: date,
            calendar: mondayCalendar(),
            now: { timestamp },
            makeWorkoutExerciseID: { entryIDs.removeFirst() }
        )
        let system = SystemExerciseCatalog.all[0]
        let custom = try viewModel.createCustomExercise(name: "Nordic Hop")

        try viewModel.addExercise(system, to: date)
        try viewModel.addExercise(custom, to: date)

        let exercises = try XCTUnwrap(repository.workout(on: date)?.exercises)
        XCTAssertEqual(exercises.map(\.id), [firstID, secondID])
        XCTAssertEqual(exercises.map(\.order), [0, 1])
        XCTAssertEqual(exercises[0].exerciseID, system.id)
        XCTAssertNil(exercises[0].customName)
        XCTAssertEqual(exercises[1].exerciseID, custom.id)
        XCTAssertEqual(exercises[1].customName, "Nordic Hop")
        XCTAssertTrue(exercises.allSatisfy { !$0.isSkipped && $0.sets.isEmpty })
        XCTAssertEqual(repository.workout(on: date)?.updatedAt, timestamp)
        XCTAssertEqual(viewModel.exerciseName(for: exercises[0]), system.name)
        XCTAssertEqual(viewModel.exerciseName(for: exercises[1]), custom.name)
    }

    func testAddingWithoutWorkoutReturnsTypedErrorAndDoesNotMutateRepository() {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: date,
            currentDate: date,
            calendar: mondayCalendar()
        )

        XCTAssertThrowsError(try viewModel.addExercise(SystemExerciseCatalog.all[0], to: date)) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .workoutNotFound(date))
        }
        XCTAssertTrue(repository.workouts.isEmpty)
    }

    func testAddingUnknownOrForeignExerciseIsRejectedWithoutWorkoutMutation() {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        _ = repository.createEmptyWorkout(on: date, at: .distantPast)
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: date,
            currentDate: date,
            calendar: mondayCalendar()
        )
        let foreign = Exercise(
            id: ExerciseID(),
            name: "Private Exercise",
            category: nil,
            isSystem: false,
            createdByUserID: UserID(rawValue: "another-user")
        )

        XCTAssertThrowsError(try viewModel.addExercise(foreign, to: date)) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .exerciseUnavailable(foreign.id))
        }
        XCTAssertTrue(repository.workout(on: date)?.exercises.isEmpty == true)
    }

    func testReorderPersistsNormalizesAndKeepsOtherDateIndependent() throws {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let otherDate = LocalDate(year: 2026, month: 8, day: 15)
        let fixedNow = Date(timeIntervalSince1970: 9000)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        var workout = repository.createEmptyWorkout(on: date, at: .distantPast).workout
        let otherWorkout = repository.createEmptyWorkout(on: otherDate, at: .distantPast).workout
        let ids = [
            WorkoutExerciseID(rawValue: UUID(uuidString: "30000000-0000-4000-8000-000000000001")!),
            WorkoutExerciseID(rawValue: UUID(uuidString: "30000000-0000-4000-8000-000000000002")!),
            WorkoutExerciseID(rawValue: UUID(uuidString: "30000000-0000-4000-8000-000000000003")!)
        ]
        workout.exercises = [
            planningExercise(id: ids[0], catalogIndex: 0, order: 2, reps: 5),
            planningExercise(id: ids[1], catalogIndex: 1, order: 7, reps: 8),
            planningExercise(id: ids[2], catalogIndex: 2, order: 12, reps: 12)
        ]
        try repository.save(workout)
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: date,
            currentDate: date,
            calendar: mondayCalendar(),
            now: { fixedNow }
        )

        try viewModel.reorderExercises([ids[1], ids[2], ids[0]], on: date)

        let persisted = try XCTUnwrap(repository.workout(on: date))
        XCTAssertEqual(persisted.exercises.map(\.id), [ids[1], ids[2], ids[0]])
        XCTAssertEqual(persisted.exercises.map(\.order), [0, 1, 2])
        XCTAssertEqual(persisted.exercises.flatMap(\.sets).map(\.reps), [8, 12, 5])
        XCTAssertEqual(persisted.updatedAt, fixedNow)
        XCTAssertEqual(repository.workout(on: otherDate), otherWorkout)
        XCTAssertEqual(viewModel.selectedDate, date)

        let freshViewModel = WorkoutViewModel(
            repository: repository,
            initialDate: date,
            currentDate: date,
            calendar: mondayCalendar()
        )
        XCTAssertEqual(freshViewModel.orderedExercises(on: date).map(\.id), [ids[1], ids[2], ids[0]])

        let beforeInvalid = repository.workout(on: date)
        XCTAssertThrowsError(try viewModel.reorderExercises([ids[0], ids[1]], on: date)) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .invalidExerciseOrder)
        }
        XCTAssertEqual(repository.workout(on: date), beforeInvalid)
    }

    func testDeleteCompactsOrderAndReAddCreatesIndependentEntryAtEnd() throws {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        var workout = repository.createEmptyWorkout(on: date, at: .distantPast).workout
        let firstID = WorkoutExerciseID(rawValue: UUID(uuidString: "40000000-0000-4000-8000-000000000001")!)
        let deletedID = WorkoutExerciseID(rawValue: UUID(uuidString: "40000000-0000-4000-8000-000000000002")!)
        let lastID = WorkoutExerciseID(rawValue: UUID(uuidString: "40000000-0000-4000-8000-000000000003")!)
        let readdedID = WorkoutExerciseID(rawValue: UUID(uuidString: "40000000-0000-4000-8000-000000000004")!)
        workout.exercises = [
            planningExercise(id: firstID, catalogIndex: 0, order: 0, reps: 5),
            planningExercise(id: deletedID, catalogIndex: 1, order: 1, reps: 8),
            planningExercise(id: lastID, catalogIndex: 2, order: 2, reps: 12)
        ]
        try repository.save(workout)
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: date,
            currentDate: date,
            calendar: mondayCalendar(),
            makeWorkoutExerciseID: { readdedID }
        )

        try viewModel.deleteExercise(deletedID, from: date)
        XCTAssertEqual(repository.workout(on: date)?.exercises.map(\.id), [firstID, lastID])
        XCTAssertEqual(repository.workout(on: date)?.exercises.map(\.order), [0, 1])

        let beforeMissing = repository.workout(on: date)
        XCTAssertThrowsError(try viewModel.deleteExercise(deletedID, from: date)) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .workoutExerciseNotFound(deletedID))
        }
        XCTAssertEqual(repository.workout(on: date), beforeMissing)

        try viewModel.addExercise(SystemExerciseCatalog.all[1], to: date)
        let afterReAdd = try XCTUnwrap(repository.workout(on: date)?.exercises)
        XCTAssertEqual(afterReAdd.map(\.id), [firstID, lastID, readdedID])
        XCTAssertEqual(afterReAdd.map(\.order), [0, 1, 2])
        XCTAssertNotEqual(readdedID, deletedID)
        XCTAssertTrue(afterReAdd.last?.sets.isEmpty == true)
        XCTAssertFalse(afterReAdd.last?.isSkipped == true)
    }

    func testAddSetCopiesOnlyPreviousPlanWithFreshIdentityAndZeroFirstSet() throws {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        var workout = repository.createEmptyWorkout(on: date, at: .distantPast).workout
        let exerciseID = WorkoutExerciseID(rawValue: UUID(uuidString: "50000000-0000-4000-8000-000000000001")!)
        let firstSetID = WorkoutSetID(rawValue: UUID(uuidString: "50000000-0000-4000-8000-000000000002")!)
        let secondSetID = WorkoutSetID(rawValue: UUID(uuidString: "50000000-0000-4000-8000-000000000003")!)
        workout.exercises = [planningExercise(id: exerciseID, catalogIndex: 0, order: 0, reps: 0)]
        workout.exercises[0].sets = []
        try repository.save(workout)
        var setIDs = [firstSetID, secondSetID]
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: date,
            currentDate: date,
            calendar: mondayCalendar(),
            makeWorkoutSetID: { setIDs.removeFirst() }
        )

        try viewModel.addSet(to: exerciseID, on: date)
        var sets = try XCTUnwrap(repository.workout(on: date)?.exercises.first?.sets)
        XCTAssertEqual(sets.map(\.id), [firstSetID])
        XCTAssertEqual(sets[0].order, 0)
        XCTAssertEqual(sets[0].reps, 0)
        XCTAssertEqual(sets[0].weight, 0)
        XCTAssertEqual(sets[0].timeSeconds, 0)
        XCTAssertFalse(sets[0].isCompleted)
        XCTAssertNil(sets[0].actualReps)

        try viewModel.editSet(firstSetID, in: exerciseID, on: date, reps: 8, weight: 0, timeSeconds: 45)
        try viewModel.addSet(to: exerciseID, on: date)
        sets = try XCTUnwrap(repository.workout(on: date)?.exercises.first?.sets)
        XCTAssertEqual(sets.map(\.id), [firstSetID, secondSetID])
        XCTAssertEqual(sets.map(\.order), [0, 1])
        XCTAssertEqual(sets[1].reps, 8)
        XCTAssertEqual(sets[1].weight, 0)
        XCTAssertEqual(sets[1].timeSeconds, 45)
        XCTAssertFalse(sets[1].isCompleted)
        XCTAssertNil(sets[1].actualWeight)
        XCTAssertEqual(SetDisplayFormatter(unit: .kilograms).string(reps: 8, weightInKilograms: 0, timeSeconds: 45), "8 reps × 45 sec")
    }

    func testTodayCompletionTogglePersistsImmediatelyAndAllowsArbitraryOrder() throws {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let timestamp = Date(timeIntervalSince1970: 12_345)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        var workout = repository.createEmptyWorkout(on: date, at: .distantPast).workout
        let firstExerciseID = WorkoutExerciseID(rawValue: UUID(uuidString: "51500000-0000-4000-8000-000000000001")!)
        let secondExerciseID = WorkoutExerciseID(rawValue: UUID(uuidString: "51500000-0000-4000-8000-000000000002")!)
        let firstSetID = WorkoutSetID(rawValue: UUID(uuidString: "51500000-0000-4000-8000-000000000101")!)
        let secondSetID = WorkoutSetID(rawValue: UUID(uuidString: "51500000-0000-4000-8000-000000000201")!)
        workout.exercises = [
            WorkoutExercise(
                id: firstExerciseID,
                exerciseID: SystemExerciseCatalog.all[0].id,
                customName: nil,
                order: 1,
                isSkipped: false,
                sets: [WorkoutSet(id: firstSetID, order: 2, reps: 8, weight: 60, timeSeconds: 0)]
            ),
            WorkoutExercise(
                id: secondExerciseID,
                exerciseID: SystemExerciseCatalog.all[6].id,
                customName: nil,
                order: 0,
                isSkipped: false,
                sets: [WorkoutSet(id: secondSetID, order: 4, reps: 12, weight: 0, timeSeconds: 0)]
            )
        ]
        try repository.save(workout)
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: date,
            currentDate: date,
            calendar: mondayCalendar(),
            now: { timestamp }
        )

        try viewModel.toggleCompletion(of: secondSetID, in: secondExerciseID, on: date)
        var persisted = try XCTUnwrap(repository.workout(on: date))
        let completedSecond = try XCTUnwrap(persisted.exercises.first { $0.id == secondExerciseID }?.sets.first)
        XCTAssertTrue(completedSecond.isCompleted)
        XCTAssertEqual(completedSecond.actualReps, 12)
        XCTAssertEqual(completedSecond.actualWeight, 0)
        XCTAssertEqual(completedSecond.actualTimeSeconds, 0)
        XCTAssertEqual(completedSecond.completedAt, timestamp)
        XCTAssertEqual(persisted.updatedAt, timestamp)
        XCTAssertFalse(try XCTUnwrap(persisted.exercises.first { $0.id == firstExerciseID }?.sets.first).isCompleted)

        try viewModel.toggleCompletion(of: firstSetID, in: firstExerciseID, on: date)
        persisted = try XCTUnwrap(repository.workout(on: date))
        XCTAssertEqual(persisted.exercises.map(\.id), [firstExerciseID, secondExerciseID])
        XCTAssertEqual(persisted.exercises.map(\.order), [1, 0])
        XCTAssertEqual(persisted.exercises.flatMap(\.sets).map(\.id), [firstSetID, secondSetID])
        XCTAssertTrue(persisted.exercises.flatMap(\.sets).allSatisfy(\.isCompleted))
        XCTAssertEqual(viewModel.workout(on: date), persisted)

        try viewModel.toggleCompletion(of: secondSetID, in: secondExerciseID, on: date)
        let undone = try XCTUnwrap(repository.workout(on: date)?.exercises.first { $0.id == secondExerciseID }?.sets.first)
        XCTAssertFalse(undone.isCompleted)
        XCTAssertNil(undone.actualReps)
        XCTAssertNil(undone.actualWeight)
        XCTAssertNil(undone.actualTimeSeconds)
        XCTAssertNil(undone.completedAt)
    }

    func testTodaySetEditUsesPlanOrActualValuesWithoutChangingCompletionSemantics() throws {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let timestamp = Date(timeIntervalSince1970: 98_765)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        var workout = repository.createEmptyWorkout(on: date, at: .distantPast).workout
        let exerciseID = WorkoutExerciseID(rawValue: UUID(uuidString: "51600000-0000-4000-8000-000000000001")!)
        let plannedSetID = WorkoutSetID(rawValue: UUID(uuidString: "51600000-0000-4000-8000-000000000101")!)
        let completedSetID = WorkoutSetID(rawValue: UUID(uuidString: "51600000-0000-4000-8000-000000000102")!)
        var completedSet = WorkoutSet(id: completedSetID, order: 1, reps: 8, weight: 60, timeSeconds: 0)
        completedSet.complete(at: .distantPast)
        workout.exercises = [WorkoutExercise(
            id: exerciseID,
            exerciseID: SystemExerciseCatalog.all[0].id,
            customName: nil,
            order: 0,
            isSkipped: false,
            sets: [
                WorkoutSet(id: plannedSetID, order: 0, reps: 10, weight: 40, timeSeconds: 0),
                completedSet
            ]
        )]
        try repository.save(workout)
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: date,
            currentDate: date,
            calendar: mondayCalendar(),
            now: { timestamp }
        )

        try viewModel.editTodaySet(plannedSetID, in: exerciseID, on: date, reps: 12, weight: 45, timeSeconds: 0)
        try viewModel.editTodaySet(completedSetID, in: exerciseID, on: date, reps: 6, weight: 55, timeSeconds: 0)

        let updated = try XCTUnwrap(repository.workout(on: date)?.exercises.first?.sets)
        XCTAssertEqual(updated[0].reps, 12)
        XCTAssertEqual(updated[0].weight, 45)
        XCTAssertFalse(updated[0].isCompleted)
        XCTAssertNil(updated[0].actualReps)
        XCTAssertEqual(updated[1].reps, 8)
        XCTAssertEqual(updated[1].weight, 60)
        XCTAssertTrue(updated[1].isCompleted)
        XCTAssertEqual(updated[1].actualReps, 6)
        XCTAssertEqual(updated[1].actualWeight, 55)
        XCTAssertEqual(updated[1].completedAt, .distantPast)

        let beforeInvalid = repository.workout(on: date)
        XCTAssertThrowsError(try viewModel.editTodaySet(
            plannedSetID,
            in: exerciseID,
            on: date,
            reps: -1,
            weight: 0,
            timeSeconds: 0
        )) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .invalidSetValues)
        }
        XCTAssertEqual(repository.workout(on: date), beforeInvalid)
        XCTAssertEqual(viewModel.workout(on: date), beforeInvalid)
    }

    func testSkipTodayExercisePersistsWithoutCompletingItsSets() throws {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        var workout = repository.createEmptyWorkout(on: date, at: .distantPast).workout
        let exerciseID = WorkoutExerciseID()
        let setID = WorkoutSetID()
        workout.exercises = [WorkoutExercise(
            id: exerciseID,
            exerciseID: SystemExerciseCatalog.all[0].id,
            customName: nil,
            order: 0,
            isSkipped: false,
            sets: [WorkoutSet(id: setID, order: 0, reps: 8, weight: 60, timeSeconds: 0)]
        )]
        try repository.save(workout)
        let viewModel = WorkoutViewModel(repository: repository, initialDate: date, currentDate: date, calendar: mondayCalendar())

        try viewModel.skipTodayExercise(exerciseID, on: date)

        let skipped = try XCTUnwrap(repository.workout(on: date)?.exercises.first)
        XCTAssertTrue(skipped.isSkipped)
        XCTAssertFalse(try XCTUnwrap(skipped.sets.first).isCompleted)
        XCTAssertNil(try XCTUnwrap(skipped.sets.first).actualReps)
        XCTAssertTrue(viewModel.workout(on: date)?.exercises.first?.isSkipped == true)
    }

    func testRestoreTodayExercisePreservesOriginalSetCompletionStateAndRequiresCurrentDate() throws {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let otherDate = LocalDate(year: 2026, month: 8, day: 15)
        let timestamp = Date(timeIntervalSince1970: 123_456)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        var workout = repository.createEmptyWorkout(on: date, at: .distantPast).workout
        let leadingExerciseID = WorkoutExerciseID()
        let exerciseID = WorkoutExerciseID()
        let plannedSetID = WorkoutSetID()
        let completedSetID = WorkoutSetID()
        var completedSet = WorkoutSet(id: completedSetID, order: 1, reps: 8, weight: 60, timeSeconds: 0)
        completedSet.complete(at: .distantPast)
        completedSet.editActual(reps: 6, weight: 55, timeSeconds: 0)
        workout.exercises = [
            WorkoutExercise(
                id: leadingExerciseID,
                exerciseID: SystemExerciseCatalog.all[6].id,
                customName: nil,
                order: 0,
                isSkipped: false,
                sets: [WorkoutSet(order: 0, reps: 12, weight: 0, timeSeconds: 0)]
            ),
            WorkoutExercise(
                id: exerciseID,
                exerciseID: SystemExerciseCatalog.all[0].id,
                customName: nil,
                order: 1,
                isSkipped: false,
                sets: [
                    WorkoutSet(id: plannedSetID, order: 0, reps: 10, weight: 40, timeSeconds: 0),
                    completedSet
                ]
            )
        ]
        try repository.save(workout)
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: date,
            currentDate: date,
            calendar: mondayCalendar(),
            now: { timestamp }
        )

        try viewModel.skipTodayExercise(exerciseID, on: date)
        try viewModel.restoreTodayExercise(exerciseID, on: date)

        let restoredWorkout = try XCTUnwrap(repository.workout(on: date))
        let restored = try XCTUnwrap(restoredWorkout.exercises.first { $0.id == exerciseID })
        XCTAssertFalse(restored.isSkipped)
        XCTAssertEqual(restored.id, exerciseID)
        XCTAssertEqual(restored.order, 1)
        let restoredPlanned = try XCTUnwrap(restored.sets.first { $0.id == plannedSetID })
        XCTAssertFalse(restoredPlanned.isCompleted)
        XCTAssertNil(restoredPlanned.actualReps)
        let restoredCompleted = try XCTUnwrap(restored.sets.first { $0.id == completedSetID })
        XCTAssertTrue(restoredCompleted.isCompleted)
        XCTAssertEqual(restoredCompleted.actualReps, 6)
        XCTAssertEqual(restoredCompleted.actualWeight, 55)
        XCTAssertEqual(restoredCompleted.actualTimeSeconds, 0)
        XCTAssertEqual(restoredCompleted.completedAt, .distantPast)
        XCTAssertEqual(restoredWorkout.exercises.map(\.id), [leadingExerciseID, exerciseID])
        XCTAssertEqual(restoredWorkout.completionStatus, .partial)
        XCTAssertEqual(restoredWorkout, viewModel.workout(on: date))

        let afterRestore = try XCTUnwrap(repository.workout(on: date))
        try viewModel.restoreTodayExercise(exerciseID, on: date)
        XCTAssertEqual(repository.workout(on: date), afterRestore)
        XCTAssertThrowsError(try viewModel.restoreTodayExercise(exerciseID, on: otherDate)) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .todayActionRequiresCurrentDate(otherDate))
        }
    }

    func testEditSetPreservesCompletedActualAndRejectsInvalidValuesAtomically() throws {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        var workout = repository.createEmptyWorkout(on: date, at: .distantPast).workout
        let exerciseID = WorkoutExerciseID(rawValue: UUID(uuidString: "51000000-0000-4000-8000-000000000001")!)
        let setID = WorkoutSetID(rawValue: UUID(uuidString: "51000000-0000-4000-8000-000000000002")!)
        var completedSet = WorkoutSet(id: setID, order: 0, reps: 5, weight: 30, timeSeconds: 0)
        completedSet.complete(at: .distantPast)
        workout.exercises = [WorkoutExercise(
            id: exerciseID,
            exerciseID: SystemExerciseCatalog.all[0].id,
            customName: nil,
            order: 0,
            isSkipped: false,
            sets: [completedSet]
        )]
        try repository.save(workout)
        let viewModel = WorkoutViewModel(repository: repository, initialDate: date, currentDate: date, calendar: mondayCalendar())

        try viewModel.editSet(setID, in: exerciseID, on: date, reps: 7, weight: 0, timeSeconds: 45)
        let updated = try XCTUnwrap(repository.workout(on: date)?.exercises.first?.sets.first)
        XCTAssertEqual(updated.reps, 7)
        XCTAssertEqual(updated.weight, 0)
        XCTAssertEqual(updated.timeSeconds, 45)
        XCTAssertTrue(updated.isCompleted)
        XCTAssertEqual(updated.actualReps, 5)
        XCTAssertEqual(updated.actualWeight, 30)
        XCTAssertEqual(updated.actualTimeSeconds, 0)

        let beforeInvalid = repository.workout(on: date)
        for invalid in [(-1, 0.0, 0), (0, -0.5, 0), (0, .nan, 0), (0, .infinity, 0), (0, 0, -1)] {
            XCTAssertThrowsError(try viewModel.editSet(
                setID,
                in: exerciseID,
                on: date,
                reps: invalid.0,
                weight: invalid.1,
                timeSeconds: invalid.2
            )) { error in
                XCTAssertEqual(error as? ProgramPlanningError, .invalidSetValues)
            }
            XCTAssertEqual(repository.workout(on: date), beforeInvalid)
        }
    }

    func testHistoricalActualEditPersistsOnlyCompletedPastSet() throws {
        let currentDate = LocalDate(year: 2026, month: 8, day: 14)
        let pastDate = LocalDate(year: 2026, month: 8, day: 7)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        var workout = repository.createEmptyWorkout(on: pastDate, at: .distantPast).workout
        let exerciseID = WorkoutExerciseID()
        let completedSetID = WorkoutSetID()
        let incompleteSetID = WorkoutSetID()
        var completedSet = WorkoutSet(id: completedSetID, order: 0, reps: 8, weight: 60, timeSeconds: 0)
        completedSet.complete(at: Date(timeIntervalSince1970: 123))
        workout.exercises = [WorkoutExercise(
            id: exerciseID,
            exerciseID: SystemExerciseCatalog.all[0].id,
            customName: nil,
            order: 0,
            isSkipped: false,
            sets: [
                completedSet,
                WorkoutSet(id: incompleteSetID, order: 1, reps: 12, weight: 0, timeSeconds: 0)
            ]
        )]
        try repository.save(workout)
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: pastDate,
            currentDate: currentDate,
            calendar: mondayCalendar(),
            now: { Date(timeIntervalSince1970: 456) }
        )

        try viewModel.editHistoricalActual(
            completedSetID,
            in: exerciseID,
            on: pastDate,
            reps: 7,
            weight: 65,
            timeSeconds: 0
        )

        let persisted = try XCTUnwrap(repository.workout(on: pastDate)?.exercises.first?.sets.first)
        XCTAssertEqual(persisted.reps, 8)
        XCTAssertEqual(persisted.weight, 60)
        XCTAssertEqual(persisted.timeSeconds, 0)
        XCTAssertEqual(persisted.actualReps, 7)
        XCTAssertEqual(persisted.actualWeight, 65)
        XCTAssertEqual(persisted.actualTimeSeconds, 0)
        XCTAssertTrue(persisted.isCompleted)
        XCTAssertEqual(persisted.completedAt, Date(timeIntervalSince1970: 123))
        XCTAssertEqual(repository.workout(on: pastDate)?.updatedAt, Date(timeIntervalSince1970: 456))
        let reopened = WorkoutViewModel(repository: repository, initialDate: pastDate, currentDate: currentDate, calendar: mondayCalendar())
        XCTAssertEqual(reopened.orderedSets(for: exerciseID, on: pastDate).first?.actualWeight, 65)

        let beforeRejectedEdits = repository.workout(on: pastDate)
        XCTAssertThrowsError(try viewModel.editHistoricalActual(
            incompleteSetID,
            in: exerciseID,
            on: pastDate,
            reps: 1,
            weight: 1,
            timeSeconds: 1
        )) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .workoutSetNotCompleted(incompleteSetID))
        }
        XCTAssertThrowsError(try viewModel.editHistoricalActual(
            completedSetID,
            in: exerciseID,
            on: currentDate,
            reps: 1,
            weight: 1,
            timeSeconds: 1
        )) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .historicalActualEditRequiresPastDate(currentDate))
        }
        XCTAssertThrowsError(try viewModel.editHistoricalActual(
            completedSetID,
            in: exerciseID,
            on: pastDate,
            reps: -1,
            weight: 1,
            timeSeconds: 1
        )) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .invalidSetValues)
        }
        XCTAssertEqual(repository.workout(on: pastDate), beforeRejectedEdits)
    }

    func testDeleteAndReorderSetsPersistOnlyOnSelectedDate() throws {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let otherDate = LocalDate(year: 2026, month: 8, day: 15)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        var workout = repository.createEmptyWorkout(on: date, at: .distantPast).workout
        let otherWorkout = repository.createEmptyWorkout(on: otherDate, at: .distantPast).workout
        let exerciseID = WorkoutExerciseID(rawValue: UUID(uuidString: "52000000-0000-4000-8000-000000000001")!)
        let setIDs = (2...4).map { ordinal in
            WorkoutSetID(rawValue: UUID(uuidString: "52000000-0000-4000-8000-00000000000\(ordinal)")!)
        }
        workout.exercises = [WorkoutExercise(
            id: exerciseID,
            exerciseID: SystemExerciseCatalog.all[0].id,
            customName: nil,
            order: 0,
            isSkipped: false,
            sets: [
                WorkoutSet(id: setIDs[0], order: 8, reps: 5, weight: 0, timeSeconds: 0),
                WorkoutSet(id: setIDs[1], order: 2, reps: 8, weight: 60, timeSeconds: 0),
                WorkoutSet(id: setIDs[2], order: 5, reps: 0, weight: 0, timeSeconds: 45)
            ]
        )]
        try repository.save(workout)
        let viewModel = WorkoutViewModel(repository: repository, initialDate: date, currentDate: date, calendar: mondayCalendar())

        try viewModel.reorderSets([setIDs[2], setIDs[0], setIDs[1]], in: exerciseID, on: date)
        var persisted = try XCTUnwrap(repository.workout(on: date)?.exercises.first?.sets)
        XCTAssertEqual(persisted.map(\.id), [setIDs[2], setIDs[0], setIDs[1]])
        XCTAssertEqual(persisted.map(\.order), [0, 1, 2])
        XCTAssertEqual(persisted.map(\.timeSeconds), [45, 0, 0])

        let beforeInvalid = repository.workout(on: date)
        XCTAssertThrowsError(try viewModel.reorderSets([setIDs[0], setIDs[0], setIDs[1]], in: exerciseID, on: date)) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .invalidSetOrder)
        }
        XCTAssertEqual(repository.workout(on: date), beforeInvalid)

        try viewModel.deleteSet(setIDs[0], from: exerciseID, on: date)
        persisted = try XCTUnwrap(repository.workout(on: date)?.exercises.first?.sets)
        XCTAssertEqual(persisted.map(\.id), [setIDs[2], setIDs[1]])
        XCTAssertEqual(persisted.map(\.order), [0, 1])
        XCTAssertEqual(repository.workout(on: otherDate), otherWorkout)

        XCTAssertThrowsError(try viewModel.deleteSet(setIDs[0], from: exerciseID, on: date)) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .workoutSetNotFound(setIDs[0]))
        }
    }

    func testDeleteWorkoutRefreshesSelectedDateAndPreservesOtherDates() throws {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let otherDate = LocalDate(year: 2026, month: 8, day: 15)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        let workout = repository.createEmptyWorkout(on: date, at: .distantPast).workout
        let otherWorkout = repository.createEmptyWorkout(on: otherDate, at: .distantPast).workout
        let viewModel = WorkoutViewModel(repository: repository, initialDate: date, currentDate: date, calendar: mondayCalendar())

        try viewModel.deleteWorkout(on: date)

        XCTAssertNil(repository.workout(on: date))
        XCTAssertEqual(repository.workout(on: otherDate), otherWorkout)
        XCTAssertEqual(viewModel.calendarState.selectedDayState, .empty)

        XCTAssertThrowsError(try viewModel.deleteWorkout(on: date)) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .workoutNotFound(date))
        }
        XCTAssertNil(repository.workout(on: date))
        XCTAssertEqual(workout.localDate, date)
    }

    func testCopyWorkoutCreatesAnIndependentPlannedCopyWithoutHistory() throws {
        let sourceDate = LocalDate(year: 2026, month: 8, day: 14)
        let destinationDate = LocalDate(year: 2026, month: 8, day: 19)
        let timestamp = Date(timeIntervalSince1970: 12_345)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        var source = repository.createEmptyWorkout(on: sourceDate, at: .distantPast).workout
        let sourceExerciseIDs = [WorkoutExerciseID(), WorkoutExerciseID()]
        let sourceSetIDs = [WorkoutSetID(), WorkoutSetID()]
        var completedSet = WorkoutSet(id: sourceSetIDs[0], order: 4, reps: 8, weight: 0, timeSeconds: 45)
        completedSet.complete(at: .distantPast)
        completedSet.editActual(reps: 9, weight: 0, timeSeconds: 50)
        source.exercises = [
            WorkoutExercise(
                id: sourceExerciseIDs[0],
                exerciseID: ExerciseID(),
                customName: "Nordic Hop",
                order: 9,
                isSkipped: true,
                sets: [completedSet]
            ),
            WorkoutExercise(
                id: sourceExerciseIDs[1],
                exerciseID: SystemExerciseCatalog.all[0].id,
                customName: nil,
                order: 2,
                isSkipped: false,
                sets: [WorkoutSet(id: sourceSetIDs[1], order: 3, reps: 5, weight: 60, timeSeconds: 0)]
            )
        ]
        try repository.save(source)
        let sourceBeforeCopy = try XCTUnwrap(repository.workout(on: sourceDate))
        let expectedCopiedExerciseIDs = [WorkoutExerciseID(), WorkoutExerciseID()]
        let expectedCopiedSetIDs = [WorkoutSetID(), WorkoutSetID()]
        var copiedExerciseIDs = expectedCopiedExerciseIDs
        var copiedSetIDs = expectedCopiedSetIDs
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: sourceDate,
            currentDate: sourceDate,
            calendar: mondayCalendar(),
            now: { timestamp },
            makeWorkoutExerciseID: { copiedExerciseIDs.removeFirst() },
            makeWorkoutSetID: { copiedSetIDs.removeFirst() }
        )

        try viewModel.copyWorkout(from: sourceDate, to: destinationDate)

        let destination = try XCTUnwrap(repository.workout(on: destinationDate))
        XCTAssertEqual(repository.workout(on: sourceDate), sourceBeforeCopy)
        XCTAssertNotEqual(destination.id, sourceBeforeCopy.id)
        XCTAssertEqual(destination.createdAt, timestamp)
        XCTAssertEqual(destination.updatedAt, timestamp)
        XCTAssertEqual(destination.exercises.map(\.id), expectedCopiedExerciseIDs)
        XCTAssertEqual(destination.exercises.map(\.order), [0, 1])
        XCTAssertEqual(destination.exercises.map(\.exerciseID), [SystemExerciseCatalog.all[0].id, sourceBeforeCopy.exercises[0].exerciseID])
        XCTAssertEqual(destination.exercises.map(\.customName), [nil, "Nordic Hop"])
        XCTAssertTrue(destination.exercises.allSatisfy { !$0.isSkipped })
        XCTAssertEqual(destination.exercises.flatMap(\.sets).map(\.order), [0, 0])
        XCTAssertEqual(destination.exercises.flatMap(\.sets).map(\.reps), [5, 8])
        XCTAssertEqual(destination.exercises.flatMap(\.sets).map(\.weight), [60, 0])
        XCTAssertEqual(destination.exercises.flatMap(\.sets).map(\.timeSeconds), [0, 45])
        XCTAssertTrue(destination.exercises.flatMap(\.sets).allSatisfy {
            !$0.isCompleted && $0.actualReps == nil && $0.actualWeight == nil && $0.actualTimeSeconds == nil && $0.completedAt == nil
        })
        XCTAssertEqual(destination.exercises.flatMap(\.sets).map(\.id), expectedCopiedSetIDs)
        XCTAssertTrue(Set(destination.exercises.map(\.id)).isDisjoint(with: Set(sourceBeforeCopy.exercises.map(\.id))))
        XCTAssertTrue(Set(destination.exercises.flatMap(\.sets).map(\.id)).isDisjoint(with: Set(sourceBeforeCopy.exercises.flatMap(\.sets).map(\.id))))
        XCTAssertEqual(viewModel.selectedDate, destinationDate)

        let copiedSetID = try XCTUnwrap(destination.exercises.first?.sets.first?.id)
        let copiedExerciseID = try XCTUnwrap(destination.exercises.first?.id)
        try viewModel.editSet(copiedSetID, in: copiedExerciseID, on: destinationDate, reps: 12, weight: 0, timeSeconds: 60)
        XCTAssertEqual(repository.workout(on: sourceDate), sourceBeforeCopy)
        XCTAssertEqual(repository.workout(on: destinationDate)?.exercises.first?.sets.first?.reps, 12)
    }

    func testCopyWorkoutRejectsMissingSameAndOccupiedDestinationsWithoutMutation() throws {
        let sourceDate = LocalDate(year: 2026, month: 8, day: 14)
        let occupiedDate = LocalDate(year: 2026, month: 8, day: 15)
        let missingDate = LocalDate(year: 2026, month: 8, day: 16)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        _ = repository.createEmptyWorkout(on: sourceDate, at: .distantPast)
        _ = repository.createEmptyWorkout(on: occupiedDate, at: .distantPast)
        let viewModel = WorkoutViewModel(repository: repository, initialDate: sourceDate, currentDate: sourceDate, calendar: mondayCalendar())
        let repositoryBefore = repository.workouts
        let viewModelBefore = viewModel.workouts

        XCTAssertThrowsError(try viewModel.copyWorkout(from: missingDate, to: LocalDate(year: 2026, month: 8, day: 17))) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .workoutNotFound(missingDate))
        }
        XCTAssertThrowsError(try viewModel.copyWorkout(from: sourceDate, to: sourceDate)) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .copyDestinationMatchesSource(sourceDate))
        }
        XCTAssertThrowsError(try viewModel.copyWorkout(from: sourceDate, to: occupiedDate)) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .copyDestinationOccupied(occupiedDate))
        }

        XCTAssertEqual(repository.workouts, repositoryBefore)
        XCTAssertEqual(viewModel.workouts, viewModelBefore)
        XCTAssertEqual(viewModel.selectedDate, sourceDate)
    }

    func testRepeatWorkoutCreatesIndependentPlanOnlyCopiesAndSkipsOccupiedDates() throws {
        let sourceDate = LocalDate(year: 2026, month: 8, day: 14)
        let occupiedDate = LocalDate(year: 2026, month: 8, day: 28)
        let endDate = LocalDate(year: 2026, month: 9, day: 11)
        let timestamp = Date(timeIntervalSince1970: 54_321)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        var source = repository.createEmptyWorkout(on: sourceDate, at: .distantPast).workout
        var completedSet = WorkoutSet(order: 6, reps: 8, weight: 40, timeSeconds: 0)
        completedSet.complete(at: .distantPast)
        completedSet.editActual(reps: 7, weight: 35, timeSeconds: 0)
        source.exercises = [WorkoutExercise(
            id: WorkoutExerciseID(),
            exerciseID: ExerciseID(),
            customName: "Custom press",
            order: 4,
            isSkipped: true,
            sets: [completedSet]
        )]
        try repository.save(source)
        let occupied = repository.createEmptyWorkout(on: occupiedDate, at: .distantPast).workout
        let sourceBeforeRepeat = try XCTUnwrap(repository.workout(on: sourceDate))
        let copiedExerciseIDs = [WorkoutExerciseID(), WorkoutExerciseID(), WorkoutExerciseID()]
        let copiedSetIDs = [WorkoutSetID(), WorkoutSetID(), WorkoutSetID()]
        var exerciseIDs = copiedExerciseIDs
        var setIDs = copiedSetIDs
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: sourceDate,
            currentDate: sourceDate,
            calendar: mondayCalendar(),
            now: { timestamp },
            makeWorkoutExerciseID: { exerciseIDs.removeFirst() },
            makeWorkoutSetID: { setIDs.removeFirst() }
        )

        let result = try viewModel.repeatWorkout(from: sourceDate, through: endDate)

        let expectedDates = [
            LocalDate(year: 2026, month: 8, day: 21),
            LocalDate(year: 2026, month: 9, day: 4),
            LocalDate(year: 2026, month: 9, day: 11)
        ]
        XCTAssertEqual(result.createdDates, expectedDates)
        XCTAssertEqual(result.skippedOccupiedDates, [occupiedDate])
        XCTAssertEqual(repository.workout(on: sourceDate), sourceBeforeRepeat)
        XCTAssertEqual(repository.workout(on: occupiedDate), occupied)
        XCTAssertEqual(viewModel.selectedDate, sourceDate)

        let copies = try expectedDates.map { try XCTUnwrap(repository.workout(on: $0)) }
        XCTAssertEqual(copies.map(\.createdAt), Array(repeating: timestamp, count: 3))
        XCTAssertEqual(copies.map(\.updatedAt), Array(repeating: timestamp, count: 3))
        XCTAssertEqual(copies.compactMap { $0.exercises.first?.id }, copiedExerciseIDs)
        XCTAssertEqual(copies.compactMap { $0.exercises.first?.sets.first?.id }, copiedSetIDs)
        XCTAssertTrue(Set(copiedExerciseIDs).isDisjoint(with: Set(sourceBeforeRepeat.exercises.map(\.id))))
        XCTAssertTrue(Set(copiedSetIDs).isDisjoint(with: Set(sourceBeforeRepeat.exercises.flatMap(\.sets).map(\.id))))
        XCTAssertTrue(copies.allSatisfy { copy in
            guard let exercise = copy.exercises.first, let set = exercise.sets.first else { return false }
            return exercise.order == 0
                && exercise.customName == "Custom press"
                && !exercise.isSkipped
                && set.order == 0
                && set.reps == 8
                && set.weight == 40
                && !set.isCompleted
                && set.actualReps == nil
                && set.actualWeight == nil
                && set.actualTimeSeconds == nil
                && set.completedAt == nil
        })

        let firstCopy = try XCTUnwrap(repository.workout(on: expectedDates[0]))
        let firstExerciseID = try XCTUnwrap(firstCopy.exercises.first?.id)
        let firstSetID = try XCTUnwrap(firstCopy.exercises.first?.sets.first?.id)
        try viewModel.editSet(firstSetID, in: firstExerciseID, on: expectedDates[0], reps: 12, weight: 50, timeSeconds: 0)
        XCTAssertEqual(repository.workout(on: sourceDate), sourceBeforeRepeat)
        XCTAssertEqual(repository.workout(on: expectedDates[1])?.exercises.first?.sets.first?.reps, 8)
        XCTAssertEqual(repository.workout(on: expectedDates[0])?.exercises.first?.sets.first?.reps, 12)
    }

    func testRepeatWorkoutUsesWeeklyDatesThroughInclusiveEndAndRejectsInvalidEndWithoutMutation() throws {
        let sourceDate = LocalDate(year: 2026, month: 12, day: 18)
        let untilDate = LocalDate(year: 2027, month: 1, day: 14)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        _ = repository.createEmptyWorkout(on: sourceDate, at: .distantPast)
        let viewModel = WorkoutViewModel(repository: repository, initialDate: sourceDate, currentDate: sourceDate, calendar: mondayCalendar())

        let result = try viewModel.repeatWorkout(from: sourceDate, through: untilDate)
        XCTAssertEqual(result.createdDates, [
            LocalDate(year: 2026, month: 12, day: 25),
            LocalDate(year: 2027, month: 1, day: 1),
            LocalDate(year: 2027, month: 1, day: 8)
        ])

        let workoutsBeforeInvalidRepeat = repository.workouts
        XCTAssertThrowsError(try viewModel.repeatWorkout(from: sourceDate, through: sourceDate)) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .repeatEndDateMustFollowSource(sourceDate))
        }
        XCTAssertThrowsError(try viewModel.repeatWorkout(from: LocalDate(year: 2026, month: 12, day: 17), through: untilDate)) { error in
            XCTAssertEqual(error as? ProgramPlanningError, .workoutNotFound(LocalDate(year: 2026, month: 12, day: 17)))
        }
        XCTAssertEqual(repository.workouts, workoutsBeforeInvalidRepeat)
    }

    func testRepeatWorkoutCreatesExactlyEightFutureWeeklyDates() throws {
        let sourceDate = LocalDate(year: 2026, month: 8, day: 14)
        let endDate = LocalDate(year: 2026, month: 10, day: 9)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        _ = repository.createEmptyWorkout(on: sourceDate, at: .distantPast)
        let viewModel = WorkoutViewModel(repository: repository, initialDate: sourceDate, currentDate: sourceDate, calendar: mondayCalendar())

        let result = try viewModel.repeatWorkout(from: sourceDate, through: endDate)
        XCTAssertEqual(result.createdDates, [
            LocalDate(year: 2026, month: 8, day: 21),
            LocalDate(year: 2026, month: 8, day: 28),
            LocalDate(year: 2026, month: 9, day: 4),
            LocalDate(year: 2026, month: 9, day: 11),
            LocalDate(year: 2026, month: 9, day: 18),
            LocalDate(year: 2026, month: 9, day: 25),
            LocalDate(year: 2026, month: 10, day: 2),
            LocalDate(year: 2026, month: 10, day: 9)
        ])
        XCTAssertTrue(result.skippedOccupiedDates.isEmpty)
    }

    func testRefreshCurrentDateUsesInjectedProviderWithoutChangingProgramSelection() {
        let initialDate = LocalDate(year: 2026, month: 8, day: 14)
        let refreshedDate = LocalDate(year: 2026, month: 8, day: 15)
        var providedDate = initialDate
        let viewModel = WorkoutViewModel(
            repository: InMemoryWorkoutRepository(userID: UserID(rawValue: "user")),
            initialDate: initialDate,
            currentDate: initialDate,
            calendar: mondayCalendar(),
            currentDateProvider: { providedDate }
        )

        viewModel.select(LocalDate(year: 2026, month: 8, day: 21))
        viewModel.refreshCurrentDate()
        XCTAssertEqual(viewModel.currentDate, initialDate)

        providedDate = refreshedDate
        viewModel.refreshCurrentDate()

        XCTAssertEqual(viewModel.currentDate, refreshedDate)
        XCTAssertEqual(viewModel.calendarState.currentDate, refreshedDate)
        XCTAssertEqual(viewModel.selectedDate, LocalDate(year: 2026, month: 8, day: 21))
    }

    func testFailedTodaySaveLeavesSnapshotUnchangedAndCanBeRetried() throws {
        let date = LocalDate(year: 2026, month: 8, day: 14)
        let backingRepository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        var workout = backingRepository.createEmptyWorkout(on: date, at: .distantPast).workout
        let exerciseID = WorkoutExerciseID()
        let setID = WorkoutSetID()
        workout.exercises = [WorkoutExercise(
            id: exerciseID,
            exerciseID: SystemExerciseCatalog.all[0].id,
            customName: nil,
            order: 0,
            isSkipped: false,
            sets: [WorkoutSet(id: setID, order: 0, reps: 8, weight: 60, timeSeconds: 0)]
        )]
        try backingRepository.save(workout)
        let repository = FailingOnceWorkoutRepository(backing: backingRepository)
        let analytics = AnalyticsRecorder()
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: date,
            currentDate: date,
            calendar: mondayCalendar(),
            analytics: analytics
        )
        let snapshotBeforeFailure = viewModel.workouts

        repository.failNextSave = true
        XCTAssertThrowsError(try viewModel.toggleCompletion(of: setID, in: exerciseID, on: date))
        XCTAssertEqual(viewModel.workouts, snapshotBeforeFailure)
        XCTAssertEqual(backingRepository.workout(on: date), snapshotBeforeFailure.first)
        XCTAssertTrue(analytics.events.isEmpty)

        try viewModel.toggleCompletion(of: setID, in: exerciseID, on: date)
        XCTAssertTrue(viewModel.workout(on: date)?.exercises.first?.sets.first?.isCompleted == true)
        XCTAssertEqual(analytics.events, [.setCompleted, .workoutCompleted])

        repository.throwAfterNextSave = true
        XCTAssertThrowsError(try viewModel.toggleCompletion(of: setID, in: exerciseID, on: date))
        XCTAssertTrue(viewModel.workout(on: date)?.exercises.first?.sets.first?.isCompleted == false)
        XCTAssertEqual(analytics.events, [.setCompleted, .workoutCompleted])
    }

    func testTodayMutationFailureUsesSafeRetryCopy() {
        XCTAssertEqual(TodayMutationError.saveFailed.title, "Couldn't confirm this change")
        XCTAssertEqual(TodayMutationError.saveFailed.message, "Check your workout before trying again.")
    }

    func testTodayMutationsRejectYesterdayAfterCurrentDateRefresh() throws {
        let yesterday = LocalDate(year: 2026, month: 8, day: 14)
        let today = LocalDate(year: 2026, month: 8, day: 15)
        var providedDate = yesterday
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "user"))
        var workout = repository.createEmptyWorkout(on: yesterday, at: .distantPast).workout
        let exerciseID = WorkoutExerciseID()
        let setID = WorkoutSetID()
        workout.exercises = [WorkoutExercise(
            id: exerciseID,
            exerciseID: SystemExerciseCatalog.all[0].id,
            customName: nil,
            order: 0,
            isSkipped: false,
            sets: [WorkoutSet(id: setID, order: 0, reps: 8, weight: 60, timeSeconds: 0)]
        )]
        try repository.save(workout)
        let viewModel = WorkoutViewModel(
            repository: repository,
            initialDate: yesterday,
            currentDate: yesterday,
            calendar: mondayCalendar(),
            currentDateProvider: { providedDate }
        )

        providedDate = today
        viewModel.refreshCurrentDate()

        XCTAssertEqual(TodayContentState.resolve(workouts: viewModel.workouts, currentDate: viewModel.currentDate), .restDay)
        let mutations: [() throws -> Void] = [
            { try viewModel.toggleCompletion(of: setID, in: exerciseID, on: yesterday) },
            { try viewModel.editTodaySet(setID, in: exerciseID, on: yesterday, reps: 7, weight: 60, timeSeconds: 0) },
            { try viewModel.skipTodayExercise(exerciseID, on: yesterday) },
            { try viewModel.restoreTodayExercise(exerciseID, on: yesterday) }
        ]
        for mutation in mutations {
            XCTAssertThrowsError(try mutation()) { error in
                XCTAssertEqual(error as? ProgramPlanningError, .todayActionRequiresCurrentDate(yesterday))
            }
        }
        XCTAssertEqual(repository.workout(on: yesterday), workout)
    }

    private func mondayCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Copenhagen")!
        calendar.firstWeekday = 2
        return calendar
    }

    private func planningExercise(
        id: WorkoutExerciseID,
        catalogIndex: Int,
        order: Int,
        reps: Int
    ) -> WorkoutExercise {
        WorkoutExercise(
            id: id,
            exerciseID: SystemExerciseCatalog.all[catalogIndex].id,
            customName: nil,
            order: order,
            isSkipped: false,
            sets: [WorkoutSet(order: 0, reps: reps)]
        )
    }
}

private final class FailingOnceWorkoutRepository: WorkoutRepository {
    enum Failure: Error { case saveFailed }

    let backing: InMemoryWorkoutRepository
    var failNextSave = false
    var throwAfterNextSave = false

    init(backing: InMemoryWorkoutRepository) {
        self.backing = backing
    }

    var userID: UserID { backing.userID }
    var workouts: [Workout] { backing.workouts }
    func observeWorkouts(_ observer: @escaping @MainActor ([Workout], WorkoutLoadState) -> Void) -> WorkoutObservation {
        backing.observeWorkouts(observer)
    }

    func workout(on date: LocalDate) -> Workout? {
        backing.workout(on: date)
    }

    @discardableResult
    func createEmptyWorkout(on date: LocalDate, at timestamp: Date) -> WorkoutCreationResult {
        backing.createEmptyWorkout(on: date, at: timestamp)
    }

    func save(_ workout: Workout) throws {
        if failNextSave {
            failNextSave = false
            throw Failure.saveFailed
        }
        try backing.save(workout)
        if throwAfterNextSave {
            throwAfterNextSave = false
            throw Failure.saveFailed
        }
    }

    func deleteWorkout(on date: LocalDate) throws {
        try backing.deleteWorkout(on: date)
    }
}

@MainActor
private final class ControllableWorkoutRepository: WorkoutRepository {
    let userID: UserID
    private var observer: (@MainActor ([Workout], WorkoutLoadState) -> Void)?
    private(set) var workouts: [Workout] = []
    private var loadState: WorkoutLoadState = .loading

    init(userID: UserID) {
        self.userID = userID
    }

    func observeWorkouts(_ observer: @escaping @MainActor ([Workout], WorkoutLoadState) -> Void) -> WorkoutObservation {
        self.observer = observer
        observer(workouts, loadState)
        return ControllableWorkoutObservation { [weak self] in self?.observer = nil }
    }

    func publish(_ workouts: [Workout], state: WorkoutLoadState) {
        self.workouts = workouts
        loadState = state
        observer?(workouts, state)
    }

    func workout(on date: LocalDate) -> Workout? {
        workouts.first { $0.localDate == date }
    }

    @discardableResult
    func createEmptyWorkout(on date: LocalDate, at timestamp: Date) -> WorkoutCreationResult {
        fatalError("Not used by availability tests")
    }

    func save(_ workout: Workout) throws {
        guard workout.userID == userID else { throw WorkoutRepositoryError.ownerMismatch }
        workouts.removeAll { $0.localDate == workout.localDate }
        workouts.append(workout)
        observer?(workouts, loadState)
    }

    func deleteWorkout(on date: LocalDate) throws {
        fatalError("Not used by availability tests")
    }
}

@MainActor
private final class ControllableWorkoutObservation: WorkoutObservation {
    private var onCancel: (() -> Void)?

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() {
        onCancel?()
        onCancel = nil
    }

    deinit { MainActor.assumeIsolated { cancel() } }
}
