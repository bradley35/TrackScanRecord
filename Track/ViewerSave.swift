//
//  ViewerSave.swift
//  Track
//
//  Created by Bradley on 6/30/20.
//  Copyright © 2020 Bradley. All rights reserved.
//

import Foundation
import UIKit
import Metal
import MetalKit
import SceneKit
import ARKit
import SceneKit.ModelIO

class ViewerSave:UIViewController{
    
    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var anchorLabel: UILabel!
    @IBOutlet weak var verticesLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    @IBOutlet weak var `switch`: UISwitch!
    
    @IBOutlet weak var nameScanLabel: UILabel!
    @IBOutlet weak var ucvatLabel: UILabel!
    @IBOutlet weak var rescanButton: UIBarButtonItem!
    
    var asset:MDLAsset!
    var presenter:ViewController?
    var verticesCount:Int!
    var anchorFound:Bool!
    var worldMap:ARWorldMap?
    let numberFormatter = NumberFormatter()
    
    var snapshot:UIImage!
    var viewing = false
    var project:Project?
    var doubleSided = true
    var rescanFunc: ((_ p:Project)->())?
    var editingMode:Bool = false
    
    override func viewDidLoad() {
        sceneView.scene = SCNScene(mdlAsset: asset)
        sceneView.autoenablesDefaultLighting = true
        for node in sceneView.scene!.rootNode.childNodes{
            for material in node.geometry!.materials{
                 material.diffuse.contents = UIColor(displayP3Red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
                 material.lightingModel = .lambert
                 material.isDoubleSided = true
            }
        }
        let light_node = SCNNode()
        let light = SCNLight()
        light.intensity = 300
        light.type = .ambient
        light_node.light = light
        light_node.name = "light"
        sceneView.scene!.rootNode.addChildNode(light_node)
        saveButton.layer.cornerRadius = 7
        numberFormatter.numberStyle = .decimal
        
        verticesLabel.text = verticesLabel.text!.replacingOccurrences(of: "NA", with: numberFormatter.string(from: NSNumber(value:verticesCount))!)
        anchorLabel.text = anchorLabel.text!.replacingOccurrences(of: "NA", with: (anchorFound ? "Yes":"No"))
        let tripleTap = UITapGestureRecognizer(target: self, action: #selector(toggleDoubleSided))
        tripleTap.numberOfTouchesRequired = 3
        sceneView.addGestureRecognizer(tripleTap)
        snapshot = sceneView.snapshot()
        rescanButton.isEnabled = false
        rescanButton.tintColor = UIColor.clear
        if(viewing){
            saveButton.setTitle("Export", for: .normal)
            saveButton.backgroundColor = UIColor(displayP3Red: 1, green: 0, blue: 0, alpha: 1)
            cancelBarButton.title = "Done"
            textField.text = project!.name
            textField.isEnabled = false
            `switch`.isHidden = true
            nameScanLabel.text = "Name of scan:"
            ucvatLabel.isHidden = true
            rescanButton.isEnabled = true
            rescanButton.tintColor = UIColor.systemBlue
            rescanButton.target = self
            rescanButton.action = #selector(rescan)
        }
        if(editingMode){
            saveButton.setTitle("Replace Model", for: .normal)
            textField.text = project!.name
            textField.isEnabled = false
            nameScanLabel.text = "Name of scan:"
        }
        
        
    }
    @objc func toggleDoubleSided(){
        doubleSided.toggle()
        for node in sceneView.scene!.rootNode.childNodes{
            if node.name == "light"{
                continue
            }
            for material in node.geometry!.materials{
                material.isDoubleSided = doubleSided
            }
            
        }
    }
    @objc func rescan(){
        self.dismiss(animated: true) {
            self.rescanFunc!(self.project!)
        }
        
    }
    func export(){
        let items = [sharedFileHolder.modelURL(uuid: project!.id)]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityVC.popoverPresentationController!.sourceView = saveButton
        present(activityVC, animated: true, completion: nil)
    }
    @IBAction func save(_ sender: Any) {
        if(viewing){
            export()
            return
        }
        if(`switch`.isOn){
            snapshot = sceneView.snapshot()
        }
            
        let text = textField.text == nil ? "" : textField.text!
        if(editingMode){
            sharedFileHolder.updateModel(model: asset, uuid: project!.id, preview: snapshot, hasAnchor: anchorFound, map: worldMap, vertices: verticesCount, updatedProject: project!)
            self.dismiss(animated: true, completion: {
                self.presenter!.navigationController!.popViewController(animated: true)
            })
            return
        }
        sharedFileHolder.saveNewModel(model: asset, name: text, preview: snapshot, hasAnchor: anchorFound, map:worldMap, vertices: verticesCount)
        self.dismiss(animated: true, completion: {
            self.presenter!.navigationController!.popViewController(animated: true)
        })
        
    }
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        presenter?.resetTrack()
        self.dismiss(animated: true, completion: nil)
    }
    
}
