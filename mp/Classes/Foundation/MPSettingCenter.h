//
//  MPSettingCenter.h
//  mp
//
//  Created by M Tsai on 11-8-29.
//  Copyright 2011年 TernTek. All rights reserved.
//

/*!
 @header MPSettingCenter
 
 MPSettingCenter provides a interface to all secure and non-secure settings.
 Methods are provided to read, write and configure settings.  MPSettingCenter
 is also responsible for updating setting information to the MP's network
 services.
 
 MPSettingCenter uses NSUserDefaults for non-secure backend and iOS KeyChain
 for secure storage.
 
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <Foundation/Foundation.h>


/*!
 @abstract CountryCodeLocale
 
 Determine which country this user has thir phone registered to.  Used to 
 determine what services are available.
 
 */
typedef enum {
    kCountryCodeLocaleUnknown,
	kCountryCodeLocaleTW,
    kCountryCodeLocaleJP,
    kCountryCodeLocaleCN,
    kCountryCodeLocaleHK
} CountryCodeLocale;



extern NSString* const kMPParamSettingDefaultNotificationTone;


/*! @group Profile Settings IDs */

/*! @abstract name shown to other users */
extern NSString* const kMPSettingNickName; 

/*! @abstract public status */
extern NSString* const kMPSettingStatus;         

/*! @abstract public headshot */
extern NSString* const kMPSettingHeadShot;

/*! @abstract alternative ID for finding users (instead of phonenumbers) */
extern NSString* const kMPSettingMPID;

/*! @abstract allow others to view presence */
extern NSString* const kMPSettingPresencePermission;

/*! @abstract allow MPID to be searched */
extern NSString* const kMPSettingMPIDSearch;

/*! @abstract country code and phonenumber */
extern NSString* const kMPSettingMSISDN;

/*!
 @abstract encrypted msisdn
 */
extern NSString* const kMPSettingMSISDNEncrypted;

/*! @abstract country code of user - no plus sign - NSString */
extern NSString* const kMPSettingPhoneCountryCode;

/*! @abstract phone number without country code */
extern NSString* const kMPSettingPhoneNumber;

/*! @abstract unique hardware ID */
extern NSString* const kMPSettingIMEI;

/*! @abstract agreed to EULA */
extern NSString* const kMPSettingEULAAgreed;

/*! @abstract was reverse ip lookup used - BOOL */
extern NSString* const kMPSettingTWM3GIPUsed;


/*! @group Network Setting IDs */

/*! @abstract domain server hostname - virtual IP of cluster */
extern NSString* const kMPSettingDomainClusterName;

/*! @abstract domain IP - actual IP of connected server */
extern NSString* const kMPSettingDomainServerName;

/*! @abstract authentication server hostname and port */
extern NSString* const kMPSettingServerAS;

/*! @abstract presence server hostname and port */ 
extern NSString* const kMPSettingServerPS;

/*! @abstract notification server hostname and port */
extern NSString* const kMPSettingServerNS;

/*! @abstract Request ResetAll not to reset the server params! - BOOL */
extern NSString* const kMPSettingServerDontResetMarker;


/*! @group Authentication Setting IDs */

/*! @abstract unique ID provided by MP Authentication Services */
extern NSString* const kMPSettingUserID;

/*!
 @abstract encrypted user ID
 */
extern NSString* const kMPSettingUserIDEncrypted;

/*! @abstract authentication key to connect to domain services */
extern NSString* const kMPSettingAuthKey;


/*! @group Message Setting IDs */

/*! 
 @abstract represents the number of message that was sent by user
 @discussion Used as a serial number to construct messageIDs
 */
extern NSString* const kMPSettingMessageCounter;


/*! @group Hidden Chat and Privacy Settings */

/*! 
 @abstract PIN number used for HiddenChat - NSString - default ""
 @discussion If defined, HiddenChat is enabled.  If not defined or valid, HiddenChat is disabled.
 */
extern NSString* const kMPSettingHiddenChatPIN;

/*! 
 @abstract Is hidden chat currently locked or unlocked - BOOL - default NO
 @discussion Indicates if HiddenChat is unlocked by the user for this session
 - hidden chat is relocked after entering background
 */
extern NSString* const kMPSettingHiddenChatIsLocked;

/*! 
 @abstract Address Book Access is Enabled - BOOL
 */
extern NSString* const kMPSettingAddressBookIsAllowed;



/*! @group Push Notification Setting IDs */

/*! 
 @abstract Is Popup alerts on (not group or p2p specific) - BOOL
 */
extern NSString* const kMPSettingPushPopUpIsOn;

/*! 
 @abstract Is P2P push notifiction on - BOOL
 */
extern NSString* const kMPSettingPushP2PAlertIsOn;

/*! 
 @abstract Is Group push notifiction on - BOOL
 */
