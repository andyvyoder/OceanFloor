import ARKit
import Combine
import SwiftUI
import RealityKit

class OceanView: ARView, ARSessionDelegate {
    static var instance: OceanView? = nil
    
    init(frame: CGRect, settings: Settings) {
        self.settings = settings
        super.init(frame: frame)
        
        if Self.instance != nil {
            print("Error multiple instances of OceanView created")
        }
        
        Self.instance = self
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }

    var arView: ARView { return self }

    let settings: Settings
    
    private var meshAnchorTracker: MeshAnchorTracker?

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // Handle mesh anchors
        for anchor in anchors.compactMap({ $0 as? ARMeshAnchor }) {
            meshAnchorTracker?.addMeshAnchor(anchor)
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // Handle mesh anchors
        for anchor in anchors.compactMap({ $0 as? ARMeshAnchor }) {
            meshAnchorTracker?.updateMeshAnchor(anchor)
        }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        // Handle mesh anchors
        for anchor in anchors.compactMap({ $0 as? ARMeshAnchor }) {
            meshAnchorTracker?.removeMeshAnchor(anchor)
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
    }

    func setup() {
        MetalLibLoader.initializeMetal()
        configureWorldTracking()
    }

    private func configureWorldTracking() {
        let configuration = ARWorldTrackingConfiguration()

        let sceneReconstruction: ARWorldTrackingConfiguration.SceneReconstruction = .meshWithClassification
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(sceneReconstruction) {
            configuration.sceneReconstruction = sceneReconstruction
            meshAnchorTracker = .init(arView: self, settings: self.settings)
        }

        let frameSemantics: ARConfiguration.FrameSemantics = [.smoothedSceneDepth, .sceneDepth]
        if ARWorldTrackingConfiguration.supportsFrameSemantics(frameSemantics) {
            configuration.frameSemantics.insert(frameSemantics)
        }
        
        session.run(configuration)
        
        session.delegate = self
    }
}

