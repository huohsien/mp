//
//  ChatDialogToolBarView.m
//  mp
//
//  Created by M Tsai on 11-10-20.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "ChatDialogToolBarView.h"
#import <QuartzCore/QuartzCore.h>
#import "MPFoundation.h"
#import "CDResource.h"


#define kBaseSize   30.0

#define DISABLE_LABEL_TAG   11001


// Throttle limit for typing messages
// - this should be frequent enough to keep typing effect going on other side
// - so if animation last 4 sec, then this limit should be less than 4 secs but not
//   too small so that we waste bandwidth
//
CGFloat const kMPParamTypingFrequencySeconds = 3.5;

/*! The maximum allowed text message byte length */
CGFloat const kMPParamTextMessageLengthMax = 2500;


// setup view sizes
CGFloat const kDefaultViewHeight = kBaseSize;

CGFloat const kSmallButtonWidth = kBaseSize;
CGFloat const kSmallButtonHeight = kBaseSize;
CGFloat const kLargeButtonWidth = 60.0;
CGFloat const kLargeButtonHeight = 27.0;
CGFloat const kPadding = 5.0;


@implementation ChatDialogToolBarView

@synthesize delegate;
@synthesize sendButton;
@synthesize emoticonButton;
@synthesize keypadButton;
@synthesize attachButton;
@synthesize textEditor;
@synthesize multiTextField;
@synthesize emoticonKeypad;
@synthesize lastTypeTimeInterval;

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.emoticonKeypad.delegate = nil;
    
    [sendButton release];
    [emoticonButton release];
    [keypadButton release];
    [attachButton release];
    [textEditor release];
    [multiTextField release];
    [emoticonKeypad release];

    
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{

    self = [super initWithFrame:frame];
    if (self) {
        
        
        // Initialization code
        
        // always on bottom and can stretch in width
        //
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        
        UIImage *backImage = [Utility resizableImage:[UIImage imageNamed:@"chat_toolbar.png"] leftCapWidth:2.0 topCapHeight:18.0];
        self.image = backImage;
        self.userInteractionEnabled = YES;
        
        self.backgroundColor = [UIColor grayColor];
        
        // add emoticon button
        //
        //UIButton *eButton = [[UIButton alloc] initWithFrame:CGRectMake(kPadding, kPadding, kSmallButtonWidth, kSmallButtonHeight)];
        CGRect leftButtonRect = CGRectMake(0.0, kPadding*-4.0, kSmallButtonWidth+kPadding, kSmallButtonHeight+kPadding*5.0);
        UIButton *eButton = [[UIButton alloc] initWithFrame:leftButtonRect];
        [eButton setImage:[UIImage imageNamed:@"chat_btn_dialog_emoti_nor.png"] forState:UIControlStateNormal];
        [eButton setImage:[UIImage imageNamed:@"chat_btn_dialog_emoti_prs.png"] forState:UIControlStateHighlighted];
        [eButton setContentEdgeInsets:UIEdgeInsetsMake(kPadding*5.0, kPadding, 0.0, 0.0)];
        [eButton addTarget:self action:@selector(pressEmoticon:) forControlEvents:UIControlEventTouchUpInside];
        eButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
        //eButton.backgroundColor = [UIColor blueColor];
        [self addSubview:eButton];
        self.emoticonButton = eButton;
        [eButton release];
        self.emoticonButton.enabled = YES;
        
        // add keypad button - 
        //
        UIButton *kButton = [[UIButton alloc] initWithFrame:leftButtonRect];
        [kButton setImage:[UIImage imageNamed:@"chat_btn_dialog_keypad_nor.png"] forState:UIControlStateNormal];
        [kButton setImage:[UIImage imageNamed:@"chat_btn_dialog_keypad_prs.png"] forState:UIControlStateHighlighted];
        [kButton setContentEdgeInsets:UIEdgeInsetsMake(kPadding*5.0, kPadding, 0.0, 0.0)];
        [kButton addTarget:self action:@selector(pressKeypad:) forControlEvents:UIControlEventTouchUpInside];
        kButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
        
        [self addSubview:kButton];
        self.keypadButton = kButton;
        [kButton release];
        self.keypadButton.hidden = YES;
        
        
        // add attachment button
        //
        CGRect rightButtonRect = CGRectMake(37.0, kPadding*-4.0, kSmallButtonWidth+kPadding, kSmallButtonHeight+kPadding*5.0);

        UIButton *atButton = [[UIButton alloc] initWithFrame:rightButtonRect];
        [atButton setImage:[UIImage imageNamed:@"chat_btn_dialog_attach_nor.png"] forState:UIControlStateNormal];
        [atButton setImage:[UIImage imageNamed:@"chat_btn_dialog_attach_prs.png"] forState:UIControlStateHighlighted];
        [atButton setContentEdgeInsets:UIEdgeInsetsMake(kPadding*5.0, 0.0, 0.0, kPadding)];
        [atButton addTarget:self action:@selector(pressAttach:) forControlEvents:UIControlEventTouchUpInside];
        atButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
        //atButton.backgroundColor = [UIColor greenColor];
        [self addSubview:atButton];
        self.attachButton = atButton;
        [atButton release];
        //self.attachButton.enabled = NO;
        
        
        // add multi line textfield
        HPGrowingTextView *newTF = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(70.0, 3.0, 180.0, 30.0)];
        
        // already set as default values to save CPU
        //newTF.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
        //newTF.minNumberOfLines = 1;
        //newTF.maxNumberOfLines = 4;
        //newTF.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];

        newTF.returnKeyType = UIReturnKeyDefault; //just as an example
        newTF.textColor = [UIColor blackColor];// [AppUtility colorForContext:kAUColorTypeLightGray1];
        newTF.delegate = self;
        newTF.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
        [newTF setAllBackgroundColor:[UIColor clearColor]];
        self.multiTextField = newTF;
        
        
        UIImage *rawEntryBackground = [UIImage imageNamed:@"chat_textbar.png"];
        UIImage *fieldImage = [Utility resizableImage:rawEntryBackground leftCapWidth:14.0 topCapHeight:14.0];
        UIImageView *fieldImageView = [[UIImageView alloc] initWithImage:fieldImage];
        fieldImageView.frame = CGRectMake(70.0, 5.0, 180.0, 30);
        fieldImageView.backgroundColor = [UIColor clearColor];
        fieldImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        newTF.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        //newTF.backgroundColor = [UIColor blueColor];
        
        // view hierachy
        [self addSubview:fieldImageView];
        [self addSubview:newTF];
        [newTF release];
        [fieldImageView release];
        
        
        // add send button std_btn_green5_nor
        //
        UIButton *sButton = [[UIButton alloc] initWithFrame:CGRectMake(255.0, kPadding, kLargeButtonWidth, kLargeButtonHeight)];
        [sButton setTitle:NSLocalizedString(@"Send", @"ChatDialog Toolbar - Button: send message button") forState:UIControlStateNormal];
        sButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldSmall];
        
        [sButton setBackgroundImage:[UIImage imageNamed:@"chat_btn_send_nor.png"] forState:UIControlStateNormal];
        [sButton setBackgroundImage:[UIImage imageNamed:@"chat_btn_send_prs.png"] forState:UIControlStateHighlighted];
        [sButton setBackgroundImage:[UIImage imageNamed:@"chat_btn_send_dis.png"] forState:UIControlStateDisabled];
        
        [sButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        [sButton setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [sButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 2.0, 0.0)];
        sButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;

        
        [sButton addTarget:self action:@selector(pressSend:) forControlEvents:UIControlEventTouchUpInside];
        
        // @TEST
        // add out of sequence test
        //
        //[sButton addTarget:self action:@selector(doubleTapSend:) forControlEvents:UIControlEventTouchUpOutside];

       
        
        
        // disabled since there is no text at first
        sButton.enabled = NO;
        [self addSubview:sButton];
        self.sendButton = sButton;
        [sButton release];
        
        // don't disable even if no-network
        /*if (![[AppUtility getSocketCenter] isLoggedIn]) {
            [self setButtonsEnabled:NO];
        }*/
        
        // always listen for connect or network loss event
        //
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLostNetwork:) name:MP_SOCKETCENTER_NETWORK_NOTREACHABLE_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleConnectTry:) name:MP_SOCKETCENTER_CONNECT_TRY_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleConnectSuccess:) name:MP_SOCKETCENTER_CONNECT_SUCCESS_NOTIFICATION object:nil];
        
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

