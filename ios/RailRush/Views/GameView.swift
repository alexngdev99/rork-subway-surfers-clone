import RealityKit
import SwiftUI

/// Hosts the RealityKit scene and routes swipe input into the world.
struct GameView: View {
    let world: RunnerWorld
    @State private var swipeConsumed = false

    var body: some View {
        RealityView { content in
            content.camera = .virtual
            await world.build(in: content)
            world.updateSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                world.tick(deltaTime: Float(event.deltaTime))
            }
        }
        .ignoresSafeArea()
        .gesture(
            DragGesture(minimumDistance: 24)
                .onChanged { value in
                    guard !swipeConsumed else { return }
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard abs(dx) > 30 || abs(dy) > 30 else { return }
                    swipeConsumed = true
                    world.handleSwipe(dx: dx, dy: dy)
                }
                .onEnded { _ in
                    swipeConsumed = false
                }
        )
    }
}
