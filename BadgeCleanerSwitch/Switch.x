/**
 * Name: BadgeCleaner
 * Type: iOS SpringBoard extension (MobileSubstrate-based)
 * Desc: When you launch the app, display the menu to clear the badge.
 *
 * Author: ichitaso
 * License: Apache v2 License (See LICENSE file for details)
 *
 */

#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"

#define PREF_PATH @"/var/mobile/Library/Preferences/com.ichitaso.badgecleaner.plist"
#define kPrefKey @"enabled"

@interface BadgeCleanerSwitch : NSObject <FSSwitchDataSource>
@end

@implementation BadgeCleanerSwitch

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    
    id enable = [dict objectForKey:kPrefKey];
    BOOL isEnabled = enable ? [enable boolValue] : YES;
    
    return isEnabled ? FSSwitchStateOn : FSSwitchStateOff;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    
    NSMutableDictionary *mutableDict = dict ? [[dict mutableCopy] autorelease] : [NSMutableDictionary dictionary];
    
    switch (newState) {
        case FSSwitchStateIndeterminate:
            return;
        case FSSwitchStateOn:
            [mutableDict setValue:@YES forKey:kPrefKey];
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.ichitaso.badgecleaner-switchOn"), NULL, NULL, true);
            break;
        case FSSwitchStateOff:
            [mutableDict setValue:@NO forKey:kPrefKey];
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.ichitaso.badgecleaner-switchOff"), NULL, NULL, true);
            break;
    }
    
    [mutableDict writeToFile:PREF_PATH atomically:YES];
    
    // Update Flipswitch state
    [[FSSwitchPanel sharedPanel] stateDidChangeForSwitchIdentifier:@"com.ichitaso.badgecleanerfs"];
}

- (void)applyAlternateActionForSwitchIdentifier:(NSString *)switchIdentifier
{
    NSString *PO2_PATH = @"/var/mobile/Library/Preferences/net.angelxwind.preferenceorganizer2.plist";
    
    BOOL Tweaks = [[NSDictionary dictionaryWithContentsOfFile:PO2_PATH] objectForKey:@"TweaksName"] != nil;
    BOOL Tweaks1 = [[[NSDictionary dictionaryWithContentsOfFile:PO2_PATH] valueForKey:@"ShowTweaks"] boolValue];
    BOOL Tweaks2 = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/PreferenceOrganizer2.dylib"];
    BOOL Tweaks3 = [[NSFileManager defaultManager] fileExistsAtPath:PO2_PATH];
    BOOL Tweaks4 = [[NSDictionary dictionaryWithContentsOfFile:PO2_PATH] objectForKey:@"ShowTweaks"] != nil;
    
    NSString *po2Str = @"";
    NSString *po2Url = @"";
    
    if (Tweaks) {
        po2Str = [[[NSDictionary dictionaryWithContentsOfFile:PO2_PATH] objectForKey:@"TweaksName"] copy];
        if (![po2Str isEqualToString:@""]) {
            CFStringRef originalString = (__bridge CFStringRef)po2Str;
            
            CFStringRef encodedString = CFURLCreateStringByAddingPercentEscapes(
                                                                                kCFAllocatorDefault,
                                                                                originalString,
                                                                                NULL,
                                                                                CFSTR(":/?#[]@!$&'()*+,;="),
                                                                                kCFStringEncodingUTF8);
            
            po2Url = [NSString stringWithFormat:@"prefs:root=%@&path=BadgeCleaner",encodedString];
        } else {
            po2Url = @"prefs:root=Tweaks&path=BadgeCleaner";
        }
    }
    
    if (Tweaks && !Tweaks1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=BadgeCleaner"]];
    } else if (Tweaks && Tweaks1 && Tweaks2) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:po2Url]];
    } else if (Tweaks1 && Tweaks2) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Tweaks&path=BadgeCleaner"]];
    } else if (Tweaks2 && !Tweaks3) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Tweaks&path=BadgeCleaner"]];
    } else if (Tweaks2 && !Tweaks4) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Tweaks&path=BadgeCleaner"]];
    } else if (Tweaks2 && !Tweaks1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=BadgeCleaner"]];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=BadgeCleaner"]];
    }
}

@end

void reloadPrefsCallBack() {
    // Update Flipswitch state
    [[FSSwitchPanel sharedPanel] applyActionForSwitchIdentifier:@"com.ichitaso.badgecleanerfs"];
}

%ctor
{
    @autoreleasepool {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        NULL,
                                        (CFNotificationCallback)reloadPrefsCallBack,
                                        CFSTR("com.ichitaso.badgecleaner-prefs"),
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
    }
}