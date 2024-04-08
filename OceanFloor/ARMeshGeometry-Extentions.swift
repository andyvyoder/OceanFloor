import RealityKit
import ARKit

extension ARMeshGeometry {
    
    // Given the index of a face, this returns it's classification
    func classificationOf(faceWithIndex index: Int) -> ARMeshClassification {
        guard let classification = classification else { return .none }
        let classificationAddress = classification.buffer.contents().advanced(by: index)
        let classificationValue = Int(classificationAddress.assumingMemoryBound(to: UInt8.self).pointee)
        return ARMeshClassification(rawValue: classificationValue) ?? .none
    }
    
    
    // This will go through the geometry and look every face. If the face is classified according
    // to the callers request it will be added to the returned MeshDescriptor.
    func createExtractedMeshDescriptor(for classification: ARMeshClassification, 
                                       referenceNormal: SIMD3<Float> = .init(0.0, 1.0, 0.0), // Up
                                       normalToleranceAngleDegrees: Float = 10.0) -> MeshDescriptor {
        var desc = MeshDescriptor()
        
        
        if faces.indexCountPerPrimitive != 3 {
            assertionFailure("Mesh was using primative other than tris. Expecting only triangles")
        }
        
        // Note (avy): This is copying ALL the verts and normals from the original geometry even though we
        // won't use all of them because we're only extracting a subset of the original geometry's faces.
        //
        // This means the MeshDescriptor takes up more memory than it really should.
        // Return to this for future memory optinmization.
        let posValues = vertices.asSIMD3(ofType: Float.self)
        desc.positions = .init(posValues)
        let normalValues = normals.asSIMD3(ofType: Float.self)
        desc.normals = .init(normalValues)
        
        
        let toleranceAngleRadians = normalToleranceAngleDegrees * .pi / 180.0
        let cosineOfToleranceAngle: Float  = Float(cos(toleranceAngleRadians))
        
        var matchingFacesVertIndices: [UInt32] = [] // holds the faces buffer that only contains faces that match our classification and orientation
        for faceIndex in 0..<faces.count {
            if classificationOf(faceWithIndex: faceIndex) != classification {
                // ignore this face, it's not the classification we're looking for
                continue
            }
            
            let faceVertNormalIndices : [UInt32] = (0..<faces.indexCountPerPrimitive).map {
                // Get the normal index for face# faceIndex's vertex# $0
                faces.buffer.contents()
                    .advanced(by: (faceIndex * faces.indexCountPerPrimitive + $0) * faces.bytesPerIndex)
                    .assumingMemoryBound(to: UInt32.self).pointee
            }
            
            let normalizedAveragedFaceNormal: SIMD3<Float> = {
                let faceNormals: [SIMD3<Float>] = faceVertNormalIndices.map { normalValues[Int($0)] }
                let averagedFaceNormal = faceNormals.reduce(SIMD3<Float>(0,0,0), +) / Float(normals.count)
                return normalize(averagedFaceNormal)
            }()
            
            if dot(normalizedAveragedFaceNormal, referenceNormal) < cosineOfToleranceAngle {
                // This face isn't oriented close enough to the reference direction,
                // reject it even though it matched the required classification
                continue
            }
        
            // This face matches the requested classification
            // and it is within the tolerance of the desired orientation
            
            matchingFacesVertIndices += faceVertNormalIndices
        }

        do {
            // Was using .polygons here, but everything seems to always be tris, so using .triangles here then the face vert count array is unneeded.
            desc.primitives = .triangles(
                matchingFacesVertIndices
            )
        }
        
        return desc
    }
}


