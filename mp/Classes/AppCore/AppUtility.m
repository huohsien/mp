//
//  AppUtility.m
//  mp
//
//  Created by M Tsai on 11-9-7.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "AppUtility.h"

#import <MessageUI/MFMessageComposeViewController.h>


#import "mpAppDelegate.h"
#import "TabBarFacade.h"
#import "MPContactManager.h"

#import "MPFoundation.h"
#import "TTContainerViewController.h"
#import "CDChat.h"
#import "ChatDialogController.h"

#import "AppUpdateView.h"
#import "ProgressOverlayView.h"


// define queue names
//
NSString* const kMPQueueMainThread = @"com.apple.main-thread";
NSString* const kMPQueueBackgroundMOC = @"com.terntek.mp.background_moc";
NSString* const kMPQueueNetwork = @"com.terntek.mp.network";


// downloadable files
//
NSString* const kMPFileTellFriendEmail = @"tell_friend_email";
NSString* const kMPFileTellFriendSMS = @"tell_friend_sms";
NSString* const kMPFileTellFriendFree = @"tell_friend_free";



NSString* const kFontFrutiger = @"frutiger";



@implementation AppUtility



#pragma mark - System and App

/*!
 @abstract gets device model information
 
 Use:
 - login, ipquery and msisdn verification
 
 */
+ (NSString *)getDeviceModel {
    
    return [NSString stringWithFormat:@"ios-%@-apple-%@", [[UIDevice currentDevice] systemVersion], [[UIDevice currentDevice] modelDetailedName] ];
}

/*!
 @abstract gets app version number
 
 Use:
 - login and msisdn verification
 
 */
+ (NSString *)getAppVersion {
    
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}


/*!
 @abstract get unique identifier compatible for M+ services
 */
+ (NSString *)getIMEI {
    
    // mac usually: 00:26:B0:F0:94:36
    // pad 18 char mac to 24 char
    NSString *mac = [[UIDevice currentDevice] getMACAddress];
    NSString *imei = [mac stringByReplacingOccurrencesOfString:@":" withString:@""];    
    return imei;
}

/*! 
 @abstract gets language setting of device
 @discussion We make an exception for two letter language for Chinese.
 Traditional = zh and Simplifed = cn
 
 @return two letter ISO language code.
 */
+ (NSString *)devicePreferredLanguageCode {
    
    NSString *preferredLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    if ([preferredLanguage isEqualToString:@"zh-Hant"]) {
        preferredLanguage = @"zh";
	}
	// if Simplified ZH
	else if ([preferredLanguage isEqualToString:@"zh-Hans"]) {
        preferredLanguage = @"cn";
	}
    return preferredLanguage;
}

/*! 
 @abstract gets language setting of device for Google services
 @discussion We make an exception for two letter language for Chinese.
 Traditional = zh-TW and Simplifed = zh-CN
 
 Should match language codes here:
 https://spreadsheets.google.com/pub?key=p9pdwsai2hDMsLkXsoM05KQ&gid=1
 
 @return two letter ISO language code.
 */
+ (NSString *)devicePreferredLanguageCodeGoogle {
    
    NSString *preferredLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    if ([preferredLanguage isEqualToString:@"zh-Hant"]) {
        preferredLanguage = @"zh-TW";
	}
	// if Simplified ZH
	else if ([preferredLanguage isEqualToString:@"zh-Hans"]) {
        preferredLanguage = @"zh-CN";
	}
    return preferredLanguage;
}


#pragma mark - AppDelegate


/**
 Returns the app delegate
 
 */
+ (mpAppDelegate *) getAppDelegate {
	mpAppDelegate *appDelegate = (mpAppDelegate *)[[UIApplication sharedApplication] delegate];
	return appDelegate;
}


/*!
 @abstract Sets the badge count for this tab bar item
 
 @discussion setting to zero, hides the badge view completely
 
 @param count           The badge count number
 @param stringCount     Use string instead of int if defined
 @param controllerIndex The index of the tab button to set
 
 */
+ (void) setBadgeCount:(NSUInteger)count stringCount:(NSString *)stringCount controllerIndex:(NSUInteger)controllerIndex {
    
    // run only on main queue
    if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
                
        // protect attributes in netQueue
        //
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            [[AppUtility getAppDelegate].tabBarFacade setBadgeCount:count stringCount:stringCount controllerIndex:controllerIndex];
            
            [pool drain];
        });
        
    }
    else {
        [[AppUtility getAppDelegate].tabBarFacade setBadgeCount:count stringCount:stringCount controllerIndex:controllerIndex];
    }
}

/*!
 @abstract Sets the badge count for this tab bar item
 
 @discussion setting to zero, hides the badge view completely
 
 @param count The badge count number
 @param controllerIndex The index of the tab button to set
 
 */
+ (void) setBadgeCount:(NSUInteger)count controllerIndex:(NSUInteger)controllerIndex {
    
    // run only on main queue
    if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
        
        // protect attributes in netQueue
        //
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            [[AppUtility getAppDelegate].tabBarFacade setBadgeCount:count stringCount:nil controllerIndex:controllerIndex];
            
            [pool drain];
        });
        
    }
    else {
        [[AppUtility getAppDelegate].tabBarFacade setBadgeCount:count stringCount:nil controllerIndex:controllerIndex];
    }
}


/*!
 @abstract Pushes new chat and tranistions to it
 
 Use:
 - start chat from friend list
 
 */
+ (void) pushNewChat:(CDChat *)newChat {
    
    mpAppDelegate *appDelegate = [AppUtility getAppDelegate];

    NSUInteger viewCount = [appDelegate.chatNavigationController.viewControllers count];
    
    // only push on top of root
    // - if there is another chat, don't push another
    // - this can happen if users tap very quickly on the tableview - more of a iOS bug
    //
    if (viewCount != 1) {
        return;
    }
    

    // make sure tab is usable first
    NSUInteger realIndex = [appDelegate.tabBarFacade warmUpTabBarItem:kMPTabIndexChat];
    
    ChatDialogController *newController = [[ChatDialogController alloc] initWithCDChat:newChat];
    
        
    //TabBarItemController *pressedController = [appDelegate.tabBarFacade.tabBarItemControllers objectAtIndex:kMPTabIndexChat];
    //[appDelegate.tabBarFacade pressed:pressedController];
    
    // set default to chat tab item
    [appDelegate.chatNavigationController  pushViewController:newController animated:NO];
    // set delegate to root chat list
    newController.delegate = [[appDelegate.chatNavigationController viewControllers] objectAtIndex:0];
    [newController release];
    
    
    // Get views. controllerIndex is passed in as the controller we want to go to. 
    UIView * fromView = appDelegate.tabBarController.selectedViewController.view;
    UIView * toView = [[appDelegate.tabBarController.viewControllers objectAtIndex:realIndex] view];
    
    
    // Get the size of the view area.
    CGRect viewSize = toView.frame;
    //BOOL scrollRight = realIndex > appDelegate.tabBarController.selectedIndex;
    
    // Add the to view to the tab bar view.
    [fromView.superview addSubview:toView];
    
    
    
    // Position it off screen.
    //toView.frame = CGRectMake((scrollRight ? 320 : -320), viewSize.origin.y, 320, viewSize.size.height);
    // always from the right
    toView.frame = CGRectMake(320.0, viewSize.origin.y, 320, viewSize.size.height);

    appDelegate.tabBarController.tabBar.hidden = YES;
    
    [UIView animateWithDuration:0.3 
                     animations: ^{
                         
                         // Animate the views on and off the screen. This will appear to slide.
                         fromView.frame = CGRectMake(-320.0, viewSize.origin.y, 320, viewSize.size.height);
                         toView.frame = CGRectMake(0, viewSize.origin.y, 320, viewSize.size.height);
                     }
     
                     completion:^(BOOL finished) {
                         if (finished) {
                             
                             // Remove the old view from the tabbar view.
                             [fromView removeFromSuperview];

                             [appDelegate.tabBarFacade pressedIndex:kMPTabIndexChat];
                             //appDelegate.tabBarController.selectedIndex = realIndex;                
                         }
                     }];
    
    
    // Transition using a page curl.
   /* [UIView transitionFromView:fromView 
                        toView:toView 
                      duration:0.5 
                       options:(realIndex > appDelegate.tabBarController.selectedIndex ? UIViewAnimationOptionTransitionFlipFromLeft : UIViewAnimationOptionTransitionFlipFromRight)
                    completion:^(BOOL finished) {
                        if (finished) {
                            appDelegate.tabBarController.selectedIndex = realIndex;
                        }
                    }];
    
    */
    
    
    
    
}

#pragma mark -
#pragma mark Queues and Threads


/*!
 @abstract gets label for current queue
 
 @discussion used to determine which queue
 */
+ (NSString *)currentQueueLabel {
    dispatch_queue_t current_queue = dispatch_get_current_queue();
    NSString *currentLabel = [NSString stringWithUTF8String:dispatch_queue_get_label(current_queue)];
    return currentLabel;
}

+ (BOOL) isMainQueue {
    if ([[AppUtility currentQueueLabel] isEqualToString:kMPQueueMainThread]) {
        return YES;
    }
    return NO;
}

+ (BOOL) isBackgroundMOCQueue {
    if ([[AppUtility currentQueueLabel] isEqualToString:kMPQueueBackgroundMOC]) {
        return YES;
    }
    return NO;
}

/*!
 @abstract gets background moc queue
 
 */
+ (dispatch_queue_t) getBackgroundMOCQueue {
	return [[AppUtility getAppDelegate] background_moc_queue];
}

/*!
 @abstract gets background contact manager
 
 */
+ (MPContactManager *) getBackgroundContactManager {
	return [[AppUtility getAppDelegate] backgroundContactManager];
}


/*!
 @abstract gets background moc queue
 
 */
+ (dispatch_queue_t) getQueueNetwork {
	return [[AppUtility getAppDelegate] network_queue];
}

/*!
 @abstract gets background moc queue
 
 */
+ (MPSocketCenter *) getSocketCenter {
	return [[AppUtility getAppDelegate] socketCenter];
}

#pragma mark -
#pragma mark Core Data Methods

/*!
 @abstract Gets the Managed Object Context for app

 @discussion each thread should get one MOC, no sharing allowed!
 
 */
+ (NSManagedObjectContext *) cdGetManagedObjectContext {
    
    mpAppDelegate *appDelegate = [AppUtility getAppDelegate];
    
    // if main queue
    // - provide main MOC
    //
    if ([AppUtility isMainQueue]){
        return appDelegate.managedObjectContext;
    }
    // for background_moc_queue
    // - use background moc
    //
    else if ([AppUtility isBackgroundMOCQueue]){
        return appDelegate.backManagedObjectContext;
    }
    // otherwise no moc available
    //
    else {
        DDLogVerbose(@"AU-gmoc: ERROR - request MOC for unknown queue!");
        return nil;
    }
}

