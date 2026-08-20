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

    static let inspectorModel = "grumpy_security_officer"
    static let dogModel = "guard_dog"
    /// Base train: the BEAT RUNNER festival graffiti car (purple + yellow
    /// splash livery). Persisted metadata: front cab on +X.
    static let trainModel = "festival_graffiti_train"
    /// Extra train style variants cycled through the obstacle pool for visual
    /// variety. Missing files are skipped so the base festival train remains
    /// the guaranteed fallback.
    static let extraTrainStyles: [TrainStyleAsset] = [
        // Graffiti subway car — persisted metadata: front cab (windshield) on +X.
        TrainStyleAsset(model: "graffiti_subway_car", frontAxis: .positiveX),
        // Freight boxcar — symmetric/directionless; length axis inferred from bounds.
        TrainStyleAsset(model: "freight_boxcar", frontAxis: nil),
        // Legacy gray subway train kept in the mix — directionless metadata.
        TrainStyleAsset(model: "subway_train", frontAxis: nil),
    ]
    /// Collectible currency: golden music note (replaces the old gold coin).
    static let coinModel = "golden_music_note"

    // MARK: Orientation metadata (from generation output)

    static let inspectorFrontAxis: GeneratedModelAxis? = .positiveZ
    static let inspectorUpAxis: GeneratedModelAxis = .positiveY
    static let dogFrontAxis: GeneratedModelAxis? = .positiveZ
    static let dogUpAxis: GeneratedModelAxis = .positiveY
    /// Festival train front cab faces +X (persisted metadata).
    static let trainFrontAxis: GeneratedModelAxis? = .positiveX
    static let trainUpAxis: GeneratedModelAxis = .positiveY
    /// Music note reads correctly from +Z; pickups Y-spin so no yaw fix needed.
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
    /// Festival street props: concert speaker stacks + conga drum sets lining
    /// both sides of the track. nil → prop is skipped.
    static let speakerStackModel: String? = "concert_speaker_stack"
    static let congaDrumsModel: String? = "conga_drums"

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
    /// Speaker cones face +Z (persisted metadata) — turned toward the track.
    static let speakerStackFrontAxis: GeneratedModelAxis? = .positiveZ
    static let speakerStackUpAxis: GeneratedModelAxis = .positiveY
    /// Congas are symmetric — directionless per persisted metadata.
    static let congaDrumsFrontAxis: GeneratedModelAxis? = nil
    static let congaDrumsUpAxis: GeneratedModelAxis = .positiveY

    // MARK: Sunset-festival environment set (bundled USDZ, no extension)

    /// Graffiti brick wall sections tiled along both track edges.
    /// nil → the curb/containment-wall fallback remains the border.
    static let grafWallModel: String? = "graffiti_brick_wall"
    /// Tropical palm trees flanking the track.
    static let palmTreeModel: String? = "tropical_palm_tree"
    /// Party balloon clusters accenting the walls.
    static let balloonClusterModel: String? = "party_balloon_cluster"
    /// Railway power poles carrying the sagging overhead wires.
    static let powerPoleModel: String? = "railway_power_pole"

    /// Wall murals face +Z (persisted metadata) — turned toward the track.
    static let grafWallFrontAxis: GeneratedModelAxis? = .positiveZ
    static let grafWallUpAxis: GeneratedModelAxis = .positiveY
    /// Palm is radially symmetric — directionless.
    static let palmTreeFrontAxis: GeneratedModelAxis? = nil
    static let palmTreeUpAxis: GeneratedModelAxis = .positiveY
    /// Balloon bouquet is directionless.
    static let balloonClusterFrontAxis: GeneratedModelAxis? = nil
    static let balloonClusterUpAxis: GeneratedModelAxis = .positiveY
    /// Utility pole is radially symmetric — directionless per persisted
    /// metadata; wires attach at fixed X offsets regardless of yaw.
    static let powerPoleFrontAxis: GeneratedModelAxis? = nil
    static let powerPoleUpAxis: GeneratedModelAxis = .positiveY

    // MARK: Jetpack power-up prop (bundled USDZ, no extension)

    /// Wearable jetpack model shown on the runner's back while flying.
    /// nil resource name → flight mode runs without a visible prop.
    static let jetpackModel: String? = "cartoon_jetpack"
    // Orientation metadata: thruster face is the front (+Z), harness straps on the back.
    static let jetpackFrontAxis: GeneratedModelAxis? = .positiveZ
    static let jetpackUpAxis: GeneratedModelAxis = .positiveY

    // MARK: Power-up pickup models (bundled USDZ, no extension)

    /// Floating pickup models on the track. nil resource name → procedural orb
    /// fallback. BEAT RUNNER set: spray paint can (note magnet), retro boombox
    /// (2x beat), glowing sneaker (Rocket Kicks super jump), wearable jetpack
    /// (flight). All pickups Y-spin on the track so no static yaw correction
    /// is applied.
    static let magnetPickupModel: String? = "spray_paint_can"
    static let doubleScorePickupModel: String? = "retro_boombox"
    static let superJumpPickupModel: String? = "glowing_sneaker"

    // MARK: Inspector animation resource names

    static let inspectorRun: String? = "grumpy_security_officer-anim-run-fast-3-inplace"
    static let inspectorIdle: String? = "grumpy_security_officer-anim-idle"

    // MARK: Playable character roster

    /// Jax — the BEAT RUNNER hero: dreadlock bun, tie-dye headband, paint-splash
    /// hoodie, purple cargo pants. Bundled under the distinct beat_boy_runner
    /// prefix (both generated characters export under the same canonical name,
    /// which would collide in Resources/).
    static let boyCharacter = RunnerCharacterAssets(
        id: "boy",
        displayName: "Jax",
        avatarImageName: "teenage_boy_dreadlocks_hoodie",
        model: "beat_boy_runner",
        frontAxis: .positiveZ,
        upAxis: .positiveY,
        run: "beat_boy_runner-anim-runfast",
        jump: "beat_boy_runner-anim-jump-run",
        slide: "beat_boy_runner-anim-slide-light",
        fly: "beat_boy_runner-anim-bar-hang-idle",
        knockDown: "beat_boy_runner-anim-knock-down",
        idle: "beat_boy_runner-anim-idle"
    )

    /// Roxy — pink bunches, teal crop top, green cargo shorts. Bundled under
    /// the distinct beat_girl_runner prefix for the same collision reason.
    static let girlCharacter = RunnerCharacterAssets(
        id: "girl",
        displayName: "Roxy",
        avatarImageName: "teenage_girl_pink_bunches",
        model: "beat_girl_runner",
        frontAxis: .positiveZ,
        upAxis: .positiveY,
        run: "beat_girl_runner-anim-runfast",
        jump: "beat_girl_runner-anim-jump-run",
        slide: "beat_girl_runner-anim-slide-light",
        fly: "beat_girl_runner-anim-bar-hang-idle",
        knockDown: "beat_girl_runner-anim-knock-down",
        idle: "beat_girl_runner-anim-idle"
    )

    static let characters: [RunnerCharacterAssets] = [boyCharacter, girlCharacter]

    static func character(withID id: String) -> RunnerCharacterAssets {
        characters.first { $0.id == id } ?? boyCharacter
    }
}
