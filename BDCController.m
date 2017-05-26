#import "BDCController.h"

#define PREF_PATH @"/var/mobile/Library/Preferences/com.ichitaso.badgecleaner.plist"
#define Preferences @"com.ichitaso.badgecleaner"

@implementation BDCController
+ (BDCController *)sharedInstance {
	static dispatch_once_t p = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (id)init {
	if (self = [super init]) {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
        id isEnabled = [dict objectForKey:@"enabled"];
        BOOL enabled = isEnabled ? [isEnabled boolValue] : YES;
        
		prefs = [[NSUserDefaults alloc] initWithSuiteName:Preferences];
		
        [prefs registerDefaults:@{
			@"enable": @YES
            }];
        
		[prefs setBool:enabled forKey:@"enabled"];
        
		_prefsChangedFromSettings = NO;
		_enable = enabled;
        
	}
	return self;
}

- (void)updateSettings
{
    [self setEnabled:[prefs boolForKey:@"enabled"]];
    _prefsChangedFromSettings = NO;
}

- (void)setEnabled:(BOOL)enable
{
	if (enable == _enable)
		return;

	_enable = enable;

	if (!_prefsChangedFromSettings)
		[prefs setBool:_enable forKey:@"enabled"];
}

@end