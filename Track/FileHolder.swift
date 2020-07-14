//
//  FileHolder.swift
//  Track
//
//  Created by Bradley on 7/2/20.
//  Copyright © 2020 Bradley. All rights reserved.
//

import Foundation
import ModelIO
import UIKit
import ARKit
import Zip
let sharedFileHolder = FileHolder()
class FileHolder{
    let fileManager = FileManager.default
    var storageDirectory: URL
    let encoder = PropertyListEncoder()
    func listProjects() -> [Project]{
        
        let contents = try! fileManager.contentsOfDirectory(atPath: storageDirectory.path)
        var list = [Project]()
        for content in contents{
            guard let project = try? PropertyListDecoder().decode(Project.self, from: Data(contentsOf: storageDirectory.appendingPathComponent(content).appendingPathComponent("data.dat"))) else{
                var project = Project(blankWithID: content)
                project.name = "This project is curropted"
                project.hasModel = true
                project.videos = [1,2,3]
                project.modelThumb = storageDirectory.appendingPathComponent(project.id).appendingPathComponent("thumbnail.jpg")
                project.safe = false
                project.modelHasAnchor = false
                list.append(project)
                continue
            }
            if(!project.saved){
                print("Removing")
                try? fileManager.removeItem(at: storageDirectory.appendingPathComponent(content))
            }else{
                list.append(project)
            }
            
        }
        
        return list
    }
    
    init() {
        storageDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Saves/")
        if !fileManager.fileExists(atPath: storageDirectory.path){
            do {
                try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch {
                fatalError("Could not create file")
            }
        }
        
    }
    
    func saveNewModel(model:MDLAsset, name:String, preview:UIImage, hasAnchor:Bool, map:ARWorldMap?, vertices:Int){
        var nameEdited = name
        if name == ""{
            nameEdited = "Untitled Project"
        }
        let uuid = UUID().uuidString
        do {
            try fileManager.createDirectory(at: storageDirectory.appendingPathComponent(uuid), withIntermediateDirectories: false, attributes: nil)
            try model.export(to: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("model.obj"))
            try preview.jpegData(compressionQuality: 1)?.write(to: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("thumbnail.jpg"))
            if(map != nil){
                try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true).write(to: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("world.map"))
            }

            let project = Project(withModelName: nameEdited, id: uuid, thumb: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("thumbnail.jpg"), hasAnchor: hasAnchor, vertices: vertices)
            try encoder.encode(project).write(to: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("data.dat"))
            print(project)
        } catch {
            print("Error")
        }
    }
    
