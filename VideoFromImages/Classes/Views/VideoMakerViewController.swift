//
//  VideoMakerViewController.swift
//  VideoFromImages
//
//  Created by PRAKASH on 5/22/19.
//  Copyright © 2019 Prakash. All rights reserved.
//

import AVFoundation
import UIKit
import Photos
import AVKit
import AVFoundation

var tempurl=""

class VideoMakerViewController: UIViewController {
    var audioPlayer: AVAudioPlayer?

    @IBOutlet weak var textView: UITextView!
    var player : AVPlayer!
    var textForTextView =   ""
    var imagesAndVideos:[PHAsset]=[]
    @IBOutlet weak var videoview: UIView!
    func printTimestamp()->String {
        return DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .full)
    }
    
    func updateTextView(text    :   String){
        textForTextView =   textForTextView +   "\n" + text +   self.printTimestamp()
        self.textView.text  =   textForTextView
    }
    
    func createNewArray(assets : [PHAsset])->[PHAsset]{
        return assets
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTextView(text: "Started Updating images")
        firstForLoop()
    }
    
    
    func firstForLoop(){
        let audioFromBundle =   Bundle.main.url(forResource: "music1", withExtension: ".mp3")
        //array of counter means, if image starts from array of point 0 and ends at 3, the video starts from 4 and ends at 6
        var arrayImagesVideos :   [[PHAsset]]   =   []
        
        var count   =   0
        var tempArray   :   [PHAsset]   =   []
        for asset in imagesAndVideos {
            
            if count    ==  0{
                tempArray.append(asset)
                if count    ==  imagesAndVideos.count - 1{
                    arrayImagesVideos.append(tempArray)
                }
            }else{
                tempArray.append(asset)
                if imagesAndVideos[count].mediaType ==  imagesAndVideos[count - 1].mediaType{
                    
                    if count    ==  imagesAndVideos.count - 1{
                        arrayImagesVideos.append(tempArray)
                    }
                }else{
                    arrayImagesVideos.append(tempArray)
                    tempArray.removeAll()
                }
            }
            count   +=  1
        }
        
        print("check for video and image asset:- \(arrayImagesVideos)")
        
        var processedVideoURL   :   [URL]   =   []
        var countAssets = 0
        for assets in arrayImagesVideos {
            
            if assets.first?.mediaType  ==  PHAssetMediaType.video{
                var videoURLs : [URL] = []
                for asset in assets{
                    self.getURL(ofVideoWith: asset) { (url) in
                        videoURLs.append(url!)
                    }
                }
                
                GenerateVideoAudioFromImages.mergeVideosInSignleVideo(videoURLs: videoURLs, andFileName: "test\(countAssets).mp4", success: { (url) in
                    processedVideoURL.append(url)
                    if countAssets  ==  arrayImagesVideos.count - 1{
                        self.mergeAllVideos(videoURLs: processedVideoURL)
                    }
                    countAssets   +=  1
                    
                }) { (error) in
                    countAssets   +=  1
                    print("error block should not called in any case")
                    
                }
            }else{
                var imagesArray : [UIImage] =   []
                for asset in assets{
                    imagesArray.append(self.getUIImage(asset: asset)!)
                }
                
                GenerateVideoAudioFromImages.shared.generateVideoFromImages(_images: imagesArray, andAudios: [audioFromBundle!], andType: GenerateVideoAudioFromImages.GenerateVideoAudioType.singleAudioMultipleImage, { (progress) in
                    print("progress from it:- \(progress)")
                }, success: { (url) in
                    print("video done- \(url)")
                    processedVideoURL.append(url)
                    if countAssets  ==  arrayImagesVideos.count - 1{
                        self.mergeAllVideos(videoURLs: processedVideoURL)
                    }
                    countAssets   +=  1
                }) { (error) in
                    print("error done- \(error)")
                    countAssets   +=  1
                    
                }
                
            }
            
            
        }
    }
    
    
    func mergeAllVideos(videoURLs : [URL]){
        GenerateVideoAudioFromImages.mergeVideosInSignleVideo(videoURLs: videoURLs, andFileName: "FinalVideo.mp4", success: { (url) in
            print("check for success url:- \(url)")
            self.displayVideo(url: url)
        }) { (error) in
            print("error block should not called in any case")
        }
    }


    
    //running this code for video only
    func getURL(ofVideoWith mPhasset: PHAsset, completionHandler : @escaping ((_ responseURL : URL?) -> Void)) {
        let options: PHVideoRequestOptions = PHVideoRequestOptions()
        options.version = .original
        PHImageManager.default().requestAVAsset(forVideo: mPhasset, options: options, resultHandler: { (asset, audioMix, info) in
            if let urlAsset = asset as? AVURLAsset {
                let localVideoUrl = urlAsset.url
                completionHandler(localVideoUrl)
            } else {
                completionHandler(nil)
            }
        })
    }
        
    
    func getUIImage(asset: PHAsset) -> UIImage? {
        var img: UIImage?
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        manager.requestImageData(for: asset, options: options) { data, _, _, _ in
            
            if let data = data {
                img = UIImage(data: data)
            }
        }
        return img
    }
    
    
    private func setupAVPlayer() {
        player.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
        if #available(iOS 10.0, *) {
            player.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        } else {
            player.addObserver(self, forKeyPath: "rate", options: [.old, .new], context: nil)
        }
    }
    
    func displayVideo(url : URL)
    {
        
//        let u:String=tempurl
//        print("check the video url:- \(u)")
        player = AVPlayer(url: url)
//        setupAVPlayer()
        let playerController = AVPlayerViewController()
        playerController.player = player
        self.addChild(playerController)
        videoview.addSubview(playerController.view)
        playerController.view.frame.size=(videoview.frame.size)
        playerController.view.contentMode = .scaleAspectFit
        playerController.view.backgroundColor=UIColor.clear
        videoview.backgroundColor=UIColor.clear
        player.play()
        self.updateTextView(text: "Video display done")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let audioFromBundle =   Bundle.main.url(forResource: "music1", withExtension: ".mp3")
        if object as AnyObject? === player {
            if keyPath == "status" {
//                if player.status == .readyToPlay {
//                    player.play()
//                }
            } else if keyPath == "timeControlStatus" {
                if #available(iOS 10.0, *) {
                    if player.timeControlStatus == .playing {
                        
                        self.playAudio(audioURL: audioFromBundle!)

                    } else {
                        self.stopAudio()
                    }
                }
            } else if keyPath == "rate" {
                if player.rate > 0 {
                    self.playAudio(audioURL: audioFromBundle!)
                } else {
                    self.stopAudio()
                }
            }
        }
    }
    
    func playAudio(audioURL : URL){
//        return
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            
            // For iOS versions < 11
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL, fileTypeHint: AVFileType.mp3.rawValue)
            audioPlayer?.play()
//            guard let aPlayer = audioPlayer else { return }
//            aPlayer.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func stopAudio(){
        guard let aPlayer = audioPlayer else { return }
        aPlayer.stop()
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            let u:String=tempurl
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: u) as URL)
            }) { success, error in
                if !success {
                    print("Could not save video to photo library:", error!)
                }
            }
        }
    }
    
    
}

