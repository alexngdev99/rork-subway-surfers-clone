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
    /// Generated railway track surface tile (rails + sleepers + ballast).
    /// Regenerated as a clean low-poly tile — the first version had corrupted
    /// spiky rail geometry. nil resource name → procedural rails fallback.
    static let trackTileModel: String? = "railway_track_clean"
    /// Additional building styles arranged into the front street row.
    static let shopBuildingModel: String? = "brick_shop_building"
    static let apartmentBuildingModel: String? = "city_apartment_building"

    // Decor orientation metadata (defaults until generation output is finalized)
    static let buildingFrontAxis: GeneratedModelAxis? = .positiveZ
    static let buildingUpAxis: GeneratedModelAxis = .positiveY
    static let shopBuildingFrontAxis: GeneratedModelAxis? = .positiveZ
    static let shopBuildingUpAxis: GeneratedModelAxis = .positiveY
    static let apartmentBuildingFrontAxis: GeneratedModelAxis? = .positiveZ
    static let apartmentBuildingUpAxis: GeneratedModelAxis = .positiveY
    static let treeFrontAxis: GeneratedModelAxis? = nil
    static let treeUpAxis: GeneratedModelAxis = .positiveY
    static let lampFrontAxis: GeneratedModelAxis? = .positiveZ
    static let lampUpAxis: GeneratedModelAxis = .positiveY

    // MARK: Jetpack power-up prop (bundled USDZ, no extension)

    /// Wearable jetpack model shown on the runner's back while flying.
    /// nil resource name → flight mode runs without a visible prop.
    static let jetpackModel: String? = "cartoon_jetpack"
    // Orientation metadata: thruster face is the front (+Z), harness straps on the back.
    static let jetpackFrontAxis: GeneratedModelAxis? = .positiveZ
    static let jetpackUpAxis: GeneratedModelAxis = .positiveY

    // MARK: Power-up pickup models (bundled USDZ, no extension)

    /// Floating pickup models on the track. nil resource name → procedural orb
    /// fallback. The jetpack pickup reuses `jetpackModel`.
    /// Magnet: directionless prop (no intrinsic front) — no yaw correction.
    /// 2X badge: front face (+Z) shows the "2X" text; the pickup Y-spin keeps
    /// it readable from every side so no static yaw correction is applied.
    static let magnetPickupModel: String? = "magnet_powerup"
    static let doubleScorePickupModel: String? = "double_score_badge"

    // MARK: Runner animation resource names (nil when the clip was not generated)

    static let runnerRun: String? = "cartoon_street_runner-anim-run-fast-3-inplace"
    // Jump_Run generated successfully (earlier inplace jump variants failed on
    // Meshy's side). When this is non-nil, RunnerWorld plays the clip on jump
    // and skips the procedural front-flip fallback.
    static let runnerJump: String? = "cartoon_street_runner-anim-jump-run"
    // Alternate jump clip, kept as a bundled backup (not wired by default).
    static let runnerJumpAlt: String? = "cartoon_street_runner-anim-regular-jump"
    static let runnerSlide: String? = "cartoon_street_runner-anim-slide-light"
    /// Airborne hang pose looped while the jetpack power-up is active.
    /// nil → the run loop keeps playing in the air (pre-generation fallback).
    static let runnerFly: String? = "cartoon_street_runner-anim-bar-hang-idle"
    /// Alternate hang clip kept as a bundled backup (not wired by default).
    static let runnerFlyAlt: String? = "cartoon_street_runner-anim-rope-hang-idle"
    static let runnerKnockDown: String? = "cartoon_street_runner-anim-knock-down"
    static let runnerIdle: String? = "cartoon_street_runner-anim-idle"

    // MARK: Inspector animation resource names

    static let inspectorRun: String? = "grumpy_security_officer-anim-run-fast-3-inplace"
    static let inspectorIdle: String? = "grumpy_security_officer-anim-idle"
}
