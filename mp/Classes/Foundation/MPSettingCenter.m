//
//  MPSettingCenter.m
//  mp
//
//  Created by M Tsai on 11-8-29.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "MPSettingCenter.h"
#import "SynthesizeSingleton.h"
#import <AddressBook/AddressBook.h>

#import "TTKeyChainItem.h"
#import "MPHTTPCenter.h"
#import "CDContact.h"
#import "MPFoundation.h"
#import "MyAES.h"


/*! Default tone file name */
NSString* const kMPParamSettingDefaultNotificationTone = @"t1_witty.caf"; 


/*! @group User Setting IDs */

/*! @abstract name shown to other users */
NSString* const kMPSettingNickName = @"kMPSettingNickName"; 

/*! @abstract public status */
NSString* const kMPSettingStatus = @"kMPSettingStatus";         

/*! @abstract public headshot */
NSString* const kMPSettingHeadShot = @"kMPSettingHeadShot";

/*! @abstract alternative ID for finding users (instead of phonenumbers) */
NSString* const kMPSettingMPID = @"kMPSettingMPID";

/*! @abstract allow MPID to be searched */
NSString* const kMPSettingMPIDSearch = @"kMPSettingMPIDSearch";

/*! @abstract allow others to view presence */
NSString* const kMPSettingPresencePermission = @"kMPSettingPresencePermission";

/*! @abstract country code of user */
NSString* const kMPSettingPhoneCountryCode = @"kMPSettingPhoneCountryCode";

/*! @abstract phone number without country code */
NSString* const kMPSettingPhoneNumber = @"kMPSettingPhoneNumber";

/*! @abstract unique hardware ID */
NSString* const kMPSettingIMEI = @"kMPSettingIMEI";

/*! @abstract did agree to EULA - BOOL */
NSString* const kMPSettingEULAAgreed = @"kMPSettingEULAAgreed";

/*! @abstract was reverse ip lookup used - BOOL */
NSString* const kMPSettingTWM3GIPUsed = @"kMPSettingTWM3GIPUsed";

/*! @abstract country code and phonenumber */
NSString* const kMPSettingMSISDN = @"kMPSettingMSISDN";

/*!
 @abstract encrypted msisdn
 */
NSString* const kMPSettingMSISDNEncrypted = @"kMPSettingMSISDNEncrypted";




/*! @group Network Setting IDs */

/*! @abstract authentication server hostname and port */
NSString* const kMPSettingServerAS = @"kMPSettingServerAS";

/*! @abstract presence server hostname and port */
NSString* const kMPSettingServerPS = @"kMPSettingServerPS";

/*! @abstract notification server hostname and port */
NSString* const kMPSettingServerNS = @"kMPSettingServerNS";

/*! @abstract Request ResetAll not to reset the server params! - BOOL */
NSString* const kMPSettingServerDontResetMarker = @"kMPSettingServerDontResetMarker";

/*! @abstract domain server hostname */
NSString* const kMPSettingDomainClusterName = @"kMPSettingDomainClusterName";

/*! @abstract domain IP - actual IP of connected server */
NSString* const kMPSettingDomainServerName = @"kMPSettingDomainServerName";






/*! @group Authentication Setting IDs */

/*! 
 @abstract unique ID provided by MP Authentication Services - not secured so reinstall will not remember this ID
 */
NSString* const kMPSettingUserID = @"kMPSettingUserID";

/*!
 @abstract encrypted user ID
 */
NSString* const kMPSettingUserIDEncrypted = @"kMPSettingUserIDEncrypted";

/*! @abstract authentication key to connect to domain services */
NSString* const kMPSettingAuthKey = @"kMPSettingAuthKey";



/*! @group Message Setting IDs */

/*! 
 @abstract represents the number of message that was sent by user
 @discussion Used as a serial number to construct messageIDs
 */
NSString* const kMPSettingMessageCounter = @"kMPSettingMessageCounter";




/*! @group Hidden Chat and Privacy Settings */

/*! 
 @abstract PIN number used for HiddenChat - NSString - default ""
 @discussion If defined, HiddenChat is enabled.  If not defined or valid, HiddenChat is disabled.
 */
NSString* const kMPSettingHiddenChatPIN = @"kMPSettingHiddenChatPIN";

/*! 
 @abstract Is hidden chat currently locked or unlocked - BOOL - default NO
 @discussion Indicates if HiddenChat is unlocked by the user for this session
 - hidden chat is relocked after entering background
 */
