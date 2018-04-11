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

#import <Foundation/Foundation.h>

@protocol MouseCursorListener;


@interface MouseCursor : NSObject

+ (id) sharedInstance;

- (void) movePositionByXDelta:(CGFloat)xDelta yDelta:(CGFloat)yDelta;

- (void) addListener:(id<MouseCursorListener>)listener;
- (void) removeListener:(id<MouseCursorListener>)listener;

- (void) update;

@property (nonatomic, assign) CGPoint location;

@property (nonatomic, assign, readonly) CGDirectDisplayID displayID;
@property (nonatomic, retain, readonly) NSScreen *screen;
@property (nonatomic, assign, readonly) CGFloat displayScaleFactor;

@end


@protocol MouseCursorListener <NSObject>
- (void) mouseCursorMovedToLocation:(CGPoint)position;
- (void) mouseCursorMovedToDisplay:(CGDirectDisplayID)display;
@end
