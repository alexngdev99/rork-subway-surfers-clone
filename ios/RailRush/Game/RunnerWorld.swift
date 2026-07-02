import Foundation
import Observation
import RealityKit
import SwiftUI
import UIKit
import simd

/// Tunable world constants. RealityKit is metric: 1 unit = 1 meter.
enum WorldConfig {
    static let laneXs: [Float] = [-2, 0, 2]
    static let spawnZ: Float = -75
    static let despawnZ: Float = 14
    static let baseSpeed: Float = 7
    static let maxSpeed: Float = 19
    static let speedRamp: Float = 0.13
    static let gravity: Float = -26
    static let jumpVelocity: Float = 8.8
    static let slideDuration: Float = 0.85
    static let jetpackHeight: Float = 4.2
    static let inspectorGraceDuration: Float = 12
}

/// A pooled obstacle on the track.
final class ObstacleNode {
    let entity: Entity
    let kind: ObstacleKind
    var isActive = false
    var extraSpeed: Float = 0
    var halfExtents: SIMD3<Float> = .zero
    var boundsCenterY: Float = 0

    init(entity: Entity, kind: ObstacleKind) {
        self.entity = entity
        self.kind = kind
    }
}

/// A pooled collectible coin.
final class CoinNode {
    let entity: Entity
    var isActive = false

    init(entity: Entity) {
        self.entity = entity
    }
}

/// A pooled power-up pickup.
final class PowerUpNode {
    let entity: Entity
    let type: PowerUpType
    var isActive = false

    init(entity: Entity, type: PowerUpType) {
        self.entity = entity
        self.type = type
    }
}

/// Owns the RealityKit scene and runs the endless-runner simulation.
@Observable
final class RunnerWorld {
    let state: GameState

    private let audio = AudioService.shared
    private let haptics = HapticsService.shared

    // Scene graph
    private let sceneRoot = Entity()
    private let environment = Entity()
    private let actors = Entity()
    private let spawned = Entity()
    private var segments: [Entity] = []
    private var camera = PerspectiveCamera()
    private var isBuilt = false

    // Actors
    private var playerContainer = Entity()
    private var runnerAnimator: GeneratedModelAnimationPlayer?
    private var inspectorContainer = Entity()
    private var inspectorAnimator: GeneratedModelAnimationPlayer?
    private var dogContainer = Entity()

    // Pools
    private var trainPool: [ObstacleNode] = []
    private var lowBarrierPool: [ObstacleNode] = []
    private var overheadBarrierPool: [ObstacleNode] = []
    private var trainTemplate: Entity?
    private var coinPool: [CoinNode] = []
    private var powerUpPools: [PowerUpType: [PowerUpNode]] = [:]

    // Player simulation state
    private var laneIndex = 1
    private var playerX: Float = 0
    private var playerY: Float = 0
    private var verticalVelocity: Float = 0
    private var isSliding = false
    private var slideTimer: Float = 0
    private var isJumping = false

    // Run state
    private var runTime: Float = 0
    private var worldSpeed: Float = WorldConfig.baseSpeed
    private var speedPenaltyTimer: Float = 0
    private var scoreAccumulator: Float = 0
    private var distanceSinceSpawn: Float = 0
    private var nextSpawnGap: Float = 16
    private var powerUpTimer: Float = 0
    private var jetpackActive = false
    private var inspectorGraceTimer: Float = 0
    private var inspectorTargetZ: Float = 8.5
    private var inspectorIntroTimer: Float = 0
    private var crashHandled = false
    private var shakeTimer: Float = 0
    private var coinSpinAngle: Float = 0

    var updateSubscription: EventSubscription?

    init(state: GameState) {
        self.state = state
    }

    // MARK: - Scene construction

    func build(in content: RealityViewCameraContent) async {
        guard !isBuilt else { return }
        isBuilt = true

        sceneRoot.addChild(environment)
        sceneRoot.addChild(actors)
        sceneRoot.addChild(spawned)
        content.add(sceneRoot)

        setupCameraAndLights(in: content)
        environment.addChild(TrackBuilder.makeBackdrop())

        // Generated environment decor prototypes must load before segments are
        // built so each segment can clone them once.
        await TrackBuilder.loadDecorPrototypes()

        // Scrolling track segments
        for i in 0..<3 {
            let segment = TrackBuilder.makeSegment()
            segment.position = [0, 0, Float(i) * -TrackBuilder.segmentLength]
            environment.addChild(segment)
            segments.append(segment)
        }

        await buildActors()
        await buildPools()

        // Idle on the home screen
        runnerAnimator?.setLoop(GeneratedAssets.runnerIdle)
        inspectorContainer.isEnabled = false
        dogContainer.isEnabled = false
    }

