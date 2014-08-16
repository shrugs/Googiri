#import <iOS/iOS7/PrivateFrameworks/Preferences/PSListController.h>
#import <iOS/iOS7/PrivateFrameworks/Preferences/PSSpecifier.h>

static CFNotificationCenterRef darwinNotifyCenter = CFNotificationCenterGetDarwinNotifyCenter();

@interface GoogiriSettingsListController: PSListController {
}

- (void)twitter:(id)arg;
// - (void)openAlexWrightPortfolio:(id)arg;
// - (void)setPreferenceValue:(id)value specifier:(id)specifier;
// - (void)openJustAddDesignPortfolio:(id)arg;
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
    if(notification) {
        CFNotificationCenterPostNotification(darwinNotifyCenter, (CFStringRef)notification, NULL, NULL, true);
    }
}

- (void)twitter:(id)arg {
    NSArray *urls = [[NSArray alloc] initWithObjects: @"twitter://user?id=606342610", @"tweetbot://Matt/follow/mattgcondon", @"https://twitter.com/mattgcondon", nil];
    for (int i = 0; i < [urls count]; ++i)
    {
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:[urls objectAtIndex:i]]]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[urls objectAtIndex:i]]];
            break;
        }
    }

}

// - (void)openAlexWrightPortfolio:(id)arg {
//     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://cargocollective.com/rednaxela1111"]];
// }

// - (void)openDemoVideo:(id)arg {
//     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.youtube.com/watch?v=7vuY2kPMQZs"]];
// }

// - (void)openJustAddDesignPortfolio:(id)arg {
//     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://justadddesign.net/"]];
// }

@end

//GoogiriExtraNames
@interface GoogiriExtraNames: PSListController {
}
- (void)setPreferenceValue:(id)value specifier:(id)specifier;

@end

@implementation GoogiriExtraNames
- (void)setPreferenceValue:(id)value specifier:(id)specifier {
    [super setPreferenceValue:value specifier:specifier];

    NSString *notification = [specifier propertyForKey:@"postNotification"];
    if(notification) {
        CFNotificationCenterPostNotification(darwinNotifyCenter, (CFStringRef)notification, NULL, NULL, true);
    }
}
@end