/**
 Rollback changes to Core Data Persistent Store
 */
+ (void) cdRollBack {
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	[managedObjectContext rollback];
}

/**
 Rollback changes to Core Data Persistent Store
 
 */
+ (void) cdReset {
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	[managedObjectContext reset];
}

/*!
 @abstract Saves to Core Data Context
 - if fail then alert user and quit
 - specify alert delegate in appDelegate to handle app quit
 
 Args:
 - quitOnFail		should quit if error encountered
 - idString			indicate the part code that you are saving at - to help track problem
 */
+ (NSError *) cdSaveWithIDString:(NSString *)idString quitOnFail:(BOOL)quit {
    
    // if app is doing hard reset, don't change CD right now.
    if ([[AppUtility getAppDelegate] isStartingFromScratch]) {
        DDLogInfo(@"cdSave: Cancel Save - SFS!! - %@", idString);
        return nil;
    }
    
    
	DDLogInfo(@"cdSave: %@", idString);
	NSError *error = nil;
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	if (![managedObjectContext save:&error]) {
		
		// automatically rollback to last saved to get rid of problems
		//	TODO: may want to let user decide in certain situations
		[managedObjectContext rollback];
		
		mpAppDelegate *appDelegate = [AppUtility getAppDelegate];
		
		DDLogError(@"ERROR CoreData Save: %@, %@, at %@", error, [error userInfo], idString);
		
		if (quit) {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error Saving to Core Data" 
                                                             message:[NSString stringWithFormat:@"Error: %@, quitting.", [error localizedDescription]] 
                                                            delegate:appDelegate
                                                   cancelButtonTitle:@"Quit" 
                                                   otherButtonTitles:nil] autorelease];
			[alert show];
		}
	}
	return error;
}

/*!
 @abstract deletes this object from CD
 
 */
+ (void) cdDeleteManagedObject:(NSManagedObject *)objectToDelete {
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
    //NSManagedObjectContext *deleteMOC = objectToDelete.managedObjectContext;
	[managedObjectContext deleteObject:objectToDelete];
}

/*!
 @abstract merge save notifcation to given MOC
 */
+ (void) cdMergeChangesToContext:(NSManagedObjectContext *)moc saveNotification:(NSNotification *)notification {
    
    //NSArray* updates = [[notification.userInfo objectForKey:@"updated"] allObjects];
    //DDLogVerbose(@"AU-mctc: merging save to MOC %d", [updates count]);
    
    // Fault in all updated objects, before merging
    /*NSArray* updates = [[notification.userInfo objectForKey:@"updated"] allObjects];
    for (NSInteger i = [updates count]-1; i >= 0; i--)
    {
        [[moc objectWithID:[[updates objectAtIndex:i] objectID]] willAccessValueForKey:nil];
    }*/
    // Merge
    [moc mergeChangesFromContextDidSaveNotification:notification];
}

/*!
 @abstract is merge is in progress than wait for it to complete
 
+ (void) cdWaitForMergeToComplete {
    
    int i = 0;
    while ([[AppUtility getAppDelegate] isMergingInProgress] == YES) {
        DDLogVerbose(@"AU-wm: waiting for merge");
        [NSThread sleepForTimeInterval:0.2];
        i++;
        // only wait up to 0.6 sec
        if (i > 3) {
            break;
        }
    }
    
}*/


/*!
 @abstract Refresh object from DB - faults this object
 
 */
+ (void) cdRefreshObject:(NSManagedObject *)refreshManagedObject {
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	[managedObjectContext refreshObject:refreshManagedObject mergeChanges:NO];
}



#pragma mark - Messaging Methods

/*!
 @abstract gets last 8 digits to use as SocketCenter write tag
 */
+ (long)getTagWithMessageID:(NSString *)mID {
    
    // create a tag to ID this message - last 8 digits
    NSUInteger idLength = [mID length];
    NSString *tagString = [mID substringFromIndex:idLength-8];
    long tag = (long)[tagString integerValue];
    return tag;
}

/*!
 @abstract generates unique ID for new messages
 
 new format:
 id:message id (fix 32 bytes) , generated by sender , to identify each message flow .
 yyyymmdd(8) + USERID(8) + serialnumber(16) e.g. 20110823282603330000000000000001
 
 old: deprecated
 id:message id (fix 22 bytes) , generated by sender , to identify each message flow .
 yyyymmdd(8) + USERID(8) + serialnumber(6) e.g. 2011082328260333000001
 
 - get counter from setting center
 - use counter and increment
 - update to message center
 
 */
+ (NSString *) generateMessageID {
    
    // gets date string
    //
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];    
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    [dateFormatter release];
    
    // get userID
    //
    //NSString *userID = [NSArray arrayWithObject:[[MPSettingCenter sharedMPSettingCenter] secureValueForID:kMPSettingAuthKey]];
    NSString *userID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    
    
    // get message serial number
    //
    //NSNumber *messageCount = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingMessageCounter];
    // - use secure value so it is still accessible after reinstall
    //
    /*NSNumber *messageCount = [[MPSettingCenter sharedMPSettingCenter] secureValueForID:kMPSettingMessageCounter];

    NSString *messageIDString = nil;
    if (messageCount) {
        messageIDString = [NSString stringWithFormat:@"%016d", [messageCount intValue]];
    }
    // start from 1
    else {
        messageCount = [NSNumber numberWithInt:1];
        messageIDString = [NSString stringWithFormat:@"%016d", [messageCount intValue]];
     
     // increment and update counter
     //[[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingMessageCounter settingValue:[NSNumber numberWithInt:[messageCount intValue]+1]];
     
     [[MPSettingCenter sharedMPSettingCenter] setSecureValueForID:kMPSettingMessageCounter settingValue:[NSNumber numberWithInt:[messageCount intValue]+1]];
     
    }*/
    
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSString *messageIDString = [NSString stringWithFormat:@"%010.3f", currentTime];
    messageIDString = [messageIDString stringByReplacingOccurrencesOfString:@"." withString:@""];

    // set ID
    NSString *idString = [NSString stringWithFormat:@"%@%@%@000", dateString, userID, messageIDString];
    
    return idString;
}

#pragma mark - Phone Number Tools & Telephony


/*!
 @abstract is user's registered country code TW?
 */
+ (BOOL) isTWCountryCode {
    
    NSString *cCode = [[MPHTTPCenter sharedMPHTTPCenter] getCountryCode];
    
    if ([cCode isEqualToString:@"886"]) {
        return YES;
    }
    return NO;
}




/*!
 @abstract strips out 0 prefixes
 */
+ (NSString *) stripZeroPrefixForString:(NSString *)string {
    
    if ([string hasPrefix:@"0"]) {
    
        NSUInteger zeroIndex = NSNotFound;
        
        for (int i=0; i < [string length]; i++) {
            if ([string characterAtIndex:i] == [@"0" characterAtIndex:0]) {
                zeroIndex = i;
            }
            // if not 0 break out
            else {
                break;
            }
        }
        
        // if 0s found, then strip it
        //
        if (zeroIndex != NSNotFound && zeroIndex < [string length]-1) {
            return [string substringFromIndex:zeroIndex+1];
        }
    }
    
    // no zero prefix, just return the same string
    return string;
}



/*!
 @abstract call a given phone number
 */
+ (void)call:(NSString *)phoneNumber {
    
    // perform action!!!
	NSString *escapedString = phoneNumber;
	
    if (!escapedString) {
        return;
    }
	
	// check for special characters
	// - if in middle of string notify users that 3rd party apps can't dial # or *
	// - if at end of string strip character and tell users to dial it manually
    // strip string of special characters
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"*" withString:@""];
	
	// prepare string for URL calling out
	escapedString = [escapedString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	// can be call, callHome, callWork, etc.
    
    NSString *urlString = [NSString stringWithFormat:@"tel:%@", escapedString];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlString]]) {
        DDLogVerbose(@"C-crp: calling registered phone");
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }
    else {
        DDLogVerbose(@"C-crp: telephony not supported %@", escapedString);
        [AppUtility showAlert:kAUAlertTypeNoTelephonyCall];
    }
}


/*!
 @abstract compose SMS to phone number
 */
+ (void)sms:(NSString *)phoneNumber delegate:(id)composerDelegate {
    
    // check if sms is available
    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *composer = [[MFMessageComposeViewController alloc] init];
        composer.messageComposeDelegate = composerDelegate;
        composer.recipients = [NSArray arrayWithObject:phoneNumber];
        
        // present with root container to allow rotation
        //
        [[AppUtility getAppDelegate].containerController presentModalViewController:composer animated:YES];
        [composer release];
    }
    else {
        // alert users that mail is not setup yet
        [AppUtility showAlert:kAUAlertTypeNoTelephonySMS];
    }
}



#pragma mark - String Validation

/*!
 @abstract check if userID format is ok
 */
+ (BOOL) isUserIDValid:(NSString *)userID {
    
    // TODO: provide better check - but really does not need to be that strict, since format can change in future
    //
    if ([userID length] > 5){
        return YES;
    }
    return NO;
}

/*!
 @abstract check if m+ message ID format is ok
 */
+ (BOOL) isMessageIDValid:(NSString *)mpID {
    
    // TODO: provide better check
    //
    if ([mpID length] > 3){
        return YES;
    }
    return NO;
}

/*!
 @abstract check if nick name format is ok
 */
+ (BOOL) isNickNameValid:(NSString *)nickName {
        
    // - min length of 3
    if ([nickName length] > 1){
        return YES;
    }
    return NO;
}


/*!
 @abstract Strip special characters from nickname in case it is corrupted for some reason
 
 */
+ (NSString *)stripNickName:(NSString *)nickName
{
    
    // include domain for all messages for now
    NSCharacterSet *specialSet = [[AppUtility getAppDelegate] sharedCacheObjectForKey:@"nicknameStripCharacterSet"];
    if (!specialSet) {
        specialSet = [NSCharacterSet characterSetWithCharactersInString:@"[]@{}&+="];
        [[AppUtility getAppDelegate] sharedCacheSetObject:specialSet forKey:@"nicknameStripCharacterSet"];
    }
    
    NSString *newNick = [[nickName componentsSeparatedByCharactersInSet:specialSet] componentsJoinedByString:@""];
    return newNick;

}


#pragma mark -  Config UI Methods

/*!
 @abstract returns UIColor for given context
 */
