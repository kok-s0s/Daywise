import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("物品", systemImage: "archivebox.fill")
                }
            StatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
        }
        .tint(Color(hex: "#2962FF"))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, configurations: config)
    ContentView()
        .modelContainer(container)
}
