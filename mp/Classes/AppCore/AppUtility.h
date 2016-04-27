//
//  AppUtility.h
//  mp
//
//  Created by M Tsai on 11-9-7.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "mpAppDelegate.h"

#define kMPNavBarImageTag 4783273
//#define kMPNavBarColor [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]
//#define kMPNavBarColor [UIColor colorWithRed:0.906 green:0.906 blue:0.906 alpha:1.0] // light gray
//#define kMPNavBarColor [UIColor colorWithRed:0.50 green:0.56 blue:0.13 alpha:1.0]    // green
#define kMPNavBarColor [UIColor colorWithRed:0.62 green:0.68 blue:0.19 alpha:1.0]    // green


extern NSString* const kMPQueueMainThread;
extern NSString* const kMPQueueBackgroundMOC;
extern NSString* const kMPQueueNetwork;

extern NSString* const kMPFileTellFriendEmail;
extern NSString* const kMPFileTellFriendSMS;
extern NSString* const kMPFileTellFriendFree;

/**
 Table Cell Styles
 
 kAUCellStyleBasic: for basic table view
 */
typedef enum {
	kCellStyleOneLine,
	kCellStyleOneLineIcon,
	kCellStyleOneLineAccessory,
	kCellStyleTwoLine,
	kCellStyleTwoLineNamePropertyGrouped,
	kCellStyleTwoLineFavorites,
    kAUCellStyleFriendList,
    kAUCellStyleSuggestList,
    kAUCellStyleSelectProperty,
    kAUCellStyleSelectCountry,
    kAUCellStyleChatList,
    kAUCellStyleScheduleList,
    kAUCellStylePhoneBook,
    kAUCellStylePhoneBookTW,
    kAUCellStyleSelectContact,
    kAUCellStyleNoSelectContact,
    kAUCellStyleBlockList,
    kAUCellStyleBasic
} AUCellStyle;

/*!
 Label Types
 
 Names should describe type of labels that should be consistent throughout this app
 
 */
typedef enum {
    kAULabelTypeGrayMicroPlus,
    kAULabelTypeGreenStandardPlus,
    kAULabelTypeGreenMicroPlus,
    kAULabelTypeBlackStandardPlus,
    kAULabelTypeBlackStandardPlusBold,
    kAULabelTypeBlackSmall,
    kAULabelTypeBlackTiny,
    kAULabelTypeBlackMicroPlus,
    kAULabelTypeLightGrayNanoPlus,
    kAULabelTypeWhiteStandardBold,
    kAULabelTypeWhiteMicro,
    kAULabelTypeBlueNanoPlus,
    kAULabelTypeBlue3,
    kAULabelTypeTableStandard,
    kAULabelTypeTableSubText,
    kAULabelTypeTableMainText,
    kAULabelTypeTableName,
    kAULabelTypeTableMyName,
    kAULabelTypeTableStatus,
    kAULabelTypeTableDate,
    kAULabelTypeTableHighlight,
    kAULabelTypeBadgeText,
    kAULabelTypeNoItem,
    kAULabelTypeBackgroundText,
    kAULabelTypeBackgroundTextInfo,
    kAULabelTypeBackgroundTextHighlight,
    kAULabelTypeBackgroundTextHighlight2,
    kAULabelTypeBackgroundTextCritical,
    kAULabelTypeButton,
    kAULabelTypeButtonLarge,
    kAULabelTypeTextBar,
    kAULabelTypeNavTitle,
    kAULabelTypeHiddenPIN
} AULabelType;


/*!
 Button Types
 
 kAUButtonTypeStatus            Status bubble button
 kAUButtonTypeSwitch            On / off switch
 kAUButtonTypeBarNormal         Standard bar button 
 kAUButtonTypeBarHighlight      Highlighted to standout bar button
 
 */