NSString* const kMPSettingHiddenChatIsLocked = @"kMPSettingHiddenChatIsLocked";

/*! 
 @abstract Address Book Access is Enabled - BOOL
 */
NSString* const kMPSettingAddressBookIsAllowed = @"kMPSettingAddressBookIsAllowed";



/*! @group Push Notification Setting IDs */

/*! 
 @abstract Is Popup alerts on (not group or p2p specific) - BOOL
 */
NSString* const kMPSettingPushPopUpIsOn = @"kMPSettingPushPopUpIsOn";

/*! 
 @abstract Is P2P push notifiction on - BOOL
 */
NSString* const kMPSettingPushP2PAlertIsOn = @"kMPSettingPushP2PAlertIsOn";

/*! 
 @abstract Is Group push notifiction on - BOOL
 */
NSString* const kMPSettingPushGroupAlertIsOn = @"kMPSettingPushGroupAlertIsOn";

/*! 
 @abstract Is P2P push message preview on - BOOL
 */
NSString* const kMPSettingPushP2PPreviewIsOn = @"kMPSettingPushP2PPreviewIsOn";

/*! 
 @abstract Is Group push message preview on - BOOL
 */
NSString* const kMPSettingPushGroupPreviewIsOn = @"kMPSettingPushGroupPreviewIsOn";

/*! 
 @abstract Is P2P push ring tone - NSString
 */
NSString* const kMPSettingPushP2PRingTone = @"kMPSettingPushP2PRingTone";

/*! 
 @abstract Is Group push ring tone - NSString
 */
NSString* const kMPSettingPushGroupRingTone = @"kMPSettingPushGroupRingTone";

/*! 
 @abstract Is P2P In-app sound on - BOOL
 */
NSString* const kMPSettingPushP2PInAppIsSoundOn = @"kMPSettingPushP2PInAppIsSoundOn";

/*! 
 @abstract Is Group In-app sound on - BOOL
 */
NSString* const kMPSettingPushGroupInAppIsSoundOn = @"kMPSettingPushGroupInAppIsSoundOn";

/*! 
 @abstract Is P2P In-app vibrate on - BOOL
 */
NSString* const kMPSettingPushP2PInAppIsVibrateOn = @"kMPSettingPushP2PInAppIsVibrateOn";

/*! 
 @abstract Is Group In-app vibrate on - BOOL
 */
NSString* const kMPSettingPushGroupInAppIsVibrateOn = @"kMPSettingPushGroupInAppIsVibrateOn";






/*! @group App Internal Setting IDs */

/*! 
 @abstract used to store what the last contact recordID was sucessfully synced
 @discussion Lets app know where to pickup from if the last sync did not finish or is split up into parts.
 */
NSString* const kMPSettingPhoneSyncLastRecordID = @"kMPSettingPhoneSyncLastRecordID";

/*! 
 @abstract Last date when phone sync was completed - NSDate
 @discussion Used to figure out if we need to phone sync again automatically
 */
NSString* const kMPSettingPhoneSyncLastCompleteDate = @"kMPSettingPhoneSyncLastCompleteDate";

/*! 
 @abstract Last date when phone sync was completed - NSDate
 @discussion Used to figure out if we need to phone sync again automatically
 */
NSString* const kMPSettingPushNotificationRegisterLastCompleteDate = @"kMPSettingPushNotificationRegisterLastCompleteDate";

/*! 
 @abstract Did user view friend list during this session? - BOOL
 @discussion Used to see if we should reset friend badge and detect new friends
  - YES if friend list appeared
  - NO whenever app becomes active
 */
NSString* const kMPSettingDidViewFriendInThisSession = @"kMPSettingDidViewFriendInThisSession";

/*! 
 @abstract Last date when app has become inactive for a session when the user has viewed friend list - NSDate
 
 @discussion Used to compare with new contacts/friends to see if they are new!
 */
NSString* const kMPSettingAppResignActiveAfterViewingFriendDate = @"kMPSettingAppResignActiveAfterViewingFriendDate";

/*! 
 @abstract Did user view friend suggestion during this session? - BOOL
 @discussion Used to see if we should reset friend suggestion badge and detect new friend suggestions
 - YES if friend suggestion was viewed
 - NO whenever app becomes active
 */
NSString* const kMPSettingDidViewFriendSuggestionInThisSession = @"kMPSettingDidViewFriendSuggestionInThisSession";

