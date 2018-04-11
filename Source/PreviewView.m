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

#import "PreviewView.h"


@implementation PreviewView

- (void) dealloc
{
    CGImageRelease(_image);
	_image = NULL;
}


- (BOOL) isOpaque
{
    return YES;
}


- (void) drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    CGContextSaveGState(context);
 
    [[NSColor grayColor] set];
    NSRectFill(NSMakeRect(0, 0, 120, 120));

    NSRect bounds = [self bounds];
    CGRect zoomedBounds = bounds;

    if (_image) {
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);

        CGFloat size   = ((CGImageGetWidth(_image) / _imageScale) * _zoomLevel);
        CGFloat origin = round((bounds.size.width - size) / 2.0);
        
        zoomedBounds = CGRectMake(origin, origin, size, size);
        
        CGFloat zoomTweak = 0.0;
        if (_imageScale > 1) {
            zoomTweak = (_zoomLevel / (_imageScale * _imageScale));
        }
           
        CGRect zoomedImageBounds = zoomedBounds;
        zoomedImageBounds.origin.x -= (_offset.x * _zoomLevel) - zoomTweak;
        zoomedImageBounds.origin.y += (_offset.y * _zoomLevel) - zoomTweak;
        
        CGContextDrawImage(context, zoomedImageBounds, _image);
    }

    // Draw aperture
    {
        CGAffineTransform transform = CGAffineTransformMakeScale(_zoomLevel, _zoomLevel);
        CGRect apertureRect = CGRectApplyAffineTransform(_apertureRect, transform);

        if (apertureRect.size.width < bounds.size.width) {
            apertureRect = CGRectInset(apertureRect, -1, -1);
        } else {
            apertureRect = CGRectInset(apertureRect, 1, 1);
        }
        

        apertureRect.origin.x += zoomedBounds.origin.x;
        apertureRect.origin.y += zoomedBounds.origin.y;

        CGRect innerRect = CGRectInset(apertureRect, 1.5, 1.5);
        CGContextSetGrayStrokeColor(context, 1.0, 0.66);
        CGContextStrokeRect(context, innerRect);

        CGContextSetGrayStrokeColor(context, 0.0, 0.75);

        CGContextStrokeRect(context, CGRectInset(apertureRect, 0.5, 0.5));
    }

    if ([[self window] backingScaleFactor] > 1) {
        CGRect strokeRect = NSInsetRect(bounds, 0.25, 0.25);
        CGContextSetLineWidth(context, 0.5);
        CGContextSetGrayStrokeColor(context, 0.0, 0.33);
        CGContextStrokeRect(context, strokeRect);
    } else {
        CGRect strokeRect = NSInsetRect(bounds, 0.5, 0.5);
        CGContextSetLineWidth(context, 0.25);
        CGContextSetGrayStrokeColor(context, 0.0, 0.33);
        CGContextStrokeRect(context, strokeRect);
    }
    

    CGContextRestoreGState(context);
}


- (BOOL) canBecomeKeyView
{
    return YES;
}


#pragma mark - Accessors

- (void) setZoomLevel:(NSInteger)zoomLevel
{
    if (zoomLevel < 1) {
        zoomLevel = 1;
    }

    if (_zoomLevel != zoomLevel) {
        _zoomLevel = zoomLevel;
        [self setNeedsDisplay:YES];
    }
}


- (void) setOffset:(CGPoint)offset
{
    if (!CGPointEqualToPoint(_offset, offset)) {
        _offset = offset;
        [self setNeedsDisplay:YES];
    }
}


- (void) setImageScale:(CGFloat)imageScale
{
    if (_imageScale != imageScale) {
        _imageScale = imageScale;
        [self setNeedsDisplay:YES];
    }
}


- (void) setApertureRect:(CGRect)apertureRect
{
    if (!CGRectEqualToRect(_apertureRect, apertureRect)) {
        _apertureRect = apertureRect;
        [self setNeedsDisplay:YES];
    }
}


- (void) setImage:(CGImageRef)image
{
    if (_image != image) {
        CGImageRelease(_image);
        _image = CGImageRetain(image);

        [self setNeedsDisplay:YES];
    }
}


@end