typedef enum {
    kAUButtonTypeTextBar,
    kAUButtonTypeTextBarSmall,
    kAUButtonTypeTextBarTop,
    kAUButtonTypeTextBarCenter,
    kAUButtonTypeTextBarBottom,
    kAUButtonTypeTextEditBar,
    kAUButtonTypeOrange,
    kAUButtonTypeOrange2,
    kAUButtonTypeOrange3,
    kAUButtonTypeSilver,
    kAUButtonTypeYellow,
    kAUButtonTypeBlueDark,
    kAUButtonTypeGreen,
    kAUButtonTypeGreen3,
    kAUButtonTypeGreen5,
    kAUButtonTypeRed3,
    kAUButtonTypeGray1,
    kAUButtonTypeOperator,
    kAUButtonTypeBadgeRed,
    kAUButtonTypeBadgeYellow,
    kAUButtonTypeStatus,
    kAUButtonTypeSwitch,
    kAUButtonTypeBarNormal,
    kAUButtonTypeBarHighlight,
    kAUButtonTyepBarPlus,
} AUButtonType;

/*!
 Info View Buttons
 
 */
typedef enum {
    kAUInfoButtonTypeChat,
    kAUInfoButtonTypeChatInvite,
    kAUInfoButtonTypeSMS,
    kAUInfoButtonTypeCall,
    kAUInfoButtonTypeBlock,
    kAUInfoButtonTypeDelete
} AUInfoButtonType;

/*!
 TextField Types
 */
typedef enum {
    kAUTextFieldTypeBasic,
    kAUTextFieldTypePhone,
    kAUTextFieldTypeStatus,
    kAUTextFieldTypeName
} AUTextFieldType;

/**
 Color standards
 - name by function
 */
typedef enum {
    kAUColorTypeBackground,
    kAUColorTypeBackgroundLight,
    kAUColorTypeBackgroundText,             
    kAUColorTypeBackgroundTextInfo,
    kAUColorTypeButtonText,
    kAUColorTypeTableSelected,
    kAUColorTypeSearchBar,
    kAUColorTypeTableSeparator,
    kAUColorTypeBlue1,
    kAUColorTypeBlue2,
    kAUColorTypeRed1,
    kAUColorTypeGreen1,
    kAUColorTypeGray1,
    kAUColorTypeLightGray1,
    kAUColorTypeGreen2,
    kAUColorTypeOrange,
    kAUColorTypeKeypad
} AUColorType;

/**
 Font standards
 
 */
typedef enum {
    kAUFontBoldHugePlus,
    kAUFontBoldHuge,
    kAUFontBoldLarge,
    kAUFontBoldStandardPlus,
    kAUFontBoldStandard,
    kAUFontBoldSmall,
    kAUFontBoldTiny,
    kAUFontBoldMicroPlus,
    kAUFontBoldMicro,
    kAUFontSystemHuge,
    kAUFontSystemLarge,
    kAUFontSystemStandard,
    kAUFontSystemStandardPlus,
    kAUFontSystemSmall,
    kAUFontSystemTiny,
    kAUFontSystemMicroPlus,
    kAUFontSystemMicro,
    kAUFontSystemNanoPlus
} AUFontType;


/**
 Font standards
 
 */
typedef enum {
    kAUAlertTypeNetwork,
    kAUAlertTypeScheduledDeleteReject,
    kAUAlertTypeScheduledCreateReject,
    kAUAlertTypeNoTelephonyCall,
    kAUAlertTypeNoTelephonySMS,
    kAUAlertTypeComposeFailsureSMS,
    kAUAlertTypeEmailNoAccount
} AUAlertType;

/**
 Global View Tags - careful
 
 */
typedef enum {
    kAUViewTagTextBarArrow = 7455501
} AUViewTags;

@class mpAppDelegate;
@class MPContactManager;
@class CDChat;

@interface AppUtility : NSObject {
    
}

// debug


// system and app
+ (NSString *) getDeviceModel;
+ (NSString *) getAppVersion;
+ (NSString *) getIMEI;
+ (NSString *) devicePreferredLanguageCode;
+ (NSString *) devicePreferredLanguageCodeGoogle;

+ (BOOL) isMainQueue;
+ (BOOL) isBackgroundMOCQueue;
+ (NSString *) currentQueueLabel;

