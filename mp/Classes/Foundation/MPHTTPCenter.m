 //
//  MPSecurityCenter.m
//  mp
//
//  Created by M Tsai on 11-8-30.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "MPHTTPCenter.h"

#import <Security/Security.h>

#import "SynthesizeSingleton.h"
#import "TTURLConnection.h"
#import "TTXMLParser.h"

#import "MPFoundation.h"
#import "CDContact.h"
#import "AppUtility.h"
#import "MPContactManager.h"
#import "CDContact.h"
#import "MPResourceCenter.h"

#import "OperatorInfoCenter.h"

#import "JSONKit.h"


NSString* const kMPHCJsonKeyJsonObject = @"json";
NSString* const kMPHCJsonKeyResults = @"results";
NSString* const kMPHCJsonKeyStatus = @"status";
NSString* const kMPHCJsonKeyFormattedAddress = @"formatted_address";
NSString* const kMPHCJsonKeyName = @"name";
NSString* const kMPHCJsonKeyVicinity = @"vicinity";
NSString* const kMPHCJsonKeyGeometry = @"geometry";
NSString* const kMPHCJsonKeyLocation = @"location";
NSString* const kMPHCJsonKeyLatitude = @"lat";
NSString* const kMPHCJsonKeyLongitude = @"lng";



// Google Map API v3 parameters
NSString* const kMPProtocolGoggle = @"http";
NSString* const kMPParamServerGoggle = @"maps.googleapis.com";
NSString* const kMPParamServiceMaps = @"maps/api";

NSString* const kMPHCRequestTypeMapGeocode = @"geocode";
NSString* const kMPHCRequestTypeMapForwardGeocode = @"forward_geocode";    // only used to diff from reverse
NSString* const kMPHCRequestTypeMapPlaceSearch = @"place/search";

NSString* const MP_HTTPCENTER_FORWARD_GEOCODE_NOTIFICATION = @"MP_HTTPCENTER_FORWARD_GEOCODE_NOTIFICATION";
NSString* const MP_HTTPCENTER_REVERSE_GEOCODE_NOTIFICATION = @"MP_HTTPCENTER_REVERSE_GEOCODE_NOTIFICATION";
NSString* const MP_HTTPCENTER_PLACE_SEARCH_NOTIFICATION = @"MP_HTTPCENTER_PLACE_SEARCH_NOTIFICATION";


// Servers to use
NSString* const kMPProtocol = @"https";

/* old servers
NSString* const kMPAuthenticationServer = @"61.66.229.110:29616"; //@"61.66.229.101";
NSString* const kMPPresenceServer = @"61.66.229.110:29616"; //@"61.66.229.118"; //  @"61.66.229.110:29616"; //
*/


// URL service names
NSString* const kMPParamServiceAS = @"AuthenticationServer";
NSString* const kMPParamServicePS = @"PresenceServer";
NSString* const kMPParamServiceNS = @"PushNotificationServer";


// AS Request Types
NSString* const kMPHCRequestTypeAuthentication = @"Authentication";


// HTTP Request Types
NSString* const kMPHCRequestTypeGetUserInformation = @"GetUserInformation";
NSString* const kMPHCRequestTypeGetResourceDownloadInfo = @"GetResourceDownloadInfo";
NSString* const kMPHCRequestTypeCancel = @"Cancel";
NSString* const kMPHCRequestTypeIPQueryMSISDN = @"IPQueryMSISDN";
NSString* const kMPHCRequestTypeCreateMPID = @"CreateMPID";
NSString* const kMPHCRequestTypeSearchMPID = @"SearchMPID";
NSString* const kMPHCRequestTypeCloseMPID = @"CloseMPID";
NSString* const kMPHCRequestTypeOpenMPID = @"OpenMPID";
NSString* const kMPHCRequestTypeUpdateNickname = @"UpdateNickname";  // response - but response is UpdateNickName
NSString* const kMPHCRequestTypeUpdateStatus = @"UpdateStatus";
NSString* const kMPHCRequestTypeBlock = @"Block";
NSString* const kMPHCRequestTypeUnBlock = @"UnBlock";
NSString* const kMPHCRequestTypePresencePermission = @"PresencePermission";
NSString* const kMPHCRequestTypeUpdateHeadshot = @"UpdateHeadshot";
NSString* const kMPHCRequestTypeQueryOperator = @"QueryOperator";
NSString* const kMPHCRequestTypeSMS = @"SMS";
NSString* const kMPHCRequestTypeSendHelperMessage = @"SendHelperMessage";



// Push Notification Requests 
NSString* const kMPHCRequestTypeSetPushTokenID = @"SetPushTokenID";
NSString* const kMPHCRequestTypeSetPushNotify = @"SetPushNotify";
NSString* const kMPHCRequestTypeSetPNPreview = @"SetPNPreview";
NSString* const kMPHCRequestTypeSetPNHidden = @"SetPNHidden";
NSString* const kMPHCRequestTypeSetPushRingTone = @"SetPushRingTone";



// query type for getUserInfo
NSString* const kMPHCQueryTag = @"queryTag";
NSString* const kMPHCQueryTagAdd = @"add";
NSString* const kMPHCQueryTagAddPhoneSync = @"addPhoneSync"; // add query but for phone sync
NSString* const kMPHCQueryTagQuery = @"query";
NSString* const kMPHCQueryTagQueryNoArguments = @"queryNoArguments"; // query with out any arguments
NSString* const kMPHCQueryTagSuggestion = @"sug";
NSString* const kMPHCQueryTagRefersh = @"refresh";
NSString* const kMPHCQueryTagRemove = @"remove";
NSString* const kMPHCQueryIDTagBlockedRecovery = @"blockedRecovery"; // id this query as for block recovery


// item type for getUserInfo
NSString* const kMPHCItemTypePhone = @"phone";
NSString* const kMPHCItemTypeUserID = @"userid";


// Response & Failure notifications
//
NSString* const MP_HTTPCENTER_CONNECT_FAILED_NOTIFICATION = @"MP_HTTPCENTER_CONNECT_FAILED_NOTIFICATION";
NSString* const MP_HTTPCENTER_CANCEL_NOTIFICATION = @"MP_HTTPCENTER_CANCEL_NOTIFICATION";

NSString* const MP_HTTPCENTER_IPQUERY_MSISDN_NOTIFICATION = @"MP_HTTPCENTER_IPQUERY_MSISDN_NOTIFICATION";

NSString* const MP_HTTPCENTER_CODE_VERIFICATION_SUCCESS = @"MP_HTTPCENTER_CODE_VERIFICATION_SUCCESS";
NSString* const MP_HTTPCENTER_CODE_VERIFICATION_FAILURE = @"MP_HTTPCENTER_CODE_VERIFICATION_FAILURE";
NSString* const MP_HTTPCENTER_MSISDN_SUCCESS_NOTIFICATION = @"MP_HTTPCENTER_MSISDN_SUCCESS_NOTIFICATION";
NSString* const MP_HTTPCENTER_MSISDN_MULTIDEVICE_NOTIFICATION = @"MP_HTTPCENTER_MSISDN_MULTIDEVICE_NOTIFICATION";
NSString* const MP_HTTPCENTER_AUTHENTICATION_NOTIFICATION = @"MP_HTTPCENTER_AUTHENTICATION_NOTIFICATION";


NSString* const MP_HTTPCENTER_CREATEID_NOTIFICATION = @"MP_HTTPCENTER_CREATEID_NOTIFICATION";
NSString* const MP_HTTPCENTER_SEARCHID_NOTIFICATION = @"MP_HTTPCENTER_SEARCHID_NOTIFICATION";
NSString* const MP_HTTPCENTER_CLOSEID_NOTIFICATION = @"MP_HTTPCENTER_CLOSEID_NOTIFICATION";
NSString* const MP_HTTPCENTER_OPENID_NOTIFICATION = @"MP_HTTPCENTER_OPENID_NOTIFICATION";


NSString* const MP_HTTPCENTER_UPDATE_NICKNAME_NOTIFICATION = @"MP_HTTPCENTER_UPDATE_NICKNAME_NOTIFICATION";
NSString* const MP_HTTPCENTER_UPDATE_STATUS_NOTIFICATION = @"MP_HTTPCENTER_UPDATE_STATUS_NOTIFICATION";
NSString* const MP_HTTPCENTER_UPDATE_HEADSHOT_NOTIFICATION = @"MP_HTTPCENTER_UPDATE_HEADSHOT_NOTIFICATION";

NSString* const MP_HTTPCENTER_GETUSERINFO_NOTIFICATION = @"MP_HTTPCENTER_GETUSERINFO_NOTIFICATION";
NSString* const MP_HTTPCENTER_GETUSERINFO_ADD_NOTIFICATION = @"MP_HTTPCENTER_GETUSERINFO_ADD_NOTIFICATION";


NSString* const MP_HTTPCENTER_BLOCK_NOTIFICATION = @"MP_HTTPCENTER_BLOCK_NOTIFICATION";
NSString* const MP_HTTPCENTER_UNBLOCK_NOTIFICATION = @"MP_HTTPCENTER_UNBLOCK_NOTIFICATION";

NSString* const MP_HTTPCENTER_PRESENCEPERMISSION_NOTIFICATION = @"MP_HTTPCENTER_PRESENCEPERMISSION_NOTIFICATION";
NSString* const MP_HTTPCENTER_QUERYOPERATOR_NOTIFICATION = @"MP_HTTPCENTER_QUERYOPERATOR_NOTIFICATION";
NSString* const MP_HTTPCENTER_SMS_NOTIFICATION = @"MP_HTTPCENTER_SMS_NOTIFICATION";
NSString* const MP_HTTPCENTER_SEND_HELPER_MESSAGE_NOTIFICATION = @"MP_HTTPCENTER_SEND_HELPER_MESSAGE_NOTIFICATION";


NSString* const MP_HTTPCENTER_SET_PUSH_NOTIFY_NOTIFICATION = @"MP_HTTPCENTER_QUERYOPERATOR_NOTIFICATION";
NSString* const MP_HTTPCENTER_SET_PN_PREVIEW_NOTIFICATION = @"MP_HTTPCENTER_SET_PN_PREVIEW_NOTIFICATION";
NSString* const MP_HTTPCENTER_SET_PN_HIDDEN_NOTIFICATION = @"MP_HTTPCENTER_SET_PN_HIDDENPREVIEW_NOTIFICATION";
NSString* const MP_HTTPCENTER_SET_PUSH_RINGTONE_NOTIFICATION = @"MP_HTTPCENTER_SET_PUSH_RINGTONE_NOTIFICATION";



@implementation MPHTTPCenter

@synthesize connections;
@synthesize parsers;
@synthesize serverHostAS;
@synthesize serverHostPS;
@synthesize serverHostNS;


SYNTHESIZE_SINGLETON_FOR_CLASS(MPHTTPCenter);


// imports pkcs12
// - deprecated since we use DER certificates instead
//
OSStatus extractIdentityAndTrust(CFDataRef inPKCS12Data,        
                                 SecIdentityRef *outIdentity,
                                 SecTrustRef *outTrust)
{
    OSStatus securityError = errSecSuccess;
    
    
    CFStringRef password = CFSTR("messageplus");
    const void *keys[] =   { kSecImportExportPassphrase };
    const void *values[] = { password };
    CFDictionaryRef optionsDictionary = CFDictionaryCreate(
                                                           NULL, keys,
                                                           values, 1,
                                                           NULL, NULL);  
    
    // Don't create an array, we just need an address
    // - otherwise this will cause memory leak
    //CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    
    CFArrayRef items;
    
    // items should be released after we are done using
    securityError = SecPKCS12Import(inPKCS12Data,
                                    optionsDictionary,
                                    &items);                   
    
    if (securityError == 0) {                                  
        CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex (items, 0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue (myIdentityAndTrust,
                                             kSecImportItemIdentity);
        *outIdentity = (SecIdentityRef)tempIdentity;
        
        const void *tempTrust = NULL;
        tempTrust = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemTrust);
        *outTrust = (SecTrustRef)tempTrust;
    }
    
    if (optionsDictionary != NULL){
        CFRelease(optionsDictionary);
    }
    
    return securityError;
}
    
    

/*!
 @abstract loads host host IP from setting params
 */
- (void) loadServerHostInfo {
    /*
    self.serverHostAS = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingServerAS];
    self.serverHostPS = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingServerPS];
    self.serverHostNS = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingServerNS];
     */
    
    self.serverHostAS = kMPParamNetworkMPServerPort;
    self.serverHostPS = kMPParamNetworkMPServerPort;
    self.serverHostNS = kMPParamNetworkMPServerPort;
        
    // load certificate

    /*
    OSStatus                err;
    SecCertificateRef       cert;
        
    NSString *certPath = [[NSBundle mainBundle]
                         pathForResource:@"mplus" ofType:@"der"];
    NSData *derData = [[NSData alloc] initWithContentsOfFile:certPath];
    cert = SecCertificateCreateWithData(NULL, (CFDataRef) derData);
    if (cert != NULL) {
        err = SecItemAdd(
                         (CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
                                            (id) kSecClassCertificate,  kSecClass, 
                                            (id) cert,                  kSecValueRef,
                                            nil
                                            ], 
                         NULL
                         );
        if ( (err == errSecSuccess) || (err == errSecDuplicateItem) ) {
            DDLogInfo(@"HC: cert import success");
            
        }
    }
     */
    
    /*
    
    NSString *thePath = [[NSBundle mainBundle]
                         pathForResource:@"mplus" ofType:@"p12"];
    NSData *PKCS12Data = [[NSData alloc] initWithContentsOfFile:thePath];
    CFDataRef inPKCS12Data = (CFDataRef)PKCS12Data;             
    
    // extract identity and trust
    //
    OSStatus status = noErr;
    SecIdentityRef myIdentity;
    SecTrustRef myTrust;
    status = extractIdentityAndTrust(
                                     inPKCS12Data,
                                     &myIdentity,
                                     &myTrust);   
    
    // handle error
    if (status != 0) {
        DDLogError(@"HC: load trust failed! - %d", status);
        return;
    }
        
    
    if (status == noErr) {                                     
        SecTrustResultType trustResult;

        status = SecTrustEvaluate(myTrust, &trustResult);
        DDLogInfo(@"HC: first trust eval - %d", status);

        
        // try to recover from failure
        if (trustResult == kSecTrustResultRecoverableTrustFailure) {
            // got an error
            DDLogInfo(@"HC: recoverable trust failure");
            
            CFDataRef trustExceptions = SecTrustCopyExceptions(myTrust);
            bool exceptionResult = SecTrustSetExceptions(myTrust, trustExceptions);
            
            if (exceptionResult) {
                status = SecTrustEvaluate(myTrust, &trustResult);
                DDLogInfo(@"HC: second trust eval - %d", status);
            }
            // set exception attempt failed
            else {
                DDLogInfo(@"HC: set trust exception failed");
            }
            CFRelease(trustExceptions);
        }
        
        // if trust is ok, then 
        if (trustResult == kSecTrustResultProceed) {
            DDLogInfo(@"HC: trust proceed");
            
            // add our trust credential to storage for later use
            //
            NSURLCredential *credential = [[NSURLCredential alloc] initWithTrust:myTrust];
            NSURLProtectionSpace *space = [[NSURLProtectionSpace alloc] initWithHost:kMPParamNetworkMPServerPort 
                                                                                port:443 
                                                                            protocol:NSURLProtectionSpaceHTTPS 
                                                                               realm:nil 
                                                                authenticationMethod:NSURLAuthenticationMethodServerTrust];
            [[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:credential forProtectionSpace:space];
            
            [credential release];
            [space release];
        }
    }
    
    [PKCS12Data release];
     */
}



