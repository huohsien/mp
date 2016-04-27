//
//  ChatDialogController.h
//  mp
//
//  Created by M Tsai on 11-10-20.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatDialogToolBarView.h"
#import "ELCImagePickerController.h"
#import "LetterController.h"
#import "LocationShareController.h"
#import "DialogTableController.h"
#import <CoreLocation/CoreLocation.h>


/*!
 @abstract Determine the state of the dialog and it's appearance
 
 Day    Day time mode - default
 Night  Night time mode
 
 Values are store in kMPSettingSVStateCode
 
 */
typedef enum {
    
	kChatDialogStateCodeDay = 0,
    kChatDialogStateCodeNight = 1
    
} ChatDialogStateCode;


/*!
 @abstract What type of photo album should we show?
 
 Query      Check system to see which one we should show
 Single     Show iOS native album
 Multi      Show Multi selection album
 
 */
typedef enum {
    
	kChatDialogAlbumTypeQuery = 0,
    kChatDialogAlbumTypeSingle = 1,
    kChatDialogAlbumTypeMulti = 2
    
} ChatDialogAlbumType;


@class CDChat;
@class DialogTableController;
@class ChatDialogToolBarView;
@class ChatDialogSrollView;
@class ChatDialogController;

/*!
 Delegate that handles input from this view's controls
 */
@protocol ChatDialogControllerDelegate <NSObject>


@optional

/*!
 @abstract Informs delegate to show another chat
 
 */
- (void)ChatDialogController:(ChatDialogController *)controller showChat:(CDChat *)newChat;

@end


@interface ChatDialogController : UIViewController <ChatDialogToolBarViewDelegate, UIActionSheetDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate, ELCImagePickerControllerDelegate, UIScrollViewDelegate, LetterControllerDelegate, LocationShareControllerDelegate, UIAlertViewDelegate, DialogTableControllerDelegate, CLLocationManagerDelegate> {
    
    
    id <ChatDialogControllerDelegate> delegate;
    CDChat *cdChat;

    // views
    UIImageView *typingView;
    ChatDialogToolBarView *toolBarView;
    
    ChatDialogSrollView *chatScrollView;
    DialogTableController *tableController;
    
    NSTimer *typingTimer;
    NSTimer *shakeViewEndTimer;
    
    NSString *viewDidAppearFlags;
    CLLocationManager *locManager;
    
    BOOL enableKeyboardAnimation;
    BOOL didPushAnotherView;
    
    //BOOL presentPortraitModalView;
}

/*! controller delegate */
@property (nonatomic, assign) id <ChatDialogControllerDelegate> delegate;

@property (nonatomic, retain) CDChat *cdChat;


/*! Typing animation background that pulses */
@property (nonatomic, retain) UIImageView *typingView;

@property (nonatomic, retain) ChatDialogToolBarView *toolBarView;
@property (nonatomic, retain) ChatDialogSrollView *chatScrollView;

@property (nonatomic, retain) DialogTableController *tableController;


/*! Timer that fires when we should automatically stop the typing visuals */
@property (nonatomic, retain) NSTimer *typingTimer;

/*! Timer that fires to make sure the shake view has ended */
@property (nonatomic, retain) NSTimer *shakeViewEndTimer;

/*! Flags to pass to VDA to handle */
@property (nonatomic, retain) NSString *viewDidAppearFlags;


/*! Help determine if loc service is available */
@property (nonatomic, retain) CLLocationManager *locManager;

/*! should keyboard animation should run */
@property (nonatomic, assign) BOOL enableKeyboardAnimation;

/*! was another view pushed on top */
@property (nonatomic, assign) BOOL didPushAnotherView;


- (id)initWithCDChat:(CDChat *)newChat;
- (BOOL) isShowingHiddenChat;

@end
