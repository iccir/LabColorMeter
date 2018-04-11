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

#import "MouseCursor.h"
#import "CaptureAndAverage.h"

@implementation MouseCursor {
    NSMutableArray *_listeners;
    id _globalMonitor;
    id _localMonitor;
}


+ (id) sharedInstance
{
    static id sSharedInstance = nil;
    if (!sSharedInstance) sSharedInstance = [[MouseCursor alloc] init];
    return sSharedInstance;
}


- (id) init
{
    if ((self = [super init])) {
        _globalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSMouseMovedMask handler:^(NSEvent *event) {
            [self _handleMouseMoved];
        }];

        _localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSMouseMovedMask handler:^(NSEvent *event) {
            [self _handleMouseMoved];
            return event;
        }];
        
        _listeners = CFBridgingRelease(CFArrayCreateMutable(NULL, 0, NULL));

        [self update];
        [self _handleMouseMoved];
        
    }
    
    return self;
}


- (void) _updateDisplay
{
    CGDirectDisplayID displayID = _displayID;
    uint32_t matchingDisplayCount;
    CGGetDisplaysWithPoint(_location, 1, &displayID, &matchingDisplayCount);

    if (_displayID != displayID) {
        _displayID = displayID;
        _screen    = nil;
        _displayScaleFactor = 1.0;

        for (NSScreen *screen in [NSScreen screens]) {
            NSInteger screenNumber = [[[screen deviceDescription] objectForKey:@"NSScreenNumber"] integerValue];

            if (_displayID == screenNumber) {
                _screen = screen;
                _displayScaleFactor = [screen backingScaleFactor];
                break;
            }
        }
        
        for (id<MouseCursorListener> listener in _listeners) {
            [listener mouseCursorMovedToDisplay:_displayID];
        }
    }
}


- (void) _handleMouseMoved
{
    CGPoint location = GetMouseLocation();

    if (!CGPointEqualToPoint(_location, location)) {
        _location = location;
        
        [self _updateDisplay];

        for (id<MouseCursorListener> listener in _listeners) {
            [listener mouseCursorMovedToLocation:_location];
        }
    }
}


- (void) update
{
    [self _updateDisplay];
}


- (void) movePositionByXDelta:(CGFloat)xDelta yDelta:(CGFloat)yDelta
{
    _location.x += xDelta;
    _location.y -= yDelta;
    
    CGWarpMouseCursorPosition(_location);

    [self _updateDisplay];

    for (id<MouseCursorListener> listener in _listeners) {
        [listener mouseCursorMovedToLocation:_location];
    }
}


- (void) addListener:(id<MouseCursorListener>)listener
{
    if (![_listeners containsObject:listener]) {
        [_listeners addObject:listener];
    }
}


- (void) removeListener:(id<MouseCursorListener>)listener
{
    [_listeners removeObject:listener];
}


@end
