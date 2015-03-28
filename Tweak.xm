

#import "Tweak.h"

//
// STATIC SETTINGS VARIABLES
//
static NSString *latestQuery;
static BOOL globalEnable = YES;
static NSMutableString *webserverAddress;
static Handler defaultHandler;
static NSArray *names;

// things I need references to at some point
static GMOVoiceRecognitionView *voiceRecognitionView;
static GMORootViewController *rootViewController;
static GMOHomePageController *homePageController;


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
    // NSLog(@"[GOOGIRI] googiriSendResult: %@ toWebserver: %@", text, webserver);

    if ((webserver != nil) && ![webserver isEqualToString:@""]) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[webserver stringByAppendingString:[text stringByAddingPercentEscapesUsingEncoding: NSASCIIStringEncoding]]]
                                                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                           timeoutInterval:10];

        [request setHTTPMethod: @"GET"];

        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {

            if (connectionError || !data) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [voiceRecognitionView cancelButtonPress:nil];
                    SCLAlertView *alert = [[SCLAlertView alloc] init];
                    [alert showError:rootViewController title:@"Uh oh!" subTitle:@"No connectivity to webserver :(" closeButtonTitle:@"OK" duration:3.0f];
                });
                return;
            }

            NSError *error = nil;
            NSDictionary *responseOptions = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];

            if (error != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [voiceRecognitionView cancelButtonPress:nil];
                });
                return;
            } else {
                // NSLog(@"[GOOGIRI] Response: %@", responseOptions);

                // if they want to do an activator action, do that
                if ([responseOptions objectForKey:@"activator"]) {
                    CPDistributedMessagingCenter *messagingCenter = [%c(CPDistributedMessagingCenter) centerNamed:@"com.mattcmultimedia.googirisiriactivator"];
                    rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
                    [messagingCenter sendMessageName:@"googiriActivateActivatorWithListener" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                                  [responseOptions objectForKey:@"activator"], @"listener",
                                                                                                                  nil]];
                }
                if ([responseOptions objectForKey:@"text"]) {
                    // otherwise if we got text, show the alert view
                    dispatch_async(dispatch_get_main_queue(), ^{

                        NSString *defaultTitle = @"Success";
                        SCLAlertViewStyle alertStyle = Success;
                        if ([responseOptions objectForKey:@"style"]) {
                            NSString *s = [responseOptions objectForKey:@"style"];
                            if ([s isEqualToString:@"success"]) {
                                alertStyle = Success;
                                defaultTitle = @"Booyah!";
                            } else if ([s isEqualToString:@"error"]) {
                                alertStyle = Error;
                                defaultTitle = @"Uh oh!";
                            } else if ([s isEqualToString:@"notice"]) {
                                alertStyle = Notice;
                                defaultTitle = @"Check it!";
                            } else if ([s isEqualToString:@"warning"]) {
                                alertStyle = Warning;
                                defaultTitle = @"Whoa There!";
                            } else if ([s isEqualToString:@"info"]) {
                                alertStyle = Info;
                                defaultTitle = @"FYI BTW";
                            }
                        }

                        SCLAlertView *alert = [[SCLAlertView alloc] init];
                        [alert showTitle:rootViewController
                                   title:[responseOptions objectForKey:@"title"] ? [responseOptions objectForKey:@"title"] : defaultTitle
                                subTitle:[responseOptions objectForKey:@"text"]
                                   style:alertStyle
                        closeButtonTitle:[responseOptions objectForKey:@"doneText"] ? [responseOptions objectForKey:@"doneText"] : @"Done!"
                                duration:[responseOptions objectForKey:@"duration"] ? [[responseOptions objectForKey:@"duration"] floatValue] : 0.0f];
                    });

                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    [voiceRecognitionView cancelButtonPress:nil];

                    if ([responseOptions objectForKey:@"reListen"]  && [[responseOptions objectForKey:@"reListen"] boolValue]) {
                        // reactivate listening
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            [homePageController voiceButtonPressed];
                        });
                    }
                });

            }
        }];
    }
}

%end

%hook GMORootViewController
// keep reference to GMORootViewController
- (id)init
{
    rootViewController = %orig;
    return rootViewController;
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

%hook GMOHomePageController
// keep a reference to the latest GMOHomePageController
-(id)initWithNibName:(id)arg1 bundle:(id)arg2
{
    homePageController = %orig;
    return homePageController;
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