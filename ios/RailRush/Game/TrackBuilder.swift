import RealityKit
import UIKit

/// Builds the procedural subway environment: track segments, rails, sleepers,
/// side walls, city buildings, and the sky backdrop.
enum TrackBuilder {
    static let segmentLength: Float = 40
    static let laneXs: [Float] = [-2, 0, 2]

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

        // Ballast bed
        let ballast = ModelEntity(
            mesh: .generateBox(size: [9.6, 0.2, segmentLength]),
            materials: [SimpleMaterial(color: UIColor(red: 0.26, green: 0.24, blue: 0.28, alpha: 1), roughness: 0.9, isMetallic: false)]
        )
        ballast.position = [0, -0.1, 0]
        segment.addChild(ballast)

        // Rails: two per lane
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

        // Sleepers spanning all lanes
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
        randomizeDecor(on: segment)

        return segment
    }

    /// Re-rolls the buildings so recycled segments look fresh.
    static func randomizeDecor(on segment: Entity) {
        guard let decor = segment.findEntity(named: "segment_decor") else { return }
        decor.children.forEach { $0.removeFromParent() }

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
                building.position = [side * Float.random(in: 9.5...12), height / 2 - 0.2, z + width / 2]
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