- (id)init {
    
    self = [super init];
    if (self) {
        [self loadServerHostInfo];
    }    
    return self;
}



- (void) dealloc{
    [connections release];
    [parsers release];
    [super dealloc];
}

/*!
 Never call the getters, use these instead
 
 Note:
 - atomic can't both use @synthesize and define custom getters
 */
- (NSMutableArray *)getConnections {
    
    if (self.connections == nil) {
        NSMutableArray *newArray = [[NSMutableArray alloc] init];
        self.connections = newArray;
        [newArray release];
    }
    return self.connections;
}

- (NSMutableArray *)getParsers {
    
    if (self.parsers == nil) {
        NSMutableArray *newArray = [[NSMutableArray alloc] init];
        self.parsers = newArray;
        [newArray release];
    }
    return self.parsers;
}




#pragma mark - External Security Services



/*!
 @abstract get registered phone number - without country code
 */
- (NSString *)getPhoneNumber {
    return [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPhoneNumber]; 
}

/*!
 @abstract get registered phone number's country code only
 */
- (NSString *)getCountryCode {
    return [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPhoneCountryCode]; 
}



/*!
 @abstract checks if users is registered on this device
 
 @discussion checks if userID exists.  Otherwise we still need to register.  However,
 if authentication rejects userID, then ask user to reregister.
 
 @return YES if aleady registered
 */
- (BOOL)isUserRegistered {
    
    NSString *userID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    if ([AppUtility isUserIDValid:userID]){
        return YES;
    }
    return NO;
}


/*!
 @abstract checks if nickname is registered on this device
 
 @discussion checks if nickname exists.  Otherwise we still need to register it.  
 
 @return YES if aleady registered
 */
- (BOOL)isNameRegistered {
    
    NSString *name = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingNickName];
    
    if ([AppUtility isNickNameValid:name]){
        return YES;
    }
    return NO;
}

/*!
 @abstract Check if registration process is complete - both userID and name are valid
 
 @return YES if aleady registered
 */
- (BOOL) isRegistrationComplete {
    
    BOOL isRegistered = [self isUserRegistered];
    BOOL isNameRegistered = [self isNameRegistered];
    
    if (!isRegistered || !isNameRegistered) {
        return NO;
    }
    return YES;
}


/*!
 @abstract logs in to network services
 
 @return YES    already registered and sent authentication request
         NO     if still needs registration
 */
- (BOOL)authenticateAndLogin {
    
    // if not registered, show registration view
    
    if (![self isRegistrationComplete]) {
        DDLogWarn(@"HC-aal: Can't Auth - not registered yet");
        return NO;
    }
    else {

        // if akey ok & domain cluster exists, try login
        if ([[MPSettingCenter sharedMPSettingCenter] isAkeyAndClusterValid]) {
            DDLogInfo(@"HC-aal: Request login from Authenticate");
            [[AppUtility getSocketCenter] loginAndConnect];
        }
        // if akey not available, try authenticating
        //
        else {
            DDLogWarn(@"HC-aal: Invalid akey, request authenticate to get new one");
            [self requestAuthenticationKey];
        }
        
    }
    return YES;
}


#pragma mark - Resource Requests


/*!
 @abstract Checks if there are new resources to download
 
 http://175.99.90.219:80/PresenceServer/GetResourceDownloadInfo?lastupdatetime=1000&LANGUAGE=zh&resolution=xhdpi&USERID=00000222
 
 
 */
- (void) getResourceDownloadInfo {
    
    //[AppUtility startActivityIndicator];
    
    // create and send Cancel request
    //
    //NSString *language = [AppUtility devicePreferredLanguageCode];
    //CGSize screenSize = [[UIDevice currentDevice] getScreenSizePixels];
    
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    NSString *language = @"zh";
    CGFloat scale = [[UIScreen mainScreen] scale];
    NSString *resolution = @"mdpi";
    if (scale == 2.0) {
        resolution = @"xhdpi";
    }
    
    NSString *lastUpdateTime = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingGetResourceLastUpateTime];
    
    // @TEST: set to 1000 to get full update for testing
    //lastUpdateTime = @"1000";
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?lastupdatetime=%@&LANGUAGE=%@&resolution=%@&USERID=%@%@",
                           kMPProtocol, self.serverHostPS, kMPParamServicePS, kMPHCRequestTypeGetResourceDownloadInfo,lastUpdateTime, language, resolution, userID, [MPHTTPCenter httpRequestEncodeFlag]];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeGetResourceDownloadInfo;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
}


/*!
 @abstract Load the default version of the resource meta-data
 
 This file is used to initially populate the resource info incase the first remote request fails
 
 http://mplusasps.tfn.net.tw/PresenceServer/GetResourceDownloadInfo?lastupdatetime=1000&LANGUAGE=zh&resolution=xhdpi&USERID=00000222
 
 */
- (void) getResourceDownloadInfoDefault {
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    NSString *resolution = @"mdpi";
    if (scale == 2.0) {
        resolution = @"xhdpi";
    }
    
    NSString *fileName = [NSString stringWithFormat:@"resource_default_%@", resolution];
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"xml"];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:nil isPost:NO nsurl:fileURL];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeGetResourceDownloadInfo;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
}

#pragma mark - Request Tools

/*!
 @abstract Gets UserID to submit to HTTP requests
 */
+ (NSString *) httpRequestEncryptIfNeeded:(NSString *)value{
    
#ifdef AES_ENCRYPT
    return [MPSettingCenter encryptAESValue:value];
#else
    return value;
#endif
    
}

/*!
 @abstract Gets UserID to submit to HTTP requests
 */
+ (NSString *) httpRequestEncodeFlag{
    
#ifdef AES_ENCRYPT
    return @"&encodeFlag=Y";
#else
    return @"";
#endif
    
}

/*!
 @abstract Gets UserID to submit to HTTP requests
 */
+ (NSString *) httpRequestUserID {
  
#ifdef AES_ENCRYPT
    
    NSString *encryptedID = [[MPSettingCenter sharedMPSettingCenter] getUserIDEncrypted];
    return [Utility stringByAddingPercentEscapeEncoding:encryptedID];
    
#else
    
    return [[MPSettingCenter sharedMPSettingCenter] getUserID];

#endif
    
}

/*!
 @abstract Gets MSISDN to submit to HTTP requests
 */
+ (NSString *) httpRequestMSISDN {
    
#ifdef AES_ENCRYPT
    
    NSString *encrypted = [[MPSettingCenter sharedMPSettingCenter] getMSISDNEncrypted];
    return [Utility stringByAddingPercentEscapeEncoding:encrypted];
    
#else
    
    return [[MPSettingCenter sharedMPSettingCenter] getMSISDN];

#endif
    
}

/*!
 @abstract Decode encrypted parameters
 
 */
+ (void) httpResponseDecrypt:(NSDictionary *)responseD responseType:(NSString *)responseType cause:(NSInteger)cause {
    
#ifdef AES_ENCRYPT
    
    // only need to decrypt if successful
    //
    if (cause == kMPCauseTypeSuccess) {
        if ([responseType isEqualToString:@"ipquerymsisdn"]) {
            NSString *encodedValue = [responseD valueForKey:@"msisdn"];
            NSString *decodedValue = [MPSettingCenter decryptAESValue:encodedValue];
            [responseD setValue:decodedValue forKey:@"msisdn"];
        }
        else if ([responseType isEqualToString:@"registration"]) {
            NSString *encodedValue = [responseD valueForKey:@"USERID"];
            NSString *decodedValue = [MPSettingCenter decryptAESValue:encodedValue];
            [responseD setValue:decodedValue forKey:@"USERID"];
        }
        else if ([responseType isEqualToString:kMPHCRequestTypeGetUserInformation]) {
            NSString *encodedValue = [responseD valueForKey:@"text"];
            NSString *decodedValue = [MPSettingCenter decryptAESValue:encodedValue];
            [responseD setValue:decodedValue forKey:@"text"];
        }
        else if ([responseType isEqualToString:kMPHCRequestTypeSearchMPID]) {
            NSString *encodedValue = [responseD valueForKey:@"text"];
            NSString *decodedValue = [MPSettingCenter decryptAESValue:encodedValue];
            [responseD setValue:decodedValue forKey:@"text"];
        }
    }
    return;
    
#else
    
    return;

#endif
}



/*!
 @abstract Encode in UTF8, decode with Latin1 and then percent encode
 
 - Needed since server needs to decode UTF8 again
 
 */
+ (NSString *) httpRequestEncodeUTF8Latin1PercentEscape:(NSString *)value {
    
    // in case there is a space
    NSData *utf8Data = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSString *latinString = [[NSString alloc] initWithData:utf8Data encoding:NSISOLatin1StringEncoding];
    NSString *escapedValue = [Utility stringByAddingPercentEscapeEncoding:latinString];
    [latinString release];
    
    return escapedValue;
}



#pragma mark - Authentication Service Requests


/*!
 @abstract Cancels user account
 
 http://61.66.229.118/AuthenticationServer/Cancel?USERID=20114567
 &Akey=1231701&LANGUAGE=zh
 
 Successful case
<Cancel>
		<cause>0</cause>
		<text>你已經成功取消服務….</text>
</Cancel>
 
Exeception case
<Cancel>
		<cause>603</cause>
		<text>Akey已經過期 , 請重新認證 ! </text>
</Cancel>
 
 
 */
- (void) requestCancelAccount {
    
    DDLogInfo(@"HC: Req CANCEL ACCOUNT");
    
    [AppUtility startActivityIndicator];

    // create and send Cancel request
    //
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    NSString *language = [AppUtility devicePreferredLanguageCode];
    NSString *aKey = [[MPSettingCenter sharedMPSettingCenter] secureValueForID:kMPSettingAuthKey];

    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?USERID=%@&Akey=%@&LANGUAGE=%@%@", 
                           kMPProtocol, self.serverHostAS, kMPParamServiceAS, kMPHCRequestTypeCancel, userID, aKey, language, [MPHTTPCenter httpRequestEncodeFlag]];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeCancel;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
    
}




/*!
 @abstract Attempts to get the phone number using 3G IP address lookup
 
 Input
 
 http://xxx.xxx.xxx.xxx/AuthenticationServer/IPQueryMSISDN?IP=xxx.xxx.xxx.xxx&LANGUAGE=en&IMEI=xxxxxxxxxxxx&devicemodel=ios-4.0-apple-iphone3gs
 
 &LANGUAGE=en
 Output
 Successful case
 
 <ipquerymsisdn>
 <cause>0</cause>
 <msisdn>886928260333</msisdn>
 </ipquerymsisdn>
 Exeception case
 
 <ipquerymsisdn>
 <cause>201</cause>
 <text>cannot get msisdn by ip query , input msisdn instead.</text>
 </ipquerymsisdn>
 Remark
 
 IMEI需寫入FIRST_TIME_APP table，以便日後出報表用，記錄第一次啟動app時間
 
 
 
 */
- (void) ipQueryMsisdn {
    
    
    // create and send request
    //
    NSString *language = [AppUtility devicePreferredLanguageCode];    
    NSString *ipAddress = [[UIDevice currentDevice] getIPAddress3G];
    NSString *imei = [AppUtility getIMEI]; 
    NSString *deviceModel = [AppUtility getDeviceModel];
    NSString *escapedModel = [Utility stringByAddingPercentEscapeEncoding:deviceModel];
    
    if (ipAddress) {
        NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?IP=%@&LANGUAGE=%@&IMEI=%@&%@=%@%@",
                               kMPProtocol, self.serverHostAS, kMPParamServiceAS, kMPHCRequestTypeIPQueryMSISDN, 
                               ipAddress, language, imei, kMPMessageKeyDeviceModel, escapedModel,
                               [MPHTTPCenter httpRequestEncodeFlag]];
        
        TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
        newConnection.delegate = self;
        newConnection.typeTag = kMPHCRequestTypeIPQueryMSISDN;
        [newConnection connect];
        [[self getConnections] addObject:newConnection];
        [newConnection release];
    }
    else {
        DDLogInfo(@"HC-iqm: nil IP address - cancel ipQueryRequest");
    }
    
    
}


