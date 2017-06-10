//
//  ImageViewController.swift
//  CamScanner
//
//  Created by Srinija on 04/06/17.
//  Copyright © 2017 Srinija Ammapalli. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var image: UIImage?

    override func viewWillAppear(_ animated: Bool) {
        if let image = image{
            imageView.image = image
            imageView.sizeToFit()
        }
    }

}
