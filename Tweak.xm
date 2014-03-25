


#import "GoogleHeaders/GMOEcoutezController.h"
#import "GoogleHeaders/GMOSearchPaneController.h"
#import <iOS7/PrivateFrameworks/AppSupport/CPDistributedMessagingCenter.h>
#import <RocketBootstrap/rocketbootstrap.h>

static NSNumber *kSiri = [NSNumber numberWithInteger: 0];
static NSNumber *kGoogle = [NSNumber numberWithInteger: 1];
static NSNumber *kWebserver = [NSNumber numberWithInteger: 2];


static NSMutableArray *intelligentRoutingCommands = [[NSMutableArray alloc] initWithObjects:@"remind me ",
                                                                                @"set a reminder ",
                                                                                @"open ",
                                                                                @"wake me up ",
                                                                                @"set an alarm ",
                                                                                @"set a timer ",
                                                                                @"email ",
                                                                                @"check email",
                                                                                @"check my email",
                                                                                @"text ",
                                                                                @"tell ",
                                                                                @"ask ",
                                                                                @"new text",
                                                                                @"send a message ",
                                                                                @"send a text ",
                                                                                @"read my ",
                                                                                @"play ",
                                                                                @"note",
                                                                                @"call ",
                                                                                @"FaceTime ",
                                                                                @"face time ",
                                                                                @"post on Facebook ",
                                                                                @"post on face book ",
                                                                                @"post on Twitter ",
                                                                                @"post on twitter ",
                                                                                @"tweet",
                                                                                @"what's the weather in ",
                                                                                @"how cold will ",
                                                                                @"will it rain ",
                                                                                @"what's the chance of ",
                                                                                @"how cold is it",
                                                                                @"is it warm ",
                                                                                @"is it hot ",
                                                                                @"is it cold ",
                                                                                @"weather",
                                                                                @"what's the weather",
                                                                                @"give me directions to ",
                                                                                @"get me directons to ",
                                                                                @"find directions for ",
                                                                                @"directions for ",
                                                                                @"directions to ",
                                                                                @"drive me ",
                                                                                @"get directions to ",
                                                                                @"get directions for ",
                                                                                @"navigate to ",
                                                                                @"navigate me to ",
                                                                                nil];
//TODO: look at how Google parses the returned data
static NSString *latestQuery = @"test";
static BOOL globalEnable = YES;
// addr
static NSMutableString *webserverAddress;
// default handler for queries
static NSNumber *defaultHandler;
// whether or not Googiri should route obvious system commands to Siri sans the 'Siri' keyword
static BOOL intelligentRouting = YES;
static NSArray *names;





#define PrefPath @"/var/mobile/Library/Preferences/com.mattcmultimedia.googirisettings.plist"

static void googiriOpenQueryInSiri() {

    CPDistributedMessagingCenter *messagingCenter = [%c(CPDistributedMessagingCenter) centerNamed:@"com.mattcmultimedia.googirisiriactivator"];
    rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
    [messagingCenter sendMessageName:@"googiriActivateSiriWithQuery" userInfo:[NSDictionary dictionaryWithObject:latestQuery forKey:@"query"]];

}

static void googiriUpdatePreferences() {
    //NSLog(@"GOOGIRI PREFS LOADED");
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PrefPath];
    ////NSLog(@"prefs: %@", prefs);
    //NSLog(@"%@", PrefPath);
    if(prefs == nil || !prefs) {
        //options for settings
        // NSLog(@"PREFS ARE NULL :(");
        globalEnable = YES;
        defaultHandler = kGoogle;
        intelligentRouting = YES;
        webserverAddress = nil;

    } else {

        id temp;
        temp = [prefs valueForKey:@"globalEnable"];
        globalEnable = temp ? [temp boolValue] : YES;

        temp = [prefs valueForKey:@"defaultHandler"];
        defaultHandler = temp ? [NSNumber numberWithInteger:[temp intValue]] : kGoogle;

        temp = [prefs valueForKey:@"intelligentRouting"];
        intelligentRouting = temp ? [temp boolValue] : YES;

        temp = [prefs valueForKey:@"webserverAddress"];
        webserverAddress = temp ? [(NSString *)temp mutableCopy] : nil;

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
                    if (![names[h] containsObject:[[justNamesArray objectAtIndex:i] stringByAppendingString:@" "]]) {
                        // add a space because string parsing
                        [names[h] addObject:[[justNamesArray objectAtIndex:i] stringByAppendingString:@" "]];
                    }
                }
                // [justNamesArray release];
            }
        }

    }
    // NSLog(@"%@", defaultHandler);
    // NSLog(@"%@", intelligentRouting?@"YES":@"NO");
    // NSLog(@"%@", webserverAddress);
    // NSLog(@"%@", names);

}


