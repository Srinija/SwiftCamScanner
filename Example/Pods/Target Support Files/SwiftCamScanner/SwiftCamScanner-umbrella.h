#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "CamScanner-Bridging-Header.h"
#import "OpenCVWrapper.h"

FOUNDATION_EXPORT double SwiftCamScannerVersionNumber;
FOUNDATION_EXPORT const unsigned char SwiftCamScannerVersionString[];

