//
//  MPSecurityCenter.h
//  mp
//
//  Created by M Tsai on 11-8-30.
//  Copyright 2011年 TernTek. All rights reserved.
//

/*!
 @header MPSecurityCenter
 
 MPSecurityCenter provides access to all security related services. It
 encapsulates network connections and parsing of XML responses.
 
 Query process
 - generated URL query
 - wait for response
 - process XML response
 - send Notification for response
 - notification listener handles response

 
 @copyright TernTek
 @updated 2011-08-30
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <Foundation/Foundation.h>
#import "TTURLConnection.h"
#import "TTXMLParser.h"
#import "MPFoundation.h"
#import <MapKit/MapKit.h>


// Google MAP
// json result keys
extern NSString* const kMPHCJsonKeyJsonObject;
extern NSString* const kMPHCJsonKeyResults;                    // geocode results array
extern NSString* const kMPHCJsonKeyStatus;              // get result status
extern NSString* const kMPHCJsonKeyFormattedAddress;    // get geocode formatted address
extern NSString* const kMPHCJsonKeyGeometry;            // place: geo->loc->lat & lng
extern NSString* const kMPHCJsonKeyLocation;
extern NSString* const kMPHCJsonKeyLatitude;
extern NSString* const kMPHCJsonKeyLongitude;
extern NSString* const kMPHCJsonKeyName;
extern NSString* const kMPHCJsonKeyVicinity;

extern NSString* const kMPHCRequestTypeMapGeocode;
extern NSString* const kMPHCRequestTypeMapPlaceSearch;

extern NSString* const MP_HTTPCENTER_FORWARD_GEOCODE_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_REVERSE_GEOCODE_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_PLACE_SEARCH_NOTIFICATION;



// define request tags to ID connections
//
extern NSString* const kMPHCRequestTypeGetResourceDownloadInfo;
extern NSString* const kMPHCRequestTypeCancel;
extern NSString* const kMPHCRequestTypeIPQueryMSISDN;
extern NSString* const kMPHCRequestTypeCreateMPID;
extern NSString* const kMPHCRequestTypeSearchMPID;
extern NSString* const kMPHCRequestTypeCloseMPID;
extern NSString* const kMPHCRequestTypeOpenMPID;
extern NSString* const kMPHCRequestTypeUpdateNickname;
extern NSString* const kMPHCRequestTypeUpdateStatus;
extern NSString* const kMPHCRequestTypeBlock;
extern NSString* const kMPHCRequestTypeUnBlock;
extern NSString* const kMPHCRequestTypePresencePermission;
extern NSString* const kMPHCRequestTypeSMS;
extern NSString* const kMPHCRequestTypeSendHelperMessage;

// Push Notification
extern NSString* const kMPHCRequestTypeSetPushTokenID;
extern NSString* const kMPHCRequestTypeSetPushNotify;
extern NSString* const kMPHCRequestTypeSetPNPreview;
extern NSString* const kMPHCRequestTypeSetPNHidden;
extern NSString* const kMPHCRequestTypeSetPushRingTone;


extern NSString* const MP_HTTPCENTER_IPQUERY_MSISDN_NOTIFICATION;

extern NSString* const MP_HTTPCENTER_CONNECT_FAILED_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_CODE_VERIFICATION_SUCCESS;
extern NSString* const MP_HTTPCENTER_CODE_VERIFICATION_FAILURE;

extern NSString* const MP_HTTPCENTER_MSISDN_SUCCESS_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_MSISDN_MULTIDEVICE_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_AUTHENTICATION_NOTIFICATION;


extern NSString* const MP_HTTPCENTER_CREATEID_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_SEARCHID_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_CLOSEID_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_OPENID_NOTIFICATION;

extern NSString* const MP_HTTPCENTER_UPDATE_NICKNAME_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_UPDATE_STATUS_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_UPDATE_HEADSHOT_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_GETUSERINFO_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_GETUSERINFO_ADD_NOTIFICATION;

extern NSString* const MP_HTTPCENTER_BLOCK_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_UNBLOCK_NOTIFICATION;

extern NSString* const MP_HTTPCENTER_PRESENCEPERMISSION_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_CANCEL_NOTIFICATION;

extern NSString* const MP_HTTPCENTER_QUERYOPERATOR_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_SMS_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_SEND_HELPER_MESSAGE_NOTIFICATION;

extern NSString* const kMPHCQueryTag;
extern NSString* const kMPHCQueryTagAdd;
extern NSString* const kMPHCQueryTagAddPhoneSync;
extern NSString* const kMPHCQueryTagQuery;
extern NSString* const kMPHCQueryTagQueryNoArguments; // query with out any arguments
extern NSString* const kMPHCQueryTagSuggestion;
extern NSString* const kMPHCQueryTagRefersh;
extern NSString* const kMPHCQueryTagRemove;
extern NSString* const kMPHCQueryIDTagBlockedRecovery;

// item type for getUserInfo
extern NSString* const kMPHCItemTypePhone;
extern NSString* const kMPHCItemTypeUserID;


// Push NS 
extern NSString* const MP_HTTPCENTER_SET_PUSH_NOTIFY_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_SET_PN_PREVIEW_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_SET_PN_HIDDEN_NOTIFICATION;
extern NSString* const MP_HTTPCENTER_SET_PUSH_RINGTONE_NOTIFICATION;





@interface MPHTTPCenter : NSObject <TTURLConnectionDelegate, TTXMLParserDelegate> {
    
    NSMutableArray *connections;
    NSMutableArray *parsers;
    
    NSString *serverHostAS;
    NSString *serverHostPS;
    NSString *serverHostNS;

}

// make thread safe
//
@property (retain) NSMutableArray *connections;
@property (retain) NSMutableArray *parsers;

/*! server host and port information */
@property (nonatomic, retain) NSString *serverHostAS;
@property (nonatomic, retain) NSString *serverHostPS;
@property (nonatomic, retain) NSString *serverHostNS;