%hook GMOEcoutezController

-(void)completeRecognitionWithResult:(id)result
{
    // %log;
    if (!globalEnable) {
        %orig;
        return;
    }

    // NSLog(@"%@", defaultHandler);

    // we want to use the defaultHandler to handle the event, unless it should be
    // -> overridden by another handler's name or intelligentRouting

    NSArray *otherHandlers = [[NSArray alloc] initWithObjects:kSiri, kGoogle, kWebserver, nil];

    for (int i = 0; i < [otherHandlers count]; ++i)
    {
        // for each other handler, check for names in the query
        // if the name exists, yay, route and be done with it
        for (int n = 0; n < [[names objectAtIndex:[[otherHandlers objectAtIndex:i] intValue]] count]; ++n)
        {
            if ([result rangeOfString:[[names objectAtIndex:[[otherHandlers objectAtIndex:i] intValue]] objectAtIndex:n]].location == 0) {
                result = [result stringByReplacingOccurrencesOfString:[[names objectAtIndex:[[otherHandlers objectAtIndex:i] intValue]] objectAtIndex:n] withString:@""];

                if ([[otherHandlers objectAtIndex:i] intValue] == [kSiri intValue]) {
                    // NSLog(@"FOUND SIRI QUERY");
                    latestQuery = result;
                    googiriOpenQueryInSiri();
                    [self cancelVoiceSearch];
                } else if ([[otherHandlers objectAtIndex:i] intValue] == [kGoogle intValue]) {
                    // NSLog(@"FOUND GOOGLE QUERY");
                    %orig;
                } else if ([[otherHandlers objectAtIndex:i] intValue] == [kWebserver intValue]) {
                    // is webserver
                    // post stuff
                    // NSLog(@"test");
                    // NSLog(@"WOULD POST %@", [webserverAddress stringByAddingPercentEscapesUsingEncoding: NSASCIIStringEncoding]);
                    if ((webserverAddress != nil) && ![webserverAddress isEqualToString:@""]) {
                        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[webserverAddress stringByAppendingString:[result stringByAddingPercentEscapesUsingEncoding: NSASCIIStringEncoding]]]
                                                                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                                           timeoutInterval:10];

                        [request setHTTPMethod: @"GET"];

                        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
                        [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:nil];
                    }
                    [self cancelVoiceSearch];
                }
                return;
            }
        }
    }

    // if handler is google or webserver, check for system commands
    if (intelligentRouting && (([defaultHandler intValue] == [kGoogle intValue]) || ([defaultHandler intValue] == [kWebserver intValue]))) {
        // NSLog(@"ATTEMPTING INTELLIGENT ROUTING");
        for (int i = 0; i < [intelligentRoutingCommands count]; ++i)
        {
            if ([result rangeOfString:[intelligentRoutingCommands objectAtIndex:i]].location == 0) {
                // yay, route to siri
                latestQuery = result;
                googiriOpenQueryInSiri();
                [self cancelVoiceSearch];
                return;
            }
        }
    }

    // nothing special, use default
    if ([defaultHandler intValue] == [kSiri intValue]) {
        // NSLog(@"FOUND NORMAL SIRI QUERY");
        // NSLog(@"%i", [defaultHandler intValue]);
        latestQuery = result;
        googiriOpenQueryInSiri();
        [self cancelVoiceSearch];
    } else if ([defaultHandler intValue] == [kGoogle intValue]) {
        // NSLog(@"FOUND NORMAL GOOGLE QUERY");
        %orig;
    } else if ([defaultHandler intValue] == [kWebserver intValue]) {
        // is webserver
        // post stuff
        if ((webserverAddress != nil) && ![webserverAddress isEqualToString:@""]) {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[webserverAddress stringByAppendingString:[result stringByAddingPercentEscapesUsingEncoding: NSASCIIStringEncoding]]]
                                                                   cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                               timeoutInterval:10];

            [request setHTTPMethod: @"GET"];

            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:nil];

        }
        [self cancelVoiceSearch];
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