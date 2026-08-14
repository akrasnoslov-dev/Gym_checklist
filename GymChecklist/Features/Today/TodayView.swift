import SwiftUI

struct TodayView: View {
    var body: some View {
        Label("Today", systemImage: "checkmark.circle")
            .font(.title)
            .accessibilityIdentifier("todayPlaceholder")
    }
}