    private func setupCameraAndLights(in content: RealityViewCameraContent) {
        camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 58
        camera.position = [0, 3.3, 6.4]
        camera.look(at: [0, 1.1, -5], from: camera.position, relativeTo: nil)
        sceneRoot.addChild(camera)

        let sunlight = DirectionalLight()
        sunlight.light.intensity = 5200
        sunlight.light.color = UIColor(red: 1.0, green: 0.96, blue: 0.88, alpha: 1)
        sunlight.orientation = simd_quatf(angle: -.pi / 3.4, axis: [1, 0, 0])
            * simd_quatf(angle: .pi / 7, axis: [0, 1, 0])
        sceneRoot.addChild(sunlight)

        let fill = DirectionalLight()
        fill.light.intensity = 1600
        fill.light.color = UIColor(red: 0.75, green: 0.85, blue: 1.0, alpha: 1)
        fill.orientation = simd_quatf(angle: .pi / 3, axis: [1, 0, 0])
        sceneRoot.addChild(fill)
    }

    private func buildActors() async {
        playerContainer = await makeGeneratedModelContainer(
            resourceName: GeneratedAssets.runnerModel,
            targetHeight: 1.8,
            localFrontAxis: GeneratedAssets.runnerFrontAxis,
            localUpAxis: GeneratedAssets.runnerUpAxis,
            desiredWorldForward: [0, 0, -1],
            worldPosition: [0, 0, 0],
            fallback: { TrackBuilder.makeFallbackHumanoid(color: UIColor(red: 0.0, green: 0.72, blue: 0.68, alpha: 1)) }
        )
        actors.addChild(playerContainer)

        let runnerPlayer = GeneratedModelAnimationPlayer(container: playerContainer)
        await runnerPlayer.preload(
            [
                GeneratedAssets.runnerRun,
                GeneratedAssets.runnerJump,
                GeneratedAssets.runnerSlide,
                GeneratedAssets.runnerKnockDown,
                GeneratedAssets.runnerIdle,
            ].compactMap { $0 }
        )
        runnerAnimator = runnerPlayer

        inspectorContainer = await makeGeneratedModelContainer(
            resourceName: GeneratedAssets.inspectorModel,
            targetHeight: 1.85,
            localFrontAxis: GeneratedAssets.inspectorFrontAxis,
            localUpAxis: GeneratedAssets.inspectorUpAxis,
            desiredWorldForward: [0, 0, -1],
            worldPosition: [-0.7, 0, 8.5],
            fallback: { TrackBuilder.makeFallbackHumanoid(color: UIColor(red: 0.15, green: 0.25, blue: 0.5, alpha: 1)) }
        )
        actors.addChild(inspectorContainer)

        let inspectorPlayer = GeneratedModelAnimationPlayer(container: inspectorContainer)
        await inspectorPlayer.preload(
            [GeneratedAssets.inspectorRun, GeneratedAssets.inspectorIdle].compactMap { $0 }
        )
        inspectorAnimator = inspectorPlayer

        dogContainer = await makeGeneratedModelContainer(
            resourceName: GeneratedAssets.dogModel,
            targetHeight: 0.75,
            localFrontAxis: GeneratedAssets.dogFrontAxis,
            localUpAxis: GeneratedAssets.dogUpAxis,
            desiredWorldForward: [0, 0, -1],
            worldPosition: [0.8, 0, 8.8],
            fallback: { TrackBuilder.makeFallbackDog() }
        )
        actors.addChild(dogContainer)
    }

