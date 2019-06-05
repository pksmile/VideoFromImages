//
//  RenderSettings.swift
//  VideoFromImages
//
//  Created by PRAKASH on 5/22/19.
//  Copyright © 2019 Prakash. All rights reserved.
//

import UIKit
import AVFoundation

struct RenderSettings {
    
    var width: CGFloat = 1500
    var height: CGFloat = 844
    var fps: Int32 = 2   // 2 frames per second
    var avCodecKey = AVVideoCodecType.h264
    var videoFilename = "renderExportVideo"
    var videoFilenameExt = "mp4"
    
    var size: CGSize {
        return CGSize(width: width, height: height)
    }
    
    var outputURL: NSURL {
        
        let fileManager = FileManager.default
        if let tmpDirURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            return tmpDirURL.appendingPathComponent(videoFilename).appendingPathExtension(videoFilenameExt) as NSURL
        }
        fatalError("URLForDirectory() failed")
    }
}
