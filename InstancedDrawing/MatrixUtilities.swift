//
//  MatrixUtilities.swift
//  InstancedDrawing
//
//  Created by brett on 7/23/15.
//  Copyright (c) 2015 DataMingle. All rights reserved.
//
import Foundation
import simd

/*

Example SIMD usage:

import simd
let vec1 = float4(1.0, 2.0, 3.0, 4.0)
let length1 = length(vec1)
let vec2 = float4(1.0, 1.0, -1.0, -1.0)
let dotProduct = dot(vec1, vec2)
let elementwiseMultiplication = vec1*vec2
let matrix1 = float4x4([[0,1,1,1], [-1,2,0,3], [-3,0,-4,5],[-1,-1,2,2]])
let matrix2 = float4x4(diagonal:[1,2,3,4])
let matrix3 = matrix1 + matrix2
let matrix4 = matrix3.transpose

*/

class MatrixUtilities : NSObject {
    
    override init() {
        
    }
    
    static func matrix_identity() -> matrix_float4x4 {
        
        let X : vector_float4 = [1, 0, 0, 0]
        let Y : vector_float4 = [0, 1, 0, 0]
        let Z : vector_float4 = [0, 0, 1, 0]
        let W : vector_float4 = [0, 0, 0, 1]
        
        let identity : matrix_float4x4  = matrix_float4x4(columns:(X, Y, Z, W))
        
        return identity;
    }

    static func matrix_rotation(axis: vector_float3, angle: Float) -> matrix_float4x4 {
        let c : Float = cos(angle)
        let s : Float = sin(angle)
        
        var X = vector_float4()
        X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c;
        X.y = axis.x * axis.y * (1 - c) - axis.z*s;
        X.z = axis.x * axis.z * (1 - c) + axis.y * s;
        X.w = 0.0;
        
        var Y = vector_float4()
        Y.x = axis.x * axis.y * (1 - c) + axis.z * s;
        Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c;
        Y.z = axis.y * axis.z * (1 - c) - axis.x * s;
        Y.w = 0.0;
        
        var Z = vector_float4()
        Z.x = axis.x * axis.z * (1 - c) - axis.y * s;
        Z.y = axis.y * axis.z * (1 - c) + axis.x * s;
        Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c;
        Z.w = 0.0;
        
        var W = vector_float4()
        W.x = 0.0;
        W.y = 0.0;
        W.z = 0.0;
        W.w = 1.0;
        
        let mat : matrix_float4x4 = matrix_float4x4(columns:(X, Y, Z, W))
        
        return mat;
    }

    static func matrix_translation(t: vector_float3) -> matrix_float4x4 {
        let X : vector_float4 = [1, 0, 0, 0]
        let Y : vector_float4 = [0, 1, 0, 0]
        let Z : vector_float4 = [0, 0, 1, 0]
        let W : vector_float4 = [t.x, t.y, t.z, 1]
        
        let mat : matrix_float4x4 = matrix_float4x4(columns:(X, Y, Z, W))
        
        return mat
    }

    static func matrix_scale(s: vector_float3) -> matrix_float4x4 {
        let X : vector_float4 = [s.x,   0,   0,  0]
        let Y : vector_float4 = [  0, s.y,   0,  0]
        let Z : vector_float4 = [  0,   0, s.z,  0]
        let W : vector_float4 = [  0,   0,   0,  1]
        
        let mat : matrix_float4x4 = matrix_float4x4(columns:(X, Y, Z, W))
        
        return mat
    }

    static func matrix_uniform_scale(s: Float) -> matrix_float4x4 {
        let X : vector_float4 = [s, 0, 0, 0]
        let Y : vector_float4 = [0, s, 0, 0]
        let Z : vector_float4 = [0, 0, s, 0]
        let W : vector_float4 = [0, 0, 0, 1]
        
        let mat : matrix_float4x4 = matrix_float4x4(columns:(X, Y, Z, W))
        
        return mat
    }

    static func matrix_perspective_projection (aspect: Float, fovy: Float, near: Float, far: Float) -> matrix_float4x4 {
        let yScale = 1 / tan(fovy * 0.5)
        let xScale = yScale / aspect
        let zRange = far - near
        let zScale = -(far + near) / zRange
        let wScale = -2 * far * near / zRange
        
        let P : vector_float4 = [xScale, 0, 0, 0]
        let Q : vector_float4 = [0, yScale, 0, 0]
        let R : vector_float4 = [0, 0, zScale, -1]
        let S : vector_float4 = [0, 0, wScale, 0]
        
        let mat : matrix_float4x4 = matrix_float4x4(columns:(P, Q, R, S))
        
        return mat
    }

    static func matrix_upper_left3x3 (mat4x4: matrix_float4x4) -> matrix_float3x3 {
        
        let column1: vector_float3 = [mat4x4.columns.0.x, mat4x4.columns.0.y, mat4x4.columns.0.z]
        let column2: vector_float3 = [mat4x4.columns.1.x, mat4x4.columns.1.y, mat4x4.columns.1.z]
        let column3: vector_float3 = [mat4x4.columns.2.x, mat4x4.columns.2.y, mat4x4.columns.2.z]
        
        let mat3x3: matrix_float3x3 = matrix_float3x3(columns: (column1, column2, column3))
        
        return mat3x3
    }
    
}






