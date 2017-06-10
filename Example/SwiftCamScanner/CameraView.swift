//
//  CameraView.swift
//  CamScanner
//
//  Created by Srinija on 15/05/17.
//  Copyright © 2017 Srinija Ammapalli. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CameraView: UIView {

    let captureSession = AVCaptureSession()
    let imageOutput = AVCaptureStillImageOutput()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var activeInput: AVCaptureDeviceInput!
    var focusMarker: UIImageView!
    
    
    func setupCamera(){
        
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        let camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                activeInput = input
            }
        } catch {
            print("Error setting device input: \(error)")
        }
        
        imageOutput.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
        if captureSession.canAddOutput(imageOutput) {
            captureSession.addOutput(imageOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = self.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.layer.addSublayer(previewLayer)
        
        let tapForFocus = UITapGestureRecognizer(target: self, action: #selector(tapToFocus(_:)))
        tapForFocus.numberOfTapsRequired = 1

        
        self.addGestureRecognizer(tapForFocus)
        
        focusMarker = UIImageView(image: #imageLiteral(resourceName: "focus"))
        focusMarker.frame.size = CGSize(width: 100, height: 100)
        focusMarker.isHidden = true

        self.addSubview(focusMarker)
        
        
        if !captureSession.isRunning {
            videoQueue().async {
                self.captureSession.startRunning()
            }
        }
    }

    func videoQueue() -> DispatchQueue {
        return DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)
    }
    
    // MARK: Focus Methods
    func tapToFocus(_ recognizer: UIGestureRecognizer) {
        if activeInput.device.isFocusPointOfInterestSupported {
            let point = recognizer.location(in: self)
            let pointOfInterest = previewLayer.captureDevicePointOfInterest(for: point)
            showMarkerAtPoint(point, marker: focusMarker)
            focusAtPoint(pointOfInterest)
        }
    }
    
    func focusAtPoint(_ point: CGPoint) {
        let device = activeInput.device
        if (device?.isFocusPointOfInterestSupported)! &&
            (device?.isFocusModeSupported(AVCaptureFocusMode.autoFocus))! {
            do {
                try device?.lockForConfiguration()
                device?.focusPointOfInterest = point
                device?.focusMode = AVCaptureFocusMode.autoFocus
                device?.unlockForConfiguration()
            } catch {
                print("Error focusing on POI: \(error)")
            }
        }
    }

    func showMarkerAtPoint(_ point: CGPoint, marker: UIImageView) {
        marker.center = point
        marker.isHidden = false
        
        UIView.animate(withDuration: 0.15,
                       delay: 0.0,
                       options: UIViewAnimationOptions(),
                       animations: { () -> Void in
                        marker.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0)
        }) { (Bool) -> Void in
            let delay = 0.5
            let popTime = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: popTime, execute: { () -> Void in
                marker.isHidden = true
                marker.transform = CGAffineTransform.identity
            })
        }
    }
    
    func capturePhoto(completionHandler:@escaping(_ image: UIImage?)->Void){
        let connection = imageOutput.connection(withMediaType: AVMediaTypeVideo)
        if (connection?.isVideoOrientationSupported)! {
            connection?.videoOrientation = getOrientation()
        }
        
        imageOutput.captureStillImageAsynchronously(from: connection) {
            (sampleBuffer: CMSampleBuffer?, error: Error?) -> Void in
            if sampleBuffer != nil {
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                let image = UIImage(data: imageData!)
                completionHandler(image)
            } else {
                print("Error capturing photo: \(error?.localizedDescription)")
            }
        }
    }
    
    func getOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = .portrait
        case .landscapeRight:
            orientation = .landscapeLeft
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        default:
            orientation = .landscapeRight
        }
        
        return orientation
    }
}
