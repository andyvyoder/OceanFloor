import RealityKit

// This came from Apple sample code

internal extension Entity {
    /// This method sets the custom vector on an entity's material and its children's materials.
    @available(iOS 15.0, *)
    func setCustomVector(vector: SIMD4<Float>) {
        children.forEach { $0.setCustomVector(vector: vector) }
        
        guard var comp = components[ModelComponent.self] as? ModelComponent else { return }
        comp.materials = comp.materials.map { (material) -> Material in
            if var customMaterial = material as? CustomMaterial {
                customMaterial.custom.value = vector
                return customMaterial
            }
            return material
        }
        components[ModelComponent.self] = comp
    }
}