/*!
 @abstract creates singleton object
 */
+ (MPHTTPCenter *)sharedMPHTTPCenter;


/*!
 @abstract checks if users is registered on this device
 
 @discussion checks if userID exists.  Otherwise we still need to register.  However,
 if authentication rejects userID, then ask user to reregister.
 
 @return YES if aleady registered
 */
- (BOOL) isUserRegistered;
- (BOOL) isRegistrationComplete;
/*!
 @abstract logs in to network services
 
 @return YES    already registered and sent authentication request
 NO     if still needs registration
 */
- (BOOL) authenticateAndLogin;

#pragma mark - AS Service Requests

/*! 
 @abstract Request security services to start registration process.
 @discussion Sends the MSISDN (country code + phone number) to centralized security 
 services.  MP should then send a passcode via SMS, so users can continue to verify
 their ownership of the MSISDN.
 
 procedure:
 - format URL request
 - start connection to URL
 - implement delegate to get data when loading completes
 
 Example URL:
 12:37:59.265 <SEND> [http://61.66.229.101/MessageAPP/MsisdnVerification?MSISDN=886928260333&LANGUAGE=zh_TW]
 12:37:59.406 <RECV> [<msisdnverification><cause>0</cause><text>msisdnverification Success</text></msisdnverification>]
 
 @param countryCode 3-4 digit country code
 @param phoneNumber phone number to be registered
 
 */
- (void)requestRegistrationCountryCode:(NSString *)countryCode phoneNumber:(NSString *)phoneNumber confirmMultiDeviceRegistration:(BOOL)confirmedByUser;


/*!
 @abstract if msisdn exists, sends another registration request
 */
- (void)resendRegistration;



/*! 
 @abstract Attempts to verify registration by providing passcode
 @discussion Use SMS passcode to verify ownership of MSISDN with MP services.
 
 procedure:
 - format URL request
 - start connection to URL
 - implement delegate to get data when loading completes
 
 Example URL:
 12:38:01.578 <SEND> [http://61.66.229.101/MessageAPP/Registration?MSISDN=886928260333&LANGUAGE=zh_TW&IMEI=80686910&PASSWORD=1234]
 12:38:01.609 <RECV> [<registration><cause>0</cause><USERID>20114567</USERID><text>Registration Success</text><registration>]
 
 @param passcode the SMS passcode sent to user after requestRegistration
 */
