import Foundation
import AppKit
import Combine
import UniformTypeIdentifiers

final class BundleModel: ObservableObject {

    // MARK: - Types

    struct AppEntry: Identifiable, Hashable {
        let id = UUID()
        let displayName: String
        let path: String
        let icon: NSImage?
    }

    enum BuildState: Equatable {
        case idle
        case building
        case success(String)
        case failure(String)
    }

    // MARK: - Published State

    @Published var apps: [AppEntry] = []
    @Published var selectedApp: AppEntry?
    @Published var outputURL: URL?
    @Published var buildState: BuildState = .idle
    @Published var currentIntent: PackagingIntent?

    // MARK: - Derived State

    var filteredApps: [AppEntry] {
        apps
    }

    var canBuild: Bool {
        selectedApp != nil &&
        outputURL != nil &&
        buildState != .building
    }

    var outputLabel: String {
        outputURL?.path ?? "Choose destination…"
    }

    // MARK: - App Loading

    func loadApps() {
        let appsURL = URL(fileURLWithPath: "/Applications")

        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: appsURL,
            includingPropertiesForKeys: nil
        ) else { return }

        apps = urls
            .filter { $0.pathExtension == "app" }
            .map { url in
                AppEntry(
                    displayName: url.deletingPathExtension().lastPathComponent,
                    path: url.path,
                    icon: NSWorkspace.shared.icon(forFile: url.path)
                )
            }
            .sorted { $0.displayName < $1.displayName }
    }

    // MARK: - Output Handling

    func suggestOutput() {
        guard let app = selectedApp else { return }

        let desktopURL = FileManager.default
            .urls(for: .desktopDirectory, in: .userDomainMask)
            .first!

        outputURL = desktopURL
            .appendingPathComponent("\(app.displayName).pkg")
    }

    func chooseOutput() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.package]
        panel.nameFieldStringValue =
            selectedApp?.displayName.appending(".pkg") ?? "Package.pkg"

        panel.directoryURL = FileManager.default
            .urls(for: .desktopDirectory, in: .userDomainMask)
            .first!

        if panel.runModal() == .OK {
            outputURL = panel.url
        }
    }

    // MARK: - Build (intent-driven)

    func build() {
        guard let selectedApp, let outputURL else {
            buildState = .failure("Missing application or output destination.")
            return
        }

        let appURL = URL(fileURLWithPath: selectedApp.path)

        let appRef = AppRef(
            name: selectedApp.displayName,
            bundleIdentifier: Bundle(url: appURL)?.bundleIdentifier,
            sourceURL: appURL
        )

        let input = PackagingIntentInput(
            app: appRef,
            outputURL: outputURL,
            includeUninstallSupport: true,
            signing: nil
        )

        switch PackagingIntentBuilder.build(from: input) {

        case .success(let intent):
            guard intent.isValid else {
                buildState = .failure("Invalid packaging configuration.")
                return
            }

            currentIntent = intent
            executeBuild(using: intent)

        case .failure(let error):
            buildState = .failure(error.localizedDescription)
        }
    }

    // MARK: - Executor

    private func executeBuild(using intent: PackagingIntent) {
        buildState = .building

        Task.detached { [self] in
            let process = Process()
            process.executableURL =
                URL(fileURLWithPath: "/usr/bin/productbuild")

            process.arguments = [
                "--component",
                intent.app.sourceURL.path,
                intent.installLocation.path,
                intent.outputURL.path
            ]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()

                let status = process.terminationStatus
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(decoding: data, as: UTF8.self)

                await MainActor.run {
                    if status == 0 {
                        buildState = .success("Package created successfully")
                    } else {
                        buildState = .failure(
                            output.isEmpty
                            ? "Build failed (exit code \(status))"
                            : output
                        )
                    }
                }

            } catch {
                await MainActor.run {
                    buildState = .failure(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - ✅ STEP 1 FIX: reset()

    func reset() {
        buildState = .idle
        currentIntent = nil
    }
}
