//
//  Types.swift
//  InstancedDrawing
//
//  Created by brett on 7/23/15.
//  Copyright (c) 2015 DataMingle. All rights reserved.
//

import Foundation
import simd

typealias IndexType = UInt16

struct Uniforms {
    var viewProjectionMatrix : matrix_float4x4?
}

struct PerInstanceUniforms {
    var modelMatrix : matrix_float4x4?
    var normalMatrix : matrix_float3x3?
}

struct Vertex {
    var position : packed_float4
    var normal : packed_float4
    var texCoords : packed_float2
    
    init() {
        position = []
        normal = []
        texCoords = []
    }
}