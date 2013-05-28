#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

static CFNotificationCenterRef darwinNotifyCenter = CFNotificationCenterGetDarwinNotifyCenter();

@interface GoogiriSettingsListController: PSListController {
}

- (void)donationButton:(id)arg;
- (void)openAlexWrightPortfolio:(id)arg;
- (void)setPreferenceValue:(id)value specifier:(id)specifier;
- (void)openJustAddDesignPortfolio:(id)arg;
@end

@implementation GoogiriSettingsListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"GoogiriSettings" target:self] retain];
	}
	return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(id)specifier {
    [super setPreferenceValue:value specifier:specifier];

    NSString *notification = [specifier propertyForKey:@"postNotification"];
    // if ([notification isEqualToString:@"com.mattcmultimedia.googirisettings/useAltIcon"]) {
    //     //change icons here.
    //     NSMutableDictionary *entry = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/Library/PreferenceLoader/Preferences/GoogiriSettings.plist"];
    //     //load entry dict
    //     NSLog(@"entry: %@", entry);
    //     if ([(NSString *)[[entry objectForKey:@"entry"] objectForKey:@"icon"] isEqualToString:@"googiri.png"]) {
    //         //if is original icon, switch to alt
    //         //[entry removeObjectForKey:@"icon"];
    //         [[entry objectForKey:@"entry"] removeObjectForKey:@"icon"];
    //         [[entry objectForKey:@"entry"] setObject:@"altGoogiri.png" forKey:@"icon"];
    //     } else {
    //         //is alt, switch to orginal
    //         [[entry objectForKey:@"entry"] removeObjectForKey:@"icon"];
    //         [[entry objectForKey:@"entry"] setObject:@"googiri.png" forKey:@"icon"];
    //     }
    //     NSLog(@"new Dictionary: %@", entry);
    //     NSDictionary *newEntry = [[NSDictionary alloc] initWithDictionary:entry];
    //     BOOL succeed = [newEntry writeToFile:@"/Library/PreferenceLoader/Preferences/GoogiriSettings.plist" atomically:YES];
    //     NSLog(@"succeeded? %i", succeed);
    //     [entry release];
    //     [newEntry release];
    //     //if "alt in the icon name, change to norm, else, change to alt"
    //     //save back to disk
    // }
    if(notification) {
        CFNotificationCenterPostNotification(darwinNotifyCenter, (CFStringRef)notification, NULL, NULL, true);
    }
}

- (void)donationButton:(id)arg {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mattcmultimedia%40gmail%2ecom&lc=US&item_name=MattCMultimedia%20Development%20%3a%29&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted"]];
}

- (void)openAlexWrightPortfolio:(id)arg {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://cargocollective.com/rednaxela1111"]];
}

- (void)openDemoVideo:(id)arg {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.youtube.com/watch?v=7vuY2kPMQZs"]];
}

- (void)openJustAddDesignPortfolio:(id)arg {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://justadddesign.net/"]];
}

@end

//googiriSpecificSystemCommands
@interface GoogiriSpecificSystemCommands: PSListController {
}
- (void)setPreferenceValue:(id)value specifier:(id)specifier;

@end

@implementation GoogiriSpecificSystemCommands
- (void)setPreferenceValue:(id)value specifier:(id)specifier {
    [super setPreferenceValue:value specifier:specifier];

    NSString *notification = [specifier propertyForKey:@"postNotification"];
    if(notification) {
        CFNotificationCenterPostNotification(darwinNotifyCenter, (CFStringRef)notification, NULL, NULL, true);
    }
}
@end