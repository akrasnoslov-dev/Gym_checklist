import Foundation
import SwiftUI

@MainActor
struct ContentView: View {
    @State private var selectedTab = AppTab.today
    @StateObject private var workoutViewModel: WorkoutViewModel

    init() {
        let calendar = Calendar.autoupdatingCurrent
        let today = Self.testReferenceDate ?? LocalDate(date: Date(), calendar: calendar)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "local-mvp-user"))
        Self.seedTodayWorkoutForUITests(in: repository, on: today)
        _workoutViewModel = StateObject(wrappedValue: WorkoutViewModel(
            repository: repository,
            initialDate: today,
            currentDate: today,
            calendar: calendar
        ))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(
                viewModel: workoutViewModel,
                currentDate: workoutViewModel.currentDate,
                calendar: workoutViewModel.calendar,
                onOpenProgram: openProgramForToday
            )
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle")
                }
                .tag(AppTab.today)

            ProgramView(viewModel: workoutViewModel)
                .tabItem {
                    Label("Program", systemImage: "calendar")
                }
                .tag(AppTab.program)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
    }

    private static var testReferenceDate: LocalDate? {
        guard let raw = ProcessInfo.processInfo.environment["UITEST_REFERENCE_DATE"] else { return nil }
        let values = raw.split(separator: "-").compactMap { Int($0) }
        guard values.count == 3, (1...12).contains(values[1]), (1...31).contains(values[2]) else { return nil }
        return LocalDate(year: values[0], month: values[1], day: values[2])
    }

    private static func seedTodayWorkoutForUITests(
        in repository: InMemoryWorkoutRepository,
        on date: LocalDate
    ) {
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
                    WorkoutSet(
                        id: WorkoutSetID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000101")!),
                        order: 0,
                        reps: 8,
                        weight: 60,
                        timeSeconds: 0
                    ),
                    WorkoutSet(
                        id: WorkoutSetID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000102")!),
                        order: 1,
                        reps: 10,
                        weight: 65,
                        timeSeconds: 0
                    )
                ]
            ),
            WorkoutExercise(
                id: WorkoutExerciseID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000002")!),
                exerciseID: SystemExerciseCatalog.all[6].id,
                customName: nil,
                order: 1,
                isSkipped: false,
                sets: [WorkoutSet(
                    id: WorkoutSetID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000201")!),
                    order: 0,
                    reps: 12,
                    weight: 0,
                    timeSeconds: 0
                )]
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

    private func openProgramForToday() {
        workoutViewModel.select(workoutViewModel.currentDate)
        selectedTab = .program
    }

    private static func seedRestDayProgramForUITests(
        in repository: InMemoryWorkoutRepository,
        on currentDate: LocalDate
    ) {
        guard ProcessInfo.processInfo.environment["UITEST_SEED_REST_DAY_PROGRAM"] == "1" else { return }
        let programDate = LocalDate(year: 2026, month: 8, day: 15)
        precondition(currentDate == LocalDate(year: 2026, month: 8, day: 14), "Rest-day UI test requires its fixed reference date")
        _ = repository.createEmptyWorkout(on: programDate, at: .distantPast)
    }

    private static func seedCompletionWorkoutForUITests(
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
                sets: [WorkoutSet(
                    id: WorkoutSetID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000101")!),
                    order: 0,
                    reps: 8,
                    weight: 60,
                    timeSeconds: 0
                )]
            ),
            WorkoutExercise(
                id: WorkoutExerciseID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000002")!),
                exerciseID: SystemExerciseCatalog.all[6].id,
                customName: nil,
                order: 1,
                isSkipped: false,
                sets: [WorkoutSet(
                    id: WorkoutSetID(rawValue: UUID(uuidString: "90000000-0000-4000-8000-000000000201")!),
                    order: 0,
                    reps: 12,
                    weight: 0,
                    timeSeconds: 0
                )]
            )
        ]
        do {
            try repository.save(workout)
        } catch {
            preconditionFailure("Could not seed the UI-test completion workout: \(error)")
        }
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