/*! 
 @abstract Request security services to start registration process.
 @discussion Sends the MSISDN (country code + phone number) to centralized security 
 services.  MP should then send a passcode via SMS, so users can continue to verify
 their ownership of the MSISDN.
 
 procedure:
 - format URL request
 - start connection to URL
 - implement delegate to get data when loading completes
 
 Input
 https://xxx.xxx.xxx.xxx/AuthenticationServer/MsisdnVerification?
 COUNTRYCODE=+886&MSISDN=928260333&LANGUAGE=zh
 
 Output
 Successful case
 
 <msisdnverification>
 <cause>0</cause>
 <text>系統馬上發一封密碼簡訊至您的手機,請使用該密碼註冊M+帳號. </text>
 </ msisdnverification >
 
 Exeception case
 
 < msisdnverification >
 <cause>601</cause>
 <text>您的門號已經停用 , 請撥客服專線 xxxxx ….</text>
 </ msisdnverification >
 After response :
 
 AS should send SMS message to User-A’s MSISDN , SMS format :
 “M password:1234”
 
 
 @param countryCode 3-4 digit country code
 @param phoneNumber phone number to be registered
 @param confirmMultiDeviceRegistration user confirms that she still want move account to this device
 
 */
- (void)requestRegistrationCountryCode:(NSString *)countryCode phoneNumber:(NSString *)phoneNumber confirmMultiDeviceRegistration:(BOOL)confirmedByUser {
    
    // TODO: validate msisdn format before sending to server
    //
    
    [AppUtility startActivityIndicator];
    
    // zeros are stripped away from start of number before combining with country code
    //
    NSString *phoneNoZeroPrefix = [AppUtility stripZeroPrefixForString:phoneNumber];
    NSString *rawPhoneNumber = [NSString stringWithFormat:@"%@%@", countryCode, phoneNoZeroPrefix];
    
    NSCharacterSet *extraSet = [NSCharacterSet characterSetWithCharactersInString:@"+()-. "];
    
    NSString *cleanFullPhoneNumber = [[rawPhoneNumber componentsSeparatedByCharactersInSet:extraSet] componentsJoinedByString:@""];
    
    NSString *cleanPhoneNumber = [[phoneNoZeroPrefix componentsSeparatedByCharactersInSet:extraSet] componentsJoinedByString:@""];
    
    NSString *cleanCountryCode = [[countryCode componentsSeparatedByCharactersInSet:extraSet] componentsJoinedByString:@""];
    
    
    // save msisdn, phone and country code to settings
    [[MPSettingCenter sharedMPSettingCenter] resetMSISDN];
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingMSISDN settingValue:cleanFullPhoneNumber];
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPhoneNumber settingValue:cleanPhoneNumber];
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPhoneCountryCode settingValue:cleanCountryCode];
    
    NSString *msisdnParam = [MPHTTPCenter httpRequestEncryptIfNeeded:cleanPhoneNumber];
    NSString *escapedMsisdnParam = [Utility stringByAddingPercentEscapeEncoding:msisdnParam];

    
    NSString *language = [AppUtility devicePreferredLanguageCode];
    NSString *imei = [AppUtility getIMEI]; 
    
    NSString *deviceModel = [AppUtility getDeviceModel];
    NSString *escapedModel = [Utility stringByAddingPercentEscapeEncoding:deviceModel];
    NSString *appVersion = [AppUtility getAppVersion];
    
    
    // %2B ==> +
    NSString *plus = @"+";
    NSString *plusEncoded = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)plus, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
 
    NSString *confirmString = @"N";
    if (confirmedByUser) {
        confirmString = @"Y";
    }
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/MsisdnVerification?COUNTRYCODE=%@%@&MSISDN=%@&LANGUAGE=%@&IMEI=%@&CONFIRM=%@&%@=%@&%@=%@%@", 
                           kMPProtocol, self.serverHostAS, kMPParamServiceAS,
                           plusEncoded, cleanCountryCode, escapedMsisdnParam,
                           language, imei, confirmString, kMPMessageKeyDeviceModel,
                           escapedModel, kMPMessageKeyAppVersion, appVersion, [MPHTTPCenter httpRequestEncodeFlag]];
    [plusEncoded release];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
}

/*!
 @abstract used saved values to resend registration
  
 Note:
 - Since users are at this point, then they don't want to be warned about multi device issue again, confirm = Y
 
 */
- (void)resendRegistration {
    
    NSString *phoneNumber = [self getPhoneNumber];
    NSString *countryCode = [self getCountryCode];
    
    [self requestRegistrationCountryCode:countryCode phoneNumber:phoneNumber confirmMultiDeviceRegistration:YES];
}


/*! 
 @abstract Attempts to verify registration by providing passcode
 @discussion Use SMS passcode to verify ownership of MSISDN with MP services.
 
 procedure:
 - format URL request
 - start connection to URL
 - implement delegate to get data when loading completes
 
 Example URL:

 Input
 https://61.66.229.118/AuthenticationServer/Registration?COUNTRYCODE=+886&MSISDN=928260333&IMEI=192471047
 &PASSWORD=xxxx&LANGUAGE=zh&CONFIRM=Y&TWM3GIP=Y
 Output
 
 Successful case
 
 <registration>
 <cause>0</cause>
 <USERID>20114567</USERID>
 <text>歡迎成為Message+新用戶</text>
 </ registration >
 
 Exeception case
 
 < registration >
 <cause>601</cause>
 <text>您的門號已經停用 , 請撥客服專線 xxxxx ….</text>
 </ registration >
 < registration >
 <cause>604</cause>
 <text> Invalid password – have to do register again </text>
 </ registration >
 
 Remark
 
 AS要把國碼和門號存在兩個欄位，一個欄位存COUNTRYCODE;另一個欄位只存MSISDN，當用戶呼叫GetUserInformation時，AS找出USERID的比對邏輯為
 1.Client帶過來的門號後九碼比對MSISDN的後九碼欄位	
 
 
 @param passcode the SMS passcode sent to user after requestRegistration
 */
- (void)verifyRegistration:(NSString *)passcode {
    
    // TODO: validate passcode format before sending to server
    //
    
    [AppUtility startActivityIndicator];

    
    NSString *language = [AppUtility devicePreferredLanguageCode];
    NSString *phoneNumber = [self getPhoneNumber];
    NSString *countryCode = [self getCountryCode];
    BOOL isIPUsed = [[[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingTWM3GIPUsed] boolValue];
    NSString *ipUsedString = isIPUsed?@"Y":@"N";
    
    NSString *msisdnParam = [MPHTTPCenter httpRequestEncryptIfNeeded:phoneNumber];
    NSString *escapedMSISDN = [Utility stringByAddingPercentEscapeEncoding:msisdnParam];

    
    // generate IMEI from mac address
    NSString *imei = [AppUtility getIMEI]; 
                      
    // %2B == +
    NSString *plus = @"+";
    NSString *plusEncoded = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)plus, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/Registration?COUNTRYCODE=%@%@&MSISDN=%@&IMEI=%@&PASSWORD=%@&LANGUAGE=%@&TWM3GIP=%@%@", 
                           kMPProtocol, self.serverHostAS, kMPParamServiceAS, plusEncoded, countryCode, escapedMSISDN, imei, passcode, language, ipUsedString, [MPHTTPCenter httpRequestEncodeFlag]];
    [plusEncoded release];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
}


/*! 
 @abstract Request authentication key used for domain server login
 @discussion Sends userID obtained from verification to obtain a new authentication key.
 
 procedure:
 - format URL request
 - start connection to URL
 - implement delegate to get data when loading completes
 
 Example URL:

 Input
 https://61.66.229.118/AuthenticationServer/Authentication?USERID=20114567
 &MSISDN=+886928260333&IMEI=192471047&LANGUAGE=zh
 
 http://61.66.229.106:8080/AuthenticationServer/Authentication?MSISDN=+886972242535&LANGUAGE=en&IMEI=0026B0F09436&USERID=00000041
 
 Output
 Successful case
 
 <authentication>
 <cause>0</cause>
 <domain>61.66.229.110:80</domain>
 <akey>1020345</akey >
 <text>您目前还有10封免费简讯额度….</text>
 </authentication>
 
 Exeception case
 
 <authentication>
 <cause>602</cause>
 <text>您的帳號已經停用 , 請撥客服專線 xxxxx ….</text>
 </authentication>
 
 
 @param msisdn unique phone number to register for this client
 */
- (void)requestAuthenticationKey {
    
    NSString *imei = [AppUtility getIMEI]; 
    NSString *language = [AppUtility devicePreferredLanguageCode];
    NSString *msisdn = [MPHTTPCenter httpRequestMSISDN];
    NSString *userID = [MPHTTPCenter httpRequestUserID];

    // %2B ==> +
    NSString *plus = @"+";
    NSString *plusEncoded = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)plus, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?MSISDN=%@%@&LANGUAGE=%@&IMEI=%@&USERID=%@%@",
                           kMPProtocol, self.serverHostAS, kMPParamServiceAS, kMPHCRequestTypeAuthentication,
                           plusEncoded, msisdn, language, imei, userID, [MPHTTPCenter httpRequestEncodeFlag]];
    [plusEncoded release];

    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeAuthentication;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
}


#pragma mark - Presence Requests


/*!
 
 @abstract Send free sms informing others about this app
 
 @return YES If request submitted.
 
 Input
 http://61.66.229.118/PresenceServer/SMS?USERID=20114567&to=0936550129&text=你好&LANGUAGE=en
 
 Output
 Successful case
 
 <SMS>
    <cause>0</cause>
    <quota>10</quota>
 </SMS>
 
 Exception case
 
 <SMS>
    <cause>602</cause>
    <text>Invalid USERID!</text>
 </SMS>
 
 */
- (BOOL) sendFreeSMS:(NSArray *)phoneNumbers messageContent:(NSString *)messageContent {
    
    [phoneNumbers retain];
    // do nothing if no numbers provided
    if ( !([phoneNumbers count] > 0) ) {
        return NO;
    }
    
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    NSString *language = [AppUtility devicePreferredLanguageCode];
    
    // optional facebook source
    NSString *phones = [phoneNumbers componentsJoinedByString:@"@"];
    NSString *encryptedPhones = [MPHTTPCenter httpRequestEncryptIfNeeded:phones];
    NSString *encodedPhones = [Utility stringByAddingPercentEscapeEncoding:encryptedPhones];
    
    [phoneNumbers release];
    
    NSString *escapedMessage = [MPHTTPCenter httpRequestEncodeUTF8Latin1PercentEscape:messageContent];
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?USERID=%@&to=%@&text=%@&LANGUAGE=%@%@",
                           kMPProtocol, self.serverHostPS, kMPParamServicePS, kMPHCRequestTypeSMS, userID, encodedPhones, escapedMessage, language, [MPHTTPCenter httpRequestEncodeFlag]];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeSMS;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
    
    return YES;
}


/*!
 
 @abstract Send message to helper after successfully registration
 
 @return YES If request submitted.
 
 Use:
 - only call after first successful login.  If called before login, this will fail.
 - 

 
 Input
 http://61.66.229.118/PresenceServer/SendHelperMessage?USERID=20114567&LANGUAGE=en
 
 Output
 ●        Successful case
 < SendHelperMessage>
    <cause>0</cause>
    <quota>10</quota>
 </ SendHelperMessage>
 
 ●        Exception case
 < SendHelperMessage>
    <cause>602</cause>
    <text>Invalid USERID!</text>
 </ SendHelperMessage>
 
 */
- (BOOL) sendHelperMessage {
    
    // request helper if needed
    if ([[MPSettingCenter sharedMPSettingCenter] didNotRunFirstStartTag:kMPHCRequestTypeSendHelperMessage]) {
        
        NSString *userID = [MPHTTPCenter httpRequestUserID];
        NSString *language = [AppUtility devicePreferredLanguageCode];
        
        NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?USERID=%@&LANGUAGE=%@%@",
                               kMPProtocol, self.serverHostPS, kMPParamServicePS, kMPHCRequestTypeSendHelperMessage, userID, language, [MPHTTPCenter httpRequestEncodeFlag]];
        
        TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
        newConnection.delegate = self;
        newConnection.typeTag = kMPHCRequestTypeSendHelperMessage;
        [newConnection connect];
        [[self getConnections] addObject:newConnection];
        [newConnection release];

        // also call friend suggestion here
        // - call it right after login, otherwise calling it too early will not work
        //
        [[MPHTTPCenter sharedMPHTTPCenter] getUserInformation:nil action:kMPHCQueryTagSuggestion idTag:nil itemType:kMPHCItemTypeUserID];
        
        return YES;
    }
    return NO;
}


/*!
 
 @abstract Query for operator
 
 @return YES If request submitted.
 
 Note:
 
 Request idTag = contains phone numbers concatenated by '@'.  This can be 
 used to help process the response.
 
 
 Input
 http://61.66.229.118/PresenceServer/QueryOperator?LANGUAGE=en&
 MSISDN=886911223344@+886936550129@0936550129
 Output
 Successful case
 
 <QueryOperator>
 <cause>0</cause>
 <operator>TWM,CHT,...</operator>
 </QueryOperator>
 
 TWM:台灣大哥大
 FET:遠傳
 CHT:中華 
 VIBO:威寶 
 ELSE:其他
 
 */
- (BOOL) queryOperator:(NSArray *)phoneNumbers {
    
    // do nothing if no numbers provided
    if ( !([phoneNumbers count] > 0) ) {
        return NO;
    }
    
    NSString *userID = [MPHTTPCenter httpRequestUserID];

    NSString *language = [AppUtility devicePreferredLanguageCode];
    
    NSString *msisdn = [phoneNumbers componentsJoinedByString:@"@"];
    
    NSString *msisdnParam = [MPHTTPCenter httpRequestEncryptIfNeeded:msisdn];
    
    NSString *escapedMSISDN = [Utility stringByAddingPercentEscapeEncoding:msisdnParam];
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?LANGUAGE=%@&MSISDN=%@&USERID=%@%@",
                           kMPProtocol, self.serverHostPS, kMPParamServicePS, kMPHCRequestTypeQueryOperator, 
                           language, escapedMSISDN, userID, [MPHTTPCenter httpRequestEncodeFlag]];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeQueryOperator;
    newConnection.idTag = msisdn;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
    
    return YES;
}