+ (UIColor *) colorForContext:(AUColorType)colorType {
    
    switch (colorType) {
           
        case kAUColorTypeGray1: // 72, 72, 72
            return [UIColor colorWithRed:0.282 green:0.282 blue:0.282 alpha:1.0];
            break;
            
        case kAUColorTypeLightGray1: // 140, 140, 140
            return [UIColor colorWithRed:0.549 green:0.549 blue:0.549 alpha:1.0];
            break;
            
        case kAUColorTypeBackground: 
            return [UIColor colorWithRed:0.871 green:0.867 blue:0.859 alpha:1.0]; // R222 G221 B219
            break;
            
        case kAUColorTypeBackgroundLight: 
            return [UIColor colorWithRed:0.965 green:0.965 blue:0.965 alpha:1.0]; // 246 246 246
            break;
            
        case kAUColorTypeTableSeparator: 
            return [UIColor colorWithRed:0.859 green:0.859 blue:0.859 alpha:1.0]; 
            //return [UIColor whiteColor]; 
            break;
            
        case kAUColorTypeBackgroundText:
            return [UIColor colorWithRed:0.345 green:0.345 blue:0.345 alpha:1.0];
            break;
        
        case kAUColorTypeBackgroundTextInfo:
            return [UIColor blackColor];
            break;
            
        case kAUColorTypeBlue2: // CreateID, PhoneReg   44 98 126
            return [UIColor colorWithRed:0.173 green:0.384 blue:0.494 alpha:1.0];
            break;
            
        case kAUColorTypeRed1:
            return [UIColor colorWithRed:0.914 green:0.314 blue:0.29 alpha:1.0];
            break;
        
        // myProfile 
        case kAUColorTypeBlue1:
            return [UIColor colorWithRed:0.022 green:0.451 blue:0.647 alpha:1.0];
            break;
  
        // navigation back button, text - 105, 115, 0
        case kAUColorTypeGreen1:
            return [UIColor colorWithRed:0.412 green:0.451 blue:0.0 alpha:1.0];
            break; 
            
        // switch tint color
        case kAUColorTypeGreen2:
            return [UIColor colorWithRed:0.553 green:0.718 blue:0.161 alpha:1.0];
            break;
            
        case kAUColorTypeButtonText:
            return [UIColor whiteColor];
            break;
        // new friends highlight - yellow 250 250 200
        case kAUColorTypeTableSelected:
            return [UIColor colorWithRed:0.98 green:0.98 blue:0.784 alpha:1.0];
            break; 
            
        // search bar - light gray
        case kAUColorTypeSearchBar:
            return [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
            break; 
            
        case kAUColorTypeKeypad:
            return [UIColor colorWithRed:0.949 green:0.949 blue:0.949 alpha:1.0];
            break;
        
        // letter warning count
        case kAUColorTypeOrange:
            return [UIColor colorWithRed:0.98 green:0.58 blue:0.27 alpha:1.0];
            break;
            
        default:
            break;
    }
    return nil;
    
}


/*!
 @abstract configure label for the given context
 */
+ (void) configTextField:(UITextField *)tField context:(AUTextFieldType)tFieldType {
    
    switch (tFieldType) {
            
        case kAUTextFieldTypeBasic:
            
            tField.clearButtonMode = UITextFieldViewModeWhileEditing;
            tField.textColor = [UIColor blackColor];
            tField.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
            tField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            tField.autocorrectionType = UITextAutocorrectionTypeNo;
            break;
            
        case kAUTextFieldTypeName:
            tField.borderStyle = UITextBorderStyleRoundedRect;
            tField.clearButtonMode = UITextFieldViewModeWhileEditing;
            tField.textColor = [UIColor blackColor];
            tField.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
            tField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            tField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            tField.autocorrectionType = UITextAutocorrectionTypeNo;
            tField.keyboardType = UIKeyboardTypeDefault;
            break;
            
        case kAUTextFieldTypePhone:
            tField.borderStyle = UITextBorderStyleRoundedRect;
            tField.autocorrectionType = UITextAutocorrectionTypeNo;
            tField.autocapitalizationType = UITextAutocapitalizationTypeNone;            
            tField.clearButtonMode = UITextFieldViewModeNever;
            tField.textColor = [UIColor blackColor];
            tField.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
            tField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            break;
            
        case kAUTextFieldTypeStatus:
            
            //tField.clearButtonMode = UITextFieldViewModeWhileEditing;
            tField.textColor = [UIColor blackColor];
            tField.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandardPlus];
            tField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
            
            break;
    }
}



/*!
 @abstract configure label for the given context
 */