/*! 
 @abstract Last date when app has entered background for a session when the user has viewed friend suggestion - NSDate
 
 @discussion Used to compare with new contacts to see if they are new friend suggestions!
 */
NSString* const kMPSettingAppEnterBackgroundAfterViewingFriendSuggestionDate = @"kMPSettingAppEnterBackgroundAfterViewingFriendSuggestionDate";



/*! 
 @abstract Indicates the number of free sms still available - NSNumber
 @discussion Helps determine if we should allow free sms to tell friends about M+
 */
NSString* const kMPSettingFreeSMSLeftNumber = @"kMPSettingFreeSMSLeftNumber";


/*! 
 @abstract The latest app version currently available for download
 @discussion Helps users notice if they should download a new version
 */
NSString* const kMPSettingLatestAppVersion = @"kMPSettingLatestAppVersion";



/*! 
 @abstract The last version of app that was installed
 @discussion Used to detect if migration code should be executed
 */
NSString* const kMPSettingLastInstalledAppVersion = @"kMPSettingLastInstalledAppVersion";


/*! 
 @abstract What was the last phonebook contacts count - NSNumber
 @discussion Compared with current count to see if we need to run phonebook sync
 */
NSString* const kMPSettingLastPhoneBookContactCount = @"kMPSettingLastPhoneBookContactCount";


/*! 
 @abstract Last system language setting that was applied
 @discussion Compare this to current language setting and decide if we should inform the NS,
             so push notif lang can also change immediately.
 */
NSString* const kMPSettingSystemLanguageLastUsed = @"kMPSettingSystemLanguageLastUsed";


/*! 
 @abstract Last time that GetResource XML results was successfully updated to CD - string
 @discussion Submit to AS to check if new resources are needed
 */
NSString* const kMPSettingGetResourceLastUpateTime = @"kMPSettingGetResourceLastUpateTime";

/*! 
 @abstract Last date when GetResource was checked - NSDate
 @discussion Controls frequency at which we check for new udpates
 */
NSString* const kMPSettingCheckResourceCompleteDate = @"kMPSettingCheckResourceCompleteDate";


/*! 
 @abstract Should paid call warning be enabled? - BOOL nsnumber
 */
NSString* const kMPSettingEnablePayCallWarning = @"kMPSettingEnablePayCallWarning";

/*! 
 @abstract Should paid sms warning be enabled? - BOOL nsnumber
 */
NSString* const kMPSettingEnablePaySMSWarning = @"kMPSettingEnablePaySMSWarning";

/*!
 @abstract Should paid invite sms warning be enabled? - BOOL nsnumber
 */
NSString* const kMPSettingEnablePayInviteWarning = @"kMPSettingEnablePayInviteWarning";


/*! 
 @abstract List of actions already completed - NSString
 @discussion Helps execute code that should only be performed once after reinstall or delete
 
 Example:
    FSRecoverFriends                Ran Query and created and added each person as a friend
    FSLoadDefaultResourceInfo       Did load the default resource information from local file

 */
NSString* const kMPSettingFirstStartActionsCompletedTags = @"kMPSettingFirstStartActionsCompletedTags";
/*
 Available Tags
 */
NSString* const kMPSettingFirstStartTagRecoverFriends = @"FSRecoverFriends";
NSString* const kMPSettingFirstStartTagLoadPhotoAlbum = @"FSLoadPhotoAlbum";
NSString* const kMPSettingFirstStartTagLoadDefaultResourceInfo = @"FSLoadDefaultResourceInfo";



/*! 
 @abstract List of actions already completed for this session - NSString
 @discussion Helps execute code that should only be performed once for each user session
 
 Example:

 SATFriendInfoQuery     Queried for friend presence info - individual presence updates should keep session in sync
 
 */
NSString* const kMPSettingSessionActionsCompletedTags = @"kMPSettingSessionActionsCompletedTags";
/*
 Available Tags
 */
NSString* const kMPSettingSessionActionTagFriendInfoQuery = @"SATFriendInfoQuery";







/*! @group User Configurable Setting IDs */

/*! 
 @abstract Preferred font size (String value "normal" or "large")
 @discussion 
 */
NSString* const kMPSettingUserFontSize = @"kMPSettingUserFontSize";

/*! 
 @abstract Presence permission is on or off (NSNumberBool)
 @discussion determines if persence should be shown to others
 */
