import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var showsCustomExercise = false
    @State private var errorMessage: String?

    let search: (String) -> [Exercise]
    let createCustom: (String) throws -> Exercise
    let onSelect: (Exercise) throws -> Void

    private var results: [Exercise] { search(query) }
    private var systemResults: [Exercise] { results.filter(\.isSystem) }
    private var customResults: [Exercise] { results.filter { !$0.isSystem } }

    var body: some View {
        NavigationStack {
            List {
                if results.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No exercises found")
                            .font(.headline)
                        Text("Add a custom exercise or try another search.")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier("exercisePickerNoResults")
                }

                if !customResults.isEmpty {
                    Section("Your exercises") {
                        ForEach(customResults) { exercise in
                            exerciseButton(exercise)
                        }
                    }
                }

                if !systemResults.isEmpty {
                    Section("Exercises") {
                        ForEach(systemResults) { exercise in
                            exerciseButton(exercise)
                        }
                    }
                }

                Section {
                    Button {
                        showsCustomExercise = true
                    } label: {
                        Label("Add custom exercise", systemImage: "plus")
                    }
                    .accessibilityIdentifier("exercisePickerAddCustom")
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("exercisePickerError")
                }
            }
            .navigationTitle("Add exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search exercises")
            .accessibilityIdentifier("exercisePicker")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("exercisePickerCancel")
                }
            }
            .navigationDestination(isPresented: $showsCustomExercise) {
                CustomExerciseView(initialName: normalizedQuery) { name in
                    let exercise = try createCustom(name)
                    try onSelect(exercise)
                    dismiss()
                }
            }
        }
    }

    private var normalizedQuery: String {
        query.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    private func exerciseButton(_ exercise: Exercise) -> some View {
        Button {
            do {
                try onSelect(exercise)
                dismiss()
            } catch {
                errorMessage = "Exercise could not be added. Try again."
            }
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                if let category = exercise.category {
                    Text(category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(exercise.isSystem ? "System exercise" : "Custom exercise")
        .accessibilityIdentifier("exercisePickerResult-\(exercise.id.rawValue.uuidString)")
    }
}

private struct CustomExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var errorMessage: String?

    let onSave: (String) throws -> Void

    init(initialName: String, onSave: @escaping (String) throws -> Void) {
        _name = State(initialValue: initialName)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section("Exercise") {
                TextField("Exercise name", text: $name)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit(save)
                    .accessibilityIdentifier("customExerciseName")
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("customExerciseError")
            }
        }
        .navigationTitle("Custom exercise")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("customExerciseScreen")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .accessibilityIdentifier("customExerciseCancel")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add", action: save)
                    .disabled(normalizedName.isEmpty)
                    .accessibilityIdentifier("customExerciseSave")
            }
        }
    }

    private var normalizedName: String {
        name.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    private func save() {
        guard !normalizedName.isEmpty else {
            errorMessage = "Enter an exercise name."
            return
        }
        do {
            try onSave(name)
        } catch {
            errorMessage = "Exercise could not be added. Try again."
        }
    }
}
