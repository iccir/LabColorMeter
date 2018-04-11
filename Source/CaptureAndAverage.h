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

#ifndef CaptureAndAverage_h
#define CaptureAndAverage_h

// Gets the current mouse cursor location.
//
extern CGPoint GetMouseLocation(void);


// Takes a screenshot of the specified captureRect.
// Result must be released via CFImageRelease() or a memory leak will occur.
//
extern CGImageRef CopyScreenshotImage(
    CGRect captureRect,
    CGWindowImageOption imageOption // imageOption arguments passed to kCGWindowListOptionOnScreenBelowWindow
) CF_RETURNS_RETAINED;


extern void ComputeLabAverage(
    CGImageRef image,     // In image from CopyScreenshotImage()
    CGFloat scaleFactor,  // The scale factor of the CGImage
    CGRect apertureRect,  // Rectangle of the aperture in image coordinates
    CGFloat *outL,        // Out L* value
    CGFloat *outA,        // Out a* value
    CGFloat *outB         // Out b* value
);

#endif /* CaptureAndAverage_h */
