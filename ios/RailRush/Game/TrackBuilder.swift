import RealityKit
import UIKit

/// Builds the procedural subway environment: track segments, rails, sleepers,
/// side walls, city buildings, and the sky backdrop.
enum TrackBuilder {
    static let segmentLength: Float = 40
    static let laneXs: [Float] = [-2, 0, 2]

    /// Normalized prototype containers for generated environment decor.
    /// Loaded once at scene build; clones are placed on each track segment.
    struct DecorPrototypes {
        /// Street-row building styles, cycled across slots for variety.
        var buildings: [Entity] = []
        var tree: Entity?
        var lamp: Entity?
        /// One lane-width track surface tile (rails + sleepers + ballast).
        var trackTile: Entity?
        /// Z-length of the normalized track tile, for cloning along a segment.
        var trackTileLength: Float = 8
        /// Full-width dirt ground slab tile cloned along the track bed.
        var groundTile: Entity?
        /// Z-length of the normalized ground tile, for cloning along a segment.
        var groundTileLength: Float = 10
    }

    static var decorPrototypes = DecorPrototypes()

    /// Loads the generated environment models (if bundled) into normalized
    /// prototype containers ready for cloning. Missing models are skipped —
    /// procedural decor remains as the fallback.
    static func loadDecorPrototypes() async {
        if let visual = try? await Entity(named: GeneratedAssets.buildingModel) {
            let container = Entity()
            attachGeneratedModelVisual(
                visual,
                to: container,
                targetHeight: 8.5,
                localFrontAxis: GeneratedAssets.buildingFrontAxis,
                localUpAxis: GeneratedAssets.buildingUpAxis,
                desiredWorldForward: [0, 0, 1]
            )
            decorPrototypes.buildings.append(container)
        }
        if let name = GeneratedAssets.shopBuildingModel,
           let visual = try? await Entity(named: name) {
            let container = Entity()
            attachGeneratedModelVisual(
                visual,
                to: container,
                targetHeight: 6.8,
                localFrontAxis: GeneratedAssets.shopBuildingFrontAxis,
                localUpAxis: GeneratedAssets.shopBuildingUpAxis,
                desiredWorldForward: [0, 0, 1]
            )
            decorPrototypes.buildings.append(container)
        }
        if let name = GeneratedAssets.apartmentBuildingModel,
           let visual = try? await Entity(named: name) {
            let container = Entity()
            attachGeneratedModelVisual(
                visual,
                to: container,
                targetHeight: 10.5,
                localFrontAxis: GeneratedAssets.apartmentBuildingFrontAxis,
                localUpAxis: GeneratedAssets.apartmentBuildingUpAxis,
                desiredWorldForward: [0, 0, 1]
            )
            decorPrototypes.buildings.append(container)
        }
        if let name = GeneratedAssets.trackTileModel,
           let visual = try? await Entity(named: name) {
            loadTrackTilePrototype(visual)
        }
        if let name = GeneratedAssets.groundTileModel,
           let visual = try? await Entity(named: name) {
            loadGroundTilePrototype(visual)
        }
        if let visual = try? await Entity(named: GeneratedAssets.treeModel) {
            let container = Entity()
            attachGeneratedModelVisual(
                visual,
                to: container,
                targetHeight: 3.2,
                localFrontAxis: GeneratedAssets.treeFrontAxis,
                localUpAxis: GeneratedAssets.treeUpAxis
            )
            decorPrototypes.tree = container
        }
        if let visual = try? await Entity(named: GeneratedAssets.lampModel) {
            let container = Entity()
            attachGeneratedModelVisual(
                visual,
                to: container,
                targetHeight: 3.6,
                localFrontAxis: GeneratedAssets.lampFrontAxis,
                localUpAxis: GeneratedAssets.lampUpAxis,
                desiredWorldForward: [0, 0, 1]
            )
            decorPrototypes.lamp = container
        }
    }

