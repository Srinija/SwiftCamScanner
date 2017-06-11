//
//  OpenCVWrapper.m
//  CamScanner
//
//  Created by Srinija on 16/05/17.
//  Copyright © 2017 Srinija Ammapalli. All rights reserved.
//
#import "OpenCVWrapper.h"
#undef NO
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import<opencv2/stitching.hpp>
using namespace std;


@implementation OpenCVWrapper



+(NSMutableArray *) getLargestSquarePoints: (UIImage *) image : (CGSize) size{
    
    
    cv::Mat imageMat;
    
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    imageMat = cvMat;

     cv::resize(imageMat, imageMat, cvSize(size.width, size.height));
    
//    UIImageToMat(image, imageMat);
    
    
    std::vector<std::vector<cv::Point> >rectangle;
    std::vector<cv::Point> largestRectangle;
    
    getRectangles(imageMat, rectangle);
    getlargestRectangle(rectangle, largestRectangle);
    
    if (largestRectangle.size() == 4)
    {
        
//        Thanks to: https://stackoverflow.com/questions/20395547/sorting-an-array-of-x-and-y-vertice-points-ios-objective-c/20399468#20399468
        
        NSArray *points = [NSArray array];
        points = @[
                            [NSValue valueWithCGPoint:(CGPoint){(CGFloat)largestRectangle[0].x, (CGFloat)largestRectangle[0].y}],
                            [NSValue valueWithCGPoint:(CGPoint){(CGFloat)largestRectangle[1].x, (CGFloat)largestRectangle[1].y}],
                            [NSValue valueWithCGPoint:(CGPoint){(CGFloat)largestRectangle[2].x, (CGFloat)largestRectangle[2].y}],
                            [NSValue valueWithCGPoint:(CGPoint){(CGFloat)largestRectangle[3].x, (CGFloat)largestRectangle[3].y}]                            ];
        
        CGPoint min = [points[0] CGPointValue];
        CGPoint max = min;
        for (NSValue *value in points) {
            CGPoint point = [value CGPointValue];
            min.x = fminf(point.x, min.x);
            min.y = fminf(point.y, min.y);
            max.x = fmaxf(point.x, max.x);
            max.y = fmaxf(point.y, max.y);
        }
        
        CGPoint center = {
            0.5f * (min.x + max.x),
            0.5f * (min.y + max.y),
        };
        
        NSLog(@"center: %@", NSStringFromCGPoint(center));
        
        NSNumber *(^angleFromPoint)(id) = ^(NSValue *value){
            CGPoint point = [value CGPointValue];
            CGFloat theta = atan2f(point.y - center.y, point.x - center.x);
            CGFloat angle = fmodf(M_PI - M_PI_4 + theta, 2 * M_PI);
            return @(angle);
        };
        
        NSArray *sortedPoints = [points sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            return [angleFromPoint(a) compare:angleFromPoint(b)];
        }];
        
        NSLog(@"sorted points: %@", sortedPoints);
        
        NSMutableArray *squarePoints = [[NSMutableArray alloc] init];
        [squarePoints addObject: [sortedPoints objectAtIndex:0]];
        [squarePoints addObject: [sortedPoints objectAtIndex:1]];
        [squarePoints addObject: [sortedPoints objectAtIndex:2]];
        [squarePoints addObject: [sortedPoints objectAtIndex:3]];
        imageMat.release();

        return squarePoints;

        
    }
    else{
        imageMat.release();
        return nil;
    }
    
}

