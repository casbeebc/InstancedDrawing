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
    var uid: IndexType
    
    init() {
        vi = 0
        ti = 0
        ni = 0
        uid = IndexType(arc4random_uniform(UInt32(IndexType.max-1)))
    }
}

func ==(lhs: FaceVertex, rhs: FaceVertex) -> Bool {
    return lhs.vi == rhs.vi && lhs.ti == rhs.ti && lhs.ni == rhs.ni
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
    var vertices: [vector_float4] = []
    var normals: [vector_float4] = []
    var texCoords: [vector_float2] = []
    var groupVertices: [Vertex] = []
    var groupIndices: [IndexType] = []
    var vertexToGroupIndexMap: [FaceVertex] = []
    
    var mutableGroups: [Group] = []
    var currentGroup: Group?
    var shouldGenerateNormals: Bool
    
    
    init (fileURL: NSURL, generateNormals: Bool) {
        
        shouldGenerateNormals = generateNormals
        
        super.init()
        
        self.parseModelAtURL(fileURL)
    }
    
    func groupForName(groupName: String) -> Group? {
        var returnedGroup : Group? = nil
        for obj in mutableGroups {
            if obj.name == groupName {
                returnedGroup = obj
                break
            }
        }
        return returnedGroup
    }
    
    func beginGroupWithName(name: NSString) {
        let newGroup : Group = Group(name: String(name))
        self.mutableGroups.append(newGroup)
        self.currentGroup = newGroup
    }
    
    func parseModelAtURL(fileURL: NSURL) {
        
        do {
            if let contents : NSString = try NSString(contentsOfURL:fileURL, encoding:NSASCIIStringEncoding) {
            
                let scanner : NSScanner = NSScanner(string: contents as String)
                let skipSet : NSCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
                let consumeSet : NSCharacterSet = skipSet.invertedSet
                
                scanner.charactersToBeSkipped = skipSet
                
                let endlineCharacters : NSCharacterSet = NSCharacterSet.newlineCharacterSet()
                
                self.beginGroupWithName("(unnamed)")
                
                while (!scanner.atEnd) {
            
                    var token: NSString? = ""
                    
                    
                    if (!scanner.scanCharactersFromSet(consumeSet, intoString: &token))
                    {
                        return
                    }
                    
                    if (token!.isEqualToString("v"))
                    {
                        var x : Float = 0
                        var y : Float = 0
                        var z : Float = 0
                        
                        scanner.scanFloat(&x)
                        scanner.scanFloat(&y)
                        scanner.scanFloat(&z)
                        
                        let v : vector_float4 = [ x, y, z, 1 ]
                        vertices.append(v)
                    }
                    else if (token!.isEqualToString("vt"))
                    {
                        var u : Float = 0
                        var v : Float = 0
                        
                        scanner.scanFloat(&u)
                        scanner.scanFloat(&v)
                        
                        let vt : vector_float2 = [ u, v ]
                        texCoords.append(vt)
                    }
                    else if (token!.isEqualToString("vn"))
                    {
                        var nx : Float = 0
                        var ny : Float = 0
                        var nz : Float = 0
                        
                        scanner.scanFloat(&nx)
                        scanner.scanFloat(&ny)
                        scanner.scanFloat(&nz)
                        
                        let vn : vector_float4 = [ nx, ny, nz, 0 ]
                        normals.append(vn)
                    }
                    else if (token!.isEqualToString("f"))
                    {
                        var faceVertices : [FaceVertex] = []
                        
                        while true {
                            var vi : Int32 = 0
                            // NOTE: was implemented, but ti is always 0 and never used in the Objective-C version of this project
                            // var ti : Int32 = 0
                            var ni : Int32 = 0
                            if !scanner.scanInt(&vi) {
                                break
                            }
                            
                            if scanner.scanString("/", intoString: nil) {
                                
                                scanner.scanInt(&vi)
                                
                                if scanner.scanString("/", intoString: nil) {
                                    scanner.scanInt(&ni)
                                }
                            }
                            
                            var faceVertex : FaceVertex = FaceVertex()
                            
                            // OBJ format allows relative vertex references in the form of negative indices, and
                            // dictates that indices are 1-based. Below, we simultaneously fix up negative indices
                            // and offset everything by -1 to allow 0-based indexing later on.
                            
                            faceVertex.vi = (vi < 0) ? IndexType(vertices.count + vi - 1) : IndexType(vi - 1)
                            
                            // NOTE: was implemented, but ti is always 0 in the Objective-C version of this project
                            //faceVertex.ti = (ti < 0) ? IndexType(texCoords.count + ti - 1) : IndexType(ti - 1)
                            
                            faceVertex.ni = (ni < 0) ? IndexType(vertices.count + ni - 1) : IndexType(ni - 1)
                            
                            faceVertices.append(faceVertex)
                            
                        }
                        
                        self.addFaceWithFaceVertices(&faceVertices)
                        
                    } else if(token!.isEqualToString("g")) {
                        
                        var groupName: NSString? = ""
                        
                        
                        if (scanner.scanCharactersFromSet(endlineCharacters, intoString: &groupName)) {
                            self.beginGroupWithName(groupName!)
                        }
                        
                    }

                }
            }
        } catch {
            
        }
        
        self.endCurrentGroup()
    }
    
    func endCurrentGroup() {
        
        if self.currentGroup != nil {
            return
        }
        if self.shouldGenerateNormals {
            self.generateNormalsForCurrentGroup()
        }
        
        // Once we've read a complete group, we copy the packed vertices that have been referenced by the group
        // into the current group object. Because it's fairly uncommon to have cross-group shared vertices, this
        // essentially divides up the vertices into disjoint sets by group.
        
        let vertexData : NSData = NSData(bytes: groupVertices, length: sizeof(Vertex) * groupVertices.count)
        self.currentGroup!.vertexData = vertexData;
        
        let indexData : NSData = NSData(bytes: groupIndices, length: sizeof(IndexType) * groupIndices.count)
        self.currentGroup!.indexData = indexData;
    }
    
    func generateNormalsForCurrentGroup() {
        let ZERO : vector_float4 = [0, 0, 0, 0]
        
        for var i = 0; i < groupVertices.count; ++i {
            groupVertices[i].normal = ZERO
        }
        
        for var i = 0; i < groupIndices.count; i += 3 {
            
            let i0 = Int(groupIndices[i])
            let i1 = Int(groupIndices[i+1])
            let i2 = Int(groupIndices[i+3])
            
            var v0 : Vertex = groupVertices[i0]
            var v1 : Vertex = groupVertices[i1]
            var v2 : Vertex = groupVertices[i2]
            
            let p0: vector_float3 = [v0.position.x, v0.position.y, v0.position.z]
            let p1: vector_float3 = [v1.position.x, v1.position.y, v1.position.z]
            let p2: vector_float3 = [v2.position.x, v2.position.y, v2.position.z]
            
            let cross : vector_float3 = MatrixUtilities.vector_cross((p1-p0), right: (p2-p0))
            let cross4 : vector_float4 = [cross.x, cross.y, cross.z, 0]
            
            v0.normal += cross4
            v1.normal += cross4
            v2.normal += cross4
        }
        
        for var i=0; i < groupVertices.count; ++i {
            groupVertices[i].normal = MatrixUtilities.vector_normalize(groupVertices[i].normal)
        }
        
    }
    
    func addFaceWithFaceVertices(inout faceVertices: [FaceVertex]) {
        
        // Transform polygonal faces into "fans" of triangles, three vertices at a time
        for var i=0; i < faceVertices.count - 2; ++i {
            
            self.addVertexToCurrentGroup(&faceVertices[i])
            self.addVertexToCurrentGroup(&faceVertices[i+1])
            self.addVertexToCurrentGroup(&faceVertices[i+2])
            
        }
        
    }
    
    func addVertexToCurrentGroup(inout fv: FaceVertex) {
        let up: vector_float4 = [0, 1, 0, 0]
        let zero2: vector_float2 = [0, 0]
        let invalidIndex: IndexType = IndexType.max
        
        var groupIndex: IndexType? = nil
        var hasFoundVertex: Bool = false
        
        for v in vertexToGroupIndexMap {
            if(v == fv) {
                groupIndex = v.uid
                hasFoundVertex = true
                break
            }
        }
        
        if !hasFoundVertex {
            var newVertex : Vertex = Vertex()
            newVertex.position = vertices[Int(fv.vi)]
            
            if fv.ni != invalidIndex {
                newVertex.normal = normals[Int(fv.ni)]
            } else {
                newVertex.normal = up
            }
            
            if fv.ti != invalidIndex {
                newVertex.texCoords = texCoords[Int(fv.ti)]
            } else {
                newVertex.texCoords = zero2
            }
            
            groupVertices.append(newVertex)
            groupIndex = IndexType(groupVertices.count - 1)
            fv.uid = groupIndex!
        }
        
        groupIndices.append(groupIndex!)

    }
}