//
//  VideoWriter.swift
//  VideoFromImages
//
//  Created by PRAKASH on 5/22/19.
//  Copyright © 2019 Prakash. All rights reserved.
//

import UIKit
import AVFoundation

class VideoWriter {
    
    /// private property to store the audio URLs
    fileprivate var audioURLs: [URL] = []
//    fileprivate var audioURL: URL  =   URL(string: "test")!
    /// public property to set the name of the finished video file
    open var fileName = "movie"
    /// private property to store the different audio durations
    fileprivate var audioDurations: [Double] = []
    /// public property to set the maximum length of a video
    open var maxVideoLengthInSeconds: Double?
    
    let renderSettings: RenderSettings
    
    var videoWriter: AVAssetWriter!
    var videoWriterInput: AVAssetWriterInput!
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    
    var isReadyForData: Bool {
        return videoWriterInput?.isReadyForMoreMediaData ?? false
    }
    
    class func pixelBufferFromImage(image: UIImage, pixelBufferPool: CVPixelBufferPool, size: CGSize) -> CVPixelBuffer {
        
        var pixelBufferOut: CVPixelBuffer?
        
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
        if status != kCVReturnSuccess {
            fatalError("CVPixelBufferPoolCreatePixelBuffer() failed")
        }
        
        let pixelBuffer = pixelBufferOut!
        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        
        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: Int(size.width), height: Int(size.height),
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        context!.clear(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let horizontalRatio = size.width / image.size.width
        let verticalRatio = size.height / image.size.height
        
        let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
        
        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)
        
        let x = newSize.width < size.width ? (size.width - newSize.width) / 2 : 0
        let y = newSize.height < size.height ? (size.height - newSize.height) / 2 : 0
        
        context!.concatenate(CGAffineTransform.identity)
        context!.draw(image.cgImage!, in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        
        return pixelBuffer
    }
    
    init(renderSettings: RenderSettings, audioUrl : URL) {
        self.renderSettings = renderSettings
//        self.audioURL   =   audioUrl
        self.audioURLs  =   [audioUrl]
    }
    
    func start() {
        
        let avOutputSettings: [String: AnyObject] = [
            AVVideoCodecKey: renderSettings.avCodecKey as AnyObject,
            AVVideoWidthKey: NSNumber(value: Float(renderSettings.width)),
            AVVideoHeightKey: NSNumber(value: Float(renderSettings.height))
        ]
        
        func createPixelBufferAdaptor() {
            let sourcePixelBufferAttributesDictionary = [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: NSNumber(value: Float(renderSettings.width)),
                kCVPixelBufferHeightKey as String: NSNumber(value: Float(renderSettings.height))
            ]
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput,
                                                                      sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        }
        
        func createAssetWriter(outputURL: NSURL) -> AVAssetWriter {
            guard let assetWriter = try? AVAssetWriter(outputURL: outputURL as URL, fileType: AVFileType.mp4) else {
                fatalError("AVAssetWriter() failed")
            }
            
            guard assetWriter.canApply(outputSettings: avOutputSettings, forMediaType: AVMediaType.video) else {
                fatalError("canApplyOutputSettings() failed")
            }
            
            return assetWriter
        }
        
        videoWriter = createAssetWriter(outputURL: renderSettings.outputURL)
        videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: avOutputSettings)
        
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }
        else {
            fatalError("canAddInput() returned false")
        }
        
        
        createPixelBufferAdaptor()
        
        if videoWriter.startWriting() == false {
            fatalError("startWriting() failed")
        }
        
        videoWriter.startSession(atSourceTime: CMTime.zero)
        