NSString* const kMPSettingUserPresencePermission = @"kMPSettingUserPresencePermission";


/*! 
 @abstract Chat dialog state - defines appearance - NSNumberInt
 */
NSString* const kMPSettingChatDialogStateCode = @"kMPSettingSVStateCode";








@implementation MPSettingCenter

@synthesize settingsCache;

SYNTHESIZE_SINGLETON_FOR_CLASS(MPSettingCenter);


#pragma mark - Instance

/*!
 Getter for value cache
 
 Use:
 - to read secure values (is hidden chat) since it is expensive to access keychain every time.
 
 */
- (NSCache *)settingsCache {
    if (!settingsCache) {
        settingsCache = [[NSCache alloc] init];
    }
    return settingsCache;
}


#pragma mark - Generic Setting Methods

/*! 
 @abstract gets the setting's value 
 @param settingID setting identifier
 @return setting value if available
 */
- (id)valueForID:(NSString *)settingID{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//[defaults synchronize]; - use cache for now
	id retValue = [defaults valueForKey:settingID];

	return retValue;
}

/*! 
 @abstract sets the setting's value 
 @param settingID setting identifier
 @param value string value assigned to setting
 @return YES if successful
 */
- (BOOL)setValueForID:(NSString *)settingID settingValue:(id)value{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	// don't use cache
	[defaults synchronize];
    [defaults setValue:value forKey:settingID];
	return YES;
}

/*! 
 @abstract gets the setting's string value - secure version
 @param settingID setting identifier
 @return setting value if available
 */
- (id)secureValueForID:(NSString *)settingID{
    
    // check cache
    id secureValue = [self.settingsCache objectForKey:settingID];
    
    // fall back on keychain
    if (!secureValue) {
        TTKeyChainItem *secureItem = [[TTKeyChainItem alloc] initWithIdentifier:settingID accessGroup:nil];
        secureValue = [secureItem objectForKey:(id)kSecValueData];
        [secureItem release];
        
        // cache it
        if (secureValue) {
            [self.settingsCache setObject:secureValue forKey:settingID];
        }
    }
    
    return secureValue;
}

/*! 
 @abstract sets the setting's string value - secure version
 @param settingID setting identifier
 @param value string value assigned to setting
 */
- (BOOL)setSecureValueForID:(NSString *)settingID settingValue:(id)value{
    
    TTKeyChainItem *secureItem = [[TTKeyChainItem alloc] initWithIdentifier:settingID accessGroup:nil];
    [secureItem setObject:value forKey:(id)kSecValueData];
    [secureItem release];
    
    // cache it
    [self.settingsCache setObject:value forKey:settingID];
    
    return YES;
}

#pragma mark - Write Methods

/*!
 @abstract reset all settings
 
 @param fullReset   Not used - but in case we don't want to reset some parameters
 
 Use:
 - if EULA shows up!
 - when user request account deletion
 
 Note:
 - all setting should be set to default value here!
 kMPSettingMessageCounter - not reset to ensure messages are unique after reset
 */
