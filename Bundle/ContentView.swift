import SwiftUI
import AppKit

// MARK: - Brand Gradient

extension LinearGradient {
    static let appBrand = LinearGradient(
        colors: [
            Color("BrandBlue"),
            Color("BrandTeal"),
            Color("BrandGreen")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - NSImage best rep helper

extension NSImage {
    func bestRepresentation(for size: CGFloat) -> NSImage {
        let pointSize = NSSize(width: size, height: size)
        let rep = bestRepresentation(for: NSRect(origin: .zero, size: pointSize), context: nil, hints: nil)
        let result = NSImage(size: pointSize)
        result.lockFocus()
        rep?.draw(in: NSRect(origin: .zero, size: pointSize))
        result.unlockFocus()
        return result
    }
}

// MARK: - Root View

struct ContentView: View {
    @StateObject private var model = BundleModel()

    var body: some View {
        VStack(spacing: 0) {
            AppBanner()

            Divider()

            HSplitView {
                AppListView(model: model)
                    .frame(minWidth: 200, idealWidth: 220, maxWidth: 260)

                RightPanel(model: model)
                    .frame(minWidth: 300)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            model.loadApps()
        }
    }
}

// MARK: - App Banner

struct AppBanner: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient.appBrand
                .overlay(
                    colorScheme == .dark
                        ? Color.black.opacity(0.08)
                        : Color.clear
                )

            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage.bestRepresentation(for: 48))
                    .resizable()
                    .frame(width: 48, height: 48)
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Bundle")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text("macOS .pkg packager")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                }

                Spacer()
            }
            .padding(.horizontal, 18)
        }
        .frame(height: 76)
        .cornerRadius(12)
        .padding([.horizontal, .top], 16)
    }
}

// MARK: - App List

struct AppListView: View {
    @ObservedObject var model: BundleModel

    var body: some View {
        List(
            model.filteredApps,
            selection: Binding(
                get: { model.selectedApp },
                set: { newValue in
                    model.selectedApp = newValue
                    DispatchQueue.main.async {
                        model.suggestOutput()
                        model.reset()
                    }
                }
            )
        ) { app in
            AppRow(app: app)
                .tag(app)
        }
        .listStyle(.sidebar)
    }
}

// MARK: - App Row

struct AppRow: View {
    let app: BundleModel.AppEntry

    var body: some View {
        HStack(spacing: 8) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            }

            Text(app.displayName)
                .font(.system(size: 13))
                .lineLimit(1)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Right Panel (SIMPLIFIED)

struct RightPanel: View {
    @ObservedObject var model: BundleModel
    @State private var showTechDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Application
            VStack(alignment: .leading, spacing: 6) {
                Label("Application", systemImage: "app.badge.checkmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                if let app = model.selectedApp {
                    Text(app.displayName)
                        .font(.system(size: 13))
                } else {
                    Text("Select an application from the sidebar")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)

            Divider()

            // Output Destination
            VStack(alignment: .leading, spacing: 6) {
                Label("Output Destination", systemImage: "arrow.down.doc")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack {
                    Text(model.outputLabel)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(
                            model.outputURL == nil ? .secondary : .primary
                        )
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button("Change…") {
                        model.chooseOutput()
                    }
                    .controlSize(.small)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            }
            .padding(16)

            // ✅ Technical Details (clean)
            if let intent = model.currentIntent {
                Divider()

                DisclosureGroup("Technical Details", isExpanded: $showTechDetails) {
                    VStack(alignment: .leading, spacing: 10) {

                        techRow("Application Name", intent.app.name)
                        techRow("Version", intent.version)
                        techRow("Install Location", intent.installLocation.path)

                        // Bundle Identifier + Copy
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bundle Identifier")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)

                            HStack {
                                Text(intent.packageIdentifier)
                                    .font(.system(size: 13, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.middle)

                                Spacer()

                                Button {
                                    let pb = NSPasteboard.general
                                    pb.clearContents()
                                    pb.setString(
                                        intent.packageIdentifier,
                                        forType: .string
                                    )
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                                .buttonStyle(.borderless)
                                .help("Copy bundle identifier")
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(16)
            }

            Spacer()

            Divider()

            BuildFooter(model: model)
                .padding(16)
        }
    }

    private func techRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 13, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

// MARK: - Build Footer

struct BuildFooter: View {
    @ObservedObject var model: BundleModel

    var body: some View {
        let buttonTitle =
            model.buildState == .building
            ? "Building…"
            : "Create Package"

        VStack(spacing: 8) {
            if !model.canBuild {
                Text("Select an app and destination to continue")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Button {
                model.build()
            } label: {
                Text(buttonTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!model.canBuild)
            .keyboardShortcut(.return, modifiers: .command)
        }
    }
}