/*!
 @abstract update the headshot count and broadcast people who add you as a friend
 
 Input
 http://61.66.229.118/PresenceServer/UpdateHeadshot?USERID=20114567&LANGUAGE=en&SOURCE=facebook
 
 Output
 
 Successful case
 
 <UpdateHeadshot>
 <cause>0</cause>
 </UpdateHeadshot>
 
 Exception case
 
 <UpdateHeadshot>
 <cause>602</cause>
 <text>invalid USERID!</text>
 </UpdateHeadshot>
 
 Remark
 
 PS should update headshot_counts + 1 in DB and should push Presence message (include new counts ) to every on-lined friend to DS’s udp-6901~6932 port, but no permission check here.
 e.g. 
 (193563804,20998124,1,61.66.229.131, 61.66.229.131,Hawk,5, 201107050916,出差)
 (msisdn,USERID,presence,domain-address,from-address, nickname ,headshot, logintime,status) 
 
 2012-06-06
  - Verified by Allen that this API call is not needed since the message sent to DS will also 
    increment the headshot serial number.
 
 */
- (void) updateHeadshotIsFromFaceBook:(BOOL)fromFacebook {
    
    // create and send Cancel request
    //
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    NSString *language = [AppUtility devicePreferredLanguageCode];
    
    // optional facebook source
    NSString *facebookParam = @"";
    if (fromFacebook) {
        facebookParam = @"&SOURCE=facebook";
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?USERID=%@&LANGUAGE=%@%@%@",
                           kMPProtocol, self.serverHostPS, kMPParamServicePS, kMPHCRequestTypeUpdateHeadshot, userID, language, facebookParam, [MPHTTPCenter httpRequestEncodeFlag]];
    
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeUpdateHeadshot;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
}




/*!
 @abstract Set Presence Permission
 
 @param shouldShowPresence  Turn presence on or off
 @param newIDTag            Tag to identify this request - set to your userID
 
 Input
 http://61.66.229.118/PresenceServer/PresencePermission?
 USERID=A&YESORNO=yes&LANGUAGE=en
 
 Output
 Successful case
 
 <PresencePermission>
 <cause>0</cause>
 </PresencePermission>
 
 Exception case
 
 <PresencePermission>
 <cause>602</cause>
 <text>invalid USERID!</text>
 </PresencePermission>
 
 
 */
- (void) setPresencePermission:(BOOL)shouldShowPresence idTag:(NSString *)newIDTag{
    
    // create and send Cancel request
    //
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    NSString *language = [AppUtility devicePreferredLanguageCode];
    
    NSString *yesOrNo = shouldShowPresence?@"yes":@"no";
    
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?USERID=%@&YESORNO=%@&LANGUAGE=%@%@",
                           kMPProtocol, self.serverHostPS, kMPParamServicePS, kMPHCRequestTypePresencePermission, userID, yesOrNo, language, [MPHTTPCenter httpRequestEncodeFlag]];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypePresencePermission;
    newConnection.idTag = newIDTag;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
    
}

/*!
 @abstract sends block request
 
 http://61.66.229.118/PresenceServer/Block?A=20114567&B=34612900&LANGUAGE=en

 for A blocking B
 
Successful case
<Block>
 <cause>0</cause>
</Block>
 
Exception case
<Block>
 <cause>602</cause>
 <text>invalid USERID!</text>
</Block>
 
 */
- (void) blockUser:(NSString *)blockUserID {
    
    NSString *language = [AppUtility devicePreferredLanguageCode];
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    
    NSString *bParam = [MPHTTPCenter httpRequestEncryptIfNeeded:blockUserID];
    NSString *escapedBParam = [Utility stringByAddingPercentEscapeEncoding:bParam];
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?A=%@&B=%@&LANGUAGE=%@%@", 
                           kMPProtocol, self.serverHostPS, kMPParamServicePS, kMPHCRequestTypeBlock, userID, escapedBParam, language, [MPHTTPCenter httpRequestEncodeFlag]];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeBlock;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
}


/*!
 @abstract sends unblock request
 
 http://61.66.229.118/PresenceServer/UnBlock?A=20114567&B=34612900&LANGUAGE=en
 
 for A unblocking B
 
 Successful case
 <UnBlock>
    <cause>0</cause>
 </UnBlock>
 
 Exception case
 <UnBlock>
    <cause>602</cause>
    <text>invalid USERID!</text>
 </UnBlock>
 
 */
- (void) unBlockUser:(NSString *)unBlockUserID {
    
    NSString *language = [AppUtility devicePreferredLanguageCode];
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    
    NSString *bParam = [MPHTTPCenter httpRequestEncryptIfNeeded:unBlockUserID];
    NSString *escapedBParam = [Utility stringByAddingPercentEscapeEncoding:bParam];

    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?A=%@&B=%@&LANGUAGE=%@%@",
                           kMPProtocol, self.serverHostPS, kMPParamServicePS, kMPHCRequestTypeUnBlock, userID, escapedBParam, language, [MPHTTPCenter httpRequestEncodeFlag]];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeUnBlock;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
}

/*!
 @abstract generates headshot download URL
 
 http://61.66.229.112/downloadheadshot?USERID=10012345
 
 */
- (NSString *) headShotURLForPresenceArray:(MPPresence *)presenceObject {
    
    NSString *domainCluster = presenceObject.aDomainAddress;
    NSString *userID = presenceObject.aUserID;
    
    NSString *encryptedID = [MPHTTPCenter httpRequestEncryptIfNeeded:userID];
    NSString *encodedID = [Utility stringByAddingPercentEscapeEncoding:encryptedID];
    NSString *encodeFlag = [MPHTTPCenter httpRequestEncodeFlag];
    
    if ([domainCluster length] > 0 && [AppUtility isUserIDValid:userID]) {
        NSString *url = [NSString stringWithFormat:@"http://%@/download/downloadheadshot?USERID=%@&domainTo=%@%@",
                         kMPParamNetworkMPDownloadServer, encodedID, domainCluster, encodeFlag];
        return url;
    }
    return nil;
}



/*!
 @abstract Update the nick name for this user
 
 Input
 http://61.66.229.118/PresenceServer/UpdateNickname?USERID=20114567
 &nickname=Beer&LANGUAGE=en
 
 Output
 Successful case
 
 <UpdateNickName>
 <cause>0</cause>
 </UpdateNickName>
 
 Exception case
 
 <UpdateNickName>
 <cause>602</cause>
 <text>invalid USERID!</text>
 </UpdateNickName>
 
 Remark
 
 1.PS should push Presence message to every on-lined friend to DS’s udp(6901~6932) port, but no permission check here !
 2.檢查ACCOUNT_STATUS=’N’，代表是第一次註冊完成的UpdateNickName，必須去檢查MPLUS_FRIEND0~9內MSISDN9=此用戶的門號的QUERYM要設為Y
 
 */
- (void) updateNickname:(NSString *)nickname {
    
    // don't send request of it is not valid
    if (![AppUtility isNickNameValid:nickname]) {
        DDLogWarn(@"HC-un: invalid nickname: %@", nickname);
        [AppUtility stopActivityIndicator];
        return;
    }
    
    // in case there is a space   
    NSString *escapedName = [MPHTTPCenter httpRequestEncodeUTF8Latin1PercentEscape:nickname];
    
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    NSString *language = [AppUtility devicePreferredLanguageCode];

    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/UpdateNickname?USERID=%@&nickname=%@&LANGUAGE=%@%@",
                           kMPProtocol, self.serverHostPS, kMPParamServicePS, userID, escapedName, language, [MPHTTPCenter httpRequestEncodeFlag]];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeUpdateNickname;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
    
}

/*!
 @abstract Update status for this user
 
 HTTP get : http://61.66.229.118/MessageAPP/UpdateStatus?USERID=20114567&status=高雄出差 USERID : Message Plus user-ID : 8 digits ( 00000001 ~ 99999999 ) , unique number of system . status : Status of user , max 128 bytes
 
 HTTP response :
 Success:
 < UpdateStatus > <cause>0</cause>
 </ UpdateStatus >
 
 Error:
 < UpdateStatus > <cause>602</cause>
 <text>invalid USERID !</text> </ UpdateStatus >
 
 After response :
 PS should push Presence message to every on-lined friend to DS’s udp(6901~6932) port Note : no permission check here !
 
 
 */
- (void) updateStatus:(NSString *)status {
    
    // in case there is a space
    NSString *escapedStatus = [MPHTTPCenter httpRequestEncodeUTF8Latin1PercentEscape:status];
    
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    NSString *language = [AppUtility devicePreferredLanguageCode];


    
    // @TEST
    /*DDLogInfo(@"%@ -- %@ -- %@ -- %@ -- %@",
     [MPHTTPCenter httpRequestEncryptIfNeeded:@"00000041"],
     [MPHTTPCenter httpRequestEncryptIfNeeded:@"00000042"],
     [MPHTTPCenter httpRequestEncryptIfNeeded:@"00000043"],
     [MPHTTPCenter httpRequestEncryptIfNeeded:@"00000044"], [[MPSettingCenter sharedMPSettingCenter] getUserID]);*/
    //NSString *encrypted = [MPHTTPCenter httpRequestEncryptIfNeeded:[[MPSettingCenter sharedMPSettingCenter] getUserID]];
    //DDLogInfo(@"%@::%@: e:%@ d:%@", [[MPSettingCenter sharedMPSettingCenter] getUserID], userID,
    //          encrypted, [MPSettingCenter decryptAESValue:encrypted]);
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/UpdateStatus?USERID=%@&status=%@&LANGUAGE=%@%@",
                           kMPProtocol, self.serverHostPS, kMPParamServicePS, userID, escapedStatus, language, [MPHTTPCenter httpRequestEncodeFlag]];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeUpdateStatus;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
    
}


/*! 
 @abstract Gets presence information for contacts
 @discussion Sends the phone numbers to verify which contacts are also using M+.
 
 This method leaves international numbers alone, but tries to append the users's country code to local numbers.
 - this could be incorrect for people who switch out sim cards or travel to other countries.
 - M+ server should be able to handle numbers without country code - but there could be a chance of overlap!
 
 @param queryItems have following format: <phoneNumber>,<phonebook ID> or <userID>,<phonebook ID>
         - phonebook ID is unique ID of addressbook record -1 is invalid ID
         - each multiple items can be joined by '@'
 
 @param action request action to perform: "add" (incremental change), "remove", "refresh" (full query), or "query" (query, but don't add friends to database)
 - add: assume these are phone numbers
 - other: assume all other queries are for userIDs
 
 @param idTag identifies who originally requested this query & who should handle it! - prevent the wrong VC from process results
 
 @param itemType Specify the type of item being sent to in query Items.  If nil provided, then use default kMPHCItemTypeUserID.
 
 
 procedure:
 - format URL request
 - start connection to URL
 - implement delegate to get data when loading completes
 
 Example URL:
 HTTP get :
 
 Input
 http://61.66.229.118/PresenceServer/GetUserInformation?USERID=xxx&USER=userid1,-1@phone1,contact1@...@...@...&action=query&LANGUAGE=en
 
 http://mplusasps.tfn.net.tw/PresenceServer/GetUserInformation?USERID=xxx&USER=xxx,xxx&action=query&LANGUAGE=en&userType=phone
 
 Output
 Successful case
 
 (1) No M+ member found
 <GetUserInformation>
 <cause>0</cause>
 <text>
 null
 </text>
 </GetUserInformation>
 
 
 M+ member found
 
 <GetUserInformation>
 <cause>0</cause>
 <text>
 (+886911223344,10012345,1,61.66.229.112,192.168.1.23,John,6, 201108231435,上班,contactid)@
 (+886988776655,10002556,0,61.66.229.109, 61.66.229.109,Mary,0, 201108211030,sleep,contactid)@
 ....………… +
 (0225711172,20998124,0,61.66.229.131, 61.66.229.131,Hawk,1, 201107050916,出差contactid)
 </text>
 </GetUserInformation>
 
 
 Text format : (msisdn,USERID,presence,domain-address,from-address, nickname ,headshot, logintime,status,uid)
 Remark
 
 Presence: 0=offline 1=online -1=cancel (delete these users)
 uid: phonebook record ID
 
 
 當<query>Y</query>時，表示PS有資料需要Client來呼叫GetUserInformation(ACTION=queryM)作好友狀態更新，這時聯絡人非M+會員會變成該使用者的聯絡人好友

 */