+ (void) configButton:(UIButton *)button context:(AUButtonType)buttonType {
    
    UIImageView *arrow = nil;
    CGFloat arrowStartX = 0.0;
    CGFloat arrowStartY = 15.0;
    
    switch (buttonType) {
          
        case kAUButtonTypeOperator:
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal]; 
            //button.contentEdgeInsets = UIEdgeInsetsMake(7.5, 10.5, 4.5, 11.0);
            button.contentEdgeInsets = UIEdgeInsetsMake(7.0, 11.0, 5.0, 11.0);
            button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            button.backgroundColor = [UIColor clearColor];
            button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
            button.enabled = NO;
            button.adjustsImageWhenDisabled = NO;
            
            break;
            

            
        case kAUButtonTypeTextBarTop:
            
            [button setBackgroundImage:[UIImage imageNamed:@"profile_statusfield_top_nor.png"] forState:UIControlStateNormal];
            [button setBackgroundImage:[UIImage imageNamed:@"profile_statusfield_top_prs.png"] forState:UIControlStateHighlighted];
            button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            button.opaque = YES;
            
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
            
            [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [button setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 20.0)];
            button.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;

            
            arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_icon_arrow.png"]];
            arrowStartX = button.frame.size.width - 18.0;
            arrow.frame = CGRectMake(arrowStartX, arrowStartY, 8.0, 14.0);
            arrow.backgroundColor = [UIColor clearColor];
            arrow.opaque = YES;
            arrow.tag = kAUViewTagTextBarArrow;
            [button addSubview:arrow];
            [arrow release];
            
            break;
            
        case kAUButtonTypeTextBarCenter:
            
            [button setBackgroundImage:[UIImage imageNamed:@"profile_statusfield_center_nor.png"] forState:UIControlStateNormal];
            [button setBackgroundImage:[UIImage imageNamed:@"profile_statusfield_center_prs.png"] forState:UIControlStateHighlighted];
            button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            button.opaque = YES;
            
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
            
            [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [button setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 20.0)];
            button.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;

            
            arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_icon_arrow.png"]];
            arrowStartX = button.frame.size.width - 18.0;
            arrow.frame = CGRectMake(arrowStartX, arrowStartY, 8.0, 14.0);
            arrow.backgroundColor = [UIColor clearColor];
            arrow.opaque = YES;
            arrow.tag = kAUViewTagTextBarArrow;
            [button addSubview:arrow];
            [arrow release];
            
            break;
            
        case kAUButtonTypeTextBarBottom:
            
            [button setBackgroundImage:[UIImage imageNamed:@"profile_statusfield_bottom_nor.png"] forState:UIControlStateNormal];
            [button setBackgroundImage:[UIImage imageNamed:@"profile_statusfield_bottom_prs.png"] forState:UIControlStateHighlighted];
            button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            button.opaque = YES;
            
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
            
            [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [button setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 20.0)];
            button.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;

            UIImageView *arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_icon_arrow.png"]];
            CGFloat arrowStartX = button.frame.size.width - 18.0;
            arrow.frame = CGRectMake(arrowStartX, arrowStartY, 8.0, 14.0);
            arrow.backgroundColor = [UIColor clearColor];
            arrow.opaque = YES;
            arrow.tag = kAUViewTagTextBarArrow;
            [button addSubview:arrow];
            [arrow release];
            
            break;
            
        case kAUButtonTypeTextBar:
            
            [button setBackgroundImage:[UIImage imageNamed:@"std_icon_textbar_nor.png"] forState:UIControlStateNormal];
            [button setBackgroundImage:[UIImage imageNamed:@"std_icon_textbar_prs.png"] forState:UIControlStateHighlighted];
            button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            button.opaque = YES;
            
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandardPlus];
            
            [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [button setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 20.0)];
            button.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
            
            arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_icon_arrow.png"]];
            arrowStartX = button.frame.size.width - 18.0;
            arrow.frame = CGRectMake(arrowStartX, arrowStartY, 8.0, 14.0);
            arrow.backgroundColor = [UIColor clearColor];
            arrow.opaque = YES;
            arrow.tag = kAUViewTagTextBarArrow;
            [button addSubview:arrow];
            [arrow release];
            break;
            
        // basic button - but looks like text edit view
        case kAUButtonTypeTextEditBar:
            
            //[button setBackgroundImage:backImage forState:UIControlStateNormal];
            //[button setBackgroundImage:[UIImage imageNamed:@"std_icon_textbar_prs.png"] forState:UIControlStateHighlighted];
            button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            button.opaque = YES;
            
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
            
            [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [button setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [button setTitleEdgeInsets:UIEdgeInsetsMake(2.0, 10.0, 0.0, 50.0)];
            button.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
            UIImage *norImage = [Utility resizableImage:[UIImage imageNamed:@"std_icon_textbar.png"] leftCapWidth:9.0 topCapHeight:22.0];
            [button setBackgroundImage:norImage forState:UIControlStateNormal];
            
            break;
            
        // basic button - gray button used in schedule message read only
        case kAUButtonTypeGray1:
            
            button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            button.opaque = YES;
            
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
            
            [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [button setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [button setTitleEdgeInsets:UIEdgeInsetsMake(2.0, 10.0, 0.0, 50.0)];
            button.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
            
            [button setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"std_btn_gray1_nor.png"] leftCapWidth:10.0 topCapHeight:25.0] forState:UIControlStateNormal];
            [button setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"std_btn_gray1_prs.png"] leftCapWidth:10.0 topCapHeight:25.0] forState:UIControlStateHighlighted];
            
            break;
            
        case kAUButtonTypeTextBarSmall:
            
            [button setBackgroundImage:[UIImage imageNamed:@"std_icon_textbar_nor.png"] forState:UIControlStateNormal];
            [button setBackgroundImage:[UIImage imageNamed:@"std_icon_textbar_prs.png"] forState:UIControlStateHighlighted];
            button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            button.opaque = YES;
            
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
            
            [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [button setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 20.0)];
            
            arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_icon_arrow.png"]];
            arrowStartX = button.frame.size.width - 18.0;
            arrow.frame = CGRectMake(arrowStartX, arrowStartY, 8.0, 14.0);
            arrow.backgroundColor = [UIColor clearColor];
            arrow.opaque = YES;
            arrow.tag = kAUViewTagTextBarArrow;
            [button addSubview:arrow];
            [arrow release];
            break;
            
        case kAUButtonTypeOrange:
            
            [button setBackgroundImage:[UIImage imageNamed:@"profile_createid_btn_nor.png"] forState:UIControlStateNormal];
            [button setBackgroundImage:[UIImage imageNamed:@"profile_createid_btn_prs.png"] forState:UIControlStateHighlighted];
            button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            button.opaque = YES;
            
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            //[button setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
            //button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemLarge];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
                        
            break;
            
            
        case kAUButtonTypeOrange2:
            
            [button setBackgroundImage:[UIImage imageNamed:@"std_btn_orange2_nor.png"] forState:UIControlStateNormal];
            [button setBackgroundImage:[UIImage imageNamed:@"std_btn_orange2_prs.png"] forState:UIControlStateHighlighted];
            button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            button.opaque = YES;
            
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];            
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandard];
            [AppUtility addShadowToLabel:button.titleLabel];
            
            button.titleLabel.textAlignment = UITextAlignmentCenter;
            button.titleLabel.lineBreakMode = UILineBreakModeCharacterWrap;  
            
            break;
            
        // light orange with black bold title
        case kAUButtonTypeOrange3:
            
            [button setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"std_btn_orange_nor.png"] leftCapWidth:9.0 topCapHeight:15.0] forState:UIControlStateNormal];
            [button setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"std_btn_orange_prs.png"] leftCapWidth:9.0 topCapHeight:15.0] forState:UIControlStateHighlighted];
            
            button.backgroundColor = [UIColor clearColor];
            button.opaque = NO;
            
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldMicro];
            button.titleLabel.textAlignment = UITextAlignmentCenter;
            button.titleLabel.lineBreakMode = UILineBreakModeCharacterWrap;  
            
            break;
            
        // silver with black bold title
        case kAUButtonTypeSilver:
            
            [button setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"std_btn_green6_nor.png"] leftCapWidth:9.0 topCapHeight:15.0] forState:UIControlStateNormal];
            [button setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"std_btn_green6_prs.png"] leftCapWidth:9.0 topCapHeight:15.0] forState:UIControlStateHighlighted];
            
            button.backgroundColor = [UIColor clearColor];
            button.opaque = NO;
            
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldMicro];
            button.titleLabel.textAlignment = UITextAlignmentCenter;
            button.titleLabel.lineBreakMode = UILineBreakModeCharacterWrap;  
            
            break;
            
        case kAUButtonTypeYellow:
            
            [button setBackgroundImage:[UIImage imageNamed:@"std_btn_yellow_nor.png"] forState:UIControlStateNormal];
            [button setBackgroundImage:[UIImage imageNamed:@"std_btn_yellow_prs.png"] forState:UIControlStateHighlighted];
            button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            button.opaque = YES;
            
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldMicroPlus];
            button.titleLabel.textAlignment = UITextAlignmentCenter;
            button.titleLabel.lineBreakMode = UILineBreakModeCharacterWrap;  
            
            break;
            
        case kAUButtonTypeBlueDark:
                    

            [button setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"std_btn_darkblue_nor.png"] leftCapWidth:56.0 topCapHeight:25.0] forState:UIControlStateNormal];
            [button setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"std_btn_darkblue_prs.png"] leftCapWidth:56.0 topCapHeight:25.0] forState:UIControlStateHighlighted];
            button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            button.opaque = YES;
            
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldMicroPlus];
            button.titleLabel.textAlignment = UITextAlignmentCenter;
            button.titleLabel.lineBreakMode = UILineBreakModeCharacterWrap;  
            
            break;
     
        case kAUButtonTypeGreen:
        
            // green button for find, ok, etc.
            //
            [button setBackgroundImage:[UIImage imageNamed:@"std_btn_green1_nor.png"] forState:UIControlStateNormal];
            [button setBackgroundImage:[UIImage imageNamed:@"std_btn_green1_prs.png"] forState:UIControlStateHighlighted];
            [button setBackgroundImage:[UIImage imageNamed:@"std_btn_green1_dis.png"] forState:UIControlStateDisabled];
            
            button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            button.opaque = YES;
            
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            //[button setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandard];
            [AppUtility addShadowToLabel:button.titleLabel];
            
            break;
            
        case kAUButtonTypeGreen3:
            // green button for find, ok, etc.
            //
            [button setBackgroundImage:[UIImage imageNamed:@"std_btn_green3_nor.png"] forState:UIControlStateNormal];
            [button setBackgroundImage:[UIImage imageNamed:@"std_btn_green3_prs.png"] forState:UIControlStateHighlighted];
            [button setBackgroundImage:[UIImage imageNamed:@"std_btn_green3_dis.png"] forState:UIControlStateDisabled];
            
            button.backgroundColor = [UIColor clearColor];
            
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandard];
            [AppUtility addShadowToLabel:button.titleLabel];
            
            break;
            
        case kAUButtonTypeGreen5:
            // green button for find, ok, etc.
            //
            [button setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"std_btn_green5_nor.png"] leftCapWidth:29.0 topCapHeight:22.0] forState:UIControlStateNormal];
            [button setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"std_btn_green5_prs.png"] leftCapWidth:29.0 topCapHeight:22.0] forState:UIControlStateHighlighted];
            [button setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"std_btn_green5_dis.png"] leftCapWidth:29.0 topCapHeight:22.0] forState:UIControlStateDisabled];
            
            button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            button.opaque = YES;
            
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            //[button setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
            //button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandard];

            
            break;
            
        case kAUButtonTypeRed3:
            // red button for popup-block
            //
            [button setBackgroundImage:[UIImage imageNamed:@"std_btn_red3.png"] forState:UIControlStateNormal];
            
            button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            button.opaque = YES;
            
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandard];
            [AppUtility addShadowToLabel:button.titleLabel];
                        
            break;
            
        case kAUButtonTypeStatus:
            // status message bubble button 255, 47
            //
            [button setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"profile_statusfield_nor.png"] leftCapWidth:127.0 topCapHeight:40.0 ] forState:UIControlStateNormal];
            [button setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"profile_statusfield_prs.png"] leftCapWidth:127.0 topCapHeight:40.0] forState:UIControlStateHighlighted];
            
            button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            button.opaque = YES;
            
            /*[button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [button setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 30.0, 0.0, 10.0)];
            
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicroPlus];
            */
            
            break;
            
        case kAUButtonTypeSwitch:
            // on / off switch button
            //
            [button setBackgroundImage:[UIImage imageNamed:@"std_btn_set_off.png"] forState:UIControlStateNormal];
            [button setBackgroundImage:[UIImage imageNamed:@"std_btn_set_on.png"] forState:UIControlStateSelected];
            button.backgroundColor = [UIColor clearColor];
            button.opaque = NO;
            
            break;
            
        case kAUButtonTypeBadgeRed:
            [button setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"std_icon_badge_nor.png"] leftCapWidth:9.0 topCapHeight:9.0] forState:UIControlStateNormal];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldMicro];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; 
            //button.titleLabel.textAlignment = UITextAlignmentCenter;
            button.contentEdgeInsets = UIEdgeInsetsMake(3.0, 7.0, 3.0, 6.0);
            //button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            //button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
            button.backgroundColor = [UIColor clearColor];
            //button.adjustsImageWhenDisabled = NO;
            //button.enabled = NO;
            button.userInteractionEnabled = NO;
            
            break;
            
        case kAUButtonTypeBadgeYellow:
            [button setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"std_icon_badge_y.png"] leftCapWidth:9.0 topCapHeight:9.0] forState:UIControlStateNormal];
            button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldMicro];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; 
            button.contentEdgeInsets = UIEdgeInsetsMake(3.0, 7.0, 3.0, 6.0);
            button.backgroundColor = [UIColor clearColor];
            button.userInteractionEnabled = NO;
            
            break;
            
        default:
            
            break;
    }
}


/*!
 @abstract configure label for the given context
 */
+ (void) configInfoButton:(UIButton *)button context:(AUInfoButtonType)buttonType {
    
    NSString *norImageName = nil;
    NSString *prsImageName = nil;
    NSString *iconName = nil;
    NSString *text = nil;
    
    switch (buttonType) {
            
        case kAUInfoButtonTypeChat:
            norImageName = @"std_btn_green4_nor.png";
            prsImageName = @"std_btn_green4_prs.png";
            iconName = @"std_icon_msg.png";
            text = @"M+";
            break;
            
        case kAUInfoButtonTypeChatInvite:
            norImageName = @"std_btn_green4_nor.png";
            prsImageName = @"std_btn_green4_prs.png";
            iconName = @"std_icon_msg.png";
            text = @"Invite M+";
            break;
            
        case kAUInfoButtonTypeSMS:
            norImageName = @"std_btn_yellow_nor.png";
            prsImageName = @"std_btn_yellow_prs.png";
            iconName = @"std_icon_pay.png";
            text = @"SMS";
            break;
            
        case kAUInfoButtonTypeCall:
            norImageName = @"std_btn_blue_nor.png";
            prsImageName = @"std_btn_blue_prs.png";
            iconName = @"std_icon_call.png";
            text = @"Call";
            break;
            
        case kAUInfoButtonTypeBlock:
            norImageName = @"std_btn_orange2_nor.png";
            prsImageName = @"std_btn_orange2_prs.png";
            iconName = @"std_icon_block.png";
            text = @"Block";
            break;

        case kAUInfoButtonTypeDelete:
            norImageName = @"std_btn_red_nor.png";
            prsImageName = @"std_btn_red_prs.png";
            iconName = @"std_icon_delete.png";
            text = @"Delete";
            break;

    }
            
    UIImage *norImage = [Utility resizableImage:[UIImage imageNamed:norImageName] leftCapWidth:77.0 topCapHeight:24.0];
    UIImage *prsImage = [Utility resizableImage:[UIImage imageNamed:prsImageName] leftCapWidth:77.0 topCapHeight:24.0];    
    [button setBackgroundImage:norImage forState:UIControlStateNormal];
    [button setBackgroundImage:prsImage forState:UIControlStateHighlighted];
    
    button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    button.opaque = YES;
    
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
            
    [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [button setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    // [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 129.0, 0.0, 20.0)];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 149.0, 0.0, 20.0)];
    [button setTitle:text forState:UIControlStateNormal];
    
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:iconName]];
    // iconView.frame = CGRectMake(85.0, 10.0, 30.0, 30.0);
    iconView.frame = CGRectMake(105.0, 10.0, 30.0, 30.0);
    iconView.backgroundColor = [UIColor clearColor];
    [button addSubview:iconView];
    [iconView release];     
}

/*!
 @abstract adds shadow to label
 */
+ (void) addShadowToLabel:(UILabel *)label {
    label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.43];
    label.shadowOffset = CGSizeMake(0, -0.5);
}

/*!
 @abstract configure label for the given context
 */
