#import "MPFoundation.h"

// *** Network ***
//
CGFloat const kMPParamNetworkTimeoutWriteToBuffer = 20.0;
BOOL const kMPParamNetworkEnableDataScrambling = YES;


// Which server should we use

#ifdef SERVER_STAGING
// Staging
//NSString* const kMPParamNetworkMPServerPort = @"61.66.229.106";
//NSString* const kMPParamNetworkMPDownloadServer = @"61.66.229.106";

NSString* const kMPParamNetworkMPServerPort = @"175.99.91.120";
NSString* const kMPParamNetworkMPDownloadServer = @"175.99.91.120";

#else
// Prod
NSString* const kMPParamNetworkMPServerPort = @"mplusasps.tfn.net.tw";
NSString* const kMPParamNetworkMPDownloadServer = @"175.99.90.226";

#endif


//test download server IP : 61.66.229.106

// Linux
//NSString* const kMPParamNetworkMPServerPort = @"175.99.90.215";




/*
 assume buffer is 150K @ 2K speed
 - so if buffer is full, we need about 50 seconds to drain it
 */
CGFloat const kMPParamNetworkTimeoutWaitForConfirmation = 75.0;  
CGFloat const kMPParamNetworkMinUploadSpeed = 2000.0;

// Time a disconnect is considered fresh
// - helps answer: should we fail a message right away if client is not currently logged in?
CGFloat const kMPParamNetworkTimeoutFreshDisconnect = 15.0;  




// Google API KEY - msgplusapp@gmail.com
NSString* const kMPParamGoogleAPIKey = @"AIzaSyDIyS6Ug_TofNbKsF2uT62dZgf8Qk7gKTE";



// Image demensions
//
CGFloat const kMPParamSendImageWidthMax = 640.0;
CGFloat const kMPParamSendImageWidthMaxPreview = 320.0;


// Chat and Broadcast max
//
NSUInteger const kMPParamGroupChatMax = 24;
NSUInteger const kMPParamBroadcastMax = 25;


// Chat Message limits
//
NSUInteger const kMPParamChatMessageLengthMax = 2500;
NSUInteger const kMPParamChatMessageLengthMin = 1;


// Chat Dialog
NSUInteger const kMPParamChatMessageBatchProcessingMessageCountMin = 20;



// Scheduled message limits
//
CGFloat const kMPParamScheduleDefaultTimeSinceNow = 300; // 15 minutes
CGFloat const kMPParamScheduleUIMinimumTimeSinceNow = 300; //600; // 5 minutes
CGFloat const kMPParamScheduleMinimumTimeSinceNow = 180; // 480; // 3 minutes


// UI
//
CGFloat const kMPParamTableRowHeight = 54.0; 
CGFloat const kMPParamDialogToolBarHeight = 38.0;       // Dialog toolbar height
CGFloat const kMPParamNavigationBarHeight = 44.0;
CGFloat const kMPParamTabBarHeight = 49.0;


CGFloat const kMPParamAnimationStdDuration = 0.3; 


// App URLS
//
NSString* const kMPParamAppURLUpdate = @"http://www.mplusapp.com/W/upgrade?device=ios";
NSString* const kMPParamAppURLEndUserLicenceAgreement = @"http://www.mplusapp.com/W/eula?language=";
NSString* const kMPParamAppURLHelp = @"http://www.mplusapp.com/W/help?device=ios&language=";


// Helper
NSString* const kMPParamHelperMinID = @"90000000";


// Constants
NSString* const kMPSharedNSCacheKeyDSTimeOffset = @"kMPSharedNSCacheKeyDSTimeOffset";