- (void)resetAllSettingsWithFullReset:(BOOL)fullReset {
    
    // user info
    [self setValueForID:kMPSettingNickName settingValue:@""];
    [self setValueForID:kMPSettingStatus settingValue:@""];
    [self setValueForID:kMPSettingHeadShot settingValue:@""];
    [self setValueForID:kMPSettingMPID settingValue:@""];
    [self setValueForID:kMPSettingMPIDSearch settingValue:[NSNumber numberWithBool:YES]];
    [self setValueForID:kMPSettingPresencePermission settingValue:[NSNumber numberWithBool:YES]];
    [self setValueForID:kMPSettingMSISDN settingValue:@""];
    [self setValueForID:kMPSettingMSISDNEncrypted settingValue:@""];
    [self setValueForID:kMPSettingPhoneCountryCode settingValue:@""];
    [self setValueForID:kMPSettingPhoneNumber settingValue:@""];
    [self setValueForID:kMPSettingIMEI settingValue:@""];
    [self setValueForID:kMPSettingEULAAgreed settingValue:[NSNumber numberWithBool:NO]];
    [self setValueForID:kMPSettingTWM3GIPUsed settingValue:[NSNumber numberWithBool:NO]];
    
    // network 
    [self setValueForID:kMPSettingDomainClusterName settingValue:@""];
    [self setValueForID:kMPSettingDomainServerName settingValue:@""];
    
    
    BOOL dontReset = [[self valueForID:kMPSettingServerDontResetMarker] boolValue];
    if (!dontReset) {        
        
        // Configure Server Settings
        [self setValueForID:kMPSettingServerAS settingValue:kMPParamNetworkMPServerPort];
        [self setValueForID:kMPSettingServerPS settingValue:kMPParamNetworkMPServerPort];
        [self setValueForID:kMPSettingServerNS settingValue:kMPParamNetworkMPServerPort];
        
        
        //[self setValueForID:kMPSettingServerDontResetMarker settingValue:[NSNumber numberWithBool:NO]];

        [[MPHTTPCenter sharedMPHTTPCenter] loadServerHostInfo];
    }
    
    /*
     NSString* const kMPParamServerAS = @"61.66.229.106:8080";
     NSString* const kMPParamServerPS = @"61.66.229.106:8080";
     NSString* const kMPParamServerNS = @"61.66.229.106:8080";
     */
    
    // secure
    [self setValueForID:kMPSettingUserID settingValue:@""];
    [self setValueForID:kMPSettingUserIDEncrypted settingValue:@""];
    [self setSecureValueForID:kMPSettingAuthKey settingValue:@""];
    
    // app internal 
    [self setValueForID:kMPSettingPhoneSyncLastRecordID settingValue:[NSNumber numberWithInt:-1]];
    [self setValueForID:kMPSettingPhoneSyncLastCompleteDate settingValue:[NSDate dateWithTimeIntervalSince1970:0.0]];
    [self setValueForID:kMPSettingPushNotificationRegisterLastCompleteDate settingValue:[NSDate dateWithTimeIntervalSince1970:0.0]];
    [self setValueForID:kMPSettingDidViewFriendInThisSession settingValue:[NSNumber numberWithBool:NO]];
    // always show new friends even on first launch
    [self setValueForID:kMPSettingAppResignActiveAfterViewingFriendDate settingValue:[NSDate dateWithTimeIntervalSince1970:0.0]];
    [self setValueForID:kMPSettingDidViewFriendSuggestionInThisSession settingValue:[NSNumber numberWithBool:NO]];
    // always show new friends even on first launch
    [self setValueForID:kMPSettingAppEnterBackgroundAfterViewingFriendSuggestionDate settingValue:[NSDate dateWithTimeIntervalSince1970:0.0]];
    [self setValueForID:kMPSettingFreeSMSLeftNumber settingValue:[NSNumber numberWithInt:0]];
    [self setValueForID:kMPSettingLatestAppVersion settingValue:@""];
    [self setValueForID:kMPSettingGetResourceLastUpateTime settingValue:@"1000"]; // old epoch time, so will get download
    [self setValueForID:kMPSettingCheckResourceCompleteDate settingValue:[NSDate dateWithTimeIntervalSince1970:0.0]];
    [self setValueForID:kMPSettingFirstStartActionsCompletedTags settingValue:@""];
    [self setValueForID:kMPSettingSessionActionsCompletedTags settingValue:@""];
    [self setValueForID:kMPSettingSystemLanguageLastUsed settingValue:@""];
    
    // telelphony warnings
    [self setValueForID:kMPSettingEnablePayCallWarning settingValue:[NSNumber numberWithBool:YES]];
    [self setValueForID:kMPSettingEnablePaySMSWarning settingValue:[NSNumber numberWithBool:YES]];
    [self setValueForID:kMPSettingEnablePayInviteWarning settingValue:[NSNumber numberWithBool:YES]];
    
    
    // user settings
    [self setValueForID:kMPSettingUserFontSize settingValue:@"normal"];
    [self setValueForID:kMPSettingUserPresencePermission settingValue:[NSNumber numberWithBool:YES]];
    [self setValueForID:kMPSettingChatDialogStateCode settingValue:[NSNumber numberWithInt:0]];


    // hidden chat (secured) and privacy
    [self setSecureValueForID:kMPSettingHiddenChatPIN settingValue:@""];
    [self setSecureValueForID:kMPSettingHiddenChatIsLocked settingValue:[NSNumber numberWithBool:YES]];
    [self setValueForID:kMPSettingAddressBookIsAllowed settingValue:[NSNumber numberWithBool:NO]];
    
    // push notification
    [self setValueForID:kMPSettingPushPopUpIsOn settingValue:[NSNumber numberWithBool:YES]];
    [self setValueForID:kMPSettingPushP2PAlertIsOn settingValue:[NSNumber numberWithBool:YES]];
    [self setValueForID:kMPSettingPushGroupAlertIsOn settingValue:[NSNumber numberWithBool:YES]];
    
    [self setValueForID:kMPSettingPushP2PPreviewIsOn settingValue:[NSNumber numberWithBool:YES]];
    [self setValueForID:kMPSettingPushGroupPreviewIsOn settingValue:[NSNumber numberWithBool:YES]];
    
    [self setValueForID:kMPSettingPushP2PRingTone settingValue:kMPParamSettingDefaultNotificationTone];
    [self setValueForID:kMPSettingPushGroupRingTone settingValue:kMPParamSettingDefaultNotificationTone];
    
    [self setValueForID:kMPSettingPushP2PInAppIsSoundOn settingValue:[NSNumber numberWithBool:YES]];
    [self setValueForID:kMPSettingPushGroupInAppIsSoundOn settingValue:[NSNumber numberWithBool:YES]];
    [self setValueForID:kMPSettingPushP2PInAppIsVibrateOn settingValue:[NSNumber numberWithBool:NO]];
    [self setValueForID:kMPSettingPushGroupInAppIsVibrateOn settingValue:[NSNumber numberWithBool:NO]];

    //[self setValueForID: settingValue:@""];
}


