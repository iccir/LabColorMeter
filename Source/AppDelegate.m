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

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

#import "Aperture.h"
#import "MouseCursor.h"
#import "Preferences.h"
#import "PreviewView.h"


@interface AppDelegate () <ApertureDelegate, NSMenuDelegate>

- (IBAction) changeApertureSize:(id)sender;

// View menu
- (IBAction) updateMagnification:(id)sender;
- (IBAction) toggleContinuous:(id)sender;
- (IBAction) toggleFloatWindow:(id)sender;

@property (nonatomic, strong) IBOutlet NSWindow      *window;

@property (nonatomic, strong) IBOutlet NSSlider      *apertureSizeSlider;
@property (nonatomic, strong) IBOutlet PreviewView   *previewView;

@property (nonatomic, strong) IBOutlet NSTextField   *value1;
@property (nonatomic, strong) IBOutlet NSTextField   *value2;
@property (nonatomic, strong) IBOutlet NSTextField   *value3;

@end


@implementation AppDelegate {
    MouseCursor *_cursor;
    Aperture    *_aperture;
}


- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _cursor   = [MouseCursor sharedInstance];
    _aperture = [[Aperture alloc] init];
    
    [_aperture setDelegate:self];

    if ([NSFont respondsToSelector:@selector(monospacedDigitSystemFontOfSize:weight:)]) {
        CGFloat  pointSize      = [[[self value1] font] pointSize];
        NSFont  *monospacedFont = [NSFont monospacedDigitSystemFontOfSize:pointSize weight:NSFontWeightRegular];

        [[self value1] setFont:monospacedFont];
        [[self value2] setFont:monospacedFont];
        [[self value3] setFont:monospacedFont];
    }

    [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *inEvent) {
        return [self _handleLocalEvent:inEvent];
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:) name:PreferencesDidChangeNotification        object:nil];
   
    NSWindow *window = [self window];

    [window setContentBorderThickness:0.0 forEdge:NSMinYEdge];
    [window setContentBorderThickness:172.0 forEdge:NSMaxYEdge];
    [window setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
    [window setAutorecalculatesContentBorderThickness:NO forEdge:NSMaxYEdge];

    [self _handlePreferencesDidChange:nil];
    
    [_aperture update];
    
    [window makeKeyAndOrderFront:self];
    [window selectPreviousKeyView:self];
}


- (void) applicationDidChangeScreenParameters:(NSNotification *)notification
{
    [_cursor update];
    [_aperture update];
}


- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
    SEL action = [menuItem action];

    if (action == @selector(updateMagnification:)) {
        [menuItem setState:([menuItem tag] == [_aperture zoomLevel])];

    } else if (action == @selector(toggleContinuous:)) {
        [menuItem setState:[_aperture updatesContinuously]];
    }

    return YES;
}


- (void) cancel:(id)sender
{
    NSWindow *window = [self window];

    if ([window firstResponder] != window) {
        [window makeFirstResponder:window];
    }
}


- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
    return NSTerminateNow;
}   


- (void) windowWillClose:(NSNotification *)note
{
    if ([[note object] isEqual:[self window]]) {
        [NSApp terminate:self];
    }
}


#pragma mark - Private Methods


static NSString *sApplyFilter(NSString *inString)
{
    NSUInteger length = [inString length];
    unichar buffer[10];
        
    if (length < 10 && length > 3) {
        [inString getCharacters:buffer range:NSMakeRange(0, length)];
        
        if (buffer[0] == '-' &&
            buffer[1] == '0' &&
            buffer[2] == '.' &&
            buffer[3] == '0')
        {
            BOOL allZero = YES;
            
            for (NSInteger i = 3; i < length; i++) {
                allZero = allZero && (buffer[i] == '0');
                if (!allZero) break;
            }

            if (allZero) {
                return [inString substringFromIndex:1];
            }
        }
    }
    
    return inString;
}


