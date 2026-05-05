import SwiftUI

@main
struct BundleApp: App {

    @AppStorage("appAppearance")
    private var appearance: AppAppearance = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearance.colorScheme)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 560, height: 620)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        // ✅ Proper macOS Settings window (⌘,)
        Settings {
            Form {
                Picker("Appearance", selection: $appearance) {
                    Text("System").tag(AppAppearance.system)
                    Text("Light").tag(AppAppearance.light)
                    Text("Dark").tag(AppAppearance.dark)
                }
                .pickerStyle(.radioGroup)
            }
            .padding(20)
            .frame(width: 300)
        }
    }
}
