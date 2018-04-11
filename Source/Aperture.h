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


@protocol ApertureDelegate;

@interface Aperture : NSObject

- (void) update;
- (void) getL:(CGFloat *)l a:(CGFloat *)a b:(CGFloat *)b;

@property (nonatomic, weak) id<ApertureDelegate> delegate;

@property (nonatomic, readonly /*retain*/) CGImageRef image;
@property (nonatomic, readonly) CGPoint offset;
@property (nonatomic, readonly) CGFloat scaleFactor;    // rect of image to display
@property (nonatomic, readonly) CGRect apertureRect;    // rect of aperture

@property (nonatomic, assign) NSInteger apertureSize;
@property (nonatomic, assign) NSInteger zoomLevel;
@property (nonatomic, assign) BOOL updatesContinuously;

@end


@protocol ApertureDelegate <NSObject>
- (void) apertureDidUpdate:(Aperture *)aperture;
@end
