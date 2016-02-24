/**
 * Name: BadgeCleaner
 * Type: iOS SpringBoard extension (MobileSubstrate-based)
 * Desc: Rotate the device screen with gestures
 *
 * Author: ichitaso
 * License: Apache v2 License (See LICENSE file for details)
 *
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <firmware.h>

#define PREF_PATH @"/var/mobile/Library/Preferences/com.ichitaso.badgecleaner.plist"

@interface SBIcon : NSObject
@end

@interface SBIconView
@property (nonatomic,retain) SBIcon * icon;
- (SBIcon *)icon;
- (void)setHighlighted:(BOOL)arg1;
@end

@interface SBIconModel
- (id)visibleIconIdentifiers;
- (id)applicationIconForBundleIdentifier:(id)arg1;
@end

@interface SBApplicationIcon
- (id)badgeNumberOrString;
- (void)setBadge:(id)arg1;
@end

@interface SBIconViewMap
@property (nonatomic,retain,readonly) SBIconModel * iconModel;
+ (id)homescreenMap;
- (SBIconModel *)iconModel;
@end

@interface SBIconController
+ (id)sharedInstance;
- (void)_launchIcon:(id)arg1;
- (void)clearBadges;
- (void)openApps;
@end

static NSString *idStr = @"";
static id launchApp;
static int badgeValue;
static BOOL openApp;
static BOOL isEnabled;

static UIWindow * window = nil;
static UIAlertController *sheet = nil;

%hook SBIconController
- (void)_launchIcon:(id)arg1
{
    launchApp = arg1;
    
    NSMutableArray *array = [@[arg1] mutableCopy];
    
    NSString *str = [array componentsJoinedByString:@";"];
    
    if ([str respondsToSelector:@selector(rangeOfString:)]) {
        NSRange found = [str rangeOfString:@"\">"];
        if (found.location != NSNotFound) {
            idStr = [str substringFromIndex:found.location + 3];
            
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
            
            NSMutableDictionary *mutableDict = dict ? [[dict mutableCopy] autorelease] : [NSMutableDictionary dictionary];
            
            [mutableDict setValue:idStr forKey:@"idStr"];
            [mutableDict writeToFile:PREF_PATH atomically:YES];
            
            isEnabled = [dict objectForKey:@"enabled"] ? [[dict objectForKey:@"enabled"] boolValue] : YES;
            openApp = [dict objectForKey:@"openApp"] ? [[dict objectForKey:@"openApp"] boolValue] : NO;
            
            NSString *badgeStr = [[[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:idStr] badgeNumberOrString];
            
            badgeValue = [badgeStr intValue];
            
            BOOL hideApp = [[dict objectForKey:idStr] boolValue];
            NSString *hideStr = hideApp ? idStr : nil;
            
            if (isEnabled && badgeValue > 0 && !openApp && ![idStr isEqualToString:hideStr]) {
                sheet = [UIAlertController alertControllerWithTitle:@"BadgeCleaner"
                                                            message:nil
                                                     preferredStyle:UIAlertControllerStyleActionSheet];
                
                [sheet addAction:[UIAlertAction actionWithTitle:@"Clear Badges" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self clearBadges];
                }]];
                
                [sheet addAction:[UIAlertAction actionWithTitle:@"Open App" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self openApps];
                }]];
                
                [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    [window release];
                    window = nil;
                }]];
                
                CGRect screenSize = [[UIScreen mainScreen] bounds];
                
                window = [[UIWindow alloc] initWithFrame:screenSize];
                window.windowLevel = 666666;
                
                UIView *uv = [[UIView alloc] initWithFrame:screenSize];
                
                [window addSubview:uv];
                
                UIViewController *vc = [[UIViewController alloc] init];
                
                vc.view.frame = [UIScreen mainScreen].applicationFrame;
                
                window.rootViewController = vc;
                [window makeKeyAndVisible];
                
                if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0 &&
                    UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    
                    sheet.popoverPresentationController.sourceView = vc.view;
                    sheet.popoverPresentationController.sourceRect = vc.view.bounds;
                    // Do not show the balloon of the arrow
                    sheet.popoverPresentationController.permittedArrowDirections = 0;
                }
                
                [vc presentViewController:sheet animated:YES completion:nil];
            } else {
                %orig;
                
                [mutableDict setValue:@NO forKey:@"openApp"];
                [mutableDict writeToFile:PREF_PATH atomically:YES];
            }
        }
    }
}

%new
- (void)clearBadges
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    idStr = [[dict objectForKey:@"idStr"] copy];
    
    NSMutableDictionary *mutableDict = dict ? [[dict mutableCopy] autorelease] : [NSMutableDictionary dictionary];
    
    [mutableDict setValue:@NO forKey:@"openApp"];
    [mutableDict writeToFile:PREF_PATH atomically:YES];
    
    [[[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:idStr] setBadge:nil];
    
    [window release];
    window = nil;
}

%new
- (void)openApps
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    
    NSMutableDictionary *mutableDict = dict ? [[dict mutableCopy] autorelease] : [NSMutableDictionary dictionary];
    
    [mutableDict setValue:@YES forKey:@"openApp"];
    [mutableDict writeToFile:PREF_PATH atomically:YES];
    
    [[%c(SBIconController) sharedInstance] _launchIcon:launchApp];
    
    [window release];
    window = nil;
}
%end

%hook SBIconBadgeView
- (void)configureForIcon:(id)arg1 location:(int)arg2 highlighted:(BOOL)arg3
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    
    NSMutableArray *array = [@[arg1] mutableCopy];
    
    NSString *str = [array componentsJoinedByString:@";"];
    
    if ([str respondsToSelector:@selector(rangeOfString:)]) {
        NSRange found = [str rangeOfString:@"\">"];
        if (found.location != NSNotFound) {
            idStr = [str substringFromIndex:found.location + 3];
            
            BOOL hideApp = [[dict objectForKey:idStr] boolValue];
            NSString *hideStr = hideApp ? idStr : nil;
            
            if ([idStr isEqualToString:hideStr]) {
                %orig(nil,arg2,arg3);
                [[[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:idStr] setBadge:nil];
            } else {
                %orig;
            }
        }
    } else {
        %orig;
    }
}
%end

%hook SBIconView
- (void)setHighlighted:(BOOL)arg1
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    
    isEnabled = [dict objectForKey:@"enabled"] ? [[dict objectForKey:@"enabled"] boolValue] : YES;
    
    if (isEnabled) {
        %orig(NO);
    } else {
        %orig();
    }
}
%end

// Called by the flipswitch toggle
//==============================================================================

#import "BDCController.h"

void prefsChanged() {
    [BDCController sharedInstance].prefsChangedFromSettings = YES;
    [[BDCController sharedInstance] updateSettings];
    
}

void switchToggleOn() {
    [[BDCController sharedInstance] setEnabled:YES];
}

void switchToggleOff() {
    [[BDCController sharedInstance] setEnabled:NO];
}

//==============================================================================

%ctor
{
    @autoreleasepool {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        NULL,
                                        (CFNotificationCallback)switchToggleOn,
                                        CFSTR("com.ichitaso.badgecleaner-switchOn"),
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        NULL,
                                        (CFNotificationCallback)switchToggleOff,
                                        CFSTR("com.ichitaso.badgecleaner-switchOff"),
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
        
        %init;
    }
}