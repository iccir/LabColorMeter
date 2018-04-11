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

#import "Preferences.h"

NSString * const PreferencesDidChangeNotification = @"PreferencesDidChange";

static NSString * const sZoomLevelKey           = @"ZoomLevel";
static NSString * const sApertureSizeKey        = @"ApertureSize";
static NSString * const sUpdatesContinuouslyKey = @"UpdatesContinuously";
static NSString * const sFloatWindowKey         = @"FloatWindow";


static void sRegisterDefaults(void)
{
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

    void (^i)(NSString *, NSInteger) = ^(NSString *key, NSInteger value) {
        NSNumber *number = [NSNumber numberWithInteger:value];
        [defaults setObject:number forKey:key];
    };

    void (^b)(NSString *, BOOL) = ^(NSString *key, BOOL yn) {
        NSNumber *number = [NSNumber numberWithBool:yn];
        [defaults setObject:number forKey:key];
    };

    i( sZoomLevelKey,         8 );
    i( sApertureSizeKey,      0 );
    
    b( sUpdatesContinuouslyKey,   NO  );
    b( sFloatWindowKey,           NO  );
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}


@implementation Preferences


+ (id) sharedInstance
{
    static Preferences *sSharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sRegisterDefaults();
    
        sSharedInstance = [[Preferences alloc] init];
        [sSharedInstance _load];
    });
    
    return sSharedInstance;
}


- (id) init
{
    if ((self = [super init])) {
        [self _load];

        [self addObserver:self forKeyPath:@"apertureSize"        options:0 context:NULL];
        [self addObserver:self forKeyPath:@"zoomLevel"           options:0 context:NULL];
        [self addObserver:self forKeyPath:@"updatesContinuously" options:0 context:NULL];
        [self addObserver:self forKeyPath:@"floatWindow"         options:0 context:NULL];
    }

    return self;
}


- (void) _load
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSInteger (^loadInteger)(NSString *) = ^(NSString *key) {
        return [defaults integerForKey:key];
    };

    BOOL (^loadBoolean)(NSString *) = ^(NSString *key) {
        return [defaults boolForKey:key];
    };

    _zoomLevel             = loadInteger( sZoomLevelKey           );
    _apertureSize          = loadInteger( sApertureSizeKey        );

    _updatesContinuously   = loadBoolean( sUpdatesContinuouslyKey );
    _floatWindow           = loadBoolean( sFloatWindowKey         );
}


- (void) _save
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults]; 

    void (^saveInteger)(NSInteger, NSString *) = ^(NSInteger i, NSString *key) {
        [defaults setInteger:i forKey:key];
    };

    void (^saveBoolean)(BOOL, NSString *) = ^(BOOL yn, NSString *key) {
        [defaults setBool:yn forKey:key];
    };

    saveInteger( _zoomLevel,                sZoomLevelKey           );
    saveInteger( _apertureSize,             sApertureSizeKey        );
    
    saveBoolean( _updatesContinuously,      sUpdatesContinuouslyKey );
    saveBoolean( _floatWindow,              sFloatWindowKey         );

    [defaults synchronize];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PreferencesDidChangeNotification object:self];
        [self _save];
    }
}

    
@end
