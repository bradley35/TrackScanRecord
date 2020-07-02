//
//  ViewController.swift
//  Track
//
//  Created by Bradley on 6/27/20.
//  Copyright © 2020 Bradley. All rights reserved.
//

import UIKit
import AVKit
import ARKit
import ModelIO
import Metal
import MetalKit
class ViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate, RecordButtonDelegate {

    @IBOutlet weak var scene: ARSCNView!
    @IBOutlet weak var sideView: UIView!
    
    let ar = ARSession()
    let config = ARWorldTrackingConfiguration()
    let coach = ARCoachingOverlayView()
    
    let done = UIButton(frame: CGRect(x:20, y:210, width:60, height:60))
    var record:RecordButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        scene.backgroundColor=UIColor.white
        switch AVCaptureDevice.authorizationStatus(for: .video){
            case .authorized:
                print("All Good")
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { (allowed) in
                    print(allowed)
            }
            default:
                //Not allowed
                print("oh No")
                fatalError("Must Allow Camera")
        }
        
 
        config.sceneReconstruction = []
        config.planeDetection = []//[.horizontal, .vertical]
        
        ar.run(config, options: [.resetTracking, .removeExistingAnchors])
        scene.session = ar
        scene.delegate = self
        scene.autoenablesDefaultLighting = true
        ar.delegate = self
        coach.frame = self.view.frame
        scene.addSubview(coach)
        coach.goal = .horizontalPlane
        coach.session = ar
        coach.activatesAutomatically = false
        coach.setActive(false, animated: true)
        let light_node = SCNNode()
        let light = SCNLight()
        light.intensity = 300
        light.type = .ambient
        light_node.light = light
        scene.scene.rootNode.addChildNode(light_node)
        