    func updateModel(model:MDLAsset, uuid:String, preview:UIImage, hasAnchor:Bool, map:ARWorldMap?, vertices:Int, updatedProject:Project){
         try? fileManager.removeItem(at: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("model.obj"))
        try? fileManager.removeItem(at: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("model.mtl"))
        try? fileManager.removeItem(at: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("thumbnail.jpg"))
        try? fileManager.removeItem(at: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("world.map"))
        
        
        try! model.export(to: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("model.obj"))
        try! preview.jpegData(compressionQuality: 1)?.write(to: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("thumbnail.jpg"))
        if(map != nil){
            try! NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true).write(to: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("world.map"))
        }
        var newProject = updatedProject
        newProject.hasModel = true
        newProject.modelHasAnchor = hasAnchor
        newProject.vertices = vertices
        newProject.modelThumb = storageDirectory.appendingPathComponent(uuid).appendingPathComponent("thumbnail.jpg")
        updateProject(uuid: uuid, newProject: newProject)
    }
    func startNewVideo() -> Project{
        let uuid = UUID().uuidString
        try! fileManager.createDirectory(at: storageDirectory.appendingPathComponent(uuid), withIntermediateDirectories: false, attributes: nil)
        let project = Project(blankWithID: uuid)
        try! encoder.encode(project).write(to: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("data.dat"))
        return project
    }
    func loadModel(uuid:String) -> (MDLAsset, ARWorldMap?){
        let model = MDLAsset(url: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("model.obj"))
        let map = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: Data(contentsOf: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("world.map")))!
        
        return (model, map)
        
    }
    func loadModel(project:Project) -> (MDLAsset, ARWorldMap?){
        return loadModel(uuid: project.id)
    }
    
    func getVideoSaveURL(index:Int, uuid:String) -> URL{
        return storageDirectory.appendingPathComponent(uuid).appendingPathComponent("video"+String(index)+".mp4")
    }
    func replaceVideoSaveURL(index:Int, uuid:String) -> URL{
        try? fileManager.removeItem(at: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("video"+String(index)+".mp4"))
        return storageDirectory.appendingPathComponent(uuid).appendingPathComponent("video"+String(index)+".mp4")
    }
    func replaceVideoThumbSaveURL(index:Int, uuid:String) -> URL{
           try? fileManager.removeItem(at: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("video"+String(index)+".jpg"))
           return storageDirectory.appendingPathComponent(uuid).appendingPathComponent("video"+String(index)+".jpg")
       }
    func getVideoThumbSaveURL(index:Int, uuid:String) -> URL{
        return storageDirectory.appendingPathComponent(uuid).appendingPathComponent("video"+String(index)+".jpg")
    }
    func getVideoTrackingSaveURL(index:Int, uuid:String) -> URL{
          return storageDirectory.appendingPathComponent(uuid).appendingPathComponent("video"+String(index)+"track.json")
      }
    func updateProject(uuid:String, newProject:Project){
        try! encoder.encode(newProject).write(to: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("data.dat"), options: [])
    }
    func deleteProject(uuid:String){
        try? fileManager.removeItem(at: storageDirectory.appendingPathComponent(uuid))
    }
    
    func modelURL(uuid:String)-> URL{
        return storageDirectory.appendingPathComponent(uuid).appendingPathComponent("model.obj")
    }
    func deleteVideo(index:Int, uuid:String){
        try? fileManager.removeItem(at: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("video"+String(index)+"track.json"))
        try? fileManager.removeItem(at: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("video"+String(index)+".jpg"))
        try? fileManager.removeItem(at: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("video"+String(index)+".mp4"))
        
        try? fileManager.removeItem(at: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("video"+String(index)+"track_blender.py"))
    }
  func getVideoTrackingPythonURL(index:Int, uuid:String) -> URL{
        return storageDirectory.appendingPathComponent(uuid).appendingPathComponent("video"+String(index)+"track_blender.py")
    }
    
    func newZip(uuid:String) -> URL{
        try? fileManager.removeItem(at: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("export.zip"))
        let contents = try! fileManager.contentsOfDirectory(at: storageDirectory.appendingPathComponent(uuid), includingPropertiesForKeys: nil, options: [])
        try? Zip.zipFiles(paths: contents, zipFilePath: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("export.zip"), password: nil, progress: {prog in
        
        print(prog)
        })
        return storageDirectory.appendingPathComponent(uuid).appendingPathComponent("export.zip")
    }
    func newCustomZip(uuid:String, index:Int, includeObject:Bool = false, includeTracking:Bool = false) -> URL{
        try? fileManager.removeItem(at: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("export.zip"))
        var contents = [storageDirectory.appendingPathComponent(uuid).appendingPathComponent("video"+String(index)+".mp4")]
        if(includeObject){
            contents.append(storageDirectory.appendingPathComponent(uuid).appendingPathComponent("model.obj"))
        }
        if(includeTracking){
            contents.append(storageDirectory.appendingPathComponent(uuid).appendingPathComponent("video"+String(index)+"track_blender.py"))
            contents.append(storageDirectory.appendingPathComponent(uuid).appendingPathComponent("video"+String(index)+"track.json"))
        }
        try? Zip.zipFiles(paths: contents, zipFilePath: storageDirectory.appendingPathComponent(uuid).appendingPathComponent("export.zip"), password: nil, progress: {prog in
        
        print(prog)
        })
        return storageDirectory.appendingPathComponent(uuid).appendingPathComponent("export.zip")
    }
}
struct Project:Codable{
    var name:String
    var id:String
    var vertices:Int = 0
    var saved = true
    private var _modelThumbRelative:String? = nil
    var modelThumb:URL? {
        get{
            if(_modelThumbRelative != nil){
                return sharedFileHolder.storageDirectory.appendingPathComponent(_modelThumbRelative!)
            }else{
                return nil
            }
            
        }
        set(url){
            _modelThumbRelative = String(url!.path.dropFirst(sharedFileHolder.storageDirectory.path.count+1))
        }
    }
    var hasModel:Bool
    var modelHasAnchor:Bool? = nil
    var videos:[Int]
    var safe = true
    
    init(withModelName:String, id:String, thumb:URL, hasAnchor:Bool, vertices:Int) {
        self.name = withModelName
        self.id = id
        self._modelThumbRelative = ""
        self.modelHasAnchor = hasAnchor
        self.hasModel = true
        self.videos = []
        self.modelThumb = thumb
        self.vertices = vertices

    }
    init (blankWithID:String){
        self.id = blankWithID
        self.name = "Untitled Project"
        self.videos = []
        self.hasModel = false
        self.saved = false
    }
    
    

}
