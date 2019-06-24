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
    var images:[UIImage]=[]
    @IBOutlet weak var videoview: UIView!
    func printTimestamp()->String {
        return DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .full)
    }
    
    func updateTextView(text    :   String){
        textForTextView =   textForTextView +   "\n" + text +   self.printTimestamp()
        self.textView.text  =   textForTextView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTextView(text: "Started Updating images")
        DispatchQueue.main.async {
            let settings = RenderSettings()
            self.updateTextView(text: "Started Image Animator")
            //replace this audio from bundle to code where you can pass the exact selected audio url
            let audioFromBundle =   Bundle.main.url(forResource: "music1", withExtension: ".mp3")
            print("check for audio from url:- \(audioFromBundle)")
            let imageAnimator = ImageAnimator(renderSettings: settings,imagearr: self.images, audioURL: audioFromBundle!)
            self.updateTextView(text: "Image Animator finishe, video create started")
            imageAnimator.render() {
                self.updateTextView(text: "Video created")
                self.displayVideo()
            }
        }
    }
    private func setupAVPlayer() {
        player.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
        if #available(iOS 10.0, *) {
            player.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        } else {
            player.addObserver(self, forKeyPath: "rate", options: [.old, .new], context: nil)
        }
    }
    
    func displayVideo()
    {
        
        let u:String=tempurl
        player = AVPlayer(url: URL(fileURLWithPath: u))
        setupAVPlayer()
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
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            
            // For iOS versions < 11
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let aPlayer = audioPlayer else { return }
            aPlayer.play()
            
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
