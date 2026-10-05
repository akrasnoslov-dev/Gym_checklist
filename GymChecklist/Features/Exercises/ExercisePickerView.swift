import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var showsCustomExercise = false
    @State private var errorMessage: String?
    @AccessibilityFocusState private var accessibilityFocus: AccessibilityFocusTarget?

    let search: (String) -> [Exercise]
    let createCustom: (String) throws -> Exercise
    let onSelect: (Exercise) throws -> Void

    private var results: [Exercise] { search(query) }
    private var systemResults: [Exercise] { results.filter(\.isSystem) }
    private var customResults: [Exercise] { results.filter { !$0.isSystem } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showsCustomExercise = true
                    } label: {
                        HStack {
                            Text("Add custom exercise")
                                .font(.body.weight(.semibold))
                            Spacer()
                            Image(systemName: "plus")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundStyle(GymTheme.accentForeground)
                        .frame(minHeight: 44)
                    }
                    .accessibilityIdentifier("exercisePickerAddCustom")
                }

                if results.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: GymTheme.spacing8) {
                            Text("No exercises found")
                                .font(.headline)
                            Text("Add a custom exercise or try another search.")
                                .font(.subheadline)
                                .foregroundStyle(GymTheme.textSecondary)
                        }
                        .padding(.vertical, GymTheme.spacing8)
                        .accessibilityIdentifier("exercisePickerNoResults")
                    }
                }

                if !customResults.isEmpty {
                    Section("Your exercises") {
                        ForEach(customResults) { exercise in
                            exerciseButton(exercise)
                        }
                    }
                }

                if !systemResults.isEmpty {
                    Section("System exercises · \(systemResults.count)") {
                        ForEach(systemResults) { exercise in
                            exerciseButton(exercise)
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(GymTheme.destructive)
                            .accessibilityLabel("Error: \(errorMessage)")
                            .accessibilityFocused($accessibilityFocus, equals: .error)
                            .accessibilityIdentifier("exercisePickerError")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(GymTheme.surfaceBase)
            .navigationTitle("Add exercise")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search exercises"
            )
            .tint(GymTheme.accentForeground)
            .accessibilityIdentifier("exercisePicker")
            .onChange(of: errorMessage) { _, newValue in
                if newValue != nil { accessibilityFocus = .error }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(GymTheme.accentForeground)
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
            HStack(spacing: GymTheme.spacing12) {
                VStack(alignment: .leading, spacing: GymTheme.spacing4) {
                    Text(exercise.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(GymTheme.textPrimary)
                    if let category = exercise.category {
                        Text(category)
                            .font(.caption)
                            .foregroundStyle(GymTheme.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(GymTheme.accentForeground)
            }
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(exercise.isSystem ? "System exercise" : "Custom exercise")
        .accessibilityIdentifier("exercisePickerResult-\(exercise.id.rawValue.uuidString)")
    }
}

private enum AccessibilityFocusTarget: Hashable {
    case error
}

private struct CustomExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var errorMessage: String?
    @AccessibilityFocusState private var isErrorFocused: Bool

    let onSave: (String) throws -> Void

    init(initialName: String, onSave: @escaping (String) throws -> Void) {
        _name = State(initialValue: initialName)
        self.onSave = onSave
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GymTheme.spacing20) {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: GymTheme.spacing4) {
                        Text("Exercise name")
                            .font(.caption)
                            .foregroundStyle(GymTheme.textSecondary)
                        TextField("Exercise name", text: $name)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .onSubmit(save)
                            .accessibilityIdentifier("customExerciseName")
                    }
                    .padding(GymTheme.spacing16)
                }
                .background(
                    GymTheme.surfaceGrouped,
                    in: RoundedRectangle(cornerRadius: GymTheme.groupRadius, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: GymTheme.groupRadius, style: .continuous)
                        .stroke(GymTheme.borderSubtle, lineWidth: 1)
                }

                Text("This exercise will be saved to your library.")
                    .font(.footnote)
                    .foregroundStyle(GymTheme.textSecondary)

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(GymTheme.destructive)
                        .accessibilityLabel("Error: \(errorMessage)")
                        .accessibilityFocused($isErrorFocused)
                        .accessibilityIdentifier("customExerciseError")
                }

                Button("Add exercise", action: save)
                    .buttonStyle(GymPrimaryButtonStyle())
                    .disabled(normalizedName.isEmpty)
                    .opacity(normalizedName.isEmpty ? 0.55 : 1)
                    .accessibilityIdentifier("customExerciseSave")
            }
            .padding(GymTheme.spacing16)
        }
        .scrollDismissesKeyboard(.interactively)
        .gymPageBackground()
        .navigationTitle("Custom exercise")
        .navigationBarTitleDisplayMode(.large)
        .accessibilityIdentifier("customExerciseScreen")
        .onChange(of: errorMessage) { _, newValue in
            if newValue != nil { isErrorFocused = true }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .fontWeight(.semibold)
                    .foregroundStyle(GymTheme.accentForeground)
                    .accessibilityIdentifier("customExerciseCancel")
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
