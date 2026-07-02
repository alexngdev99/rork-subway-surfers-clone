import RealityKit
import simd

/// Semantic local axis of a generated 3D model, from its orientation metadata.
enum GeneratedModelAxis: String {
    case positiveX, negativeX, positiveY, negativeY, positiveZ, negativeZ

    var vector: SIMD3<Float> {
        switch self {
        case .positiveX: return [1, 0, 0]
        case .negativeX: return [-1, 0, 0]
        case .positiveY: return [0, 1, 0]
        case .negativeY: return [0, -1, 0]
        case .positiveZ: return [0, 0, 1]
        case .negativeZ: return [0, 0, -1]
        }
    }
}

/// Quaternion for the orthonormal basis built from `front` and `up`.
func generatedModelBasisQuaternion(front: SIMD3<Float>, up: SIMD3<Float>) -> simd_quatf {
    let f = simd_normalize(front)
    let r = simd_normalize(simd_cross(up, f))
    let u = simd_normalize(simd_cross(f, r))
    return simd_quatf(simd_float3x3(r, u, f))
}

/// Full body-frame correction: rotates the model so its classified local front
/// axis points along `desiredWorldForward` while its local up axis stays world-up.
func generatedModelOrientationCorrection(
    localFrontAxis: GeneratedModelAxis,
    localUpAxis: GeneratedModelAxis,
    desiredWorldForward: SIMD3<Float>,
    worldUp: SIMD3<Float> = [0, 1, 0]
) -> simd_quatf {
    let localBasis = generatedModelBasisQuaternion(front: localFrontAxis.vector, up: localUpAxis.vector)
    let worldBasis = generatedModelBasisQuaternion(front: desiredWorldForward, up: worldUp)
    return worldBasis * localBasis.inverse
}

/// Normalizes a loaded visual into an existing container following the
/// container → runtime child → visual placement contract.
func attachGeneratedModelVisual(
    _ visual: Entity,
    to container: Entity,
    targetHeight: Float,
    localFrontAxis: GeneratedModelAxis?,
    localUpAxis: GeneratedModelAxis = .positiveY,
    desiredWorldForward: SIMD3<Float>? = nil
) {
    let runtime = container.findEntity(named: "generated_model_runtime") ?? {
        let runtime = Entity()
        runtime.name = "generated_model_runtime"
        container.addChild(runtime)
        return runtime
    }()
    runtime.children.forEach { $0.removeFromParent() }
    runtime.addChild(visual)

    // 1. Scale so height matches the planned size.
    let rawBounds = visual.visualBounds(relativeTo: runtime)
    visual.scale *= SIMD3<Float>(repeating: targetHeight / max(rawBounds.extents.y, 0.001))

    // 2. Orientation correction — only when the model has an intrinsic front.
    if let localFrontAxis, let desiredWorldForward {
        visual.orientation = generatedModelOrientationCorrection(
            localFrontAxis: localFrontAxis,
            localUpAxis: localUpAxis,
            desiredWorldForward: desiredWorldForward
        ) * visual.orientation
    }

    // 3. Center X/Z and ground Y from post-transform bounds.
    let bounds = visual.visualBounds(relativeTo: runtime)
    visual.position -= SIMD3<Float>(bounds.center.x, bounds.min.y, bounds.center.z)
}

/// Builds container → runtime child → normalized visual for a bundled generated model.
func makeGeneratedModelContainer(
    resourceName: String,
    targetHeight: Float,
    localFrontAxis: GeneratedModelAxis?,
    localUpAxis: GeneratedModelAxis = .positiveY,
    desiredWorldForward: SIMD3<Float>? = nil,
    worldPosition: SIMD3<Float> = .zero,
    fallback: () -> Entity
) async -> Entity {
    let container = Entity()
    let visual = (try? await Entity(named: resourceName)) ?? fallback()
    attachGeneratedModelVisual(
        visual,
        to: container,
        targetHeight: targetHeight,
        localFrontAxis: localFrontAxis,
        localUpAxis: localUpAxis,
        desiredWorldForward: desiredWorldForward
    )
    container.position = worldPosition
    return container
}
