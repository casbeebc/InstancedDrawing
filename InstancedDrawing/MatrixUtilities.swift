//
//  MatrixUtilities.swift
//  InstancedDrawing
//
//  Created by brett on 7/23/15.
//  Copyright (c) 2015 DataMingle. All rights reserved.
//

func matrix_identity() -> matrix_float4x4 {
    
    let X : vector_float4 = [1, 0, 0, 0]
    let Y : vector_float4 = [0, 1, 0, 0]
    let Z : vector_float4 = [0, 0, 1, 0]
    let W : vector_float4 = [0, 0, 0, 1]
    
    let identity : matrix_float4x4  = [X, Y, Z, W];
    
    return identity;
}

func matrix_rotation(axis: vector_float3, angle: Float) -> matrix_float4x4 {
    let c : Float = cos(angle)
    let s : Float = sin(angle)
    
    X = vector_float4()
    X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c;
    X.y = axis.x * axis.y * (1 - c) - axis.z*s;
    X.z = axis.x * axis.z * (1 - c) + axis.y * s;
    X.w = 0.0;
    
    Y = vector_float4()
    Y.x = axis.x * axis.y * (1 - c) + axis.z * s;
    Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c;
    Y.z = axis.y * axis.z * (1 - c) - axis.x * s;
    Y.w = 0.0;
    
    Z = vector_float4()
    Z.x = axis.x * axis.z * (1 - c) - axis.y * s;
    Z.y = axis.y * axis.z * (1 - c) + axis.x * s;
    Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c;
    Z.w = 0.0;
    
    W = vector_float4()
    W.x = 0.0;
    W.y = 0.0;
    W.z = 0.0;
    W.w = 1.0;
    
    let mat : matrix_float4x4 = [ X, Y, Z, W ]
    
    return mat;
}

func matrix_translation(t: vector_float3) -> matrix_float4x4 {
    let X : vector_float4 = [1, 0, 0, 0]
    let Y : vector_float4 = [0, 1, 0, 0]
    let Z : vector_float4 = [0, 0, 1, 0]
    let W : vector_float4 = [t.x, t.y, t.z, 1]
    
    let mat : matrix_float4x4 = [ X, Y, Z, W ]
    
    return mat
}

func matrix_scale(s: vector_float3) -> matrix_float4x4 {
    let X : vector_float4 = [s.x,   0,   0,  0]
    let Y : vector_float4 = [  0, s.y,   0,  0]
    let Z : vector_float4 = [  0,   0, s.z,  0]
    let W : vector_float4 = [  0,   0,   0,  1]
    
    let mat : matrix_float4x4 = [ X, Y, Z, W ]
    
    return mat
}

func matrix_uniform_scale(s: Float) -> matrix_float4x4 {
    let X : vector_float4 = [s, 0, 0, 0]
    let Y : vector_float4 = [0, s, 0, 0]
    let Z : vector_float4 = [0, 0, s, 0]
    let W : vector_float4 = [0, 0, 0, 1]
    
    let mat : matrix_float4x4 = [ X, Y, Z, W ]
    
    return mat
}

func matrix_perspective_projection (aspect: Float, fovy: Float, near: Float, far: Float) -> matrix_float4x4 {
    yScale = 1 / tan(fovy * 0.5)
    xScale = yScale / aspect
    zRange = far - near
    zScale = -(far + near) / zRange
    wzScale = -2 * far * near / zRange
    
    let P : vector_float4 = [xScale, 0, 0, 0]
    let Q : vector_float4 = [0, yScale, 0, 0]
    let R : vector_float4 = [0, 0, zScale, -1]
    let S : vector_float4 = [0, 0, wScale, 0]
    
    let mat : matrix_float4x4 = [ P, Q, R, S ]
    
    return mat
}

func matrix_upper_left3x3 (mat4x4: matrix_float4x4) -> matrix_float3x3 {
    let mat3x3 : matrix_float3x3 = [ mat4x4.columns[0].xyz, mat4x4.columns[1].xyz, mat4x4.columns[2].xyz ]
    return mat3x3
}