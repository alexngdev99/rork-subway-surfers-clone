import RealityKit
import simd

/// Swaps generated Meshy animation entities under a model container.
/// Assumes the placement contract:
/// container → runtime child ("generated_model_runtime") → normalized base visual.
@MainActor
final class GeneratedModelAnimationPlayer {
    /// Generated animation USDZ files are authored Z-up while base models and
    /// RealityKit are Y-up; rotating -90° about X maps the clip's +Z (up) to +Y.
    private static let zUpToYUp = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])

    private let container: Entity
    private var templates: [String: Entity] = [:]
    private var activeAnimation: Entity?
    private var baseVisual: Entity?
    private var baseMaterials: [String: [any RealityKit.Material]] = [:]
    private var currentLoop: String?
    private var oneShotRestoreTask: Task<Void, Never>?

    init(container: Entity) {
        self.container = container
    }

    private var runtime: Entity {
        container.findEntity(named: "generated_model_runtime") ?? container
    }

    func preload(_ resourceNames: [String]) async {
        if baseVisual == nil {
            baseVisual = runtime.children.first
            captureBaseMaterials()
        }
        for name in resourceNames where templates[name] == nil {
            templates[name] = try? await Entity(named: name)
        }
    }

    /// Passing nil stops generated playback and restores the base visual.
    func setLoop(_ resourceName: String?) {
        currentLoop = resourceName
        oneShotRestoreTask?.cancel()
        play(resourceName, looping: true)
    }

    func playOnce(_ resourceName: String?, restoreAfter duration: Duration = .milliseconds(650)) {
        guard let resourceName else { return }
        play(resourceName, looping: false)
        oneShotRestoreTask?.cancel()
        oneShotRestoreTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard let self, !Task.isCancelled else { return }
            self.play(self.currentLoop, looping: true)
        }
    }

    func stop() {
        currentLoop = nil
        oneShotRestoreTask?.cancel()
        play(nil, looping: false)
    }

    private func play(_ resourceName: String?, looping: Bool) {
        activeAnimation?.removeFromParent()
        activeAnimation = nil
        baseVisual?.isEnabled = true
        guard let resourceName, let template = templates[resourceName] else { return }

        let animated = template.clone(recursive: true)
        // Match the base visual's normalization, then convert the clip's Z-up
        // authoring frame into the base model's Y-up frame so the character
        // stands upright instead of lying flat.
        if let base = baseVisual {
            animated.scale = base.scale
            animated.orientation = base.orientation * Self.zUpToYUp
            base.isEnabled = false
        }
        transferBaseMaterials(to: animated)
        runtime.addChild(animated)
        // Re-ground and re-center from the corrected bounds.
        let bounds = animated.visualBounds(relativeTo: runtime)
        animated.position -= SIMD3<Float>(bounds.center.x, bounds.min.y, bounds.center.z)
        if let animation = animated.availableAnimations.first {
            animated.playAnimation(looping ? animation.repeat() : animation, transitionDuration: 0.2)
        }
        activeAnimation = animated
    }

    /// Meshy FBX→USDZ conversion can drop PBR materials on animation files;
    /// copy the base model's materials onto matching parts by name.
    private func captureBaseMaterials() {
        guard let base = baseVisual else { return }
        base.forEachDescendant { entity in
            if let model = (entity as? ModelEntity)?.model {
                baseMaterials[entity.name] = model.materials
            }
        }
    }

    private func transferBaseMaterials(to animated: Entity) {
        guard !baseMaterials.isEmpty else { return }
        animated.forEachDescendant { entity in
            if let modelEntity = entity as? ModelEntity,
               let materials = baseMaterials[entity.name],
               modelEntity.model?.materials.count == materials.count {
                modelEntity.model?.materials = materials
            }
        }
    }
}

extension Entity {
    /// Depth-first visit of self and all descendants.
    func forEachDescendant(_ visit: (Entity) -> Void) {
        visit(self)
        for child in children {
            child.forEachDescendant(visit)
        }
    }
}
