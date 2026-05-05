import SwiftUI

struct TechnicalDetailsView: View {

    let intent: PackagingIntent
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded
        ) {
            VStack(alignment: .leading, spacing: 8) {

                detailRow(
                    title: "Application Name",
                    value: intent.app.name
                )

                detailRow(
                    title: "Bundle Identifier",
                    value: intent.packageIdentifier
                )

                detailRow(
                    title: "Version",
                    value: intent.version
                )

                detailRow(
                    title: "Install Location",
                    value: intent.installLocation.path
                )

                if !intent.validation.warnings.isEmpty {
                    Divider()

                    Text("Warnings")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    ForEach(intent.validation.warnings, id: \.self) { warning in
                        Text("• \(warning.description)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 8)

        } label: {
            Label("Technical Details", systemImage: "chevron.right")
                .font(.system(size: 12, weight: .medium))
        }
        .padding(16)
    }

    private func detailRow(title: String, value: String) -> some View {
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
