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

#import "Aperture.h"
#import "MouseCursor.h"
#import "CaptureAndAverage.h"

@interface Aperture () <MouseCursorListener>
@property (nonatomic, strong) MouseCursor *cursor;
@property (nonatomic, strong) NSTimer *timer;
@end


@implementation Aperture {
    CFMutableDictionaryRef _displayToScaleFactorMap;
    NSTimeInterval         _lastUpdateTimeInterval;
    CGRect                 _screenBounds;
    CGRect                 _captureRect;
    CGFloat                _L;
    CGFloat                _a;
    CGFloat                _b;
    BOOL                   _needsUpdate;
    BOOL                   _canHaveMixedScaleFactors;
    BOOL                   _hasMixedScaleFactors;
}


- (id) init
{
    if ((self = [super init])) {
        _cursor = [MouseCursor sharedInstance];
    
        [_cursor addListener:self];

        _timer = [NSTimer timerWithTimeInterval:(1.0 / 30.0) target:self selector:@selector(_timerTick:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
        
        _zoomLevel = 1;

        [self _updateImage];
    }

    return self;
}


- (void) dealloc
{
    if (_displayToScaleFactorMap) {
        CFRelease(_displayToScaleFactorMap);
        _displayToScaleFactorMap = NULL;
    }
}


#pragma mark - Private Methods

- (void) _timerTick:(NSTimer *)timer
{
    NSTimeInterval now   = [NSDate timeIntervalSinceReferenceDate];
    BOOL needsUpdateTick = (now - _lastUpdateTimeInterval) > 0.5;
    
    if (_updatesContinuously || _needsUpdate || needsUpdateTick) {
        [self _updateOffsetAndCaptureRect];

        if (_canHaveMixedScaleFactors) {
            [self _updateScaleFactor];
            [self _updateAperture];
        }

        [self _updateImage];
        _lastUpdateTimeInterval = now;
    }
}


- (void) _updateImage
{
    CGWindowImageOption imageOption = kCGWindowImageDefault;
    
    if (_hasMixedScaleFactors) {
        if (_scaleFactor == 1.0) {
            imageOption |= kCGWindowImageNominalResolution;
        } else {
            imageOption |= kCGWindowImageBestResolution;
        }
    }

    CGImageRelease(_image);
    _image = CopyScreenshotImage(_captureRect, imageOption);

    ComputeLabAverage(_image, _scaleFactor, _apertureRect, &_L, &_a, &_b);

    [_delegate apertureDidUpdate:self];

    _needsUpdate = NO;
}


- (void) _updateScreenBounds
{
    CGFloat pointsToCapture = (120.0 / _zoomLevel) + (1 + 1); // Pad with 1 pixel on each side
    CGFloat captureOffset = floor(pointsToCapture / 2.0);

    _screenBounds = CGRectMake(-captureOffset, -captureOffset, pointsToCapture, pointsToCapture);
}


- (void) _updateOffsetAndCaptureRect
{
    CGPoint location = [_cursor location];
    
    _captureRect = _screenBounds;
    _captureRect.origin.x += location.x;
    _captureRect.origin.y += location.y;
}


- (void) _updateScaleFactor
{
    _scaleFactor = [_cursor displayScaleFactor];
    _hasMixedScaleFactors = NO;

    uint32_t count = 0;
    CGError  err   = kCGErrorSuccess;
    CGDirectDisplayID *displays = NULL;

    err = CGGetOnlineDisplayList(0, NULL, &count);
    if (!err && (count > 1)) {
        displays = alloca(sizeof(CGDirectDisplayID) * count);
        err = CGGetDisplaysWithRect(_captureRect, count, displays, &count);
    }

    if (!err && (count > 1)) {
        NSInteger existingScaleFactor = -1;
        for (NSInteger i = 0; i < count; i++) {
            NSInteger display     = displays[i];
            NSInteger scaleFactor = (NSInteger) CFDictionaryGetValue(_displayToScaleFactorMap, (const void *)display);

            if (existingScaleFactor < 0) {
                existingScaleFactor = scaleFactor;

            } else if (scaleFactor != existingScaleFactor) {
                _hasMixedScaleFactors = YES;
                break;
            }
        }
    }
}


- (void) _updateAperture
{
    CGFloat pointsToAverage = ((_apertureSize * 2) + 1) * (8.0 / (_zoomLevel * _scaleFactor));
    CGFloat averageOffset = ((_screenBounds.size.width - pointsToAverage) / 2.0);

    _apertureRect = CGRectMake( averageOffset,  averageOffset, pointsToAverage, pointsToAverage);
}


#pragma mark - Callbacks

- (void) mouseCursorMovedToLocation:(CGPoint)position
{
    _needsUpdate = YES;
}


- (void) mouseCursorMovedToDisplay:(CGDirectDisplayID)display
{
    [self _updateScaleFactor];
    [self _updateOffsetAndCaptureRect];
    [self _updateImage];
}


#pragma mark - Public Methods

- (void) update
{
    if (!_displayToScaleFactorMap) {
        _displayToScaleFactorMap = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
    }

    _canHaveMixedScaleFactors = NO;
    CFDictionaryRemoveAllValues(_displayToScaleFactorMap);

    NSInteger existingScaleFactor = -1;

    for (NSScreen *screen in [NSScreen screens]) {
        NSInteger screenNumber = [[[screen deviceDescription] objectForKey:@"NSScreenNumber"] integerValue];
        NSInteger scaleFactor  = (NSInteger)[screen backingScaleFactor];
        
        if (existingScaleFactor < 0) {
            existingScaleFactor = scaleFactor;
        } else if (scaleFactor != existingScaleFactor) {
            _canHaveMixedScaleFactors = YES;
        }
        
        CFDictionarySetValue(_displayToScaleFactorMap, (void *)screenNumber, (void *)scaleFactor);
    }

    [self _updateScreenBounds];
    [self _updateOffsetAndCaptureRect];
    [self _updateScaleFactor];
    [self _updateAperture];
    [self _updateImage];
}


- (void) getL:(CGFloat *)L a:(CGFloat *)a b:(CGFloat *)b
{
    if (L) *L = _L;
    if (a) *a = _a;
    if (b) *b = _b;
}


#pragma mark - Accessors

- (void) setApertureSize:(NSInteger)apertureSize
{
    if (_apertureSize != apertureSize) {
        _apertureSize = apertureSize;
        [self _updateAperture];
        [self _updateImage];
    }
}


- (void) setZoomLevel:(NSInteger)zoomLevel
{
    if (zoomLevel < 1) {
        zoomLevel = 1;
    }

    if (_zoomLevel != zoomLevel) {
        _zoomLevel = zoomLevel;
        
        [self _updateScreenBounds];
        [self _updateOffsetAndCaptureRect];
        [self _updateAperture];
        [self _updateImage];
    }
}


@end
