//
//  TrackedData.swift
//  Track
//
//  Created by Bradley on 7/11/20.
//  Copyright © 2020 Bradley. All rights reserved.
//

import Foundation
import AVFoundation
struct TrackingData: Codable{
    var points:[TrackingPoint] = [TrackingPoint]()
    
    func saveToFile(url:URL) throws{
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        try data.write(to: url)
    }
    func saveToFile(project:Project, index:Int) throws{
        try saveToFile(url: sharedFileHolder.getVideoTrackingSaveURL(index: index, uuid: project.id))
    }
    static func loadFromFile(url:URL) throws -> TrackingData{
        let decoder = JSONDecoder()
        return try decoder.decode(TrackingData.self, from: Data(contentsOf: url))
    }
    static func loadFromFile(project:Project, index:Int) throws -> TrackingData{
        return try loadFromFile(url: sharedFileHolder.getVideoTrackingSaveURL(index: index, uuid: project.id))
    }
    
}

struct TrackingPoint:Codable{
    var timeStamp:CMTimeValue
    var timeScale:CMTimeScale
    
    var position:simd_float4x4
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        var positionContainer = container.nestedContainer(keyedBy: PositionKeys.self, forKey: .position)
        try positionContainer.encode(position.columns.0, forKey: .col0)
        try positionContainer.encode(position.columns.1, forKey: .col1)
        try positionContainer.encode(position.columns.2, forKey: .col2)
        try positionContainer.encode(position.columns.3, forKey: .col3)
        
        try container.encode(timeStamp, forKey: .timeStamp)
        try container.encode(timeScale, forKey: .timeScale)
    }
    init(from decoder: Decoder) throws {
        var container = try decoder.container(keyedBy: Keys.self)
        var positionContainer = try container.nestedContainer(keyedBy: PositionKeys.self, forKey: .position)
        let col0 = try positionContainer.decode(simd_float4.self, forKey: .col0)
        let col1 = try positionContainer.decode(simd_float4.self, forKey: .col1)
        let col2 = try positionContainer.decode(simd_float4.self, forKey: .col2)
        let col3 = try positionContainer.decode(simd_float4.self, forKey: .col3)
        
        position = simd_float4x4(col0, col1, col2, col3)
        
        timeStamp = try container.decode(CMTimeValue.self, forKey: .timeStamp)
        timeScale = try container.decode(CMTimeScale.self, forKey: .timeScale)
    }
    private enum Keys:String, CodingKey{
        case position
        case timeStamp
        case timeScale
    }
    private enum PositionKeys:String, CodingKey{
        case col0
        case col1
        case col2
        case col3
    }
    init(timeStamp:CMTimeValue, timeScale:CMTimeScale, position:simd_float4x4){
        self.timeStamp = timeStamp
        self.position = position
        self.timeScale = timeScale
    }
}