// app & views
+ (mpAppDelegate *) getAppDelegate;
+ (void) setBadgeCount:(NSUInteger)count stringCount:(NSString *)stringCount controllerIndex:(NSUInteger)controllerIndex;
+ (void) setBadgeCount:(NSUInteger)count controllerIndex:(NSUInteger)controllerIndex;
+ (void) pushNewChat:(CDChat *)newChat;

// GCD
+ (dispatch_queue_t) getBackgroundMOCQueue;
+ (MPContactManager *) getBackgroundContactManager;
+ (dispatch_queue_t) getQueueNetwork;
+ (MPSocketCenter *) getSocketCenter;

// core data
//
+ (NSManagedObjectContext *) cdGetManagedObjectContext;
+ (void) cdRollBack;
+ (void) cdReset;
+ (NSError *) cdSaveWithIDString:(NSString *)idString quitOnFail:(BOOL)quit;
+ (void) cdDeleteManagedObject:(NSManagedObject *)objectToDelete;
+ (void) cdMergeChangesToContext:(NSManagedObjectContext *)moc saveNotification:(NSNotification *)notification;
+ (void) cdRefreshObject:(NSManagedObject *)refreshManagedObject;


// phone utility
//
+ (BOOL) isTWCountryCode;
+ (NSString *) stripZeroPrefixForString:(NSString *)string;
+ (void)call:(NSString *) phoneNumber;
+ (void)sms:(NSString *) phoneNumber delegate:(id)composerDelegate;


// Validation
//
+ (BOOL) isUserIDValid:(NSString *)userID;
+ (BOOL) isMessageIDValid:(NSString *)mpID;
+ (BOOL) isNickNameValid:(NSString *)nickName;
+ (NSString *) stripNickName:(NSString *)nickName;

// UI
//
+ (UIColor *) colorForContext:(AUColorType)colorType;
+ (UIFont *) fontPreferenceWithContext:(AUFontType)fontType;
+ (void) configLabel:(UILabel *)label context:(AULabelType)labelType;
+ (void) configButton:(UIButton *)button context:(AUButtonType)buttonType;
+ (void) configInfoButton:(UIButton *)button context:(AUInfoButtonType)buttonType;
+ (void) configTextField:(UITextField *)tField context:(AUTextFieldType)tFieldType;

+ (void) setCellStyle:(AUCellStyle)style  labels:(NSArray *)labels;
+ (void) setCellStyle:(AUCellStyle)style  mainLabel:(UILabel *)mainLabel subLabel:(UILabel *)subLabel;
+ (void) configTableView:(UITableView *)tableView;
+ (void) addShadowToLabel:(UILabel *)label;
+ (void) setBadge:(UIButton *)badgeButton text:(NSString *)text;

// UIView
+ (void) findAndResignFirstResponder;
+ (void) showAppUpdateView:(NSString *)serverText;

// Nav bar
+ (void)customizeNavigationController:(UINavigationController *)navController;
+ (void)setCustomTitle:(NSString *)title navigationItem:(UINavigationItem *)navItem;

// Activity Indicator
+ (BOOL) isActivityIndicatorRunning;
+ (void) startActivityIndicatorBackgroundAlpha:(CGFloat)backAlpha;
+ (void) startActivityIndicator; // :(UINavigationController *)navController;
+ (void) stopActivityIndicator; // :(UINavigationController *)navController;
+ (void) showProgressOverlayForMessageID:(NSString *)msgID totalSize:(NSUInteger)totalSize;
+ (void) removeProgressOverlay;
+ (void) showAlert:(AUAlertType)alertType;
+ (void) askAddressBookAccessPermissionAlertDelegate:(id)alertDelegate alertTag:(NSInteger)alertTag;
    
// Button
+ (UIBarButtonItem *) barButtonWithTitle:(NSString *)title buttonType:(AUButtonType)buttonType target:(id)target action:(SEL)selector;

// MP
+ (NSString *) headShotFilenameForUserID:(NSString *)userID;
+ (NSString *) generateMessageID;
+ (long) getTagWithMessageID:(NSString *)mID;

// Downloadable
+ (NSString *) pathForDownloadableContentWithFilename:(NSString *)filename;

@end