    private func buildPools() async {
        // Train template: load the generated model once, clone for the pool.
        let trainVisualTemplate = (try? await Entity(named: GeneratedAssets.trainModel)) ?? TrackBuilder.makeFallbackTrain()
        trainTemplate = trainVisualTemplate

        // No persisted orientation metadata for the train — infer its length
        // axis from real bounds so cars always run along the track (Z axis).
        let trainBounds = trainVisualTemplate.visualBounds(relativeTo: nil)
        let trainFrontAxis: GeneratedModelAxis = trainBounds.extents.x > trainBounds.extents.z ? .positiveX : .positiveZ

        for _ in 0..<6 {
            let container = Entity()
            attachGeneratedModelVisual(
                trainVisualTemplate.clone(recursive: true),
                to: container,
                targetHeight: 2.8,
                localFrontAxis: trainFrontAxis,
                localUpAxis: GeneratedAssets.trainUpAxis,
                desiredWorldForward: [0, 0, 1] // oncoming: front faces the runner
            )
            let node = ObstacleNode(entity: container, kind: .trainParked)
            configureHitbox(for: node)
            container.isEnabled = false
            spawned.addChild(container)
            trainPool.append(node)
        }

        for _ in 0..<6 {
            let node = ObstacleNode(entity: TrackBuilder.makeLowBarrier(), kind: .barrierLow)
            node.halfExtents = [0.95, 0.45, 0.15]
            node.boundsCenterY = 0.45
            node.entity.isEnabled = false
            spawned.addChild(node.entity)
            lowBarrierPool.append(node)
        }

        for _ in 0..<6 {
            let node = ObstacleNode(entity: TrackBuilder.makeOverheadBarrier(), kind: .barrierOverhead)
            node.halfExtents = [1.0, 0.5, 0.1]
            node.boundsCenterY = 1.78
            node.entity.isEnabled = false
            spawned.addChild(node.entity)
            overheadBarrierPool.append(node)
        }

        // Coin template: load the generated model once, clone for the pool.
        let coinVisualTemplate = try? await Entity(named: GeneratedAssets.coinModel)

        for _ in 0..<70 {
            let coinEntity: Entity
            if let coinVisualTemplate {
                coinEntity = Self.makeGeneratedCoin(from: coinVisualTemplate)
            } else {
                coinEntity = TrackBuilder.makeCoin()
            }
            let coin = CoinNode(entity: coinEntity)
            coin.entity.isEnabled = false
            spawned.addChild(coin.entity)
            coinPool.append(coin)
        }

        for type in PowerUpType.allCases {
            var pool: [PowerUpNode] = []
            for _ in 0..<2 {
                let node = PowerUpNode(entity: TrackBuilder.makePowerUp(type: type), type: type)
                node.entity.isEnabled = false
                spawned.addChild(node.entity)
                pool.append(node)
            }
            powerUpPools[type] = pool
        }
    }

    /// Clones the generated coin visual into a container normalized to the
    /// gameplay coin size and centered on all axes so Y-spin looks correct.
    private static func makeGeneratedCoin(from template: Entity) -> Entity {
        let container = Entity()
        let visual = template.clone(recursive: true)
        container.addChild(visual)

        let targetHeight: Float = 0.68
        let rawBounds = visual.visualBounds(relativeTo: container)
        visual.scale *= SIMD3<Float>(repeating: targetHeight / max(rawBounds.extents.y, 0.001))

        let bounds = visual.visualBounds(relativeTo: container)
        visual.position -= bounds.center
        return container
    }

    private func configureHitbox(for node: ObstacleNode) {
        let bounds = node.entity.visualBounds(relativeTo: node.entity)
        node.halfExtents = bounds.extents / 2
        node.boundsCenterY = bounds.center.y
    }

    // MARK: - Run lifecycle

    func startRun() {
        // Reset pools
        for node in trainPool + lowBarrierPool + overheadBarrierPool {
            node.isActive = false
            node.entity.isEnabled = false
        }
        for coin in coinPool {
            coin.isActive = false
            coin.entity.isEnabled = false
        }
        for pool in powerUpPools.values {
            for node in pool {
                node.isActive = false
                node.entity.isEnabled = false
            }
        }

        laneIndex = 1
        playerX = 0
        playerY = 0
        verticalVelocity = 0
        isSliding = false
        isJumping = false
        slideTimer = 0
        runTime = 0
        worldSpeed = WorldConfig.baseSpeed
        speedPenaltyTimer = 0
        scoreAccumulator = 0
        distanceSinceSpawn = 0
        nextSpawnGap = 14
        powerUpTimer = 0
        jetpackActive = false
        inspectorGraceTimer = 0
        inspectorIntroTimer = 2.6
        inspectorTargetZ = 3.4
        crashHandled = false
        shakeTimer = 0

        playerContainer.position = [0, 0, 0]
        playerContainer.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
        inspectorContainer.isEnabled = true
        dogContainer.isEnabled = true
        inspectorContainer.position = [-0.7, 0, 5.5]
        dogContainer.position = [0.8, 0, 5.8]

        state.beginRun()
        runnerAnimator?.setLoop(GeneratedAssets.runnerRun)
        inspectorAnimator?.setLoop(GeneratedAssets.inspectorRun)
        audio.startMusic()
    }

