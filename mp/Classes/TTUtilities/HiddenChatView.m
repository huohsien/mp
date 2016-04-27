//
//  TTRefreshTableHeaderView.m
//  ContactBook
//
//  Created by M Tsai on 11-3-22.
//  Copyright 2011 TernTek. All rights reserved.
//

#import "HiddenChatView.h"
#import <QuartzCore/QuartzCore.h>
#import "MPFoundation.h"
#import "CDChat.h"
#import "MPChatManager.h"


#define TEXT_COLOR [UIColor colorWithRed:0.341 green:0.737 blue:0.537 alpha:1.0]
#define BORDER_COLOR [UIColor blackColor]

#define kHCHeightLockNow    55.0
#define kHCHeightWall       145.0
#define kHCHeightPIN        57.0
#define kHCHeightWallFull   425.0   // actually image height
#define kHCHeightWallExtra  280.0   // height added




#define ENABLE_VIEW_TAG     16001
#define KEY_VIEW_TAG        16002

#define PIN_E_TAG           16003
#define PIN_F_TAG           16004
#define PIN_G_TAG           16005
#define PIN_H_TAG           16006

#define E_LABEL_TAG         16007
#define F_LABEL_TAG         16008
#define G_LABEL_TAG         16009
#define H_LABEL_TAG         16010

#define MESSAGE_TAG         17001
#define MESSAGE_LABEL_TAG   17002

#define SAFE_TAG            17003
#define LOCKNOW_TAG         17004

#define BEAR1_TAG           17005
#define BEAR2_TAG           17006

@interface HiddenChatView (Private)

- (void) closeAndReset;
- (void)setStatusChangePIN;

@end


@implementation HiddenChatView

@synthesize isAlignedToTop;

@synthesize isFlipped;
@synthesize viewStatus; // arrowImage, speakingLabel, 
@synthesize frameButton;
@synthesize containerView;
@synthesize delegate;

@synthesize tempNewPIN;
@synthesize allowEnterPIN;

@synthesize eLabel;
@synthesize fLabel;
@synthesize gLabel;
@synthesize hLabel;

@synthesize hiddenTextField;

@synthesize performTimer;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[frameButton release];
    [containerView release];
    [tempNewPIN release];
    [eLabel release];
    [fLabel release];
    [gLabel release];
    [hLabel release];
    [hiddenTextField release];
    [performTimer release];
    
    [super dealloc];
}

/**
 Initialize this view
 - setup all components
 */
