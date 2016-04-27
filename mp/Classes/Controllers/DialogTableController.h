//
//  ChatDialogController.h
//  mp
//
//  Created by M Tsai on 11-9-22.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GenericTableViewController.h"
#import "DialogMessageCellController.h"
#import "SelectContactController.h"
#import "MediaImageController.h"
#import "LetterDisplayView.h"
#import "HiddenController.h"
#import "MPImageManager.h"


/*!
 Automated robot currently running
 */
typedef enum {
	kDTCRobotNone,
    kDTCRobotEcho,
    kDTCRobotSend
} kDTCRobot;

extern NSString* const MP_DAILOG_UPDATE_NAME_NOTIFICATION;

@class CDChat;
@class CDResource;
@class DialogTableController;

/*!
 Delegate that handles input from this view's controls
 */
@protocol DialogTableControllerDelegate <NSObject>


@optional

/*!
 @abstract Informs delegate to hide keypad
 
 */
- (void)DialogTableController:(DialogTableController *)controller hideKeypad:(BOOL)hideKeypad;


/*!
 @abstract Informs delegate to show another chat
 
 */
- (void)DialogTableController:(DialogTableController *)controller showChat:(CDChat *)newChat;

/*!
 @abstract Informs delegate to shake view
 
 */
- (void)DialogTableController:(DialogTableController *)controller shouldShake:(BOOL)shouldShake;

@end




@interface DialogTableController : GenericTableViewController <DialogMessageCellControllerDelegate, SelectContactsControllerDelegate, MediaImageControllerDelegate, LetterDisplayViewDelegate, HiddenControllerDelegate, MPImageManagerDelegate> {
    
    id <DialogTableControllerDelegate> delegate;
    
    CDChat *cdChat;
    UIViewController *parentController;
    
    NSMutableArray *messages;
    NSMutableArray *messageCells;
    
    NSUInteger readMessageCount;
    CDMessage *firstMessageEver;
    BOOL allMessageShowing;
    
    CDMessage *tempMessage;
    CGFloat keyboardHeight;
    BOOL firstRun;
    
    CDChat *pendingHiddenChat;
    
    MPImageManager *imageManager;
    
    kDTCRobot runningRobot;
    NSString *lastSentRobotMessage;
    
    BOOL shouldScrollToBottomAfterReload;
    
    NSTimer *throttleScrollToLastTimer;

}

/*! controller delegate */
@property (nonatomic, assign) id <DialogTableControllerDelegate> delegate;


/*! chat that is shown by this chat dialog */
@property (nonatomic, retain) CDChat *cdChat;

/*! reference to chat dialog controller, so we can show other views */
@property (nonatomic, assign) UIViewController *parentController;


/*! reference to all messages shown */
@property (nonatomic, retain) NSMutableArray *messages;

/*! all cell controllers */
@property (nonatomic, retain) NSMutableArray *messageCells;


/*! number of read messages we should load */
@property (nonatomic, assign) NSUInteger readMessageCount;

/*! if no more messages to load */
@property (nonatomic, assign) BOOL allMessageShowing;


/*! very first message in this chat - not accurate after clear history */
@property (nonatomic, retain) CDMessage *firstMessageEver;

/*! temp store to help forward messages */
@property (nonatomic, retain) CDMessage *tempMessage;


/*! keep track of kb height so we know how to display and scroll view */
@property (nonatomic, assign) CGFloat keyboardHeight;

/*! Marks first run of this instanace - to move to start position on first run */
@property (nonatomic, assign) BOOL firstRun;

/*! Hidden chat that should be shown after unlocking PIN - forward message */
@property (nonatomic, retain) CDChat *pendingHiddenChat;

/*! helps access headshots for friends */
@property(nonatomic, retain) MPImageManager *imageManager;


/*! Should only go to bottom, when we new messages are showing or after first load */
@property(nonatomic, assign) BOOL shouldScrollToBottomAfterReload;


/*! Which robot is running right now */
@property (nonatomic, assign) kDTCRobot runningRobot;

/*! What message are we waiting for echo reply for - if we recv this, then send next robot msg */
@property (nonatomic, retain) NSString *lastSentRobotMessage;


/*! Rate limits scroll to bottom so only last call of a burst is executed */
@property (nonatomic, retain) NSTimer *throttleScrollToLastTimer;



- (id)initWithStyle:(UITableViewStyle)style cdChat:(CDChat *)newChat parentController:(UIViewController *)controller;

- (void) scrollToBottomWithAnimation:(BOOL)animated;

- (void) sendOutOfSequenceText;
- (void) sendText:(NSString *)textMessage;
- (void) sendStickerResource:(CDResource *)resource;
- (void) clearContentInsets;
- (void) scrollToBottomWithAnimation:(BOOL)animated;
- (void) scrollToShowLastMessageWithKeyboardHeight:(CGFloat)kbHeight animated:(BOOL)animated;
- (void) scrollToStartPosition;

@end
