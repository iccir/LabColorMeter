/*
    Lab Color Meter
    Copyright (c) 2011-2018 Ricci Adams

    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in
    the Software without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
    the Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "CaptureAndAverage.h"


static CGWindowID sGetWindowIDForSoftwareCursor(void)
{
    CFArrayRef descriptionList = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);
    CGWindowID result          = kCGNullWindowID;
    CGWindowID resultWithName  = kCGNullWindowID;

    CFIndex count = CFArrayGetCount(descriptionList);
    for (CFIndex i = 0; i < count; i++) {
        NSDictionary *description = (__bridge NSDictionary *)CFArrayGetValueAtIndex(descriptionList, i);

        CGWindowLevel cursorLevel = CGWindowLevelForKey(kCGCursorWindowLevelKey);
        CGWindowLevel windowLevel = [[description objectForKey:(id)kCGWindowLayer] intValue];
        
        if (cursorLevel == windowLevel) {
            NSString *name = [description objectForKey:(id)kCGWindowName];

            if ([name isEqualToString:@"Cursor"]) {
                result = [[description objectForKey:(id)kCGWindowNumber] intValue];
                break;
            } else {
                result = [[description objectForKey:(id)kCGWindowNumber] intValue];
            }
        }
    }
    
    CFRelease(descriptionList);
    
    return resultWithName ? resultWithName : result;
}


static void sConvertColor(CGFloat r, CGFloat g, CGFloat b, CGFloat *outL, CGFloat *outA, CGFloat *outB)
{
    ColorSyncProfileRef fromProfile = ColorSyncProfileCreateWithDisplayID(CGMainDisplayID());
    ColorSyncProfileRef toProfile   = ColorSyncProfileCreateWithName(kColorSyncGenericLabProfile);
    
    NSDictionary *from = [[NSDictionary alloc] initWithObjectsAndKeys:
        (__bridge id)fromProfile,                       (__bridge id)kColorSyncProfile,
        (__bridge id)kColorSyncRenderingIntentRelative, (__bridge id)kColorSyncRenderingIntent,
        (__bridge id)kColorSyncTransformDeviceToPCS,    (__bridge id)kColorSyncTransformTag,
        nil];

    NSDictionary *to = [[NSDictionary alloc] initWithObjectsAndKeys:
        (__bridge id)toProfile,                         (__bridge id)kColorSyncProfile,
        (__bridge id)kColorSyncRenderingIntentRelative, (__bridge id)kColorSyncRenderingIntent,
        (__bridge id)kColorSyncTransformPCSToDevice,    (__bridge id)kColorSyncTransformTag,
        nil];
        
    NSArray      *profiles = [[NSArray alloc] initWithObjects:from, to, nil];
    NSDictionary *options  = [[NSDictionary alloc] initWithObjectsAndKeys:
        (__bridge id)kColorSyncBestQuality, (__bridge id)kColorSyncConvertQuality,
        nil]; 

    ColorSyncTransformRef transform = ColorSyncTransformCreate((__bridge CFArrayRef)profiles, (__bridge CFDictionaryRef)options);
    
    if (transform) {
        float input[3]  = { r, g, b };
        float output[3] = { 0.0, 0.0, 0.0 };

        if (!ColorSyncTransformConvert(transform, 1, 1, &output[0], kColorSync32BitFloat, kColorSyncByteOrderDefault, 12, &input[0], kColorSync32BitFloat, kColorSyncByteOrderDefault, 12, NULL)) {
            NSLog(@"ColorSyncTransformConvert failed");
        }

        if (outL) *outL = output[0];
        if (outA) *outA = output[1];
        if (outB) *outB = output[2];
    
        CFRelease(transform);
    }

    if (fromProfile) CFRelease(fromProfile);
    if (toProfile)   CFRelease(toProfile);
}


extern CGPoint GetMouseLocation(void)
{
    CGPoint realUnflippedLocation = [NSEvent mouseLocation];

    NSArray  *screensArray = [NSScreen screens];
    NSScreen *screenZero   = [screensArray count] ? [screensArray objectAtIndex:0] : nil;

    CGFloat screenZeroHeight = screenZero ? [screenZero frame].size.height : 0.0;
    
    realUnflippedLocation.x = floor(realUnflippedLocation.x);
    realUnflippedLocation.y = ceil(realUnflippedLocation.y);

    return CGPointMake(realUnflippedLocation.x, screenZeroHeight - realUnflippedLocation.y);
}


extern CGImageRef CopyScreenshotImage(CGRect captureRect, CGWindowImageOption imageOption)
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    BOOL needsAirplayWorkaround = CGCursorIsDrawnInFramebuffer();
#pragma clang diagnostic pop

    CGImageRef image = NULL;

    if (needsAirplayWorkaround) {
        CGWindowID cursorWindowID = sGetWindowIDForSoftwareCursor();
        
        if (cursorWindowID != kCGNullWindowID) {
            image = CGWindowListCreateImage(captureRect, kCGWindowListOptionOnScreenBelowWindow, cursorWindowID, imageOption);
        } else {
            image = CGWindowListCreateImage(captureRect, kCGWindowListOptionAll, kCGNullWindowID, imageOption);
        }
        
    } else {
        image = CGWindowListCreateImage(captureRect, kCGWindowListOptionAll, kCGNullWindowID, imageOption);
    }

    return image;
}


static void sGetAverageRGB(CGImageRef image, CGFloat scaleFactor, CGRect apertureRect, CGFloat *outR, CGFloat *outG, CGFloat *outB)
{
    CFDataRef data = NULL;

    // 1) Check the CGBitmapInfo of the image.  We need it to be kCGBitmapByteOrder32Little with
    //    non-float-components and in RGB_ or _RGB;
    //
    CGBitmapInfo      bitmapInfo = CGImageGetBitmapInfo(image);
    CGImageAlphaInfo  alphaInfo  = bitmapInfo & kCGBitmapAlphaInfoMask;
    NSInteger         orderInfo  = bitmapInfo & kCGBitmapByteOrderMask;

    size_t bytesPerRow = CGImageGetBytesPerRow(image);

    BOOL isOrderOK = (orderInfo == kCGBitmapByteOrder32Little);
    BOOL isAlphaOK = NO;

    if (alphaInfo == kCGImageAlphaLast || alphaInfo == kCGImageAlphaNoneSkipLast) {
        alphaInfo = kCGImageAlphaLast;
        isAlphaOK = YES;
    } else if (alphaInfo == kCGImageAlphaFirst || alphaInfo == kCGImageAlphaNoneSkipFirst) {
        alphaInfo = kCGImageAlphaFirst;
        isAlphaOK = YES;
    }


    // 2) If the order and alpha are both ok, we can do a fast path with CGImageGetDataProvider()
    //    Else, convert it to  kCGImageAlphaNoneSkipLast+kCGBitmapByteOrder32Little
    //
    if (isOrderOK && isAlphaOK) {
        CGDataProviderRef provider = CGImageGetDataProvider(image);
        data = CGDataProviderCopyData(provider);
        
    } else {
        size_t       width      = CGImageGetWidth(image);
        size_t       height     = CGImageGetHeight(image);
        CGBitmapInfo bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Little;

        CGColorSpaceRef space   = CGImageGetColorSpace(image);
        CGContextRef    context = space ? CGBitmapContextCreate(NULL, width, height, 8, 4 * width, space, bitmapInfo) : NULL;

        if (context) {
            CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);

            const void *bytes = CGBitmapContextGetData(context);
            data = CFDataCreate(NULL, bytes, 4 * width * height);

            bytesPerRow = CGBitmapContextGetBytesPerRow(context);
            alphaInfo   = kCGImageAlphaLast;
        }
        
        CGContextRelease(context);
    }
    
    UInt8 *buffer = data ? (UInt8 *)CFDataGetBytePtr(data) : NULL;
    NSInteger totalSamples = apertureRect.size.width * apertureRect.size.height * scaleFactor * scaleFactor;
    
    if (buffer && (totalSamples > 0)) {
        NSUInteger totalR = 0;
        NSUInteger totalG = 0;
        NSUInteger totalB = 0;

        NSInteger minY = CGRectGetMinY(apertureRect) * scaleFactor;
        NSInteger maxY = CGRectGetMaxY(apertureRect) * scaleFactor;
        NSInteger minX = CGRectGetMinX(apertureRect) * scaleFactor;
        NSInteger maxX = CGRectGetMaxX(apertureRect) * scaleFactor;

        for (NSInteger y = minY; y < maxY; y++) {
            UInt8 *ptr    = buffer + (y * bytesPerRow) + (4 * minX);
            UInt8 *maxPtr = buffer + (y * bytesPerRow) + (4 * maxX);

            if (alphaInfo == kCGImageAlphaLast) {
                while (ptr < maxPtr) {
                    //   ptr[0]
                    totalB += ptr[1];
                    totalG += ptr[2];
                    totalR += ptr[3];

                    ptr += 4;
                }

            } else if (alphaInfo == kCGImageAlphaFirst) {
                while (ptr < maxPtr) {
                    totalB += ptr[0];
                    totalG += ptr[1];
                    totalR += ptr[2];
                    //   ptr[3]

                    ptr += 4;
                }
            }
        }

        if (outR) *outR = ((totalR / totalSamples) / 255.0);
        if (outG) *outG = ((totalG / totalSamples) / 255.0);
        if (outB) *outB = ((totalB / totalSamples) / 255.0);
    }

    if (data) {
        CFRelease(data);
    }
}


extern void ComputeLabAverage(
    CGImageRef image,
    CGFloat scaleFactor,  // The scale factor of the CGImage
    CGRect apertureRect,
    CGFloat *outL,
    CGFloat *outA,
    CGFloat *outB
) {
    CGFloat r, g, b;
    sGetAverageRGB(image, scaleFactor, apertureRect, &r, &g, &b);

    sConvertColor(r, g, b, outL, outA, outB);
}