- (id)initWithFrame:(CGRect)frame isAlignedToTop:(BOOL)alignedToTop {
    if ((self = [super initWithFrame:frame]))
	{
        self.isAlignedToTop = alignedToTop;
        self.allowEnterPIN = YES;
        
        self.userInteractionEnabled = YES;
		self.viewStatus = kHCViewStatusClose;
		
		self.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
		
        CGFloat startY = 0.0;
        if (!self.isAlignedToTop) {
            startY = frame.size.height - kHCHeightWallFull;
        }
        else {
            startY = kHCHeightWall - kHCHeightWallFull;
        }
        
        UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.0f, startY, 320.0f, kHCHeightWallFull)];
        // views outside of bounds are hidden
        container.clipsToBounds = YES;
        container.userInteractionEnabled = YES;
        self.containerView = container;
        [container release];
		[self addSubview:self.containerView];
        
		// add wall
		//
		UIImageView *backView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hidden_wall.png"]];
		backView.frame = CGRectMake(0.0f, 0.0f, 320.0f, kHCHeightWallFull);
        backView.userInteractionEnabled = YES;
		[self.containerView addSubview:backView];
		
        
        // add safe
        //
        UIImageView *safeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hidden_box.png"]];
		safeView.frame = CGRectMake(65.0, 25.0+kHCHeightWallExtra, 185.0, 105.0);
        safeView.hidden = YES;
        safeView.tag = SAFE_TAG;
		[backView addSubview:safeView];
        [safeView release];
        
        
        // add frame button
        UIButton *newButton = [[UIButton alloc] initWithFrame:CGRectMake(35.0, 6.0+kHCHeightWallExtra, 250.0, 130.0)];
        self.frameButton = newButton;
        [newButton release];
        
        [self.frameButton setImage:[UIImage imageNamed:@"hidden_drawing_frame.png"] forState:UIControlStateNormal];
        [self.frameButton addTarget:self action:@selector(hideFrame:) forControlEvents:UIControlEventTouchDown];
		[backView addSubview:self.frameButton];
        [backView release];
        
        // add picture image
        UIImageView *pictureView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hidden_drawing1.png"]];
		pictureView.frame = CGRectMake(15, 17.5, 220, 95.0);
		[self.frameButton addSubview:pictureView];
        
        // add bear badge count images
        UIImageView *bear1Image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hidden_drawing2.png"]];
		bear1Image.frame = CGRectMake(0, 0, 220, 95.0);
        bear1Image.hidden = YES;
        bear1Image.tag = BEAR1_TAG;
		[pictureView addSubview:bear1Image];
        [bear1Image release];
        
        UIImageView *bear2Image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hidden_drawing3.png"]];
		bear2Image.frame = CGRectMake(0, 0, 220, 95.0);
        bear2Image.hidden = YES;
        bear2Image.tag = BEAR2_TAG;
		[pictureView addSubview:bear2Image];
        [bear2Image release];
        [pictureView release];

        
        // add pin views
        //
        UIImageView *pinView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hidden_code.png"]];
		pinView.frame = CGRectMake(0.0f, kHCHeightWallFull, 320.0f, kHCHeightPIN);
        pinView.userInteractionEnabled = YES;
		[self.containerView addSubview:pinView];
        
        
        // add key and nail
        //
        UIImageView *keyView = [[UIImageView alloc] initWithFrame:CGRectMake(25.0, 3.0, 21.0, 53.0)];
        keyView.image = [UIImage imageNamed:@"hidden_key.png"];
        keyView.tag = KEY_VIEW_TAG;
        [pinView addSubview:keyView];
        
        UIImageView *tackView = [[UIImageView alloc] initWithFrame:CGRectMake(7.0, 1.0, 7.0, 7.0)];
        tackView.image = [UIImage imageNamed:@"hidden_tack.png"];
        [keyView addSubview:tackView];
        [tackView release];
        [keyView release];
        
        CGRect rectE = CGRectMake(60.0, 7.0, 50.0, 45.0);
        CGRect rectF = CGRectMake(115.0, 7.0, 50.0, 45.0);
        CGRect rectG = CGRectMake(170.0, 7.0, 50.0, 45.0);
        CGRect rectH = CGRectMake(225.0, 7.0, 50.0, 45.0);

        
        // add red backgrounds
        //
        UIImageView *pinEView = [[UIImageView alloc] initWithFrame:rectE];
        pinEView.image = [UIImage imageNamed:@"hidden_code_e_wrong.png"];
        pinEView.alpha = 0.0;
        pinEView.tag = PIN_E_TAG;
        [pinView addSubview:pinEView];
        [pinEView release];
        
        UIImageView *pinFView = [[UIImageView alloc] initWithFrame:rectF];
        pinFView.image = [UIImage imageNamed:@"hidden_code_f_wrong.png"];
        pinFView.alpha = 0.0;
        pinFView.tag = PIN_F_TAG;
        [pinView addSubview:pinFView];
        [pinFView release];

        
        UIImageView *pinGView = [[UIImageView alloc] initWithFrame:rectG];
        pinGView.image = [UIImage imageNamed:@"hidden_code_g_wrong.png"];
        pinGView.alpha = 0.0;
        pinGView.tag = PIN_G_TAG;
        [pinView addSubview:pinGView];
        [pinGView release];

        
        UIImageView *pinHView = [[UIImageView alloc] initWithFrame:rectH];
        pinHView.image = [UIImage imageNamed:@"hidden_code_h_wrong.png"];
        pinHView.alpha = 0.0;
        pinHView.tag = PIN_H_TAG;
        [pinView addSubview:pinHView];
        [pinHView release];

        
        
        // add PIN Number Labels 
        //
        UILabel *newELabel = [[UILabel alloc] initWithFrame:rectE];
        [AppUtility configLabel:newELabel context:kAULabelTypeHiddenPIN];
        self.eLabel = newELabel;
        [newELabel release];
        [pinView addSubview:self.eLabel];
        
        UILabel *newFLabel = [[UILabel alloc] initWithFrame:CGRectOffset(rectF, 2.0, 0.0)];
        [AppUtility configLabel:newFLabel context:kAULabelTypeHiddenPIN];
        self.fLabel = newFLabel;
        [newFLabel release];
        [pinView addSubview:self.fLabel];
        
        UILabel *newGLabel = [[UILabel alloc] initWithFrame:CGRectOffset(rectG, 2.0, 0.0)];
        [AppUtility configLabel:newGLabel context:kAULabelTypeHiddenPIN];
        self.gLabel = newGLabel;
        [newGLabel release];
        [pinView addSubview:self.gLabel];
        
        UILabel *newHLabel = [[UILabel alloc] initWithFrame:CGRectOffset(rectH, 2.0, 0.0)];
        [AppUtility configLabel:newHLabel context:kAULabelTypeHiddenPIN];
        self.hLabel = newHLabel;
        [newHLabel release];
        [pinView addSubview:self.hLabel];
        [pinView release];
     
        
        // hidden text field to manage user input
        //
        UITextField *newField = [[UITextField alloc] initWithFrame:CGRectZero];
        newField.keyboardType = UIKeyboardTypeNumberPad;
        newField.delegate = self;
        [self.containerView addSubview:newField];
        self.hiddenTextField = newField;
        [newField release];
        
        // start in locked state
        [[MPSettingCenter sharedMPSettingCenter] lockHiddenChat:YES];
        
        
        // observer badge count updates
        // - and update HC's own badge count
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateHiddenChatBadge) name:MP_CHATMANAGER_UPDATE_BADGECOUNT_NOTIFICATION object:nil];
        
        // lock HC when entering background
        //
        /*
         Don't lock by here since view may be dellocated and still be notified causing crash
         - instead let parent controller take care of this
         
         [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(pressLockNowNoAnimation:)
                                                     name:UIApplicationDidEnterBackgroundNotification object:nil];
        */
        
		isFlipped = NO;
    }
    return self;
}



/**
 Draw a separator line a the bottom
 */
/*
- (void)drawRect:(CGRect)rect{
	
    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextDrawPath(context,  kCGPathFillStroke);
	[BORDER_COLOR setStroke];
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, 0.0f, self.bounds.size.height - 1);
	CGContextAddLineToPoint(context, self.bounds.size.width,
							self.bounds.size.height - 1);
	CGContextStrokePath(context);
}*/


#pragma mark - Tools

/*!
 @abstract displayes a new message instructions to user
 - hides previous message string
 
 @param Message to display, nil if messages should be hidden
 
 */