/*!
 @abstract Set my status message
 */
- (void)setMyStatusMessage:(NSString *)statusMessage {
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingStatus settingValue:statusMessage];
    [CDContact updateMyNickname:nil domainClusterName:nil domainServerName:nil statusMessage:statusMessage];
}

#pragma mark - First Start Tag Management


/*!
 @abstract Query if a particular tag ran already
 
 @return NO if did ran already, YES if did not run yet
 
 */
- (BOOL) didNotRunFirstStartTag:(NSString *)firstStartTag {
    // request helper if needed
    NSString *firstTags = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingFirstStartActionsCompletedTags];
    
    if (firstTags && [firstTags rangeOfString:firstStartTag].location != NSNotFound) {
        return NO;
    }
    return YES;
}
    
/*!
 @abstract Mark action as being complete
  
 */
- (void) markFirstStartTagComplete:(NSString *)firstStartTag {
    
    NSString *firstTags = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingFirstStartActionsCompletedTags];
    
    NSString *newTags = nil;
    
    if (!firstTags || [firstTags length] == 0) {
        newTags = firstStartTag;
    }
    else {
        newTags = [firstTags stringByAppendingFormat:@",%@", firstStartTag];
    }
    
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingFirstStartActionsCompletedTags settingValue:newTags];
    
}

#pragma mark - Query UserID and MSISDN Methods

/*!
 @abstract get the users own userID
 */
+ (NSString *) encryptAESValue:(NSString *)value {
    return [MyAES AES128EncryptWithValue:value];
}

/*!
 @abstract get the users own userID
 */
+ (NSString *) decryptAESValue:(NSString *)value {
    if ([value length] > 0) {
        return [MyAES AES128DecryptWithValue:value];
    }
    return value;
}


/*!
 @abstract get the users own userID
 */
- (NSString *)getUserID {
    return [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingUserID];
}

/*!
 @abstract get the users own userID
 */
- (NSString *)getUserIDEncrypted {
    NSString *encryptedID = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingUserIDEncrypted];
    
    if ([encryptedID length] > 1) {
        return encryptedID;
    }
    
    NSString *userID = [self getUserID];
    if ([userID length] > 1) {
        encryptedID = [MyAES AES128EncryptWithValue:userID];
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingUserIDEncrypted settingValue:encryptedID];
        return encryptedID;
    }
    return nil;
}


/*!
 @abstract get user's msisdn
 */
- (NSString *) getMSISDN {
    return [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingMSISDN];
}

/*!
 @abstract get user's msisdn
 */
- (NSString *) getMSISDNEncrypted {
    NSString *encryptedMSISDN = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingMSISDNEncrypted];
    
    if ([encryptedMSISDN length] > 1) {
        return encryptedMSISDN;
    }
    
    NSString *msisdn = [self getMSISDN];
    if ([msisdn length] > 1) {
        encryptedMSISDN = [MyAES AES128EncryptWithValue:msisdn];
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingMSISDNEncrypted settingValue:encryptedMSISDN];
        return encryptedMSISDN;
    }
    return nil;
}

