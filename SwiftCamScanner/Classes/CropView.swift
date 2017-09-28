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
    public var rectangleBorderColor = UIColor.blue
    public var rectangleFillColor = UIColor.clear
    public var circleBorderColor = UIColor.white
    public var circleBackgroundColor = UIColor.black
    public var selectedCircleBorderColor = UIColor.blue
    public var selectedCircleBackgroundColor = UIColor.blue
    
    public var rectangleBorderWidth:CGFloat = 2.0
    public var circleBorderWidth:CGFloat = 1.0
    
    public var circleBorderRadius:CGFloat = 10
    public var circleAlpha:CGFloat = 0.65
    public var rectangleAlpha:CGFloat = 1
    
//    public var showOnlyCornerCircles = false
    
    var cropPoints = [CGPoint]()
    var cropCircles = [UIView]()
    var cropFrame: CGRect!
    var cropImageView = UIImageView()
    var selectedCircle : UIView? = nil
    var selectedIndex : Int?
    var m:Double = 0
    var newImageView = UIImageView()
    let border = CAShapeLayer()
    var oldPoint = CGPoint(x: 0, y: 0)
    
    
    public func setUpImage(image : UIImage){
        if(!self.subviews.contains(cropImageView)){
            cropImageView = UIImageView(image: normalizedImage(image: image))
            cropImageView.contentMode = .scaleToFill
            cropImageView.frame = self.bounds
            self.addSubview(cropImageView)
            cropFrame = cropImageView.frame
            setUpCropRegion()
            setUpGestureRecognizer()
            
        }
        
    }
    
    private func setUpCropRegion(){
        addBorderRectangle()
        var i = 1
        let x = cropImageView.frame.origin.x
        let y = cropImageView.frame.origin.y
        let width = cropImageView.frame.width
        let height = cropImageView.frame.height
        
        let points = OpenCVWrapper.getLargestSquarePoints(cropImageView.image, cropImageView.frame.size)
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
            cropCircle.alpha = circleAlpha
            cropCircle.layer.cornerRadius = circleBorderRadius
            cropCircle.frame.size = CGSize(width: circleBorderRadius*2, height: circleBorderRadius*2)
            cropCircle.layer.borderWidth = circleBorderWidth
            cropCircle.layer.borderColor = circleBorderColor.cgColor
            cropCircle.backgroundColor = circleBackgroundColor
            /*
             1----2----3
             |         |
             8         4
             |         |
             7----6----5
             */
            switch i{
            case 1:
                cropCircle.center = endPoints[0]
            case 2:
                cropCircle.center = centerOf(firstPoint: endPoints[0], secondPoint: endPoints[1])
            case 3:
                cropCircle.center = endPoints[1]
            case 4:
                cropCircle.center = centerOf(firstPoint: endPoints[1], secondPoint: endPoints[2])
            case 5:
                cropCircle.center = endPoints[2]
            case 6:
                cropCircle.center = centerOf(firstPoint: endPoints[2], secondPoint: endPoints[3])
            case 7:
                cropCircle.center = endPoints[3]
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
    
    @objc internal func panGesture(gesture : UIPanGestureRecognizer){
        let point = gesture.location(in: self)
        if(gesture.state == UIGestureRecognizerState.began){
            selectedIndex = nil
            //Setup the point
            for i in stride(from: 1, to: 8, by: 2){
                let newFrame = CGRect(x: cropCircles[i].center.x, y: cropCircles[i].center.y, width: cropCircles[i].frame.width, height: cropCircles[i].frame.height)
                if(newFrame.contains(point)){
                    selectedIndex = i
                    let pt1 = cropCircles[selectedIndex! - 1].center
                    let pt2 = cropCircles[(selectedIndex! == 7 ? 0 : selectedIndex! + 1)].center
                    m = ((Double)(pt1.y - pt2.y)/(Double)(pt2.x - pt1.x))
                    cropCircles[selectedIndex!].backgroundColor = selectedCircleBackgroundColor
                    cropCircles[selectedIndex!].layer.borderColor = selectedCircleBorderColor.cgColor

                    break
                }
            }
            if(selectedIndex == nil){
                selectedIndex = getClosestCorner(point: point)
                oldPoint = point
                cropCircles[selectedIndex!].backgroundColor = selectedCircleBackgroundColor
                cropCircles[selectedIndex!].layer.borderColor = selectedCircleBorderColor.cgColor

            }
        }
        if let selectedIndex = selectedIndex {
            if((selectedIndex) % 2 != 0){
                //Do complex stuff
                let pt1 = cropCircles[selectedIndex - 1]
                let pt2 = cropCircles[(selectedIndex == 7 ? 0 : selectedIndex + 1)]
                let pt1New = getNewPoint(pt1: pt1.center,pt2: pt2.center,point: point,m: m)
                let pt2New = getNewPoint(pt1: pt2.center, pt2: pt1.center, point: point,m: m)
                if(isInsideFrame(pt: pt1New) && isInsideFrame(pt: pt2New)){
                    pt1.center = pt1New
                    pt2.center = pt2New
                }
            }else{
                let edge = cropCircles[selectedIndex].center
                let newPoint = CGPoint(x: edge.x + (point.x - oldPoint.x) , y: edge.y + (point.y - oldPoint.y) )
                oldPoint = point
                let boundedX = min(max(newPoint.x, cropImageView.frame.origin.x),(cropImageView.frame.origin.x+cropImageView.frame.size.width))
                let boundedY = min(max(newPoint.y, cropImageView.frame.origin.y),(cropImageView.frame.origin.y+cropImageView.frame.size.height))
                let finalPoint = CGPoint(x: boundedX, y: boundedY)
                cropCircles[selectedIndex].center = finalPoint
            }
            moveNonCornerPoints()
            redrawBorderRectangle()
            
        }
        
        if(gesture.state == UIGestureRecognizerState.ended){
            if let selectedIndex = selectedIndex{
                cropCircles[selectedIndex].backgroundColor = circleBackgroundColor
                cropCircles[selectedIndex].layer.borderColor = circleBorderColor.cgColor
            }
            selectedIndex = nil
            
            //check intersections and stuff
            checkQuadrilateral()
            
        }
    }
    
    private func getClosestCorner(point: CGPoint) -> Int{
        var index = 0
        var minDistance = CGFloat.greatestFiniteMagnitude
        for i in stride(from: 0, to: 7, by: 2){
            let distance = distanceBetweenPoints(point1: point, point2: cropCircles[i].center)
            if(distance < minDistance){
                minDistance = distance
                index = i
            }
        }
        return index;
    }
    
    
    private func checkQuadrilateral(){
        let A = cropCircles[0].center
        let B = cropCircles[2].center
        let C = cropCircles[4].center
        let D = cropCircles[6].center
        
        //Are B and D on either sides of AC
        if(checkIfOppositeSides(p1: B,p2: D,l1: A,l2: C) && checkIfOppositeSides(p1: A,p2: C,l1: B,l2: D)){
            border.strokeColor = rectangleBorderColor.cgColor
        }else if(!checkIfOppositeSides(p1: B,p2: D,l1: A,l2: C) && !checkIfOppositeSides(p1: A,p2: C,l1: B,l2: D)){
            border.strokeColor = rectangleBorderColor.cgColor
            reorderEndPoints()
        } else{
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
            return fmodf((Float)(Double.pi - Double.pi/4 + theta), (Float)(2.0 * Double.pi))
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
        let c1:Double = (Double)(pt1.x) - (Double)(m*(Double)(pt1.y))
        let c2:Double =  (Double)(m*(Double)(point.x) + (Double)(point.y)) * (-1)
        let x = (-1*m*c2 + c1)/(m*m + 1)
        let y =  (-1*m*c1 - c2)/(m*m + 1)
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
        border.lineWidth = rectangleBorderWidth
        border.strokeColor = rectangleBorderColor.withAlphaComponent(rectangleAlpha).cgColor
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
        /*
         0 -- 1
         |    |
         3 -- 2
         */
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
        let widthScale = cropImageView.image!.size.width/cropImageView.frame.size.width
        let heightScale = cropImageView.image!.size.height/cropImageView.frame.size.height
        var corners2 = [CGPoint]()
        for i in stride(from: 0, to:7 , by: 2) {
            let point = CGPoint(x: cropCircles[i].center.x * widthScale, y: cropCircles[i].center.y*heightScale)
            corners2.append(point)
        }
        let newImage = OpenCVWrapper.getTransformedImage(newWidth*widthScale, newHeight*heightScale, cropImageView.image, &corners2, (cropImageView.image!.size))
        
        completionHandler(newImage!)
    }
    
    
    private func distanceBetweenPoints(point1: CGPoint, point2: CGPoint) -> CGFloat{
        let xPow = pow((point1.x - point2.x), 2)
        let yPow = pow((point1.y - point2.y), 2)
        return CGFloat(sqrtf(Float(xPow + yPow)))
        
    }
    
    /**
     Updating the metaData of the image if its orientation is landscape
     */
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
