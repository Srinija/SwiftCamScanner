//
//  CropView.swift
//  CamScanner
//
//  Created by Srinija on 16/05/17.
//  Copyright © 2017 Srinija Ammapalli. All rights reserved.
//
import UIKit

public class CropView: UIView {
    
    //Editable Variables
    public var borderColor: CGColor = UIColor.blue.cgColor
    
    
    
    
    var cropPoints = [CGPoint]()
    var cropCircles = [UIView]()
    var cropFrame: CGRect!
    var cropImageView = UIImageView()
    var selectedCircle : UIView? = nil
    var selectedIndex : Int?
    var m:Double = 0
    var newImageView = UIImageView()
    let border = CAShapeLayer()
    
    
    public func setUpImage(image : UIImage){
        if(!self.subviews.contains(cropImageView)){
            cropImageView = UIImageView(image: normalizedImage(image: image))
            cropImageView.contentMode = .scaleToFill
            cropImageView.frame = self.bounds
            self.addSubview(cropImageView)
            cropFrame = cropImageView.frame
            setUpCropRegion()
            setUpGestureRecognizer()
            print("Dimensions: \(self.frame.width), \(self.frame.height)")
            
        }
        
    }
    
    
    
    private func setUpCropRegion(){
        addBorderRectangle()
        var i = 1
        let x = cropImageView.frame.origin.x
        let y = cropImageView.frame.origin.y
        let width = cropImageView.frame.width
        let height = cropImageView.frame.height
        
        var points = OpenCVWrapper.getLargestSquarePoints(cropImageView.image, cropImageView.frame.size)
        print(points)
        var endPoints = [CGPoint]()
        if let points = points{
            for i in (0...3) {
                let newPoint = points[i] as! CGPoint
                endPoints.append(CGPoint(x: newPoint.x + x, y: newPoint.y+y))
            }
        }else{
            endPoints.append(CGPoint(x: x, y: y))
            endPoints.append(CGPoint(x: x+width, y: y))
            endPoints.append(CGPoint(x: x+width, y: y+height))
            endPoints.append(CGPoint(x: x, y: y+height))
        }
        
        
        while(i<=8){
            let cropCircle = UIView()
            cropCircle.alpha = 0.65
            cropCircle.layer.cornerRadius = 10
            cropCircle.frame.size = CGSize(width: 20, height: 20)
            cropCircle.layer.borderWidth = 1
            cropCircle.layer.borderColor = UIColor.white.cgColor
            cropCircle.backgroundColor = UIColor.black
            /*
             1----2----3
             |             |
             8            4
             |             |
             7----6----5
             */
            switch i{
            case 1:
                cropCircle.center = endPoints[0]
                cropCircle.backgroundColor = UIColor.black
            case 2:
                cropCircle.center = centerOf(firstPoint: endPoints[0], secondPoint: endPoints[1])
            case 3:
                cropCircle.center = endPoints[1]
                cropCircle.backgroundColor = UIColor.black
            case 4:
                cropCircle.center = centerOf(firstPoint: endPoints[1], secondPoint: endPoints[2])
            case 5:
                cropCircle.center = endPoints[2]
                cropCircle.backgroundColor = UIColor.black
            case 6:
                cropCircle.center = centerOf(firstPoint: endPoints[2], secondPoint: endPoints[3])
            case 7:
                cropCircle.center = endPoints[3]
                cropCircle.backgroundColor = UIColor.black
            case 8:
                cropCircle.center = centerOf(firstPoint: endPoints[3], secondPoint: endPoints[0])
            default:
                break
            }
            cropCircles.append(cropCircle)
            self.addSubview(cropCircle)
            i = i+1
        }
        
        redrawBorderRectangle()
    }
    
    
    private func centerOf(firstPoint: CGPoint, secondPoint: CGPoint) -> CGPoint{
        return CGPoint(x: (firstPoint.x+secondPoint.x)/2, y: (firstPoint.y + secondPoint.y)/2)
    }
    
    
    private func setUpGestureRecognizer(){
        let gestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(CropView.panGesture))
        self.addGestureRecognizer(gestureRecognizer)
    }
    
    internal func panGesture(gesture : UIPanGestureRecognizer){
        let point = gesture.location(in: self)
        if(gesture.state == UIGestureRecognizerState.began){
            selectedIndex = nil
            //Setup the point
            for i in (0...7) {
                let newFrame = CGRect(x: cropCircles[i].frame.origin.x, y: cropCircles[i].frame.origin.y, width: cropCircles[i].frame.width + 60, height: cropCircles[i].frame.height + 60)
                if(newFrame.contains(point)){
                    selectedIndex = i
                    cropCircles[selectedIndex!].backgroundColor = UIColor.blue
                    if((selectedIndex)! % 2 != 0){
                        var pt1 = cropCircles[selectedIndex! - 1].center
                        var pt2 = cropCircles[(selectedIndex! == 7 ? 0 : selectedIndex! + 1)].center
                        m = ((Double)(pt1.y - pt2.y)/(Double)(pt2.x - pt1.x))
                    }
                    
                    
                    break
                }
            }
            
        }
        if let selectedIndex = selectedIndex {
            
            
            if((selectedIndex) % 2 != 0){
                //Do complex stuff
                print("New point: x: \(point.x), y: \(point.y)")
                var pt1 = cropCircles[selectedIndex - 1]
                var pt2 = cropCircles[(selectedIndex == 7 ? 0 : selectedIndex + 1)]
                let pt1New = getNewPoint(pt1: pt1.center,pt2: pt2.center,point: point,m: m)
                let pt2New = getNewPoint(pt1: pt2.center, pt2: pt1.center, point: point,m: m)
                if(isInsideFrame(pt: pt1New) && isInsideFrame(pt: pt2New)){
                    pt1.center = pt1New
                    pt2.center = pt2New
                }
            }else{
                let boundedX = min(max(point.x, cropImageView.frame.origin.x),(cropImageView.frame.origin.x+cropImageView.frame.size.width))
                let boundedY = min(max(point.y, cropImageView.frame.origin.y),(cropImageView.frame.origin.y+cropImageView.frame.size.height))
                let newPoint = CGPoint(x: boundedX, y: boundedY)
                cropCircles[selectedIndex].center = newPoint
            }
            moveNonCornerPoints()
            redrawBorderRectangle()
            
        }
        
        if(gesture.state == UIGestureRecognizerState.ended){
            if let selectedIndex = selectedIndex{
                cropCircles[selectedIndex].backgroundColor = UIColor.black
            }
            selectedIndex = nil
            
            //check intersections and stuff
            checkQuadrilateral()
            
        }
    }
    
    
    private func checkQuadrilateral(){
        let A = cropCircles[0].center
        let B = cropCircles[2].center
        let C = cropCircles[4].center
        let D = cropCircles[6].center
        
        //Are B and D on either sides of AC
        if(checkIfOppositeSides(p1: B,p2: D,l1: A,l2: C) && checkIfOppositeSides(p1: A,p2: C,l1: B,l2: D)){
            border.strokeColor = borderColor
            print("CONVEX QUAD")
        }else if(!checkIfOppositeSides(p1: B,p2: D,l1: A,l2: C) && !checkIfOppositeSides(p1: A,p2: C,l1: B,l2: D)){
            print("Intersection HAPPENED")
            border.strokeColor = borderColor
            reorderEndPoints()
        } else{
            print("CONCAVE")
            border.strokeColor = UIColor.red.cgColor
        }
    }
    
    private func reorderEndPoints(){
        let endPoints = [cropCircles[0].center, cropCircles[2].center, cropCircles[4].center, cropCircles[6].center]
        var low = cropCircles[0].center
        var high = low;
        for point in endPoints{
            low.x = min(point.x, low.x);
            low.y = min(point.y, low.y);
            high.x = max(point.x, high.x);
            high.y = max(point.y, high.y);
        }
        
        let center = CGPoint(x: (low.x + high.x)/2,y: (low.y + high.y)/2)
        
        func angleFromPoint(point: CGPoint) -> Float{
            let theta = (Double)(atan2f((Float)(point.y - center.y), (Float)(point.x - center.x)))
            return fmodf((Float)(M_PI - M_PI_4 + theta), (Float)(2.0 * M_PI))
        }
        
        var sortedArray = endPoints.sorted(by: {  (p1, p2)  in
            return angleFromPoint(point: p1) < angleFromPoint(point: p2)
        })
        
        cropCircles[0].center = sortedArray[0]
        cropCircles[2].center = sortedArray[1]
        cropCircles[4].center = sortedArray[2]
        cropCircles[6].center = sortedArray[3]
        moveNonCornerPoints()
        redrawBorderRectangle()
        
        
    }
    
    
    //https://math.stackexchange.com/questions/162728/how-to-determine-if-2-points-are-on-opposite-sides-of-a-line
    private func checkIfOppositeSides(p1:CGPoint, p2: CGPoint, l1: CGPoint, l2:CGPoint) -> Bool{
        let part1 = (l1.y-l2.y)*(p1.x-l1.x) + (l2.x-l1.x)*(p1.y-l1.y)
        let part2 = (l1.y-l2.y)*(p2.x-l1.x) + (l2.x-l1.x)*(p2.y-l1.y)
        if((part1*part2) < 0){
            return true
        }else{
            return false
        }
    }
    
    
    private func isInsideFrame(pt: CGPoint) -> Bool{
        if(pt.x < cropImageView.frame.origin.x || pt.x > (cropImageView.frame.origin.x+cropImageView.frame.size.width)){
            return false
        }
        if(pt.y < cropImageView.frame.origin.y || pt.y > (cropImageView.frame.origin.y+cropImageView.frame.size.height)){
            return false
        }
        return true
        
    }
    
    private func getNewPoint(pt1: CGPoint, pt2:CGPoint, point: CGPoint, m:Double) -> CGPoint{
        if(abs(pt2.x - pt1.x) < 0.1){
            return CGPoint(x: pt1.x, y: point.y)
        }
        //        let m:Double = abs((Double)(pt2.y - pt1.y)/(Double)(pt2.x - pt1.x))
        print(m)
        let c1:Double = (Double)(pt1.x) - (Double)(m*(Double)(pt1.y))
        print(c1)
        let c2:Double =  (Double)(m*(Double)(point.x) + (Double)(point.y)) * (-1)
        print(c2)
        let denom = (m*m + 1)
        print(denom)
        let x = (-1*m*c2 + c1)/(m*m + 1)
        print(x)
        let y =  (-1*m*c1 - c2)/(m*m + 1)
        print(y)
        return CGPoint(x: x, y: y)
    }
    
    private func moveNonCornerPoints(){
        for i in stride(from: 1, to: 8, by: 2){
            let prev = i-1
            let next = (i == 7 ? 0 : i+1)
            cropCircles[i].center = CGPoint(x: (cropCircles[prev].center.x + cropCircles[next].center.x)/2, y: (cropCircles[prev].center.y + cropCircles[next].center.y)/2)
        }
    }
    
    private func addBorderRectangle(){
        border.fillColor = UIColor.clear.cgColor
        border.lineWidth = 2.0
        border.strokeColor = borderColor
        self.layer.addSublayer(border)
    }
    
    private func redrawBorderRectangle(){
        
        let beizierPath = UIBezierPath()
        beizierPath.move(to: cropCircles[0].center)
        beizierPath.addLine(to: cropCircles[2].center)
        beizierPath.addLine(to: cropCircles[4].center)
        beizierPath.addLine(to: cropCircles[6].center)
        beizierPath.addLine(to: cropCircles[0].center)
        
        border.path = beizierPath.cgPath
    }
    
    public func cropAndTransform(completionHandler :@escaping(_ image : UIImage) -> Void){
        //        let scale = cropImageView.image?.scale
        //        var corners = [CGPoint]()
        //        /*
        //         0 -- 1
        //         |      |
        //         3 -- 2
        //        */
        //
        //        for i in stride(from: 0, to:7 , by: 2) {
        //        corners.append(CGPoint(x: (cropCircles[i].frame.origin.x)/scale!, y: (cropCircles[i].frame.origin.y)/scale!))
        //        }
        
        reorderEndPoints()
        
        var corners = [CGPoint]()
        for i in stride(from: 0, to:7 , by: 2) {
            corners.append(cropCircles[i].center)
        }
        
        let topWidth = distanceBetweenPoints(point1: corners[0], point2: corners[1])
        let bottomWidth = distanceBetweenPoints(point1: corners[3], point2: corners[2])
        let leftHeight = distanceBetweenPoints(point1: corners[0], point2: corners[3])
        let rightHeight = distanceBetweenPoints(point1: corners[1], point2: corners[2])
        let newWidth = max(topWidth, bottomWidth)
        let newHeight = max(leftHeight, rightHeight)
        
        print("\(newWidth),\(newHeight)")
        var corners2 = [CGPoint]()
        for i in stride(from: 0, to:7 , by: 2) {
            corners2.append(cropCircles[i].center)
        }
        let newImage = OpenCVWrapper.getTransformedImage(newWidth, newHeight, cropImageView.image, &corners, (cropImageView.frame.size))
        //        cropImageView.isHidden = true
        //        newImageView = UIImageView(image: newImage)
        //        newImageView.isHidden = false
        //        newImageView.contentMode = .scaleAspectFit
        //        newImageView.frame = CGRect(origin:  cropImageView.frame.origin, size: CGSize(width: newWidth, height: newHeight))
        //        self.addSubview(newImageView)
        completionHandler(newImage!)
    }
    
    
    private func distanceBetweenPoints(point1: CGPoint, point2: CGPoint) -> CGFloat{
        let xPow = pow((point1.x - point2.x), 2)
        let yPow = pow((point1.y - point2.y), 2)
        return CGFloat(sqrtf(Float(xPow + yPow)))
        
    }
    
    private func normalizedImage(image: UIImage) -> UIImage {
        
        if (image.imageOrientation == UIImageOrientation.up) {
            return image;
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale);
        let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        image.draw(in: rect)
        
        let normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext();
        return normalizedImage;
    }
    
    
    
    
}