/*!
 @abstract resigns this view's textfield
 */
- (void) resignTextField {
    
    [self.multiTextField resignFirstResponder];
    
    //[self.textEditor resignFirstResponder];

}


#pragma mark - UIView 

/*!
 @abstract return views that should respond to events given a point in the local frame
 
 This is needed since this parent frame is smaller and does not hold all subviews within it's bounds.
 - views outside of bounds are usually not responsive at all.
 - this enables them to respond even though out of bounds
 
 */
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    
    // subviews is ordered from back most view to the front most view
    // - so we want to test the front most view first
    //
    NSEnumerator *reverseE = [self.subviews reverseObjectEnumerator];
    
    UIView *iSubView;
    
    while ((iSubView = [reverseE nextObject])) {
        
        UIView *viewWasHit = [iSubView hitTest:[self convertPoint:point toView:iSubView] withEvent:event];
        if(viewWasHit) return viewWasHit;
    
    }
    return [super hitTest:point withEvent:event];
}


#pragma mark - Button Methods

/*!
 @abstract Sets toolb bar button to enabled or disabled
 
 */
- (void) setButtonsEnabled:(BOOL)enabled {
    
    self.attachButton.enabled = enabled;
    self.emoticonButton.enabled = enabled;
    self.keypadButton.enabled = enabled;
}

