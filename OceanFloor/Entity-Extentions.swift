import RealityKit

// This came from Apple sample code
//
// Although it's been adapted to also set a texture on the custom material as well.

internal extension Entity {
    /// This method sets the custom vector on an entity's material and its children's materials.
    @available(iOS 15.0, *)
    func setCustomVectorAndTexture(vector: SIMD4<Float>, texture: CustomMaterial.Texture) {
        children.forEach { $0.setCustomVectorAndTexture(vector: vector, texture: texture) }
        
        guard var comp = components[ModelComponent.self] as? ModelComponent else { return }
        comp.materials = comp.materials.map { (material) -> Material in
            if var customMaterial = material as? CustomMaterial {
                customMaterial.custom.value = vector
                customMaterial.custom.texture = texture
                return customMaterial
            }
            return material
        }
        components[ModelComponent.self] = comp
    }
}