// http://stackoverflow.com/questions/8667818/opencv-c-obj-c-detecting-a-sheet-of-paper-square-detection
void getRectangles(cv::Mat& image, std::vector<std::vector<cv::Point> >&rectangles) {
    
    // blur will enhance edge detection
    
    cv::Mat blurred(image);
    GaussianBlur(image, blurred, cvSize(11,11), 0);
    
    cv::Mat gray0(blurred.size(), CV_8U), gray;
    std::vector<std::vector<cv::Point> > contours;
    
    // find squares in every color plane of the image
    for (int c = 0; c < 3; c++)
    {
        int ch[] = {c, 0};
        mixChannels(&blurred, 1, &gray0, 1, ch, 1);
        
        // try several threshold levels
        const int threshold_level = 2;
        for (int l = 0; l < threshold_level; l++)
        {
            // Use Canny instead of zero threshold level!
            // Canny helps to catch squares with gradient shading
            if (l == 0)
            {
                Canny(gray0, gray, 10, 20, 3); //
                //                Canny(gray0, gray, 0, 50, 5);
                
                // Dilate helps to remove potential holes between edge segments
                dilate(gray, gray, cv::Mat(), cv::Point(-1,-1));
            }
            else
            {
                gray = gray0 >= (l+1) * 255 / threshold_level;
            }
            
            // Find contours and store them in a list
            findContours(gray, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
            
            // Test contours
            std::vector<cv::Point> approx;
            for (size_t i = 0; i < contours.size(); i++)
            {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                approxPolyDP(cv::Mat(contours[i]), approx, arcLength(cv::Mat(contours[i]), true)*0.02, true);
                
                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                if (approx.size() == 4 &&
                    fabs(contourArea(cv::Mat(approx))) > 1000 &&
                    isContourConvex(cv::Mat(approx)))
                {
                    double maxCosine = 0;
                    
                    for (int j = 2; j < 5; j++)
                    {
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    
                    if (maxCosine < 0.3)
                        rectangles.push_back(approx);
                }
            }
        }
    }
}

void getlargestRectangle(const std::vector<std::vector<cv::Point> >& rectangles, std::vector<cv::Point>& largestRectangle)
{
    if (!rectangles.size())
    {
        return;
    }
    
    double maxArea = 0;
    int index = 0;
    
    for (size_t i = 0; i < rectangles.size(); i++)
    {
        cv::Rect rectangle = boundingRect(cv::Mat(rectangles[i]));
        double area = rectangle.width * rectangle.height;
                
        if (maxArea < area)
        {
            maxArea = area;
            index = i;
        }
    }
    
    largestRectangle = rectangles[index];
}


double angle( cv::Point pt1, cv::Point pt2, cv::Point pt0 ) {
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}


+(UIImage *) getTransformedImage: (CGFloat) newWidth : (CGFloat) newHeight : (UIImage *) origImage : (CGPoint [4]) corners : (CGSize) size {
    
    cv::Mat imageMat;
    
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(origImage.CGImage);
    CGFloat cols = size.width;
    CGFloat rows = size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), origImage.CGImage);
    CGContextRelease(contextRef);
    
    imageMat = cvMat;
    
    cv::Mat newImageMat = cv::Mat( cvSize(newWidth,newHeight), CV_8UC4);
    
    cv::Point2f src[4], dst[4];
    src[0].x = corners[0].x;
    src[0].y = corners[0].y;
    src[1].x = corners[1].x;
    src[1].y = corners[1].y;
    src[2].x = corners[2].x;
    src[2].y = corners[2].y;
    src[3].x = corners[3].x;
    src[3].y = corners[3].y;
    
    dst[0].x = 0;
    dst[0].y = 0;
    dst[1].x = newWidth - 1;
    dst[1].y = 0;
    dst[2].x = newWidth - 1;
    dst[2].y = newHeight - 1;
    dst[3].x = 0;
    dst[3].y = newHeight - 1;
 
    
    
    cv::warpPerspective(imageMat, newImageMat, cv::getPerspectiveTransform(src, dst), cvSize(newWidth, newHeight));
    
    //Transform to UIImage
    
    NSData *data = [NSData dataWithBytes:newImageMat.data length:newImageMat.elemSize() * newImageMat.total()];
    
    CGColorSpaceRef colorSpace2;
    
    if (newImageMat.elemSize() == 1) {
        colorSpace2 = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace2 = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGFloat width = newImageMat.cols;
    CGFloat height = newImageMat.rows;
    
    CGImageRef imageRef = CGImageCreate(width,                                     // Width
                                        height,                                     // Height
                                        8,                                              // Bits per component
                                        8 * newImageMat.elemSize(),                           // Bits per pixel
                                        newImageMat.step[0],                                  // Bytes per row
                                        colorSpace2,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace2);
    
    return image;
}


@end
