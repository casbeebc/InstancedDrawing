//
//  Mesh.swift
//  InstancedDrawing
//
//  Created by brett on 7/24/15.
//  Copyright © 2015 DataMingle. All rights reserved.
//

import Foundation
import Metal

class ObjectMesh : NSObject {
    
    var indexBuffer: MTLBuffer
    var vertexBuffer: MTLBuffer
    var groupName: String
    
    init (group: Group, device: MTLDevice) {
        
        vertexBuffer = device.newBufferWithBytes(group.vertexData!.bytes, length: group.vertexData!.length, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        vertexBuffer.label = "Vertices ("+group.name+")"
        
        indexBuffer = device.newBufferWithBytes(group.indexData!.bytes, length: group.indexData!.length, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        indexBuffer.label  = "Indices ("+group.name+")"
        
        groupName = group.name
    }

}