import RealityKit
import ARKit
import SwiftUI
import Combine


class WaveSystem: RealityKit.System {    
    private static var instance : WaveSystem? = nil
    
    //
    // Wave materials and material modifiers
    //
    
    private static var baseWaveMaterial: SimpleMaterial = SimpleMaterial(color: #colorLiteral(red:0.5, green:0.5, blue:0.5, alpha:1), isMetallic: true)
    
    // This produces the undulating sin wave
    private static let waveGeometryModifier: CustomMaterial.GeometryModifier = CustomMaterial.GeometryModifier(
        named: "waveGeometryModifier",
        in: MetalLibLoader.library
    )
    
    // This provides color control of the wave
    private static let waveSurfaceShader: CustomMaterial.SurfaceShader = CustomMaterial.SurfaceShader(
        named: "waveSurfaceShader",
        in: MetalLibLoader.library
    )
    
    
    private static let waveTexture = try? CustomMaterial.Texture(TextureResource.load(named: "cell_noise_1"))
    
    // This will be the final material to be used on wave models, combining the base material with the modifiers
    private var waveMaterial: CustomMaterial? = {
        guard var mat = try? CustomMaterial(from: baseWaveMaterial, surfaceShader: waveSurfaceShader, geometryModifier: waveGeometryModifier) else {
            return nil
        }
        
        guard let waveTexture = waveTexture else {
            print("Failed to load texture")
            return nil;
        }
        
        mat.custom.texture = .init(waveTexture)
        return mat
    }()
    
    
    // These are the values that are currently applied as custom parameters to our wave material
    private var currentWaveHeightScale: Float = 0.1
    private var currentWaveColor: Color = Color(red: 0.0, green: 0.0, blue: 1.0)
    
    
    // For every Mesh Anchor we have a mesh processing tracker for converting MeshDescriptions into
    // meshes for the Waves' ModelComponent.
    private var waveMeshProcessingTrackers: [Entity: WaveMeshProcessingTracker] = [:]
    
    
    required init(scene: RealityKit.Scene) {
        if Self.instance != nil {
            print("Error: Multiple instances of WaveSystem created.")
            return
        }
                
        Self.instance = self
    }
    
    public static func notifyMeshAnchorAdded(anchorEntity: AnchorEntity, anchorGeometry: ARMeshGeometry) {
        // Create a subset of the mesh that is just tagged as floor
        let desc = anchorGeometry.createExtractedMeshDescriptor(for: .floor)
        
        // Add WaveComponent so we can find this entity again.
        anchorEntity.components[WaveComponent.self] = WaveComponent()
        
        // queu processing of the wave's mesh
        Self.instance!.queueWaveMeshProcessing(for: anchorEntity, meshDescriptor: desc)
    }
    
    public static func notifyMeshAnchorUpdated(anchorEntity: AnchorEntity, anchorGeometry: ARMeshGeometry) {
        // Extract the floor tagged faces
        let desc = anchorGeometry.createExtractedMeshDescriptor(for: .floor)
        
        // queue processing of this mesh which will result it it being updated on the approriate Wave entity
        Self.instance!.queueWaveMeshProcessing(for: anchorEntity, meshDescriptor: desc)
    }
    
    public static func notifyMeshAnchorRemoved(anchorEntity: AnchorEntity) {
        Self.instance!.waveMeshProcessingTrackers[anchorEntity] = nil
    }
    
    private func queueWaveMeshProcessing(for entity: Entity, meshDescriptor: MeshDescriptor) {
        // get the mesh processing tracker for this entity
        let tracker: WaveMeshProcessingTracker = {
            if let tracker = waveMeshProcessingTrackers[entity] { return tracker }
            return WaveMeshProcessingTracker(parentEntity: entity, material: self.waveMaterial!, waveSystem: self)
        }()
        
        // queue processing of this mesh with this entities tracker.
        tracker.queueNextMeshUpdate(meshDescriptor: meshDescriptor)
    }
    
    func update(context: SceneUpdateContext) {
        // Update is called early by AppDelegate, but settings isn't assigned yet
        // in OceanView, so protect against this here.
        //
        // Clearly we should improve how settings are accessed
        guard let settings = OceanView.instance?.settings else {
            return
        }
        
        // check to see if the settings have changed from what's currently applied to the shader.
        
        let settingsWaveHeightScale:Float = Float(settings.waveHeightScale)
        let settingsWaveColor: Color = settings.waveColor
        
        // If custom shader param values haven't changed, we can return now and not push them.
        if self.currentWaveHeightScale == settingsWaveHeightScale && self.currentWaveColor == settingsWaveColor {
            return
        }
        
        // Update the new shader values we'll be using
        self.currentWaveHeightScale = settingsWaveHeightScale
        self.currentWaveColor = settingsWaveColor
        
        // push the new shader values to all entities with waves.
        context.scene.performQuery(WaveComponent.Query).forEach { entity in
            pushCustomMaterialParams(entity: entity)
        }
    }
    
    
    // Making this fileprivate so that WaveMeshProcessingTracker can call it.
    fileprivate func pushCustomMaterialParams(entity: Entity) {
        guard let waveTexture = Self.waveTexture else {
            return
        }
        
        let (red, green, blue) = self.currentWaveColor.getRGB()
        entity.setCustomVectorAndTexture(vector: SIMD4<Float>(x: red, y: green, z: blue, w: self.currentWaveHeightScale), texture: waveTexture)
    }
}



// Handles generating (and regenerating) the mesh used by a 
// ModelComponent on the same entity as the WaveComponent
class WaveMeshProcessingTracker {
    private var parentEntity: Entity
    private var waveMaterial: RealityKit.Material
    private var waveSystem: WaveSystem
    private var meshGenSub: Cancellable? = nil