- (void) apertureDidUpdate:(Aperture *)aperture
{
    NSString *lString = nil;
    NSString *aString = nil;
    NSString *bString = nil;

    CGFloat l, a, b;
    [_aperture getL:&l a:&a b:&b];

    NSString *format = @"%0.03lf";
    
    lString = [NSString stringWithFormat:format, (l * 100.0)];
    aString = [NSString stringWithFormat:format, (a * 256.0) - 128.0];
    bString = [NSString stringWithFormat:format, (b * 256.0) - 128.0];
        
    lString = sApplyFilter(lString);
    aString = sApplyFilter(aString);
    bString = sApplyFilter(bString);

    [[self value1] setStringValue:lString];
    [[self value2] setStringValue:aString];
    [[self value3] setStringValue:bString];

    PreviewView *previewView = [self previewView];
    [previewView setImage:[_aperture image]];
    [previewView setImageScale:[_aperture scaleFactor]];
    [previewView setOffset:[_aperture offset]];
    [previewView setApertureRect:[_aperture apertureRect]];
}


#pragma mark - Private Methods

- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    Preferences *preferences  = [Preferences sharedInstance];
    NSInteger    apertureSize = [preferences apertureSize];

    PreviewView *previewView     = [self previewView];
    NSSlider    *apertureSlider  = [self apertureSizeSlider];

    [apertureSlider setIntegerValue:apertureSize];
    [previewView setZoomLevel:[preferences zoomLevel]];

    [_aperture setZoomLevel:[preferences zoomLevel]];
    [_aperture setUpdatesContinuously:[preferences updatesContinuously]];
    [_aperture setApertureSize:apertureSize];
   
    if ([preferences floatWindow]) {
        [[self window] setLevel:NSFloatingWindowLevel];
    } else {
        [[self window] setLevel:NSNormalWindowLevel];
    }
}


- (NSEvent *) _handleLocalEvent:(NSEvent *)event
{
    if (![[self window] isKeyWindow]) {
        return event;
    }

    NSEventType type = [event type];

    if (type == NSKeyDown) {
        NSUInteger modifierFlags = [event modifierFlags];

        id        firstResponder = [[self window] firstResponder];
        NSString *characters     = [event charactersIgnoringModifiers];
        unichar   c              = [characters length] ? [characters characterAtIndex:0] : 0; 
        BOOL      isShift        = (modifierFlags & NSShiftKeyMask)   > 0;
        BOOL      isLeftOrRight  = (c == NSLeftArrowFunctionKey) || (c == NSRightArrowFunctionKey);
        BOOL      isUpOrDown     = (c == NSUpArrowFunctionKey)   || (c == NSDownArrowFunctionKey);
        BOOL      isArrowKey     = isLeftOrRight || isUpOrDown;

        // Text fields get all events
        if ([firstResponder isKindOfClass:[NSTextField class]] ||
            [firstResponder isKindOfClass:[NSTextView  class]])
        {
            return event;

        // Pop-up menus that are first responder get up/down events
        } else if ([firstResponder isKindOfClass:[NSPopUpButton class]] && isUpOrDown) {
            return event;
        }

        if (isArrowKey) {
            if (firstResponder != [self window]) {
                [[self window] makeFirstResponder:[self window]];
            }

            CGFloat xDelta = 0.0;
            CGFloat yDelta = 0.0;

            if (c == NSUpArrowFunctionKey) {
                yDelta =  1.0;
            } else if (c == NSDownArrowFunctionKey) {
                yDelta = -1.0;
            } else if (c == NSLeftArrowFunctionKey) {
                xDelta = -1.0;
            } else if (c == NSRightArrowFunctionKey) {
                xDelta =  1.0;
            }

            if (isShift) {
                xDelta *= 10.0;
                yDelta *= 10.0;
            }

            [_cursor movePositionByXDelta:xDelta yDelta:yDelta];

            return nil;
        }
    }

    return event;
}


#pragma mark - IBActions

- (IBAction) changeApertureSize:(id)sender
{
    [[Preferences sharedInstance] setApertureSize:[sender integerValue]];
}


- (IBAction) updateMagnification:(id)sender
{
    NSInteger tag = [sender tag];
    [[Preferences sharedInstance] setZoomLevel:[sender tag]];
    [_aperture setZoomLevel:tag];
}


- (IBAction) toggleContinuous:(id)sender
{
    Preferences *preferences = [Preferences sharedInstance];
    BOOL updatesContinuously = ![preferences updatesContinuously];
    [preferences setUpdatesContinuously:updatesContinuously];
}


- (IBAction) toggleFloatWindow:(id)sender
{
    Preferences *preferences = [Preferences sharedInstance];
    BOOL floatWindow = ![preferences floatWindow];
    [preferences setFloatWindow:floatWindow];
}


@end
