/**
 * Name: BadgeCleaner
 * Type: iOS SpringBoard extension (MobileSubstrate-based)
 * Desc: When you launch the app, display the menu to clear the badge.
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
- (id)badgeNumberOrString;
- (void)setBadge:(id)arg1;
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
- (void)clearHighlightedIcon;
- (void)clearBadges;
- (void)openApps;
- (SBIconViewMap *)homescreenIconViewMap; // iOS 9.3
- (void)showAlertView;
@end

@interface SBFolderIcon
- (void)_updateBadgeValue;
@end

static NSString *idStr = @"";
static id identifier;
static int badgeValue;
static BOOL openApp;
static BOOL isEnabled;
static BOOL swipeMenu;
static int direction;
static BOOL disableSpot;

static UIWindow * window = nil;
static UIAlertController *sheet = nil;
static void clearSheet() {
    sheet = nil;
}

// iOS 8 & 9
//==============================================================================
%group iOS_8_9
%hook SBIconController
- (void)setLastTouchedIcon:(id)arg1
{
    identifier = arg1;
    %orig;
}

// Swipe Icon Mode
//==============================================================================
- (void)icon:(id)arg1 touchMoved:(id)arg2
{
    %orig;
    
    BOOL iconTool = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/IconTool.dylib"];
    
    if (iconTool) return;
    
    // Disable Edting Mode
    if ([[%c(SBIconController) sharedInstance] isEditing]) return;
    
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    
    direction = [dict objectForKey:@"direction"] ? [[dict objectForKey:@"direction"] intValue] : 0;
    
    UITouch *touch = arg2;
    
    SBIconView *iconView = [%c(SBIconView) alloc];
    UIView *view = MSHookIvar<UIView *>(iconView,"_currentImageView");
    
    CGPoint location = [touch locationInView:view];
    CGPoint prevLocation = [touch previousLocationInView:view];
    
    if (location.y - prevLocation.y > 0 && location.x - prevLocation.x == 0 && direction == 1) {
        [self showAlertView];
    } else if (location.y - prevLocation.y < 0 && location.x - prevLocation.x == 0 && direction == 0) {
        [self showAlertView];
    }
}

%new
- (void)showAlertView
{
    NSMutableArray *array = [@[identifier] mutableCopy];
    
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
            swipeMenu = [dict objectForKey:@"swipeMenu"] ? [[dict objectForKey:@"swipeMenu"] boolValue] : YES;
            openApp = [dict objectForKey:@"openApp"] ? [[dict objectForKey:@"openApp"] boolValue] : NO;
            
            if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_3) {
                //iOS 9.3
                SBIconModel *iconModel = (SBIconModel *)[[[%c(SBIconController) sharedInstance] homescreenIconViewMap] iconModel];
                SBIcon *icon = (SBIcon *)[iconModel applicationIconForBundleIdentifier:idStr];
                
                badgeValue = [[icon badgeNumberOrString] intValue];
            } else {
                NSString *badgeStr = [[[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:idStr] badgeNumberOrString];
                
                badgeValue = [badgeStr intValue];
            }
            
            BOOL hideApp = [[dict objectForKey:idStr] boolValue];
            NSString *hideStr = hideApp ? idStr : nil;
            
            if (isEnabled && swipeMenu && badgeValue > 0 && !openApp && ![idStr isEqualToString:hideStr] && sheet == nil) {
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
                
                if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_9_0) {
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
                    
                    [vc presentViewController:sheet animated:YES completion:^{
                        
                        double delayInSeconds = 0.8;
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            clearSheet();
                        });
                        
                    }];
                } else {
                    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
                    while (vc.presentedViewController != nil && !vc.presentedViewController.isBeingDismissed) {
                        vc = vc.presentedViewController;
                    }
                    
                    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0 &&
                        UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                        
                        sheet.popoverPresentationController.sourceView = vc.view;
                        sheet.popoverPresentationController.sourceRect = vc.view.bounds;
                        // Do not show the balloon of the arrow
                        sheet.popoverPresentationController.permittedArrowDirections = 0;
                    }
                    
                    [vc presentViewController:sheet animated:YES completion:^{
                        
                        double delayInSeconds = 0.8;
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            clearSheet();
                        });
                        
                    }];
                }
            } else {
                [mutableDict setValue:@NO forKey:@"openApp"];
                [mutableDict writeToFile:PREF_PATH atomically:YES];
            }
        }
    }
}

// Launch Icon Mode
//==============================================================================
- (void)_launchIcon:(id)arg1
{
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
            swipeMenu = [dict objectForKey:@"swipeMenu"] ? [[dict objectForKey:@"swipeMenu"] boolValue] : YES;
            openApp = [dict objectForKey:@"openApp"] ? [[dict objectForKey:@"openApp"] boolValue] : NO;
            
            if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_3) {
                //iOS 9.3
                SBIconModel *iconModel = (SBIconModel *)[[[%c(SBIconController) sharedInstance] homescreenIconViewMap] iconModel];
                SBIcon *icon = (SBIcon *)[iconModel applicationIconForBundleIdentifier:idStr];
                
                badgeValue = [[icon badgeNumberOrString] intValue];
            } else {
                NSString *badgeStr = [[[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:idStr] badgeNumberOrString];
                
                badgeValue = [badgeStr intValue];
            }
            
            BOOL hideApp = [[dict objectForKey:idStr] boolValue];
            NSString *hideStr = hideApp ? idStr : nil;
            
            if (isEnabled && !swipeMenu && badgeValue > 0 && !openApp && ![idStr isEqualToString:hideStr] && sheet == nil) {
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
                
                if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_9_0) {
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
                    
                    [vc presentViewController:sheet animated:YES completion:^{
                        
                        double delayInSeconds = 0.8;
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            clearSheet();
                        });
                        
                    }];
                } else {
                    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
                    while (vc.presentedViewController != nil && !vc.presentedViewController.isBeingDismissed) {
                        vc = vc.presentedViewController;
                    }
                    
                    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0 &&
                        UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                        
                        sheet.popoverPresentationController.sourceView = vc.view;
                        sheet.popoverPresentationController.sourceRect = vc.view.bounds;
                        // Do not show the balloon of the arrow
                        sheet.popoverPresentationController.permittedArrowDirections = 0;
                    }
                    
                    [vc presentViewController:sheet animated:YES completion:^{
                        
                        double delayInSeconds = 0.8;
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            clearSheet();
                        });
                        
                    }];
                }
                
                [self clearHighlightedIcon];
            } else {
                %orig;
                
                [window release];
                window = nil;
                
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
    
    if ([%c(SBIconViewMap) respondsToSelector:@selector(homescreenMap)]) {
        [[[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:idStr] setBadge:nil];
    } else { // iOS 9.3
        SBIconController *iconCtrl = [%c(SBIconController) sharedInstance];
        
        SBIconModel *iconModel = (SBIconModel *)[[iconCtrl homescreenIconViewMap] iconModel];
        SBIcon *icon = (SBIcon *)[iconModel applicationIconForBundleIdentifier:idStr];
        [icon setBadge:nil];
    }
    
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
    
    [[%c(SBIconController) sharedInstance] _launchIcon:identifier];
    
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
                if ([%c(SBIconViewMap) respondsToSelector:@selector(homescreenMap)]) {
                    [[[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:idStr] setBadge:nil];
                } else { // iOS 9.3
                    SBIconController *iconCtrl = [%c(SBIconController) sharedInstance];
                    
                    SBIconModel *iconModel = (SBIconModel *)[[iconCtrl homescreenIconViewMap] iconModel];
                    SBIcon *icon = (SBIcon *)[iconModel applicationIconForBundleIdentifier:idStr];
                    [icon setBadge:nil];
                }
                
                [[%c(SBFolderIcon) alloc] _updateBadgeValue];
            } else {
                %orig;
            }
        }
    } else {
        %orig;
    }
}
%end
%end

// iOS 10
//==============================================================================
%group iOS_10
%hook SBIconController
- (void)setLastTouchedIcon:(id)arg1
{
    identifier = arg1;
    %orig;
}

// Swipe Icon Mode
//==============================================================================
- (void)icon:(id)arg1 touchMoved:(id)arg2
{
    %orig;
    
    BOOL iconTool = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/IconTool.dylib"];
    
    if (iconTool) return;
    
    // Disable Edting Mode
    if ([[%c(SBIconController) sharedInstance] isEditing]) return;
    
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    
    direction = [dict objectForKey:@"direction"] ? [[dict objectForKey:@"direction"] intValue] : 0;
    
    UITouch *touch = arg2;
    
    SBIconView *iconView = [%c(SBIconView) alloc];
    UIView *view = MSHookIvar<UIView *>(iconView,"_currentImageView");
    
    CGPoint location = [touch locationInView:view];
    CGPoint prevLocation = [touch previousLocationInView:view];
    
    if (location.y - prevLocation.y > 0 && location.x - prevLocation.x == 0 && direction == 1) {
        [self showAlertView];
    } else if (location.y - prevLocation.y < 0 && location.x - prevLocation.x == 0 && direction == 0) {
        [self showAlertView];
    }
}

%new
- (void)showAlertView
{
    NSMutableArray *array = [@[identifier] mutableCopy];
    
    NSString *str = [array componentsJoinedByString:@";"];
    
    if ([str respondsToSelector:@selector(rangeOfString:)]) {
        NSRange found = [str rangeOfString:@">"];
        if (found.location != NSNotFound) {
            idStr = [str substringFromIndex:found.location + 2];
            
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
            
            NSMutableDictionary *mutableDict = dict ? [[dict mutableCopy] autorelease] : [NSMutableDictionary dictionary];
            
            [mutableDict setValue:idStr forKey:@"idStr"];
            [mutableDict writeToFile:PREF_PATH atomically:YES];
            
            isEnabled = [dict objectForKey:@"enabled"] ? [[dict objectForKey:@"enabled"] boolValue] : YES;
            swipeMenu = [dict objectForKey:@"swipeMenu"] ? [[dict objectForKey:@"swipeMenu"] boolValue] : YES;
            openApp = [dict objectForKey:@"openApp"] ? [[dict objectForKey:@"openApp"] boolValue] : NO;
            
            SBIconModel *iconModel = (SBIconModel *)[[[%c(SBIconController) sharedInstance] homescreenIconViewMap] iconModel];
            SBIcon *icon = (SBIcon *)[iconModel applicationIconForBundleIdentifier:idStr];
            
            badgeValue = [[icon badgeNumberOrString] intValue];
            
            BOOL hideApp = [[dict objectForKey:idStr] boolValue];
            NSString *hideStr = hideApp ? idStr : nil;
            
            if (isEnabled && swipeMenu && badgeValue > 0 && !openApp && ![idStr isEqualToString:hideStr] && sheet == nil) {
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
                
                UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
                while (vc.presentedViewController != nil && !vc.presentedViewController.isBeingDismissed) {
                    vc = vc.presentedViewController;
                }
                
                if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0 &&
                    UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    
                    sheet.popoverPresentationController.sourceView = vc.view;
                    sheet.popoverPresentationController.sourceRect = vc.view.bounds;
                    // Do not show the balloon of the arrow
                    sheet.popoverPresentationController.permittedArrowDirections = 0;
                }
                
                [vc presentViewController:sheet animated:YES completion:^{
                    
                    double delayInSeconds = 0.8;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        clearSheet();
                    });
                    
                }];
            } else {
                [mutableDict setValue:@NO forKey:@"openApp"];
                [mutableDict writeToFile:PREF_PATH atomically:YES];
            }
        }
    }
}

// Launch Icon Mode
//==============================================================================
- (void)_launchIcon:(id)arg1
{
    NSMutableArray *array = [@[arg1] mutableCopy];
    
    NSString *str = [array componentsJoinedByString:@";"];
    
    if ([str respondsToSelector:@selector(rangeOfString:)]) {
        NSRange found = [str rangeOfString:@">"];
        if (found.location != NSNotFound) {
            idStr = [str substringFromIndex:found.location + 2];
            
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
            
            NSMutableDictionary *mutableDict = dict ? [[dict mutableCopy] autorelease] : [NSMutableDictionary dictionary];
            
            [mutableDict setValue:idStr forKey:@"idStr"];
            [mutableDict writeToFile:PREF_PATH atomically:YES];
            
            isEnabled = [dict objectForKey:@"enabled"] ? [[dict objectForKey:@"enabled"] boolValue] : YES;
            swipeMenu = [dict objectForKey:@"swipeMenu"] ? [[dict objectForKey:@"swipeMenu"] boolValue] : YES;
            openApp = [dict objectForKey:@"openApp"] ? [[dict objectForKey:@"openApp"] boolValue] : NO;
            
            SBIconModel *iconModel = (SBIconModel *)[[[%c(SBIconController) sharedInstance] homescreenIconViewMap] iconModel];
            SBIcon *icon = (SBIcon *)[iconModel applicationIconForBundleIdentifier:idStr];
            
            badgeValue = [[icon badgeNumberOrString] intValue];
            
            BOOL hideApp = [[dict objectForKey:idStr] boolValue];
            NSString *hideStr = hideApp ? idStr : nil;
            
            if (isEnabled && !swipeMenu && badgeValue > 0 && !openApp && ![idStr isEqualToString:hideStr] && sheet == nil) {
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
                
                UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
                while (vc.presentedViewController != nil && !vc.presentedViewController.isBeingDismissed) {
                    vc = vc.presentedViewController;
                }
                
                if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0 &&
                    UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    
                    sheet.popoverPresentationController.sourceView = vc.view;
                    sheet.popoverPresentationController.sourceRect = vc.view.bounds;
                    // Do not show the balloon of the arrow
                    sheet.popoverPresentationController.permittedArrowDirections = 0;
                }
                
                [vc presentViewController:sheet animated:YES completion:^{
                    
                    double delayInSeconds = 0.8;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        clearSheet();
                    });
                    
                }];
                
                [self clearHighlightedIcon];
            } else {
                %orig;
                
                [window release];
                window = nil;
                
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
    
    SBIconController *iconCtrl = [%c(SBIconController) sharedInstance];
    
    SBIconModel *iconModel = (SBIconModel *)[[iconCtrl homescreenIconViewMap] iconModel];
    SBIcon *icon = (SBIcon *)[iconModel applicationIconForBundleIdentifier:idStr];
    [icon setBadge:nil];
    
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
    
    [[%c(SBIconController) sharedInstance] _launchIcon:identifier];
    
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
        NSRange found = [str rangeOfString:@">"];
        if (found.location != NSNotFound) {
            idStr = [str substringFromIndex:found.location + 2];
            
            BOOL hideApp = [[dict objectForKey:idStr] boolValue];
            NSString *hideStr = hideApp ? idStr : nil;
            
            if ([idStr isEqualToString:hideStr]) {
                %orig(nil,arg2,arg3);
                
                SBIconController *iconCtrl = [%c(SBIconController) sharedInstance];
                
                SBIconModel *iconModel = (SBIconModel *)[[iconCtrl homescreenIconViewMap] iconModel];
                SBIcon *icon = (SBIcon *)[iconModel applicationIconForBundleIdentifier:idStr];
                [icon setBadge:nil];
                
                [[%c(SBFolderIcon) alloc] _updateBadgeValue];
            } else {
                %orig;
            }
        }
    } else {
        %orig;
    }
}
%end
%end

// Disable Home Screen SpotLight
//==============================================================================
%group iOS9
%hook SBSpotlightSettings
- (BOOL)enableSpotlightHomeScreenGesture
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    
    isEnabled = [dict objectForKey:@"enabled"] ? [[dict objectForKey:@"enabled"] boolValue] : YES;
    swipeMenu = [dict objectForKey:@"swipeMenu"] ? [[dict objectForKey:@"swipeMenu"] boolValue] : YES;
    disableSpot = [dict objectForKey:@"disableSpot"] ? [[dict objectForKey:@"disableSpot"] boolValue] : NO;
    
    if ((isEnabled && swipeMenu && badgeValue > 0) || disableSpot) {
        return NO;
    } else {
        return %orig;
    }
}
%end

%hook SBSearchScrollView
- (BOOL)gestureRecognizerShouldBegin:(id)arg1
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    
    isEnabled = [dict objectForKey:@"enabled"] ? [[dict objectForKey:@"enabled"] boolValue] : YES;
    swipeMenu = [dict objectForKey:@"swipeMenu"] ? [[dict objectForKey:@"swipeMenu"] boolValue] : YES;
    disableSpot = [dict objectForKey:@"disableSpot"] ? [[dict objectForKey:@"disableSpot"] boolValue] : NO;
    
    if ((isEnabled && swipeMenu && badgeValue > 0) || disableSpot) {
        return NO;
    } else {
        return %orig;
    }
}
%end
%end

@interface SBSearchScrollView : UIScrollView
@end

@interface SBSearchGesture
@property (assign,nonatomic) BOOL enabled;
- (void)scrollViewEnabled:(BOOL)enabled;
@end

%group iOS8
%hook SBSearchGesture
%new
- (void)scrollViewEnabled:(BOOL)enabled
{
    [MSHookIvar<SBSearchScrollView *>(self, "_scrollView") setScrollEnabled:enabled];
}

- (void)_updateScrollingEnabled
{
    %orig;
    
    if ([[%c(SBIconController) sharedInstance] isEditing]) return;
    
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    
    isEnabled = [dict objectForKey:@"enabled"] ? [[dict objectForKey:@"enabled"] boolValue] : YES;
    swipeMenu = [dict objectForKey:@"swipeMenu"] ? [[dict objectForKey:@"swipeMenu"] boolValue] : YES;
    disableSpot = [dict objectForKey:@"disableSpot"] ? [[dict objectForKey:@"disableSpot"] boolValue] : NO;
    
    if ((isEnabled && swipeMenu && badgeValue > 0) || disableSpot) {
        [self scrollViewEnabled:NO];
    }
}
%end
%end

// No More Shadow
//==============================================================================
//%hook SBIconView
//- (void)setHighlighted:(BOOL)arg1
//{
//    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
//    
//    isEnabled = [dict objectForKey:@"enabled"] ? [[dict objectForKey:@"enabled"] boolValue] : YES;
//    
//    if (isEnabled) {
//        %orig(NO);
//    } else {
//        %orig();
//    }
//}
//%end

static void LoadSettings()
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    
    isEnabled = [dict objectForKey:@"enabled"] ? [[dict objectForKey:@"enabled"] boolValue] : YES;
    swipeMenu = [dict objectForKey:@"swipeMenu"] ? [[dict objectForKey:@"swipeMenu"] boolValue] : YES;
    direction = [dict objectForKey:@"direction"] ? [[dict objectForKey:@"direction"] intValue] : 0;
    disableSpot = [dict objectForKey:@"disableSpot"] ? [[dict objectForKey:@"disableSpot"] boolValue] : NO;
}

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
                                        (CFNotificationCallback)LoadSettings,
                                        CFSTR("com.ichitaso.badgecleaner.preferencechanged"),
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
        
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
        
        if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0) {
            %init(iOS_10);
        } else {
            %init(iOS_8_9);
        }
        
        if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0) {
            %init(iOS9);
        } else {
            %init(iOS8);
        }
        
        LoadSettings();
    }
}