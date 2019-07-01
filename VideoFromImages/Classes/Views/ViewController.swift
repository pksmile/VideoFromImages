//
//  ViewController.swift
//  VideoFromImages
//
//  Created by PRAKASH on 5/22/19.
//  Copyright © 2019 Prakash. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var imagesAndVideosToPass  :   [PHAsset]   =   []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view. 
        self.collectionView.register(UINib(nibName: "ImageToPassCell", bundle: nil), forCellWithReuseIdentifier: "CollecionCell")
    }
    
    @IBAction func actionAddImages(_ sender: Any) {
        let imagePicker = OpalImagePickerController()
        presentOpalImagePickerController(imagePicker, animated: true,
                                         select: { (assets) in
                                            print("done clicked")
                                            self.dismiss(animated: true, completion: nil)
//                                            var images :    [UIImage] =   []
//                                            for asset in assets{
//                                                images.append(self.getUIImage(asset: asset) ?? UIImage())
//                                            }
                                            
                                     self.openNextView(imagesAndVideos: assets)
                                            //Select Assets
                                            
                                            
        }, cancel: {
            //Cancel
            print("cancel clicked")
        })
    }
    
    @IBAction func actionCreateVideo(_ sender: Any) {
        if self.imagesAndVideosToPass.count  >   0{
            self.performSegue(withIdentifier: "segueCreateVideo", sender: self)
        }else{
            self.showAlert(title: "Can not create video!", message: "please select at least one image from Top Right + button.")
        }
        
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
    
    func openNextView(imagesAndVideos    :   [PHAsset]){
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.imagesAndVideosToPass   =   imagesAndVideos
            self.collectionView.reloadData()
//
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier ==  "segueCreateVideo"{
            let destination =   segue.destination   as! VideoMakerViewController
            destination.imagesAndVideos  =   self.imagesAndVideosToPass
        }
    }
    
}



extension ViewController    :   UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesAndVideosToPass.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell    =   collectionView.dequeueReusableCell(withReuseIdentifier: "CollecionCell", for: indexPath) as! ImageToPassCell
        let image   :   PHAsset   =   self.imagesAndVideosToPass[indexPath.item]
        cell.imageView.image    =   self.getUIImage(asset: image)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize    =   UIScreen.main.bounds.size.width/2   -   50
        return CGSize(width: cellSize, height: cellSize)
    }
    
}

