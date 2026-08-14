import Foundation
import SwiftUI

@MainActor
struct ContentView: View {
    @State private var selectedTab = AppTab.today
    @StateObject private var programViewModel: ProgramViewModel

    init() {
        let calendar = Calendar.autoupdatingCurrent
        let today = Self.testReferenceDate ?? LocalDate(date: Date(), calendar: calendar)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "local-mvp-user"))
        _programViewModel = StateObject(wrappedValue: ProgramViewModel(
            repository: repository,
            initialDate: today,
            currentDate: today,
            calendar: calendar
        ))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle")
                }
                .tag(AppTab.today)

            ProgramView(viewModel: programViewModel)
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
}

private enum AppTab: String {
    case today
    case program
    case settings
}

#Preview {
    ContentView()
}