extern NSString* const kMPSettingPushGroupAlertIsOn;

/*! 
 @abstract Is P2P push message preview on - BOOL
 */
extern NSString* const kMPSettingPushP2PPreviewIsOn;

/*! 
 @abstract Is Group push message preview on - BOOL
 */
extern NSString* const kMPSettingPushGroupPreviewIsOn;

/*! 
 @abstract Is P2P push ring tone - NSString
 */
extern NSString* const kMPSettingPushP2PRingTone;

/*! 
 @abstract Is Group push ring tone - NSString
 */
extern NSString* const kMPSettingPushGroupRingTone;

/*! 
 @abstract Is P2P In-app sound on - BOOL
 */
extern NSString* const kMPSettingPushP2PInAppIsSoundOn;

/*! 
 @abstract Is Group In-app sound on - BOOL
 */
extern NSString* const kMPSettingPushGroupInAppIsSoundOn;

/*! 
 @abstract Is P2P In-app vibrate on - BOOL
 */
extern NSString* const kMPSettingPushP2PInAppIsVibrateOn;

/*! 
 @abstract Is Group In-app vibrate on - BOOL
 */
extern NSString* const kMPSettingPushGroupInAppIsVibrateOn;




/*! @group App Internal Setting IDs */

/*! 
 @abstract used to store what the last contact recordID was sucessfully synced
 @discussion Lets app know where to start syncing from
 */
extern NSString* const kMPSettingPhoneSyncLastRecordID;

/*! 
 @abstract Last date when phone synce was completed - NSDate
 @discussion Used to figure out if we need to phone sync again automatically
 */
extern NSString* const kMPSettingPhoneSyncLastCompleteDate;

/*! 
 @abstract Last date when phone sync was completed - NSDate
 @discussion Used to figure out if we need to phone sync again automatically
 */
extern NSString* const kMPSettingPushNotificationRegisterLastCompleteDate;

/*! 
 @abstract BOOL - did user view friend list during this session?
 @discussion Determine if kMPSettingAppResignActiveAfterViewingFriendDate should be set and if we should clear badge count
 - YES if friend list appeared
 - NO whenever app becomes active
 */
extern NSString* const kMPSettingDidViewFriendInThisSession;

/*! 
 @abstract Last date when app has become inactive for a session when the user has viewed friend list
 @discussion Used to compare with new contacts/friends to see if they are new!
 */
extern NSString* const kMPSettingAppResignActiveAfterViewingFriendDate;


/*! 
 @abstract Did user view friend suggestion during this session? - BOOL
 @discussion Used to see if we should reset friend suggestion badge and detect new friend suggestions
 - YES if friend suggestion was viewed
 - NO whenever app becomes active
 */
extern NSString* const kMPSettingDidViewFriendSuggestionInThisSession;

/*! 
 @abstract Last date when app has entered background for a session when the user has viewed friend suggestion - NSDate
 @discussion Used to compare with new contacts to see if they are new friend suggestions!
 */
extern NSString* const kMPSettingAppEnterBackgroundAfterViewingFriendSuggestionDate;

/*! 
 @abstract Indicates the number of free sms still available - NSNumber
 @discussion Helps determine if we should allow free sms to tell friends about M+
 */
extern NSString* const kMPSettingFreeSMSLeftNumber;

/*! 
 @abstract The latest app version currently available for download
 @discussion Helps users notice if they should download a new version
 */
extern NSString* const kMPSettingLatestAppVersion;

/*! 
 @abstract The last version of app that was installed
 @discussion Used to detect if migration code should be executed
 */
NSString* const kMPSettingLastInstalledAppVersion;

/*! 
 @abstract What was the last phonebook contacts count - NSNumber
 @discussion Compared with current count to see if we need to run phonebook sync
 */
extern NSString* const kMPSettingLastPhoneBookContactCount;


/*! 
 @abstract Last system language setting that was applied
 @discussion Compare this to current language setting and decide if we should inform the NS,
 so push notif lang can also change immediately.
 */
extern NSString* const kMPSettingSystemLanguageLastUsed;


/*! 
 @abstract Last time that GetResource XML results was successfully updated to CD - string
 @discussion Submit to AS to check if new resources are needed
 */
extern NSString* const kMPSettingGetResourceLastUpateTime;

/*! 
 @abstract Last date when GetResource was checked - NSDate
 @discussion Controls frequency at which we check for new udpates
 */
extern NSString* const kMPSettingCheckResourceCompleteDate;


/*! 
 @abstract Should paid call warning be enabled? - BOOL nsnumber
 */
extern NSString* const kMPSettingEnablePayCallWarning;

/*! 
 @abstract Should paid sms warning be enabled? - BOOL nsnumber
 */
extern NSString* const kMPSettingEnablePaySMSWarning;