    /// Normalizes the generated track tile: length runs along Z, width matches
    /// one lane's track bed, and the rail top surface sits just above ground.
    private static func loadTrackTilePrototype(_ visual: Entity) {
        let container = Entity()
        container.addChild(visual)

        // The tile has no persisted front metadata — infer the long axis from
        // real bounds so rails always run down the track (Z axis).
        var bounds = visual.visualBounds(relativeTo: container)
        if bounds.extents.x > bounds.extents.z {
            visual.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0]) * visual.orientation
            bounds = visual.visualBounds(relativeTo: container)
        }

        // Scale by WIDTH so the rail gauge visually matches one 2 m lane.
        let targetWidth: Float = 2.5
        visual.scale *= SIMD3<Float>(repeating: targetWidth / max(bounds.extents.x, 0.001))

        bounds = visual.visualBounds(relativeTo: container)
        // Center X/Z; sink the tile so the rail tops sit ~0.16 m above ground
        // (the ballast body hides inside the procedural bed below).
        visual.position -= SIMD3<Float>(bounds.center.x, bounds.max.y - 0.16, bounds.center.z)

        decorPrototypes.trackTile = container
        decorPrototypes.trackTileLength = max(bounds.extents.z, 2)
    }

    /// Normalizes the generated dirt ground slab: width spans the full track
    /// bed, length runs along Z, and the dirt top surface sits at ground level
    /// (just below rails/sleepers so nothing z-fights).
    private static func loadGroundTilePrototype(_ visual: Entity) {
        let container = Entity()
        container.addChild(visual)

        // No persisted front metadata — make the LONG side run down the track (Z).
        var bounds = visual.visualBounds(relativeTo: container)
        if bounds.extents.x > bounds.extents.z {
            visual.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0]) * visual.orientation
            bounds = visual.visualBounds(relativeTo: container)
        }

        // Scale by WIDTH so one tile covers the whole 9.6 m track bed.
        let targetWidth: Float = 9.6
        visual.scale *= SIMD3<Float>(repeating: targetWidth / max(bounds.extents.x, 0.001))

        bounds = visual.visualBounds(relativeTo: container)
        // Center X/Z; sink so the dirt top sits ~2 cm below rail bases.
        visual.position -= SIMD3<Float>(bounds.center.x, bounds.max.y + 0.02, bounds.center.z)

        decorPrototypes.groundTile = container
        decorPrototypes.groundTileLength = max(bounds.extents.z, 3)
    }

    private static let buildingPalette: [UIColor] = [
        UIColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1),
        UIColor(red: 0.36, green: 0.62, blue: 0.72, alpha: 1),
        UIColor(red: 0.85, green: 0.73, blue: 0.45, alpha: 1),
        UIColor(red: 0.62, green: 0.45, blue: 0.62, alpha: 1),
        UIColor(red: 0.42, green: 0.55, blue: 0.42, alpha: 1),
        UIColor(red: 0.78, green: 0.42, blue: 0.38, alpha: 1),
    ]

    /// One scrolling track segment; call `randomizeDecor(on:)` when recycling.
    static func makeSegment() -> Entity {
        let segment = Entity()

        if let ground = decorPrototypes.groundTile {
            // Generated dirt ground: clone the slab down the segment, plus a
            // thin dark base box underneath to hide any seams.
            let base = ModelEntity(
                mesh: .generateBox(size: [9.6, 0.2, segmentLength]),
                materials: [SimpleMaterial(color: UIColor(red: 0.34, green: 0.24, blue: 0.17, alpha: 1), roughness: 0.95, isMetallic: false)]
            )
            base.position = [0, -0.14, 0]
            segment.addChild(base)

            let step = decorPrototypes.groundTileLength * 0.98
            let count = Int((segmentLength / step).rounded(.up))
            for i in 0..<count {
                let clone = ground.clone(recursive: true)
                clone.position = [0, 0, -segmentLength / 2 + step * (Float(i) + 0.5)]
                segment.addChild(clone)
            }
        } else {
            // Procedural fallback ballast bed.
            let ballast = ModelEntity(
                mesh: .generateBox(size: [9.6, 0.2, segmentLength]),
                materials: [SimpleMaterial(color: UIColor(red: 0.26, green: 0.24, blue: 0.28, alpha: 1), roughness: 0.9, isMetallic: false)]
            )
            ballast.position = [0, -0.1, 0]
            segment.addChild(ballast)
        }

        if let tile = decorPrototypes.trackTile {
            // Generated track surface: clone the tile down each lane.
            let step = decorPrototypes.trackTileLength * 0.99
            let count = Int((segmentLength / step).rounded(.up))
            for laneX in laneXs {
                for i in 0..<count {
                    let clone = tile.clone(recursive: true)
                    clone.position = [laneX, 0, -segmentLength / 2 + step * (Float(i) + 0.5)]
                    segment.addChild(clone)
                }
            }
        } else {
            // Procedural fallback: rails + sleepers.
            let railMaterial = SimpleMaterial(color: UIColor(white: 0.75, alpha: 1), roughness: 0.35, isMetallic: true)
            for laneX in laneXs {
                for offset in [-0.62, 0.62] {
                    let rail = ModelEntity(
                        mesh: .generateBox(size: [0.09, 0.12, segmentLength]),
                        materials: [railMaterial]
                    )
                    rail.position = [laneX + Float(offset), 0.06, 0]
                    segment.addChild(rail)
                }
            }

            let sleeperMaterial = SimpleMaterial(color: UIColor(red: 0.35, green: 0.27, blue: 0.2, alpha: 1), roughness: 0.85, isMetallic: false)
            let sleeperCount = 16
            let spacing = segmentLength / Float(sleeperCount)
            for i in 0..<sleeperCount {
                let sleeper = ModelEntity(
                    mesh: .generateBox(size: [8.6, 0.06, 0.5]),
                    materials: [sleeperMaterial]
                )
                sleeper.position = [0, 0.01, -segmentLength / 2 + spacing * (Float(i) + 0.5)]
                segment.addChild(sleeper)
            }
        }

        // Side containment walls with graffiti-toned stripes
        for side in [Float(-1), 1] {
            let wall = ModelEntity(
                mesh: .generateBox(size: [0.5, 1.3, segmentLength]),
                materials: [SimpleMaterial(color: UIColor(red: 0.5, green: 0.52, blue: 0.6, alpha: 1), roughness: 0.8, isMetallic: false)]
            )
            wall.position = [side * 5.1, 0.65, 0]
            segment.addChild(wall)

            let stripe = ModelEntity(
                mesh: .generateBox(size: [0.52, 0.28, segmentLength]),
                materials: [UnlitMaterial(color: UIColor(red: 1.0, green: 0.45, blue: 0.1, alpha: 1))]
            )
            stripe.position = [side * 5.1, 0.9, 0]
            segment.addChild(stripe)
        }

        // Buildings container — populated by randomizeDecor
        let decor = Entity()
        decor.name = "segment_decor"
        segment.addChild(decor)

        // Generated decor clones — created ONCE per segment, repositioned on recycle.
        let generatedDecor = Entity()
        generatedDecor.name = "generated_decor"
        segment.addChild(generatedDecor)
        populateGeneratedDecor(in: generatedDecor)

        randomizeDecor(on: segment)

        return segment
    }

    /// Clones the loaded prototypes into a segment's generated-decor container.
    /// Each clone stores its side in the sign of its X position; randomizeDecor
    /// keeps the sign and re-rolls the rest.
    private static func populateGeneratedDecor(in container: Entity) {
        let buildings = decorPrototypes.buildings
        for (sideIndex, side) in [Float(-1), 1].enumerated() {
            // Street row: one building per slot, styles cycled so neighbors
            // and the two sides never mirror each other.
            if !buildings.isEmpty {
                for slot in 0..<3 {
                    let style = buildings[(slot + sideIndex * 2) % buildings.count]
                    let clone = style.clone(recursive: true)
                    clone.name = "gen_building_\(slot)"
                    clone.position = [side * 10, 0, 0]
                    container.addChild(clone)
                }
            }
            for index in 0..<2 {
                if let tree = decorPrototypes.tree {
                    let clone = tree.clone(recursive: true)
                    clone.name = "gen_tree"
                    clone.position = [side * 7, 0, Float(index) * 14 - 12]
                    container.addChild(clone)
                }
                if let lamp = decorPrototypes.lamp {
                    let clone = lamp.clone(recursive: true)
                    clone.name = "gen_lamp"
                    clone.position = [side * 5.85, 0, Float(index) * 20 - 10]
                    container.addChild(clone)
                }
            }
        }
    }

    /// Re-rolls the buildings so recycled segments look fresh.
    static func randomizeDecor(on segment: Entity) {
        randomizeGeneratedDecor(on: segment)
        guard let decor = segment.findEntity(named: "segment_decor") else { return }
        decor.children.forEach { $0.removeFromParent() }

        // Procedural filler buildings sit BEHIND the generated front row when
        // generated models are available; otherwise they stay close as before.
        let hasGeneratedRow = !decorPrototypes.buildings.isEmpty
        let xRange: ClosedRange<Float> = hasGeneratedRow ? 13.0...16.0 : 9.5...12.0

        for side in [Float(-1), 1] {
            var z: Float = -segmentLength / 2
            while z < segmentLength / 2 - 4 {
                let width = Float.random(in: 4.5...7)
                let height = Float.random(in: 6...16)
                let color = buildingPalette.randomElement() ?? .systemOrange
                let building = ModelEntity(
                    mesh: .generateBox(size: [width, height, Float.random(in: 5...8)]),
                    materials: [SimpleMaterial(color: color, roughness: 0.9, isMetallic: false)]
                )
                building.position = [side * Float.random(in: xRange), height / 2 - 0.2, z + width / 2]
                decor.addChild(building)

                // Simple rooftop block for skyline variety
                if Bool.random() {
                    let cap = ModelEntity(
                        mesh: .generateBox(size: [width * 0.4, 1.2, 2]),
                        materials: [SimpleMaterial(color: UIColor(white: 0.3, alpha: 1), roughness: 0.9, isMetallic: false)]
                    )
                    cap.position = [building.position.x, height + 0.4, z + width / 2]
                    decor.addChild(cap)
                }
                z += width + Float.random(in: 1...3)
            }
        }
    }

    /// Repositions the pre-cloned generated decor so recycled segments vary.
    /// Clones keep their side (sign of X); Z, distance band, scale, and facing
    /// are re-rolled. Buildings and lamps turn their front toward the track.
    private static func randomizeGeneratedDecor(on segment: Entity) {
        guard let container = segment.findEntity(named: "generated_decor") else { return }
        let halfLength = segmentLength / 2

        let slotWidth = segmentLength / 3

        for child in container.children {
            let side: Float = child.position.x < 0 ? -1 : 1
            // Prototype visuals are normalized to face +Z; turn toward track center.
            let faceTrack = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: SIMD3<Float>(-side, 0, 0))

            if child.name.hasPrefix("gen_building_"),
               let slot = Int(child.name.dropFirst("gen_building_".count)) {
                // Even street-row slots with light jitter keep the block tidy.
                let slotCenter = -halfLength + slotWidth * (Float(slot) + 0.5)
                child.position = [
                    side * Float.random(in: 9.3...10.6),
                    0,
                    slotCenter + Float.random(in: -2.2...2.2),
                ]
                child.scale = SIMD3<Float>(repeating: Float.random(in: 0.92...1.18))
                child.orientation = faceTrack
                continue
            }

            switch child.name {
            case "gen_tree":
                child.position = [side * Float.random(in: 6.4...7.8), 0, Float.random(in: -halfLength + 2 ... halfLength - 2)]
                child.scale = SIMD3<Float>(repeating: Float.random(in: 0.8...1.15))
                child.orientation = simd_quatf(angle: Float.random(in: 0...(2 * .pi)), axis: [0, 1, 0])
            case "gen_lamp":
                child.position = [side * 5.85, 0, Float.random(in: -halfLength + 3 ... halfLength - 3)]
                child.scale = SIMD3<Float>(repeating: 1)
                child.orientation = faceTrack
            default:
                break
            }
        }
    }

    /// Static distant backdrop: sky, sun, and skyline silhouettes.
    static func makeBackdrop() -> Entity {
        let backdrop = Entity()

        let sky = ModelEntity(
            mesh: .generatePlane(width: 400, height: 180),
            materials: [UnlitMaterial(color: UIColor(red: 0.45, green: 0.78, blue: 0.92, alpha: 1))]
        )
        sky.position = [0, 60, -110]
        backdrop.addChild(sky)

        let horizonGlow = ModelEntity(
            mesh: .generatePlane(width: 400, height: 26),
            materials: [UnlitMaterial(color: UIColor(red: 0.99, green: 0.85, blue: 0.55, alpha: 1))]
        )
        horizonGlow.position = [0, 10, -109]
        backdrop.addChild(horizonGlow)

        let sun = ModelEntity(
            mesh: .generateSphere(radius: 7),
            materials: [UnlitMaterial(color: UIColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1))]
        )
        sun.position = [26, 46, -108]
        backdrop.addChild(sun)

        // Distant skyline silhouettes
        let silhouette = UIColor(red: 0.35, green: 0.5, blue: 0.65, alpha: 1)
        for i in 0..<14 {
            let height = Float.random(in: 12...34)
            let tower = ModelEntity(
                mesh: .generateBox(size: [Float.random(in: 6...12), height, 4]),
                materials: [UnlitMaterial(color: silhouette)]
            )
            tower.position = [Float(i - 7) * 14 + Float.random(in: -3...3), height / 2, -100]
            backdrop.addChild(tower)
        }

        // Far ground filler so gaps between buildings don't show sky
        let farGround = ModelEntity(
            mesh: .generateBox(size: [400, 0.2, 140]),
            materials: [SimpleMaterial(color: UIColor(red: 0.32, green: 0.36, blue: 0.4, alpha: 1), roughness: 1, isMetallic: false)]
        )
        farGround.position = [0, -0.25, -60]
        backdrop.addChild(farGround)

        return backdrop
    }

    // MARK: Procedural fallbacks / obstacle geometry

    /// Fallback train when the generated model is unavailable.
    static func makeFallbackTrain() -> Entity {
        let train = Entity()
        let body = ModelEntity(
            mesh: .generateBox(size: [2.1, 2.4, 10], cornerRadius: 0.25),
            materials: [SimpleMaterial(color: UIColor(red: 0.2, green: 0.45, blue: 0.75, alpha: 1), roughness: 0.5, isMetallic: false)]
        )
        body.position = [0, 1.4, 0]
        train.addChild(body)
        let face = ModelEntity(
            mesh: .generateBox(size: [1.9, 1.9, 0.2], cornerRadius: 0.2),
            materials: [UnlitMaterial(color: UIColor(red: 0.98, green: 0.8, blue: 0.2, alpha: 1))]
        )
        face.position = [0, 1.3, 5.02]
        train.addChild(face)
        return train
    }

    /// Low hurdle barrier — jump over it.
    static func makeLowBarrier() -> Entity {
        let barrier = Entity()
        let barMaterial = UnlitMaterial(color: UIColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 1))
        let bar = ModelEntity(mesh: .generateBox(size: [1.8, 0.32, 0.22], cornerRadius: 0.06), materials: [barMaterial])
        bar.position = [0, 0.68, 0]
        barrier.addChild(bar)
        let stripe = ModelEntity(
            mesh: .generateBox(size: [1.82, 0.1, 0.24]),
            materials: [UnlitMaterial(color: .white)]
        )
        stripe.position = [0, 0.68, 0]
        barrier.addChild(stripe)
        let legMaterial = SimpleMaterial(color: UIColor(white: 0.35, alpha: 1), roughness: 0.7, isMetallic: false)
        for x in [Float(-0.8), 0.8] {
            let leg = ModelEntity(mesh: .generateBox(size: [0.12, 0.85, 0.12]), materials: [legMaterial])
            leg.position = [x, 0.42, 0]
            barrier.addChild(leg)
        }
        return barrier
    }

    /// Overhead barrier — slide under it.
    static func makeOverheadBarrier() -> Entity {
        let barrier = Entity()
        let postMaterial = SimpleMaterial(color: UIColor(white: 0.4, alpha: 1), roughness: 0.7, isMetallic: false)
        for x in [Float(-0.95), 0.95] {
            let post = ModelEntity(mesh: .generateBox(size: [0.14, 2.5, 0.14]), materials: [postMaterial])
            post.position = [x, 1.25, 0]
            barrier.addChild(post)
        }
        let panel = ModelEntity(
            mesh: .generateBox(size: [2.0, 1.0, 0.14], cornerRadius: 0.06),
            materials: [UnlitMaterial(color: UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1))]
        )
        panel.position = [0, 1.78, 0]
        barrier.addChild(panel)
        let arrow = ModelEntity(
            mesh: .generateBox(size: [1.4, 0.2, 0.16]),
            materials: [UnlitMaterial(color: .white)]
        )
        arrow.position = [0, 1.78, 0]
        barrier.addChild(arrow)
        return barrier
    }

    /// Spinning collectible coin.
    static func makeCoin() -> Entity {
        let coin = Entity()
        let disc = ModelEntity(
            mesh: .generateCylinder(height: 0.09, radius: 0.34),
            materials: [UnlitMaterial(color: UIColor(red: 1.0, green: 0.82, blue: 0.1, alpha: 1))]
        )
        // Stand the disc up so its face points down the track
        disc.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        let rim = ModelEntity(
            mesh: .generateCylinder(height: 0.1, radius: 0.24),
            materials: [UnlitMaterial(color: UIColor(red: 0.95, green: 0.65, blue: 0.05, alpha: 1))]
        )
        rim.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        coin.addChild(disc)
        coin.addChild(rim)
        return coin
    }

    /// Floating power-up pickup.
    static func makePowerUp(type: PowerUpType) -> Entity {
        let pickup = Entity()
        let color: UIColor
        switch type {
        case .magnet: color = UIColor(red: 0.2, green: 0.55, blue: 1.0, alpha: 1)
        case .doubleScore: color = UIColor(red: 1.0, green: 0.75, blue: 0.1, alpha: 1)
        case .jetpack: color = UIColor(red: 1.0, green: 0.4, blue: 0.15, alpha: 1)
        }
        let orb = ModelEntity(
            mesh: .generateSphere(radius: 0.42),
            materials: [UnlitMaterial(color: color)]
        )
        pickup.addChild(orb)
        let ring = ModelEntity(
            mesh: .generateCylinder(height: 0.06, radius: 0.56),
            materials: [UnlitMaterial(color: .white)]
        )
        pickup.addChild(ring)
        return pickup
    }

    /// Fallback dog when the generated model is unavailable.
    static func makeFallbackDog() -> Entity {
        let dog = Entity()
        let body = ModelEntity(
            mesh: .generateBox(size: [0.35, 0.4, 0.7], cornerRadius: 0.12),
            materials: [SimpleMaterial(color: UIColor(red: 0.6, green: 0.42, blue: 0.25, alpha: 1), roughness: 0.8, isMetallic: false)]
        )
        body.position = [0, 0.4, 0]
        dog.addChild(body)
        let head = ModelEntity(
            mesh: .generateBox(size: [0.3, 0.28, 0.3], cornerRadius: 0.1),
            materials: [SimpleMaterial(color: UIColor(red: 0.55, green: 0.38, blue: 0.22, alpha: 1), roughness: 0.8, isMetallic: false)]
        )
        head.position = [0, 0.62, -0.4]
        dog.addChild(head)
        return dog
    }

    /// Fallback humanoid capsule when a generated character is unavailable.
    static func makeFallbackHumanoid(color: UIColor) -> Entity {
        let figure = Entity()
        let body = ModelEntity(
            mesh: .generateBox(size: [0.55, 1.2, 0.4], cornerRadius: 0.18),
            materials: [SimpleMaterial(color: color, roughness: 0.7, isMetallic: false)]
        )
        body.position = [0, 0.9, 0]
        figure.addChild(body)
        let head = ModelEntity(
            mesh: .generateSphere(radius: 0.22),
            materials: [SimpleMaterial(color: UIColor(red: 0.95, green: 0.8, blue: 0.65, alpha: 1), roughness: 0.7, isMetallic: false)]
        )
        head.position = [0, 1.68, 0]
        figure.addChild(head)
        return figure
    }
}
