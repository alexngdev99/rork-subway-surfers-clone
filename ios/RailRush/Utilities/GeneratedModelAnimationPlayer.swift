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

    // Root-motion cancellation state. Some generated clips (slide, jump) are
    // not authored in-place — the skeleton translates forward inside the clip,
    // then snaps back when the next clip swaps in. Each frame we measure the
    // reference joint's drift from its starting point and counter-shift the
    // animation entity so the character visually stays at the gameplay origin.
    private var skinnedModel: ModelEntity?
    private var referenceJointChain: [Int] = []
    private var referenceStart: SIMD3<Float>?
    private var animatedBasePosition: SIMD3<Float> = .zero

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

    /// Call once per frame from the game loop. Cancels the clip's horizontal
    /// root motion so non-inplace clips (slide, jump) don't drift the model
    /// forward and snap back when the run loop resumes. Vertical motion from
    /// the pose is preserved.
    func cancelHorizontalRootMotion() {
        guard let animated = activeAnimation,
              let model = skinnedModel,
              !referenceJointChain.isEmpty else { return }

        let transforms = model.jointTransforms
        guard referenceJointChain.allSatisfy({ $0 < transforms.count }) else { return }

        var matrix = matrix_identity_float4x4
        for index in referenceJointChain {
            matrix *= transforms[index].matrix
        }
        let jointLocal = SIMD3<Float>(matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z)
        // Express the joint in the animation entity's own frame — this ignores
        // `animated.position`, so adjusting it below causes no feedback loop.
        let inAnimated = model.convert(position: jointLocal, to: animated)

        guard let start = referenceStart else {
            referenceStart = inAnimated
            return
        }

        let deltaLocal = inAnimated - start
        let deltaRuntime = animated.orientation.act(deltaLocal * animated.scale)
        animated.position = animatedBasePosition - SIMD3<Float>(deltaRuntime.x, 0, deltaRuntime.z)
    }

    private func play(_ resourceName: String?, looping: Bool) {
        activeAnimation?.removeFromParent()
        activeAnimation = nil
        baseVisual?.isEnabled = true
        skinnedModel = nil
        referenceJointChain = []
        referenceStart = nil
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
        animatedBasePosition = animated.position
        if let model = Self.findSkinnedModel(in: animated) {
            skinnedModel = model
            referenceJointChain = Self.referenceJointChain(for: model.jointNames)
        }
    }

    private static func findSkinnedModel(in entity: Entity) -> ModelEntity? {
        var found: ModelEntity?
        entity.forEachDescendant { descendant in
            if found == nil,
               let model = descendant as? ModelEntity,
               !model.jointNames.isEmpty {
                found = model
            }
        }
        return found
    }

    /// Picks a body-motion reference joint (hips/pelvis when present, else the
    /// shallowest joint) and returns the joint-index chain from the skeleton
    /// root down to it, for composing its model-space transform.
    private static func referenceJointChain(for jointNames: [String]) -> [Int] {
        guard !jointNames.isEmpty else { return [] }
        var indexByPath: [String: Int] = [:]
        for (index, path) in jointNames.enumerated() {
            indexByPath[path] = index
        }

        let hipsPath = jointNames.first { path in
            let last = path.split(separator: "/").last.map(String.init)?.lowercased() ?? ""
            return last.contains("hip") || last.contains("pelvis")
        }
        let targetPath = hipsPath ?? jointNames.min {
            $0.split(separator: "/").count < $1.split(separator: "/").count
        }
        guard let targetPath else { return [] }

        var chain: [Int] = []
        var prefix = ""
        for component in targetPath.split(separator: "/") {
            prefix = prefix.isEmpty ? String(component) : prefix + "/" + component
            if let index = indexByPath[prefix] {
                chain.append(index)
            }
        }
        return chain
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
