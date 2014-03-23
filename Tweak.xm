


#import "GoogleHeaders/GMOEcoutezController.h"
#import "GoogleHeaders/GMOSearchPaneController.h"
#import <iOS7/PrivateFrameworks/AppSupport/CPDistributedMessagingCenter.h>
#import <RocketBootstrap/rocketbootstrap.h>


typedef enum Handler : NSUInteger {
    kSiri,
    kGoogle,
    kWebserver
} Handler;


static NSMutableArray *intelligentRoutingCommands = [[NSMutableArray alloc] initWithObjects:@"remind me to ",
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
// static NSString *latestQuery = @"test";
static BOOL globalEnable = YES;

// default handler for queries
static NSUInteger defaultHandler = kSiri;
// whether or not Googiri should route obvious system commands to Siri sans the 'Siri' keyword
static BOOL intelligentRouting = YES;
static NSArray *names;





#define PrefPath @"/var/mobile/Library/Preferences/com.mattcmultimedia.googirisettings.plist"

// static void googiriOpenQueryInSiri() {

//     CPDistributedMessagingCenter *messagingCenter = [%c(CPDistributedMessagingCenter) centerNamed:@"com.mattcmultimedia.googirisiriactivator"];
//     rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
//     [messagingCenter sendMessageName:@"googiriActivateSiriWithQuery" userInfo:[NSDictionary dictionaryWithObject:latestQuery forKey:@"query"]];

// }

static void googiriUpdatePreferences() {
    //NSLog(@"GOOGIRI PREFS LOADED");
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PrefPath];
    ////NSLog(@"prefs: %@", prefs);
    //NSLog(@"%@", PrefPath);
    if(prefs == NULL || !prefs) {
        //options for settings
        //NSLog(@"PREFS ARE NULL :(");
        globalEnable = YES;
        defaultHandler = kSiri;
        intelligentRouting = YES;

    } else {

        id temp;
        NSMutableString *tempStr;
        temp = [prefs valueForKey:@"globalEnable"];
        globalEnable = temp ? [temp boolValue] : YES;

        temp = [prefs valueForKey:@"defaultHandler"];
        defaultHandler = temp ? [temp intValue] : 0;

        temp = [prefs valueForKey:@"intelligentRouting"];
        intelligentRouting = temp ? [temp boolValue] : YES;

        for (int h = 0; h < 3; ++h)
        {
            // look for key 0Names, 1Names, 2Names
            temp = [prefs valueForKey:[NSString stringWithFormat:@"%iNames", h]];
            tempStr = temp ? (NSMutableString *)temp : nil;

            if (tempStr != nil && names[h] != NULL) {
                //create the array of names. Separate on the space and then append a space to each and then add to array
                NSArray *justNamesArray = [tempStr componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                justNamesArray = [justNamesArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
                for (unsigned int i = 0; i < [justNamesArray count]; ++i)
                {
                    // add a space because string parsing
                    [names[h] addObject:[[justNamesArray objectAtIndex:i] stringByAppendingString:@" "]];
                }
                [justNamesArray release];
            }
        }

    }

    NSLog(@"PAY ATTENTION TO ME");
    NSLog(@"%@", names);
}


// %hook GMOEcoutezController

// -(void)completeRecognitionWithResult:(id)result
// {
//     // %log;
//     // NSLog(@"enable:%i, allToSiri:%i", globalEnable, sendEverythingToSiri);
//     if (!globalEnable) {
//         //NSLog(@"GLOBAL ENABLE OFF. USE NORMAL");
//         %orig;
//         return;
//     }
//     if (useSiriForSystemFunctions) {
//         //find a prefix - if founc, pipe to siri without replacing text
//         BOOL siriSystemCommandPrefixFound = NO;
//         for (unsigned int i = 0; i < [intelligentRoutingCommands count]; ++i)
//         {
//             NSString *prefixString = [intelligentRoutingCommands objectAtIndex:i];
//             NSRange prefix = [result rangeOfString:prefixString];
//             if (prefix.location == 0) {
//                 //NSLog(@"prefix %@", NSStringFromRange(prefix));
//                 //NSLog(@"^^^ %@", prefixString);

//                 //NSString *normalResult = [[result stringByReplacingOccurrencesOfString:prefixString withString:@""] mutableCopy];
//                 //result = normalResult;

//                 siriSystemCommandPrefixFound = YES;
//                 break;

//             }
//         }
//         //if we didn't find one yet, try looking though the customsystemCommands array
//         if (!siriSystemCommandPrefixFound) {

//             for (unsigned int i = 0; i < [alternativeSystemCommandsArray count]; ++i)
//             {
//                 NSString *prefixString = [alternativeSystemCommandsArray objectAtIndex:i];
//                 NSRange prefix = [result rangeOfString:prefixString];
//                 if (prefix.location == 0) {
//                     //NSLog(@"prefix %@", NSStringFromRange(prefix));
//                     //NSLog(@"^^^ %@", prefixString);

//                     //NSString *normalResult = [[result stringByReplacingOccurrencesOfString:prefixString withString:@""] mutableCopy];
//                     //result = normalResult;

//                     siriSystemCommandPrefixFound = YES;
//                     break;

//                 }
//             }
//         }

//         if (siriSystemCommandPrefixFound) {
//             //if we found the prefix, open in siri, else just continue
//             latestQuery = result;
//             googiriOpenQueryInSiri();
//             [self cancelVoiceSearch];
//             return;
//         }

//     }

//     if (sendEverythingToSiri) {
//         // NSLog(@"SENDING RESULT STRAIGHT TO SIRI");
//         BOOL googlePrefixMatchWasFound = NO;
//         //GOOGLE
//         for (unsigned int i = 0; i < [forceToGoogleArray count]; ++i)
//         {
//             NSString *prefixString = [forceToGoogleArray objectAtIndex:i];
//             NSRange prefix = [result rangeOfString:prefixString];
//             if (prefix.location == 0) {
//                 //NSLog(@"prefix %@", NSStringFromRange(prefix));
//                 //NSLog(@"^^^ %@", prefixString);

//                 NSString *normalResult = [[result stringByReplacingOccurrencesOfString:prefixString withString:@""] mutableCopy];
//                 result = normalResult;
//                 //latestQuery = result;
//                 googlePrefixMatchWasFound = YES;
//                 break;

//             }
//         }
//         //remove alternative names if any are set
//         if (alternativeNamesForSiri != nil || alternativeNamesForSiriArray != NULL) {
//             // NSLog(@"looking for alt names");
//             // NSLog(@"%@", alternativeNamesForSiriArray);
//             for (unsigned int i = 0; i < [alternativeNamesForSiriArray count]; ++i)
//             {
//                 NSString *prefixString = [alternativeNamesForSiriArray objectAtIndex:i];
//                 NSRange prefix = [result rangeOfString:prefixString];
//                 if (prefix.location == 0) {
//                     //NSLog(@"prefix %@", NSStringFromRange(prefix));
//                     //NSLog(@"^^^ %@", prefixString);

//                     NSString *normalResult = [[result stringByReplacingOccurrencesOfString:prefixString withString:@""] mutableCopy];
//                     result = normalResult;
//                     break;

//                 }
//             }
//         }
//         if (!googlePrefixMatchWasFound) {
//             latestQuery = result;
//             googiriOpenQueryInSiri();
//             [self cancelVoiceSearch];
//             return;
//         } else {
//             //if the match was found, just open it in google
//             %orig;
//             return;
//         }

//     } else {
//         //else if we should only send to siri if explicitly

//         BOOL googlePrefixMatchWasFound = NO;
//         //GOOGLE
//         for (unsigned int i = 0; i < [forceToGoogleArray count]; ++i)
//         {
//             NSString *prefixString = [forceToGoogleArray objectAtIndex:i];
//             NSRange prefix = [result rangeOfString:prefixString];
//             if (prefix.location == 0) {
//                 //NSLog(@"prefix %@", NSStringFromRange(prefix));
//                 //NSLog(@"^^^ %@", prefixString);

//                 NSString *normalResult = [[result stringByReplacingOccurrencesOfString:prefixString withString:@""] mutableCopy];
//                 result = normalResult;
//                 latestQuery = result;
//                 googlePrefixMatchWasFound = YES;
//                 break;

//             }
//         }

//         //SIRI
//         BOOL siriPrefixMatchWasFound = NO;

//         if (!googlePrefixMatchWasFound) {
//             for (unsigned int i = 0; i < [forceToSiriArray count]; ++i)
//             {
//                 NSString *prefixString = [forceToSiriArray objectAtIndex:i];
//                 NSRange prefix = [result rangeOfString:prefixString];
//                 if (prefix.location == 0) {
//                     //NSLog(@"prefix %@", NSStringFromRange(prefix));
//                     //NSLog(@"^^^ %@", prefixString);

//                     NSString *normalResult = [[result stringByReplacingOccurrencesOfString:prefixString withString:@""] mutableCopy];
//                     result = normalResult;
//                     latestQuery = result;
//                     siriPrefixMatchWasFound = YES;
//                     break;

//                 }
//             }
//             //remove alternative names if any are set
//             if (alternativeNamesForSiri != nil || alternativeNamesForSiriArray != NULL) {
//                 // NSLog(@"looking for alt names");
//                 // NSLog(@"%@", alternativeNamesForSiriArray);
//                 for (unsigned int i = 0; i < [alternativeNamesForSiriArray count]; ++i)
//                 {
//                     NSString *prefixString = [alternativeNamesForSiriArray objectAtIndex:i];
//                     NSRange prefix = [result rangeOfString:prefixString];
//                     if (prefix.location == 0) {
//                         //NSLog(@"prefix %@", NSStringFromRange(prefix));
//                         //NSLog(@"^^^ %@", prefixString);

//                         NSString *normalResult = [[result stringByReplacingOccurrencesOfString:prefixString withString:@""] mutableCopy];
//                         result = normalResult;
//                         latestQuery = result;
//                         siriPrefixMatchWasFound = YES;
//                         break;

//                     }
//                 }
//             }
//         }


//         if (siriPrefixMatchWasFound) {
//             googiriOpenQueryInSiri();
//             [self cancelVoiceSearch];
//             return;
//         }
//     }
//     %orig;
//     return;
// }

// %end


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
                                                   @"Siri",
                                                   @"siri",
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
                                                   @"Jeeves ",
                                                   nil],
           nil
       ];


    CFNotificationCenterRef reload = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(reload, NULL, &reloadPrefsNotification,
                    CFSTR("com.mattcmultimedia.googirisettings/reload"), NULL, 0);
    googiriUpdatePreferences();
    [pool release];
}