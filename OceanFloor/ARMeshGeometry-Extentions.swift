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
    func createExtractedMeshDescriptor(for classification: ARMeshClassification) -> MeshDescriptor {
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
        
        /******************************************
         Ran out of time trying to get this working at the end.
         The idea here was to average the normals for each face and only include faces where that normal
         is mostly pointing up.
         
        let Up : SIMD3<Float> = .init(0.0, 1.0, 0.0)
        let toleranceAngleDegrees = 10.0
        let cosineOfToleranceAngle: Float  = Float(cos(toleranceAngleDegrees * .pi / 180.0))
        
        var matchingFaces: [UInt32] = [] // holds the faces buffer that only contains faces that match our classification and orientation
        for faceIndex in 0..<faces.count {
            if classificationOf(faceWithIndex: faceIndex) == classification {
                let indices = (0..<faces.indexCountPerPrimitive).map {
                    faces.buffer.contents()
                        .advanced(by: (faceIndex * faces.indexCountPerPrimitive + $0) * faces.bytesPerIndex)
                        .assumingMemoryBound(to: UInt32.self).pointee
                }
                let normals = indices.map { normalValues[Int($0)] }
                let averagedNormal = normals.reduce(SIMD3<Float>(0,0,0), +) / Float(normals.count)
                let normalizedAveragedNormal = normalize(averagedNormal)
                
                if dot(normalValues[faceIndex], Up) > cosineOfToleranceAngle {
                    // This face matches the requested classification
                    // and it is within the tolerance of the desired normal (Up)
                    
                    // $$$$ Note (avy): use a mapping function to do this instead of having this similar code.
                    let v1Index = faces.buffer.contents()
                        .advanced(by: (faceIndex * faces.bytesPerIndex * faces.indexCountPerPrimitive) )
                        .assumingMemoryBound(to: UInt32.self).pointee
                    
                    let v2Index = faces.buffer.contents()
                        .advanced(by: (faceIndex * faces.bytesPerIndex * faces.indexCountPerPrimitive) + (faces.bytesPerIndex) )
                        .assumingMemoryBound(to: UInt32.self).pointee
                    
                    let v3Index = faces.buffer.contents()
                        .advanced(by: (faceIndex * faces.bytesPerIndex * faces.indexCountPerPrimitive) + (2*faces.bytesPerIndex))
                        .assumingMemoryBound(to: UInt32.self).pointee
                    
                    matchingFaces.append(v1Index)
                    matchingFaces.append(v2Index)
                    matchingFaces.append(v3Index)
                }
            }
        }
         */

        do {
            // Was using .polygons here, but everything seems to always be tris, so using .triangles here then the face vert count array is unneeded.
            desc.primitives = .triangles(
                // filter only those faces that are classified as requested by the caller, ignore all other faces.
                (0..<faces.count * faces.indexCountPerPrimitive).filter({
                    let faceIndex = Int($0/faces.indexCountPerPrimitive)
                    return classificationOf(faceWithIndex: faceIndex) == classification
                }).map {
                    faces.buffer.contents()
                        .advanced(by: $0 * faces.bytesPerIndex)
                        .assumingMemoryBound(to: UInt32.self).pointee
                }
            )
        }
        
        return desc
    }
}