    func returnHome() {
        state.phase = .home
        state.isPaused = false
        runnerAnimator?.setLoop(GeneratedAssets.runnerIdle)
        inspectorAnimator?.setLoop(nil)
        inspectorContainer.isEnabled = false
        dogContainer.isEnabled = false
        playerContainer.position = [0, 0, 0]
        audio.stopMusic()
    }

    func togglePause() {
        guard state.phase == .running else { return }
        state.isPaused.toggle()
    }

    // MARK: - Input

    func handleSwipe(dx: CGFloat, dy: CGFloat) {
        guard state.phase == .running, !state.isPaused, !crashHandled else { return }
        if abs(dx) > abs(dy) {
            changeLane(direction: dx > 0 ? 1 : -1)
        } else if dy < 0 {
            jump()
        } else {
            slide()
        }
    }

    private func changeLane(direction: Int) {
        let target = laneIndex + direction
        guard (0..<WorldConfig.laneXs.count).contains(target) else { return }
        laneIndex = target
        haptics.laneChange()
    }

    private func jump() {
        guard !jetpackActive, !isJumping, playerY < 0.1 else { return }
        isJumping = true
        isSliding = false
        slideTimer = 0
        verticalVelocity = WorldConfig.jumpVelocity
        haptics.jump()
        audio.play(.jump)
        runnerAnimator?.playOnce(GeneratedAssets.runnerJump, restoreAfter: .milliseconds(750))
    }

    private func slide() {
        guard !jetpackActive else { return }
        if isJumping {
            // Fast-fall out of a jump
            verticalVelocity = min(verticalVelocity, -12)
            return
        }
        isSliding = true
        slideTimer = WorldConfig.slideDuration
        haptics.laneChange()
        runnerAnimator?.playOnce(GeneratedAssets.runnerSlide, restoreAfter: .milliseconds(Int(WorldConfig.slideDuration * 1000)))
    }

    // MARK: - Per-frame simulation

    func tick(deltaTime: Float) {
        let dt = min(deltaTime, 1 / 20)
        coinSpinAngle += dt * 4

        switch state.phase {
        case .home:
            updateIdleScene(dt: dt)
        case .running:
            guard !state.isPaused else { return }
            if crashHandled {
                updateCrashCamera(dt: dt)
            } else {
                updateRun(dt: dt)
            }
        case .gameOver:
            updateCrashCamera(dt: dt)
        }
    }

    private func updateIdleScene(dt: Float) {
        // Gentle camera sway on the home screen
        let sway = sin(coinSpinAngle * 0.35) * 0.25
        camera.position = [sway, 3.3, 6.4]
        camera.look(at: [0, 1.1, -5], from: camera.position, relativeTo: nil)
    }

    private func updateRun(dt: Float) {
        runTime += dt

        // Speed ramp with stumble penalty
        var speed = min(WorldConfig.maxSpeed, WorldConfig.baseSpeed + WorldConfig.speedRamp * runTime)
        if speedPenaltyTimer > 0 {
            speedPenaltyTimer -= dt
            speed *= 0.62
        }
        worldSpeed = speed

        updatePlayer(dt: dt)
        scrollWorld(dt: dt)
        updateSpawning(dt: dt)
        updateCoins(dt: dt)
        updatePowerUps(dt: dt)
        updateInspector(dt: dt)
        updateCamera(dt: dt)
        checkCollisions()

        // Score
        scoreAccumulator += speed * dt * Float(state.multiplier)
        state.score = Int(scoreAccumulator)
    }

