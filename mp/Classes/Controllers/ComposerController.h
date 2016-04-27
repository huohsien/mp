//
//  ComposerController.h
//  mp
//
//  Created by Min Tsai on 1/14/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

/*!
 @header ComposerController
 
 Generic controller that allows user to edit text and emoticon.

 Usage:
 - allocate
 - set .title attribute
 - set .characterLimit if needed - defaults to 0 for no limit
 - use delegate to get informed when save is tapped and the desired text
 
 
 Example:
 - configure contacts selection -> thus allows user to modify
 - set edit mode to text
 - configure char limits
 - set the title for this edit view
 
 ComposerController *newController = [[ComposerController alloc] init];
 newController.toContacts = self.broadcastContacts;
 newController.editMode = kCCEditModeText;
 newController.characterLimitMin = kMPParmChatMessageLengthMin;
 newController.characterLimitMax = kMPParmChatMessageLengthMax;
 newController.title = NSLocalizedString(@"Broadcast", @"Broadcast - title: broadcast a message to multiple friends");
 
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <UIKit/UIKit.h>
#import "TKTabButton.h"
#import "EmoticonKeypad.h"
#import "SelectContactController.h"



/*!
 @abstract Edit mode that affects the UI interface for edit view

 Text       Text editing
 Sticker    Select sticker
 Image      Selected image
 
 */
typedef enum {
    
    // basic text edit
	kCCEditModeBasic = 0,
    
    // broadcast modes
	kCCEditModeText = 1,
    kCCEditModeSticker = 2,
	kCCEditModeImage = 3,
    kCCEditModeLetter = 4,
    kCCEditModeLocation = 5
} CCEditMode;


@class ComposerController;

/*!
 Delegate that handles input from this view's controls
 */
@protocol ComposerControllerDelegate <NSObject>
@optional
/*!
 @abstract User pressed saved with new text string
 
 Use:
 - when composer is done editing some text
 */
- (void)ComposerController:(ComposerController *)composerController didSaveWithText:(NSString *)text;

/*!
 @abstract User pressed saved with new message information
 
 Use:
 - when composer is done creating a broadcast or schedule message
 */
- (void)ComposerController:(ComposerController *)composerController text:(NSString *)text contacts:(NSArray *)contacts image:(UIImage *)image date:(NSDate *)date letterImage:(UIImage *)letterImage letterID:(NSString *)letterID locationImage:(UIImage *)locationImage locationText:(NSString *)locationText;

@end



@interface ComposerController : UIViewController <UITextViewDelegate, TKTabButtonDelegate, EmoticonKeypadDelegate, SelectContactsControllerDelegate> {
    
    id <ComposerControllerDelegate> delegate;
    NSString *tempText;
    NSInteger characterLimitMin;
    NSInteger characterLimitMax;
    NSArray *tabButtons;
    
    UITextView *textView;
    EmoticonKeypad *emoticonKeypad;
    
    CCEditMode editMode;
    NSArray *toContacts;
    UIImage *sendImage;
    
    // letter
    UIImage *letterImage;
    NSString *letterID;
    
    // location
    UIImage *locationImage;
    NSString *locationText;

    // date 
    NSDate *sendDate;
    UIDatePicker *datePicker;
    UIActionSheet *dateActionSheet;
    
    NSUInteger defaultTimeSinceNow;
    NSUInteger minimumTimeSinceNow;
    NSUInteger uiMinimumTimeSinceNow;
    
    NSString *saveButtonTitle;

}

@property (nonatomic, assign) id <ComposerControllerDelegate> delegate;

/*! save pending text update value here */
@property (nonatomic, retain) NSString *tempText;
@property (nonatomic, assign) NSInteger characterLimitMin;
@property (nonatomic, assign) NSInteger characterLimitMax;
@property (nonatomic, retain) NSArray *tabButtons;

@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, retain) EmoticonKeypad *emoticonKeypad;


/*! specify type of message being edited */
@property (nonatomic, assign) CCEditMode editMode;

/*! allow this user to review and re select contacts */
@property (nonatomic, retain) NSArray *toContacts;

/*! user selected image to send out */
@property (nonatomic, retain) UIImage *sendImage;

/*! user created letter image */
@property (nonatomic, retain) UIImage *letterImage;

/*! letter ID */
@property (nonatomic, retain) NSString *letterID;

/*! location preview image */
@property (nonatomic, retain) UIImage *locationImage;

/*! location cooridinate info */
@property (nonatomic, retain) NSString *locationText;


/*! when will message be delivered */
@property (nonatomic, retain) NSDate *sendDate;

/*! save reference to date picker action sheet */
@property (nonatomic, retain) UIDatePicker *datePicker;
@property (nonatomic, retain) UIActionSheet *dateActionSheet;

/*! default that is given when first created */
@property (nonatomic, assign) NSUInteger defaultTimeSinceNow;
/*! min date when finished editing */
@property (nonatomic, assign) NSUInteger minimumTimeSinceNow;
/*! min allowed by UI datepicker */
@property (nonatomic, assign) NSUInteger uiMinimumTimeSinceNow;

/*! alternative title for the save button used at the end - broadcast uses "Send" */
@property (nonatomic, retain) NSString *saveButtonTitle;


- (void) setImage:(UIImage *)image;
- (void) setLetterImage:(UIImage *)image letterID:(NSString *)idString;
- (void) setLocationPreviewImage:(UIImage *)image coordinateText:(NSString *)coordinateText;


@end