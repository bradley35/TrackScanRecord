//
//  VideoRecordViewController.swift
//  Track
//
//  Created by Bradley on 7/6/20.
//  Copyright © 2020 Bradley. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import ARKit
import SceneKit
import CoreServices
import TrackingToBlender

class VideoRecordViewController:UIViewController, RecordButtonDelegate, ARSessionDelegate, ARSCNViewDelegate, AVCaptureAudioDataOutputSampleBufferDelegate{
    
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var cameraPositionView: SCNView!
    
    @IBOutlet weak var removeAnchorButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var anchorLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    var session:ARSession!
    var images:Set<ARReferenceImage>?
    var config:ARWorldTrackingConfiguration!
    
    var recordButton:RecordButton!
    
    var detected = false
    var recording = false
    
    var tracking = TrackingData()
    var positions = [simd_float4x4]()
    
    
    var writer:AVAssetWriter!
    var writerInput:AVAssetWriterInput!
    let timebase = try! CMTimebase(masterClock: CMClockGetHostTimeClock())
    let formatter = DateFormatter()
    var project:Project?
    var index = 0
    
    var firstFrame:CVImageBuffer?
    var parentCell:MainCell!
    
    var soundOn:Bool = true
    var audioDevice = AVCaptureDevice.default(for: .audio)!
    var audioSession:AVCaptureSession!
    var audioOutput:AVCaptureAudioDataOutput!
    var writerAudio:AVAssetWriterInput!
    var audioBaseTime:CMTime?
    var vstart = false
    var new = false
    var offset:CMTime!
    var origin = simd_float4x4(1)
    var bronze = Bronze()
    
