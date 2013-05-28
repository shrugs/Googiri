

#import <SpringBoard/SpringBoard.h>
#import <UIKit/UIKit.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <SpringBoard/SBAssistantController.h>
#import <libactivator/LASimpleListener.h>
#import <AssistantServices.framework/AFConnection.h>
static AFConnection *latestConnection = nil;
//________________________________________________________________
//      GoogiriData Stuff
//________________________________________________________________
@interface GoogiriData : NSObject
- (NSDictionary *)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userinfo;
@end


@implementation GoogiriData

- (NSDictionary *)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userinfo {

    // Process userinfo (simple dictionary) and return a dictionary (or nil)
    [[%c(LASimpleListener) sharedInstance] activateVirtualAssistant];

    if (![[userinfo objectForKey:@"query"] isEqualToString:@""] )
        [latestConnection startRequestWithCorrectedText:[userinfo objectForKey:@"query"] forSpeechIdentifier:@"00000000-0000-0000-0000-000000000000"];


    //performSelector:withObject:afterDelay


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
    CPDistributedMessagingCenter *messagingCenter;
    // Center name must be unique, recommend using application identifier.
    messagingCenter = [%c(CPDistributedMessagingCenter) centerNamed:@"com.mattcmultimedia.googirisiriactivator"];
    [messagingCenter runServerOnCurrentThread];
    GoogiriData *googiriData = [[GoogiriData alloc] init];
    // Register Messages
    [messagingCenter registerForMessageName:@"googiriActivateSiriWithQuery" target:googiriData selector:@selector(handleMessageNamed:withUserInfo:)];
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