- (void)getUserInformation:(NSArray *)queryItems action:(NSString *)action idTag:(NSString *)newID itemType:(NSString *)itemType {
    
    // default to query since it is not destructive
    //
    if (!action) {
        action = kMPHCQueryTagQuery;
    }
    
    // only allow these two options
    // - default is kMPHCItemTypeUserID
    NSString *queryItemType = kMPHCItemTypeUserID;
    if ([itemType isEqualToString:kMPHCItemTypePhone]) {
        queryItemType = itemType;
    }
    
    //NSString *countryCode = [self getCountryCode];
    //NSUInteger ccLength = [countryCode length];
    
    NSString *queryString = @"";
    
    // if phone numbers - add
    //
    if ([action isEqualToString:kMPHCQueryTagAddPhoneSync]) {
        //NSMutableArray *findPhones = [[NSMutableArray alloc] init];
        
        //for (NSString *iNumber in queryItems){
            
            // if international, strip out + sign and add
            //
            /*if ([iNumber hasPrefix:@"+"]) {
                [findPhones addObject:[[iNumber componentsSeparatedByString:@"+"] componentsJoinedByString:@""]];
            }
            // if phone is not international, prepend my country code
            //
            else {
                // number should be max 15 digits
                if ([iNumber length] + ccLength < 16 ) {
                    NSString *noZeroNumber = [AppUtility stripZeroPrefixForString:iNumber];
                    [findPhones addObject:[NSString stringWithFormat:@"%@%@", countryCode, noZeroNumber]];
                }
                // for long numbers, maybe already include cc
                else {
                    DDLogVerbose(@"HC-mff: WARN - number not added for find friends! %@", iNumber);
                }
            }*/
            
            // don't strip out zeros, PS should be able to handle this
            // - this will let us store numbers that are callable from this cell phone
            //[findPhones addObject:[AppUtility stripZeroPrefixForString:iNumber]];
        //}
        //queryString = [findPhones componentsJoinedByString:@"@"]; 
        //[findPhones release];

        // just combine all phone numbers together
        queryString = [queryItems componentsJoinedByString:@"@"];
    }
    // not phone numbers, userIDs
    //
    else if ([queryItems count] > 0){
        queryString = [queryItems componentsJoinedByString:@"@"]; 
    }
    // other wise queryString is @""
    
    // URL encode
    //NSString *encodedString = [Utility stringByAddingPercentEscapeEncoding:queryString];
    //queryString = [queryString stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    
    // modify addPhoneSync to add, since addPhoneSync is just an internal differentiator
    // for MPContactManager
    //
    NSString *urlAction = action;
    if ([action isEqualToString:kMPHCQueryTagAddPhoneSync]){
        urlAction = kMPHCQueryTagAdd;
    }
    else if ([action isEqualToString:kMPHCQueryTagQueryNoArguments]) {
        urlAction = kMPHCQueryTagQuery;
    }
     
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    NSString *language = [AppUtility devicePreferredLanguageCode];
    
    NSString *userParamComplete = @"";
    
    if ([queryString length] > 0) {
        NSString *userParam = [MPHTTPCenter httpRequestEncryptIfNeeded:queryString];
        NSString *escapedUserParam = [Utility stringByAddingPercentEscapeEncoding:userParam];
        userParamComplete = [NSString stringWithFormat:@"&USER=%@", escapedUserParam];
    }
    
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/GetUserInformation?action=%@&USERID=%@%@&LANGUAGE=%@&userType=%@%@",
                           kMPProtocol, self.serverHostPS, kMPParamServicePS, urlAction, userID,
                           userParamComplete, language, queryItemType, [MPHTTPCenter httpRequestEncodeFlag]];
    
    if (![AppUtility isUserIDValid:userID]) {
        DDLogError(@"HC: ERROR Invalid userID %@ query: %@", userID, urlString);
        return;
    }
    
    //NSError *error = nil;
    //NSString *testRes = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString] encoding:NSASCIIStringEncoding error:&error];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    
    // tag connection so we know what this query was about
    newConnection.typeTag = action;
    newConnection.idTag = newID;
    newConnection.delegate = self;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
}


#pragma mark - Notification Requests



/*!
 @abstract SetPushTokenID
 
 @param p2pTone P2P ring tone (optional)
 @param groupTone Group ring tone (optional)
 
 Input
 http://61.66.229.118/PushNotificationServer/SetPushTokenID?USERID=20114567
 &TOKEN=avaf33dsdsdsdsdsds&LANGUAGE=en
 Output
 
 Successful case
 <PushTokenID>
 <cause>0</cause>
 </PushTokenID>
 
 Exception case
 <PushTokenID>
 <cause>602</cause>
 <text>Invalid USERID!</text>
 </PushTokenID >
 
 
 */
- (void) setPushTokenID:(NSData *)tokenData p2pTone:(NSString *)p2pTone groupTone:(NSString *)groupTone{
    
    NSString *tokenString = [Utility stringWithHexFromData:tokenData];
    
    // create and send Cancel request
    //
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    NSString *language = [AppUtility devicePreferredLanguageCode];
    
    
    NSString *p2pString = @"";
    NSString *groupString = @"";
    
    if ([p2pTone length] > 0) {
        p2pString = [NSString stringWithFormat:@"&P2P_RINGTONE=%@", p2pTone];
    }
    if ([groupTone length] > 0) {
        groupString = [NSString stringWithFormat:@"&GROUP_RINGTONE=%@", groupTone];
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?USERID=%@&TOKEN=%@%@%@&LANGUAGE=%@%@", 
                           kMPProtocol, self.serverHostNS, kMPParamServiceNS, kMPHCRequestTypeSetPushTokenID, userID, tokenString, 
                           p2pString, groupString, language, [MPHTTPCenter httpRequestEncodeFlag]];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeSetPushTokenID;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
    
}


/*!
 @abstract setPushNotify Sets Push notification on or off
 
 Input
 http://61.66.229.118/PushNotificationServer/SetPushNotify?USERID=20114567&TYPE=group&ENABLE=Y&LANGUAGE=en
 
 Output
 Successful case
 <PushNotify>
 <cause>0</cause>
 </PushNotify>
 
 Exception case
 <PushNotify>
 <cause>602</cause>
 <text>Invalid USERID!</text>
 </PushNotify>
 
 */
- (void) setPushNotify:(BOOL)isPushOn isGroup:(BOOL)isGroup {
    
    NSString *enableString = isPushOn?@"Y":@"N";
    NSString *typeString = isGroup?@"group":@"p2p";
    
    // create and send Cancel request
    //
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    NSString *language = [AppUtility devicePreferredLanguageCode];
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?USERID=%@&TYPE=%@&ENABLE=%@&LANGUAGE=%@%@",
                           kMPProtocol, self.serverHostNS, kMPParamServiceNS, kMPHCRequestTypeSetPushNotify, userID, typeString, enableString, language, [MPHTTPCenter httpRequestEncodeFlag]];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeSetPushNotify;
    newConnection.idTag = kMPHCRequestTypeSetPushNotify;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
    
}


/*!
 @abstract setPNPreview Turns message preview on or off

 Input
 http://61.66.229.118/PushNotificationServer/SetPNPreview?USERID=20114567&TYPE=group&ENABLE=Y&LANGUAGE=en
 
 Output
 Successful case
 <PNPreview>
 <cause>0</cause>
 </PNPreview>
 
 Exception case
 <PNPreview>
 <cause>602</cause>
 <text>Invalid USERID!</text>
 </PNPreview>
 
 Remark
 用戶PNS設定存在PNS_SETTING table中，詳細table schema說明請看chapter 5 DB Schema
 */
- (void) setPNPreview:(BOOL)isPreviewOn isGroup:(BOOL)isGroup {
    
    NSString *enableString = isPreviewOn?@"Y":@"N";
    NSString *typeString = isGroup?@"group":@"p2p";
    
    // create and send Cancel request
    //
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    NSString *language = [AppUtility devicePreferredLanguageCode];
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?USERID=%@&TYPE=%@&ENABLE=%@&LANGUAGE=%@%@",
                           kMPProtocol, self.serverHostNS, kMPParamServiceNS, kMPHCRequestTypeSetPNPreview, userID, typeString, enableString, language, [MPHTTPCenter httpRequestEncodeFlag]];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeSetPNPreview;
    newConnection.idTag = kMPHCRequestTypeSetPNPreview;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
    
}


/*!
 @abstract setPNHiddenPreview Turns message preview on or off for hidden chats

 @param userID      ID of P2P chat to set as hidden chat - only define userID or groupID
 @param groupID     ID of group chat to set as hidden chat
 @param status      YES if set hidden chat, NO if not hidden chat
 @param disableAll  disable all hidden chats for this user
 
 Input
 http://61.66.229.118/PushNotificationServer/SetPNHidden?USERID=20114567&FROMID=20117890&GROUPID=12345&STATUS=Y&LANGUAGE=en
 
 Output
 
 Successful case
 <SetPNHidden>
 <cause>0</cause>
 </SetPNHidden>
 
 Exception case
 <SetPNHidden>
 <cause>602</cause>
 <text>Invalid USERID!</text>
 </SetPNHidden>
 
 Remark
 Hidden Chat設定存在PNS_HIDDEN table中，詳細table schema說明請看chapter 5 DB Schema
 
 */
- (void) setPNHiddenPreviewForUserID:(NSString *)newUserID groupID:(NSString *)groupID hiddenStatus:(BOOL)hiddenStatus disableAll:(BOOL)disable {
    
    NSString *hiddenStatusString = hiddenStatus?@"Y":@"N";
    NSString *disableString = disable?@"&DISABLE=Y":@"";
    
    // create and send Cancel request
    //
    NSString *myUserID = [MPHTTPCenter httpRequestUserID];
    NSString *language = [AppUtility devicePreferredLanguageCode];
    
    NSString *idString = nil;
    if ([AppUtility isUserIDValid:newUserID]) {
        NSString *encodedFrom = [MPHTTPCenter httpRequestEncryptIfNeeded:newUserID];
        NSString *escapedFrom= [Utility stringByAddingPercentEscapeEncoding:encodedFrom];
        idString = [NSString stringWithFormat:@"&FROMID=%@", escapedFrom];
    }
    else if ([groupID length] > 1) {
        idString = [NSString stringWithFormat:@"&GROUPID=%@", groupID];
    }
    else {
        idString = @"";
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?USERID=%@%@&STATUS=%@&LANGUAGE=%@%@%@",
                           kMPProtocol, self.serverHostNS, kMPParamServiceNS, kMPHCRequestTypeSetPNHidden, myUserID, idString, hiddenStatusString, language, disableString, [MPHTTPCenter httpRequestEncodeFlag]];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeSetPNHidden;
    newConnection.idTag = kMPHCRequestTypeSetPNHidden;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
}

/*!
 @abstract setPushRingTone Configure notification tone settings
 
 Input
 http://61.66.229.118/PushNotificationServer/SetPushRingTone?USERID=20114567
 &P2P_RINGTONE=Jingle.aiff&GROUP_RINGTONE=Jingle.aiff&LANGUAGE=en
 
 Output
 Successful case
 <SetPushRingTone>
 <cause>0</cause>
 </SetPushRingTone>
 
 Exception case
 <SetPushRingTone>
 <cause>602</cause>
 <text>Invalid USERID!</text>
 </SetPushRingTone>
 
 Remark
 Ringtone設定存在PNS_SETTING table中，詳細table schema說明請看chapter 5 DB Schema
 
 */
- (void) setPushRingToneP2P:(NSString *)p2pTone groupTone:(NSString *)groupTone {
    
    // create and send Cancel request
    //
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    NSString *language = [AppUtility devicePreferredLanguageCode];
    
    NSString *p2pString = @"";
    NSString *groupString = @"";
    
    if ([p2pTone length] > 0) {
        p2pString = [NSString stringWithFormat:@"&P2P_RINGTONE=%@", p2pTone];
    }
    if ([groupTone length] > 0) {
        groupString = [NSString stringWithFormat:@"&GROUP_RINGTONE=%@", groupTone];
    }
    
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?USERID=%@%@%@&LANGUAGE=%@%@",
                           kMPProtocol, self.serverHostNS, kMPParamServiceNS, kMPHCRequestTypeSetPushRingTone, userID, p2pString, groupString, language, [MPHTTPCenter httpRequestEncodeFlag]];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeSetPushRingTone;
    newConnection.idTag = kMPHCRequestTypeSetPushRingTone;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
    
}

#pragma mark - M+ ID Methods




/*! 
 @abstract Create a M+ID
 @discussion also checks for duplicate, but use search for this instead
 
 
 Example URL:
 
 Input
 http://61.66.229.118/PresenceServer/CreateMPID?USERID=20114567&MPID=NaturalTel-Julian&LANGUAGE=en
 
 Output
 Successful case
 
 <CreateMPID>
 <cause>0</cause>
 </CreateMPID>
 
 Exception case
 
 <CreateMPID>
 <cause>705</cause>
 <text>MPID duplicated !</text>
 </CreateMPID>
 
 
 @param msisdn unique phone number to register for this client
 */
- (void)createID:(NSString *)idString {
    
    NSString *escapedID = [MPHTTPCenter httpRequestEncodeUTF8Latin1PercentEscape:idString];
    
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    NSString *language = [AppUtility devicePreferredLanguageCode];

    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?USERID=%@&MPID=%@&LANGUAGE=%@%@", 
                           kMPProtocol, self.serverHostPS, kMPParamServicePS, kMPHCRequestTypeCreateMPID, userID, escapedID, language, [MPHTTPCenter httpRequestEncodeFlag]];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeCreateMPID;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
}


/*! 
 @abstract Search a M+ID
 @discussion used for finding duplicate and finding contacts
 
 
 Example URL:
 
 HTTP get : https://61.66.229.118/SearchMPID?MPID=NaturalTel-Julian MPID : User defined unique ID for searching purpose . Max 24 bytes .
 HTTP response :
 Success:
 
 <SearchMPID>
    <cause>0</cause>
    <text>(+886934363874,00000223,1,175.99.90.201:80,10.39.106.3,Dennn,7,201204060918,At work &,-1)</text>
 </SearchMPID>

 
 */
- (void)searchID:(NSString *)idString {
        
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    NSString *escapedID = [MPHTTPCenter httpRequestEncodeUTF8Latin1PercentEscape:idString];
    NSString *language = [AppUtility devicePreferredLanguageCode];

    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?MPID=%@&LANGUAGE=%@&USERID=%@%@", 
                           kMPProtocol, self.serverHostPS, kMPParamServicePS, kMPHCRequestTypeSearchMPID, escapedID, language, userID, [MPHTTPCenter httpRequestEncodeFlag]];
    
    TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
    newConnection.delegate = self;
    newConnection.typeTag = kMPHCRequestTypeSearchMPID;
    [newConnection connect];
    [[self getConnections] addObject:newConnection];
    [newConnection release];
}

/*! 
 @abstract Prevent a M+ID from being searched
 
 @param shouldAllowSearch   Turn search on or off
 @param newIDTag            String to identify this request - usually set to your userID
 
 @discussion stop others from finding you via your ID
 
 HTTP get : https://61.66.229.118/CloseMPID?USERID=20114567&MPID=NaturalTel-Julian USERID : Message Plus user-ID : 8 digits ( 00000001 ~ 99999999 ) , unique number of system . MPID : User defined unique ID for searching purpose . Max 24 bytes .
 HTTP response :
 Success:
 < CloseMPID > <cause>0</cause>
 </ CloseMPID >
 Error:
 < CloseMPID > <cause>602</cause>
 <text>invalid USERID !</text> </ CloseMPID >
 
 
 */