        sideView.backgroundColor = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.1)
        
        record = RecordButton(frame: CGRect(x: 0, y: sideView.frame.height/2-50, width: sideView.frame.width, height: sideView.frame.width))
        record.delegate = self
        sideView.addSubview(record)
        
        let reset = UIButton(frame: CGRect(x:0, y:10, width:100, height:100))
        reset.setImage(UIImage(systemName: "arrow.counterclockwise.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .thin)), for: .normal)
        reset.tintColor = UIColor.white
        reset.addTarget(self, action: #selector(resetTrack), for: .touchUpInside)
        
        
        var done_image = UIImage(named: "DoneButton")?.withRenderingMode(.alwaysTemplate)
        done.setImage(done_image, for: .normal)
        done.imageView!.contentMode = .scaleAspectFit
        done.tintColor = UIColor.white
        done.isEnabled = false
        done.addTarget(self, action: #selector(save), for: .touchUpInside)
        //reset.addTarget(self, action: #selector(reset(sender:)), for: .touchUpInside)
        sideView.addSubview(reset)
        sideView.addSubview(done)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(resetTrack), name: UIApplication.willEnterForegroundNotification, object:nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        print("Appear")
        resetTrack()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let mesh = (anchor as? ARMeshAnchor) else{
            return nil
        }
        coach.setActive(false, animated: true)
        DispatchQueue.main.async {
            self.done.isEnabled = true
        }
        let vertices = SCNGeometrySource(buffer: mesh.geometry.vertices.buffer, vertexFormat: mesh.geometry.vertices.format, semantic: .vertex, vertexCount: mesh.geometry.vertices.count, dataOffset: mesh.geometry.vertices.offset, dataStride: mesh.geometry.vertices.stride)
        
        let normals = SCNGeometrySource(buffer: mesh.geometry.normals.buffer, vertexFormat: mesh.geometry.normals.format, semantic: .normal, vertexCount: mesh.geometry.normals.count, dataOffset: mesh.geometry.normals.offset, dataStride: mesh.geometry.normals.stride)
        
        let faces = SCNGeometryElement(data: Data(bytesNoCopy: mesh.geometry.faces.buffer.contents(), count: mesh.geometry.faces.buffer.length, deallocator: .none), primitiveType: .triangles, primitiveCount: mesh.geometry.faces.count, bytesPerIndex: mesh.geometry.faces.bytesPerIndex)
        
        let geometry_fill = SCNGeometry(sources: [vertices, normals], elements: [faces])
        let geometry_outline = geometry_fill.copy() as! SCNGeometry
        
        
        let node = SCNNode()
        let node_fill = SCNNode(geometry: geometry_fill)
        node_fill.name = "Fill"
        
        let node_outline = SCNNode(geometry: geometry_outline)
        node_outline.name = "Outline"
        
        let material_fill = SCNMaterial()
        material_fill.diffuse.contents = UIColor(red: 1, green: 1, blue: 1, alpha: 0.95)
        material_fill.transparencyMode = .aOne
        material_fill.fillMode = .fill
        material_fill.lightingModel = .lambert
        
        let material_outline = SCNMaterial()
        material_outline.diffuse.contents = UIColor(red: 0.3, green: 1, blue: 1, alpha: 0.85)
        material_outline.diffuse.intensity = 1
        material_outline.fillMode = .lines
        material_outline.isDoubleSided = true
        material_outline.lightingModel = .constant
        
        geometry_fill.materials = [material_fill]
        geometry_outline.materials = [material_outline]
        
        node.simdTransform = mesh.transform
        
        node.addChildNode(node_fill)
        node.addChildNode(node_outline)
        node.name = "Mesh"
        return node
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let mesh = (anchor as? ARMeshAnchor) else{
            return
        }
        coach.setActive(false, animated: true)
        let vertices = SCNGeometrySource(buffer: mesh.geometry.vertices.buffer, vertexFormat: mesh.geometry.vertices.format, semantic: .vertex, vertexCount: mesh.geometry.vertices.count, dataOffset: mesh.geometry.vertices.offset, dataStride: mesh.geometry.vertices.stride)

        let normals = SCNGeometrySource(buffer: mesh.geometry.normals.buffer, vertexFormat: mesh.geometry.normals.format, semantic: .normal, vertexCount: mesh.geometry.normals.count, dataOffset: mesh.geometry.normals.offset, dataStride: mesh.geometry.normals.stride)

        let faces = SCNGeometryElement(data: Data(bytesNoCopy: mesh.geometry.faces.buffer.contents(), count: mesh.geometry.faces.buffer.length, deallocator: .none), primitiveType: .triangles, primitiveCount: mesh.geometry.faces.count, bytesPerIndex: mesh.geometry.faces.bytesPerIndex)

        
        let node_fill = node.childNode(withName: "Fill", recursively: false)!
        let node_outline = node.childNode(withName: "Outline", recursively: false)!
        let geometry_fill = SCNGeometry(sources: [vertices, normals], elements: [faces])
        let geometry_outline = geometry_fill.copy() as! SCNGeometry
        
        geometry_fill.materials = node_fill.geometry!.materials
        node_fill.geometry = geometry_fill
        
        geometry_outline.materials = node_outline.geometry!.materials
        node_outline.geometry = geometry_outline
        
    }
    
    func start() -> Bool {
        config.sceneReconstruction = .mesh
        ar.run(config, options: [])
                coach.setActive(true, animated: true)
        return true
    }
    func stop() -> Bool {
        config.sceneReconstruction = []
        ar.run(config, options: [])
        coach.setActive(false, animated: true)
        return true
    }

    @objc func save(){
        print("Saving")
        record.circle()
        record.toggle = false
        stop()
        ar.pause()
        let frame = ar.currentFrame!
        guard let device = MTLCreateSystemDefaultDevice() else{
            fatalError("Oh No")
        }
        let allocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(bufferAllocator: allocator)
        var verticesCount = 0
        for anchor in frame.anchors.compactMap({$0 as? ARMeshAnchor}){
            let geometry = anchor.geometry
            let vertices = geometry.vertices
            let verticesPointer = UnsafeMutableRawPointer.allocate(byteCount: vertices.count * vertices.stride, alignment: vertices.stride)
            verticesPointer.copyMemory(from: vertices.buffer.contents(), byteCount: vertices.count * vertices.stride)
            print("Offset:"+String(vertices.offset))
            let faces = geometry.faces
            
            for vertexIndex in 0..<vertices.count{
                let vertex = retrieve_vertex(vertices: vertices, index: vertexIndex)
                var vertexLocalTransform = matrix_identity_float4x4
                vertexLocalTransform.columns.3 = SIMD4<Float>(x: vertex.0, y:vertex.1, z:vertex.2, w:1)
                
                let worldMatrix = (anchor.transform * vertexLocalTransform)
                let worldTransform = SIMD3<Float>(worldMatrix.columns.3.x, worldMatrix.columns.3.y, worldMatrix.columns.3.z)
                verticesCount+=1
                verticesPointer.storeBytes(of: worldTransform.x, toByteOffset: vertices.offset+vertices.stride*vertexIndex, as: Float.self)
                verticesPointer.storeBytes(of: worldTransform.y, toByteOffset: vertices.offset+vertices.stride*vertexIndex+vertices.stride/3, as: Float.self)
                verticesPointer.storeBytes(of: worldTransform.z, toByteOffset: vertices.offset+vertices.stride*vertexIndex+vertices.stride*2/3, as: Float.self)
            }
            
            let byteCountVertices = vertices.count * vertices.stride
            let byteCountFaces = faces.count * faces.indexCountPerPrimitive * faces.bytesPerIndex
            
            let vertexBuffer = allocator.newBuffer(with: Data(bytesNoCopy: verticesPointer, count: byteCountVertices, deallocator: .none), type: .vertex)
            let faceBuffer = allocator.newBuffer(with: Data(bytesNoCopy: faces.buffer.contents(), count: byteCountFaces, deallocator: .none), type: .index)
            
            let material = MDLMaterial(name: "material", scatteringFunction: MDLPhysicallyPlausibleScatteringFunction())
            
            let submesh = MDLSubmesh(indexBuffer: faceBuffer, indexCount: faces.count*faces.indexCountPerPrimitive, indexType: .uint32, geometryType: .triangles, material: material)
            
            let vertexFormat = MTKModelIOVertexFormatFromMetal(vertices.format)
            let vertexDescriptor = MDLVertexDescriptor()
            vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: vertexFormat, offset: 0, bufferIndex: 0)
            vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: vertices.stride)
            
            let mesh = MDLMesh(vertexBuffer: vertexBuffer, vertexCount: vertices.count, descriptor: vertexDescriptor, submeshes: [submesh])
            asset.add(mesh)
            verticesPointer.deallocate()
            
        }
        performSegue(withIdentifier: "saveSegue", sender: (asset, verticesCount, false))
        print("Done")
        
    }
    @IBSegueAction func segueAction(_ coder: NSCoder, sender: Any?) -> ViewerSave? {
        let vs = ViewerSave(coder: coder)
        vs?.asset = (sender as! (MDLAsset, Int, Bool)).0
        vs?.verticesCount = (sender as! (MDLAsset, Int, Bool)).1
        vs?.anchorFound = (sender as! (MDLAsset, Int, Bool)).2
        vs?.isModalInPresentation = true
        vs?.presenter = self
        return vs
    }
    @objc func resetTrack(){

        if ar.currentFrame == nil{
            return
        }
        done.isEnabled = false
        for anchor in ar.currentFrame!.anchors{
            ar.remove(anchor: anchor)
        }
        ar.run(config, options: [.resetSceneReconstruction, .resetTracking])
        if(config.sceneReconstruction == .mesh){
            coach.setActive(true, animated: true)
        }
    }
    
    
    func retrieve_vertex(vertices:ARGeometrySource, index:Int)->(Float, Float, Float){
        let pointer = vertices.buffer.contents().advanced(by: vertices.offset+(vertices.stride*index))
        let vertex = pointer.assumingMemoryBound(to: (Float, Float, Float).self).pointee
        return vertex
    }

}