/*!
 @abstract resets registered phone number
 */
- (void)resetMSISDN {
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingMSISDN settingValue:@""];
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingMSISDNEncrypted settingValue:@""];
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPhoneNumber settingValue:@""];
}

#pragma mark - Query Methods


/*!
 @abstract Is this user from Taiwan
 
 Use:
 - determine if local services are provided
 */
- (CountryCodeLocale) getUserCountryCodeLocale {
    NSString *countryCode =  [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPhoneCountryCode];
    
    NSInteger countryCodeInt = [countryCode intValue];
    
    switch (countryCodeInt) {
        case 886:
            return kCountryCodeLocaleTW;
            break;
            
        case 81:
            return kCountryCodeLocaleJP;
            break;
            
        case 86:
            return kCountryCodeLocaleCN;
            break;
            
        case 852:
            return kCountryCodeLocaleHK;
            break;
            
        default:
            return kCountryCodeLocaleUnknown;
            break;
    }
}

/*!
 @abstract get user's nickname
 */
- (NSString *)getNickName {
    return [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingNickName];
}


/*!
 @abstract agreed to EULA
 */
- (void) agreedToEULA {
    
    [self setValueForID:kMPSettingEULAAgreed settingValue:[NSNumber numberWithBool:YES]];
}

/*!
 @abstract check if did agree to EULA
 */
- (BOOL) didAgreeToEULA {
    
    NSNumber *didAgree = [self valueForID:kMPSettingEULAAgreed];
    if (didAgree != nil) {
        return [didAgree boolValue];
    }
    return NO;
}

/*!
 @abstract get the last record that was synced
 */
- (NSNumber *) getPhoneSyncLastRecordID {
    
    NSNumber *recordID = [self valueForID:kMPSettingPhoneSyncLastRecordID];
    
    if (recordID) {
        return recordID;
    }
    // return negative number to represent sync was not in progress
    else {
        return [NSNumber numberWithInt:-1];
    }
}

/*!
 @abstract record the last record that was synced
 */
- (void) setPhoneSyncLastRecordID:(NSNumber *)recordID {
    
    [self setValueForID:kMPSettingPhoneSyncLastRecordID settingValue:recordID];
}

/*!
 @abstract clear out the last sync record, so we know sync is done
 */
- (void) clearPhoneSyncLastRecordID {
    
    [self setValueForID:kMPSettingPhoneSyncLastRecordID settingValue:[NSNumber numberWithInt:kABRecordInvalidID]];
}

/*!
 @abstract checks if phone sync is currently running
 */
- (BOOL) isPhoneSyncRunning {
    
    NSNumber *runningNum = [self getPhoneSyncLastRecordID];
    if ([runningNum intValue] == kABRecordInvalidID) {
        return NO;
    }
    return YES;
}

/*!
 @abstract sets the phone sync complete date to now. Used when we finish complete a sync.
 
 @discussion call this whenever phone sync is complete.  It cleans up settings.
 */
- (void) setPhoneSyncCompleteDateToNow {
    
    // also clear out the last record ID, so we will know we are done!
    [self clearPhoneSyncLastRecordID];
    [self setValueForID:kMPSettingPhoneSyncLastCompleteDate settingValue:[NSDate date]];
    
}

/*!
 @abstract gets last sync date
 */
- (NSDate *) getPhoneSyncCompleteDate {
    return [self valueForID:kMPSettingPhoneSyncLastCompleteDate];
}

/*!
 @abstract checks if last phone sync is fresh according to fresh seconds: now-fresh (older than) last complete date
 */
- (BOOL) isPhoneSyncFresh:(NSTimeInterval)secsConsideredFresh {

    NSDate *lastCompleteDate = [self valueForID:kMPSettingPhoneSyncLastCompleteDate];
    
	NSDate *checkDate = [[NSDate alloc] initWithTimeIntervalSinceNow:secsConsideredFresh*(-1.0f)]; // neg to go into past
	BOOL answer = NO;
	if ([lastCompleteDate compare:checkDate] == NSOrderedDescending) {
		answer = YES;
	}
	[checkDate release];
	return answer;
}


/*!
 @abstract Did this session run this action tag yet?
 
 @param actionTag   Action tag of interest
 @param runIt       Mark this action as done if it is not already
 
 */