- (void)setSearchID:(BOOL)shouldAllowSearch idTag:(NSString *)newIDTag {

    NSString *userID = [MPHTTPCenter httpRequestUserID];
    NSString *mpID = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingMPID];
    NSString *language = [AppUtility devicePreferredLanguageCode];

    NSString *escapedID = [Utility stringByAddingPercentEscapeEncoding:mpID];

    // note: logic is reversed.
    // - allow search -> close=N
    // - disable search -> close=Y
    NSString *shouldSearchString = shouldAllowSearch?@"N":@"Y";
    
    // only if mpID exists
    //
    if ([mpID length] > 2) {
        NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?USERID=%@&MPID=%@&CLOSE=%@&LANGUAGE=%@%@", 
                               kMPProtocol, self.serverHostPS, kMPParamServicePS, kMPHCRequestTypeCloseMPID, userID, escapedID, shouldSearchString, language, [MPHTTPCenter httpRequestEncodeFlag]];
        
        TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:YES];
        newConnection.delegate = self;
        newConnection.typeTag = kMPHCRequestTypeCloseMPID;
        newConnection.idTag = newIDTag;
        [newConnection connect];
        [[self getConnections] addObject:newConnection];
        [newConnection release];
    }

}


/*! 
 @abstract Allow a M+ID from being searched
 @discussion 
 
 xxx
 
 

- (void)openID {
    
    NSString *userID = [MPHTTPCenter httpRequestUserID];
    NSString *mpID = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingMPID];
    NSString *language = [AppUtility devicePreferredLanguageCode];
    
    NSString *escapedID = [Utility createStringByAddingPercentEscape:mpID];
    
    // only if mpID exists
    //
    if ([mpID length] > 2) {
        NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@?USERID=%@&MPID=%@&LANGUAGE=%@", 
                               kMPProtocol, self.serverHostPS, kMPParamServicePS, kMPHCRequestTypeOpenMPID, userID, escapedID, language];
        TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString];
        newConnection.delegate = self;
        newConnection.typeTag = kMPHCRequestTypeOpenMPID;
        [newConnection connect];
        [[self getConnections] addObject:newConnection];
        [newConnection release];
    }
    [escapedID release];
}*/



#pragma mark - Google MAP API Requests

/*! 
 @abstract Request Forward Geocoding Data
 
 @param addressString   Address that we want to get the coordinate for
 
 Request:
 http://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA&sensor=true

 
 * latlng      Coordinate you want to geocode
 * sensor      If client has sensor
 * language    Language of the client device
 
 
 NSString* const kMPProtocolGoggle = @"http";
 NSString* const kMPParamServerGoggle = @"maps.googleapis.com";
 NSString* const kMPParamServiceMaps = @"maps/api";
 
 NSString* const kMPHCRequestTypeMapGeocode = @"geocode";
 NSString* const kMPHCRequestTypeMapPlaceSearch = @"place/search";
 
 */
- (void)mapForwardGeocodeAddress:(NSString *)address idTag:(NSString *)idTag {
    
    NSString *language = [AppUtility devicePreferredLanguageCodeGoogle];
    
    NSString *addressString = @"";
    if (address) {
        NSString *addressEscaped = [Utility stringByAddingPercentEscapeEncoding:address];
        addressString = [NSString stringWithFormat:@"%@", addressEscaped];
    }
    
    // only if mpID exists
    //
    if ([address length] > 0) {
        NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@/json?address=%@&sensor=true&language=%@", 
                               kMPProtocolGoggle, kMPParamServerGoggle, kMPParamServiceMaps, kMPHCRequestTypeMapGeocode, addressString, language];
        TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString];
        newConnection.delegate = self;
        newConnection.typeTag = kMPHCRequestTypeMapForwardGeocode;  // just a tag - real request still use plain geocode
        newConnection.idTag = idTag;
        newConnection.responseFormat = TTURLResponseFormatJSON;
        [newConnection connect];
        [[self getConnections] addObject:newConnection];
        [newConnection release];
    }    
}

/*! 
 @abstract Request Reverse Geocoding Data
 
 @param coordinate The location that we need an address for.
 
 Request:
 http://maps.googleapis.com/maps/api/geocode/json?latlng=40.714224,-73.961452&sensor=true&language=en

  * latlng      Coordinate you want to geocode
  * sensor      If client has sensor
  * language    Language of the client device
 
 
 NSString* const kMPProtocolGoggle = @"http";
 NSString* const kMPParamServerGoggle = @"maps.googleapis.com";
 NSString* const kMPParamServiceMaps = @"maps/api";
 
 NSString* const kMPHCRequestTypeMapGeocode = @"geocode";
 NSString* const kMPHCRequestTypeMapPlaceSearch = @"place/search";
 
 */
- (void)mapReverseGeocode:(CLLocationCoordinate2D)coordinate idTag:(NSString *)idTag {
    
    NSString *language = [AppUtility devicePreferredLanguageCodeGoogle];
    
    NSString *lat = [NSString stringWithFormat:@"%f", coordinate.latitude];
    NSString *lng = [NSString stringWithFormat:@"%f", coordinate.longitude];
    
    // only if mpID exists
    //
    if ([lat length] > 0 && [lng length] > 0) {
        NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/%@/json?latlng=%@,%@&sensor=true&language=%@", 
                               kMPProtocolGoggle, kMPParamServerGoggle, kMPParamServiceMaps, kMPHCRequestTypeMapGeocode, lat, lng, language];
        TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString];
        newConnection.delegate = self;
        newConnection.typeTag = kMPHCRequestTypeMapGeocode;
        newConnection.idTag = idTag;
        newConnection.responseFormat = TTURLResponseFormatJSON;
        [newConnection connect];
        [[self getConnections] addObject:newConnection];
        [newConnection release];
    }    
}


/*! 
 @abstract Request Place Search
 
 @param coordinate  The location center that we are searching near
 @param radius      Vicinity in meter from center to search within
 @param keyword     Search string - optional
 @param type        Types of places to search for - at least one type should match - optional
 @param idTag       Used to identify this request
 
 Request:
 * https://maps.googleapis.com/maps/api/place/search/json?location=-33.8670522,151.1957362&radius=500&types=food&name=harbour&sensor=false&key=AddYourOwnKeyHere
 
 
 NSString* const kMPProtocolGoggle = @"http";
 NSString* const kMPParamServerGoggle = @"maps.googleapis.com";
 NSString* const kMPParamServiceMaps = @"maps/api";
 
 NSString* const kMPHCRequestTypeMapGeocode = @"geocode";
 NSString* const kMPHCRequestTypeMapPlaceSearch = @"place/search";
 
 */
- (void)mapPlaceSearch:(CLLocationCoordinate2D)coordinate radiusMeters:(CGFloat)radius keyword:(NSString *)keyword type:(NSString *)type idTag:(NSString *)idTag {
    
    NSString *language = [AppUtility devicePreferredLanguageCodeGoogle];
    
    NSString *lat = [NSString stringWithFormat:@"%f", coordinate.latitude];
    NSString *lng = [NSString stringWithFormat:@"%f", coordinate.longitude];
    
    NSString *keywordString = @"";
    if (keyword) {
        NSString *escapedKeyword = [Utility stringByAddingPercentEscapeEncoding:keyword];
        keywordString = [NSString stringWithFormat:@"&keyword=%@", escapedKeyword];
    }
    
    NSString *typeString = @"";
    if (type) {
        NSString *escapedType = [Utility stringByAddingPercentEscapeEncoding:type];
        typeString = [NSString stringWithFormat:@"&types=%@", escapedType];

    }
    
    // only if mpID exists
    // 
    if ([lat length] > 0 && [lng length] > 0) {
        NSString *urlString = [NSString stringWithFormat:@"https://%@/%@/%@/json?location=%@,%@&radius=%f%@%@&sensor=true&language=%@&key=%@", 
                               kMPParamServerGoggle, 
                               kMPParamServiceMaps, 
                               kMPHCRequestTypeMapPlaceSearch, 
                               lat, lng, radius,
                               keywordString, typeString, language,
                               kMPParamGoogleAPIKey];
        
        TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString];
        newConnection.delegate = self;
        newConnection.typeTag = kMPHCRequestTypeMapPlaceSearch;
        newConnection.idTag = idTag;
        newConnection.responseFormat = TTURLResponseFormatJSON;
        [newConnection connect];
        [[self getConnections] addObject:newConnection];
        [newConnection release];
    }    
}

#pragma mark - Response Handler

/*!
 @abstract Process helper message response
 
 */
- (void) handleSendHelperMessageResponseDictionary:(NSDictionary *)responseDictionary {
    
    // request was successful
    // - mark this as done
    //
    if ([MPHTTPCenter getCauseForResponseDictionary:responseDictionary] == kMPCauseTypeSuccess) {
        
        [[MPSettingCenter sharedMPSettingCenter] markFirstStartTagComplete:kMPHCRequestTypeSendHelperMessage];

    }
    // if failed
    else {
        // faile silently
    }
}




/*!
 @abstract Gets response code
 
 Use:
 compare it to cause types to understand the results
 */
+ (NSInteger)getCauseForResponseDictionary:(NSDictionary *)responseD {
    
    NSString *cause = [responseD valueForKey:@"cause"];
    return [cause intValue];
    
}

#define INVALID_IMEI_ALERT_TAG  19001


/*!
 @abstract handles response from MP service requests
 
 @param responseDictionary - hold response results
        if only kRootElementName exists, then connection failure!
 
 @param queryTag used to help identify the original request
 
 @discussion
 
 Handler should receive results and perform basic processing so code is not
 repeated in VCs that request these queries.  However, VCs should check for failure
 and handle them according to the given context.
 
 */
