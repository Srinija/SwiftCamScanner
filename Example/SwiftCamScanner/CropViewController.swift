//
//  CropViewController.swift
//  CamScanner
//
//  Created by Srinija on 16/05/17.
//  Copyright © 2017 Srinija Ammapalli. All rights reserved.
//

import UIKit

class CropViewController: UIViewController {
    @IBOutlet weak var cropView: CropView!
    
    var capturedImage:UIImage?
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
        if let capturedImage = capturedImage{
        cropView.setUpImage(image: capturedImage)
        }
    }

    @IBAction func onDoneTap(_ sender: UIBarButtonItem) {
       cropView.cropAndTransform(completionHandler: {(croppedImage) -> Void in
            let imageVC = self.storyboard?.instantiateViewController(withIdentifier: "imageViewController") as! ImageViewController
            imageVC.image = croppedImage
            self.navigationController?.pushViewController(imageVC, animated: true)
        })


    }
    
}