- (void)showMessage:(NSString *)message {
    
    UIFont *font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
    CGSize msgSize = [message sizeWithFont:font];
    msgSize.width = msgSize.width + 30.0; // add width padding
    msgSize.height = msgSize.height + 5.0;
    CGRect msgRect = CGRectMake((self.containerView.frame.size.width-msgSize.width)/2.0, kHCHeightWallFull - msgSize.height, msgSize.width, msgSize.height);
    
    
    UIImageView *messageView = (UIImageView *)[self.containerView viewWithTag:MESSAGE_TAG];
    
    // if old message view existed, hide it
    if (messageView) {
        [UIView animateWithDuration:0.3 
                         animations:^{
                             messageView.alpha = 0.0;
                         } 
                         completion:^(BOOL finished) {
                             
                             // resize and update message 
                             // - only if text exists
                             
                             if (message) {
                                 messageView.frame = msgRect;
                                 
                                 UILabel *messageLabel = (UILabel *)[messageView viewWithTag:MESSAGE_LABEL_TAG];
                                 messageLabel.text = message;
                                 
                                 // animate into view
                                 [UIView animateWithDuration:0.3 
                                                  animations:^{
                                                      messageView.alpha = 1.0;
                                                  }];
                             }
                             
                         }];
    }
    // shows a brand new message
    else {
        if (message) {
            UIImageView *newMsgView = [[UIImageView alloc] initWithFrame:msgRect];
            newMsgView.image = [Utility resizableImage:[UIImage imageNamed:@"hidden_icon_msg.png"] leftCapWidth:12.0 topCapHeight:8.0];
            newMsgView.alpha = 0.0;
            newMsgView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            newMsgView.tag = MESSAGE_TAG;
            
            UILabel *msgLabel = [[UILabel alloc] initWithFrame:newMsgView.bounds];
            msgLabel.font = font;
            msgLabel.textColor = [UIColor whiteColor];
            msgLabel.backgroundColor = [UIColor clearColor];
            msgLabel.textAlignment = UITextAlignmentCenter;
            msgLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            msgLabel.text = message;
            msgLabel.tag = MESSAGE_LABEL_TAG;
            [newMsgView addSubview:msgLabel];
            [msgLabel release];
            
            [self.containerView addSubview:newMsgView];
            
            // animate into view
            [UIView animateWithDuration:0.3 
                             animations:^{
                                 newMsgView.alpha = 1.0;
                             }];
            [newMsgView release];
        }
    }
}



#pragma mark - PIN 


/*!
 @abstract Show Safe View
 
 */
- (void) showSafeAnimated:(BOOL)animated {
    UIView *safeView = [self.containerView viewWithTag:SAFE_TAG];

    if (animated) {
        safeView.alpha = 0.0;
        safeView.hidden = NO;
        
        [UIView animateWithDuration:0.3 animations:^{
            safeView.alpha = 1.0;
        }];
    }
    else {
        safeView.hidden = NO;
    }
}

/*!
 @abstract Hides Safe View
 
 */
- (void) hideSafe {
    UIView *safeView = [self.containerView viewWithTag:SAFE_TAG];
    safeView.hidden = YES;
}

/*!
 @abstract Start Change PIN process
 
 */