- (void) responseDictionaryHandler:(NSDictionary *)responseDictionary {
   
    BOOL showAlert = NO;

    NSInteger causeResult = [MPHTTPCenter getCauseForResponseDictionary:responseDictionary];
    NSString *responseType = [responseDictionary valueForKey:kTTXMLRootElementName];
    NSString *queryTypeTag = [responseDictionary valueForKey:kTTXMLTypeTag];

    
    // Decrypt response
    [MPHTTPCenter httpResponseDecrypt:responseDictionary responseType:responseType cause:causeResult];
    
    DDLogInfo(@"HC-RDH: got dictionary - %@", responseDictionary);

    // Don't disable indicator when these results return
    // - userinfo - usually runs w/o an indicator
    // - let cancel need indicator running
    // - authen during name registration should not shot indicator
    //
    if (![responseType isEqualToString:kMPHCRequestTypeGetUserInformation] &&
        ![responseType isEqualToString:kMPHCRequestTypeCancel] &&
        ![responseType isEqualToString:@"authentication"]){
        DDLogInfo(@"HC-rdh: stop activity request: %@", responseType);
        [AppUtility stopActivityIndicator];
    }

    /*
     - Update core data with presence results
     - Process and send notification with results
     
     */
    if ([responseType isEqualToString:kMPHCRequestTypeGetUserInformation]) {

        // don't show alert, since text is normal key here
        showAlert = NO;
        
        // save domain and authentication key
        //
        NSString *presenceInfo = [responseDictionary valueForKey:@"text"];
    
        // replace presence in response dictionary
        NSArray *presenceArray = [MPPresence getArrayFromPresence:presenceInfo];
        
        // make sure latest results are also updated to the core data
        // - run in background thread so large query does not block
        //
        dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
        
        dispatch_async(back_queue, ^{
            [[AppUtility getBackgroundContactManager] processGetUserInformation:presenceArray responseDictionary:responseDictionary];
        });
        
        // Post notification with results in "array"
        //
        NSMutableDictionary *newD = [[NSMutableDictionary alloc] initWithDictionary:responseDictionary];
        [newD setValue:presenceArray forKey:@"array"];
             
        DDLogInfo(@"HC: posting new GETUSERINFO notif");
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_GETUSERINFO_NOTIFICATION object:newD];
        
        // post add specific results
        if ([queryTypeTag isEqualToString:kMPHCQueryTagAdd]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_GETUSERINFO_ADD_NOTIFICATION object:newD];
        }
        
        [newD release];
        
    }
    else if ([responseType isEqualToString:kMPHCRequestTypeQueryOperator]){
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_QUERYOPERATOR_NOTIFICATION object:responseDictionary];
    }
    else if ([responseType isEqualToString:kMPHCRequestTypeUpdateNickname]){
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_UPDATE_NICKNAME_NOTIFICATION object:responseDictionary];
    }
    else if ([responseType isEqualToString:kMPHCRequestTypeUpdateStatus]){
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_UPDATE_STATUS_NOTIFICATION object:responseDictionary];
    }
    else if ([responseType isEqualToString:kMPHCRequestTypeUpdateHeadshot]){
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_UPDATE_HEADSHOT_NOTIFICATION object:responseDictionary];
    }
    else if ([responseType isEqualToString:kMPHCRequestTypeCreateMPID]){
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_CREATEID_NOTIFICATION object:responseDictionary];
    }
    else if ([responseType isEqualToString:kMPHCRequestTypeSearchMPID]){
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_SEARCHID_NOTIFICATION object:responseDictionary];
    }
    else if ([responseType isEqualToString:kMPHCRequestTypeCloseMPID]){
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_CLOSEID_NOTIFICATION object:responseDictionary];
    }
    else if ([responseType isEqualToString:kMPHCRequestTypeOpenMPID]){
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_OPENID_NOTIFICATION object:responseDictionary];
    }
    // Push Notification Responses
    //
    else if ([queryTypeTag isEqualToString:kMPHCRequestTypeSetPNHidden]){
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_SET_PN_HIDDEN_NOTIFICATION object:responseDictionary];
    }
    else if ([queryTypeTag isEqualToString:kMPHCRequestTypeSetPNPreview]){
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_SET_PN_PREVIEW_NOTIFICATION object:responseDictionary];
    }
    else if ([queryTypeTag isEqualToString:kMPHCRequestTypeSetPushNotify]){
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_SET_PUSH_NOTIFY_NOTIFICATION object:responseDictionary];
    }
    else if ([queryTypeTag isEqualToString:kMPHCRequestTypeSetPushRingTone]){
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_SET_PUSH_RINGTONE_NOTIFICATION object:responseDictionary];
    }
    // Block Responses
    //
    else if ([responseType isEqualToString:kMPHCRequestTypeBlock]){
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_BLOCK_NOTIFICATION object:responseDictionary];
    }
    else if ([responseType isEqualToString:kMPHCRequestTypeUnBlock]){
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_UNBLOCK_NOTIFICATION object:responseDictionary];
    }
    else if ([responseType isEqualToString:@"Presence"]){ // different from request string
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_PRESENCEPERMISSION_NOTIFICATION object:responseDictionary];
    }
    else if ([responseType isEqualToString:kMPHCRequestTypeGetResourceDownloadInfo]){
        
        DDLogInfo(@"HC: got resource xml");

        if (causeResult == kMPCauseTypeSuccess) {
            [[MPResourceCenter sharedMPResourceCenter] updateCDResourceWithXML:responseDictionary];
        }
        else {
            DDLogError(@"HC: error getting resource xml");
        }
    }
    else if ([responseType isEqualToString:kMPHCRequestTypeCancel]){
        
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_CANCEL_NOTIFICATION object:responseDictionary];
    }
    else if ([responseType isEqualToString:@"PushTokenID"]){ //kMPHCRequestTypeSetPushTokenID]){
        // got token response
        DDLogInfo(@"HC-rdh: got set token response - %@", responseDictionary);
        
        if (causeResult == kMPCauseTypeSuccess) {
            // set last date to now
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPushNotificationRegisterLastCompleteDate settingValue:[NSDate date]];
        }
        else {
            //NSString *debug = [NSString stringWithFormat:@"Submit Failed: %@", responseDictionary];
        }
        /* test
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"PNS Response: %@", responseType]
														 message:[responseDictionary description]
														delegate:nil
											   cancelButtonTitle:@"OK"
											   otherButtonTitles:nil] autorelease];
		[alert show];*/
    }
    else if ([responseType isEqualToString:kMPHCRequestTypeSMS]){
        
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_SMS_NOTIFICATION object:responseDictionary];
    }
    else if ([responseType isEqualToString:kMPHCRequestTypeSendHelperMessage]){
        
        [self handleSendHelperMessageResponseDictionary:responseDictionary];
        
        //[[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_SEND_HELPER_MESSAGE_NOTIFICATION object:responseDictionary];
    }
    // response for sending phone number 
    //
    else if ([responseType isEqualToString:@"msisdnverification"]) {
        
        // don't show alert, since text is normal key here
        showAlert = NO;
        
        // if ok, then just wait for code
        DDLogInfo(@"HC-rdh: got verification results");
        
        // save userID
        //
        if (causeResult == kMPCauseTypeSuccess) {
            // inform VC we can go to next step - register
            //
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_MSISDN_SUCCESS_NOTIFICATION object:nil];
            
        }
        // code verification failed
        else if (causeResult == kMPCauseTypeMultipleDeviceRegistration ){
            // if 608 - multiple registration then warn users and ask if they like to proceed
            //
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_MSISDN_MULTIDEVICE_NOTIFICATION object:nil];
        }
        // server thinks we should force update
        //
        else if (causeResult == kMPCauseTypeForceUpdate) {
            DDLogInfo(@"HC-rdh: force update requested by server");
            
            // reset phone number so we don't proceed to next view
            //
            [[MPSettingCenter sharedMPSettingCenter] resetMSISDN];
            
            NSString* serverText = [responseDictionary valueForKey:@"text"];
            dispatch_async(dispatch_get_main_queue(), ^{
                // show force update if needed
                [AppUtility showAppUpdateView:serverText];
            });
        }
        // msisdn verification failed
        // - possible: invalid msisdn
        // - show text message
        else {
            NSString *message = [responseDictionary valueForKey:@"text"];
            if (message) {
                NSString *title = NSLocalizedString(@"Phone Registration", @"PhoneRegistraiton - title: error occurred");
                [Utility showAlertViewWithTitle:title message:message];
            }
        }
        
    }
    // response for sending verification code
    //
    else if ([responseType isEqualToString:@"registration"]) {
        // save userID
        //
        if (causeResult == kMPCauseTypeSuccess) {
            NSString *userID = [responseDictionary valueForKey:@"USERID"];
            if ([AppUtility isUserIDValid:userID]) {
                DDLogInfo(@"HC-rdh: Registration successful userID - %@", userID);
                
                // save user ID
                //[[MPSettingCenter sharedMPSettingCenter] setSecureValueForID:kMPSettingUserID settingValue:userID];
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingUserID settingValue:userID];
                
                
                // recover nickname if available
                NSString *nickname = [responseDictionary valueForKey:@"NICKNAME"];
                if ([nickname length] > 0) {
                    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingNickName settingValue:nickname];
                }
                
                // get friends now - while user is entering name
                [MPContactManager tryStartingPhoneBookSyncForceStart:NO delayed:YES];
                
                // @DISABLE - wait until after login is successful
                // try registering for push notification
                //BOOL popOn = [[[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPushPopUpIsOn] boolValue];
                //[[AppUtility getAppDelegate] tryRegisterPushNotificationForceStart:YES enableAlertPopup:popOn];
                
                // post notification so VC can go to the next step
                //
                [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_CODE_VERIFICATION_SUCCESS object:nil];
                
                // Recover related user information - headshot serial number
                [CDContact mySelf]; // create contact first, so data can be updated
                [self getUserInformation:[NSArray arrayWithObject:userID] action:kMPHCQueryTagQuery idTag:nil itemType:kMPHCItemTypeUserID];
            }
            else {
                DDLogError(@"HC-rdh: ERROR - registration failed - invalid userID %@", userID);
                // inform VC of failure
                //
                [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_CODE_VERIFICATION_FAILURE object:nil];
            }
        }
        // code verification failed
        else {
            // inform VC of failure
            //
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_CODE_VERIFICATION_FAILURE object:responseDictionary];
        }
        
    }
    /*
     Get authentication key & domain cluster and try login

     Example response:
     
        "ALERT_GROUP" = Y;
        "ALERT_P2P" = Y;
        "PREVIEW_GROUP" = Y;
        "PREVIEW_P2P" = Y;
     
        "BLOCK_USERS" = "00000035,00000037,00000036";
        CLOSEMPID = N;
        MPID = mtsai;
        SHOWPRESENCE = Y;
        STATUSMESSAGE = "I am using M+ app";
     
        akey = 1912540;
        cause = 0;
        domain = "61.66.229.120:80";
        text = "You have 30 SMS quota.....";
     */
    else if ([responseType isEqualToString:@"authentication"]) {
        
        if (causeResult == kMPCauseTypeSuccess) {
            
            // save domain and authentication key
            //
            NSString *domain = [responseDictionary valueForKey:@"domain"];
            if ([domain length] > 0) {
                [[AppUtility getSocketCenter] setDomainClusterName:domain];
                
                // also update the my CDContact
                [CDContact updateMyNickname:nil domainClusterName:domain domainServerName:nil statusMessage:nil];
            }
            NSString *authKey = [responseDictionary valueForKey:@"akey"];
            if ([authKey length] > 0) {
                [[MPSettingCenter sharedMPSettingCenter] setSecureValueForID:kMPSettingAuthKey settingValue:authKey];
            }
            
            NSString *mpid = [responseDictionary valueForKey:@"MPID"];
            if ([mpid length] > 0) {
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingMPID settingValue:mpid];
            }
            
            // if status is blank, store @""
            NSString *statusMsg = [responseDictionary valueForKey:@"STATUSMESSAGE"];
            NSString *storeStatus = ([statusMsg length] > 0)?statusMsg:@"";
            [[MPSettingCenter sharedMPSettingCenter] setMyStatusMessage:storeStatus];

            
            NSString *closeMPID = [responseDictionary valueForKey:@"CLOSEMPID"];
            if ([closeMPID length] > 0) {
                NSNumber *searchBool = [NSNumber numberWithBool:YES]; // allow search
                if ([closeMPID isEqualToString:@"Y"]) {
                    searchBool = [NSNumber numberWithBool:NO];
                }
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingMPIDSearch settingValue:searchBool];
            }
            
            NSString *showPresence = [responseDictionary valueForKey:@"SHOWPRESENCE"];
            if ([showPresence length] > 0) {
                NSNumber *presenceBool = [NSNumber numberWithBool:YES]; // show presence by default
                if ([showPresence isEqualToString:@"N"]) {
                    presenceBool = [NSNumber numberWithBool:NO];
                }
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPresencePermission settingValue:presenceBool];
            }
            
            // - ALERT_P2P=Y/N, ALERT_GROUP=Y/N, PREVIEW_P2P=Y/N, GROUP_P2P=Y/N
            // - RINGTONE_P2P, RINGTONE_GROUP, BLOCK_USERS(userid,userid,..)
            
            // Recover notification settings
            //
            NSString *alertP2P = [responseDictionary valueForKey:@"ALERT_P2P"];
            if ([alertP2P length] > 0) {
                BOOL alertP2POn = [alertP2P isEqualToString:@"Y"]?YES:NO;
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPushP2PAlertIsOn settingValue:[NSNumber numberWithBool:alertP2POn]];
            }
            NSString *alertGroup = [responseDictionary valueForKey:@"ALERT_GROUP"];
            if ([alertGroup length] > 0) {
                BOOL alertGroupOn = [alertGroup isEqualToString:@"Y"]?YES:NO;
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPushGroupAlertIsOn settingValue:[NSNumber numberWithBool:alertGroupOn]];
            }
            NSString *previewP2P = [responseDictionary valueForKey:@"PREVIEW_P2P"];
            if ([previewP2P length] > 0) {
                BOOL previewP2POn = [previewP2P isEqualToString:@"Y"]?YES:NO;
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPushP2PPreviewIsOn settingValue:[NSNumber numberWithBool:previewP2POn]];
            }
            NSString *previewGroup = [responseDictionary valueForKey:@"PREVIEW_GROUP"];
            if ([previewGroup length] > 0) {
                BOOL previewGroupOn = [previewGroup isEqualToString:@"Y"]?YES:NO;
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPushGroupPreviewIsOn settingValue:[NSNumber numberWithBool:previewGroupOn]];
            }
            NSString *ringP2P = [responseDictionary valueForKey:@"RINGTONE_P2P"];
            if ([ringP2P length] > 0) {
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPushP2PRingTone settingValue:ringP2P];
            }
            NSString *ringGroup = [responseDictionary valueForKey:@"RINGTONE_GROUP"];
            if ([ringGroup length] > 0) {
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPushGroupRingTone settingValue:ringGroup];
            }
            
            
            // now try logging in
            // - but only if nickname is set, AS requires this otherwise authentication will fail
            //
            if ([self isNameRegistered]){
                DDLogVerbose(@"HC-rdh: Authen ok - now try login");
                [[AppUtility getSocketCenter] loginAndConnect];
            }
            
            // post notification
            // - to inform name registration that it can continue and register nickname
            //
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_AUTHENTICATION_NOTIFICATION object:responseDictionary];
            
            
        }
        // this is normally caused by registering on another device
        // - so this device will be reset!
        else if (causeResult == kMPCauseTypeInvalidIMEI) {
        
            // Show - "account transferred to another device so delete"
            //
            NSString *alertMessage = [responseDictionary valueForKey:@"text"];

            // show system alert message
            if ([alertMessage length] > 0 && ![Utility doesAlertViewExistWithTag:INVALID_IMEI_ALERT_TAG]){
                NSString *alertTitle = NSLocalizedString(@"Authentication Failed", @"HTTPRequest: Invalid IMEI detected, so account will be deleted.");
                [Utility showAlertViewWithTitle:alertTitle message:alertMessage delegate:self tag:INVALID_IMEI_ALERT_TAG];
            }
        
        }
        // Another possible result is 602 - invalid user ID - if we suspend or shutdown account??
        
        // TODO: What if authentication fails
        // - this means that the userID has failed.. this should not happen
        // - but if it does, re-register! - or users has to delete account
        
    }
    // get phone number from TWM reverse ip lookup service, save it so users can use it in registration
    //
    else if ([responseType isEqualToString:@"ipquerymsisdn"]) {
        
        DDLogInfo(@"HC-rdh: got set token response - %@", responseDictionary);
        
        if (causeResult == kMPCauseTypeSuccess) {
            NSString *phoneLookup = [responseDictionary valueForKey:@"msisdn"];

            // only if correct format is provided
            if ([phoneLookup length] == 12) {
                NSString *cc = [phoneLookup substringWithRange:NSMakeRange(0, 3)];
                NSString *ph = [phoneLookup substringWithRange:NSMakeRange(3, 9)];
                
                // these settings will let phone view to fill in form for user
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPhoneCountryCode settingValue:cc];
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPhoneNumber settingValue:ph];
                
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingTWM3GIPUsed settingValue:[NSNumber numberWithBool:YES]];
            }
        }
        // notify view that we are finished
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_IPQUERY_MSISDN_NOTIFICATION object:responseDictionary];    
    }
    else {
        
        DDLogInfo(@"HC-RDH: ERROR invalid response obtained - %@", responseDictionary);
        return;
    }

    NSString *alertMessage = nil;
    if (showAlert) {
        alertMessage = [responseDictionary valueForKey:@"text"];
    }
    
    // show system alert message
    if ([alertMessage length] > 0){
        
        [Utility showAlertViewWithTitle:NSLocalizedString(@"M+ Alert", @"HTTPRequest: alert message received from servers") message:alertMessage];
    }
}