+ (void) configLabel:(UILabel *)label context:(AULabelType)labelType {
    
    switch (labelType) {
    
        case kAULabelTypeNavTitle:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemHuge];
            label.textAlignment = UITextAlignmentCenter;
            label.adjustsFontSizeToFitWidth = YES;
            label.minimumFontSize = 15.0;
            label.textColor = [UIColor whiteColor];
            label.backgroundColor = [UIColor clearColor];
            label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.43];
            label.shadowOffset = CGSizeMake(0, 1);
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            break;
            
        case kAULabelTypeGrayMicroPlus:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicroPlus];
            label.textColor = [AppUtility colorForContext:kAUColorTypeGray1];
            label.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            label.opaque = YES;
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            
            break;
            
        case kAULabelTypeGreenStandardPlus:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandardPlus];
            label.textColor = [AppUtility colorForContext:kAUColorTypeGreen1];
            label.backgroundColor = [UIColor whiteColor];
            label.opaque = YES;
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            
            break;
            
        case kAULabelTypeGreenMicroPlus:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicroPlus];
            label.textColor = [AppUtility colorForContext:kAUColorTypeGreen1];
            label.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            label.opaque = YES;
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            
            break;
            
        case kAULabelTypeBlackStandardPlus:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandardPlus];
            label.textColor = [UIColor blackColor];
            label.highlightedTextColor = [UIColor whiteColor];
            label.opaque = YES;
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            break;
            
        case kAULabelTypeBlackStandardPlusBold:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandardPlus];
            label.textColor = [UIColor blackColor];
            label.highlightedTextColor = [UIColor whiteColor];
            label.opaque = YES;
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            break;
            
        case kAULabelTypeBlackSmall:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
            label.textColor = [UIColor blackColor];
            label.highlightedTextColor = [UIColor whiteColor];
            label.opaque = YES;
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            break;
            
        case kAULabelTypeBlackTiny:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
            label.textColor = [UIColor blackColor];
            label.highlightedTextColor = [UIColor whiteColor];
            label.opaque = YES;
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            break;
            
        case kAULabelTypeBlackMicroPlus:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
            label.textColor = [UIColor blackColor];
            label.highlightedTextColor = [UIColor whiteColor];
            label.backgroundColor = [UIColor clearColor];
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            break;
            
        case kAULabelTypeWhiteStandardBold:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
            label.textColor = [UIColor whiteColor];
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            
            break;
            
        case kAULabelTypeWhiteMicro:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
            label.textColor = [UIColor whiteColor];
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            break;
            
        case kAULabelTypeLightGrayNanoPlus:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemNanoPlus];
            label.textColor = [AppUtility colorForContext:kAUColorTypeLightGray1];
            label.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            label.opaque = YES;
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            break;
            
        case kAULabelTypeBlueNanoPlus:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemNanoPlus];
            label.textColor = [AppUtility colorForContext:kAUColorTypeBlue2];
            label.backgroundColor = [UIColor clearColor];
            label.opaque = NO;
            break;
            
        case kAULabelTypeBlue3:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandard];
            label.textColor = [AppUtility colorForContext:kAUColorTypeBlue2];
            label.backgroundColor = [UIColor clearColor];
            label.opaque = NO;
            label.textAlignment = UITextAlignmentCenter;
            break;
            
        case kAULabelTypeTableName:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandardPlus];
            label.textColor = [UIColor blackColor];
            label.highlightedTextColor = [UIColor whiteColor];
            label.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            label.opaque = YES;
            label.lineBreakMode = UILineBreakModeTailTruncation;
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            break;
            
        case kAULabelTypeTableMyName:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandard];
            label.textColor = [UIColor colorWithRed:0.459 green:0.537 blue:0.161 alpha:1.0];
            label.highlightedTextColor = [UIColor whiteColor];
            label.opaque = YES;
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            
            break;
            
        case kAULabelTypeTableStatus:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
            label.textColor = [UIColor grayColor];
            label.highlightedTextColor = [UIColor whiteColor];  
            label.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            label.opaque = YES;
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            
            break;
            
        case kAULabelTypeTableDate:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
            label.textColor = [UIColor grayColor];
            label.highlightedTextColor = [UIColor whiteColor];
            label.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            label.opaque = YES;
            label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            label.textAlignment = UITextAlignmentRight;
            
            break;
            
        case kAULabelTypeTableMainText:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
            label.textColor = [UIColor colorWithRed:0.055 green:0.055 blue:0.055 alpha:1.0];
            
            break;
            
        // for subtext of tablerows
        //
        case kAULabelTypeTableSubText:
            
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
            label.textColor = [UIColor colorWithRed:0.537 green:0.561 blue:0.58 alpha:1.0];
            
            break;
            
        case kAULabelTypeTableHighlight:
            
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
            label.textColor = [AppUtility colorForContext:kAUColorTypeBlue1];
            
            break;
        

            
        // for button labels
        //
        case kAULabelTypeButton:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandard];
            label.textColor = [UIColor whiteColor];
            //label.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            //label.opaque = YES;
            break;
            
        case kAULabelTypeButtonLarge:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemLarge];
            label.textColor = [UIColor whiteColor];
            //label.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            //label.opaque = YES;
            break;
            
        // for subtext of tablerows
        //
        case kAULabelTypeBackgroundText:
            
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
            label.textColor = [AppUtility colorForContext:kAUColorTypeBackgroundText];
            label.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            label.opaque = YES;
            break;
            
        case kAULabelTypeBackgroundTextInfo:
            
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemLarge];
            label.textColor = [AppUtility colorForContext:kAUColorTypeBackgroundTextInfo];
            label.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            label.opaque = YES;
            break;
            
        case kAULabelTypeBackgroundTextHighlight:
            
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
            label.textColor = [AppUtility colorForContext:kAUColorTypeBlue2];
            label.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            label.opaque = YES;
            break;
            
        case kAULabelTypeBackgroundTextHighlight2:
            
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
            label.textColor = [AppUtility colorForContext:kAUColorTypeBlue1];
            label.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            label.opaque = YES;
            break;
            
        case kAULabelTypeBackgroundTextCritical:
            
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
            label.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
            label.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
            label.opaque = YES;
            break;
            
        case kAULabelTypeTextBar:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandardPlus];
            label.textColor = [UIColor blackColor];
            label.backgroundColor = [UIColor whiteColor];
            label.opaque = YES;
            break;
            
        case kAULabelTypeHiddenPIN:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontBoldHugePlus];
            label.textColor = [UIColor colorWithRed:0.992 green:0.851 blue:0.439 alpha:1.0];
            label.backgroundColor = [UIColor clearColor];
            label.textAlignment = UITextAlignmentCenter;
            label.opaque = NO;
            break;
            
        case kAULabelTypeNoItem:
            label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandard];
            label.textColor = [AppUtility colorForContext:kAUColorTypeLightGray1];
            label.backgroundColor = [UIColor clearColor];
            label.numberOfLines = 4;
            label.textAlignment = UITextAlignmentCenter;
            label.opaque = NO;
            break;
            
        case kAULabelTypeBadgeText:
            
            label.font = [AppUtility fontPreferenceWithContext:kAUFontBoldMicro];
            label.textColor = [UIColor whiteColor];
            label.backgroundColor = [UIColor clearColor];
            label.textAlignment = UITextAlignmentCenter;
            
            break;
            
        default:
            break;
    }
    
}

// Get the perferred font size
// * return UIFont that you should use
//
+ (UIFont *)fontPreferenceWithContext:(AUFontType)fontType {
	
	// mht: Feb 2010
	// * disable this option since probably not widely used
	// * hardcode to normal
	//
	//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//NSString *textSize = [defaults stringForKey:@"text_size"];
	//
	NSString *textSize = @"normal";
	
	if ([textSize isEqualToString:@"small"]) {
        return [UIFont boldSystemFontOfSize:17];
	}
	// for large text
	else if ([textSize isEqualToString:@"large"]) {
        return [UIFont boldSystemFontOfSize:17];
	}
	// normal size
	else {
        switch (fontType) {
            case kAUFontBoldHugePlus:
                return [UIFont boldSystemFontOfSize:21];
                break;
                
            case kAUFontBoldHuge:
                return [UIFont boldSystemFontOfSize:20];
                break;
                
            case kAUFontBoldLarge:
                return [UIFont boldSystemFontOfSize:19];
                break;
                
            case kAUFontBoldStandardPlus:
                return [UIFont boldSystemFontOfSize:18];
                break;
                
            case kAUFontBoldStandard:
                return [UIFont boldSystemFontOfSize:17];
                break;
                
            case kAUFontBoldSmall:
                return [UIFont boldSystemFontOfSize:15];
                break;
                
            case kAUFontBoldTiny:
                return [UIFont boldSystemFontOfSize:13];
                break;
                
            case kAUFontBoldMicroPlus:
                return [UIFont boldSystemFontOfSize:12];
                break;
                
            case kAUFontBoldMicro:
                return [UIFont boldSystemFontOfSize:11];
                break;
                
            case kAUFontSystemHuge:
                return [UIFont systemFontOfSize:20];
                break;
                
            case kAUFontSystemLarge:
                return [UIFont systemFontOfSize:19];
                break;
                
            case kAUFontSystemStandardPlus:
                return [UIFont systemFontOfSize:18];
                break;
                
            case kAUFontSystemStandard:
                return [UIFont systemFontOfSize:17];
                break;
                
            case kAUFontSystemSmall:
                return [UIFont systemFontOfSize:15];
                break;
                
            case kAUFontSystemTiny:
                return [UIFont systemFontOfSize:13];
                break;
              
            case kAUFontSystemMicroPlus:
                return [UIFont systemFontOfSize:12];
                break;
                
            case kAUFontSystemMicro:
                return [UIFont systemFontOfSize:11];
                break;
                
            case kAUFontSystemNanoPlus:
                return [UIFont systemFontOfSize:10];
                break;
                
            default:
                return [UIFont systemFontOfSize:17];
                break;
        }
	}
}

/*!
 @abstract Sets the text for badge buttons
 - need inset adjustments
 - hide if 0
 
 Note: badge should set autoresizemask properly so badge can grow to the right side
 
 */
+ (void) setBadge:(UIButton *)badgeButton text:(NSString *)text {
    
    if (badgeButton) {
        NSString *numString = text;
        if ([numString length] > 1) {
            badgeButton.contentEdgeInsets = UIEdgeInsetsMake(3.0, 7.0, 3.0, 7.0);
        }
        else {
            badgeButton.contentEdgeInsets = UIEdgeInsetsMake(3.0, 7.0, 3.0, 6.0);
        }
        [badgeButton setTitle:numString forState:UIControlStateNormal];
        
        CGRect badgeFrame = badgeButton.frame;
        [badgeButton sizeToFit];
        
        // if flexible left margin, keep it right aligned
        //
        if (badgeButton.autoresizingMask & UIViewAutoresizingFlexibleLeftMargin) {
            // old width - new width
            badgeFrame.origin.x = badgeFrame.origin.x + (badgeFrame.size.width - badgeButton.frame.size.width);
            badgeFrame.size = badgeButton.frame.size;
            badgeButton.frame = badgeFrame;
        }
        // left align, nothing needs to be done
        
        
        // allow for regular text (e.g. "N")
        // - 0 and less is hidden
        //
        if ([text isEqualToString:@"0"] || [text intValue] < 0 || text == nil) {
            badgeButton.hidden = YES;
        }
        else {
            badgeButton.hidden = NO;
        }
    }
}


