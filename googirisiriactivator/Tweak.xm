

// #import <iOS/iOS7/PrivateFrameworks/AppSupport/CPDistributedMessagingCenter.h>
#import <iOS/iOS7/SpringBoard/SBAssistantController.h>
// #import <iOS/iOS7/PrivateFrameworks/AssistantServices/AFConnection.h>
#import <libactivator/LAActivator.h>
#import <libactivator/LAEvent.h>

@interface CPDistributedMessagingCenter : NSObject
+ (id)centerNamed:(id)arg1;
- (void)runServerOnCurrentThread;
- (void)registerForMessageName:(id)arg1 target:(id)arg2 selector:(SEL)arg3;
@end


@interface AFConnection : NSObject
- (void)startRequestWithCorrectedText:(id)arg1 forSpeechIdentifier:(id)arg2;
- (void)startRequestWithText:(id)text;
- (void)startDirectActionRequestWithString:(id)arg1;
- (void)startContinuationRequestWithUserInfo:(id)arg1;
@end


#import <RocketBootstrap/rocketbootstrap.h>

static AFConnection *latestConnection = nil;
//________________________________________________________________
//      GoogiriData Stuff
//________________________________________________________________
@interface GoogiriData : NSObject
- (NSDictionary *)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userInfo;
@end


@implementation GoogiriData

- (NSDictionary *)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userInfo {

    if ([name isEqualToString:@"googiriActivateSiriWithQuery"]) {
        if (![[userInfo objectForKey:@"query"] isEqualToString:@""] )
            NSLog(@"[GOOGIRI] - triggering activator");

            // activate Siri
            [[LAActivator sharedInstance] sendEvent:[LAEvent eventWithName:@"googiri_trigger_siri"] toListenerWithName:@"libactivator.system.virtual-assistant"];
            // wait and then inject into Siri
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                NSLog(@"[GOOGIRI] starting request with: %@", [userInfo objectForKey:@"query"]);
                [latestConnection startRequestWithText:@"hi"];
                [latestConnection startRequestWithText:[userInfo objectForKey:@"query"]];
            });
    } else if ([name isEqualToString:@"googiriActivateActivatorWithListener"]) {
        [[LAActivator sharedInstance] sendEvent:[LAEvent eventWithName:@"blah"] toListenerWithName:[userInfo objectForKey:@"listener"]];
    }

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
    [messagingCenter registerForMessageName:@"googiriActivateActivatorWithListener" target:googiriData selector:@selector(handleMessageNamed:withUserInfo:)];

    return %orig;
}


%end



%hook AFConnection

- (id)init {
    latestConnection = %orig;
    return latestConnection;
}

- (void)startRequestWithCorrectedText:(id)arg1 forSpeechIdentifier:(id)arg2
{
  %log;
  %orig;
}

%end


%ctor {
    %init;
}