/*!
 @abstract handles JSON response from Google Services
 
 @param jsonObject Parsed result object from request
 @param typeTag Identify type of request
 @param idTag Identify the request uniquely
 
 Handler should receive results and perform basic processing so code is not
 repeated in VCs that request these queries.  However, VCs should check for failure
 and handle them according to the given context.
 
 extern NSString* const kTTXMLTypeTag;
 extern NSString* const kTTXMLIDTag;
 
 == Status results from Geocode requests ==
 "OK"               indicates that no errors occurred; the address was successfully parsed and at least one geocode was returned.
 "ZERO_RESULTS"     indicates that the geocode was successful but returned no results. This may occur if the geocode was passed a non-existent address or a latlng in a remote location.
 "OVER_QUERY_LIMIT" indicates that you are over your quota.
 "REQUEST_DENIED"   indicates that your request was denied, generally because of lack of a sensor parameter.
 "INVALID_REQUEST"  generally indicates that the query (address or latlng) is missing.
 
 
 */
- (void) responseHandlerJSONObject:(id)jsonObject typeTag:(NSString *)typeTag idTag:(NSString *)idTag {
    
    //BOOL showAlert = NO;
    //DDLogVerbose(@"HC-RDH: got json object - %@", jsonObject);
    
    if (jsonObject && typeTag && idTag) {
        NSDictionary *responseDictionary = [NSDictionary dictionaryWithObjectsAndKeys:jsonObject, kMPHCJsonKeyJsonObject, 
                                            typeTag, kTTXMLTypeTag, idTag, kTTXMLIDTag, nil];
                                            
        if ([typeTag isEqualToString:kMPHCRequestTypeMapGeocode]){
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_REVERSE_GEOCODE_NOTIFICATION object:responseDictionary];
        }
        else if ([typeTag isEqualToString:kMPHCRequestTypeMapForwardGeocode]){
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_FORWARD_GEOCODE_NOTIFICATION object:responseDictionary];
        }
        else if ([typeTag isEqualToString:kMPHCRequestTypeMapPlaceSearch]){
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_PLACE_SEARCH_NOTIFICATION object:responseDictionary];
        }
    }
}

#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {

    // tap ok, then start to delete account
    //
    if (alertView.tag == INVALID_IMEI_ALERT_TAG) {        
        
        [AppUtility startActivityIndicator];
        // delete everything and restart
        [[AppUtility getAppDelegate] startFromScratchWithFullSettingReset:YES];
        
    }
    
}

#pragma mark - TTURLConnection Delegate


/*!
 @abstract Make sure user entered info is encoded since they may include bad characters
 
 - This prevent illegal character from messing up XML encoding.
 - <GetUserInformation>'s <text>content</text>
 - <authentication>'s <STATUSMESSAGE>At work &</STATUSMESSAGE>
 
 @return Data to be parsed by XML parser
 
 */
- (NSData *) encodeUserInputElements:(NSData *)data {
    
    NSData *retData = nil;
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // only this request has user related data
    //
    if ([dataString hasPrefix:@"<GetUserInformation>"] ||
        [dataString hasPrefix:@"<SearchMPID>"]) {
      
        // find <text></text> and encode it's contents
        //
        NSRange startRange = [dataString rangeOfString:@"<text>"];
        NSRange endRange = [dataString rangeOfString:@"</text>"];
        
        if (startRange.location != NSNotFound &&
            endRange.location != NSNotFound &&
            endRange.location > startRange.location) {
            
            NSUInteger textLocation = startRange.location+startRange.length;
            NSUInteger textlength = endRange.location - textLocation;
            NSRange textRange = NSMakeRange(textLocation, textlength);
            
            NSString *textContent = [dataString substringWithRange:textRange];
            NSString *encodedText = [Utility stringByAddingPercentEscapeEncoding:textContent];
            
            NSString *encodedString = [dataString stringByReplacingCharactersInRange:textRange withString:encodedText];
            NSData *encodedData = [encodedString dataUsingEncoding:NSUTF8StringEncoding];
            
            retData = encodedData;
            
        }
        else {
            retData = data;
        }
        
    }
    else if ([dataString hasPrefix:@"<authentication>"]) {
        
        // find <STATUSMESSAGE></STATUSMESSAGE> and encode it's contents
        //
        NSRange startRange = [dataString rangeOfString:@"<STATUSMESSAGE>"];
        NSRange endRange = [dataString rangeOfString:@"</STATUSMESSAGE>"];
        
        if (startRange.location != NSNotFound &&
            endRange.location != NSNotFound &&
            endRange.location > startRange.location) {
            NSUInteger textLocation = startRange.location+startRange.length;
            NSUInteger textlength = endRange.location - textLocation;
            NSRange textRange = NSMakeRange(textLocation, textlength);
            
            NSString *textContent = [dataString substringWithRange:textRange];
            NSString *encodedText = [Utility stringByAddingPercentEscapeEncoding:textContent];
            
            NSString *encodedString = [dataString stringByReplacingCharactersInRange:textRange withString:encodedText];
            NSData *encodedData = [encodedString dataUsingEncoding:NSUTF8StringEncoding];
            
            retData = encodedData;
        }
        else {
            retData = data;
        }
        
    }
    else {
        retData = data;
    }
    [dataString release];
    return retData;
}


/*!
 @abstract handles content that was just received by TTURLConnection
 
 @discussion - Removes the connection from array, so that it can be released.
 - Creates a parser to process the received data
 
 */
- (void)TTURLConnection:(TTURLConnection *)urlConnection finishLoadingWithData:(NSData *)data {
    
    if (urlConnection.responseFormat == TTURLResponseFormatXML) {
        
        
        // encode data in case we get some invalid data from the servers
        //
        NSData *processedData = [self encodeUserInputElements:data];
        
        TTXMLParser *newParser = [[TTXMLParser alloc] initWithData:processedData typeTag:urlConnection.typeTag idTag:urlConnection.idTag];
        newParser.urlString = urlConnection.urlRequest.URL.absoluteString;
        
        newParser.delegate = self;
        
        // parse in worker threads
        //
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            DDLogInfo(@"HC-gotdata: start xml parse");
            [newParser parse];
        });
        
        [[self getParsers] addObject:newParser];
        [newParser release];
    }
    // parse JSON response
    // 
    else if (urlConnection.responseFormat == TTURLResponseFormatJSON) {
    
        // parse in worker threads
        // - handle in mainthread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSObject *jsonObject = [data objectFromJSONData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self responseHandlerJSONObject:jsonObject typeTag:urlConnection.typeTag idTag:urlConnection.idTag];
            });
            
        });
        
    }    
    [[self getConnections] removeObject:urlConnection];
}

/*! 
 @abstract Delegate called when error has occurred
 @discussion Handles connection error.  No further delegate calls will be made 
 for this connection. So reset connection and received data.
 
 */
- (void)TTURLConnection:(TTURLConnection *)connection didFailWithError:(NSError *)error {
    
    // redundant DDLogWarn(@"HC: URL error - %@ - %@", [error localizedDescription], connection.typeTag);
    
    //NSString *logS = [NSString stringWithFormat:@"%@ - %@", [error localizedDescription], connection.typeTag];
    
    // if phone sync fails
    //
    if ([connection.typeTag isEqualToString:kMPHCQueryTagAddPhoneSync]) {
        
        // access the background CM and reset it's status
        dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
        
        dispatch_async(back_queue, ^{
            [[AppUtility getBackgroundContactManager] resetPhoneSyncProcess];
        });
        
    }
    // if presence update fails, suggestion, recover friends 
    //
    else if ([connection.typeTag isEqualToString:kMPHCQueryTagQuery] || 
             [connection.typeTag isEqualToString:kMPHCQueryTagQueryNoArguments] ||
             [connection.typeTag isEqualToString:kMPHCQueryTagSuggestion]
             ) {
        // no big deal really, do nothing
    }
    // If add/remove and contact ID not specified then ignore error
    // 
    else if (connection.idTag == nil && 
             ([connection.typeTag isEqualToString:kMPHCQueryTagAdd] || [connection.typeTag isEqualToString:kMPHCQueryTagRemove])
             ) {
        // do nothing
    }
    // if operator query failed, clear it's cache
    //
    else if ([connection.typeTag isEqualToString:kMPHCRequestTypeQueryOperator]) {
        [[OperatorInfoCenter sharedOperatorInfoCenter] clearCache];
    }
    // if reverse geocode fails
    //
    else if ([connection.typeTag isEqualToString:kMPHCRequestTypeMapGeocode]) {
        // no address is shown for location view's center pin
        // - no big deal, ignore it
    }
    // if get resource fails, fail silently
    //
    else if ([connection.typeTag isEqualToString:kMPHCRequestTypeGetResourceDownloadInfo]) {
        // - client will retry later
    }
    // Helper message is best effort no need to warn
    else if ([connection.typeTag isEqualToString:kMPHCRequestTypeSendHelperMessage]) {
        // - client will retry later
    }
    // Fail silently - These will retry later
    // - set push token
    //
    else if ([connection.typeTag isEqualToString:kMPHCRequestTypeSetPushTokenID] ) {
        // - client will retry later
    }
    // Authen fails, try again
    //
    else if ( [connection.typeTag isEqualToString:kMPHCRequestTypeAuthentication] ) {
        // fail silently, no need to inform user
    }
    // if ip query fails inform view
    //
    else if ([connection.typeTag isEqualToString:kMPHCRequestTypeIPQueryMSISDN]) {
        // notify view that we are finished
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_IPQUERY_MSISDN_NOTIFICATION object:nil];  
    }
    // show alert otherwise
    // - typeTag && idTag exists also raise a failure notification
    //
    else {
        [AppUtility stopActivityIndicator];
        
        if ([connection.typeTag length] > 0 && [connection.idTag length] > 0) {
            
            NSMutableDictionary *newD = [[NSMutableDictionary alloc] init];
            [newD setValue:connection.typeTag forKey:kTTXMLTypeTag];
            [newD setValue:connection.idTag forKey:kTTXMLIDTag];
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_CONNECT_FAILED_NOTIFICATION object:newD];
            [newD release];
        }

        NSString *alertTitle = NSLocalizedString(@"Request Failed", @"HTTPRequests: if requests to servers failed for some reason, inform the user to try at a later time");
        //NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Request failed (%@). Try again later.", @"HTTPRequests: if requests to servers failed for some reason, inform the user to try at a later time"), connection.typeTag];
        NSString *alertMessage = NSLocalizedString(@"Check your network connectivity and try again.", @"HTTPRequests: if requests to servers failed for some reason, inform the user to try at a later time");

        [Utility showAlertViewWithTitle:alertTitle message:alertMessage];
        
        DDLogWarn(@"HC Request failed: %@", connection.typeTag);
    }
}

#pragma mark -
#pragma mark TTXMLParser Delegate

/*!
 @abstract handles xml dictionary after parser is finished processing
 */
- (void)TTXMLParser:(TTXMLParser *)parser finishParsingWithDictionary:(NSDictionary *)dictionary{
    
    // after parsing, run back in mainthread
    //
    dispatch_async(dispatch_get_main_queue(), ^{
        //DDLogVerbose(@"HC-xmlparse: get dictionary %@", dictionary);
        [self responseDictionaryHandler:dictionary];
        
        [[self getParsers] removeObject:parser];
    });
}

/*!
 @abstract Called when error encountered
 */
- (void)TTXMLParser:(TTXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    // redundant - DDLogWarn(@"HC: XML error - %@ - %@", [parseError localizedDescription], parser.typeTag);
    
    // if phone sync fails
    // - reset the sync process
    if ([parser.typeTag isEqualToString:kMPHCQueryTagAddPhoneSync]) {
        
        // access the background CM and reset it's status
        dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
        
        dispatch_async(back_queue, ^{
            [[AppUtility getBackgroundContactManager] resetPhoneSyncProcess];
        });
        
    }
    // if presence update fails, add/remove contact fails
    // - fail silently
    else if ([parser.typeTag isEqualToString:kMPHCQueryTagQuery] || 
             [parser.typeTag isEqualToString:kMPHCQueryTagQueryNoArguments] ||
             [parser.typeTag isEqualToString:kMPHCQueryTagSuggestion]
             ) {
        // no big deal, do nothing
    }
    // If add/remove and contact ID not specified then ignore error
    // 
    else if (parser.idTag == nil && 
             ([parser.typeTag isEqualToString:kMPHCQueryTagAdd] || [parser.typeTag isEqualToString:kMPHCQueryTagRemove])
             ) {
        // do nothing
    }
    // Helper message is best effort no need to warn
    else if ([parser.typeTag isEqualToString:kMPHCRequestTypeSendHelperMessage]) {
        // - client will retry later
    }
    // if operator query failed, clear it's cache
    //
    else if ([parser.typeTag isEqualToString:kMPHCRequestTypeQueryOperator]) {
        [[OperatorInfoCenter sharedOperatorInfoCenter] clearCache];
    }
    // if ip query fails inform view
    //
    else if ([parser.typeTag isEqualToString:kMPHCRequestTypeIPQueryMSISDN]) {
        // notify view that we are finished
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_HTTPCENTER_IPQUERY_MSISDN_NOTIFICATION object:nil];  
    }
    // show alert otherwise
    // TODO: consider creating a blank responsedictionary and calling reponseHandler
    //       to send notification back to caller
    //
    else {
        [AppUtility stopActivityIndicator];
        

        NSString *alertTitle = NSLocalizedString(@"Response Format Issue", @"HTTPRequests: if requests to servers failed for some reason, inform the user to try at a later time - XML ISSUE");

        NSString *alertMessage = NSLocalizedString(@"Check your network connectivity and try again.", @"HTTPRequests: if requests to servers failed for some reason, inform the user to try at a later time - XML ISSUE");
        
        [Utility showAlertViewWithTitle:alertTitle message:alertMessage];
        
        /*
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Invalid Server Response"
														 message:[parseError localizedDescription]
														delegate:nil
											   cancelButtonTitle:@"OK"
											   otherButtonTitles:nil] autorelease];
		[alert show];*/
    }
}

@end
