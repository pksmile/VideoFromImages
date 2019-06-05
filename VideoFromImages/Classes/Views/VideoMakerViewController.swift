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
    @IBOutlet weak var textView: UITextView!
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
    
    func displayVideo()
    {
        
        let u:String=tempurl
        let player = AVPlayer(url: URL(fileURLWithPath: u))
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
