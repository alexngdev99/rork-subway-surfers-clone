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
        /// Sidewalk curb strip cloned along both track edges.
        var curb: Entity?
        /// Festival props lining the street: concert speaker stacks + congas.
        var speaker: Entity?
        var conga: Entity?
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
        if let name = GeneratedAssets.curbModel,
           let visual = try? await Entity(named: name) {
            let container = Entity()
            // Normalize by the curb's HEIGHT (small Y extent) so the raised
            // block reads at real-world curb scale; the strip length is
            // measured from bounds at placement time. Directionless model —
            // no front-axis yaw correction.
            attachGeneratedModelVisual(
                visual,
                to: container,
                targetHeight: 0.55,
                localFrontAxis: GeneratedAssets.curbFrontAxis,
                localUpAxis: GeneratedAssets.curbUpAxis
            )
            decorPrototypes.curb = container
        }
        if let name = GeneratedAssets.speakerStackModel,
           let visual = try? await Entity(named: name) {
            let container = Entity()
            attachGeneratedModelVisual(
                visual,
                to: container,
                targetHeight: 2.6,
                localFrontAxis: GeneratedAssets.speakerStackFrontAxis,
                localUpAxis: GeneratedAssets.speakerStackUpAxis,
                desiredWorldForward: [0, 0, 1]
            )
            decorPrototypes.speaker = container
        }
        if let name = GeneratedAssets.congaDrumsModel,
           let visual = try? await Entity(named: name) {
            let container = Entity()
            attachGeneratedModelVisual(
                visual,
                to: container,
                targetHeight: 1.15,
                localFrontAxis: GeneratedAssets.congaDrumsFrontAxis,
                localUpAxis: GeneratedAssets.congaDrumsUpAxis,
                desiredWorldForward: [0, 0, 1]
            )
            decorPrototypes.conga = container
        }
    }

    private static let buildingPalette: [UIColor] = [
        UIColor(red: 0.98, green: 0.56, blue: 0.20, alpha: 1),
        UIColor(red: 0.60, green: 0.34, blue: 0.86, alpha: 1),
        UIColor(red: 0.95, green: 0.40, blue: 0.62, alpha: 1),
        UIColor(red: 0.20, green: 0.72, blue: 0.70, alpha: 1),
        UIColor(red: 0.99, green: 0.78, blue: 0.28, alpha: 1),
        UIColor(red: 0.42, green: 0.52, blue: 0.92, alpha: 1),
    ]

    /// Confetti / streamer festival palette shared by trusses and bunting.
    static let festivalPalette: [UIColor] = [
        UIColor(red: 0.94, green: 0.26, blue: 0.62, alpha: 1),
        UIColor(red: 1.0, green: 0.80, blue: 0.22, alpha: 1),
        UIColor(red: 0.25, green: 0.85, blue: 0.78, alpha: 1),
        UIColor(red: 0.62, green: 0.36, blue: 0.95, alpha: 1),
        UIColor(red: 1.0, green: 0.52, blue: 0.16, alpha: 1),
    ]

    /// One scrolling track segment; call `randomizeDecor(on:)` when recycling.
    static func makeSegment() -> Entity {
        let segment = Entity()

        addTrackBed(to: segment)

        if let curb = decorPrototypes.curb {
            // Generated sidewalk curb strips line both edges of the track.
            addCurbRows(from: curb, to: segment)
        } else {
            // Fallback: side containment walls with graffiti-toned stripes.
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

        // Concert light truss spanning the track once per segment, with
        // strings of bunting flags hanging off both sides.
        addLightTruss(to: segment, atZ: -segmentLength * 0.25)
        addBuntingLine(to: segment, atZ: segmentLength * 0.2, height: 4.6)

        randomizeDecor(on: segment)

        return segment
    }

    /// Concert lighting gantry: two side posts, a horizontal truss beam, and a
    /// row of colored stage-light boxes shining down on the track.
    private static func addLightTruss(to segment: Entity, atZ z: Float) {
        let truss = Entity()
        truss.position = [0, 0, z]

        let frameMaterial = SimpleMaterial(color: UIColor(red: 0.28, green: 0.26, blue: 0.34, alpha: 1), roughness: 0.55, isMetallic: true)
        for side in [Float(-1), 1] {
            let post = ModelEntity(mesh: .generateBox(size: [0.22, 5.6, 0.22]), materials: [frameMaterial])
            post.position = [side * 5.6, 2.8, 0]
            truss.addChild(post)
        }
        let beam = ModelEntity(mesh: .generateBox(size: [11.6, 0.3, 0.3]), materials: [frameMaterial])
        beam.position = [0, 5.45, 0]
        truss.addChild(beam)
        // Thin cross-brace under the beam for the truss look.
        let brace = ModelEntity(mesh: .generateBox(size: [11.6, 0.08, 0.08]), materials: [frameMaterial])
        brace.position = [0, 5.12, 0]
        truss.addChild(brace)

        // Colored stage-light cans hanging under the beam.
        let lightXs: [Float] = [-4.2, -2.1, 0, 2.1, 4.2]
        for (index, x) in lightXs.enumerated() {
            let color = festivalPalette[index % festivalPalette.count]
            let housing = ModelEntity(
                mesh: .generateBox(size: [0.34, 0.4, 0.34], cornerRadius: 0.06),
                materials: [SimpleMaterial(color: UIColor(white: 0.16, alpha: 1), roughness: 0.5, isMetallic: true)]
            )
            housing.position = [x, 4.9, 0]
            truss.addChild(housing)

            let lens = ModelEntity(
                mesh: .generateSphere(radius: 0.14),
                materials: [UnlitMaterial(color: color)]
            )
            lens.position = [x, 4.68, 0]
            truss.addChild(lens)
        }

        segment.addChild(truss)
    }

    /// A sagging string of colorful triangle bunting flags across the track.
    private static func addBuntingLine(to segment: Entity, atZ z: Float, height: Float) {
        let line = Entity()
        line.position = [0, 0, z]

        let wire = ModelEntity(
            mesh: .generateBox(size: [11.0, 0.03, 0.03]),
            materials: [UnlitMaterial(color: UIColor(white: 0.92, alpha: 1))]
        )
        wire.position = [0, height, 0]
        line.addChild(wire)

        let flagCount = 9
        for i in 0..<flagCount {
            let t = Float(i) / Float(flagCount - 1)
            let x = -5.0 + t * 10.0
            // Gentle catenary-ish sag toward the middle.
            let sag = sinf(t * .pi) * 0.55
            let color = festivalPalette[i % festivalPalette.count]
            let flag = ModelEntity(
                mesh: .generateBox(size: [0.36, 0.5, 0.02]),
                materials: [UnlitMaterial(color: color)]
            )
            flag.position = [x, height - 0.28 - sag, 0]
            flag.orientation = simd_quatf(angle: Float.random(in: -0.12...0.12), axis: [0, 0, 1])
            line.addChild(flag)
        }

        segment.addChild(line)
    }

    /// Subway Surfers-style track bed, built procedurally for a guaranteed
    /// clean look: packed brown dirt, per-lane red-brown sleepers with shiny
    /// purple-tinted rails, and moss patches + pebbles in the dirt strips.
    private static func addTrackBed(to segment: Entity) {
        // Full-width packed dirt bed; top surface sits at y = 0.
        let bed = ModelEntity(
            mesh: .generateBox(size: [9.6, 0.24, segmentLength]),
            materials: [SimpleMaterial(color: UIColor(red: 0.55, green: 0.4, blue: 0.26, alpha: 1), roughness: 1, isMetallic: false)]
        )
        bed.position = [0, -0.12, 0]
        segment.addChild(bed)

        // Shared meshes/materials — sleepers and rails are cloned many times.
        let sleeperMesh = MeshResource.generateBox(size: [1.6, 0.1, 0.42], cornerRadius: 0.03)
        let sleeperMaterial = SimpleMaterial(color: UIColor(red: 0.58, green: 0.22, blue: 0.16, alpha: 1), roughness: 0.85, isMetallic: false)
        let railMesh = MeshResource.generateBox(size: [0.1, 0.12, segmentLength])
        let railMaterial = SimpleMaterial(color: UIColor(red: 0.72, green: 0.7, blue: 0.82, alpha: 1), roughness: 0.32, isMetallic: true)

        let sleeperSpacing: Float = 1.4
        let sleeperCount = Int(segmentLength / sleeperSpacing)

        for laneX in laneXs {
            for i in 0..<sleeperCount {
                let sleeper = ModelEntity(mesh: sleeperMesh, materials: [sleeperMaterial])
                sleeper.position = [laneX, 0.05, -segmentLength / 2 + sleeperSpacing * (Float(i) + 0.5)]
                segment.addChild(sleeper)
            }
            for offset in [Float(-0.62), 0.62] {
                let rail = ModelEntity(mesh: railMesh, materials: [railMaterial])
                rail.position = [laneX + offset, 0.16, 0]
                segment.addChild(rail)
            }
        }

        // Moss patches on the outer dirt shoulders (like the reference art).
        let mossColors: [UIColor] = [
            UIColor(red: 0.42, green: 0.6, blue: 0.24, alpha: 1),
            UIColor(red: 0.36, green: 0.54, blue: 0.22, alpha: 1),
            UIColor(red: 0.5, green: 0.66, blue: 0.28, alpha: 1),
        ]
        for _ in 0..<10 {
            let width = Float.random(in: 0.7...1.5)
            let depth = Float.random(in: 0.6...1.2)
            let moss = ModelEntity(
                mesh: .generateBox(size: [width, 0.05, depth], cornerRadius: 0.025),
                materials: [SimpleMaterial(color: mossColors.randomElement() ?? mossColors[0], roughness: 1, isMetallic: false)]
            )
            let side: Float = Bool.random() ? 1 : -1
            moss.position = [
                side * Float.random(in: 3.3...4.3),
                0.012,
                Float.random(in: -segmentLength / 2 + 1 ... segmentLength / 2 - 1),
            ]
            segment.addChild(moss)
        }

        // Small pebbles scattered across the dirt strips between the tracks.
        let pebbleMaterial = SimpleMaterial(color: UIColor(red: 0.62, green: 0.58, blue: 0.55, alpha: 1), roughness: 0.9, isMetallic: false)
        let pebbleBands: [ClosedRange<Float>] = [(-4.4)...(-3.1), (-1.12)...(-0.88), 0.88...1.12, 3.1...4.4]
        for _ in 0..<8 {
            let size = Float.random(in: 0.1...0.2)
            let pebble = ModelEntity(
                mesh: .generateBox(size: [size, size * 0.6, size], cornerRadius: size * 0.25),
                materials: [pebbleMaterial]
            )
            let band = pebbleBands.randomElement() ?? pebbleBands[0]
            pebble.position = [
                Float.random(in: band),
                0.02,
                Float.random(in: -segmentLength / 2 + 0.5 ... segmentLength / 2 - 0.5),
            ]
            pebble.orientation = simd_quatf(angle: Float.random(in: 0...(2 * .pi)), axis: [0, 1, 0])
            segment.addChild(pebble)
        }
    }

    /// Clones the generated curb prototype into evenly-spaced strips along both
    /// track edges. The model is directionless, so the strip's measured long
    /// axis is aligned down the track geometrically, and the two sides are
    /// mirrored so both rows show the same face toward the lanes. Sections are
    /// stretched along the long axis so a whole number of clones covers the
    /// segment exactly — no gaps, no overlap.
    private static func addCurbRows(from prototype: Entity, to segment: Entity) {
        let bounds = prototype.visualBounds(relativeTo: nil)
        let longAxisIsX = bounds.extents.x >= bounds.extents.z
        let rawLength = max(longAxisIsX ? bounds.extents.x : bounds.extents.z, 0.001)

        let sectionsPerSide = 4
        let spacing = segmentLength / Float(sectionsPerSide)
        let lengthScale = spacing / rawLength

        for side in [Float(-1), 1] {
            // Geometric alignment: long axis down the track, mirrored per side.
            let yaw: Float
            if longAxisIsX {
                yaw = side < 0 ? .pi / 2 : -.pi / 2
            } else {
                yaw = side < 0 ? 0 : .pi
            }
            let orientation = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))

            for index in 0..<sectionsPerSide {
                let clone = prototype.clone(recursive: true)
                // Scale is applied in the clone's LOCAL space (before the yaw),
                // so the stretch always targets the model's own long axis.
                clone.scale = longAxisIsX ? [lengthScale, 1, 1] : [1, 1, lengthScale]
                clone.orientation = orientation
                clone.position = [side * 5.2, 0, -segmentLength / 2 + spacing * (Float(index) + 0.5)]
                segment.addChild(clone)
            }
        }
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
            // One festival prop per side: speaker stack + conga set.
            if let speaker = decorPrototypes.speaker {
                let clone = speaker.clone(recursive: true)
                clone.name = "gen_speaker"
                clone.position = [side * 6.6, 0, -6]
                container.addChild(clone)
            }
            if let conga = decorPrototypes.conga {
                let clone = conga.clone(recursive: true)
                clone.name = "gen_conga"
                clone.position = [side * 6.4, 0, 8]
                container.addChild(clone)
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
            case "gen_speaker":
                child.position = [side * Float.random(in: 6.2...7.2), 0, Float.random(in: -halfLength + 2 ... halfLength - 2)]
                child.scale = SIMD3<Float>(repeating: Float.random(in: 0.9...1.12))
                child.orientation = faceTrack
            case "gen_conga":
                child.position = [side * Float.random(in: 6.1...7.0), 0, Float.random(in: -halfLength + 2 ... halfLength - 2)]
                child.scale = SIMD3<Float>(repeating: Float.random(in: 0.85...1.05))
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
            materials: [UnlitMaterial(color: UIColor(red: 0.40, green: 0.72, blue: 0.98, alpha: 1))]
        )
        sky.position = [0, 60, -110]
        backdrop.addChild(sky)

        let horizonGlow = ModelEntity(
            mesh: .generatePlane(width: 400, height: 26),
            materials: [UnlitMaterial(color: UIColor(red: 1.0, green: 0.72, blue: 0.72, alpha: 1))]
        )
        horizonGlow.position = [0, 10, -109]
        backdrop.addChild(horizonGlow)

        let sun = ModelEntity(
            mesh: .generateSphere(radius: 7),
            materials: [UnlitMaterial(color: UIColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1))]
        )
        sun.position = [26, 46, -108]
        backdrop.addChild(sun)

        // Distant skyline silhouettes in festival dusk purples and pinks.
        let silhouettes: [UIColor] = [
            UIColor(red: 0.48, green: 0.36, blue: 0.72, alpha: 1),
            UIColor(red: 0.62, green: 0.40, blue: 0.78, alpha: 1),
            UIColor(red: 0.72, green: 0.44, blue: 0.70, alpha: 1),
        ]
        for i in 0..<14 {
            let height = Float.random(in: 12...34)
            let tower = ModelEntity(
                mesh: .generateBox(size: [Float.random(in: 6...12), height, 4]),
                materials: [UnlitMaterial(color: silhouettes[i % silhouettes.count])]
            )
            tower.position = [Float(i - 7) * 14 + Float.random(in: -3...3), height / 2, -100]
            backdrop.addChild(tower)
        }

        // Slow-falling confetti filling the air over the whole track.
        let confetti = Entity()
        var particles = ParticleEmitterComponent()
        particles.emitterShape = .box
        particles.emitterShapeSize = [14, 0.5, 90]
        particles.birthLocation = .volume
        particles.speed = 0.25
        particles.speedVariation = 0.2
        particles.mainEmitter.birthRate = 60
        particles.mainEmitter.lifeSpan = 9
        particles.mainEmitter.lifeSpanVariation = 2
        particles.mainEmitter.size = 0.055
        particles.mainEmitter.sizeVariation = 0.03
        particles.mainEmitter.spreadingAngle = 0.5
        particles.mainEmitter.acceleration = [0.35, -1.1, 0.5]
        particles.mainEmitter.angularSpeed = 2.4
        particles.mainEmitter.color = .constant(.random(
            a: UIColor(red: 0.94, green: 0.26, blue: 0.62, alpha: 0.95),
            b: UIColor(red: 1.0, green: 0.82, blue: 0.24, alpha: 0.95)
        ))
        confetti.components.set(particles)
        confetti.position = [0, 10.5, -30]
        backdrop.addChild(confetti)

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
