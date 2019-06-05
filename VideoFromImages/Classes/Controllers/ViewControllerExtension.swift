//
//  ViewControllerExtension.swift
//  VideoFromImages
//
//  Created by PRAKASH on 5/24/19.
//  Copyright © 2019 Prakash. All rights reserved.
//

import UIKit

extension UIViewController{
    func showAlert(title : String, message : String){
        let alertC  =   UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction    =   UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertC.addAction(okAction)
        self.present(alertC, animated: true, completion: nil)
    }
    
    
}