    private func updatePlayer(dt: Float) {
        // Lane lerp
        let targetX = WorldConfig.laneXs[laneIndex]
        playerX += (targetX - playerX) * min(1, dt * 12)

        if jetpackActive {
            playerY += (WorldConfig.jetpackHeight - playerY) * min(1, dt * 4)
            verticalVelocity = 0
            isJumping = false
        } else if isJumping || playerY > 0.01 {
            verticalVelocity += WorldConfig.gravity * dt
            playerY += verticalVelocity * dt
            if playerY <= 0 {
                playerY = 0
                verticalVelocity = 0
                isJumping = false
            }
        }

        if isSliding {
            slideTimer -= dt
            if slideTimer <= 0 { isSliding = false }
        }

        playerContainer.position = [playerX, playerY, 0]

        // Lean into lane changes
        let lean = (targetX - playerX) * -0.14
        playerContainer.orientation = simd_quatf(angle: lean, axis: [0, 0, 1])
    }

    private func scrollWorld(dt: Float) {
        let dz = worldSpeed * dt

        for segment in segments {
            segment.position.z += dz
            if segment.position.z >= TrackBuilder.segmentLength {
                segment.position.z -= TrackBuilder.segmentLength * 3
                TrackBuilder.randomizeDecor(on: segment)
            }
        }

        for node in trainPool + lowBarrierPool + overheadBarrierPool where node.isActive {
            node.entity.position.z += dz + node.extraSpeed * dt
            if node.entity.position.z > WorldConfig.despawnZ + node.halfExtents.z {
                node.isActive = false
                node.entity.isEnabled = false
            }
        }

        for coin in coinPool where coin.isActive {
            coin.entity.position.z += dz
            coin.entity.orientation = simd_quatf(angle: coinSpinAngle, axis: [0, 1, 0])
            if coin.entity.position.z > WorldConfig.despawnZ {
                coin.isActive = false
                coin.entity.isEnabled = false
            }
        }

        for pool in powerUpPools.values {
            for node in pool where node.isActive {
                node.entity.position.z += dz
                node.entity.position.y = 1.1 + sin(coinSpinAngle * 1.6) * 0.15
                node.entity.orientation = simd_quatf(angle: coinSpinAngle, axis: [0, 1, 0])
                if node.entity.position.z > WorldConfig.despawnZ {
                    node.isActive = false
                    node.entity.isEnabled = false
                }
            }
        }

        distanceSinceSpawn += dz
    }

    // MARK: Spawning

    private func updateSpawning(dt: Float) {
        guard distanceSinceSpawn >= nextSpawnGap else { return }
        distanceSinceSpawn = 0
        nextSpawnGap = Float.random(in: 13...20)

        let roll = Float.random(in: 0...1)
        if roll < 0.42 {
            spawnTrainRow()
        } else if roll < 0.74 {
            spawnBarrierRow()
        } else {
            spawnCoinWeave()
        }

        // Occasional power-up in a random lane slightly beyond the pattern
        if Float.random(in: 0...1) < 0.14, state.activePowerUp == nil {
            spawnPowerUp(z: WorldConfig.spawnZ - 8)
        }
    }

    private func spawnTrainRow() {
        let trainLaneCount = runTime > 40 ? Int.random(in: 1...2) : 1
        var lanes = [0, 1, 2].shuffled()
        let trainLanes = Array(lanes.prefix(trainLaneCount))
        lanes.removeFirst(trainLaneCount)

        for lane in trainLanes {
            guard let node = trainPool.first(where: { !$0.isActive }) else { continue }
            let moving = runTime > 25 && Bool.random()
            node.extraSpeed = moving ? Float.random(in: 4...7) : 0
            node.entity.position = [WorldConfig.laneXs[lane], 0, WorldConfig.spawnZ - node.halfExtents.z]
            node.isActive = true
            node.entity.isEnabled = true
        }

        // A coin line in one free lane
        if let freeLane = lanes.first, Bool.random() {
            spawnCoinLine(lane: freeLane, startZ: WorldConfig.spawnZ, count: 6, height: jetpackActive ? WorldConfig.jetpackHeight : 1.0)
        }
    }

