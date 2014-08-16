

#import <iOS/iOS7/PrivateFrameworks/AppSupport/CPDistributedMessagingCenter.h>
#import <iOS/iOS7/SpringBoard/SBAssistantController.h>
#import <iOS/iOS7/PrivateFrameworks/AssistantServices/AFConnection.h>
#import <libactivator/LAActivator.h>
#import <libactivator/LAEvent.h>

#import <RocketBootstrap/rocketbootstrap.h>

static AFConnection *latestConnection = nil;
//________________________________________________________________
//      GoogiriData Stuff
//________________________________________________________________
@interface GoogiriData : NSObject
- (NSDictionary *)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userinfo;
@end


@implementation GoogiriData

- (NSDictionary *)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userinfo {
    if (![[userinfo objectForKey:@"query"] isEqualToString:@""] )

        // activate Siri here
        [[LAActivator sharedInstance] sendEvent:[LAEvent eventWithName:@"blah"] toListenerWithName: @"libactivator.system.virtual-assistant"];
        // wait 0.3 seconds and then inject into Siri
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [latestConnection startRequestWithCorrectedText:[userinfo objectForKey:@"query"] forSpeechIdentifier:nil];
        });

    return nil;
}

@end

%hook SpringBoard

- (id)init
{
    GoogiriData *googiriData = [[GoogiriData alloc] init];

    CPDistributedMessagingCenter *messagingCenter = [%c(CPDistributedMessagingCenter) centerNamed:@"com.mattcmultimedia.googirisiriactivator"];
    rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
    [messagingCenter runServerOnCurrentThread];


    // Register Messages
    [messagingCenter registerForMessageName:@"googiriActivateSiriWithQuery" target:googiriData selector:@selector(handleMessageNamed:withUserInfo:)];
    // NSLog(@"CREATED MESSAGING CENTER AND APPLIED ROCKET BOOTSTRAP");

    return %orig;
}


%end



%hook AFConnection

- (id)init {
    latestConnection = %orig;
    return %orig;
}

%end


%ctor {
    %init;
}