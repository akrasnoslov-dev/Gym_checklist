import SwiftUI

struct ProgramView: View {
    var body: some View {
        Label("Program", systemImage: "calendar")
            .font(.title)
            .accessibilityIdentifier("programPlaceholder")
    }
}
