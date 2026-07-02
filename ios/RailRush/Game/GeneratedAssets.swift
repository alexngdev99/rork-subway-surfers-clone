import Foundation

/// Central registry of generated asset resource names and orientation metadata.
/// Resource names are finalized from the asset generation output — if a model or
/// animation is missing from the bundle the game falls back to procedural geometry.
enum GeneratedAssets {
    // MARK: 3D model resource names (bundled USDZ, no extension)

    static let runnerModel = "cartoon_street_runner"
    static let inspectorModel = "grumpy_security_officer"
    static let dogModel = "guard_dog"
    static let trainModel = "subway_train"
    static let coinModel = "gold_coin"

    // MARK: Orientation metadata (from generation output; defaults until finalized)

    static let runnerFrontAxis: GeneratedModelAxis? = .positiveZ
    static let runnerUpAxis: GeneratedModelAxis = .positiveY
    static let inspectorFrontAxis: GeneratedModelAxis? = .positiveZ
    static let inspectorUpAxis: GeneratedModelAxis = .positiveY
    static let dogFrontAxis: GeneratedModelAxis? = .positiveZ
    static let dogUpAxis: GeneratedModelAxis = .positiveY
    // Train orientation metadata unavailable — treat as directionless (no yaw correction).
    static let trainFrontAxis: GeneratedModelAxis? = nil
    static let trainUpAxis: GeneratedModelAxis = .positiveY
    static let coinFrontAxis: GeneratedModelAxis? = nil
    static let coinUpAxis: GeneratedModelAxis = .positiveY

    // MARK: Environment decor models (bundled USDZ, no extension)

    static let buildingModel = "graffiti_city_building"
    static let treeModel = "city_tree"
    static let lampModel = "railway_signal_lamp"

    // Decor orientation metadata (defaults until generation output is finalized)
    static let buildingFrontAxis: GeneratedModelAxis? = .positiveZ
    static let buildingUpAxis: GeneratedModelAxis = .positiveY
    static let treeFrontAxis: GeneratedModelAxis? = nil
    static let treeUpAxis: GeneratedModelAxis = .positiveY
    static let lampFrontAxis: GeneratedModelAxis? = .positiveZ
    static let lampUpAxis: GeneratedModelAxis = .positiveY

    // MARK: Runner animation resource names (nil when the clip was not generated)

    static let runnerRun: String? = "cartoon_street_runner-anim-run-fast-3-inplace"
    // Jump clip failed to bundle (Meshy USDZ missing) — keep the run loop during jumps.
    static let runnerJump: String? = nil
    static let runnerSlide: String? = "cartoon_street_runner-anim-slide-light"
    static let runnerKnockDown: String? = "cartoon_street_runner-anim-knock-down"
    static let runnerIdle: String? = "cartoon_street_runner-anim-idle"

    // MARK: Inspector animation resource names

    static let inspectorRun: String? = "grumpy_security_officer-anim-run-fast-3-inplace"
    static let inspectorIdle: String? = "grumpy_security_officer-anim-idle"
}