/*!
 @abstract Show Emoticon button and not Keypad button
 
 Use:
 - call when keypad is hidden to reset the toolbar
 
 */
- (void) showEmoticonButton {
    self.emoticonButton.hidden = NO;
    self.keypadButton.hidden = YES;
    self.multiTextField.internalTextView.inputView = nil;
}

/*!
 */
- (UIView *) emoticonKeyPad {
    
    UIView *backView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 216.0)] autorelease];
    backView.backgroundColor = [UIColor lightGrayColor];
    
    return backView;
}

/*!
 @abstract press emoticon button
 */
- (void) pressEmoticon:(id)sender {
    
    BOOL shouldShowEmoticon = NO;
    if ([self.delegate respondsToSelector:@selector(ChatDialogToolBarView:shouldProceedWithAction:)]) {
        shouldShowEmoticon = [self.delegate ChatDialogToolBarView:self shouldProceedWithAction:@"emoticon"];
    }
    
    if (!shouldShowEmoticon) {
        return;
    }
    
    self.emoticonButton.hidden = YES;
    self.keypadButton.hidden = NO;
    
    // lazy create emoticon view
    // add it as a subview
    //
    if (!self.emoticonKeypad) {
        /*EmoticonKeypad *newKP = [[EmoticonKeypad alloc] initWithFrame:CGRectMake(0.0, self.multiTextField.frame.origin.y+self.multiTextField.frame.size.height+3.0, 1.0, 1.0)];
        newKP.delegate = self;
        self.emoticonKeypad = newKP;
        [newKP release];*/

        self.emoticonKeypad = [[AppUtility getAppDelegate] emoticonKeypad]; //[EmoticonKeypad sharedEmoticonKeypad];
        self.emoticonKeypad.delegate = self;
        [self.emoticonKeypad setFrameOrigin:CGPointMake(0.0, 0.0)];
        [self.emoticonKeypad setMode:kEKModeDefault];
        
        // set emoticon first
        [self.emoticonKeypad setKeypadForIndex:0];        
    }
    
    
    /*
     keyboard animation should be disabled if we are just switching from one keyboard to another
     - otherwise a bounce animaiton will show up
     - but make sure animation does occur if the keyboard is not showing at all
     
     ==> This is resolved by disabling dialog animation instead!
     */
    /*BOOL shouldDisableKBAnimation = NO;
    if ([self.multiTextField.internalTextView isFirstResponder]) {
        shouldDisableKBAnimation = YES;
    }*/
    
    /*if (shouldDisableKBAnimation && [self.delegate respondsToSelector:@selector(ChatDialogToolBarView:enableKeyboardAnimation:)]) {
        [self.delegate ChatDialogToolBarView:self enableKeyboardAnimation:NO];
    }*/
    
    // dismiss the keypad and set the new emoticon keypad!
    [self.multiTextField resignFirstResponder];
    self.multiTextField.internalTextView.inputView = self.emoticonKeypad;
    [self.multiTextField becomeFirstResponder];
    
    /*if (shouldDisableKBAnimation && [self.delegate respondsToSelector:@selector(ChatDialogToolBarView:enableKeyboardAnimation:)]) {
        [self.delegate ChatDialogToolBarView:self enableKeyboardAnimation:YES];
    }*/
}