- (void) startUnlock {
    
    NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
    BOOL isLocked = [[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];
    
    // if PIN exists
    //
    if (pin && isLocked) {
        [self showMessage:NSLocalizedString(@"Enter PIN to unlock hidden chats", @"HiddenChat - text: ask user for current PIN to unlock")];
    }
}

/*!
 @abstract Show PIN display
 
 */
- (void) showPINDisplay {
    
    [UIView animateWithDuration:0.3 
                     animations:^{
                         CGFloat yOffset = 0.0;
                         if (!self.isAlignedToTop) {
                             yOffset =  -kHCHeightPIN;
                         }
            
                         // expand old frame
                         CGRect newFrame = CGRectOffset(self.containerView.frame, 0.0, yOffset);
                         newFrame.size.height = kHCHeightWallFull + kHCHeightPIN;
                         self.containerView.frame = newFrame;
                         
                         if ([self.delegate respondsToSelector:@selector(HiddenChatView:showPINDisplayWithHeight:)]) {
                             [self.delegate HiddenChatView:self showPINDisplayWithHeight:kHCHeightPIN];
                         }
                         
                         [self.hiddenTextField becomeFirstResponder];
                     } 
                     completion:^(BOOL finished) {
                         if ([self.delegate respondsToSelector:@selector(HiddenChatView:showPINDisplayAnimationDidComplete:)]){
                             [self.delegate HiddenChatView:self showPINDisplayAnimationDidComplete:YES];
                         }
                     }];
}


/*!
 @abstract Start Change PIN process
 
 */
- (void) startChangePIN {
    
    NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
    //BOOL isLocked = [[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];
    
    
    // if PIN already defined
    // - then we are changing existing PIN
    //
    if (pin) {
        
        // always ask for old PIN! if old PIN exists
        [self setStatus:kHCViewStatusChangePINUnlockFirst];
        [self showMessage:NSLocalizedString(@"Enter current PIN", @"HiddenChat - text: ask user for current PIN before changing PIN")];
        
        /*
        // if locked, then enter old PIN first
        if (isLocked) {
            [self setStatus:kHCViewStatusChangePINUnlockFirst];
            [self showMessage:NSLocalizedString(@"Enter current PIN", @"HiddenChat - text: ask user for current PIN before changing PIN")];
        }
        else {
            [self showMessage:NSLocalizedString(@"Enter new PIN", @"HiddenChat - text: ask user to enter new PIN number")];
        }*/
    }
    // if PIN does not exists
    // - we are enabling HC and entering new PIN
    else {
        [self showMessage:NSLocalizedString(@"Enter new PIN", @"HiddenChat - text: ask user to enter new PIN number")];
    }
}

/*!
 @abstract Clear PIN number to start over
 
 @param showError Show red background to indicate error.
 
 Phase:1
 - If error
   ~ show red error backgrounds
   ~ vibrate
 - fade out numbers
 
 Phase:2
 - If error
   ~ fade out red backgrounds
 - show empty labels again
 
 */
- (void) clearPINShowError:(BOOL)showError animated:(BOOL)animated {
    
    self.hiddenTextField.text = @"";
    
    if (animated) {
        // don't allow users to tap pin number when animation is occuring
        self.allowEnterPIN = NO;
        UIView *eErrorView = [self.containerView viewWithTag:PIN_E_TAG];
        UIView *fErrorView = [self.containerView viewWithTag:PIN_F_TAG];
        UIView *gErrorView = [self.containerView viewWithTag:PIN_G_TAG];
        UIView *hErrorView = [self.containerView viewWithTag:PIN_H_TAG];
        
        if (showError) {
            eErrorView.alpha = 1.0;
            fErrorView.alpha = 1.0;
            gErrorView.alpha = 1.0;
            hErrorView.alpha = 1.0;
            [Utility vibratePhone];
        }
        
        [UIView animateWithDuration:1.0 
                         animations:^{
                             self.eLabel.alpha = 0.0;
                             self.fLabel.alpha = 0.0;
                             self.gLabel.alpha = 0.0;
                             self.hLabel.alpha = 0.0;
                         }
                         completion:^(BOOL finished){
                             self.eLabel.text = nil;
                             self.fLabel.text = nil;
                             self.gLabel.text = nil;
                             self.hLabel.text = nil;
                             
                             [UIView animateWithDuration:0.5 
                                              animations:^{
                                                  eErrorView.alpha = 0.0;
                                                  fErrorView.alpha = 0.0;
                                                  gErrorView.alpha = 0.0;
                                                  hErrorView.alpha = 0.0;
                                              }
                                              completion:^(BOOL finished){
                                                  self.eLabel.alpha = 1.0;
                                                  self.fLabel.alpha = 1.0;
                                                  self.gLabel.alpha = 1.0;
                                                  self.hLabel.alpha = 1.0;
                                                  self.allowEnterPIN = YES;
                                              }];
                             
                         }];
    }
    else {
        self.eLabel.text = nil;
        self.fLabel.text = nil;
        self.gLabel.text = nil;
        self.hLabel.text = nil;
    }
    
}

/*!
 @abstract When 4 numbers are entered, then process it right away
 
 kHCViewStatusUnlockPIN
  - match HC PIN? 
    ~ Y unlock and close HC
    ~ N report error
 
 kHCViewStatusChangePIN
  - save into temp PIN
  - reset PIN numbers
  - change to status to kHCViewStatusChangePINConfirm
 
 kHCViewStatusChangePINConfirm,
  - match temp PIN?
    ~ Y set new PIN and close HC
    ~ N report error and status set back to kHCViewStatusChangePIN
 
 kHCViewStatusChangePINUnlockFirst
  - match HC PIN? 
    ~ Y unlock and set state to kHCViewStatusChangePIN
    ~ N report error 
 
 */
- (void) processPIN:(NSString *)pinString {
    
    NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
    
    // Unlock HC
    //
    if (self.viewStatus == kHCViewStatusUnlockPIN) {
        if ([pinString isEqualToString:pin]) {
            // unlock
            [[MPSettingCenter sharedMPSettingCenter] lockHiddenChat:NO];
            
            //[self showMessage:NSLocalizedString(@"Unlocked", @"HiddenChat - text: user entered incorrect PIN number")];
            
            [UIView animateWithDuration:0.75 
                             animations:^{
                                 self.eLabel.alpha = 0.0;
                                 self.fLabel.alpha = 0.0;
                                 self.gLabel.alpha = 0.0;
                                 self.hLabel.alpha = 0.0;
                             }
                             completion:^(BOOL finished){
                                 if (finished) {
                                     // inform delegate of unlock
                                     if ([self.delegate respondsToSelector:@selector(HiddenChatView:unlockDidSucceed:)]) {
                                         [self.delegate HiddenChatView:self unlockDidSucceed:YES];
                                     }
                                     
                                     // hide hidden chat pull down view - animated
                                     if ([self.delegate respondsToSelector:@selector(HiddenChatView:closeWithAnimation:)]) {
                                         [self.delegate HiddenChatView:self closeWithAnimation:YES];
                                     }
                                 }
                             }];
        }
        else {
            [self showMessage:NSLocalizedString(@"Incorrect PIN", @"HiddenChat - text: user entered incorrect PIN number")];
            [self clearPINShowError:YES animated:YES];
            self.performTimer = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(startUnlock) userInfo:nil repeats:NO];
        }
    }
    // Change PIN
    //
    else if (self.viewStatus == kHCViewStatusChangePIN || self.viewStatus == kHCViewStatusChangePINEnter) {
        self.tempNewPIN = pinString;
        [self clearPINShowError:NO animated:YES];
        [self setStatus:kHCViewStatusChangePINConfirm];
    }
    // Confirm Change PIN
    //
    else if (self.viewStatus == kHCViewStatusChangePINConfirm) {
        if ([pinString isEqualToString:self.tempNewPIN]) {
            
            [[MPSettingCenter sharedMPSettingCenter] setHiddenChatPIN:self.tempNewPIN];
            // change an existing PIN
            if (pin) {
                [Utility showAlertViewWithTitle:NSLocalizedString(@"Change PIN", @"HiddenChat - title: change pin results") message:NSLocalizedString(@"Change PIN succeeded", @"HiddenChat - title: change pin is successful")];
            }
            // if setting a new PIN
            else {
                [Utility showAlertViewWithTitle:NSLocalizedString(@"Enable Hidden Chat", @"HiddenChat - title: change pin results") message:NSLocalizedString(@"Set new PIN succeeded", @"HiddenChat - title: change pin is successful")];
            }
            
            // unlock after setting new PIN
            [[MPSettingCenter sharedMPSettingCenter] lockHiddenChat:NO];
            
            // inform delegate of unlock
            if ([self.delegate respondsToSelector:@selector(HiddenChatView:unlockDidSucceed:)]) {
                [self.delegate HiddenChatView:self unlockDidSucceed:YES];
            }
            
            // hide hidden chat pull down view - animated
            if ([self.delegate respondsToSelector:@selector(HiddenChatView:closeWithAnimation:)]) {
                [self.delegate HiddenChatView:self closeWithAnimation:YES];
            }
        }
        else {
            [self showMessage:NSLocalizedString(@"PINs do not match", @"HiddenChat - text: user entered incorrect PIN number")];
            [self clearPINShowError:YES animated:YES];
            
            self.performTimer = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(setStatusChangePIN) userInfo:nil repeats:NO];
        }
    }
    // Unlock before Change PIN
    //
    else if (self.viewStatus == kHCViewStatusChangePINUnlockFirst) {
        if ([pinString isEqualToString:pin]) {
            // unlock
            [[MPSettingCenter sharedMPSettingCenter] lockHiddenChat:NO];
            [self clearPINShowError:NO animated:YES];
            self.performTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(setStatusChangePINEnter) userInfo:nil repeats:NO];
        }
        else {
            [self showMessage:NSLocalizedString(@"Incorrect PIN entered", @"HiddenChat - text: user entered incorrect PIN number")];
            [self clearPINShowError:YES animated:YES];
            self.performTimer = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(setStatusChangePIN) userInfo:nil repeats:NO];
        }
    }
}

