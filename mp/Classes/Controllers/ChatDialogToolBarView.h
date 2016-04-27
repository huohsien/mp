//
//  ChatDialogToolBarView.h
//  mp
//
//  Created by M Tsai on 11-10-20.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

/*!
 @header ChatDialogToolBarView
 
 ChatDialogToolBarView constructs a chat toolbar where users can add content to the
 chat conversation: text, emoticon, attachments, etc.
 
 Usage:
 
 
 @copyright TernTek
 @updated 2011-10-20
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <UIKit/UIKit.h>
#import "HPGrowingTextView.h"
#import "EmoticonKeypad.h"




@class ChatDialogToolBarView;
@class EmoticonKeypad;

/*!
 Delegate that handles input from this view's controls
 
 */
@protocol ChatDialogToolBarViewDelegate <NSObject>


@optional

/*!
 @abstract Call if tool bar wants to know if it is ok to do something
 
 @return YES if should proceeed, NO if action should not be taken
 
 */
- (BOOL)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView shouldProceedWithAction:(NSString *)actionTag;

/*!
 @abstract Call when send button is pressed
 
 @return YES if success, NO if failure
 
 Delegate can takes text and helps send's this message
 - return NO, don't clear text since send failed (usually because this contact is blocked)
 
 */
- (BOOL)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView pressSendButtonWithText:(NSString *)text;

/*!
 @abstract Run out of sequence message test
 
 */
- (void)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView startOutOfSequenceMessageTest:(BOOL)start;

/*!
 @abstract Call when sticker is selected
 
 Delegate takes resource and creates a sticker CDMessage
 */
- (void)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView pressStickerResource:(CDResource *)resource;

/*!
 @abstract Call when emoticon button is pressed
 
 @return YES if we can proceed to show emoticon
 
 Delegate should show emoticon keypad
 */
- (BOOL)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView pressEmoticonButton:(UIButton *)button;

/*!
 @abstract Call when keypad button is pressed
 
 Delegate should show default keypad
 */
- (void)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView pressKeypadButton:(UIButton *)button;

/*!
 @abstract Call when attach button is pressed
 
 Delegate should show attach action sheet
 */
- (void)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView pressAttachButton:(UIButton *)button;

/*!
 @abstract Call when a typing now message should be sent out - indicates toolbar is content is changing
 
 Delegate should send out the message
 */
- (void)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView isTypingNow:(BOOL)isTypingNow;


/*!
 @abstract Inform delegate to enable or disable keyboard animation adjustments
 
 Use:
 - This is used to temporarily disable chat dialog animation during quick emoticon/text keyboard changes
 
 */
- (void)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView enableKeyboardAnimation:(BOOL)enableKeyboardAnimation;

@end


@class HPGrowingTextView;

@interface ChatDialogToolBarView : UIImageView <HPGrowingTextViewDelegate, UITextViewDelegate, EmoticonKeypadDelegate> {
    
    id <ChatDialogToolBarViewDelegate> delegate;
    UIButton *sendButton;
    UIButton *emoticonButton;
    UIButton *keypadButton;
    UIButton *attachButton;
    
    HPGrowingTextView *multiTextField;
    
    //UITextView *textView;
    UITextField *textEditor;
    
    EmoticonKeypad *emoticonKeypad;
    
    NSTimeInterval lastTypeTimeInterval;
    
}

@property (nonatomic, assign) id <ChatDialogToolBarViewDelegate> delegate;
@property (nonatomic, retain) UIButton *sendButton;
@property (nonatomic, retain) UIButton *emoticonButton;
@property (nonatomic, retain) UIButton *keypadButton;
@property (nonatomic, retain) UIButton *attachButton;

@property (nonatomic, retain) HPGrowingTextView *multiTextField;
@property (nonatomic, retain) UITextField *textEditor;
@property (nonatomic, retain) EmoticonKeypad *emoticonKeypad;

/*! last date when typing occurred - helps throttle typing messages */
@property (nonatomic, assign) NSTimeInterval lastTypeTimeInterval;



- (void) resignTextField;
- (void) setSendButtonEnabled:(BOOL)enabled ignoreCurrentTextLength:(BOOL)ignoreTextLength;
- (void) disableControlsWithMessage:(NSString *)disableMessage;
- (void) enableControls;
- (void) showEmoticonButton;

@end
