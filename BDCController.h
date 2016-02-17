@interface BDCController : NSObject
{
    NSUserDefaults *prefs;
}

@property (nonatomic) BOOL prefsChangedFromSettings;
@property (nonatomic) BOOL enable;
+ (BDCController *)sharedInstance;
- (void)updateSettings;
- (void)setEnabled:(BOOL)enable;

@end