#pragma mark - Lock HC Now

/*!
 @abstract Shows Enabled Hidden Chat View
 
 
- (void) showEnableView {
    UIView *enableView = [self.containerView viewWithTag:ENABLE_VIEW_TAG];
    enableView.alpha = 1.0;
}*/


- (void) removeLockNowViewFromSuperview {
    
    UIView *lockView = [self.containerView viewWithTag:LOCKNOW_TAG];
    [lockView removeFromSuperview];
    
}

/*!
 @abstract Removes Lock Now View
 
 Use:
 - call when lock button is pushed
 
 */
- (void) removeLockNowView {
    //UIView *lockView = [self.containerView viewWithTag:LOCKNOW_TAG];
    
    // remove the view after a delay
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(removeLockNowViewFromSuperview) userInfo:nil repeats:NO];
    
    //Animation seems to happen immediately - this may be caused by nesting & interference with other animations
    /* 
    [UIView animateWithDuration:0.5 delay:0.5 options:UIViewAnimationCurveEaseIn 
                     animations:^{
                         lockView.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                         if (finished){
                             [lockView removeFromSuperview];
                         }
                     }];*/
}


/*!
 @abstract Adds Lock Now View
 
 */
- (void) addLockNowView {
    
    UIView *lockView = [self.containerView viewWithTag:LOCKNOW_TAG];

    // add view if it does not exists already
    if (!lockView) {
        // add background
        //
        UIImageView *backView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hidden_lock.png"]];
        backView.frame = CGRectMake(0.0f, 0.0f, 320.0f, kHCHeightLockNow);
        backView.userInteractionEnabled = YES;
        backView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        backView.tag = LOCKNOW_TAG;
        [self.containerView addSubview:backView];
        
        // add enable button
        //
        UIButton *lockButton = [[UIButton alloc] initWithFrame:CGRectMake(105.0, 10.0, 140.0, 34.0)];
        [AppUtility configButton:lockButton context:kAUButtonTypeOrange3];
        [lockButton setTitle:NSLocalizedString(@"Lock Hidden Chat Now", @"HiddenChat - button: locks hidden chat after unlocking") forState:UIControlStateNormal];
        [lockButton addTarget:self action:@selector(pressLockNow:) forControlEvents:UIControlEventTouchUpInside];
        [backView addSubview:lockButton];
        [lockButton release];
        
        // hide at first
        [backView release];
    }
   
}


/*!
 @abstract Locks HC
 
 */
- (void) pressLockNow:(id)sender {
    
    // inform delegate that we have locked view
    // - reload chats to hide hidden chats again
    //
    [[MPSettingCenter sharedMPSettingCenter] lockHiddenChat:YES];
    if ([self.delegate respondsToSelector:@selector(HiddenChatView:lockDidSucceed:animated:)]) {
        [self.delegate HiddenChatView:self lockDidSucceed:YES animated:YES];
    }
    
    // remove lock view
    [self removeLockNowView];
    
    // hide hidden chat pull down view - animated
    if ([self.delegate respondsToSelector:@selector(HiddenChatView:closeWithAnimation:)]) {
        [self.delegate HiddenChatView:self closeWithAnimation:YES];
    }   
}


/*!
 @abstract Locks HC without animation
 
 */