/*!
 @abstract press keypad button
 
 - 
 */
- (void) pressKeypad:(id)sender {
    self.emoticonButton.hidden = NO;
    self.keypadButton.hidden = YES;   
    
    /*
     Disable animation since we are just switching from emoticon to text keyboard
     - we assume that the keyboard is always showing during this state.
     - so we are not starting from a keyboard hidden state.
     */
    /*BOOL shouldDisableKBAnimation = YES;
    
    if (shouldDisableKBAnimation && [self.delegate respondsToSelector:@selector(ChatDialogToolBarView:enableKeyboardAnimation:)]) {
        [self.delegate ChatDialogToolBarView:self enableKeyboardAnimation:NO];
    }*/
    
    // dismiss the keypad and set the new emoticon keypad!
    [self.multiTextField resignFirstResponder];
    self.multiTextField.internalTextView.inputView = nil;
    [self.multiTextField becomeFirstResponder];

    /*if (shouldDisableKBAnimation && [self.delegate respondsToSelector:@selector(ChatDialogToolBarView:enableKeyboardAnimation:)]) {
        [self.delegate ChatDialogToolBarView:self enableKeyboardAnimation:YES];
    }*/
}

/*!
 @abstract press attachment button
 */
- (void) pressAttach:(id)sender {

    if ([self.delegate respondsToSelector:@selector(ChatDialogToolBarView:pressAttachButton:)]){
        [self.delegate ChatDialogToolBarView:self pressAttachButton:sender];
    }
    // dismiss keypad
    [self resignTextField];
     
    
}

/*!
 @abstract press Send button
 */
- (void) pressSend:(id)sender {
    
    // resets the shared emoticon keypad
    [[AppUtility getAppDelegate] resetEmoticonKeypad];
    
    if ([self.delegate respondsToSelector:@selector(ChatDialogToolBarView:pressSendButtonWithText:)]){
        
        NSString *text = self.multiTextField.text;
        NSInteger textLength = [text length];
        
        if (textLength > kMPParamTextMessageLengthMax) {
            text = [self.multiTextField.text substringToIndex:kMPParamTextMessageLengthMax];
        }
        
        BOOL isBlocked = [self.delegate ChatDialogToolBarView:self pressSendButtonWithText:text];
        
        // if not blocked - clear and reset send button
        if (!isBlocked) {
            self.multiTextField.text = nil;
            [self setSendButtonEnabled:NO ignoreCurrentTextLength:NO];
        }
        
        //[self.delegate ChatDialogToolBarView:self pressSendButtonWithText:self.textEditor.text];
        //self.textEditor.text = nil;
    }
}

/*!
 @abstract press Send button
 */
- (void) doubleTapSend:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(ChatDialogToolBarView:startOutOfSequenceMessageTest:)]){
        [self.delegate ChatDialogToolBarView:self startOutOfSequenceMessageTest:YES];
    }
}

#pragma mark - Network handlers

/*!
 @abstract Lost network
 
 */
- (void) handleLostNetwork:(NSNotification *)notification {
        
    // disable send
    /*
    [self setSendButtonEnabled:NO ignoreCurrentTextLength:NO];
    [self setButtonsEnabled:NO];
     */
}


/*!
 @abstract Trying to connect - lost connection
 
 */
- (void) handleConnectTry:(NSNotification *)notification {
        
    // we are not connected so disable
    /*
    [self setSendButtonEnabled:NO ignoreCurrentTextLength:NO];
    [self setButtonsEnabled:NO];
     */
}

/*!
 @abstract We are connected!
 
 */
- (void) handleConnectSuccess:(NSNotification *)notification {
        
    // try enabling send
    [self setSendButtonEnabled:YES ignoreCurrentTextLength:NO];
    [self setButtonsEnabled:YES];
    
}


#pragma mark - External 

/*!
 @abstract Enables and disabled send button
 
 @param enable  Enable or disable send button
 @param ignoreCurrentTextLength  ignore current text message length
 
 */
