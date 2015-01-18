
//
// GMOEcoutezController
//
@interface GMOEcoutezController : NSObject
+(id)sharedInstance;
-(void)cancelRecognition;
@end

//
// GMOSearchApplication
//
@interface GMOSearchApplication : NSObject
@property (nonatomic,retain) UIWindow* window;
+ (id)sharedApplication;

// my added methods
- (void)googiriSendResult:(NSString *)text toWebserver:(NSString *)webserver;
@end

//
// GMOVoiceSearchViewController + GMOEcoutezControllerDelegate
//
@protocol GMOEcoutezControllerDelegate
-(void)ecoutezControllerDidCompleteRecognitionWithResult:(id)arg1;
@end
@interface GMOVoiceSearchViewController : UIViewController <GMOEcoutezControllerDelegate>
@end

//
// GMOVoiceRecognitionView
//
@interface GMOVoiceRecognitionView : UIView
- (void)cancelButtonPress:(id)arg1;
@end

//
// CPDistributedMessagingCenter
//
@interface CPDistributedMessagingCenter : NSObject
+ (id)centerNamed:(id)arg1;
- (BOOL)sendMessageName:(id)arg1 userInfo:(id)arg2;
@end

//
// RocketBootstrap
//
#import <RocketBootstrap/rocketbootstrap.h>

//
// Handlers
//
typedef enum {
    kSiri,
    kGoogle,
    kWebserver
} Handler;


//
// STATIC SETTINGS VARIABLES
//

static NSString *latestQuery;
static BOOL globalEnable = YES;
// addr
static NSMutableString *webserverAddress;
// default handler for queries
static Handler defaultHandler;
// whether or not Googiri should route obvious system commands to Siri sans the 'Siri' keyword
static NSArray *names;

static GMOVoiceRecognitionView *voiceRecognitionView;





#define PrefPath @"/var/mobile/Library/Preferences/com.mattcmultimedia.googirisettings.plist"

static void googiriOpenQueryInSiri() {
    CPDistributedMessagingCenter *messagingCenter = [%c(CPDistributedMessagingCenter) centerNamed:@"com.mattcmultimedia.googirisiriactivator"];
    rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
    [messagingCenter sendMessageName:@"googiriActivateSiriWithQuery" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                            latestQuery, @"query",
                                                                                        nil]];

}

static void googiriUpdatePreferences() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PrefPath];
    if(prefs == nil || !prefs) {
        //options for settings
        globalEnable = YES;
        defaultHandler = kGoogle;
        webserverAddress = nil;

    } else {

        id temp;
        temp = [prefs valueForKey:@"globalEnable"];
        globalEnable = temp ? [temp boolValue] : YES;

        temp = [prefs valueForKey:@"defaultHandler"];
        if (temp) {
            switch ([temp intValue]) {
                case 0: {
                    defaultHandler = kSiri;
                    break;
                }
                case 2: {
                    defaultHandler = kWebserver;
                    break;
                }
                case 1:
                default: {
                    defaultHandler = kGoogle;
                    break;
                }
            }
        } else {
            defaultHandler = kGoogle;
        }

        temp = [prefs valueForKey:@"webserverAddress"];
        webserverAddress = temp ? [(NSString *)temp mutableCopy] : nil;

        // create the array of names for each handler
        NSMutableString *tempStr;
        for (int h = 0; h < 3; ++h)
        {
            // look for key 0Names, 1Names, 2Names
            temp = [prefs valueForKey:[NSString stringWithFormat:@"%iNames", h]];
            tempStr = temp ? (NSMutableString *)temp : nil;

            // if tempStr or names[h] is defined
            if (tempStr != nil || names[h] != NULL) {
                //create the array of names. Separate on the space and then append a space to each and then add to array
                NSArray *justNamesArray = [tempStr componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                justNamesArray = [justNamesArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
                for (unsigned int i = 0; i < [justNamesArray count]; ++i)
                {
                    NSString *newEntry = [[justNamesArray objectAtIndex:i] stringByAppendingString:@" "];
                    if (![names[h] containsObject:newEntry]) {
                        // add a space because string parsing
                        [names[h] addObject:newEntry];
                    }
                }
            }
        }

    }

}


%hook GMOSearchApplication

%new
- (void)googiriSendResult:(NSString *)text toWebserver:(NSString *)webserver
{
    NSLog(@"[GOOGIRI] googiriSendResult: %@ toWebserver: %@", text, webserver);

    if ((webserver != nil) && ![webserver isEqualToString:@""]) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[webserver stringByAppendingString:[text stringByAddingPercentEscapesUsingEncoding: NSASCIIStringEncoding]]]
                                                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                           timeoutInterval:10];

        [request setHTTPMethod: @"GET"];

        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSError *error = nil;
            NSDictionary *responseOptions = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];

            if (error != nil) {
                NSLog(@"[GOOGIRI] Error parsing JSON.");
            } else {
                NSLog(@"[GOOGIRI] Response: %@", responseOptions);

                // if they want to do an activator action, do that
                if ([responseOptions objectForKey:@"activator"]) {
                    CPDistributedMessagingCenter *messagingCenter = [%c(CPDistributedMessagingCenter) centerNamed:@"com.mattcmultimedia.googirisiriactivator"];
                    rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
                    [messagingCenter sendMessageName:@"googiriActivateActivatorWithListener" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                                  [responseOptions objectForKey:@"activator"], @"listener",
                                                                                                                  nil]];
                }
                if ([responseOptions objectForKey:@"image"] || [responseOptions objectForKey:@"text"]) {
                    // if we got an image or text, show the alert view
                    NSLog(@"[GOOGIRI] Got text: %@", [responseOptions objectForKey:@"text"]);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"YO!"
                                                                        message:[responseOptions objectForKey:@"text"]
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Neat"
                                                              otherButtonTitles:nil];
                        [alert show];
                    });

                }

            }
        }];
    }
}