/*!
 @abstract Should paid invite sms warning be enabled? - BOOL nsnumber
 */
extern NSString* const kMPSettingEnablePayInviteWarning;

/*!
 @abstract List of actions already completed - NSString
 @discussion Helps execute code that should only be performed once after reinstall or delete
 
 Example:
 FSRecoverFriends                Ran Query and created and added each person as a friend
 FSLoadDefaultResourceInfo       Did load the default resource information from local file
 
 */
extern NSString* const kMPSettingFirstStartActionsCompletedTags;

// Available tags
extern NSString* const kMPSettingFirstStartTagRecoverFriends;
extern NSString* const kMPSettingFirstStartTagLoadPhotoAlbum;
extern NSString* const kMPSettingFirstStartTagLoadDefaultResourceInfo;



/*! 
 @abstract List of actions already completed for this session - NSString
 @discussion Helps execute code that should only be performed once for each user session
 
 Example:
 
 SATFriendInfoQuery     Queried for friend presence info - individual presence updates should keep session in sync
 
 */
extern NSString* const kMPSettingSessionActionsCompletedTags;
/*
 Available Tags
 */
extern NSString* const kMPSettingSessionActionTagFriendInfoQuery;


/*! @group User Configurable Setting IDs */

/*! 
 @abstract Preferred font size
 @discussion String value "normal" or "large"
 */
extern NSString* const kMPSettingUserFontSize;

/*! 
 @abstract Presence permission is on or off (NSNumberBool)
 @discussion determines if persence should be shown to others
 */
extern NSString* const kMPSettingUserPresencePermission;

/*! 
 @abstract Chat dialog state - defines appearance - NSNumberInt
 */
extern NSString* const kMPSettingChatDialogStateCode;


@interface MPSettingCenter : NSObject {
    
    NSCache *settingsCache;
    
}

/*! caches secure values for faster access */
@property (nonatomic, retain) NSCache *settingsCache;



/*!
 @abstract creates singleton object
 */
+ (MPSettingCenter *)sharedMPSettingCenter;

/*! 
 @abstract gets the setting's value 
 @param settingID setting identifier
 @return setting value if available
 */
- (id)valueForID:(NSString *)settingID;

/*! 
 @abstract sets the setting's value 
 @param settingID setting identifier
 @param value string value assigned to setting
 @return YES if successful
 */
- (BOOL)setValueForID:(NSString *)settingID settingValue:(id)value;

/*! 
 @abstract gets the setting's string value - secure version
 @param settingID setting identifier
 @return setting value if available
 */
- (id)secureValueForID:(NSString *)settingID;

/*! 
 @abstract sets the setting's string value - secure version
 @param settingID setting identifier
 @param value string value assigned to setting
 */
- (BOOL)setSecureValueForID:(NSString *)settingID settingValue:(id)value;

// write
//
- (void)setMyStatusMessage:(NSString *)statusMessage;


// first start tags
//
- (BOOL) didNotRunFirstStartTag:(NSString *)firstStartTag;
- (void) markFirstStartTagComplete:(NSString *)firstStartTag;


// registration
//
- (void)resetAllSettingsWithFullReset:(BOOL)fullReset;
+ (NSString *) encryptAESValue:(NSString *)value;
+ (NSString *) decryptAESValue:(NSString *)value;
- (NSString *) getUserID;
- (NSString *) getUserIDEncrypted;
- (NSString *) getMSISDN;
- (NSString *) getMSISDNEncrypted;
- (void) resetMSISDN;
- (CountryCodeLocale) getUserCountryCodeLocale;
- (NSString *)getNickName;
- (void) agreedToEULA;
- (BOOL) didAgreeToEULA;

// sec
//
- (BOOL) isAkeyAndClusterValid;

// phone book
//
- (NSNumber *) getPhoneSyncLastRecordID;
- (void) setPhoneSyncLastRecordID:(NSNumber *)recordID;
- (void) clearPhoneSyncLastRecordID;
- (BOOL) isPhoneSyncRunning;
- (NSDate *) getPhoneSyncCompleteDate;

- (void) setPhoneSyncCompleteDateToNow;
- (BOOL) isPhoneSyncFresh:(NSTimeInterval)secsConsideredFresh;

// Font settings
- (void) setFontSizeToLarge:(BOOL)isLarge;
- (BOOL) isFontSizeLarge;

// Hidden chat settings
- (NSString *) hiddenChatPIN;
- (void) setHiddenChatPIN:(NSString *)newPIN;
- (void) lockHiddenChat:(BOOL)lockChat;
- (BOOL) isHiddenChatLocked;

// session
- (BOOL) didSessionRunActionYet:(NSString *)actionTag runIt:(BOOL)runIt;

// system
- (BOOL) isAppUpToDate;
- (BOOL) isForceUpdateRequired;

@end