        precondition(pixelBufferAdaptor.pixelBufferPool != nil, "nil pixelBufferPool")
    }
    
    func render(videoOutputURL : URL,appendPixelBuffers: @escaping (VideoWriter)->Bool, completion: @escaping ()->Void) {
        
        precondition(videoWriter != nil, "Call start() to initialze the writer")
        
        let queue = DispatchQueue(label: "mediaInputQueue")
        videoWriterInput.requestMediaDataWhenReady(on: queue) {
            let isFinished = appendPixelBuffers(self)
            if isFinished {
                self.videoWriterInput.markAsFinished()
                self.videoWriter.finishWriting() {
                    /// if the writing is successfull, go on to merge the video with the audio files
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                        // your code here
                        self.mergeAudio(withVideoURL: videoOutputURL, success: { (videoURL) in
                            print("finished")
                            DispatchQueue.main.async {
                                completion()
                            }
                        }, failure: { (error) in
                            print("error while saving audio:- \(error)")
                            //                        failure(error)
                        })
                    }

                    
                    
                }
            }
            else {
                
            }
        }
    }
    
    func addImage(image: UIImage, withPresentationTime presentationTime: CMTime) -> Bool {
        
        precondition(pixelBufferAdaptor != nil, "Call start() to initialze the writer")
        
        let pixelBuffer = VideoWriter.pixelBufferFromImage(image: image, pixelBufferPool: pixelBufferAdaptor.pixelBufferPool!, size: renderSettings.size)
        return pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
 
    
    
    // MARK: --------------------------------------------------------------- Private methods ---------------------------------------------------------------
    
    /// Private method to generate a movie with the selected frame and the given audio
    ///
    /// - parameter audioUrl: the audio url
    /// - parameter videoUrl: the video url
    private func mergeAudio(withVideoURL videoUrl: URL, success: @escaping ((URL) -> Void), failure: @escaping ((Error) -> Void)) {
        let dispatchQueueMerge = DispatchQueue(label: "merge audio", qos: .background)
        dispatchQueueMerge.async { [weak self] in
            /// create a mutable composition
            let mixComposition = AVMutableComposition()
            
            /// create a video asset from the url and get the video time range
            let videoAsset = AVURLAsset(url: videoUrl, options: nil)
            let videoTimeRange = CMTimeRange(start: CMTime.zero, duration: videoAsset.duration)
            
            /// add a video track to the composition
            let videoComposition = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            if let videoTrack = videoAsset.tracks(withMediaType: .video).first {
                do {
                    /// try to insert the video time range into the composition
                    try videoComposition?.insertTimeRange(videoTimeRange, of: videoTrack, at: CMTime.zero)
                } catch {
                    failure(error)
                }
                
                var duration = CMTime(seconds: 0, preferredTimescale: 1)
                
                /// add an audio track to the composition
                let audioCompositon = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                
                /// for all audio files add the audio track and duration to the existing audio composition
                for (index, audioUrl) in self?.audioURLs.enumerated() ?? [].enumerated() {
                    let audioDuration = CMTime(seconds: self?.audioDurations[index] ?? 0.0, preferredTimescale: 1)
                    
                    let audioAsset = AVURLAsset(url: audioUrl)
                    let audioTimeRange = CMTimeRange(start: CMTime.zero, duration: self?.maxVideoLengthInSeconds != nil ? audioDuration : audioAsset.duration)
                    
                    let shouldAddAudioTrack = self?.maxVideoLengthInSeconds != nil ? audioDuration.seconds > 0 : true
                    
                    if shouldAddAudioTrack {
                        if let audioTrack = audioAsset.tracks(withMediaType: .audio).first {
                            do {
                                try audioCompositon?.insertTimeRange(audioTimeRange, of: audioTrack, at: duration)
                            } catch {
                                failure(error)
                            }
                        }
                    }
                    
                    duration = duration + (self?.maxVideoLengthInSeconds != nil ? audioDuration : audioAsset.duration)
                }
                
                /// check if the documents folder is available
                if let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                    self?.getTempVideoFileUrl { (_) in }
                    
                    /// create a path to the video file
                    let videoOutputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("\(self?.fileName ?? "").m4v")
                    self?.deleteFile(pathURL: videoOutputURL) {
                        if let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) {
                            exportSession.outputURL = videoOutputURL
                            exportSession.outputFileType = AVFileType.mp4
                            exportSession.shouldOptimizeForNetworkUse = true
                            
                            /// try to export the file and handle the status cases
                            exportSession.exportAsynchronously(completionHandler: {
                                if exportSession.status == .failed || exportSession.status == .cancelled {
                                    if let _error = exportSession.error {
                                        DispatchQueue.main.async {
                                            failure(_error)
                                        }
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        success(videoOutputURL)
                                    }
                                }
                            })
                        } else {
                            DispatchQueue.main.async {
                                failure(VideoGeneratorError(error: .kFailedToStartAssetExportSession))
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        failure(VideoGeneratorError(error: .kFailedToFetchDirectory))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    failure(VideoGeneratorError(error: .kFailedToReadVideoTrack))
                }
            }
        }
    }
    /// Private method to delete the temp video file
    ///
    /// - Returns: the temp file url
    private func getTempVideoFileUrl(completion: @escaping (URL) -> ()) {
        DispatchQueue.main.async {
            if let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                let testOutputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("test.m4v")
                do {
                    if FileManager.default.fileExists(atPath: testOutputURL.path) {
                        try FileManager.default.removeItem(at: testOutputURL)
                    }
                } catch {
                    print(error.localizedDescription)
                }
                
                completion(testOutputURL)
            }
        }
    }
    
    /// Private method to delete a file
    ///
    /// - Parameters:
    ///   - pathURL: the file's path
    ///   - completion: a blick to handle completion
    private func deleteFile(pathURL: URL, completion: @escaping () throws -> ()) {
        DispatchQueue.main.async {
            do {
                if FileManager.default.fileExists(atPath: pathURL.path) {
                    try FileManager.default.removeItem(at: pathURL)
                }
            } catch {
                print(error.localizedDescription)
            }
            
            do {
                try completion()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