- (BOOL) didSessionRunActionYet:(NSString *)actionTag runIt:(BOOL)runIt {
    
    BOOL didRun = NO;
    NSString *sessionTags = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingSessionActionsCompletedTags];
    
    if (sessionTags && [sessionTags rangeOfString:actionTag].location != NSNotFound) {
        didRun = YES;
    }
    
    // run if it has not
    if (didRun == NO && runIt) {
        NSString *newTags = nil;
        if (!sessionTags || [sessionTags length] == 0) {
            newTags = actionTag;
        }
        else {
            newTags = [sessionTags stringByAppendingFormat:@",%@", actionTag];
        }
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingSessionActionsCompletedTags settingValue:newTags];
    }

    return didRun;
}


/*!
 @abstract Is app version the latest
 
 */
- (BOOL) isAppUpToDate {
    
    NSString *latestVersion = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingLatestAppVersion];
    NSString *currentVersion = [AppUtility getAppVersion];

    if ([latestVersion compare:currentVersion options:NSNumericSearch] == NSOrderedDescending){
        return NO;
    }
    else {
        return YES;
    }
}

/*!
 @abstract Should we force update this app
 
 Deprecated - force update only when server informs us via login response
 
 */
- (BOOL) isForceUpdateRequired {
    
    NSString *latestVersion = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingLatestAppVersion];
    NSString *currentVersion = [AppUtility getAppVersion];
    
    NSArray *currentParts = [currentVersion componentsSeparatedByString:@"."];
    NSArray *latestParts = [latestVersion componentsSeparatedByString:@"."];
    
    // both valid
    if ([currentParts count] > 2 && [latestParts count] > 2) {
        
        // if either 1 and 2 parts don't match
        // - then update
        if (![[currentParts objectAtIndex:0] isEqualToString:[latestParts objectAtIndex:0]] ||
            ![[currentParts objectAtIndex:1] isEqualToString:[latestParts objectAtIndex:1]]
            ) {
            
            return YES;
        }
    }
    return NO;
}


/*!
 @abstract Checks if the Akey and cluster valid
 - If not we need to authenticate again
 
 */
- (BOOL) isAkeyAndClusterValid
{
    NSString *aKey = [self secureValueForID:kMPSettingAuthKey];
    NSString *cluster = [self valueForID:kMPSettingDomainClusterName];
    if ([aKey length] > 3 && [cluster length] > 3) {
        return YES;
    }
    return NO;
}

#pragma mark - Font Settings

/*!
 @abstract set font size
 @param if not isLarge, then set to normal
 */
- (void) setFontSizeToLarge:(BOOL)isLarge {
    
    if (isLarge) {
        [self setValueForID:kMPSettingUserFontSize settingValue:@"large"];
    }
    else {
        [self setValueForID:kMPSettingUserFontSize settingValue:@"normal"];
    }
}

/*!
 @abstract query font size
 @param YES if large, NO if normal
 */
- (BOOL) isFontSizeLarge {
    
    NSString *fontSize = [self valueForID:kMPSettingUserFontSize];
    if ([fontSize isEqualToString:@"large"]) {
        return YES;
    }
    return NO;
}

#pragma mark - Hidden Chat Settings

/*!
 @abstract get hidden chat PIN string
 @return PIN is valid, nil if invalid
 
 */
- (NSString *) hiddenChatPIN {
    
    NSString *pin = [self secureValueForID:kMPSettingHiddenChatPIN];
    
    NSCharacterSet *nonDigit = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    
    NSRange nonDigitRange = [pin rangeOfCharacterFromSet:nonDigit];
    
    // valid digit
    if (nonDigitRange.location == NSNotFound && [pin length] == 4) {
        return pin;
    }
    return nil;
}

/*!
 @abstract set a new PIN for hidden chat
 @param: newPIN New PIN code
 */
- (void) setHiddenChatPIN:(NSString *)newPIN {
    
    [self setSecureValueForID:kMPSettingHiddenChatPIN settingValue:newPIN];
    
}

/*!
 @abstract lock or unlock hidden chat
 @param lockChat YES to lock, NO to unlock
 
 */
- (void) lockHiddenChat:(BOOL)lockChat {
    [self setSecureValueForID:kMPSettingHiddenChatIsLocked settingValue:[NSNumber numberWithBool:lockChat]];
}

/*!
 @abstract check lock state of hidden chat
 
 */
- (BOOL) isHiddenChatLocked {
    return [[self secureValueForID:kMPSettingHiddenChatIsLocked] boolValue];
}


@end