- (void) setSendButtonEnabled:(BOOL)enabled ignoreCurrentTextLength:(BOOL)ignoreTextLength {
    
    // don't enabled
    // - if text field is disabled
    // - or if not logged in
    // - or if no text available
    // - of if no network
    if (enabled) {
        
        /*if (self.multiTextField.editable == NO || 
            ![[AppUtility getSocketCenter] isLoggedIn] ||
            ![[AppUtility getSocketCenter] isNetworkReachable]) {
            enabled = NO;
        }*/
        if (self.multiTextField.editable == NO) {
            enabled = NO;
        }
        NSString *inputText = [Utility trimWhiteSpace:self.multiTextField.text];
        
        if (!ignoreTextLength && [inputText length] == 0) {
            enabled = NO;
        }
    }
    
    self.sendButton.enabled = enabled;
}

/*!
 @abstract Disables tool bar since this p2p chat user's account is cancelled
 
 - Disable buttons
 - Set placeholder
 
 */
- (void) disableControlsWithMessage:(NSString *)disableMessage {
    
    // disable controls
    [self setSendButtonEnabled:NO ignoreCurrentTextLength:NO];
    [self setButtonsEnabled:NO];

    
    UIView *previousLabel = [self.multiTextField viewWithTag:DISABLE_LABEL_TAG];

    // prevent adding duplicate labels 
    //
    if (!previousLabel) {
        // add text label
        //
        CGRect labelFrame = self.multiTextField.bounds;
        labelFrame.size.height -= 5.0;
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:labelFrame];
        messageLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
        messageLabel.textColor = [AppUtility colorForContext:kAUColorTypeLightGray1];
        messageLabel.backgroundColor = [UIColor clearColor];
        messageLabel.textAlignment = UITextAlignmentCenter;
        messageLabel.text = disableMessage; // 
        messageLabel.tag = DISABLE_LABEL_TAG;
        [self.multiTextField addSubview:messageLabel];
        [messageLabel release];
        self.multiTextField.textColor = [UIColor clearColor];
        self.multiTextField.editable = NO;
    }
}

/*!
 @abstract Enable controls 
 
 - Also checks connectivity before enabling
 
 */
- (void) enableControls {
    
    // remove disable label
    //
    UIView *messageLabel = [self.multiTextField viewWithTag:DISABLE_LABEL_TAG];
    [messageLabel removeFromSuperview];
    
    self.multiTextField.textColor = [UIColor blackColor];
    self.multiTextField.editable = YES;
    
    // check connecitivity and enable/disable properly
    // 
    if ([[AppUtility getSocketCenter] isLoggedIn]) {
        [self handleConnectSuccess:nil];
    }
    else {
        [self handleLostNetwork:nil];
    }

}


#pragma mark - Grow TextField Delegate

- (BOOL)growingTextViewShouldBeginEditing:(HPGrowingTextView *)growingTextView{
    
    BOOL shouldProceed = NO;
    if ([self.delegate respondsToSelector:@selector(ChatDialogToolBarView:shouldProceedWithAction:)]) {
        shouldProceed = [self.delegate ChatDialogToolBarView:self shouldProceedWithAction:@"emoticon"];
    }
    return shouldProceed;
}


/*!
 @abstract Change toolbar height if text field height changes
 */
- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff = (growingTextView.frame.size.height - height);
    
    CGRect myFrame = self.frame;
    myFrame.size.height -= diff;
    myFrame.origin.y += diff;
    self.frame = myFrame;
}

/*!
 @abstract Enable and disabled send button depending if there is text
 */
- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    // check if it is an emoticon - if so delete the entire emoticon
    NSString *currentText = growingTextView.text;
    
    NSRange selectedRange = growingTextView.selectedRange;
    NSString *startText = [currentText substringToIndex:selectedRange.location];
    NSString *endText = [currentText substringFromIndex:selectedRange.location + selectedRange.length];
    
    // if deleting a ")" char
    if ([startText hasSuffix:@")"] && [text isEqualToString:@""]) {
        
        // search backwards to find "("
        NSRange startRange = [startText rangeOfString:@"(" options:NSBackwardsSearch];
                
        if (startRange.location != NSNotFound) {
            NSString *isEmoticonText = [startText substringFromIndex:startRange.location];
            CDResource *emoticon = [[MPResourceCenter sharedMPResourceCenter] emoticonForText:isEmoticonText];
            if (emoticon) {
                
                NSString *newStartText = [startText substringToIndex:startRange.location];
                NSString *finalText = nil;
                if (endText) {
                    finalText = [newStartText stringByAppendingString:endText];
                }
                else {
                    finalText = newStartText;
                }
                growingTextView.text = finalText;
                growingTextView.selectedRange = NSMakeRange(startRange.location, 0);

                NSString *trimmedText = [Utility trimWhiteSpace:growingTextView.text];
                NSInteger afterLength = [trimmedText length];
                
                if (afterLength > 0){
                    [self setSendButtonEnabled:YES ignoreCurrentTextLength:YES];
                }
                else{
                    [self setSendButtonEnabled:NO ignoreCurrentTextLength:YES];
                }
                return NO; // we modified text manually
            }
        }
    }
    
    /* Cannot delete emoticon in the middle of text, only at the end
     if ([[currentText substringWithRange:range] isEqualToString:@")"] && [text isEqualToString:@""]) {
     
     // search backwards to find "("
     NSRange startRange = [currentText rangeOfString:@"(" options:NSBackwardsSearch];
     if (startRange.location != NSNotFound) {
     NSString *isEmoticonText = [currentText substringFromIndex:startRange.location];
     CDResource *emoticon = [[MPResourceCenter sharedMPResourceCenter] emoticonForText:isEmoticonText];
     if (emoticon) {
     growingTextView.text = [currentText substringToIndex:startRange.location];
     NSString *trimmedText = [Utility trimWhiteSpace:growingTextView.text];
     NSInteger afterLength = [trimmedText length];
     
     if (afterLength > 0){
     [self setSendButtonEnabled:YES ignoreCurrentTextLength:YES];
     }
     else{
     [self setSendButtonEnabled:NO ignoreCurrentTextLength:YES];
     }
     return NO; // we changed manually
     }
     }
     }
     */
    
    // otherwise we proceed with text change
    //
    NSString *newText = [growingTextView.text stringByReplacingCharactersInRange:range withString:text];
    NSString *trimmedText = [Utility trimWhiteSpace:newText];
    NSInteger afterLength = [trimmedText length];
    
    if (afterLength > 0){
        [self setSendButtonEnabled:YES ignoreCurrentTextLength:YES];
    }
    else{
        [self setSendButtonEnabled:NO ignoreCurrentTextLength:YES];
    }
    
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    
    // if time is up that we can send messages again
    //
    if (currentTime - self.lastTypeTimeInterval > kMPParamTypingFrequencySeconds) {
        self.lastTypeTimeInterval = currentTime;
        if ([self.delegate respondsToSelector:@selector(ChatDialogToolBarView:isTypingNow:)]) {
            [self.delegate ChatDialogToolBarView:self isTypingNow:YES];
        }
    }
    // if typing is too frequent, do nothing
    
    return YES;
}

#pragma mark - EmoticonKeypad Delegate

/*!
 @abstract User pressed delete key
 */