    private func spawnBarrierRow() {
        let laneCount = runTime > 30 ? Int.random(in: 1...3) : Int.random(in: 1...2)
        let lanes = [0, 1, 2].shuffled().prefix(laneCount)

        for lane in lanes {
            let useLow = Bool.random()
            let pool = useLow ? lowBarrierPool : overheadBarrierPool
            guard let node = pool.first(where: { !$0.isActive }) else { continue }
            node.extraSpeed = 0
            node.entity.position = [WorldConfig.laneXs[lane], 0, WorldConfig.spawnZ]
            node.isActive = true
            node.entity.isEnabled = true

            // Coins arc behind low barriers to reward the jump
            if useLow, Bool.random() {
                spawnCoinLine(lane: lane, startZ: WorldConfig.spawnZ - 3, count: 4, height: 1.0)
            }
        }
    }

    private func spawnCoinWeave() {
        let startLane = Int.random(in: 0...2)
        var lane = startLane
        var z = WorldConfig.spawnZ
        let height: Float = jetpackActive ? WorldConfig.jetpackHeight : 1.0
        for _ in 0..<4 {
            spawnCoinLine(lane: lane, startZ: z, count: 4, height: height)
            z -= 4 * 1.7
            let next = lane + (Bool.random() ? 1 : -1)
            lane = min(2, max(0, next))
        }
    }

    private func spawnCoinLine(lane: Int, startZ: Float, count: Int, height: Float) {
        var z = startZ
        for _ in 0..<count {
            guard let coin = coinPool.first(where: { !$0.isActive }) else { return }
            coin.entity.position = [WorldConfig.laneXs[lane], height, z]
            coin.isActive = true
            coin.entity.isEnabled = true
            z -= 1.7
        }
    }

    private func spawnPowerUp(z: Float) {
        guard let type = PowerUpType.allCases.randomElement(),
              let node = powerUpPools[type]?.first(where: { !$0.isActive }) else { return }
        node.entity.position = [WorldConfig.laneXs[Int.random(in: 0...2)], 1.1, z]
        node.isActive = true
        node.entity.isEnabled = true
    }

    // MARK: Collection

    private func updateCoins(dt: Float) {
        let magnetActive = state.activePowerUp == .magnet
        let playerCenterY = playerY + (isSliding ? 0.5 : 0.9)

        for coin in coinPool where coin.isActive {
            var position = coin.entity.position

            if magnetActive {
                let dz = position.z
                if dz > -8 && dz < 2 {
                    let target = SIMD3<Float>(playerX, playerCenterY, 0)
                    let delta = target - position
                    let distance = simd_length(delta)
                    if distance < 6 {
                        position += simd_normalize(delta) * min(distance, 16 * dt)
                        coin.entity.position = position
                    }
                }
            }

            if abs(position.z) < 0.8,
               abs(position.x - playerX) < 0.95,
               abs(position.y - playerCenterY) < 1.25 {
                coin.isActive = false
                coin.entity.isEnabled = false
                state.coins += 1
                audio.play(.coin)
                haptics.coin()
            }
        }
    }

    private func updatePowerUps(dt: Float) {
        // Pickup detection
        for pool in powerUpPools.values {
            for node in pool where node.isActive {
                let position = node.entity.position
                if abs(position.z) < 0.9, abs(position.x - playerX) < 1.0, playerY < 2.2 {
                    node.isActive = false
                    node.entity.isEnabled = false
                    activatePowerUp(node.type)
                }
            }
        }

        // Active power-up countdown
        if let active = state.activePowerUp {
            powerUpTimer -= dt
            state.powerUpProgress = Double(max(0, powerUpTimer / active.duration))
            if powerUpTimer <= 0 {
                if active == .doubleScore { state.multiplier = 1 }
                if active == .jetpack { jetpackActive = false }
                state.activePowerUp = nil
                state.powerUpProgress = 0
            }
        }
    }

    private func activatePowerUp(_ type: PowerUpType) {
        state.activePowerUp = type
        powerUpTimer = type.duration
        state.powerUpProgress = 1
        audio.play(.powerUp)
        haptics.powerUp()

        switch type {
        case .doubleScore:
            state.multiplier = 2
        case .jetpack:
            jetpackActive = true
            isSliding = false
            slideTimer = 0
        case .magnet:
            break
        }
    }

    // MARK: Inspector chase

