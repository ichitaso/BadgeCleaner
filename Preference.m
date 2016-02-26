/**
 * Name: BadgeCleaner
 * Type: iOS SpringBoard extension (MobileSubstrate-based)
 * Desc: Rotate the device screen with gestures
 *
 * Author: ichitaso
 * License: Apache v2 License (See LICENSE file for details)
 *
 */

#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>
#import <Preferences/PSListController.h>

@interface BDCPreferenceController : PSListController <UIActionSheetDelegate>
- (NSArray *)specifiers;
- (void)reloadPrefs:(NSNotification *)notification;
- (void)addRespringButton:(NSNotification *)notification;
@end

@implementation BDCPreferenceController
- (instancetype)init
{
    self = [super init];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    (CFNotificationCallback)reloadPrefsCallBack,
                                    CFSTR("com.ichitaso.badgecleaner-switchOn"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    (CFNotificationCallback)reloadPrefsCallBack,
                                    CFSTR("com.ichitaso.badgecleaner-switchOff"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPrefs:) name:@"reloadPrefs" object:nil];
    
    // Call Respring Alert
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    (CFNotificationCallback)addRespringButtonCallBack,
                                    CFSTR("com.ichitaso.badgecleaner-respring"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addRespringButton:) name:@"AddRespringButton" object:nil];
    
    return self;
}

void reloadPrefsCallBack() {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadPrefs" object:nil];
}

- (void)reloadPrefs:(NSNotification *)notification
{
    [self reloadSpecifiers];
}

void addRespringButtonCallBack () {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AddRespringButton" object:nil];
}

- (void)addRespringButton:(NSNotification *)notification
{
    UIAlertView *alert =
    [[UIAlertView alloc] initWithTitle:@"Respring Required"
                               message:nil
                              delegate:self
                     cancelButtonTitle:@"Later"
                     otherButtonTitles:@"Respring",nil];
    [alert show];
}

- (void)respring {
    system("/usr/bin/killall SpringBoard");
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self respring];
    }
}

- (NSArray *)specifiers
{
    if (_specifiers == nil) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"BadgeCleaner" target:self] retain];
    }
    return _specifiers;
}

- (void)openTwitter:(id)specifier
{
	NSMutableArray *items = [NSMutableArray array];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot://"]]) {
        [items addObject:@"Open in Tweetbot"];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
        [items addObject:@"Open in Twitter"];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"theworld:"]]) {
        [items addObject:@"Open in TheWolrd"];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetlogix:"]]) {
        [items addObject:@"Open in TweetLogix"];
    }
    
	[items addObject:@"Open in Safari"];
	
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Follow @ichitaso"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];
    
    for (NSString *buttonTitle in items) {
        [sheet addButtonWithTitle:buttonTitle];
    }
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
    [sheet showInView:[UIApplication sharedApplication].keyWindow];
    [sheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *option = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([option isEqualToString:@"Open in Tweetbot"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tweetbot:///user_profile/ichitaso"]];
    } else if ([option isEqualToString:@"Open in TheWolrd"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"theworld://scheme/user/?screen_name=ichitaso"]];
    } else if ([option isEqualToString:@"Open in TweetLogix"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tweetlogix:///home?username=ichitaso"]];
    } else if ([option isEqualToString:@"Open in Twitter"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=ichitaso"]];
    } else if ([option isEqualToString:@"Open in Safari"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/ichitaso/"]];
    }
}

@end

static NSString * const InitialURL = @"http://willfeeltips.appspot.com/depiction/donate.html";

@interface WFTWebBrowserViewController : UIViewController
{
    UIWebView *webView;
}
@property (nonatomic, retain) UIWebView *webView;

@end

@implementation WFTWebBrowserViewController

@synthesize webView;

- (void)dealloc
{
    [webView release];
    [super dealloc];
}

- (void)viewDidLoad
{
    CGRect webFrame = [[UIScreen mainScreen] applicationFrame];
    
    self.webView = [[[UIWebView alloc] initWithFrame:webFrame] autorelease];
    self.webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    
    [self.view addSubview:self.webView];
    
    NSURL *url = [NSURL URLWithString:InitialURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [self.webView loadRequest:request];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.webView = nil;
}

- (void)btnBackPress
{
    if (self.webView.canGoBack) {
        [self.webView goBack];
    }
}

- (void)btnNextPress
{
    if (self.webView.canGoForward) {
        [self.webView goForward];
    }
}

@end

@interface WFTWebView : PSViewController
{
    WFTWebBrowserViewController *_viewController;
    UIView *view;
}
@end

@implementation WFTWebView

- (id)initForContentSize:(CGSize)size
{
    CGRect r = [[UIScreen mainScreen] bounds];
    CGFloat w = r.size.width;
    CGFloat h = r.size.height;
    
    if ([[PSViewController class] instancesRespondToSelector:@selector(initForContentSize:)]) {
        self = [super initForContentSize:size];
    } else {
        self = [super init];
    }
    if (self) {
        CGRect frame =  CGRectMake(0, 0, w, h);
        view = [[UIView alloc] initWithFrame:frame];
        _viewController = [[WFTWebBrowserViewController alloc] init];
        _viewController.view.frame = CGRectMake(_viewController.view.frame.origin.x, _viewController.view.frame.origin.y + 44, _viewController.view.frame.size.width, _viewController.view.frame.size.height - 44);
        [view addSubview:_viewController.view];
        
        if ([self respondsToSelector:@selector(navigationItem)]) {
            //Set Back Button
            UIBarButtonItem *rightButton =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply
                                                          target:self
                                                          action:@selector(btnBackPress)];
            
            [[self navigationItem] setRightBarButtonItem:rightButton];
            [rightButton release];
        }
    }
    return self;
}

- (UIView *)view
{
    return view;
}

- (CGSize)contentSize
{
    return [view frame].size;
}

- (void)dealloc
{
    [_viewController release];
    [view release];
    [super dealloc];
}

- (void)btnBackPress
{
    [_viewController btnBackPress];
}

@end