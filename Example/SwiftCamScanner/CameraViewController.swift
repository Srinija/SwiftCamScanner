//
//  CameraViewController.swift
//  CamScanner
//
//  Created by Srinija on 14/05/17.
//  Copyright © 2017 Srinija Ammapalli. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {

    @IBOutlet weak var cameraView: CameraView!
    @IBOutlet weak var imageThumbnail: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraView.setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = true
    }
    
    @IBAction func captureImage(_ sender: UIButton) {
        cameraView.capturePhoto(){(photo) in
        //set thumbnail image
        DispatchQueue.main.async { () -> Void in
            self.imageThumbnail.setBackgroundImage(photo, for: UIControlState())
            self.imageThumbnail.layer.borderColor = UIColor.white.cgColor
            self.imageThumbnail.layer.borderWidth = 1.0
        }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "showCropView"){
            var vc = segue.destination as! CropViewController
            vc.capturedImage = imageThumbnail.backgroundImage(for: UIControlState())
        }
    }
    
    
    @IBAction func onFlashTap(_ sender: UIButton) {
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        if let device = device {
            if(!device.hasTorch){ return }
            do {
                try device.lockForConfiguration()
        if(sender.currentImage == #imageLiteral(resourceName: "flashAuto")){
            sender.setImage(#imageLiteral(resourceName: "flashOn"), for: .normal)
            device.torchMode = .on
        }else if(sender.currentImage == #imageLiteral(resourceName: "flashOn")){
            sender.setImage(#imageLiteral(resourceName: "flashOff"), for: .normal)
            device.torchMode = .off
        }else if(sender.currentImage == #imageLiteral(resourceName: "flashOff")){
            sender.setImage(#imageLiteral(resourceName: "flashAuto"), for: .normal)
            device.torchMode = .auto
        }
        device.unlockForConfiguration()

            }catch{
                print("Error with flash")
            }
    }
    }

@IBAction func switchCamera(_ sender: UIButton) {
    }

}