    private var unprocessedMeshDesc: MeshDescriptor? = nil
    
    public init(parentEntity: Entity, material: RealityKit.Material, waveSystem: WaveSystem) {
        self.parentEntity = parentEntity
        self.waveMaterial = material
        self.waveSystem = waveSystem
    }
    
    public func queueNextMeshUpdate(meshDescriptor: MeshDescriptor)
    {
        if meshGenSub != nil {
            // There's currently a mesh generation running. So we're done for now.
            // Later when the current mesh generation completes, it will check to see
            // if there is unprocessedMeshDesc and will start it running.
            
            // If there's already an unprecessed mesh descriptor, it's ok that we just
            // replace it it. This new one if more current and since we hadn't started
            // that old mesh desc, just use the newer one next time.
            unprocessedMeshDesc = meshDescriptor
            
            return
        }
        
        // There is no currently running mesh generation so let's kick off one for
        // our task now.
        doAsyncMeshGeneration(meshDescriptor: meshDescriptor)
    }
    
    private func doAsyncMeshGeneration(meshDescriptor: MeshDescriptor) {
        meshGenSub = MeshResource.generateAsync(from: [meshDescriptor])
            .sink(
                receiveCompletion: { result in
                    switch result {
                    case .failure(let error): assertionFailure("\(error)")
                    default: return
                    }
                },
                receiveValue: { [self] mesh in
                    if self.parentEntity.components[ModelComponent.self] == nil {
                        // This is the first mesh being generated for this Wave.
                        // Add the ModelComponent
                        self.parentEntity.components[ModelComponent.self] = ModelComponent(
                            mesh: mesh,
                            materials: [waveMaterial]
                        )
                        
                        // Also since this is the first time this model has existed,
                        // we need to push the custom shader params to it.
                        self.waveSystem.pushCustomMaterialParams(entity: self.parentEntity)
                    } else {
                        // This is an update to an the existing mesh.
                        //
                        // Note: it's important to update just the mesh.
                        // Replacing the whole comoponent with a new mesh on it causes hitching.
                        self.parentEntity.components[ModelComponent.self]!.mesh = mesh
                    }
                    
                    // Check to see if there is another mesh generation waiting to be started.
                    // If so, start it.
                    if self.unprocessedMeshDesc != nil {
                        let desc = self.unprocessedMeshDesc
                        self.unprocessedMeshDesc = nil
                        self.doAsyncMeshGeneration(meshDescriptor: desc!)
                    }
                }
            )
    }
}