    var lastVideoTimeStamp:CMTime!
    override func viewDidLoad() {
        self.hidesBottomBarWhenPushed = true
        session = ARSession()
        session.delegate = self
        sceneView.session = session
        sceneView.delegate = self
        sceneView.contentMode = .scaleAspectFit
        //sceneView.layer.borderWidth = 5
        //sceneView.layer.borderColor = UIColor.red.cgColor
        config = ARWorldTrackingConfiguration()
        config.isAutoFocusEnabled = true
        
        recordButton = RecordButton(frame: CGRect(x: sceneView.frame.width-120, y: sceneView.frame.height/2-50, width: 100, height: 100))
        recordButton.delegate = self
        sceneView.addSubview(recordButton)
        
        
        cameraPositionView.scene = SCNScene(named: "SceneAssets.scnassets/CameraScene.scn")!
        //let map =
        //config.initialWorldMap = map
        config.sceneReconstruction = .mesh
        config.videoFormat = ARWorldTrackingConfiguration.supportedVideoFormats.first(where: { (format) -> Bool in
            return format.imageResolution==CGSize(width: 1920, height: 1080)
        })!
        
        images = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main)
        config.detectionImages = images
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
        if(project != nil){
            let saved_data = sharedFileHolder.loadModel(project: project!)
            
            for object in saved_data.0.childObjects(of: MDLObject.self){
                let node = SCNNode(mdlObject: object)
                node.geometry!.firstMaterial!.diffuse.contents = UIColor(displayP3Red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
                node.geometry!.firstMaterial!.lightingModel = .lambert
                node.geometry!.firstMaterial!.isDoubleSided = false
                node.isHidden = true
                node.name = "Mesh"

                cameraPositionView.scene!.rootNode.addChildNode(node)
            }
        }else{
            project = sharedFileHolder.startNewVideo()
            new = true
        }
        
        
        removeAnchorButton.addTarget(self, action: #selector(removeAnchor(sender:)), for: .touchUpInside)
        
        writer = try! AVAssetWriter(outputURL: sharedFileHolder.replaceVideoSaveURL(index: 0, uuid: project!.id), fileType: .mp4)
        writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: [AVVideoCodecKey:AVVideoCodecType.hevc, AVVideoHeightKey: 1080, AVVideoWidthKey:1920, AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey:NSNumber(50000000), AVVideoExpectedSourceFrameRateKey:60]])//
        //writerInput.mediaTimeScale = 1000000000
        //writer.movieTimeScale = 1000000000
        writerInput.expectsMediaDataInRealTime = true
        writer.add(writerInput)
        
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        audioSession = AVCaptureSession()
        guard let aud = try? AVCaptureDeviceInput(device: audioDevice) else{
          print("cannot create audio")
            soundOn = false
            return
        }
        if (!audioSession.canAddInput(aud)){
            print("Cannot add audio")
            soundOn = false
            return
        }
        if(soundOn){
            audioSession.addInput(aud)
            audioOutput = AVCaptureAudioDataOutput()
            
            audioSession.addOutput(audioOutput)
            
            let queue = DispatchQueue(label: "AudioOutput")
            audioOutput.setSampleBufferDelegate(self, queue: queue)
            
            writerAudio = AVAssetWriterInput(mediaType: .audio, outputSettings: [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44100, AVNumberOfChannelsKey: 2])
            writerAudio.expectsMediaDataInRealTime = true
            writer.add(writerAudio)
        }
        
        
    

    }
    
    func start() -> Bool {
        if(statusLabel.text == "Ready"){
            DispatchQueue.global(qos: .background).async {
                self.writer.startWriting()
                try! self.timebase.setRate(1)
                //self.writer.startSession(atSourceTime: self.timebase.time)
                self.recording = true
                if(self.soundOn){
                    self.audioSession.startRunning()
                }
            }

            return true
        }else{
            return false
        }
        
    }
    
    func stop() -> Bool {
        if(firstFrame == nil){
            return false
        }
        self.audioSession.stopRunning()
        self.recording = false
        self.session.pause()
        //writer.endSession(atSourceTime: timebase.time)
        try! self.timebase.setRate(0)
        writer.endSession(atSourceTime: lastVideoTimeStamp)
        writer.finishWriting {
            
            self.audioSession.stopRunning()
            if(self.index == 0){
                self.index = 1
            }
            
            try! sharedFileHolder.fileManager.moveItem(at:  sharedFileHolder.getVideoSaveURL(index: 0, uuid: self.project!.id), to:  sharedFileHolder.replaceVideoSaveURL(index: self.index, uuid: self.project!.id))
            self.project!.videos.append(self.index)
            let img = CIImage(cvImageBuffer: self.firstFrame!)
            let context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
            let imgTransformed = context.createCGImage(img, from: CGRect(x:0, y:0, width: CVPixelBufferGetWidth(self.firstFrame!), height: CVPixelBufferGetHeight(self.firstFrame!)))
            let destination = CGImageDestinationCreateWithURL(sharedFileHolder.replaceVideoThumbSaveURL(index: self.index, uuid: self.project!.id) as CFURL, kUTTypeJPEG, 1, nil)
            CGImageDestinationAddImage(destination!, imgTransformed!, nil)
            CGImageDestinationFinalize(destination!)
            self.project!.saved = true
            sharedFileHolder.updateProject(uuid: self.project!.id, newProject: self.project!)
            
            let gpumat_array = self.bronze.newGPUMatArrayFromSIMD(input: self.positions)
            var inverse = self.origin.inverse
            
            let multiplier_gpumat = self.bronze.newGPUMatFromSIMD(input: &inverse)
            self.bronze.multMatrixMultiInPlaceSquare(A: gpumat_array, B: multiplier_gpumat, right: true)
            self.positions = gpumat_array.toSIMD()
            for i in 0..<self.positions.count{
                self.tracking.points[i].position = self.positions[i]
            }
            try! self.tracking.saveToFile(project: self.project!, index: self.index)
            self.saveTrackingToPython()
            if(self.new){
                DispatchQueue.main.async {
                    let namePopup = UIAlertController(title: "Name", message: "Please name this project", preferredStyle: .alert)
                    namePopup.addTextField { (textField) in
                        textField.placeholder = "Untitled"
                        textField.autocapitalizationType = .words
                    }
                    namePopup.addAction(UIAlertAction(title: "Done", style: .default, handler: { (action) in
                        let text = namePopup.textFields!.first!.text!
                        if(text != ""){
                            self.project!.name = text
                        }else{
                            self.project!.name = "Untitled Project"
                        }
                        
                        
                        sharedFileHolder.updateProject(uuid: self.project!.id, newProject: self.project!)
                        
                        self.navigationController!.popViewController(animated: true)
                    }))
                    self.present(namePopup, animated: true, completion: nil)
                }

             }else{
                DispatchQueue.main.sync {
                    self.navigationController!.popViewController(animated: true)
                    self.parentCell.parent.collectionView.reloadItems(at: [self.parentCell.parent!.collectionView.indexPath(for: self.parentCell)!])
                }
                
            }
            
            
        }
        recording = false

        
        return true
    }
    
    func saveTrackingToPython(){
        let t2b = try! TrackingToBlender(frameRate: 60, jsonURL: sharedFileHolder.getVideoTrackingSaveURL(index: self.index, uuid: self.project!.id))
        t2b.processFrames()
        try! t2b.generateString().write(to: sharedFileHolder.getVideoTrackingPythonURL(index: self.index, uuid: self.project!.id), atomically: false, encoding: .ascii)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState{
        case .limited(let reason):
            statusLabel.text = "Initializing"
            statusLabel.textColor = UIColor.red
            print(reason)
        case.normal:
            statusLabel.text = "Ready"
            statusLabel.textColor = UIColor.green
        case.notAvailable:
            statusLabel.text = "Error"
            statusLabel.textColor = UIColor.red
        }
    }
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        cameraPositionView.scene!.rootNode.childNode(withName: "cameraBox", recursively: false)!.simdTransform = frame.camera.transform
        if(recording && !soundOn && audioBaseTime == nil){
            audioBaseTime = CMTime(seconds: 0, preferredTimescale: timebase.time.timescale)
            try! timebase.setTime(audioBaseTime!)
            offset = CMTime(seconds: 0, preferredTimescale: audioBaseTime!.timescale)
            writer.startSession(atSourceTime: audioBaseTime!+offset)
        }
        if(recording && audioBaseTime != nil){
            vstart = true
            if(firstFrame == nil){
                firstFrame = frame.capturedImage
            }
            var timing = CMSampleTimingInfo(duration: CMTime.invalid, presentationTimeStamp: timebase.time, decodeTimeStamp: CMTime.invalid)
            let t1 = tracking.points.last?.position ?? frame.camera.transform
            
            tracking.points.append(TrackingPoint(timeStamp: (timebase.time-audioBaseTime!-offset).value, timeScale: timing.presentationTimeStamp.timescale, position: simd_float4x4(0)))
            positions.append(frame.camera.transform)
            //tracking.points.append(TrackingPoint(timeStamp: (timebase.time-audioBaseTime!-offset).value, timeScale: timing.presentationTimeStamp.timescale, position: frame.camera.transform))
            
            let t2 = frame.camera.transform
            
            let pos1 = t1.columns.3
            let pos2 = t2.columns.3
            
            let line = SCNGeometry.lineFrom(vector: SCNVector3(pos1.x, pos1.y, pos1.z), toVector: SCNVector3(pos2.x, pos2.y, pos2.z))
            line.firstMaterial!.diffuse.contents = UIColor.green
            let node = SCNNode(geometry: line)
            cameraPositionView.scene?.rootNode.addChildNode(node)
            
            var desc:CMFormatDescription? = nil
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: frame.capturedImage, formatDescriptionOut: &desc)
            var buffer:CMSampleBuffer? = nil
            CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: frame.capturedImage, formatDescription: desc!, sampleTiming: &timing, sampleBufferOut: &buffer)
            
            writerInput.append(buffer!)
            lastVideoTimeStamp = timing.presentationTimeStamp
        }
        
        durationLabel.text = formatter.string(from: Date(timeIntervalSinceReferenceDate: (timebase.time-(audioBaseTime ?? CMTime.zero)).seconds))
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if(recording && audioBaseTime == nil){
            audioBaseTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            offset = CMTime(seconds: 1/60, preferredTimescale: audioBaseTime!.timescale)
            try! timebase.setTime(audioBaseTime!)
            writer.startSession(atSourceTime: audioBaseTime!+offset)
            
        }

        if(writerAudio.isReadyForMoreMediaData && vstart){
            writerAudio.append(sampleBuffer)
        }
        
        
    }
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnch = (anchor as? ARImageAnchor)else{
            return
        }
        
        let plane = SCNPlane(width: imageAnch.referenceImage.physicalSize.width,
                             height: imageAnch.referenceImage.physicalSize.height)
        let planeNode = SCNNode(geometry: plane)
        planeNode.opacity = 0.8
        planeNode.geometry?.materials.first?.diffuse.contents = UIColor.yellow
        let changeColor = SCNAction.customAction(duration: 4) { (node, time) in
            let percentage = pow((time/4),1)
            DispatchQueue.main.async {
                self.anchorLabel.text = "Processing: "+String(Int(percentage*100))
            }
            
            let color = UIColor(displayP3Red: 1-percentage, green: 1, blue: 0, alpha: 1)
            node.geometry?.materials.first?.diffuse.contents = color
            if(percentage >= 1){
                DispatchQueue.main.async {
                    self.detected = true
                    self.anchorLabel.textColor = UIColor.green
                    self.anchorLabel.text = "Found"
                    self.removeAnchorButton.isHidden = false
                    for node in self.cameraPositionView.scene!.rootNode.childNodes{
                        if node.name == "Mesh"{
                            node.isHidden = false
                        }
                    }
                        self.config.detectionImages = []
                        self.session.run(self.config, options: [])
                        //planeNode.isHidden = true
                }
            }
        }
        planeNode.runAction(changeColor)
        DispatchQueue.main.async {
            self.anchorLabel.textColor = UIColor.yellow
            self.anchorLabel.text = "Processing"
        }
        
        
        planeNode.eulerAngles.x = -.pi / 2
        node.addChildNode(planeNode)
        //anchorAnchor = imageAnch
    }
    override func viewWillDisappear(_ animated: Bool) {
        session.pause()
    }
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let imageAnch = (anchor as? ARImageAnchor)else{
            return nil
        }
        origin = imageAnch.transform
        //session.setWorldOrigin(relativeTransform: imageAnch.transform)
        return SCNNode()
    }
    
    @objc func removeAnchor(sender:UIButton!){
        self.anchorLabel.text = "Not Found"
        self.anchorLabel.textColor = UIColor.black
        self.removeAnchorButton.isHidden = true
        for node in self.cameraPositionView.scene!.rootNode.childNodes{
            if node.name == "Mesh"{
                node.isHidden = true
            }
        }
        
        self.config.detectionImages = images
        self.session.run(self.config, options: [.removeExistingAnchors])
        detected = false
        
    }
    
    
}

extension SCNGeometry {//https://stackoverflow.com/questions/21886224/drawing-a-line-between-two-points-using-scenekit
    class func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]

        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)

        return SCNGeometry(sources: [source], elements: [element])

    }
}
