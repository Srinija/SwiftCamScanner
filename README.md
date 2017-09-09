# SwiftCamScanner

## Overview
[Demo GIF](../master/demo.gif)

## Requirements
Minimum iOS Version: 8.0

## Installation

### CocoaPods
SwiftCamScanner is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:
```
pod 'SwiftCamScanner'
```

### Manual
For manual installation, drag and drop the files in SwiftCamScanner/Classes into your project.

## Usage
Storyboard: To setup the cropping area, add a UIView to your storyboard and assign constraints. Set its class to 'CropView' and module to 'SwiftCamScanner'

ViewController: 
```swift
import SwiftCamScanner
```
```swift
@IBOutlet weak var cropView: CropView!
```
```swift
 cropView.setUpImage(image: imageName)
 ```
 ```swift
  cropView.cropAndTransform{(croppedImage) in
    //Use the cropped Image
  }
  ```


## Example
An example project is included with this repo.  To run the example project, clone the repo, and run `pod install` from the Example directory.


## Author

Srinija Ammapalli

## License

SwiftCamScanner is available under the MIT license. See the LICENSE file for more info.
