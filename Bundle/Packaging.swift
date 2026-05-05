import Foundation

// MARK: - PackagingIntent
/// A fully validated, immutable description of what will be built.
/// This is the single source of truth for package creation.
///
/// IMPORTANT:
/// - No UI logic
/// - No file system mutation
/// - No process execution
/// - No AppKit or SwiftUI imports
///
/// If a package is built, it MUST be built from a PackagingIntent.
struct PackagingIntent {

    // MARK: Identity

    /// Reference to the application being packaged
    let app: AppRef

    /// The macOS package identifier (NOT the app bundle identifier)
    let packageIdentifier: String

    /// The package version (derived from the app's Info.plist)
    let version: String

    // MARK: Installation

    /// Where the application will be installed
    let installLocation: URL

    // MARK: Output

    /// The final output path of the generated .pkg file
    let outputURL: URL

    // MARK: Behaviour Flags

    /// Whether uninstall support should be included
    let includeUninstallSupport: Bool

    /// Optional signing configuration
    let signing: SigningIntent?

    // MARK: Validation

    /// Validation results computed at intent creation time
    let validation: ValidationResult

    /// Convenience: intent is buildable only if validation passes
    var isValid: Bool {
        validation.isValid
    }
}

// MARK: - AppRef
/// A stable, UI‑independent reference to an application.
struct AppRef: Hashable {
    let name: String
    let bundleIdentifier: String?
    let sourceURL: URL
}

// MARK: - SigningIntent
/// Explicit description of how (and with what) the package should be signed.
struct SigningIntent: Hashable {
    let identityName: String
}

// MARK: - ValidationResult
/// Captures whether an intent is safe to build and any warnings encountered.
struct ValidationResult {
    let isValid: Bool
    let warnings: [ValidationWarning]

    static let valid = ValidationResult(isValid: true, warnings: [])
}

// MARK: - ValidationWarning
enum ValidationWarning: Hashable {
    case missingBundleIdentifier
    case derivedIdentifierUsed
    case missingVersion
    case unsignedPackage
    case uninstallSupportDisabled
}

extension ValidationWarning {
    var description: String {
        switch self {
        case .missingBundleIdentifier:  return "Application has no bundle identifier"
        case .derivedIdentifierUsed:    return "Package identifier was derived automatically"
        case .missingVersion:           return "Application version could not be determined"
        case .unsignedPackage:          return "Package will not be signed"
        case .uninstallSupportDisabled: return "Uninstall support is not included"
        }
    }
}

// MARK: - PackagingIntentDefaults
enum PackagingIntentDefaults {
    static let installLocation          = URL(fileURLWithPath: "/Applications")
    static let fallbackPackageNamespace = "com.bundle.unknown"
    static let packageIdentifierSuffix  = "pkg"
}

// MARK: - Builder Input
struct PackagingIntentInput {
    let app: AppRef
    let outputURL: URL
    let includeUninstallSupport: Bool
    let signing: SigningIntent?
}

// MARK: - Build Errors
enum PackagingIntentBuildError: Error, LocalizedError {
    case unreadableAppBundle
    case invalidPackageIdentifier
    case missingVersion

    var errorDescription: String? {
        switch self {
        case .unreadableAppBundle:      return "The selected application could not be read."
        case .invalidPackageIdentifier: return "A valid package identifier could not be generated."
        case .missingVersion:           return "The application does not define a version."
        }
    }
}

// MARK: - PackagingIntentBuilder
enum PackagingIntentBuilder {

    static func build(
        from input: PackagingIntentInput
    ) -> Result<PackagingIntent, PackagingIntentBuildError> {

        // 1. Load the application bundle
        guard let bundle = Bundle(url: input.app.sourceURL),
              let info = bundle.infoDictionary else {
            return .failure(.unreadableAppBundle)
        }

        var warnings: [ValidationWarning] = []

        // 2. Determine bundle identifier
        let bundleIdentifier = info["CFBundleIdentifier"] as? String

        if bundleIdentifier == nil {
            warnings.append(.missingBundleIdentifier)
            warnings.append(.derivedIdentifierUsed)
        }

        // 3. Generate package identifier (enterprise‑safe)
        let packageIdentifier: String

        if let bundleIdentifier {
            packageIdentifier = bundleIdentifier.lowercased()
        } else {
            let normalizedName = input.app.name
                .lowercased()
                .replacingOccurrences(of: " ", with: "")
            packageIdentifier =
                "\(PackagingIntentDefaults.fallbackPackageNamespace).\(normalizedName)"
        }

        guard packageIdentifier.contains(".") else {
            return .failure(.invalidPackageIdentifier)
        }

        // 4. Determine version
        let version =
            (info["CFBundleShortVersionString"] as? String)
            ?? (info["CFBundleVersion"] as? String)

        guard let version, !version.isEmpty else {
            warnings.append(.missingVersion)
            return .failure(.missingVersion)
        }

        // 5. Signing validation
        if input.signing == nil {
            warnings.append(.unsignedPackage)
        }

        // 6. Uninstall support validation
        if !input.includeUninstallSupport {
            warnings.append(.uninstallSupportDisabled)
        }

        // 7. Construct PackagingIntent
        let intent = PackagingIntent(
            app: input.app,
            packageIdentifier: packageIdentifier,
            version: version,
            installLocation: PackagingIntentDefaults.installLocation,
            outputURL: input.outputURL,
            includeUninstallSupport: input.includeUninstallSupport,
            signing: input.signing,
            validation: ValidationResult(
                isValid: true,
                warnings: warnings
            )
        )

        return .success(intent)
    }
}