    private func updateInspector(dt: Float) {
        if inspectorIntroTimer > 0 {
            inspectorIntroTimer -= dt
            if inspectorIntroTimer <= 0, inspectorGraceTimer <= 0 {
                inspectorTargetZ = 8.5
            }
        }

        if inspectorGraceTimer > 0 {
            inspectorGraceTimer -= dt
            if inspectorGraceTimer <= 0 {
                state.inspectorClose = false
                inspectorTargetZ = 8.5
            }
        }

        let currentZ = inspectorContainer.position.z
        let newZ = currentZ + (inspectorTargetZ - currentZ) * min(1, dt * 2.2)
        let bob = abs(sin(runTime * 8)) * 0.06
        inspectorContainer.position = [playerX * 0.6 - 0.7, bob, newZ]
        dogContainer.position = [playerX * 0.6 + 0.8, abs(sin(runTime * 9 + 1)) * 0.1, newZ + 0.4]
    }

    // MARK: Camera

    private func updateCamera(dt: Float) {
        var shakeX: Float = 0
        var shakeY: Float = 0
        if shakeTimer > 0 {
            shakeTimer -= dt
            let intensity = shakeTimer * 0.5
            shakeX = Float.random(in: -intensity...intensity)
            shakeY = Float.random(in: -intensity...intensity)
        }
        let camY: Float = 3.3 + playerY * 0.35
        camera.position = [playerX * 0.55 + shakeX, camY + shakeY, 6.4]
        camera.look(at: [playerX * 0.7, 1.1 + playerY * 0.4, -5], from: camera.position, relativeTo: nil)
    }

    private func updateCrashCamera(dt: Float) {
        if shakeTimer > 0 {
            shakeTimer -= dt
            let intensity = shakeTimer * 0.6
            camera.position = [
                playerX * 0.55 + Float.random(in: -intensity...intensity),
                3.3 + Float.random(in: -intensity...intensity),
                6.4,
            ]
            camera.look(at: [playerX * 0.7, 1.1, -5], from: camera.position, relativeTo: nil)
        }
    }

    // MARK: Collisions

    private func checkCollisions() {
        guard !crashHandled else { return }
        // Jetpack soars over everything
        guard !jetpackActive, playerY < 2.4 else { return }

        let playerHalfWidth: Float = 0.42
        let playerHeight: Float = isSliding ? 0.95 : 1.75
        let playerBottom = playerY
        let playerTop = playerY + playerHeight
        let playerHalfDepth: Float = 0.35

        for node in trainPool + lowBarrierPool + overheadBarrierPool where node.isActive {
            let position = node.entity.position
            let overlapX = abs(position.x - playerX) < (node.halfExtents.x * 0.85 + playerHalfWidth)
            let overlapZ = abs(position.z) < (node.halfExtents.z + playerHalfDepth)
            let obstacleBottom = position.y + node.boundsCenterY - node.halfExtents.y
            let obstacleTop = position.y + node.boundsCenterY + node.halfExtents.y
            let overlapY = playerBottom < obstacleTop && playerTop > obstacleBottom

            guard overlapX, overlapZ, overlapY else { continue }

            switch node.kind {
            case .trainParked, .trainMoving:
                crash(reason: .crashedIntoTrain)
                return
            case .barrierLow, .barrierOverhead:
                if state.inspectorClose {
                    crash(reason: .caughtByInspector)
                    return
                }
                stumble(through: node)
            }
        }
    }

    private func stumble(through node: ObstacleNode) {
        node.isActive = false
        node.entity.isEnabled = false
        speedPenaltyTimer = 1.1
        inspectorGraceTimer = WorldConfig.inspectorGraceDuration
        inspectorTargetZ = 2.6
        state.inspectorClose = true
        shakeTimer = 0.35
        haptics.stumble()
        audio.play(.crash)
    }

    private func crash(reason: RunEndReason) {
        crashHandled = true
        shakeTimer = 0.6
        haptics.crash()
        audio.play(.crash)
        audio.stopMusic()
        runnerAnimator?.stop()
        runnerAnimator?.playOnce(GeneratedAssets.runnerKnockDown, restoreAfter: .seconds(30))
        inspectorAnimator?.setLoop(GeneratedAssets.inspectorIdle)

        if reason == .caughtByInspector {
            inspectorTargetZ = 0.9
        }

        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1000))
            guard let self else { return }
            self.state.finishRun(reason: reason)
        }
    }
}
