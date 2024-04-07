import ARKit
import RealityKit
import Combine


// Handles creating and managing AnchorEntities for ARMeshAnchors.
// notifies WaveSystem when AnchorEntities change.
class MeshAnchorTracker {

    var entries: [ARMeshAnchor: Entry] = [:]
    weak var arView: ARView?
    var settings: Settings

    init(arView: ARView, settings: Settings) {
        self.arView = arView
        self.settings = settings
    }

    class Entry {
        var entity: AnchorEntity
        
        init(entity: AnchorEntity) {
            self.entity = entity
        }
    }
    
    func addMeshAnchor(_ anchor: ARMeshAnchor) {
        let tracker: Entry = {
            let entity = AnchorEntity(world: SIMD3<Float>())
            let tracker = Entry(entity: entity)
            entries[anchor] = tracker
            arView?.scene.addAnchor(entity)
            return tracker
        }()
        
        tracker.entity.transform = .init(matrix: anchor.transform)
        
        WaveSystem.notifyMeshAnchorAdded(anchorEntity: tracker.entity, anchorGeometry: anchor.geometry)
    }
    
    func updateMeshAnchor(_ anchor: ARMeshAnchor) {
        guard let tracker: Entry = entries[anchor] else { return }

        tracker.entity.transform = .init(matrix: anchor.transform)
        
        WaveSystem.notifyMeshAnchorUpdated(anchorEntity: tracker.entity, anchorGeometry: anchor.geometry)
    }

    func removeMeshAnchor(_ anchor: ARMeshAnchor) {
        if let entry = self.entries[anchor] {
            WaveSystem.notifyMeshAnchorRemoved(anchorEntity: entry.entity)
            entry.entity.removeFromParent()
            self.entries[anchor] = nil
        }
    }
}