- (void) pressLockNowNoAnimation:(id)sender {
    
    // inform delegate that we have locked view
    // - reload chats to hide hidden chats again
    //
    [[MPSettingCenter sharedMPSettingCenter] lockHiddenChat:YES];
    if ([self.delegate respondsToSelector:@selector(HiddenChatView:lockDidSucceed:animated:)]) {
        [self.delegate HiddenChatView:self lockDidSucceed:YES animated:NO];
    }
    
    // remove lock view
    [self removeLockNowView];
    
    // hide hidden chat pull down view - animated
    if ([self.delegate respondsToSelector:@selector(HiddenChatView:closeWithAnimation:)]) {
        [self.delegate HiddenChatView:self closeWithAnimation:NO];
    }   
}


#pragma mark - Enable HC


#define kEnableStartX 125.0

/*!
 @abstract Shows Enabled Hidden Chat View
 
 */
- (void) showEnableView {
    UIView *enableView = [self.containerView viewWithTag:ENABLE_VIEW_TAG];
    enableView.alpha = 1.0;
}

/*!
 @abstract Removes Enabled Hidden Chat View
 
 */
- (void) removeEnableView {
    UIView *enableView = [self.containerView viewWithTag:ENABLE_VIEW_TAG];

    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationCurveEaseIn 
                     animations:^{
                         enableView.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                         if (finished){
                             [enableView removeFromSuperview];
                         }
                     }];
}


/*!
 @abstract Adds Enabled Hidden Chat View
 
 */
- (void) addEnableView {
    
    // add background
    //
    UIImageView *backView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hidden_enable.png"]];
    backView.frame = CGRectMake(0.0f, 0.0f+kHCHeightWallExtra, 320.0f, 145.0f);
    backView.userInteractionEnabled = YES;
    backView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    backView.tag = ENABLE_VIEW_TAG;
    [self.containerView addSubview:backView];
    
    // add title label
    //
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kEnableStartX, 20.0, 170.0, 17.0)];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldSmall];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = NSLocalizedString(@"Enable Hidden Chat?", @"HiddenChat - title: view that allows users to enable hidden chat");
    [backView addSubview:titleLabel];
    [titleLabel release];
    
    // add description label
    //
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(kEnableStartX, 40.0, 170.0, 45.0)];
    [AppUtility configLabel:descriptionLabel context:kAULabelTypeWhiteMicro];
    descriptionLabel.numberOfLines = 4;
    descriptionLabel.backgroundColor = [UIColor clearColor];
    descriptionLabel.text = NSLocalizedString(@"Hide private chats from the Chat List. Select chats to hide in the chat room's settings.", @"HiddenChat - text: explain hidden chat");
    [backView addSubview:descriptionLabel];
    [descriptionLabel release];
    
    // add enable button
    //
    UIButton *enableButton = [[UIButton alloc] initWithFrame:CGRectMake(kEnableStartX, 100.0, 63.0, 32.0)];
    [AppUtility configButton:enableButton context:kAUButtonTypeOrange3];
    [enableButton setTitle:NSLocalizedString(@"Enable", @"HiddenChat - button: enable hidden chat") forState:UIControlStateNormal];
    [enableButton addTarget:self action:@selector(pressEnable:) forControlEvents:UIControlEventTouchUpInside];
    [backView addSubview:enableButton];
    [enableButton release];
    
    // add not now button
    //
    UIButton *notNowButton = [[UIButton alloc] initWithFrame:CGRectMake(199.0, 100.0, 63.0, 32.0)];
    [AppUtility configButton:notNowButton context:kAUButtonTypeSilver];
    [notNowButton setTitle:NSLocalizedString(@"Not Now", @"HiddenChat - button: ignore enable hidden chat") forState:UIControlStateNormal];
    [notNowButton addTarget:self action:@selector(pressNotNow:) forControlEvents:UIControlEventTouchUpInside];
    [backView addSubview:notNowButton];
    [notNowButton release];
    
    // hide at first
    backView.alpha = 0.0;
    [backView release];
    
}


/*!
 @abstract User Pressed Enable - Show Set PIN view
 
 */
- (void) pressEnable:(id)sender {
    
    [self removeEnableView];
    [self showSafeAnimated:YES];
    [self setStatus:kHCViewStatusChangePIN];
    
}


/*!
 @abstract User Pressed Enable - Show Set PIN view
 
 */
- (void) pressNotNow:(id)sender {
    
    // hide hidden chat pull down view - animated
    if ([self.delegate respondsToSelector:@selector(HiddenChatView:closeWithAnimation:)]) {
        [self.delegate HiddenChatView:self closeWithAnimation:YES];
    }   
    
    [self removeEnableView];
    
}


#pragma mark - Wall Frame and General Methods

/*!
 @abstract Reset view to initial state
 
 - frame is showing
 - container only shows wall and lined with bottom
 
 */
- (void) closeAndReset {
    
    // stop pending method executions
    //
    [self.performTimer invalidate];
    
    NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
    BOOL isLocked = [[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];
    
    [self clearPINShowError:NO animated:YES];
    
    // clear temp PIN
    self.tempNewPIN = nil;
    
    // clear messages
    [self showMessage:nil];
    
    // dismiss keyboard
    self.hiddenTextField.text = @"";
    [self.hiddenTextField resignFirstResponder];
    
    // make sure enable view is also dismissed too
    [self removeEnableView];
    
    // If locked or HC not enabled
    // - show wall and frame 
    if (isLocked || !pin ) {
        
        [self removeLockNowView];
        // show only if frame is hidden
        //
        if (self.frameButton.hidden) {
            self.frameButton.alpha = 0.0;
            self.frameButton.hidden = NO;
            
            [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationCurveEaseIn 
                             animations:^{
                                 self.frameButton.alpha = 1.0;
                                 self.containerView.frame = CGRectMake(0.0f, self.frame.size.height - kHCHeightWallFull, 320.0f, kHCHeightWallFull);
                             }
                             completion:^(BOOL finished){
                                 if (finished){
                                     // nothing to do
                                 }
                             }];
        }
        // if frame is already showing, just make sure container is right size
        else {
            self.containerView.frame = CGRectMake(0.0f, self.frame.size.height - kHCHeightWallFull, 320.0f, kHCHeightWallFull);
        }
    }
    // if unlocked, show unlock view
    else {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationCurveEaseIn 
                         animations:^{
                             self.containerView.frame = CGRectMake(0.0f, self.frame.size.height - kHCHeightLockNow, 320.0f, kHCHeightLockNow);
                         }
                         completion:^(BOOL finished){
                             if (finished){
                                 [self hideSafe];
                                 self.frameButton.hidden = YES;
                                 [self addLockNowView];
                             }
                         }];
    }
    
}


