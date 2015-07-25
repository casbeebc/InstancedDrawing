//
//  Model.swift
//  InstancedDrawing
//
//  Created by brett on 7/24/15.
//  Copyright © 2015 DataMingle. All rights reserved.
//

import Foundation
import simd

// "Face vertices" are tuples of indices into file-wide lists of positions, normals, and texture coordinates.
// We maintain a mapping from these triples to the indices they will eventually occupy in the group that
// is currently being constructed.
struct FaceVertex
{
    var vi: UInt16
    var ti: UInt16
    var ni: UInt16
    
}

func <(v0:FaceVertex, v1:FaceVertex) -> Bool {
    
    if (v0.vi < v1.vi) {
        return true
    } else if (v0.vi > v1.vi) {
        return false
    } else if (v0.ti < v1.ti) {
        return true
    } else if (v0.ti > v1.ti) {
        return false
    } else if (v0.ni < v1.ni) {
        return true
    } else if (v0.ni > v1.ni) {
        return false
    } else {
        return false
    }
}

class Model : NSObject {
    
    var groups : NSArray = []
    var vertices: [vector_float4]
    var normals: [vector_float4]
    var texCoords: [vector_float2]
    var groupVertices: [Vertex]
    var groupIndices: [IndexType]
    var vertexToGroupIndexMap: [IndexType: FaceVertex]
    
    
    init (fileURL: NSURL, generateNormals: Bool) {
        
    }
}