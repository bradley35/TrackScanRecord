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
import SceneKit.ModelIO

class ViewerSave:UIViewController{
    
    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var anchorLabel: UILabel!
    @IBOutlet weak var verticesLabel: UILabel!
    var asset:MDLAsset!
    var presenter:ViewController!
    var verticesCount:Int!
    var anchorFound:Bool!
    let numberFormatter = NumberFormatter()
    
    var doubleSided = true
    override func viewDidLoad() {
        sceneView.scene = SCNScene(mdlAsset: asset)
        sceneView.autoenablesDefaultLighting = true
        for node in sceneView.scene!.rootNode.childNodes{
            node.geometry!.firstMaterial!.diffuse.contents = UIColor(displayP3Red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
            node.geometry!.firstMaterial!.lightingModel = .lambert
            node.geometry!.firstMaterial!.isDoubleSided = true
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
    }
    @objc func toggleDoubleSided(){
        doubleSided.toggle()
        for node in sceneView.scene!.rootNode.childNodes{
            if node.name == "light"{
                continue
            }
            node.geometry!.firstMaterial!.isDoubleSided = doubleSided
        }
    }
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        presenter.resetTrack()
        self.dismiss(animated: true, completion: nil)
    }
    
}