#define kCellTextWidth          175.0
#define kCellTextWidthShort     60.0
#define kCellTextWidthExtend    220.0
#define kCellTextWidthLong      280.0

#define kCellTextHeight         20.0
#define kCellTextHeightShort    18.0

#define kCellHeight			44.0

#define kCellYStart			1.0

#define kCellXStart			10.0
#define	kCellXStartIndent	54.0
#define	kCellXStartIndentNew	60.0
#define kCellXStartRight    270.0
#define kCellXSelectIndent  40.0

/*!
 @abstract Responsible for formating table row cells.
 
 @discussion Use this method to keep formatting consistent and easy to make future changes.
 
 @param an array of labels that should be formatted
 */
+ (void) setCellStyle:(AUCellStyle)style  labels:(NSArray *)labels {
	
    UILabel *mainLabel = nil;
    UILabel *subLabel = nil;
    UILabel *thirdLabel = nil;
    
    NSInteger labelCount = [labels count];
    if (labelCount > 0) {
        mainLabel = [labels objectAtIndex:0];
    }
    if (labelCount > 1) {
        subLabel = [labels objectAtIndex:1];
    }
    if (labelCount > 2) {
        thirdLabel = [labels objectAtIndex:2];
    }
    
    [self configLabel:subLabel context:kAULabelTypeTableStatus];
    [self configLabel:thirdLabel context:kAULabelTypeTableDate];

    
    switch (style) {

        case kAUCellStyleChatList:
            /* 3 labels
             main and sub align left
             third alight right
             */
            [self configLabel:mainLabel context:kAULabelTypeTableName];
            [self configLabel:subLabel context:kAULabelTypeGrayMicroPlus];
            [self configLabel:thirdLabel context:kAULabelTypeLightGrayNanoPlus];
            subLabel.lineBreakMode = UILineBreakModeTailTruncation;
            subLabel.numberOfLines = 1;
            mainLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
            subLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
            thirdLabel.textAlignment = UITextAlignmentRight;
            thirdLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            
            mainLabel.frame = CGRectMake(kCellXStartIndentNew, 7.0, 170.0, 22.0);
            subLabel.frame = CGRectMake(kCellXStartIndentNew, 30.0, 170.0, 20.0);
            thirdLabel.frame = CGRectMake(262.0, 2.0, 50.0, kCellTextHeightShort);
            break;
            
        case kAUCellStyleFriendList:
            /* 3 labels
             main and sub align left
             third alight right
             */
            [self configLabel:mainLabel context:kAULabelTypeTableName];
            [self configLabel:subLabel context:kAULabelTypeGrayMicroPlus];
            subLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            subLabel.numberOfLines = 1;
            subLabel.lineBreakMode = UILineBreakModeTailTruncation;
            
            mainLabel.frame = CGRectMake(kCellXStartIndentNew, 7.0, kCellTextWidth, 22.0);
            subLabel.frame = CGRectMake(kCellXStartIndentNew, 30.0, kCellTextWidth, 20.0);
            thirdLabel.frame = CGRectMake(235.0, (kMPParamTableRowHeight-kCellTextHeightShort)/2.0, 50.0, kCellTextHeightShort); // origin.y = 240 w/index
            
            //thirdLabel.frame = CGRectMake(245.0, (kCellHeight-kCellTextHeightShort)/2.0, 45.0, kCellTextHeightShort);
            break;
            
        case kAUCellStyleSelectContact:
            /* radio + 3 labels
             - radio button 
             - main black alight left
             - sub gray alight left
             - third gray alight right
             */
            
            [self configLabel:mainLabel context:kAULabelTypeTableName];
            [self configLabel:subLabel context:kAULabelTypeGrayMicroPlus];
            [self configLabel:thirdLabel context:kAULabelTypeLightGrayNanoPlus];
            subLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            thirdLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            thirdLabel.textAlignment = UITextAlignmentRight;
            thirdLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            
            mainLabel.frame = CGRectMake(kCellXStartIndentNew+kCellXSelectIndent, 7.0, 165.0, 22.0);
            subLabel.frame = CGRectMake(kCellXStartIndentNew+kCellXSelectIndent, 30.0, 165.0, 20.0);
            //thirdLabel.frame = CGRectMake(262.0+5.0, 2.0, 50.0, kCellTextHeightShort);
            thirdLabel.frame = CGRectMake(262.0, 2.0, 50.0, kCellTextHeightShort);
            
            break;
            
        case kAUCellStyleScheduleList:
            /* 3 labels
             main and sub align left
             third alight right
             */
            [self configLabel:mainLabel context:kAULabelTypeBlackStandardPlus];
            [self configLabel:subLabel context:kAULabelTypeGreenMicroPlus];
            [self configLabel:thirdLabel context:kAULabelTypeLightGrayNanoPlus];
            
            mainLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            subLabel.lineBreakMode = UILineBreakModeTailTruncation;
            subLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
            thirdLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            thirdLabel.textAlignment = UITextAlignmentRight;
            thirdLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            
            mainLabel.frame = CGRectMake(kCellXStartIndentNew, 7.0, 165.0, 22.0);
            subLabel.frame = CGRectMake(kCellXStartIndentNew, 30.0, 165.0, 20.0);
            thirdLabel.frame = CGRectMake(234.0, 20.0, 75.0, 14.0);
            break;
            
        case kAUCellStylePhoneBook:
            /* 3 labels
             main and sub align left
             third align center under operator tag
             */
            [self configLabel:mainLabel context:kAULabelTypeTableName];
            [self configLabel:subLabel context:kAULabelTypeGrayMicroPlus];
            subLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            thirdLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            
            mainLabel.frame = CGRectMake(kCellXStart, 8.0, kCellTextWidthExtend, 21.0);
            subLabel.frame = CGRectMake(kCellXStart, 33.0, kCellTextWidthExtend, 14.0);
            thirdLabel.frame = CGRectMake(247.0, 20.0, 65.0, 14.0);
            
            break;
            
        case kAUCellStylePhoneBookTW:
            /* 3 labels
             main and sub align left
             third alight right
             */
            [self configLabel:mainLabel context:kAULabelTypeTableName];
            [self configLabel:subLabel context:kAULabelTypeGrayMicroPlus];
            subLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            thirdLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            thirdLabel.textAlignment = UITextAlignmentCenter;
            thirdLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

            mainLabel.frame = CGRectMake(kCellXStart, 8.0, kCellTextWidthExtend, 21.0);
            subLabel.frame = CGRectMake(kCellXStart, 33.0, kCellTextWidthExtend, 14.0);
            //thirdLabel.frame = CGRectMake(247.0, 33.0, 65.0, 14.0);
            thirdLabel.frame = CGRectMake(240.0, 33.0, 80.0, 14.0);
            break;
            
        case kAUCellStyleSuggestList:
            /* 3 labels
             main left
             */
            [self configLabel:mainLabel context:kAULabelTypeTableName];
            [self configLabel:subLabel context:kAULabelTypeGrayMicroPlus];
            [self configLabel:thirdLabel context:kAULabelTypeLightGrayNanoPlus];
            
            subLabel.lineBreakMode = UILineBreakModeTailTruncation;
            subLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            thirdLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            thirdLabel.textAlignment = UITextAlignmentRight;
            thirdLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            
            //mainLabel.frame = CGRectMake(kCellXStartIndentNew, 7.0, kCellTextWidth, 22.0);
            //subLabel.frame = CGRectMake(kCellXStartIndentNew, 32.0, kCellTextWidth+50.0, 15.0);
            mainLabel.frame = CGRectMake(kCellXStartIndentNew, (kMPParamTableRowHeight-22.0)/2.0, kCellTextWidth, 22.0);
            subLabel.frame = CGRectZero;
            thirdLabel.frame = CGRectMake(260.0, (kMPParamTableRowHeight-kCellTextHeightShort)/2.0, 50.0, kCellTextHeightShort);
            break;
            
        case kAUCellStyleNoSelectContact:
            /* radio + 3 labels
             - radio button 
             - main black alight left
             - sub gray alight left
             - third gray alight right
             */
            
            [self configLabel:mainLabel context:kAULabelTypeTableName];
            [self configLabel:subLabel context:kAULabelTypeGrayMicroPlus];
            [self configLabel:thirdLabel context:kAULabelTypeLightGrayNanoPlus];
            subLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            thirdLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            thirdLabel.textAlignment = UITextAlignmentRight;
            thirdLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            
            mainLabel.frame = CGRectMake(kCellXStartIndentNew, 7.0, 165.0, 22.0);
            subLabel.frame = CGRectMake(kCellXStartIndentNew, 30.0, 165.0, 20.0);
            thirdLabel.frame = CGRectMake(262.0, 2.0, 50.0, kCellTextHeightShort);
            
            break;
            
        case kAUCellStyleSelectProperty:
            /* radio + 2 labels
              - radio button 
              - main black text alight left
              - sub blue text alight right
             */
            [self configLabel:mainLabel context:kAULabelTypeTableName];
            [self configLabel:subLabel context:kAULabelTypeTableHighlight];
            subLabel.textAlignment = UITextAlignmentRight;
            
            mainLabel.frame = CGRectMake(40.0, (kMPParamTableRowHeight-kCellTextHeight)/2.0, 140.0, kCellTextHeight);
            subLabel.frame = CGRectMake(200.0, (kMPParamTableRowHeight-kCellTextHeightShort)/2.0, 110.0, kCellTextHeightShort);
            break;
            
        case kAUCellStyleSelectCountry:
            /* 2 labels
             - main black text alight left
             - sub blue text alight right
             */
            [self configLabel:mainLabel context:kAULabelTypeBlackSmall];
            [self configLabel:subLabel context:kAULabelTypeBlackSmall];
            
            subLabel.textAlignment = UITextAlignmentRight;
            
            mainLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            subLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];

            mainLabel.frame = CGRectMake(kCellXStart, (kCellHeight-kCellTextHeight)/2.0, 160.0, kCellTextHeight);
            subLabel.frame = CGRectMake(225.0, (kCellHeight-kCellTextHeightShort)/2.0, 80.0, kCellTextHeightShort);
            break;
            
        case kAUCellStyleBlockList:
            /* 3 labels
             main and sub align left
             third alight right
             */
            [self configLabel:mainLabel context:kAULabelTypeTableName];
            [self configLabel:subLabel context:kAULabelTypeGrayMicroPlus];
            subLabel.lineBreakMode = UILineBreakModeTailTruncation;
            subLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
            
            //mainLabel.frame = CGRectMake(kCellXStartIndentNew, 7.0, 155.0, 22.0);
            //subLabel.frame = CGRectMake(kCellXStartIndentNew, 32.0, 155.0, 15.0);
            mainLabel.frame = CGRectMake(kCellXStartIndentNew, (kMPParamTableRowHeight-22.0)/2.0, 155.0, 22.0);
            subLabel.frame = CGRectZero;
            break;
            
        case kAUCellStyleBasic:
            // single label
            [self configLabel:mainLabel context:kAULabelTypeTableStandard];
            
            mainLabel.frame = CGRectMake(kCellXStart, (kCellHeight - kCellTextHeight)/2.0, kCellTextWidthLong, kCellTextHeight);
            break;
            
        default:
            [self configLabel:mainLabel context:kAULabelTypeTableName];
            break;
    }
    

    
}

