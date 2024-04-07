import RealityKit
import Combine

// A basic component to tag our wavwe entities so we
// WaveSystem can find them to update them when custom shader
// params change.
struct WaveComponent: RealityKit.Component {
    static let Query = EntityQuery(where: .has(WaveComponent.self))
    
    public init() {
    }
}


