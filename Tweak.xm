




#import <Google/GMOEcoutezController.h>
#import <Google/GMOSearchPaneController.h>
//#import <Google/GMOVoiceSpeakerButtonFlipContainer.h>

#import <AppSupport/CPDistributedMessagingCenter.h>





static NSArray *forceToSiriArray = [[NSArray alloc] initWithObjects:@"Siri ", @"hey Siri ", @"is Siri ", @"siri ", @"hey siri ", @"is siri ",@"Siri", @"siri", nil];
static NSArray *forceToGoogleArray = [[NSArray alloc] initWithObjects:@"Google ", @"hey Google ",@"search for ", @"search ", @"Google for ", @"Google search for ", @"Google search ", @"google ", @"hey google ",@"search for ", @"search ", @"google for ", @"google search for ", @"google search ", nil];
static NSMutableArray *systemFunctionsCommandPrefixes = [[NSMutableArray alloc] initWithObjects:@"remind me to ",
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
                                                                                nil];
//TODO: look at how Google parses the returned data
static GMOSearchPaneController *spController;
static NSString *latestQuery = @"test";
static UIButton *speakerButton = nil;
static BOOL shouldSilenceNextAudioReading = NO;
static BOOL globalEnable = YES;
static BOOL sendEverythingToSiri = NO;
static BOOL useSiriForSystemFunctions = YES;
static NSString *alternativeNamesForSiri = nil;
static NSMutableArray *alternativeNamesForSiriArray = nil;
static NSString *alternativeSystemCommands = nil;
static NSMutableArray *alternativeSystemCommandsArray = nil;
static BOOL systemCommandNavigation = NO;
static BOOL systemCommandWeather = NO;


#define PrefPath @"/var/mobile/Library/Preferences/com.mattcmultimedia.googirisettings.plist"

static void googiriOpenQueryInSiri() {
    //NSLog(@"googiriOpenQueryInSiri: %@", latestQuery);
    CPDistributedMessagingCenter *messagingCenter;
    messagingCenter = [%c(CPDistributedMessagingCenter) centerNamed:@"com.mattcmultimedia.googirisiriactivator"];

    // One-way (message only)
    [messagingCenter sendMessageName:@"googiriActivateSiriWithQuery" userInfo:[NSDictionary dictionaryWithObject:latestQuery forKey:@"query"]/* optional dictionary. in this example it will be ignored. */];
    shouldSilenceNextAudioReading = YES;

}