- (void)verifyRegistration:(NSString *)passcode;


/*! 
 @abstract Request authentication key used for domain server login
 @discussion Sends userID obtained from verification to obtain a new authentication key.
 
 procedure:
 - format URL request
 - start connection to URL
 - implement delegate to get data when loading completes
 
 Example URL:
 12:38:03.656 <SEND> [http://61.66.229.101/MessageAPP/Authentication?MSISDN=886928260333&LANGUAGE=zh_TW&IMEI=80686910&USERID=20114567]
 12:38:03.671 <RECV> [<authentication><cause>0</cause><domain>61.66.229.110:80</domain><akey>1020345</akey><text>Authentication Success</text></authentication>]
 
 @param msisdn unique phone number to register for this client
 */
- (void)requestAuthenticationKey;
- (void) requestCancelAccount;
- (void) ipQueryMsisdn;

// Test configuration
- (void) loadServerHostInfo;

- (NSString *)getPhoneNumber;
- (NSString *)getCountryCode;

#pragma mark - Encryption

+ (NSString *) httpRequestUserID;
+ (NSString *) httpRequestEncryptIfNeeded:(NSString *)value;
+ (NSString *) httpRequestEncodeFlag;

#pragma mark - Resources
- (void) getResourceDownloadInfo;
- (void) getResourceDownloadInfoDefault;

#pragma mark - PS
- (void) blockUser:(NSString *)blockUserID;
- (void) unBlockUser:(NSString *)unBlockUserID;
- (NSString *) headShotURLForPresenceArray:(MPPresence *)presenceObject;
- (void) updateNickname:(NSString *)nickname;
- (void) updateStatus:(NSString *)status;
- (void) updateHeadshotIsFromFaceBook:(BOOL)fromFacebook;
- (void) setPresencePermission:(BOOL)shouldShowPresence idTag:(NSString *)newIDTag;

- (void)getUserInformation:(NSArray *)queryItems action:(NSString *)action idTag:(NSString *)newID itemType:(NSString *)itemType;
- (void)createID:(NSString *)idString;
- (void)searchID:(NSString *)idString;
- (void)setSearchID:(BOOL)shouldAllowSearch idTag:(NSString *)newIDTag;

- (BOOL) queryOperator:(NSArray *)phoneNumbers;
- (BOOL) sendFreeSMS:(NSArray *)phoneNumbers messageContent:(NSString *)messageContent;
- (BOOL) sendHelperMessage;

#pragma mark - NS
- (void) setPushTokenID:(NSData *)tokenData p2pTone:(NSString *)p2pTone groupTone:(NSString *)groupTone;
- (void) setPNHiddenPreviewForUserID:(NSString *)newUserID groupID:(NSString *)groupID hiddenStatus:(BOOL)hiddenStatus disableAll:(BOOL)disable;
- (void) setPushNotify:(BOOL)isPushOn isGroup:(BOOL)isGroup;
- (void) setPNPreview:(BOOL)isPreviewOn isGroup:(BOOL)isGroup;
- (void) setPushRingToneP2P:(NSString *)p2pTone groupTone:(NSString *)groupTone;

#pragma mark - Map
- (void)mapForwardGeocodeAddress:(NSString *)address idTag:(NSString *)idTag;
- (void)mapReverseGeocode:(CLLocationCoordinate2D)coordinate idTag:(NSString *)idTag;
- (void)mapPlaceSearch:(CLLocationCoordinate2D)coordinate radiusMeters:(CGFloat)radius keyword:(NSString *)keyword type:(NSString *)type idTag:(NSString *)idTag;

+ (NSInteger)getCauseForResponseDictionary:(NSDictionary *)responseD;
@end