/*
 deprecate this!
 */
+ (void) setCellStyle:(AUCellStyle)style  mainLabel:(UILabel *)mainLabel subLabel:(UILabel *)subLabel {
	
	mainLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
	subLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldTiny];
	
	// simple one line one label cell
	if (style == kCellStyleOneLine) {
		mainLabel.frame = CGRectMake(kCellXStart, kCellYStart, kCellTextWidth, kCellHeight);
	}
	// One-Line with Icon
	else if (style == kCellStyleOneLineIcon) {
		mainLabel.frame = CGRectMake(kCellXStartIndent, kCellYStart, kCellTextWidth, kCellHeight);
	}
	// One-Line with subLabel to the right
	else if (style == kCellStyleOneLineAccessory) {
		mainLabel.frame = CGRectMake(kCellXStart, kCellYStart, 140.0, kCellHeight);
		subLabel.frame = CGRectMake(150.0, kCellYStart, 138.0, kCellHeight);
		subLabel.textAlignment = UITextAlignmentRight;
	}
	else if (style == kCellStyleTwoLine) {
		mainLabel.frame = CGRectMake(kCellXStart, kCellYStart, kCellTextWidth, kCellHeight/2.0+2.0);
		subLabel.frame = CGRectMake(kCellXStart, kCellYStart+kCellHeight/2.0+2.0, kCellTextWidth, kCellHeight/2.0-2.0);
		
		mainLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
		subLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
	}
	// grouped indented table view with name and property on two lines
	else if (style == kCellStyleTwoLineNamePropertyGrouped ){
		mainLabel.frame = CGRectMake(10.0, kCellYStart, kCellTextWidth, kCellHeight/2.0+2.0);
		subLabel.frame = CGRectMake(10.0, kCellYStart+kCellHeight/2.0+2.0, kCellTextWidth, kCellHeight/2.0-2.0);
        
		mainLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
		subLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldMicro];
	}
	// two line for favorites cell: icon to the left
	else if (style == kCellStyleTwoLineFavorites ){
		//nameFrame = CGRectMake(kStartX, 5.0, 220.0, 22.0);
		//propertyFrame = CGRectMake(kStartX, 22.0, 170.0, 22.0);
		
		mainLabel.frame = CGRectMake(kCellXStartIndent, kCellYStart, kCellTextWidth, kCellHeight/2.0+2.0);
		subLabel.frame = CGRectMake(kCellXStartIndent, kCellYStart+kCellHeight/2.0+2.0, kCellTextWidth, kCellHeight/2.0-2.0);
		
		mainLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
		subLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldMicro];
	}
    /*
	mainLabel.textColor = [AppUtility colorFor:kTextColorMain];
	mainLabel.highlightedTextColor = [AppUtility colorFor:kTextColorMainHightlighted];
    
	subLabel.textColor = [AppUtility colorFor:kTextColorSub];
	subLabel.highlightedTextColor = [AppUtility colorFor:kTextColorSubHighlighted];
	*/
    
    mainLabel.textColor = [UIColor blackColor];
	mainLabel.highlightedTextColor = [UIColor blackColor];
    
	subLabel.textColor = [UIColor blackColor];
	subLabel.highlightedTextColor = [UIColor blackColor];
    
    // if opaque
	if (NO) {
		if (style == kCellStyleTwoLineNamePropertyGrouped) {
			mainLabel.backgroundColor = [UIColor whiteColor];
			subLabel.backgroundColor = [UIColor whiteColor];
		}
		else {
			mainLabel.backgroundColor = [UIColor whiteColor];
			subLabel.backgroundColor = [UIColor whiteColor];
		}
		mainLabel.opaque = YES;
		subLabel.opaque = YES;
	}
	else {
		mainLabel.backgroundColor = [UIColor clearColor];
		subLabel.backgroundColor = [UIColor clearColor];
		mainLabel.opaque = NO;
		subLabel.opaque = NO;
	}
}

#pragma mark - UIView

/*!
 @abstract Finds first responder and resigns it
 
 */
+ (void) findAndResignFirstResponder {
    
    UIViewController *currentVC = [[AppUtility getAppDelegate].tabBarController selectedViewController];
    UIView *first = [currentVC.view findFirstResponder];
    [first resignFirstResponder];

}


#pragma mark - Update App
#define UPDATE_VIEW_TAG     19901

/*!
 @abstract Show the app update view if a major version update change was made
 
 @param serverText  Text that server would like us to display to the user as an alert
 */
+ (void) showAppUpdateView:(NSString *)serverText {

    // @TMP disable force update
    //return;
    
    UIViewController *containerVC = [[AppUtility getAppDelegate] containerController];
    
    // make sure modal view is dismissed so it does not cover this view
    [containerVC dismissModalViewControllerAnimated:YES];
    
    UIView *viewAlreadyExists = [containerVC.view viewWithTag:UPDATE_VIEW_TAG];
    if (viewAlreadyExists) {
        DDLogWarn(@"App force update - skip, already showing");
        return;
    }
    
    DDLogWarn(@"App force update is showing!");
    AppUpdateView *updateView = [[AppUpdateView alloc] initWithFrame:CGRectZero];
    updateView.tag = UPDATE_VIEW_TAG;
    
    [containerVC.view addSubview:updateView];
    [updateView release];
    
    // show server text alert message
    [Utility showAlertViewWithTitle:nil message:serverText];
    
    
    // check versions - deprecated
    //
    //if ([[MPSettingCenter sharedMPSettingCenter] isForceUpdateRequired]) {
    //}
}



#pragma mark - Nav Bar

/*!
 @abstract call this method selectively modify nav controller you want to change
 */
+ (void)customizeNavigationController:(UINavigationController *)navController
{
    UINavigationBar *navBar = [navController navigationBar];
    [navBar setTintColor:kMPNavBarColor];
    
    if ([navBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)])
    {
        [navBar setBackgroundImage:[UIImage imageNamed:@"std_titlebar.png"] forBarMetrics:UIBarMetricsDefault];
    }
    else
    {
        UIImageView *imageView = (UIImageView *)[navBar viewWithTag:kMPNavBarImageTag];
        if (imageView == nil)
        {
            imageView = [[UIImageView alloc] initWithImage:
                         [UIImage imageNamed:@"std_titlebar.png"]];
            [imageView setTag:kMPNavBarImageTag];
            [navBar insertSubview:imageView atIndex:0];
            [imageView release];
        }
    }
}

/*!
 @abstract Sets custom navigation bar label
 */
+ (void)setCustomTitle:(NSString *)title navigationItem:(UINavigationItem *)navItem {
    
    UILabel *titleLabel = [[UILabel alloc] init];
    [AppUtility configLabel:titleLabel context:kAULabelTypeNavTitle];
    titleLabel.text = title;
    CGSize size = [title sizeWithFont:[AppUtility fontPreferenceWithContext:kAUFontSystemHuge]];
    titleLabel.frame = CGRectMake(0.0, 0.0, size.width, size.height);
                   
    navItem.titleView = titleLabel;
    [titleLabel release];
}


/*!
 @abstract Make standard configurations to tableviews
 */
+ (void) configTableView:(UITableView *)tableView {
    
    tableView.rowHeight = kMPParamTableRowHeight;
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView.separatorColor = [AppUtility colorForContext:kAUColorTypeTableSeparator]; 
    //[UIColor colorWithRed:0.99 green:1.0 blue:0.99 alpha:1.0]; //
    
    // set to gray background
    tableView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
}


#pragma mark - Activity Indicator and Alerts


#define kIndicatorTag       55001
#define kBackViewTag        55002
#define kProgressViewTag    55003

/*!
 @abstract Is activity indicator running?
 
 */
+ (BOOL)isActivityIndicatorRunning {
    
    UIViewController *workingVC = nil;
    
    // get container view
    UIViewController *containerVC = [[AppUtility getAppDelegate] containerController];
    
    if (containerVC.modalViewController) {
        workingVC = containerVC.modalViewController;
    }
    else {
        workingVC = containerVC;
    }
    
    // check if there is one already
	UIActivityIndicatorView *indicatorView = (UIActivityIndicatorView *)[workingVC.view viewWithTag:kIndicatorTag];
    
    if (indicatorView) {
        return YES;
    }
    return NO;
}

/*!
 @abstract Adds an activity indicator and start it
 
 @param backAlpha Specify how dark the background should be.  If activity is quick or does not need to be very noticable, then use light alpha
 */
+ (void)startActivityIndicatorBackgroundAlpha:(CGFloat)backAlpha {
	
    UIViewController *workingVC = nil;
    
    // get container view
    UIViewController *containerVC = [[AppUtility getAppDelegate] containerController];
    
    if (containerVC.modalViewController) {
        workingVC = containerVC.modalViewController;
    }
    else {
        workingVC = containerVC;
    }
    
	// check if there is one already
	UIActivityIndicatorView *indicatorView = (UIActivityIndicatorView *)[workingVC.view viewWithTag:kIndicatorTag];
    // background view
    UIView *backView = (UIView *)[workingVC.view viewWithTag:kBackViewTag];
    
	if (indicatorView) {
		if (![indicatorView isAnimating]) {
			[indicatorView startAnimating];
            backView.hidden = NO;
		}
	}
	// if none, add one!
	else {
        // add backview
        UIView *backView = [[UIView alloc] initWithFrame:workingVC.view.bounds];
        backView.backgroundColor = [UIColor blackColor];
        backView.alpha = backAlpha;
        backView.tag = kBackViewTag;
        [workingVC.view addSubview:backView];
        [backView release];
        
		// loading indicator
		UIActivityIndicatorView *loadingActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		loadingActivityIndicator.center = workingVC.view.center;
		loadingActivityIndicator.hidesWhenStopped = YES;
		[loadingActivityIndicator startAnimating];	
		loadingActivityIndicator.tag = kIndicatorTag;
		[workingVC.view addSubview:loadingActivityIndicator];
		[loadingActivityIndicator release];
	}	
}

/*!
 @Abstract Use dark background
 */
+ (void)startActivityIndicator {
    
    [AppUtility startActivityIndicatorBackgroundAlpha:0.5];
}