static void googiriUpdatePreferences() {
    //NSLog(@"GOOGIRI PREFS LOADED");
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PrefPath];
    ////NSLog(@"prefs: %@", prefs);
    //NSLog(@"%@", PrefPath);
    if(prefs == NULL || !prefs) {
        //options for settings
        //NSLog(@"PREFS ARE NULL :(");
        globalEnable = YES;
        sendEverythingToSiri = NO;
        useSiriForSystemFunctions = YES;
        alternativeNamesForSiri = nil;
        systemCommandNavigation = NO;
        systemCommandWeather = NO;

    } else {

        //NSLog(@"begin loading booleans");


        id temp;
        temp = [prefs valueForKey:@"globalEnable"];
        globalEnable = temp ? [temp boolValue] : YES;

        temp = [prefs valueForKey:@"sendEverythingToSiri"];
        sendEverythingToSiri = temp ? [temp boolValue] : NO;

        temp = [prefs valueForKey:@"useSiriForSystemFunctions"];
        useSiriForSystemFunctions = temp ? [temp boolValue] : YES;

        temp = [prefs valueForKey:@"alternativeNamesForSiri"];
        alternativeNamesForSiri = temp ? (NSMutableString *)temp : nil;

        if (alternativeNamesForSiri != nil || alternativeNamesForSiriArray != NULL) {
            //create the array of names. Separate on the space and then append a space to each and then add to array
            NSArray *justNamesArray = [alternativeNamesForSiri componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            justNamesArray = [justNamesArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
            alternativeNamesForSiriArray = [[NSMutableArray alloc] init];
            [alternativeNamesForSiriArray addObjectsFromArray:justNamesArray];
            for (unsigned int i = 0; i < [justNamesArray count]; ++i)
            {
                [alternativeNamesForSiriArray replaceObjectAtIndex:i withObject:[[justNamesArray objectAtIndex:i] stringByAppendingString:@" "]];
            }

            //NSLog(@"%@", alternativeNamesForSiriArray);
        }

        temp = [prefs valueForKey:@"alternativeSystemCommands"];
        alternativeSystemCommands = temp ? (NSMutableString *)temp : nil;

        if (alternativeSystemCommands != nil || alternativeSystemCommandsArray != NULL) {
            //create the array of names. Separate on the space and then append a space to each and then add to array
            //NSLog(@"%@", alternativeSystemCommands);
            // NSMutableCharacterSet *charactersToRemove = [NSMutableCharacterSet alphanumericCharacterSet];
            // [charactersToRemove addCharactersInString:@","];
            // NSLog(@"charactersToRemove: %@", charactersToRemove);
            NSArray *justCommandsArray = [alternativeSystemCommands componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
            //NSLog(@"justCommandsArray: %@", justCommandsArray);
            justCommandsArray = [justCommandsArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
            //NSLog(@"justCommandsArray: %@", justCommandsArray);
            alternativeSystemCommandsArray = [[NSMutableArray alloc] init];
            [alternativeSystemCommandsArray addObjectsFromArray:justCommandsArray];
            for (unsigned int i = 0; i < [justCommandsArray count]; ++i)
            {
                [alternativeSystemCommandsArray replaceObjectAtIndex:i withObject:[[justCommandsArray objectAtIndex:i] stringByAppendingString:@" "]];
            }

            //NSLog(@"%@", alternativeSystemCommandsArray);
        }

        //SPECIFIC COMMANDS NAVIGATION
        temp = [prefs valueForKey:@"systemCommandNavigation"];
        systemCommandNavigation = temp ? [temp boolValue] : NO;

        NSArray *systemCommandNavigationArray = [[NSArray alloc] initWithObjects:@"give me directions to ",
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
        if (systemCommandNavigation) {
            //add navigation commands to the systemCommands array
            for (unsigned int i = 0; i < [systemCommandNavigationArray count]; ++i)
            {
                //if array doesn't already contain the object, add it
                if (![systemFunctionsCommandPrefixes containsObject:[systemCommandNavigationArray objectAtIndex:i]]){
                    [systemFunctionsCommandPrefixes addObject:[systemCommandNavigationArray objectAtIndex:i]];
                }
            }
        } else {
            //remove them
            for (unsigned int i = 0; i < [systemCommandNavigationArray count]; ++i)
            {
                //if array doesn't already contain the object, add it
                if ([systemFunctionsCommandPrefixes containsObject:[systemCommandNavigationArray objectAtIndex:i]]){
                    [systemFunctionsCommandPrefixes removeObject:[systemCommandNavigationArray objectAtIndex:i]];
                }
            }
        }
        [systemCommandNavigationArray release];

        //SPECIFIC COMMANDS WEATHER

        temp = [prefs valueForKey:@"systemCommandWeather"];
        systemCommandWeather = temp ? [temp boolValue] : NO;

        NSArray *systemCommandWeatherArray = [[NSArray alloc] initWithObjects:@"what's the weather in ",
                                                                                @"how cold will ",
                                                                                @"will it rain ",
                                                                                @"what's the chance of ",
                                                                                @"how cold is it",
                                                                                @"is it warm ",
                                                                                @"is it hot ",
                                                                                @"is it cold ",
                                                                                @"weather",
                                                                                @"what's the weather",
                                                                                nil];
        if (systemCommandWeather) {
            //add navigation commands to the systemCommands array
            for (unsigned int i = 0; i < [systemCommandWeatherArray count]; ++i)
            {
                //if array doesn't already contain the object, add it
                if (![systemFunctionsCommandPrefixes containsObject:[systemCommandWeatherArray objectAtIndex:i]]){
                    [systemFunctionsCommandPrefixes addObject:[systemCommandWeatherArray objectAtIndex:i]];
                }
            }
        } else {
            //remove them
            for (unsigned int i = 0; i < [systemCommandWeatherArray count]; ++i)
            {
                //if array doesn't already contain the object, add it
                if ([systemFunctionsCommandPrefixes containsObject:[systemCommandWeatherArray objectAtIndex:i]]){
                    [systemFunctionsCommandPrefixes removeObject:[systemCommandWeatherArray objectAtIndex:i]];
                }
            }
        }
        [systemCommandWeatherArray release];
        //NSLog(@"%@", prefs);
    }
}


%hook GMOEcoutezController

-(void)completeRecognitionWithResult:(id)result
{
    //%log;
    //NSLog(@"enable:%i, allToSiri:%i", globalEnable, sendEverythingToSiri);
    if (!globalEnable) {
        //NSLog(@"GLOBAL ENABLE OFF. USE NORMAL");
        %orig;
        return;
    }
    if (useSiriForSystemFunctions) {
        //find a prefix - if founc, pipe to siri without replacing text
        BOOL siriSystemCommandPrefixFound = NO;
        for (unsigned int i = 0; i < [systemFunctionsCommandPrefixes count]; ++i)
        {
            NSString *prefixString = [systemFunctionsCommandPrefixes objectAtIndex:i];
            NSRange prefix = [result rangeOfString:prefixString];
            if (prefix.location == 0) {
                //NSLog(@"prefix %@", NSStringFromRange(prefix));
                //NSLog(@"^^^ %@", prefixString);

                //NSString *normalResult = [[result stringByReplacingOccurrencesOfString:prefixString withString:@""] mutableCopy];
                //result = normalResult;

                siriSystemCommandPrefixFound = YES;
                break;

            }
        }
        //if we didn't find one yet, try looking though the customsystemCommands array
        if (!siriSystemCommandPrefixFound) {

            for (unsigned int i = 0; i < [alternativeSystemCommandsArray count]; ++i)
            {
                NSString *prefixString = [alternativeSystemCommandsArray objectAtIndex:i];
                NSRange prefix = [result rangeOfString:prefixString];
                if (prefix.location == 0) {
                    //NSLog(@"prefix %@", NSStringFromRange(prefix));
                    //NSLog(@"^^^ %@", prefixString);

                    //NSString *normalResult = [[result stringByReplacingOccurrencesOfString:prefixString withString:@""] mutableCopy];
                    //result = normalResult;

                    siriSystemCommandPrefixFound = YES;
                    break;

                }
            }
        }

        if (siriSystemCommandPrefixFound) {
            //if we found the prefix, open in siri, else just continue
            latestQuery = result;
            googiriOpenQueryInSiri();
            return;
        }

    }

    if (sendEverythingToSiri) {
        //NSLog(@"SENDING RESULT STRAIGHT TO SIRI");
        BOOL googlePrefixMatchWasFound = NO;
        //GOOGLE
        for (unsigned int i = 0; i < [forceToGoogleArray count]; ++i)
        {
            NSString *prefixString = [forceToGoogleArray objectAtIndex:i];
            NSRange prefix = [result rangeOfString:prefixString];
            if (prefix.location == 0) {
                //NSLog(@"prefix %@", NSStringFromRange(prefix));
                //NSLog(@"^^^ %@", prefixString);

                NSString *normalResult = [[result stringByReplacingOccurrencesOfString:prefixString withString:@""] mutableCopy];
                result = normalResult;
                //latestQuery = result;
                googlePrefixMatchWasFound = YES;
                break;

            }
        }
        //remove alternative names if any are set
        if (alternativeNamesForSiri != nil || alternativeNamesForSiriArray != NULL) {
            NSLog(@"looking for alt names");
            NSLog(@"%@", alternativeNamesForSiriArray);
            for (unsigned int i = 0; i < [alternativeNamesForSiriArray count]; ++i)
            {
                NSString *prefixString = [alternativeNamesForSiriArray objectAtIndex:i];
                NSRange prefix = [result rangeOfString:prefixString];
                if (prefix.location == 0) {
                    //NSLog(@"prefix %@", NSStringFromRange(prefix));
                    //NSLog(@"^^^ %@", prefixString);

                    NSString *normalResult = [[result stringByReplacingOccurrencesOfString:prefixString withString:@""] mutableCopy];
                    result = normalResult;
                    break;

                }
            }
        }
        if (!googlePrefixMatchWasFound) {
            latestQuery = result;
            googiriOpenQueryInSiri();
            return;
        } else {
            //if the match was found, just open it in google
            %orig;
            return;
        }

    } else {
        //else if we should only send to siri if explicitly

        BOOL googlePrefixMatchWasFound = NO;
        //GOOGLE
        for (unsigned int i = 0; i < [forceToGoogleArray count]; ++i)
        {
            NSString *prefixString = [forceToGoogleArray objectAtIndex:i];
            NSRange prefix = [result rangeOfString:prefixString];
            if (prefix.location == 0) {
                //NSLog(@"prefix %@", NSStringFromRange(prefix));
                //NSLog(@"^^^ %@", prefixString);

                NSString *normalResult = [[result stringByReplacingOccurrencesOfString:prefixString withString:@""] mutableCopy];
                result = normalResult;
                latestQuery = result;
                googlePrefixMatchWasFound = YES;
                break;

            }
        }

        //SIRI
        BOOL siriPrefixMatchWasFound = NO;

        if (!googlePrefixMatchWasFound) {
            for (unsigned int i = 0; i < [forceToSiriArray count]; ++i)
            {
                NSString *prefixString = [forceToSiriArray objectAtIndex:i];
                NSRange prefix = [result rangeOfString:prefixString];
                if (prefix.location == 0) {
                    //NSLog(@"prefix %@", NSStringFromRange(prefix));
                    //NSLog(@"^^^ %@", prefixString);

                    NSString *normalResult = [[result stringByReplacingOccurrencesOfString:prefixString withString:@""] mutableCopy];
                    result = normalResult;
                    latestQuery = result;
                    siriPrefixMatchWasFound = YES;
                    break;

                }
            }
            //remove alternative names if any are set
            if (alternativeNamesForSiri != nil || alternativeNamesForSiriArray != NULL) {
                NSLog(@"looking for alt names");
                NSLog(@"%@", alternativeNamesForSiriArray);
                for (unsigned int i = 0; i < [alternativeNamesForSiriArray count]; ++i)
                {
                    NSString *prefixString = [alternativeNamesForSiriArray objectAtIndex:i];
                    NSRange prefix = [result rangeOfString:prefixString];
                    if (prefix.location == 0) {
                        //NSLog(@"prefix %@", NSStringFromRange(prefix));
                        //NSLog(@"^^^ %@", prefixString);

                        NSString *normalResult = [[result stringByReplacingOccurrencesOfString:prefixString withString:@""] mutableCopy];
                        result = normalResult;
                        latestQuery = result;
                        siriPrefixMatchWasFound = YES;
                        break;

                    }
                }
            }
        }


        //kGMOPrefTextToSpeech
        //the result is a string of the text that is googled
        //possibly search this for keywords and then pipe to SIRI, but that's sub par
        //audio only goes off if it's something dynamic, so It'd be better to see if audio is played after this, and if it isn't, pipe through siri

        // GMOVoiceSpeakerButtonFlipContainer *speakerContainer = (GMOVoiceSpeakerButtonFlipContainer *)[spController currentVoiceSpeakerButtonContainer];
        // UIButton *speakerButton = MSHookIvar<UIButton *>(speakerContainer, "_speakerButton");
        // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"test"
        //     message:[NSString stringWithFormat:@"%@", speakerButton]
        //     delegate:nil
        //     cancelButtonTitle:@"K"
        //     otherButtonTitles:nil];
        // [alert show];
        // [alert release];


        if (siriPrefixMatchWasFound) {
            googiriOpenQueryInSiri();
            return;
        }
    }
    %orig;
    return;
}

%end


%hook GMOSearchPaneController

-(id)initWithPaneManager:(id)paneManager headerController:(id)controller instantWebView:(id)view locationManager:(id)manager
{
    spController = self;
    %log;
    return %orig;
}

-(id)initWithFrame:(CGRect)frame voiceButton:(id)button speakerButton:(id)button3
{
    if ((self = %orig) != nil) {
        speakerButton = button3;
    }

    return self;

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


    CFNotificationCenterRef reload = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(reload, NULL, &reloadPrefsNotification,
                    CFSTR("com.mattcmultimedia.googirisettings/reload"), NULL, 0);
    googiriUpdatePreferences();
    [pool release];
}