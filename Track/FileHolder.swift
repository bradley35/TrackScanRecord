//
//  FileHolder.swift
//  Track
//
//  Created by Bradley on 7/2/20.
//  Copyright © 2020 Bradley. All rights reserved.
//

import Foundation

class FileHolder{
    func listProject() -> [Project]{
        return []
    }
}
struct Project{
    var name:String
    var id:String
    var thumb:URL
    var contents:ProjectType
}
enum ProjectType:Int{
    case scanOnly = 0
    case recordingOnly = 1
    case both = 2
}