%end


%hook GMOVoiceRecognitionView
// keep a reference to the latest GMOVoiceRecognitionView so that I can programatically close it
-(id)initWithFrame:(CGRect)arg1
{
    voiceRecognitionView = %orig;
    return voiceRecognitionView;
}
%end


%hook GMOVoiceSearchViewController

-(void)ecoutezControllerDidCompleteRecognitionWithResult:(NSString *)result
{

    if (!globalEnable || !result) {
        %orig;
        return;
    }

    // FIRST - check for names at the beginning; these override the default handler

    for (int handler = kSiri; handler <= kWebserver; handler++)
    {
        // for each other handler, check for names in the query
        for (int n = 0; n < [[names objectAtIndex:handler] count]; ++n)
        {
            // if the name is at the beginning of the result string
            if ([result rangeOfString:[[names objectAtIndex:handler] objectAtIndex:n]].location == 0) {
                // remove the name from the result string
                result = [result stringByReplacingOccurrencesOfString:[[names objectAtIndex:handler] objectAtIndex:n] withString:@""];
                latestQuery = [result copy];

                switch (handler) {
                    case kSiri: {
                        // open the query in siri
                        googiriOpenQueryInSiri();
                        [voiceRecognitionView cancelButtonPress:nil];
                        break;
                    }
                    case kWebserver: {
                        [((GMOSearchApplication *)[%c(GMOSearchApplication) sharedApplication]) googiriSendResult:result toWebserver:webserverAddress];
                        [voiceRecognitionView cancelButtonPress:nil];
                        break;
                    }
                    case kGoogle:
                    default: {
                        %orig;
                        break;
                    }
                }

                // if we entered this block, the request was handled, so return
                return;
            }
        }
    }

    // SECOND - nothing special, use default

    latestQuery = [result copy];

    switch (defaultHandler) {
        case kSiri: {
            googiriOpenQueryInSiri();
            [voiceRecognitionView cancelButtonPress:nil];
            break;
        }
        case kWebserver: {
            [((GMOSearchApplication *)[%c(GMOSearchApplication) sharedApplication]) googiriSendResult:result toWebserver:webserverAddress];
            [voiceRecognitionView cancelButtonPress:nil];
            break;
        }
        case kGoogle:
        default: {
            %orig;
            break;
        }
    }

    return;
}

%end


static void reloadPrefsNotification(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo) {
    googiriUpdatePreferences();
}



%ctor {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    %init;

    // I would use shorthand but these need to be mutable inner arrays
    names = [[NSMutableArray alloc] initWithObjects:
           [[NSMutableArray alloc] initWithObjects:@"Siri ",
                                                   @"hey Siri ",
                                                   @"is Siri ",
                                                   @"siri ",
                                                   @"hey siri ",
                                                   @"is siri ",
                                                   nil],
           [[NSMutableArray alloc] initWithObjects:@"Google ",
                                                   @"hey Google ",
                                                   @"search for ",
                                                   @"search ",
                                                   @"Google for ",
                                                   @"Google search for ",
                                                   @"Google search ",
                                                   @"google ",
                                                   @"hey google ",
                                                   @"search for ",
                                                   @"search ",
                                                   @"google for ",
                                                   @"google search for ",
                                                   @"google search ",
                                                   nil],
           [[NSMutableArray alloc] initWithObjects:@"Jarvis ",
                                                   nil],
           nil
       ];


    CFNotificationCenterRef reload = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(reload, NULL, &reloadPrefsNotification,
                    CFSTR("com.mattcmultimedia.googirisettings/reload"), NULL, 0);
    googiriUpdatePreferences();
    [pool release];
}