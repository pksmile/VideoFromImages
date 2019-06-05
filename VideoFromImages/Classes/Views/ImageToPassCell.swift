//
//  ImageToPassCell.swift
//  VideoFromImages
//
//  Created by PRAKASH on 5/24/19.
//  Copyright © 2019 Prakash. All rights reserved.
//

import UIKit

class ImageToPassCell: UICollectionViewCell {
    @IBOutlet weak var viewImage: UIView!
    
    @IBOutlet weak var imageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.viewImage.layer.cornerRadius   =   5
        self.viewImage.layer.borderWidth    =   1
        self.viewImage.layer.borderColor    =   UIColor.red.cgColor
    }

}
