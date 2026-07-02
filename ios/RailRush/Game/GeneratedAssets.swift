import Foundation

/// Bundled asset set for one playable runner character.
struct RunnerCharacterAssets: Identifiable, Equatable {
    let id: String
    let displayName: String
    /// Asset-catalog image name for the character's card avatar (nil → SF Symbol fallback).
    let avatarImageName: String?
    let model: String
    let frontAxis: GeneratedModelAxis?
    let upAxis: GeneratedModelAxis
    let run: String?
    let jump: String?
    let slide: String?
    let fly: String?
    let knockDown: String?
    let idle: String?
}

/// One extra train visual style: bundled resource name plus optional persisted
/// front-axis metadata. nil frontAxis → directionless car; the length axis is
/// inferred from measured bounds at load time.
struct TrainStyleAsset {
    let model: String
    let frontAxis: GeneratedModelAxis?
}

/// Central registry of generated asset resource names and orientation metadata.
/// Resource names are finalized from the asset generation output — if a model or
/// animation is missing from the bundle the game falls back to procedural geometry.
enum GeneratedAssets {
    // MARK: 3D model resource names (bundled USDZ, no extension)

    static let runnerModel = "cartoon_street_runner"
    static let inspectorModel = "grumpy_security_officer"
    static let dogModel = "guard_dog"
    static let trainModel = "subway_train"
    /// Extra train style variants cycled through the obstacle pool for visual
    /// variety. Missing files are skipped so the base subway train remains the
    /// guaranteed fallback. (Two more styles — red express + vintage tram —
    /// were cancelled at the preview step by the user.)
    static let extraTrainStyles: [TrainStyleAsset] = [
        // Graffiti subway car — persisted metadata: front cab (windshield) on +X.
        TrainStyleAsset(model: "graffiti_subway_car", frontAxis: .positiveX),
        // Freight boxcar — symmetric/directionless; length axis inferred from bounds.
        TrainStyleAsset(model: "freight_boxcar", frontAxis: nil),
    ]
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
    // NOTE: generated track/ground tile models were removed — AI generation
    // repeatedly produced corrupted textures on flat tiled surfaces. The track
    // bed (dirt, rails, sleepers, moss) is now built procedurally in
    // TrackBuilder.addTrackBed for a guaranteed-clean Subway Surfers look.
    /// Additional building styles arranged into the front street row.
    static let shopBuildingModel: String? = "brick_shop_building"
    static let apartmentBuildingModel: String? = "city_apartment_building"
    /// Sidewalk curb strip cloned along both track edges. nil → the procedural
    /// gray containment wall remains as the fallback border.
    static let curbModel: String? = "sidewalk_curb"

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
    /// Curb is a modular tiled strip — directionless per generation metadata;
    /// the long axis is aligned to the track by measured bounds at placement.
    static let curbFrontAxis: GeneratedModelAxis? = nil
    static let curbUpAxis: GeneratedModelAxis = .positiveY

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

    static let runnerRun: String? = "cartoon_street_runner-anim-runfast"
    // Previous run loop kept as a bundled backup (not wired by default).
    static let runnerRunAlt: String? = "cartoon_street_runner-anim-run-fast-3-inplace"
    // Jump_Run generated successfully (earlier inplace jump variants failed on
    // Meshy's side). When this is non-nil, RunnerWorld plays the clip on jump
    // and skips the procedural front-flip fallback.
    static let runnerJump: String? = "cartoon_street_runner-anim-jump-run"
    // Alternate jump clip, kept as a bundled backup (not wired by default).
    static let runnerJumpAlt: String? = "cartoon_street_runner-anim-regular-jump"
    // Slide clip. The downloaded roll-dodge replacement was removed: it looked
    // bad and the boy's file actually contained the girl's model, so rolling
    // as Max swapped in the wrong character.
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

    // MARK: Playable character roster

    /// Original male runner, assembled from the legacy runner constants.
    static let boyCharacter = RunnerCharacterAssets(
        id: "boy",
        displayName: "Max",
        avatarImageName: "boy_spiky_orange_hair_avatar",
        model: runnerModel,
        frontAxis: runnerFrontAxis,
        upAxis: runnerUpAxis,
        run: runnerRun,
        jump: runnerJump,
        slide: runnerSlide,
        fly: runnerFly,
        knockDown: runnerKnockDown,
        idle: runnerIdle
    )

    /// Female runner (generated model, bundled under distinct girl file names
    /// to avoid colliding with the boy's resources). Falls back to procedural
    /// geometry if the files are ever missing.
    static let girlCharacter = RunnerCharacterAssets(
        id: "girl",
        displayName: "Ruby",
        avatarImageName: "girl_peace_sign_avatar",
        model: "cartoon_girl_runner",
        frontAxis: .positiveZ,
        upAxis: .positiveY,
        run: "cartoon_girl_runner-anim-runfast",
        jump: "cartoon_girl_runner-anim-jump-run",
        slide: "cartoon_girl_runner-anim-slide-light",
        fly: "cartoon_girl_runner-anim-bar-hang-idle",
        knockDown: "cartoon_girl_runner-anim-knock-down",
        idle: "cartoon_girl_runner-anim-idle"
    )

    static let characters: [RunnerCharacterAssets] = [boyCharacter, girlCharacter]

    static func character(withID id: String) -> RunnerCharacterAssets {
        characters.first { $0.id == id } ?? boyCharacter
    }
}
