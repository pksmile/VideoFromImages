//
//  ImageAnimator.swift
//  VideoFromImages
//
//  Created by PRAKASH on 5/22/19.
//  Copyright © 2019 Prakash. All rights reserved.
//

import UIKit
import AVFoundation

class ImageAnimator{
    
    static let kTimescale: Int32 = 600
    
    let settings: RenderSettings
    let videoWriter: VideoWriter
    var images: [UIImage]!
    
    var frameNum = 0
    
    class func removeFileAtURL(fileURL: NSURL) {
        do {
            try FileManager.default.removeItem(atPath: fileURL.path!)
        }
        catch _ as NSError {
            //
        }
    }
    
    init(renderSettings: RenderSettings,imagearr: [UIImage], audioURL : URL) {
        settings = renderSettings
        videoWriter = VideoWriter(renderSettings: renderSettings, audioUrl: audioURL)
        images = imagearr
    }
    
    func render(completion: @escaping ()->Void) {
        
        // The VideoWriter will fail if a file exists at the URL, so clear it out first.
        ImageAnimator.removeFileAtURL(fileURL: settings.outputURL)
        
        videoWriter.start()
        let s:URL=self.settings.outputURL.absoluteURL!
        videoWriter.render(videoOutputURL: s, appendPixelBuffers: appendPixelBuffers(writer:)) {
            tempurl=s.path
            completion()
        }
//        videoWriter.render(videoOutputURL: s, appendPixelBuffers: appendPixelBuffers, completion: {
//            {
//
//
//
//
//
//        })
//        }
        
    }
    
    
    func appendPixelBuffers(writer: VideoWriter) -> Bool {
        
        let frameDuration = CMTimeMake(value: Int64(ImageAnimator.kTimescale / settings.fps), timescale: ImageAnimator.kTimescale)
        
        while !images.isEmpty {
            
            if writer.isReadyForData == false {
                
                return false
            }
            
            let image = images.removeFirst()
            let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameNum))
            let success = videoWriter.addImage(image: image, withPresentationTime: presentationTime)
            if success == false {
                fatalError("addImage() failed")
            }
            
            frameNum=frameNum+1
        }
        
        
        return true
    }
    
}