/*!
 @abstract Hides frame
 - animate it down the screen
 */
- (void) hideFrame:(id)sender animated:(BOOL)animated {
    static BOOL hideStarted = NO;
    
    // if process started or already hidden
    // - do nothing
    if (hideStarted || self.frameButton.hidden) {
        return;
    }
    
    hideStarted = YES;
    
    UIView *frameView = self.frameButton;
    
    CGRect originalFrame = frameView.frame;
    CGRect newFrame = CGRectOffset(originalFrame, 0.0, +500.0);
    
    // is PIN set?
    NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
    
    // if HC enabled
    // - prep unlock view
    if (pin) {
        [self showSafeAnimated:NO];
    }
    // if HC not enabled yet
    // - prep enable view
    else {
        [self hideSafe];
        [self addEnableView];
    }
    
    // animated only if user taps in integrated view
    //
    if (animated) {
        [UIView animateWithDuration:0.6 delay:0.0 options:UIViewAnimationCurveEaseIn 
                         animations:^{
                             frameView.frame = newFrame;
                             if (pin && self.viewStatus != kHCViewStatusUnlockPIN) {
                                 [self setStatus:kHCViewStatusUnlockPIN];
                             }
                             else {
                                 [self showEnableView];
                             }
                         }
                         completion:^(BOOL finished){
                             if (finished){
                                 frameView.hidden = YES;
                                 frameView.frame = originalFrame;
                                 hideStarted = NO;
                             }
                         }];
    }
    // not animated
    // - just simply hide it
    // - safe should show for unlocking, changing, setting PIN
    else {
        [self showSafeAnimated:NO];
        frameView.hidden = YES;
        hideStarted = NO;
    }
}

/*!
 @abstract Hides frame
 - animate it down the screen
 */
- (void) hideFrame:(id)sender {
    
    [self hideFrame:sender animated:YES];
}


/*!
 @abstract Updates number of hidden chat count in frame
 */
- (void) updateHiddenChatBadge {
    
    NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];

    // only if HC is enabled
    if (pin) {
        NSUInteger totalUnreadChats = 0;
        
        NSArray *hiddenChats = [CDChat chatsIsHidden:YES];
        for (CDChat *iChat in hiddenChats) {
            if ([iChat numberOfUnreadMessages] > 0) {
                totalUnreadChats++;
                if (totalUnreadChats > 1)
                    break;
            }
        }   
        
        UIView *bear1View = [self.frameButton viewWithTag:BEAR1_TAG];
        UIView *bear2View = [self.frameButton viewWithTag:BEAR2_TAG];
        
        if (totalUnreadChats == 1) {
            bear1View.hidden = NO;
            bear2View.hidden = YES;
        }
        else if (totalUnreadChats >= 2) {
            bear1View.hidden = YES;
            bear2View.hidden = NO;
        }
        else {
            bear1View.hidden = YES;
            bear2View.hidden = YES;
        }
    }

}



#pragma mark - Get Heights and Thresholds

// point after which view will open all the way
//
#define kHCLockedThreshold      -70.0f
#define kHCUnLockedThreshold	-70.0f


/*!
 @abstract Gets threshold to determine when to open this view completely
 
 */
