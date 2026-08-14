import SwiftUI

struct ContentView: View {
    @State private var selectedTab = AppTab.today

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle")
                }
                .tag(AppTab.today)

            ProgramView()
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

}

private enum AppTab: String {
    case today
    case program
    case settings
}

#Preview {
    ContentView()
}