- (void)EmoticonKeypad:(EmoticonKeypad *)emoticonKeypad pressDelete:(id)sender {
    
    // check if it is an emoticon - if so delete the entire emoticon
    NSString *currentText = self.multiTextField.text;
    
    NSRange selectedRange = self.multiTextField.selectedRange;
    //DDLogInfo(@"PD - rng:%d ct: %@", selectedRange.location, currentText);

    // if at start nothing to do
    if (selectedRange.location == 0 && selectedRange.length == 0) {
        return;
    }
    
    NSString *startText = [currentText substringToIndex:selectedRange.location];
    NSString *endText = [currentText substringFromIndex:selectedRange.location + selectedRange.length];
    
    // if selected, just delete that selected text
    if (selectedRange.length > 0) {

        self.multiTextField.text = [startText stringByAppendingString:endText];
        self.multiTextField.selectedRange = NSMakeRange(selectedRange.location, 0);
        
    }
    // zero length selected range
    else {
        
        NSString *newStartText = nil;
        NSRange newSelectedRange = NSMakeRange(0, 0);
        
        // if possible emoticon
        if ([startText hasSuffix:@")"]) {
            // search backwards to find "("
            NSRange startRange = [startText rangeOfString:@"(" options:NSBackwardsSearch];
            if (startRange.location != NSNotFound) {
                NSString *isEmoticonText = [startText substringFromIndex:startRange.location];
                CDResource *emoticon = [[MPResourceCenter sharedMPResourceCenter] emoticonForText:isEmoticonText];
                if (emoticon) {
                    newSelectedRange = NSMakeRange(startRange.location, 0);
                    newStartText = [startText substringToIndex:startRange.location];
                }
            }
        }
        
        // just delete on char at cursor
        // - if emoticon was not found above
        if ([currentText length] > 0 && !newStartText) {
            newSelectedRange = NSMakeRange([startText length]-1, 0);
            newStartText = [startText substringToIndex:newSelectedRange.location];
        }
        
        if (newStartText) {
            NSString *finalText = nil;
            if (endText) {
                finalText = [newStartText stringByAppendingString:endText];
            }
            else {
                finalText = newStartText;
            }
            self.multiTextField.text = finalText;
            self.multiTextField.selectedRange = newSelectedRange;
            
            NSString *trimmedText = [Utility trimWhiteSpace:finalText];
            NSInteger afterLength = [trimmedText length];
            
            if (afterLength > 0){
                [self setSendButtonEnabled:YES ignoreCurrentTextLength:YES];
            }
            else{
                [self setSendButtonEnabled:NO ignoreCurrentTextLength:YES];
            }
        }
    }
    
    
    /* This only deletes from the end of the current text
     
    // if deleting end, check if it is an emoticon - if so delete the entire emoticon
    NSString *currentText = self.multiTextField.text;
    if ([currentText hasSuffix:@")"]) {
        
        // search backwards to find "("
        NSRange startRange = [currentText rangeOfString:@"(" options:NSBackwardsSearch];
        if (startRange.location != NSNotFound) {
            NSString *isEmoticonText = [currentText substringFromIndex:startRange.location];
            CDResource *emoticon = [[MPResourceCenter sharedMPResourceCenter] emoticonForText:isEmoticonText];
            if (emoticon) {
                self.multiTextField.text = [currentText substringToIndex:startRange.location];
                NSString *trimmedText = [Utility trimWhiteSpace:self.multiTextField.text];
                NSInteger afterLength = [trimmedText length];
                
                if (afterLength > 0){
                    [self setSendButtonEnabled:YES ignoreCurrentTextLength:YES];
                }
                else{
                    [self setSendButtonEnabled:NO ignoreCurrentTextLength:YES];
                }
            }
        }
    }
    // just delete on char otherwise
    else if ([currentText length] > 0) {
        self.multiTextField.text = [currentText substringToIndex:[currentText length]-1];
    }
     */
}

/*!
 @abstract User pressed this resource
 
 - emoticon & petphrase: appends text
 - sticker: send resource to chat scroll view to display
 
 */
- (void)EmoticonKeypad:(EmoticonKeypad *)emoticonKeypad resource:(CDResource *)resource {
    
    
    // text based: emoticons and petphrase
    //
    RCType rcType = [resource rcType];
    
    // emoticon and petphrase, just append the new text
    //
    if (rcType == kRCTypeEmoticon || rcType == kRCTypePetPhrase) {
        
        NSRange oldRange = self.multiTextField.selectedRange;
        self.multiTextField.text = [self.multiTextField.text stringByReplacingCharactersInRange:oldRange withString:resource.text];
        // set cursor behind emoticon
        self.multiTextField.selectedRange = NSMakeRange(oldRange.location+[resource.text length], 0);
        
        // this does not update heigth - use range solution above
        //[self.multiTextField.internalTextView insertText:resource.text];        
        
        [self setSendButtonEnabled:YES ignoreCurrentTextLength:YES];
    }
    else if (rcType == kRCTypeSticker) {
        if ([self.delegate respondsToSelector:@selector(ChatDialogToolBarView:pressStickerResource:)]) {
            [self.delegate ChatDialogToolBarView:self pressStickerResource:resource];
        }
    }
}



#pragma mark - TextView Delegates

/*
- (void)scrollContainerToCursor:(UIScrollView*)scrollView {
    if (self.textView.hasText) {
        if (scrollView.contentSize.height > scrollView.frame.size.height) {
            NSRange range = self.textView.selectedRange;
            if (range.location == self.textView.text.length) {
                [scrollView scrollRectToVisible:CGRectMake(0,scrollView.contentSize.height-1,1,1)
                                       animated:NO];
            }
        } else {
            [scrollView scrollRectToVisible:CGRectMake(0,0,1,1) animated:NO];
        }
    }
}*/

@end