- (CGFloat) openViewThreshold {
    
    NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
    BOOL isLocked = [[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];

    CGFloat threshold = 0.0;
    if (isLocked || !pin) {
        threshold = kHCHeightWall * -0.7;
    }
    else {
        threshold = kHCHeightLockNow * -0.85;
    }
    return threshold;
}


/*!
 @abstract Gets current view height
 
 */
- (CGFloat) openViewHeight {
    
    NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
    BOOL isLocked = [[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];
    
    if (isLocked || !pin) {
        return kHCHeightWall;
    }
    else {
        return kHCHeightLockNow;
    }
}




#pragma mark - External Methods


- (void)flipImageAnimated:(BOOL)animated
{
    /*
     [UIView beginAnimations:nil context:NULL];
     [UIView setAnimationDuration:animated ? .18 : 0.0];
     [arrowImage layer].transform = isFlipped ?
     CATransform3DMakeRotation(M_PI, 0.0f, 0.0f, 1.0f) :
     CATransform3DMakeRotation(M_PI * 2, 0.0f, 0.0f, 1.0f);
     [UIView commitAnimations];
     */
	isFlipped = !isFlipped;
}

/**
 Moves image according to the position
 
 position	0.0 start position	1.0 end position
 */
- (void) moveImage:(CGFloat)position animated:(BOOL)animated{
    /*
     DDLogVerbose(@"RTHV-MI: position - %f", position);
     [self.arrowImage rotateViews:position];
     [self.speakingLabel updatePosition:position animate:animated];
     */
}


- (void)setLastUpdatedDate:(NSDate *)newDate
{
	/*
     if (newDate)
     {
     if (lastUpdatedDate != newDate)
     {
     [lastUpdatedDate release];
     }
     
     lastUpdatedDate = [newDate retain];
     
     NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
     [formatter setDateStyle:NSDateFormatterShortStyle];
     [formatter setTimeStyle:NSDateFormatterShortStyle];
     lastUpdatedLabel.text = [NSString stringWithFormat:
     @"Last Updated: %@", [formatter stringFromDate:lastUpdatedDate]];
     [formatter release];
     }
     else
     {
     lastUpdatedDate = nil;
     lastUpdatedLabel.text = @"Last Updated: Never";
     }
	 */
}


/*!
 @abstract Sets the state for this view
 
 */
- (void)setStatus:(HCViewStatus)newStatus
{
    HCViewStatus oldStatus = self.viewStatus;
	self.viewStatus = newStatus;
	
	switch (newStatus) {
        
        case kHCViewStatusClose:
            // always close in case state was modifed else where and we need to update
            [self closeAndReset];
            /*if (oldStatus != kHCViewStatusClose) {
                [self closeAndReset];
            }*/
            break;
            
        case kHCViewStatusChangePIN:
            if (oldStatus != kHCViewStatusChangePIN && 
                oldStatus != kHCViewStatusChangePINConfirm &&
                oldStatus != kHCViewStatusChangePINUnlockFirst) {
                // show PIN view & hide frame
                [self hideFrame:nil animated:NO];
                [self showPINDisplay];
            }
            [self startChangePIN];
            break;
            
        case kHCViewStatusChangePINEnter:
            [self showMessage:NSLocalizedString(@"Enter new PIN", @"HiddenChat - text: enter new PIN to change to")];
            break;
            
        case kHCViewStatusChangePINConfirm:
            [self showMessage:NSLocalizedString(@"Enter PIN again to confirm", @"HiddenChat - text: enter new PIN again to verify PIN")];
            break;
            
        case kHCViewStatusUnlockPIN:
            // make sure frame is not seen
            [self hideFrame:nil animated:NO];
            [self showPINDisplay];
            [self startUnlock];
            break;
        
            
        case kTableStatusNormal:
            [self closeAndReset];
            break;
        case kTableStatusReleaseToReload:
			//[self.speakingLabel showEnd];
			break;
		default:
			break;
	}
	
}

/*!
 @abstract Sets state to ChangePIN
 
 Use:
 - when PIN entry fails
 
 */
- (void)setStatusChangePIN {
    [self setStatus:kHCViewStatusChangePIN];
}

/*!
 @abstract Sets state to ChangePINEnter
 
 Use:
 - call after current PIN is entered, so safe to change PIN
 
 */
- (void)setStatusChangePINEnter {
    [self setStatus:kHCViewStatusChangePINEnter];
}


/*!
 @abstract Sets the state for this view
 
 Use:
 - allow object to be passed to use performSelector
 
 */
- (void)setStatusNumber:(NSNumber *)statusNumber {
    
    HCViewStatus statusValue = [statusNumber intValue];
    [self setStatus:statusValue];

}



/*!
 @abstract Should we show the "Loading" status?
 
 */
- (void)toggleActivityView:(BOOL)isON
{
	// not loading: go to starting position
	//
	if (!isON)
	{
		//[self.arrowImage stopAnimation];
		//[self.speakingLabel reset];
	}
	// loading: start flapping wings
	//
	else
	{
		//[self.speakingLabel showEnd];
		//[self.arrowImage startAnimation];
		[self setStatus:kTableStatusLoading];
	}
}


/* 
 //old - show activitiy indicator and hides the arrow image
 //
 - (void)toggleActivityView:(BOOL)isON
 {
 if (!isON)
 {
 [activityView stopAnimating];
 arrowImage.hidden = NO;
 }
 else
 {
 [activityView startAnimating];
 arrowImage.hidden = YES;
 [self setStatus:kTableStatusLoading];
 }
 }*/



#pragma mark - TextViewDelegate


/*!
 @abstract called when hidden textfield is modified
 
 */
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {  
    
    // don't allow PIN to be entered
    if (!self.allowEnterPIN) {
        return NO;
    }
    
    BOOL shouldChange = NO;
    
    // the preview string itself
    NSString *previewString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    // number of characters
    NSInteger previewCharCount = [previewString length]; // [textField.text length] + [string length] - range.length;
    

    NSString *eString = nil;
    NSString *fString = nil;
    NSString *gString = nil;
    NSString *hString = nil;

    for (int i=0; i < previewCharCount; i++) {
        
        switch (i) {
            case 0:
                eString = [previewString substringWithRange:NSMakeRange(i, 1)];
                break;
                
            case 1:
                fString = [previewString substringWithRange:NSMakeRange(i, 1)];
                break;
                
            case 2:
                gString = [previewString substringWithRange:NSMakeRange(i, 1)];
                break;
                
            case 3:
                hString = [previewString substringWithRange:NSMakeRange(i, 1)];
                break;
                
            default:
                break;
        }
    }
    
    self.eLabel.text = eString?@"●":@"";
    self.fLabel.text = fString?@"●":@"";
    self.gLabel.text = gString?@"●":@"";
    self.hLabel.text = hString?@"●":@"";
    
    // don't update the 4th string otherwise it will be written to the textfield after we clear it 
    // in processPIN
    //
    if (previewCharCount < 4) {
        shouldChange = YES;
    }
    
    if (previewCharCount == 4) {
        [self processPIN:previewString];
    }
    
    return shouldChange;
}







@end