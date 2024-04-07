/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Vector math utilities.
*/

import RealityKit

extension SIMD3 where Scalar == Float {

    func distance(from other: SIMD3<Float>) -> Float {
        return simd_distance(self, other)
    }
}

extension SIMD2 where Scalar == Float {
    func distance(from other: Self) -> Float {
        return simd_distance(self, other)
    }

    var length: Float { return distance(from: .init()) }
}

