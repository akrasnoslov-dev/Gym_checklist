import SwiftUI

struct TodayView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let currentDate: LocalDate
    let calendar: Calendar

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                header

                if let workout = viewModel.workout(on: currentDate), !workout.exercises.isEmpty {
                    ForEach(orderedExercises(in: workout).filter { !$0.isSkipped }) { exercise in
                        exerciseSection(exercise)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 20)
        }
        .accessibilityIdentifier("todayScreen")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Today")
                .font(.largeTitle.weight(.bold))
            Text(dateLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func exerciseSection(_ exercise: WorkoutExercise) -> some View {
        let sets = orderedSets(in: exercise)

        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.exerciseName(for: exercise))
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(sets) { set in
                    Button {
                        toggleCompletion(for: set, in: exercise)
                    } label: {
                        setRow(set)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("todaySet-\(set.id.rawValue.uuidString)")
                    .accessibilityValue(set.isCompleted ? "Completed" : "Incomplete")
                    if set.id != sets.last?.id {
                        Divider()
                    }
                }
            }
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func setRow(_ set: WorkoutSet) -> some View {
        HStack(spacing: 12) {
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(set.isCompleted ? Color.accentColor : Color.secondary)
            Text(setDescription(for: set))
                .font(.body)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func orderedExercises(in workout: Workout) -> [WorkoutExercise] {
        workout.exercises.sorted {
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.id.rawValue.uuidString < $1.id.rawValue.uuidString
        }
    }

    private func orderedSets(in exercise: WorkoutExercise) -> [WorkoutSet] {
        exercise.sets.sorted {
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.id.rawValue.uuidString < $1.id.rawValue.uuidString
        }
    }

    private func setDescription(for set: WorkoutSet) -> String {
        SetDisplayFormatter(unit: .kilograms).string(
            reps: set.displayedReps,
            weight: set.displayedWeight,
            timeSeconds: set.displayedTimeSeconds
        )
    }

    private var dateLabel: String {
        guard let date = currentDate.date(in: calendar) else { return currentDate.description }
        return date.formatted(.dateTime.weekday(.wide).month(.wide).day().year().locale(Locale(identifier: "en")))
    }

    private func toggleCompletion(for set: WorkoutSet, in exercise: WorkoutExercise) {
        do {
            try viewModel.toggleCompletion(of: set.id, in: exercise.id, on: currentDate)
        } catch {
            assertionFailure("Today set completion failed: \(error)")
        }
    }
}
