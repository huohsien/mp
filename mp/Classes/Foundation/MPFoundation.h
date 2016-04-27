//
//  MPFoundation.h
//  mp
//
//  Created by M Tsai on 11-9-5.
//  Copyright 2011年 TernTek. All rights reserved.
//

/*!
 Imports basic classes for MP app
 */
#import "MPPresence.h"
#import "MPSettingCenter.h"
#import "MPHTTPCenter.h"
#import "MPSocketCenter.h"
//#import "MPNetworkCenter.h"
#import "MPMessage.h"
#import "MPMessageCenter.h"
#import "TKFileManager.h"
#import "MPImageManager.h"


#import "Utility.h"
#import "AppUtility.h"
#import "TKLog.h"



/*! Secs to wait for message to write to buffer */
extern CGFloat const kMPParamNetworkTimeoutWriteToBuffer;

/*! Should DS communication be scrambled? */
extern BOOL const kMPParamNetworkEnableDataScrambling;

/*! MP Server to connect to */
extern NSString* const kMPParamNetworkMPServerPort;

/*! Download server for files */
extern NSString* const kMPParamNetworkMPDownloadServer;


/*! Secs to wait for message to get confirmation message after write buffer - send remaining data over network */ 
extern CGFloat const kMPParamNetworkTimeoutWaitForConfirmation;

/*! Assumed minimum upload speed - used to calc amount of time used for write buffer timeout */ 
extern CGFloat const kMPParamNetworkMinUploadSpeed;

/* 
 Elapsed time after a disconnect when we should still consider the disconnect as fresh
 - helps answer: should we fail a message right away if client is not currently logged in?
 */
extern CGFloat const kMPParamNetworkTimeoutFreshDisconnect;  


/*! Google API Key */ 
extern NSString* const kMPParamGoogleAPIKey;



/*! Max width of the images to send over MP */
extern CGFloat const kMPParamSendImageWidthMax;
extern CGFloat const kMPParamSendImageWidthMaxPreview;


// Chat and Broadcast max
//
extern NSUInteger const kMPParamGroupChatMax;
extern NSUInteger const kMPParamBroadcastMax;


/*! message length limits */
extern NSUInteger const kMPParamChatMessageLengthMax;
extern NSUInteger const kMPParamChatMessageLengthMin;


/*! minimum number of multimessage submessage that are need to use batch processing */
extern NSUInteger const kMPParamChatMessageBatchProcessingMessageCountMin;


/*! default time to use to create new SM */
extern CGFloat const kMPParamScheduleDefaultTimeSinceNow;
/*! min forced by UI */
extern CGFloat const kMPParamScheduleUIMinimumTimeSinceNow;
/*! min checked when new SM create is done (less than UI limit) */
extern CGFloat const kMPParamScheduleMinimumTimeSinceNow;


/*! standard table row height */
extern CGFloat const kMPParamTableRowHeight; 

/*! dialog toolbar heigth */
extern CGFloat const kMPParamDialogToolBarHeight;   

/*! navigation bar height */
extern CGFloat const kMPParamNavigationBarHeight;

/*! tab bar height */
extern CGFloat const kMPParamTabBarHeight;



/*! standard animation duration */
extern CGFloat const kMPParamAnimationStdDuration; 

/*! app urls */
extern NSString* const kMPParamAppURLUpdate;
extern NSString* const kMPParamAppURLEndUserLicenceAgreement;
extern NSString* const kMPParamAppURLHelp;



/*! IDs above this ID are consider helper IDs */
extern NSString* const kMPParamHelperMinID;


/*!
 @abstract Identifies the tab indexes
 
 */
typedef enum {
	kMPTabIndexFriend=0,
    kMPTabIndexPhone=1,
    kMPTabIndexChat=2,
    kMPTabIndexScheduled=3,
    kMPTabIndexSetting=4
} MPTabIndex;


/*
 Cause Table :
 value
 description
 
 0
 Success
 
 1~127
 Refer to ISDN release cause ( call type )
 
 600    Invalid IMEI - cannot use this service
 601    Invalid MSISDN - cannot use this service
 602    Invalid USERID - cannot use this service
 603    Invalid akey – have to do authentication again
 604    Invalid password – have to do register again
 605    Invalid IMEI – not match USERID
 606    Invalid MSISDN – not match USERID
 607    IP query msisdn failed !
 
 699    Client requires force update to latest version
 
 701    AS timeout – try it later
 705    MPID already created
 706    MPID not found
 
 801    Protocol error
 804    Schedule time > 60 days
 
 901    System error : I/O error
 902    Delete request : schedule message not found
 
 */
typedef enum {
	kMPCauseTypeSuccess=0,
    kMPCauseTypeInvalidAKey=603,
    kMPCauseTypeInvalidIMEI=605,
    kMPCauseTypeMultipleDeviceRegistration = 608,
    kMPCauseTypePassCodeExpired = 609,
    kMPCauseTypeForceUpdate = 699,
    kMPCauseTypeMPIDAlreadyCreated=705,
    kMPCauseTypeMPIDNotFound=706,
    kMPCauseTypeProtocolError=801,
    kMPCauseTypeSystemError=901,
    kMPCauseTypeScheduleMessageNotFound=902
} MPCauseType;


// Constants
extern NSString* const kMPSharedNSCacheKeyDSTimeOffset;

