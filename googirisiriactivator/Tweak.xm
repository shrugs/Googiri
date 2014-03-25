

#import <iOS7/PrivateFrameworks/AppSupport/CPDistributedMessagingCenter.h>
#import <iOS7/SpringBoard/SBAssistantController.h>
#import <libactivator/LASimpleListener.h>
#import <iOS7/PrivateFrameworks/AssistantServices/AFConnection.h>
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
        [[%c(LASimpleListener) sharedInstance] activateVirtualAssistant];

        [latestConnection startRequestWithCorrectedText:[userinfo objectForKey:@"query"] forSpeechIdentifier:@"00000000-0000-0000-0000-000000000000"];

    return nil;
}

- (id)init
{
    self = [super init];
    if (self) {

    }
    return self;
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
    // NSLog(@"CREATED MESSAGEING CENTER AND APPLIED ROCKET BOOTSTRAP");

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