/*!
 @abstract Remove all activity indicators
 - use loop to make sure you remove all of them, in case more than one exists
 
 */
+ (void)stopActivityIndicator { //:(UINavigationController *)navController {
	DDLogVerbose(@"MV: stop indicator");
    
    UIViewController *workingVC = nil;
    
    // get container view
    UIViewController *containerVC = [[AppUtility getAppDelegate] containerController];
    
    if (containerVC.modalViewController) {
        workingVC = containerVC.modalViewController;
    }
    else {
        workingVC = containerVC;
    }

    // check if there is one already
	UIActivityIndicatorView *indicatorView = (UIActivityIndicatorView *)[workingVC.view viewWithTag:kIndicatorTag];
    // background view
    UIView *backView = (UIView *)[workingVC.view viewWithTag:kBackViewTag];
    
    [indicatorView removeFromSuperview];
    [backView removeFromSuperview];
    
	/*for (UIView *iView in navController.view.subviews){
		if (iView.tag == kIndicatorTag){
			[iView removeFromSuperview];
		}
	}*/
}


/*!
 @abstract Shows a progress indicator view to let users know progress
 */
+ (void) showProgressOverlayForMessageID:(NSString *)msgID totalSize:(NSUInteger)totalSize {
	
    UIViewController *workingVC = nil;
    
    // get container view
    UIViewController *containerVC = [[AppUtility getAppDelegate] containerController];
    
    if (containerVC.modalViewController) {
        workingVC = containerVC.modalViewController;
    }
    else {
        workingVC = containerVC;
    }
    
    ProgressOverlayView *progressView = [[ProgressOverlayView alloc] initWithFrame:workingVC.view.bounds messageID:msgID totalSize:totalSize];
    progressView.tag = kProgressViewTag;
    [workingVC.view addSubview:progressView];
    [progressView release];
    
}

/*!
 @abstract Remove progress view
 
 */
+ (void) removeProgressOverlay { 
    
    UIViewController *workingVC = nil;
    
    // get container view
    UIViewController *containerVC = [[AppUtility getAppDelegate] containerController];
    
    if (containerVC.modalViewController) {
        workingVC = containerVC.modalViewController;
    }
    else {
        workingVC = containerVC;
    }
    
    // check if there is one already
	UIView *progressView = [workingVC.view viewWithTag:kProgressViewTag];    
    [progressView removeFromSuperview];
}


/*!
 @abstract show standard app alerts
 
 */
+ (void)showAlert:(AUAlertType)alertType { 
	
    NSString *title = nil;
    NSString *detMessage = nil;
    
    switch (alertType) {
        case kAUAlertTypeNetwork:
            title = NSLocalizedString(@"Network Unavailable", @"ChatList - alert: inform of failure");
            detMessage = NSLocalizedString(@"Make sure you have network connectivity and try again.", @"ChatList - alert: inform of failure");
            break;
            
        case kAUAlertTypeScheduledDeleteReject:
            title = NSLocalizedString(@"Delete Failed", @"Schedule - alert: inform of failure");
            detMessage = NSLocalizedString(@"Scheduled message cannot be deleted.", @"Schedule - alert: inform of failure");
            break;
            
        case kAUAlertTypeScheduledCreateReject:
            title = NSLocalizedString(@"Create Failed", @"Schedule - alert: inform of failure");
            detMessage = NSLocalizedString(@"Scheduled time must be more than 3 minutes later or less than 60 days from now.", @"Schedule - alert: inform of failure");
            break;
            
        case kAUAlertTypeNoTelephonyCall:
            title = NSLocalizedString(@"Call Failure", @"Call - alert: inform of failure");
            detMessage = NSLocalizedString(@"Device does not support Telephony.", @"Call - alert: device does not support calls");
            break;
            
        case kAUAlertTypeNoTelephonySMS:
            title = NSLocalizedString(@"Compose SMS Failure", @"SMS - alert: inform of failure");
            detMessage = NSLocalizedString(@"Device does not support SMS.", @"SMS - alert: device does not support SMS");
            break;
            
        case kAUAlertTypeComposeFailsureSMS:
            DDLogInfo(@"SMS send message failed");
            title = NSLocalizedString(@"Compose SMS Failure", @"SMS - alert: inform of failure");
            detMessage = NSLocalizedString(@"Failed to send SMS message.", @"SMS - alert: sms message failed to send out");
            break;
            
        case kAUAlertTypeEmailNoAccount:
            title = NSLocalizedString(@"Compose Email Failure", @"Email - alert: inform of failure");
            detMessage = NSLocalizedString(@"Email account setup is incomplete.", @"Email - alert: email account is not setup.");
            break;
    
            
        default:
            break;
    }
    
    if (title) {
        
        [Utility showAlertViewWithTitle:title message:detMessage];
        
    }
}


/*!
 @abstract Asks users permission to access contacts information
 
 */
+ (void) askAddressBookAccessPermissionAlertDelegate:(id)alertDelegate alertTag:(NSInteger)alertTag {
    
    NSString *title = NSLocalizedString(@"<access contacts title>", @"Phone Registration - Alert title: ask for contacts access");
    NSString *msg = NSLocalizedString(@"<access contacts message>", @"Phone Registration - Alert message: ask for contacts access");
    
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                     message:msg
                                                    delegate:alertDelegate
                                           cancelButtonTitle:NSLocalizedString(@"<access contacts deny>", @"Phone Registration: deny access to contacts") 
                                           otherButtonTitles:NSLocalizedString(@"<access contacts allow>", @"Phone Registration: allow acccess to contacts"), nil] autorelease];
    alert.tag = alertTag;
    [alert show];
}




#pragma mark - Button Methods

/*!
 @abstract Creates BarButtonItem of a given type
 
 Use:
 - create custom nav bar buttons
 
 */
+ (UIBarButtonItem *) barButtonWithTitle:(NSString *)title buttonType:(AUButtonType)buttonType target:(id)target action:(SEL)selector {
    
    
    if (buttonType == kAUButtonTypeBarNormal) {
        // regular button
        //
        UIBarButtonItem *regularButton = [[UIBarButtonItem alloc] initWithTitle:title 
                                                                          style:UIBarButtonItemStyleBordered 
                                                                         target:target 
                                                                         action:selector];
        return [regularButton autorelease];
        
        
        /*norImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_green6_nor.png"] leftCapWidth:9.0 topCapHeight:15.0];
         
         prsImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_green6_prs.png"] leftCapWidth:9.0 topCapHeight:15.0];
         [customButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
         customButton.titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.43];
         customButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);*/
    } 
    
    // highlighted buttons
    //
    
    
    UIButton *customButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    
    UIImage *norImage = nil;
    UIImage *prsImage = nil;
    UIImage *disImage = nil;
    
    if (buttonType == kAUButtonTypeBarHighlight) {
        norImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_yellow2_nor.png"] leftCapWidth:9.0 topCapHeight:15.0];
        
        prsImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_yellow2_prs.png"] leftCapWidth:9.0 topCapHeight:15.0];
        
        disImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_dis.png"] leftCapWidth:9.0 topCapHeight:15.0];
        
        [customButton setTitleColor:[AppUtility colorForContext:kAUColorTypeGreen1] forState:UIControlStateNormal];
        [customButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];

        //customButton.titleLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.83];
        //customButton.titleLabel.shadowColor = [UIColor colorWithRed:.99 green:.91 blue:.18 alpha:0.83];
        //customButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    }

    [customButton setBackgroundImage:norImage forState:UIControlStateNormal];
    [customButton setBackgroundImage:prsImage forState:UIControlStateHighlighted];
    [customButton setBackgroundImage:disImage forState:UIControlStateDisabled];

    [customButton setEnabled:YES];
    
    customButton.backgroundColor = [UIColor clearColor];
    customButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldMicroPlus];
    
    [customButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [customButton setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    //[customButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 11.0, 0.0, 0.0)];
    
    CGFloat labelWidth = [title sizeWithFont:customButton.titleLabel.font].width;
    if (labelWidth > 90.0) {
        labelWidth = 90.0;
    }
    if (labelWidth < 60.0) {
        labelWidth = 60.0;
    }
    [customButton setFrame:CGRectMake(0,0,labelWidth,32.0)];
    [customButton setTitle:title forState:UIControlStateNormal];
    
    [customButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem* barButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:customButton] autorelease];
    [customButton release];
    
    return barButtonItem;
}

#pragma mark - MP Methods


/*!
 @abstract get headshot file name
 */
+ (NSString *)headShotFilenameForUserID:(NSString *)userID {
    NSString *fileName = [NSString stringWithFormat:@"%@_headshot.png", userID];
    return fileName;
}

#pragma mark - Downloadable Content


/*!
 @abstract Gets the file path of the downloadable content
 
 Downloadable Content
 
 App Bundle:
 Downloadable content should be available initially in the bundle.  Each resource should also be localized into target languages.  
 
 Loading into App for use:
 When these resources are needed, the app will load the file from doc directory and NOT from bundle.  This is because these files need to be updated in the future.  The bundle files cannot be modified!  The following sequence are used to find and load a specific resource.
 
 Search order:
 1 - doc directory: <filename>_<iso language code>
 2 - doc directory: <filename>
 3 - bundle: <filename> then copy it over to the doc directory for future use.
 
 if user changes language setting:
 - try to find language specific file
 - fail over to last created default file
 
 Server update:
 - server should provide resource files for all languages supported: 
 e.g. <fileanme>_zh_TW, <filename>_zh_CN, <filename>_ja, <filename> (default file)
 - check if new version exists, if so then overwrite the file in the document directory
 
 Example:
 * status_zh_TW, status_zh_CN, status_ja, status (en default)
 - comma separated list of predefined status messages
 
 */
+ (NSString *) pathForDownloadableContentWithFilename:(NSString *)filename {
    
    NSString *localFilename = [NSString stringWithFormat:@"%@_%@", filename, [AppUtility devicePreferredLanguageCode]];
    NSString *filePath = [Utility documentFilePath:localFilename];
    
    // check if doc: filename_<iso language code> file exists
    //
    if ([Utility fileExistsAtDocumentFilePath:localFilename]){
        return filePath;
    }
    
    filePath = [Utility documentFilePath:filename];
    // - for testing only... [Utility deleteFileAtPath:filePath];
    // check if doc: filename exits
    //
    if ([Utility fileExistsAtDocumentFilePath:filename]){
        return filePath;
    }
    // finally get from bundle as last option
    //
    else {
        // copy it over file bundle
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:filename ofType:@""];
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] copyItemAtPath:bundlePath toPath:filePath error:&error];
        
        if (!success)
            NSAssert1(0, @"Failed to create writable file with message '%@'.", [error localizedDescription]);
        
        if (success) {
            return filePath;
        }
    }
    // error
    return nil;
}

@end
