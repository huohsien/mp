//
//  DialogMessageCellController.m
//  mp
//
//  Created by Min Tsai on 3/7/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "DialogMessageCellController.h"
#import "MPFoundation.h"
#import "CDMessage.h"
#import "CDChat.h"
#import "CDContact.h"
#import "CDResource.h"
#import "UIImage+TKUtilities.h"
#import "TextEmoticonView.h"
#import "StickerButton.h"
#import "AddFriendAlertView.h"
#import "MPChatManager.h"


NSString* const kDMTextCell = @"kDMTextCell";
NSString* const kDMStickerCell = @"kDMStickerCell";
NSString* const kDMImageCell = @"kDMImageCell";
NSString* const kDMLetterCell = @"kDMLetterCell";
NSString* const kDMLocationCell = @"kDMLocationCell";

NSTimeInterval const kDMLongPressInterval = 0.7;


CGFloat const kDMChatFreshSeconds = 60.0;

CGFloat const kDMMarginBase = 5.0;
CGFloat const kDMMarginAlert = 20.0;
CGFloat const kDMMarginShowHead = 17.0;


CGFloat const kDMHeadSize = 35.0;
CGFloat const kDMAlertSize = 32.0;  //22.0;

CGFloat const kDMBubbleMinHeight = 32.0;
CGFloat const kDMBubbleMinWidth = 40.0;

CGFloat const kDMBubblePaddingTail = 15.0;
CGFloat const kDMBubblePaddingHead = 10.0;
CGFloat const kDMBubblePaddingVertical = 7.0;
CGFloat const kDMBubblePaddingPhoto = 3.0;
CGFloat const kDMBubblePaddingPhotoBottom = 7.0; // bottom has 4 additional shawdow 


CGFloat const kDMBubbleWidthMaxMe = 200.0;
CGFloat const kDMBubbleWidthMaxOther = 160.0;




CGFloat const kDMLabelHeight = 13.0;
CGFloat const kDMLabelWidth = 65.0; 
CGFloat const kDMLabelMargin = 3.0;

CGFloat const kDMProgressHeight = 13.0;
CGFloat const kDMProgressWidth = 50.0;
CGFloat const kDMProgressMarginHead = 10.0;
CGFloat const kDMProgressMarginTail = 13.0;
CGFloat const kDMProgressMarginBottom = 7.0;


CGFloat const kDMJoinLeftWidthMax = 280.0;
CGFloat const kDMJoinLeftWidthMin = 150.0;

CGFloat const kDMPreviewImageWidthMax = 210.0;



@implementation DialogMessageCellController

@synthesize delegate;
@synthesize cdMessage;
@synthesize previousMessage;

@synthesize currentProgress;
@synthesize fileManager;
@synthesize shouldStartAnimation;
@synthesize textEmoticonView;


/*!
 @abstract initialized cell controller with related CDMessage
 
 */
- (id)initWithMessage:(CDMessage *)message previousMessage:(CDMessage *)prevMessage
{
	self = [super init];
	if (self != nil)
	{
        
        self.cdMessage = message;
        self.previousMessage = prevMessage;
        self.shouldStartAnimation = NO;
        

        // use notification since one alert view can broadcast to several message cells for headshot updates
        //
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateHeadView:) name:MP_ADDFRIENDALERT_CONTACT_CHANGED_NOTIFICATION object:nil];
        
        // use notification since one alert view can broadcast to several message cells for headshot updates
        //
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSentTimeout:) name:MP_MESSAGECENTER_SENT_TIMEOUT_NOTIFICATION object:nil];
        
        
	}
	return self;
}

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    fileManager.delegate = nil;
    
    [cdMessage release];
    [previousMessage release];
    
    [fileManager release];
    [textEmoticonView release];
    
    [super dealloc];
}


#pragma mark - Create Bubbles

#define HEADBASE_TAG        12001
#define HEADIMAGE_TAG       12002
#define HEADPLUS_TAG        12003
#define NAME_TAG            12004
#define STATUS_TAG          12005
#define TIME_TAG            12006
#define PROGRESS_TAG        12007
#define ALERT_TAG           12008

#define BUBBLE_TAG          12009
#define BUBBLE_TEXT_TAG     12010
#define BUBBLE_IMAGE_TAG    12011
#define DOWN_ARROW_TAG      12012

#define FRAME_UP_LEFT_TAG       12013
#define FRAME_UP_RIGHT_TAG      12014
#define FRAME_DOWN_LEFT_TAG     12015
#define FRAME_DOWN_RIGHT_TAG    12016






/*!
 @abstract should show headshot for this message
 
 Check if message is from same person: N->show headshot
 Check if message is within XX seconds: > X sec -> show headshot
 
 For chats from same person that are close together, don't show headshots
 */
- (BOOL) shouldShowHeadShot {
    
    // if not previous message
    // - or if blank group control message
    //
    if (!self.previousMessage || [self.previousMessage isGroupControlMessage])
    {
        return YES;
    }
    
    BOOL shouldShow = YES;
    
    NSString *thisID = self.cdMessage.contactFrom.userID;
    NSString *previousID = self.previousMessage.contactFrom.userID;
    
    // same person, check time
    if ([thisID isEqualToString:previousID]) {
        CGFloat thisTime = [self.cdMessage.sentDate timeIntervalSince1970];
        CGFloat previousTime = [self.previousMessage.sentDate timeIntervalSince1970];
        if ((thisTime - previousTime) < kDMChatFreshSeconds) {
            shouldShow = NO;
        }
    }
    // diff person, YES
    return shouldShow;
}



/*!
 @abstract Creates text bubble button
 */
- (UIButton *) textBubbleButton {
    
    TextEmoticonView *textView = [[TextEmoticonView alloc] initWithFrame:CGRectZero];
    textView.backgroundColor = [UIColor clearColor];
    textView.autoresizingMask = UIViewAutoresizingNone;
    textView.userInteractionEnabled = YES;              // want data detection!
    textView.tag = BUBBLE_TEXT_TAG;

    UIButton *bubble = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
    bubble.backgroundColor = [UIColor clearColor];
    [bubble addSubview:textView];
    [textView release];
    
    return bubble;
}

/*!
 @abstract Creates image based bubble button
 
 - bottom bubble
 - image view
 - arrow image
 
 */
- (UIButton *) imageBubbleButton {
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    imageView.backgroundColor = [UIColor clearColor];
    imageView.tag = BUBBLE_IMAGE_TAG;
    
    UIButton *bubble = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
    bubble.backgroundColor = [UIColor clearColor];
    [bubble addSubview:imageView];
    [imageView release];
    
    /*UIImageView *arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_dialog_icon_dl_nor.png"]];
    arrowImageView.tag = DOWN_ARROW_TAG;
    [bubble addSubview:arrowImageView];
    [arrowImageView release];*/
    
    UIImageView *frameULView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_dialog_icon_dl_left_up.png"]];
    frameULView.tag = FRAME_UP_LEFT_TAG;
    [bubble addSubview:frameULView];
    [frameULView release];
    
    UIImageView *frameURView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_dialog_icon_dl_right_up.png"]];
    frameURView.tag = FRAME_UP_RIGHT_TAG;
    [bubble addSubview:frameURView];
    [frameURView release];
    
    UIImageView *frameDLView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_dialog_icon_dl_left_down.png"]];
    frameDLView.tag = FRAME_DOWN_LEFT_TAG;
    [bubble addSubview:frameDLView];
    [frameDLView release];
    
    UIImageView *frameDRView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_dialog_icon_dl_right_down.png"]];
    frameDRView.tag = FRAME_DOWN_RIGHT_TAG;
    [bubble addSubview:frameDRView];
    [frameDRView release];
    
    return bubble;
}


/*!
 @abstract Create letter bubble button
 
 - single bubble
 
 */
- (UIButton *) letterBubbleButton {
    
    UIButton *bubble = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
    bubble.backgroundColor = [UIColor clearColor];
    bubble.enabled = YES;
    // NEVER set image directly - use setImage: instead
    bubble.imageView.animationDuration = kDMLongPressInterval;
    bubble.imageView.animationRepeatCount = 1;
    bubble.imageView.animationImages = [NSArray arrayWithObjects:
                                        [UIImage imageNamed:@"letter_ani_01.png"],
                                        [UIImage imageNamed:@"letter_ani_02.png"],
                                        [UIImage imageNamed:@"letter_ani_03.png"],
                                        [UIImage imageNamed:@"letter_ani_04.png"],
                                        [UIImage imageNamed:@"letter_ani_05.png"],
                                        [UIImage imageNamed:@"letter_ani_06.png"],
                                        [UIImage imageNamed:@"letter_ani_07.png"],
                                        nil];
    return bubble;
}


/*!
 @abstract Create sticker bubble button
 
 - single bubble
 
 */
- (UIButton *) stickerBubbleButton {
    
    // make some randown frame
    StickerButton *stickerButton = [[[StickerButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 10.0) resource:nil] autorelease];
    stickerButton.backgroundColor = [UIColor clearColor];
    
    return stickerButton;

}



/*!
 @abstract Creates bubble button
 */
- (UIButton *) bubbleButton {
    
    UIButton *bubbleButton = nil;
    
    CDMessageType mType = [self.cdMessage.type intValue];
    switch (mType) {
        case kCDMessageTypeStickerGroup:
        case kCDMessageTypeSticker:
            bubbleButton = [self stickerBubbleButton];
            break;
            
        case kCDMessageTypeImage:
            bubbleButton =  [self imageBubbleButton];
            break;
            
        case kCDMessageTypeLetter:
            bubbleButton =  [self letterBubbleButton];
            break;
            
        case kCDMessageTypeLocation:
            bubbleButton =  [self imageBubbleButton];
            break;
            
        default:
            bubbleButton =  [self textBubbleButton];
            break;
    }
    
    // add long tap recognizer
    
    UILongPressGestureRecognizer *pressRecognizer = [[UILongPressGestureRecognizer alloc]
                                                     initWithTarget:self action:@selector(longPressBubble:)];
    pressRecognizer.numberOfTouchesRequired = 1;
    pressRecognizer.minimumPressDuration = kDMLongPressInterval;
    [bubbleButton addGestureRecognizer:pressRecognizer];
    [pressRecognizer release];
    
    return bubbleButton;
}

#pragma mark - Bubble Configuration


/*!
 @abstract Text view max frame given current message configuration
 
 Use:
 - when creating text view
 - when calc row height
 
 */
- (CGRect) textMaxRectForIsRightSide:(BOOL)isRightSide dialogWidth:(CGFloat)dialogWidth {
    
    // TODO: change for landscape width
    
    CGRect maxRect = CGRectZero;
    
    CGFloat vertOffset = 0.0;
    
    if (isRightSide) {
        maxRect = CGRectMake(kDMBubblePaddingHead, kDMBubblePaddingVertical+vertOffset, kDMBubbleWidthMaxMe, 15000.0);
    }
    else {
        maxRect = CGRectMake(kDMBubblePaddingTail, kDMBubblePaddingVertical+vertOffset, kDMBubbleWidthMaxOther, 15000.0);
    }
    
    return maxRect;
}


/*!
 @abstract Configures text bubble button
 */
- (void) configureTextBubble:(UIButton *)bubble showHead:(BOOL)showHead isRightSide:(BOOL)isRightSide dialogWidth:(CGFloat)dialogWidth {
    
    TextEmoticonView *textView = (TextEmoticonView *)[bubble viewWithTag:BUBBLE_TEXT_TAG];

    UIFont *bubbleFont = nil;
    if ([[MPSettingCenter sharedMPSettingCenter] isFontSizeLarge]) {
        bubbleFont = [AppUtility fontPreferenceWithContext:kAUFontSystemStandardPlus];
    }
    else {
        bubbleFont = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
    }
    textView.font = bubbleFont;
    
    
    // create text view
    CGRect maxRect = [self textMaxRectForIsRightSide:isRightSide dialogWidth:dialogWidth];
    textView.frame = maxRect;
    [textView setText:self.cdMessage.text enableDataDetection:YES];
    [textView sizeToFit];
    
    /*CGRect fittedRect = textView.frame;
    if (fittedRect.size.height < 40.0) {
        fittedRect.size.height = 40.0;
    }
    fittedRect.size.width += 20.0;
    textView.frame = fittedRect;*/
    
    //textView.backgroundColor = [UIColor orangeColor];
    CGSize expectedLabelSize = textView.frame.size;
    //CGRect textFrame = textView.frame;
    
    
    CGFloat bubbleWidth = expectedLabelSize.width + kDMBubblePaddingHead + kDMBubblePaddingTail;
    CGFloat bubbleHeight = expectedLabelSize.height + kDMBubblePaddingVertical*2.0;
    // don't go beyond min and max size, otherwise bubble will deform
    if (bubbleHeight < kDMBubbleMinHeight) {
        bubbleHeight = kDMBubbleMinHeight;

        // if text is smaller than center text vertically in bubble
        //
        CGRect newTextFrame = textView.frame;
        newTextFrame.origin.y = (32.0 - expectedLabelSize.height)/2.0;
        textView.frame = newTextFrame;
    }
    if (bubbleWidth < kDMBubbleMinWidth) {
        bubbleWidth = kDMBubbleMinWidth;
    }
    
    // adjust vertical height for non retina displays
    // - needs to be a little higer
    // - removed since text height increase
    //
    /*CGFloat scale = [[UIScreen mainScreen] scale];
    if (scale == 1.0) {
        CGRect newTextFrame = textView.frame;
        newTextFrame.origin.y = newTextFrame.origin.y - 1.0;
        textView.frame = newTextFrame;
    }*/
    
    // my own text message!
    if (isRightSide) {
                
        if (bubbleWidth > 225.0) {
            bubbleWidth = 225.0;
        }
        CGFloat bubbleStartX = dialogWidth - kDMMarginBase - bubbleWidth;
        
        UIImage *myImage = [Utility resizableImage:[UIImage imageNamed:@"chat_icon_bubble_wh.png"] leftCapWidth:15.0 rightCapWidth:24.0 topCapHeight:15.0 bottomCapHeight:15.0];
        
        bubble.frame = CGRectMake(bubbleStartX, kDMMarginBase, bubbleWidth, bubbleHeight);
        [bubble setBackgroundImage:myImage forState:UIControlStateNormal];
        
    }
    // text message from others!
    else {
                
        if (bubbleWidth > 185.0) {
            bubbleWidth = 185.0;
        }
        CGFloat bubbleStartX = kDMMarginBase*2 + kDMHeadSize;
        CGFloat bubbleStartY = showHead?kDMMarginShowHead:kDMMarginBase;
        
        UIImage *myImage = [Utility resizableImage:[UIImage imageNamed:@"chat_icon_bubble_y.png"] leftCapWidth:22.0 rightCapWidth:17.0 topCapHeight:15.0 bottomCapHeight:15.0];
        
        bubble.frame = CGRectMake(bubbleStartX, bubbleStartY, bubbleWidth, bubbleHeight);
        [bubble setBackgroundImage:myImage forState:UIControlStateNormal];
    }
    
    // add tap
    [bubble removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents]; 
    [bubble addTarget:self action:@selector(pressTextBubble:) forControlEvents:UIControlEventTouchUpInside];
    
}

#define kArrowSize          27.0
#define kArrowMargin        10.0

#define kFrameSize          13.0

/*!
 @abstract Configures image bubble button
 */
- (void) configureImageBubble:(UIButton *)bubble showHead:(BOOL)showHead isRightSide:(BOOL)isRightSide dialogWidth:(CGFloat)dialogWidth {
    
    UIImageView *imageView = (UIImageView *)[bubble viewWithTag:BUBBLE_IMAGE_TAG];
    //UIImageView *arrowView = (UIImageView *)[bubble viewWithTag:DOWN_ARROW_TAG];
    
    UIImageView *frameULView = (UIImageView *)[bubble viewWithTag:FRAME_UP_LEFT_TAG];
    UIImageView *frameURView = (UIImageView *)[bubble viewWithTag:FRAME_UP_RIGHT_TAG];
    UIImageView *frameDLView = (UIImageView *)[bubble viewWithTag:FRAME_DOWN_LEFT_TAG];
    UIImageView *frameDRView = (UIImageView *)[bubble viewWithTag:FRAME_DOWN_RIGHT_TAG];
    
    // find the right size for this bubble
    UIImage *thisImage = self.cdMessage.previewImage;
    CGSize thisSize = [thisImage size];
    
    // resize location messages
    if ([self.cdMessage.type intValue] == kCDMessageTypeLocation) {
        thisSize = CGSizeMake(170.0, 160.0);
    }
    
    CGSize newImageSize = thisSize;
    
    // if image is too large
    //
    if (thisSize.width > kDMPreviewImageWidthMax) {
        // new height scaled proportionally
        //
        CGFloat newHeight = thisSize.height * kDMPreviewImageWidthMax/thisSize.width;
        newImageSize = CGSizeMake(kDMPreviewImageWidthMax, newHeight);
    }
        
    CGFloat bubbleWidth = newImageSize.width+kDMBubblePaddingPhoto*2.0;
    CGFloat bubbleStartX = isRightSide?(dialogWidth-kDMMarginBase-bubbleWidth):(kDMMarginBase*2+kDMHeadSize);
    CGFloat bubbleStartY = showHead?kDMMarginShowHead:kDMMarginBase;
    CGFloat bubbleHeight = newImageSize.height+kDMBubblePaddingPhoto+kDMBubblePaddingPhotoBottom;
    bubble.frame = CGRectMake(bubbleStartX, bubbleStartY, bubbleWidth, bubbleHeight);
    
    bubble.backgroundColor = [UIColor clearColor];
    [bubble addTarget:self action:@selector(pressImageBubble:) forControlEvents:UIControlEventTouchUpInside];
    
    UIImage *bubbleImage = [Utility resizableImage:[UIImage imageNamed:@"chat_dialog_sendphoto_bubble.png"] leftCapWidth:49.0 rightCapWidth:49.0 topCapHeight:4.0 bottomCapHeight:8.0];
    
    [bubble setBackgroundImage:bubbleImage forState:UIControlStateNormal];
    
    imageView.image = thisImage;
    imageView.frame = CGRectMake(kDMBubblePaddingPhoto, kDMBubblePaddingPhoto, newImageSize.width, newImageSize.height);
    
    /* Old masked bubble
    UIImage *bubbleImage = isRightSide?
                                [Utility resizableImage:[UIImage imageNamed:@"chat_dialog_sendphoto_bubble_wh.png"] leftCapWidth:15.0 rightCapWidth:15.0 topCapHeight:13.0 bottomCapHeight:13.0]:
                                [Utility resizableImage:[UIImage imageNamed:@"chat_dialog_sendphoto_bubble_y.png"] leftCapWidth:15.0 rightCapWidth:15.0 topCapHeight:13.0 bottomCapHeight:13.0];
                                
    [bubble setBackgroundImage:bubbleImage forState:UIControlStateNormal];

    // create mask
    // - same size as image!
    UIImage *maskImage = isRightSide?
    [Utility resizableImage:[UIImage imageNamed:@"chat_dialog_sendphoto_mask2.png"] leftCapWidth:15.0 rightCapWidth:15.0 topCapHeight:13.0 bottomCapHeight:13.0]:
    [Utility resizableImage:[UIImage imageNamed:@"chat_dialog_sendphoto_mask1.png"] leftCapWidth:15.0 rightCapWidth:15.0 topCapHeight:13.0 bottomCapHeight:13.0];
    
    UIImageView *maskView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, thisSize.width, thisSize.height)];
    maskView.image = maskImage;
    UIImage *resizedMaskImage = [UIImage sharpImageWithView:maskView];
    [maskView release];
    
    UIImage *maskedImage = [UIImage maskImage:thisImage withMask:resizedMaskImage];
    
    // acutalImage
    imageView.image = maskedImage;
    imageView.frame = CGRectMake(0.0, 0.0, bubbleWidth, bubbleHeight);
     */

    // add download arrow
    // - only read or delivered
    // - only for image not location types
    //
    CDMessageState state = [self.cdMessage.state intValue];
    if ( (state == kCDMessageStateInRead ||
        state == kCDMessageStateInDelivered) &&
        [self.cdMessage isType:kCDMessageTypeImage] ) {
        // hide arrow image
        // - basically disable this feature for now
        //
        /*arrowView.hidden = NO;
        arrowView.alpha = 1.0;
        arrowView.frame = CGRectMake(bubbleWidth-kArrowSize-kArrowMargin, bubbleHeight-kArrowSize-kArrowMargin, kArrowSize, kArrowSize);
         */
        
        frameULView.hidden = NO;
        frameURView.hidden = NO;
        frameDLView.hidden = NO;
        frameDRView.hidden = NO;

        frameULView.alpha = 1.0;
        frameURView.alpha = 1.0;
        frameDLView.alpha = 1.0;
        frameDRView.alpha = 1.0;
        
        frameULView.frame = CGRectMake(kDMBubblePaddingPhoto, kDMBubblePaddingPhoto, kFrameSize, kFrameSize);
        frameURView.frame = CGRectMake(bubbleWidth-kDMBubblePaddingPhoto-kFrameSize, kDMBubblePaddingPhoto, kFrameSize, kFrameSize);
        frameDLView.frame = CGRectMake(kDMBubblePaddingPhoto, bubbleHeight-kDMBubblePaddingPhotoBottom-kFrameSize, kFrameSize, kFrameSize);
        frameDRView.frame = CGRectMake(bubbleWidth-kDMBubblePaddingPhoto-kFrameSize, bubbleHeight-kDMBubblePaddingPhotoBottom-kFrameSize, kFrameSize, kFrameSize);
        
    }
    else {
        //arrowView.hidden = YES;
        frameULView.hidden = YES;
        frameURView.hidden = YES;
        frameDLView.hidden = YES;
        frameDRView.hidden = YES;
    }
    
    [bubble removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents]; 
    [bubble addTarget:self action:@selector(pressImageBubble:) forControlEvents:UIControlEventTouchUpInside];

    //DDLogVerbose(@"DMCC-cv: config image height:%f state:%@", newImageSize.height, self.cdMessage.state);
}

/*!
 @abstract Get appropriate image for letter message state
 */
- (UIImage *) letterImageForCurrentState {
    
    NSString *sendLetterImageName = @"letter_stk_uploading.png";
    NSInteger messageState = [self.cdMessage.state intValue];
    switch (messageState) {
            
        case kCDMessageStateOutSent:
        case kCDMessageStateOutSentBlocked:
        case kCDMessageStateOutDelivered:
            sendLetterImageName = @"letter_stk_sent.png";
            break;
        case kCDMessageStateOutRead:
            sendLetterImageName = @"letter_stk_read.png";
            break;
        case kCDMessageStateInDelivered:
        case kCDMessageStateInRead:
            sendLetterImageName = @"letter_stk_received1.png";
            break;
        case kCDMessageStateInReadDownloaded:
            sendLetterImageName = @"letter_stk_received2.png";
            break;
        default:
            break;
    }
    
    return [UIImage imageNamed:sendLetterImageName];
}


/*!
 @abstract Configures letter bubble button
 */
- (void) configureLetterBubble:(UIButton *)bubble showHead:(BOOL)showHead isRightSide:(BOOL)isRightSide dialogWidth:(CGFloat)dialogWidth {
    
    // stop animation if it was running before
    [bubble.imageView stopAnimating];
    
    UIImage *bubbleImage = [self letterImageForCurrentState];
    CGSize letterSize = bubbleImage.size;
    
    CGFloat bubbleWidth = letterSize.width;
    CGFloat bubbleStartX = isRightSide?dialogWidth-kDMMarginBase-bubbleWidth:kDMMarginBase*2+kDMHeadSize;
    CGFloat bubbleStartY = showHead?kDMMarginShowHead:kDMMarginBase;
    CGFloat bubbleHeight = letterSize.height;
    
    bubble.frame = CGRectMake(bubbleStartX, bubbleStartY, bubbleWidth, bubbleHeight);
    [bubble.imageView setContentMode:UIViewContentModeRight];
    [bubble setImage:bubbleImage forState:UIControlStateNormal];

    [bubble removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents]; 
    
    [bubble addTarget:self action:@selector(pressLetterBubble:) forControlEvents:UIControlEventTouchUpInside];
    
}


/*!
 @abstract Configures sticker bubble button
 */
- (void) configureStickerBubble:(UIButton *)bubble showHead:(BOOL)showHead isRightSide:(BOOL)isRightSide dialogWidth:(CGFloat)dialogWidth {
    
    StickerButton *stickerButton = (StickerButton *)bubble;
    
    // find the right size for this bubble
    CDResource *stickerResource = self.cdMessage.stickerResource;
    [stickerButton setStickerResource:stickerResource];
        
    CGSize stickerSize = stickerButton.frame.size;
    
    CGFloat bubbleWidth = stickerSize.width;
    CGFloat bubbleStartX = isRightSide?dialogWidth-kDMMarginBase-bubbleWidth:kDMMarginBase*2+kDMHeadSize;
    CGFloat bubbleStartY = showHead?kDMMarginShowHead:kDMMarginBase;
    CGFloat bubbleHeight = stickerSize.height;
    
    stickerButton.frame = CGRectMake(bubbleStartX, bubbleStartY, bubbleWidth, bubbleHeight);
    
    // marked to run animation
    // - run on first display
    if (self.shouldStartAnimation) {
        self.shouldStartAnimation = NO;
        [stickerButton runAnimation];
    }
    
}



/*!
 @abstract Configures bubble button
 */
- (void) configureBubble:(UIButton *)bubble showHead:(BOOL)showHead isRightSide:(BOOL)isRightSide dialogWidth:(CGFloat)dialogWidth {
    
    bubble.autoresizingMask =  isRightSide?UIViewAutoresizingFlexibleLeftMargin:UIViewAutoresizingFlexibleRightMargin| UIViewAutoresizingFlexibleBottomMargin;
    
    CDMessageType mType = [self.cdMessage.type intValue];
    switch (mType) {
        case kCDMessageTypeStickerGroup:
        case kCDMessageTypeSticker:
            [self configureStickerBubble:bubble showHead:showHead isRightSide:isRightSide dialogWidth:dialogWidth];
            break;
            
        case kCDMessageTypeImage:
            [self configureImageBubble:bubble showHead:showHead isRightSide:isRightSide dialogWidth:dialogWidth];
            break;
            
        case kCDMessageTypeLetter:
            [self configureLetterBubble:bubble showHead:showHead isRightSide:isRightSide dialogWidth:dialogWidth];
            break;
            
        case kCDMessageTypeLocation:
            [self configureImageBubble:bubble showHead:showHead isRightSide:isRightSide dialogWidth:dialogWidth];
            break;
            
        default:
            [self configureTextBubble:bubble showHead:showHead isRightSide:isRightSide dialogWidth:dialogWidth];
            break;
    }

    // configure correct target for recognier
    //
    UIGestureRecognizer *recognizer = [bubble.gestureRecognizers lastObject];
    if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        [recognizer removeTarget:nil action:NULL];
        [recognizer addTarget:self action:@selector(longPressBubble:)];
    }
}

#pragma mark - TableView Methods




//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // If will animate when keyboard is dismissed, so disable it to prevent stretching of images
    //
    [UIView setAnimationsEnabled:NO];

    
    // Provide separate cell type of each message type
    //
	NSString *CellIdentifier = kDMTextCell;
    CDMessageType mType = [self.cdMessage.type intValue];
    switch (mType) {
        case kCDMessageTypeStickerGroup:
        case kCDMessageTypeSticker:
            CellIdentifier = kDMStickerCell;
            break;
            
        case kCDMessageTypeImage:
            CellIdentifier = kDMImageCell;
            break;
            
        case kCDMessageTypeLetter:
            CellIdentifier = kDMLetterCell;
            break;
            
        case kCDMessageTypeLocation:
            CellIdentifier = kDMLocationCell;
            break;
            
        default:
            break;
    }
    
    // get the right type of cell for message type
    //
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
        // Headshot
        //
        UIButton *headButton = [[UIButton alloc] initWithFrame:CGRectMake(kDMMarginBase, 0.0, kDMHeadSize, kDMHeadSize)];
        [headButton setImage:[UIImage imageNamed:@"profile_headshot_bear.png"] forState:UIControlStateNormal];
        headButton.tag = HEADBASE_TAG;
        [cell.contentView addSubview:headButton];
    
        // head image
        //
        UIImageView *headImage = [[UIImageView alloc] initWithFrame:CGRectMake(2.0, 2.0, 31.0, 31.0)];
        headImage.tag = HEADIMAGE_TAG;
        [headButton addSubview:headImage];
        [headImage release];
        
        // Plus sign on headshot
        UIImageView *plusView = [[UIImageView alloc] initWithFrame:CGRectMake(25, 21.0, 15.0, 15.0)];
        plusView.image = [UIImage imageNamed:@"chat_icon_addfriend.png"];
        plusView.tag = HEADPLUS_TAG;
        [headButton addSubview:plusView];
        [plusView release];
        
        // Name label next to head
        //
        UILabel *nLabel = [[UILabel alloc] initWithFrame:CGRectMake(kDMHeadSize+kDMMarginBase, 0.0, 90.0, 15.0)];
        nLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
        nLabel.textColor = [UIColor whiteColor];
        nLabel.backgroundColor = [UIColor clearColor];
        nLabel.shadowColor = [UIColor darkGrayColor];
        nLabel.shadowOffset = CGSizeMake(0, 1);
        nLabel.tag = NAME_TAG;
        [headButton addSubview:nLabel];
        [nLabel release];
        [headButton release];
        

        // Time
        //
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [AppUtility configLabel:timeLabel context:kAULabelTypeBlueNanoPlus];
        timeLabel.tag = TIME_TAG;
        [cell.contentView addSubview:timeLabel];
        [timeLabel release];
        
        // Status
        //
        UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [AppUtility configLabel:statusLabel context:kAULabelTypeBlueNanoPlus];
        statusLabel.tag = STATUS_TAG;
        [cell.contentView addSubview:statusLabel];
        [statusLabel release];
        
        // add alert button
        //
        UIButton *alertButton = [[UIButton alloc] initWithFrame:CGRectMake(293.0, 0.0, kDMAlertSize, kDMAlertSize)];
        [alertButton setImage:[UIImage imageNamed:@"chat_icon_alert.png"] forState:UIControlStateNormal];
        alertButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        //alertButton.backgroundColor = [UIColor yellowColor];
        alertButton.tag = ALERT_TAG;
        [cell.contentView addSubview:alertButton];
        [alertButton release];
        
        // add bubble type of this message
        //
        UIButton *bubbleButton = [self bubbleButton]; // autoreleased
        bubbleButton.tag = BUBBLE_TAG;
        [cell.contentView addSubview:bubbleButton];  
        
        
        // Progress view
        //
        UIProgressView *pView = [[UIProgressView alloc] initWithFrame:CGRectZero];
        pView.progressViewStyle = UIProgressViewStyleDefault;
        pView.tag = PROGRESS_TAG;
        [bubbleButton addSubview:pView];
        //[cell.contentView addSubview:pView];
        [pView release];  
                
	}
    // cell.contentView.backgroundColor = [UIColor greenColor];
    //CGFloat cellWidth = cell.frame.size.width;
    
    // get components
    UIButton *headView = (UIButton *)[cell.contentView viewWithTag:HEADBASE_TAG];
    UIImageView *headImageView = (UIImageView *)[cell.contentView viewWithTag:HEADIMAGE_TAG];
    UIView *plusView = [cell.contentView viewWithTag:HEADPLUS_TAG];
    UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:NAME_TAG];
    
    UILabel *statusLabel = (UILabel *)[cell.contentView viewWithTag:STATUS_TAG];
    UILabel *timeLabel = (UILabel *)[cell.contentView viewWithTag:TIME_TAG];
    UIProgressView *progressView = (UIProgressView *)[cell.contentView viewWithTag:PROGRESS_TAG];
    UIButton *alertButton = (UIButton *)[cell.contentView viewWithTag:ALERT_TAG];

    
    UIButton *bubbleButton = (UIButton *)[cell.contentView viewWithTag:BUBBLE_TAG];
    
    
    // get current setup params
    CDContact *thisContact = self.cdMessage.contactFrom;
    BOOL showHead = NO;
    BOOL isRightSide = [thisContact isMySelf];
    if (!isRightSide) {
        showHead = [self shouldShowHeadShot];
    }

    // if empty group text message - hide it
    // - and return cell right away since we don't need to process anything
    //
    if ( [self.cdMessage isGroupControlMessage] ) {
        cell.contentView.hidden = YES;
        [UIView setAnimationsEnabled:YES];
        return cell;
    }
    else {
        cell.contentView.hidden = NO;
        // configure bubble for this particular message
        [self configureBubble:bubbleButton showHead:showHead isRightSide:isRightSide dialogWidth:cell.contentView.frame.size.width];
    }
    
    if (showHead) {
        headView.hidden = NO;
        
        // add target
        [headView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [headView addTarget:self action:@selector(pressHeadShot:) forControlEvents:UIControlEventTouchUpInside];
        
        
        // add head image
        //  
        MPImageManager *imageM = [[MPImageManager alloc] init];
        UIImage *headImage = [imageM getImageForObject:self.cdMessage.contactFrom context:kMPImageContextList];
        [imageM release];
        
        
        // Add photo
        if (headImage) {
            headImageView.image = headImage;
            headImageView.hidden = NO;
        }
        else {
            headImageView.hidden = YES;
        }
        
        // plus sign - for non friends
        if (![thisContact isFriend] && ![thisContact isBlockedByMe] && ![thisContact isUserAccountedCanceled]){
            plusView.hidden = NO;
        }
        else {
            plusView.hidden = YES;
        }
        
        // name
        nameLabel.text = [thisContact displayName];
        
    }
    else {
        headView.hidden = YES;
    }
    
    
    // Sets time, status and progress views
    //
    CGRect timeFrame = CGRectNull;
    CGRect statusFrame = CGRectNull;
    CGRect progressFrame = CGRectNull;
    CGRect bubbleFrame = bubbleButton.frame;
    CGFloat bubbleHeightCenter = bubbleFrame.origin.y + floor(bubbleFrame.size.height/2.0);
    //CGFloat bubbleHeightBottom = bubbleFrame.origin.y + bubbleFrame.size.height - kDMProgressMarginBottom - kDMProgressHeight;
    CGFloat bubbleHeightBottom = bubbleFrame.size.height - kDMProgressMarginBottom - kDMProgressHeight;
    CGFloat progressWidth = bubbleFrame.size.width - kDMProgressMarginHead - kDMProgressMarginTail;
    
    
    // bubble head is on the left
    if (isRightSide) {
        
        statusFrame = CGRectMake(bubbleFrame.origin.x-kDMLabelMargin-kDMLabelWidth, bubbleHeightCenter-kDMLabelHeight, kDMLabelWidth, kDMLabelHeight);
        timeFrame = CGRectMake(bubbleFrame.origin.x-kDMLabelMargin-kDMLabelWidth, bubbleHeightCenter, kDMLabelWidth, kDMLabelHeight);
        //progressFrame = CGRectMake(bubbleFrame.origin.x+kDMProgressMarginHead, bubbleHeightBottom, progressWidth, kDMProgressHeight);
        progressFrame = CGRectMake(kDMProgressMarginHead, bubbleHeightBottom, progressWidth, kDMProgressHeight);
        
    }
    // bubble head is on the right
    else {
        statusFrame = CGRectMake(bubbleFrame.origin.x+bubbleFrame.size.width+kDMLabelMargin, bubbleHeightCenter-kDMLabelHeight, kDMLabelWidth, kDMLabelHeight);
        timeFrame = CGRectMake(bubbleFrame.origin.x+bubbleFrame.size.width+kDMLabelMargin, bubbleHeightCenter, kDMLabelWidth, kDMLabelHeight);
        //progressFrame = CGRectMake(bubbleFrame.origin.x+kDMProgressMarginTail, bubbleHeightBottom, progressWidth, kDMProgressHeight);
        progressFrame = CGRectMake(kDMProgressMarginTail, bubbleHeightBottom, progressWidth, kDMProgressHeight);
    }
    
    NSString *timeString = [self.cdMessage getSentTimeString];
    timeLabel.frame = timeFrame;
    if ([timeString length] > 0) {
        timeLabel.text = timeString;
        timeLabel.alpha = 1.0;
    }
    else {
        // hide if no text available - helps with animation
        timeLabel.alpha = 0.0;   
    }    
    statusLabel.frame = statusFrame;
    statusLabel.text = [self.cdMessage getStateString];
    // @TEST statusLabel.backgroundColor = [UIColor yellowColor];

    if (isRightSide) {
        timeLabel.textAlignment = UITextAlignmentRight;
        statusLabel.textAlignment = UITextAlignmentRight;
        
        timeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        statusLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        progressView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

    }
    else {
        timeLabel.textAlignment = UITextAlignmentLeft;
        statusLabel.textAlignment = UITextAlignmentLeft;
        
        timeLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        statusLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        progressView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;

    }
    
    // add progress only for messages that upload and download
    //
    if (mType == kCDMessageTypeImage ||
        mType == kCDMessageTypeLetter ) {
        progressView.frame = progressFrame;
        progressView.hidden = YES;
        progressView.alpha = 0.0;
    }
    
    // show alert view
    // - push bubble left
    // - show alert button
    //
    CDMessageState msgState = [self.cdMessage.state intValue];
    if (msgState == kCDMessageStateOutFailed) {
        // don't shift bubble
        //bubbleButton.frame = CGRectOffset(bubbleFrame, -kDMMarginAlert, 0);
        
        CGRect alertFrame = alertButton.frame;
        alertFrame.origin.y = bubbleHeightCenter - kDMAlertSize/2.0;
        alertFrame.origin.x = bubbleFrame.origin.x - kDMAlertSize;
        alertButton.frame = alertFrame;
        alertButton.alpha = 1.0;
        
        bubbleButton.alpha = 0.5;
        
    }
    else {
        alertButton.alpha = 0.0;
        if (msgState == kCDMessageStateOutCreated) {
            bubbleButton.alpha = 0.5;
        }
        else {
            bubbleButton.alpha = 1.0;
        }
    }
    [alertButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [alertButton addTarget:self action:@selector(pressAlert:) forControlEvents:UIControlEventTouchUpInside];
    
    [UIView setAnimationsEnabled:YES];

    return cell;
}


// respond to cell selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    // can't press this 
    
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
	return NO;
}

// Which style to show for editing
//
- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleNone;
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
	return NO;
}





#pragma mark - Row Height


/*!
 @abstract Height to add apart from bubble
 */
- (CGFloat) bubbleMarginHeight {
    BOOL showHead = NO;
    BOOL isRightSide = [cdMessage.contactFrom isMySelf];
    if (!isRightSide) {
        showHead = [self shouldShowHeadShot];
    }

    return showHead?kDMMarginBase+kDMMarginShowHead : kDMMarginBase*2.0;
}


/*!
 @abstract Informs table of row height
 */
- (CGFloat)textRowHeightForTableWidth:(CGFloat)tableWidth {
    

    // if empty group text message - hide it
    //
    if ([self.cdMessage isGroupControlMessage]) {
        return 10.0; //0.0;
    }
    else {
        
        UIFont *bubbleFont = nil;
        if ([[MPSettingCenter sharedMPSettingCenter] isFontSizeLarge]) {
            bubbleFont = [AppUtility fontPreferenceWithContext:kAUFontSystemStandardPlus];
        }
        else {
            bubbleFont = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
        }
        
        // use text view to get right size
        //
        if (!self.textEmoticonView) {
            TextEmoticonView *textSizeView = [[TextEmoticonView alloc] init];
            self.textEmoticonView = textSizeView;
            [textSizeView release];
        }
        
        self.textEmoticonView.font = bubbleFont;



        BOOL isRightSide = [cdMessage.contactFrom isMySelf];
        
        CGRect maxRect = [self textMaxRectForIsRightSide:isRightSide dialogWidth:tableWidth];
        //textSizeView.frame = maxRect;
        [self.textEmoticonView setText:self.cdMessage.text];
        CGSize textSize = [self.textEmoticonView sizeThatFits:maxRect.size];
        //[textSizeView release];
        
        return textSize.height + kDMBubblePaddingVertical*2.0 + [self bubbleMarginHeight];
    }

}

/*!
 @abstract Informs table of row height
 */
- (CGFloat)imageRowHeightForTableWidth:(CGFloat)tableWidth {
        
    // find the right size for this bubble
    UIImage *thisImage = self.cdMessage.previewImage;
    CGSize thisSize = [thisImage size];
    
    // resize location messages
    if ([self.cdMessage.type intValue] == kCDMessageTypeLocation) {
        thisSize = CGSizeMake(170.0, 160.0);
    }
    
    CGSize newImageSize = thisSize;
    
    // if image is too large
    //
    if (thisSize.width > kDMPreviewImageWidthMax) {
        // new height scaled proportionally
        //
        CGFloat newHeight = thisSize.height * kDMPreviewImageWidthMax/thisSize.width;
        newImageSize = CGSizeMake(kDMPreviewImageWidthMax, newHeight);
    }
    
    // add extra padding at bottom of images
    return newImageSize.height + [self bubbleMarginHeight] + kDMMarginBase;
    
}


/*!
 @abstract Informs table of row height
 */
- (CGFloat) locationRowHeightForTableWidth:(CGFloat)tableWidth {
    
    return 160.0 + [self bubbleMarginHeight] + kDMMarginBase;
}


/*!
 @abstract Informs table of row height
 */
- (CGFloat) letterRowHeightForTableWidth:(CGFloat)tableWidth {
    
    UIImage *bubbleImage = [self letterImageForCurrentState];
    CGSize letterSize = bubbleImage.size;
    
    return letterSize.height + [self bubbleMarginHeight];
}

/*!
 @abstract Informs table of row height
 */
- (CGFloat) stickerRowHeightForTableWidth:(CGFloat)tableWidth {
    
    UIImage *previewImage = [self.cdMessage.stickerResource getImageForType:kRSImageTypeStickerStart];
    
    if (previewImage) {
        CGSize stickerSize = previewImage.size;
        return stickerSize.height + [self bubbleMarginHeight];
    }
    // otherwise return max size and show default sticker
    else {
        return 160.0 + [self bubbleMarginHeight];
    }

}

/*!
 @abstract Informs table of row height
 */
- (CGFloat)rowHeightForTableWidth:(CGFloat)tableWidth {
    
    CDMessageType mType = [self.cdMessage.type intValue];
    switch (mType) {
        case kCDMessageTypeStickerGroup:
        case kCDMessageTypeSticker:
            return [self stickerRowHeightForTableWidth:tableWidth];
            break;
            
        case kCDMessageTypeImage:
            return [self imageRowHeightForTableWidth:tableWidth];
            break;
            
        case kCDMessageTypeLetter:
            return [self letterRowHeightForTableWidth:tableWidth];
            break;
            
        case kCDMessageTypeLocation:
            return [self locationRowHeightForTableWidth:tableWidth];
            break;
            
        default:
            break;
    }
    return [self textRowHeightForTableWidth:tableWidth];
}


#pragma mark - Button and Actions


/*!
 @abstract Gets visible cell for this cell controller
 
 @return nil if no matching visible cell
 
 */
- (UITableViewCell *) visibleCell {
    if ([self.delegate respondsToSelector:@selector(DialogMessageCellController:visibleCellForMessage:)]) {
        UITableViewCell *cell = [self.delegate DialogMessageCellController:self visibleCellForMessage:self.cdMessage];
        return cell;
    }
    return nil;
}


- (void) hideProgress {
    
    UITableViewCell *cell = [self visibleCell];
    UIProgressView *progressView = (UIProgressView *)[cell.contentView viewWithTag:PROGRESS_TAG];
    
    progressView.hidden = YES;
    progressView.alpha = 0.0;
    
}

/*!
 @abstract Update the progress bar
 
 @param bytes amount of data already sent or received
 @param isIncreamental bytes will add incrementally, NO if bytes are the amount downloaded so far
 Note:
 - if 0 or 100% then bar will disappear
 
 */
- (void)updateProgress:(NSInteger)bytes isIncreamental:(BOOL)isIncreamental{
    
    CDMessageState state = [self.cdMessage.state intValue];

    
    UIProgressView *progressView = nil;
    UIButton *bubbleView = nil;
    
    UITableViewCell *cell = [self visibleCell];
    progressView = (UIProgressView *)[cell.contentView viewWithTag:PROGRESS_TAG];
    bubbleView = (UIButton *)[cell.contentView viewWithTag:BUBBLE_TAG];
    
    //DDLogVerbose(@"DMCC-up: progress bytes: %d %d - %@", bytes, state, progressView);
    
    // only if progress view exists and message is in the right state
    //
    if (progressView && bubbleView && (state == kCDMessageStateOutCreated || 
                              state == kCDMessageStateInRead || 
                              state == kCDMessageStateInReadDownloaded )) {
        NSUInteger fullSize = [self.cdMessage.attachLength integerValue];
        
        if (state == kCDMessageStateOutCreated) {
            // out going will include a preview icon and header data
            // - approximate header to be 1000 bytes max, so we should never go over 100%
            //
            fullSize = fullSize + [self.cdMessage.previewImageData length]+1000;
        }
        
        if (progressView.hidden) {
            progressView.hidden = NO;
            progressView.alpha = 1.0;
            self.currentProgress = 0;
        }
        
        if (isIncreamental) {
            self.currentProgress += bytes;
        }
        else {
            self.currentProgress = bytes;
        }
        
        CGFloat ratio = (CGFloat)self.currentProgress/(CGFloat)fullSize;
        
        // write complete sends -1 as bytes
        //
        if (bytes == -1) {
            ratio = 1.0;
        }
        
        DDLogVerbose(@"DMCC-up: progress %d : %d/%d = %f", bytes, self.currentProgress, fullSize, ratio);
        
        // only animated for 5.0
        if ([progressView respondsToSelector:@selector(setProgress:animated:)]) {
            [progressView setProgress:ratio animated:YES];
        }
        else {
            [progressView setProgress:ratio];
        }
        
        // hide progress when done
        if (ratio == 1.0) {
            [self performSelector:@selector(hideProgress) withObject:nil afterDelay:1.0];
            
            // for inbound messages
            if (state == kCDMessageStateInRead || 
                state == kCDMessageStateInReadDownloaded) {
                
                // if in read, then change state to read downloaded
                self.cdMessage.state = [NSNumber numberWithInt:kCDMessageStateInReadDownloaded];
                [AppUtility cdSaveWithIDString:@"msg download state" quitOnFail:NO];
                
                
                // image
                // - hide download image
                //
                if ([self.cdMessage.type intValue] == kCDMessageTypeImage) {
                    //UIView *arrowView = [bubbleView viewWithTag:DOWN_ARROW_TAG];
                    
                    UIImageView *frameULView = (UIImageView *)[bubbleView viewWithTag:FRAME_UP_LEFT_TAG];
                    UIImageView *frameURView = (UIImageView *)[bubbleView viewWithTag:FRAME_UP_RIGHT_TAG];
                    UIImageView *frameDLView = (UIImageView *)[bubbleView viewWithTag:FRAME_DOWN_LEFT_TAG];
                    UIImageView *frameDRView = (UIImageView *)[bubbleView viewWithTag:FRAME_DOWN_RIGHT_TAG];
                    
                    [UIView animateWithDuration:kMPParamAnimationStdDuration 
                                     animations:^{
                                         //arrowView.alpha = 0.0;
                                         
                                         frameULView.alpha = 0.0;
                                         frameURView.alpha = 0.0;
                                         frameDLView.alpha = 0.0;
                                         frameDRView.alpha = 0.0;
                                     }
                                     completion:^(BOOL finished){
                                         //arrowView.hidden = YES;
                                         
                                         frameULView.hidden = YES;
                                         frameURView.hidden = YES;
                                         frameDLView.hidden = YES;
                                         frameDRView.hidden = YES;
                                     }];
                }
                // letter
                // - update to new image
                //
                else if ([self.cdMessage.type intValue] == kCDMessageTypeLetter) {
                    UIImage *letterImage = [self letterImageForCurrentState];
                    CGSize newSize = [letterImage size];
                    CGRect oldFrame = bubbleView.frame;
                    [bubbleView setImage:letterImage forState:UIControlStateNormal];
                    bubbleView.frame = CGRectMake(oldFrame.origin.x+(oldFrame.size.width-newSize.width), 
                                                       oldFrame.origin.y, 
                                                       newSize.width, newSize.height);
                }
            }
        }
    }
}


/*!
 @abstract Show headview if needed
 
 Use:
 - after deleting a row the next row may need to show the head shot, animate it smoothly w/o refreshing entire cell
 */
- (void) refreshHeadViewForCell:(UITableViewCell *)refreshCell animated:(BOOL)animated{
    
    if ([self.cdMessage isSentFromSelf]) {
        return;
    }
    
    UIButton *headView = nil;
    UIImageView *headImageView = nil;
    UIView *plusView = nil;
    UILabel *nameLabel = nil;
    
    UIButton *bubbleView = nil;
    UILabel *timeLabel = nil;
    UILabel *statusLabel = nil;
    
    
    headView = (UIButton *)[refreshCell.contentView viewWithTag:HEADBASE_TAG];
    headImageView = (UIImageView *)[refreshCell.contentView viewWithTag:HEADIMAGE_TAG];
    plusView = [refreshCell.contentView viewWithTag:HEADPLUS_TAG];
    nameLabel = (UILabel *)[refreshCell.contentView viewWithTag:NAME_TAG];
    
    bubbleView = (UIButton *)[refreshCell.contentView viewWithTag:BUBBLE_TAG];
    timeLabel = (UILabel *)[refreshCell.contentView viewWithTag:TIME_TAG];
    statusLabel = (UILabel *)[refreshCell.contentView viewWithTag:STATUS_TAG];
    
    /*
    if ([self.delegate respondsToSelector:@selector(DialogMessageCellController:visibleCellForMessage:)]) {
        UITableViewCell *cell = [self.delegate DialogMessageCellController:self visibleCellForMessage:self.cdMessage];
        headView = (UIButton *)[cell.contentView viewWithTag:HEADBASE_TAG];
        headImageView = (UIImageView *)[cell.contentView viewWithTag:HEADIMAGE_TAG];
        plusView = [cell.contentView viewWithTag:HEADPLUS_TAG];
        nameLabel = (UILabel *)[cell.contentView viewWithTag:NAME_TAG];
    }*/
    
    if (headView) {
        
        // if hidden, then show it
        // - should only need to show, never hide a headview!
        //
        if ([self shouldShowHeadShot]){ // && headView.hidden == YES) {
            headView.hidden = NO;
            headView.alpha = 0.0;
            
            // add target
            [headView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [headView addTarget:self action:@selector(pressHeadShot:) forControlEvents:UIControlEventTouchUpInside];
            
            // add head image
            //      
            MPImageManager *imageM = [[MPImageManager alloc] init];
            UIImage *headImage = [imageM getImageForObject:self.cdMessage.contactFrom context:kMPImageContextList];
            [imageM release];
            
            
            // Add photo
            if (headImage) {
                headImageView.image = headImage;
                headImageView.hidden = NO;
            }
            else {
                headImageView.hidden = YES;
            }
            
            // plus sign - for non friends
            if (![self.cdMessage.contactFrom isFriend] && 
                ![self.cdMessage.contactFrom isBlockedByMe] && 
                ![self.cdMessage.contactFrom isUserAccountedCanceled]){
                plusView.hidden = NO;
            }
            else {
                plusView.hidden = YES;
            }
            
            // name
            nameLabel.text = [self.cdMessage.contactFrom displayName];
            
            
            // Sets time, status and progress views
            //
            CGRect timeFrame = CGRectNull;
            CGRect statusFrame = CGRectNull;
            CGRect bubbleFrame = bubbleView.frame;
            bubbleFrame.origin.y = kDMMarginShowHead;
            
            CGFloat bubbleHeightCenter = bubbleFrame.origin.y + bubbleFrame.size.height/2.0;
            
            statusFrame = CGRectMake(bubbleFrame.origin.x+bubbleFrame.size.width+kDMLabelMargin, bubbleHeightCenter-kDMLabelHeight, kDMLabelWidth, kDMLabelHeight);
            timeFrame = CGRectMake(bubbleFrame.origin.x+bubbleFrame.size.width+kDMLabelMargin, bubbleHeightCenter, kDMLabelWidth, kDMLabelHeight);
            
            
            // refresh time and status
            //
            if (animated) {
                [UIView animateWithDuration:kMPParamAnimationStdDuration/2.0
                                 animations:^{
                                     headView.alpha = 1.0;
                                     timeLabel.frame = timeFrame;
                                     statusLabel.frame = statusFrame;
                                     bubbleView.frame = bubbleFrame;
                                 } 
                                 completion:^(BOOL finished){
                                 }];
            }
            else {
                headView.alpha = 1.0;
                timeLabel.frame = timeFrame;
                statusLabel.frame = statusFrame;
                bubbleView.frame = bubbleFrame;
            }
        }
    }
}

/*!
 @abstract Refresh cell visuals that can change
 
 - time & status
 - fail and retry
 - letter sent image states
 
 Remaining elements should not need to be updated.
 
 */
- (void) refreshCell {
        
    UIButton *bubbleView = nil;
    UILabel *timeLabel = nil;
    UILabel *statusLabel = nil;
    
    UITableViewCell *cell = [self visibleCell];
    bubbleView = (UIButton *)[cell.contentView viewWithTag:BUBBLE_TAG];
    timeLabel = (UILabel *)[cell.contentView viewWithTag:TIME_TAG];
    statusLabel = (UILabel *)[cell.contentView viewWithTag:STATUS_TAG];
    UIButton *alertButton = (UIButton *)[cell.contentView viewWithTag:ALERT_TAG];
    UIProgressView *progressView = (UIProgressView *)[cell.contentView viewWithTag:PROGRESS_TAG];

    
    if (statusLabel && timeLabel && bubbleView) {
        
        // update letter image if state has changed
        // - only for letters from me
        //
        BOOL didAlertChange = NO;
        BOOL isMyLetter = NO;
        CGRect timeFrame = CGRectNull;
        CGRect statusFrame = CGRectNull;
        CGRect newBubbleFrame = CGRectNull;
        CGFloat alertNewAlpha = 0.0;
        CDMessageState state = [self.cdMessage getStateValue];
                
        // show alert view
        // - push bubble left
        // - show alert button
        //
        if (state == kCDMessageStateOutFailed) {
            progressView.alpha = 0.0;
            
            didAlertChange = YES;
            newBubbleFrame = bubbleView.frame;
            // no shift
            // newBubbleFrame.origin.x = cell.contentView.frame.size.width - newBubbleFrame.size.width - kDMMarginAlert - kDMMarginBase;
            
            CGRect alertFrame = alertButton.frame;
            alertFrame.origin.y = newBubbleFrame.origin.y+(newBubbleFrame.size.height-kDMAlertSize)/2.0;
            alertFrame.origin.x = newBubbleFrame.origin.x - kDMAlertSize;
            alertButton.frame = alertFrame;
            alertNewAlpha = 1.0;
            
        }
        // if alert button is showing - handle state change
        //
        // retry sending message
        // - shift bubble back
        //
        else if (state == kCDMessageStateOutCreated) {
            didAlertChange = YES;
            newBubbleFrame = bubbleView.frame;
            // no shift
            // newBubbleFrame.origin.x = cell.contentView.frame.size.width - kDMMarginBase - newBubbleFrame.size.width;
            
            alertNewAlpha = 0.0;
        }
        // in case msg was actually delivered
        // - shift bubble back
        //
        else if (state == kCDMessageStateOutRead ||
                 state == kCDMessageStateOutDelivered ||
                 state == kCDMessageStateOutSent) {
            didAlertChange = YES;
            newBubbleFrame = bubbleView.frame;
            // no shift
            // newBubbleFrame.origin.x = cell.contentView.frame.size.width - kDMMarginBase - newBubbleFrame.size.width;
            
            alertNewAlpha = 0.0;
        }
        // sent out letter may change in size
        //
        if ([self.cdMessage.type intValue] == kCDMessageTypeLetter && [self.cdMessage isSentFromSelf]) {
            isMyLetter = YES;
            UIImage *bubbleImage = [self letterImageForCurrentState];
            [bubbleView setImage:bubbleImage forState:UIControlStateNormal];
            
            CGSize newSize = [bubbleImage size];
            CGSize oldSize = bubbleView.frame.size;
            
            // expand to the left and down
            newBubbleFrame = CGRectMake(bubbleView.frame.origin.x+(oldSize.width-newSize.width),
                                               bubbleView.frame.origin.y, newSize.width, newSize.height);
            
            // letter expands and moves labels
            //
            CGRect bubbleFrame = newBubbleFrame;
            CGFloat bubbleHeightCenter = bubbleFrame.origin.y + bubbleFrame.size.height/2.0;
            
            statusFrame = CGRectMake(bubbleFrame.origin.x-kDMLabelMargin-kDMLabelWidth, bubbleHeightCenter-kDMLabelHeight, kDMLabelWidth, kDMLabelHeight);
            timeFrame = CGRectMake(bubbleFrame.origin.x-kDMLabelMargin-kDMLabelWidth, bubbleHeightCenter, kDMLabelWidth, kDMLabelHeight);
        
        }
        
        
        // refresh time and status
        //
        [UIView animateWithDuration:kMPParamAnimationStdDuration/2.0
                         animations:^{
                             statusLabel.alpha = 0.0;
                             if (didAlertChange) {
                                 bubbleView.frame = newBubbleFrame;
                                 alertButton.alpha = alertNewAlpha;
                             }
                             else if (isMyLetter) {
                                 timeLabel.frame = timeFrame;
                                 statusLabel.frame = statusFrame;
                                 bubbleView.frame = newBubbleFrame;
                             }
                         } 
                         completion:^(BOOL finished){
                             
                             timeLabel.text = [self.cdMessage getSentTimeString];
                             statusLabel.text = [self.cdMessage getStateString];
                             
                             // set bubble alpha here since otherwise animation sequence may get mixed up
                             // - so get state right before animation for more accurate results.
                             CDMessageState finalState = [self.cdMessage getStateValue];
                             CGFloat finalBubbleAlpha = 1.0;
                             if (finalState == kCDMessageStateOutCreated ||
                                 finalState == kCDMessageStateOutFailed) {
                                 finalBubbleAlpha = 0.5;
                             }

                             [UIView animateWithDuration:kMPParamAnimationStdDuration/2.0
                                              animations:^{
                                                  timeLabel.alpha = 1.0;
                                                  statusLabel.alpha = 1.0;
                                                  bubbleView.alpha = finalBubbleAlpha;
                                              }];
                         }];
    }
    
}

/*!
 @abstract start action for this message
 
 Use:
 - for sticker views, start animation
 */
- (void) startAnimation {
    
    UIButton *bubbleView = nil;
    
    UITableViewCell *cell = [self visibleCell];
    bubbleView = (UIButton *)[cell.contentView viewWithTag:BUBBLE_TAG];

    if ([bubbleView respondsToSelector:@selector(runAnimation)]) {
        [bubbleView performSelector:@selector(runAnimation)];
    }
}


/*!
 @abstract Press headshot
 - Show add friend alert view
 
 */
- (void) pressHeadShot:(id)sender{
    
    // For non friends - show pop up to add/block
    //
    CDContact *thisContact = self.cdMessage.contactFrom;
    if (![thisContact isFriend] && 
        ![thisContact isBlockedByMe] && 
        ![thisContact isUserAccountedCanceled]){
        
        CGRect appFrame = [Utility appFrame];
        AddFriendAlertView *alertView = [[AddFriendAlertView alloc] initWithFrame:appFrame contact:self.cdMessage.contactFrom];
        
        UIViewController *containerVC = [[AppUtility getAppDelegate] containerController];
        [containerVC.view addSubview:alertView];
        [alertView release];
    }
}

/*!
 @abstract Remove "+" if unknown contact added or blocked
 
 */
- (void) updateHeadView:(NSNotification *)notification {
    
    CDContact *updateContact = [notification object];
    
    if (self.cdMessage.contactFrom == updateContact ) {
        UIView *plusView = nil;
        UITableViewCell *cell = [self visibleCell];
        plusView = [cell.contentView viewWithTag:HEADPLUS_TAG];
        
        if (plusView) {
            plusView.hidden = YES;
        }
    }
}


/*!
 @abstract Press Image or Location Bubble
 
 Image
 - If image downloaded, then get it now
 - If image available call delegate to show image
 
 Location
 - get coordinate
 - ask delegate to show location
 
 */
- (void) pressImageBubble:(id)sender {
    
    NSInteger messageType = [self.cdMessage.type intValue];
    
    if (messageType == kCDMessageTypeImage) {
        if (!self.fileManager) {
            TKFileManager *newFileManager = [[TKFileManager alloc] init];
            newFileManager.delegate = self;
            self.fileManager = newFileManager;
            [newFileManager release];
        }
        
        UIImage *fullImage = nil;

        // get locally created broadcast image
        //
        if ([self.cdMessage isFromSelf] && self.cdMessage.parentMessage) {
            NSData *imageData = [fileManager getFileDataForFilename:self.cdMessage.parentMessage.filename url:nil];
            fullImage = [UIImage imageWithData:imageData];
        }
        
        // try getting message 
        //
        if (fullImage == nil) {
            NSString *url = [self.cdMessage getDownloadURL];
            
            if (url) {
                NSData *imageData = [fileManager getFileDataForFilename:self.cdMessage.filename url:url];
                fullImage = [UIImage imageWithData:imageData];
            }
        }
        
        
        // ask delegate to show this image
        if (fullImage) {
            if ([self.delegate respondsToSelector:@selector(DialogMessageCellController:showImage:message:)]) {
                
                // make sure state is updated correctly in case update progress does not provide 100% download update
                //
                CDMessageState state = [self.cdMessage getStateValue];
                if (state == kCDMessageStateInRead ||
                    state == kCDMessageStateInDelivered) {
                    // if in read, then change state to read downloaded
                    self.cdMessage.state = [NSNumber numberWithInt:kCDMessageStateInReadDownloaded];
                    [AppUtility cdSaveWithIDString:@"msg download state" quitOnFail:NO];
                }
                
                [self.delegate DialogMessageCellController:self showImage:fullImage message:self.cdMessage];
            }
        }
        else {
            // disable button until download if finished
            [sender setEnabled:NO];
        }
    }
    // 
    else if (messageType == kCDMessageTypeLocation) {
        
        // ask delegate to show this location coordinate
        //
        NSArray *locationInfo = [self.cdMessage.text componentsSeparatedByString:@","];
        
        // first two elements are lat and long
        if ([locationInfo count] > 1) {
            CGFloat lat = [[locationInfo objectAtIndex:0] floatValue];
            CGFloat lng = [[locationInfo objectAtIndex:1] floatValue];
            
            if ([self.delegate respondsToSelector:@selector(DialogMessageCellController:showLocationLatitude:longitude:)]) {
                [self.delegate DialogMessageCellController:self showLocationLatitude:lat longitude:lng];
            }
            
        }
    }
}

/*!
 @abstract Show Letter
 */
- (void) showLetter:(UIImage *)fullImage {
    if ([self.delegate respondsToSelector:@selector(DialogMessageCellController:showLetter:message:)]) {
        [self.delegate DialogMessageCellController:self showLetter:fullImage message:self.cdMessage];
    }
}



/*!
 @abstract Press Image Bubble
 
 - If image downloaded, then get it now
 - If image available call delegate to show image
 
 */
- (void) pressLetterBubble:(UIButton *)sender {
    
    if (!self.fileManager) {
        TKFileManager *newFileManager = [[TKFileManager alloc] init];
        newFileManager.delegate = self;
        self.fileManager = newFileManager;
        [newFileManager release];
    }
    
    UIImage *fullImage = nil;
    
    // get locally created broadcast image
    //
    if ([self.cdMessage isFromSelf] && self.cdMessage.parentMessage) {
        NSData *imageData = [fileManager getFileDataForFilename:self.cdMessage.parentMessage.filename url:nil];
        fullImage = [UIImage imageWithData:imageData];
    }
    
    // try getting message 
    //
    if (fullImage == nil) {
        NSString *url = [self.cdMessage getDownloadURL];
        
        if (url) {
            NSData *imageData = [fileManager getFileDataForFilename:self.cdMessage.filename url:url];
            fullImage = [UIImage imageWithData:imageData];
        }
    }

    
    // ask delegate to show this image
    if (fullImage) {
        // un-highlight - otherwise image remains dark after being pressed
        // - maybe caused by starting animation
        [sender setHighlighted:NO];
        
        if ([self.cdMessage isFromSelf]) {
            [self showLetter:fullImage];
        }
        else {
            [sender.imageView startAnimating];
            [self performSelector:@selector(showLetter:) withObject:fullImage afterDelay:sender.imageView.animationDuration];
        }
    }
    else {
        // disable button until download if finished
        [sender setEnabled:NO];
    }
}

/*!
 @abstract Pressed Text Bubble
 
 */
- (void) pressTextBubble:(id)sender {
    
}




/*!
 @abstract Long press for each bubble
 
 */
- (void) longPressBubble:(UIGestureRecognizer *)gestureRecognizer {
    
    // only handle for start
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    NSString *cancelTitle = NSLocalizedString(@"Cancel", @"DialogMessage - button: cancel bubble long press");
    NSString *deleteTitle = NSLocalizedString(@"Delete", @"DialogMessage - button: delete bubble");
    
    NSString *copyTitle = NSLocalizedString(@"Copy", @"DialogMessage - button: copy bubble");
    NSString *forwardTitle = NSLocalizedString(@"Forward", @"DialogMessage - button: forward bubble");
    
    NSString *retry = NSLocalizedString(@"Try Again", @"DialogMessage - button: try sending this message again");
    
    UIActionSheet *aSheet;

    BOOL showRetry = NO;
    
    if ([self.cdMessage getStateValue] == kCDMessageStateOutFailed) {
        showRetry = YES;
        
        // don't allow message retry if account is deleted
        //
        CDContact *p2pContact = [self.cdMessage.chat p2pUser];
        if ([p2pContact isUserAccountedCanceled]) {
            showRetry = NO;
        }
        // don't allow message retry if no chat members
        //
        if ([self.cdMessage.chat isGroupChat]) {
            NSUInteger memberCount = [self.cdMessage.chat.participants count];
            if (memberCount == 0) {
                showRetry = NO;
            }
        }
    }
    
    // if failed message, add retry option
    if (showRetry) {
        switch ([self.cdMessage.type intValue]) {
                
            case kCDMessageTypeTextGroup:
            case kCDMessageTypeText:
                aSheet	= [[UIActionSheet alloc]
                           initWithTitle:nil
                           delegate:self
                           cancelButtonTitle: cancelTitle
                           destructiveButtonTitle: deleteTitle
                           otherButtonTitles:retry, forwardTitle, copyTitle, nil];            
                break;
                
            case kCDMessageTypeImage:
            case kCDMessageTypeLetter:
                aSheet	= [[UIActionSheet alloc]
                           initWithTitle:nil
                           delegate:self
                           cancelButtonTitle:cancelTitle
                           destructiveButtonTitle:deleteTitle
                           otherButtonTitles:retry, nil];  
                break;
                
                // sticker, location
            default:
                aSheet	= [[UIActionSheet alloc]
                           initWithTitle:nil
                           delegate:self
                           cancelButtonTitle:cancelTitle
                           destructiveButtonTitle:deleteTitle
                           otherButtonTitles:retry, forwardTitle, nil];  
                break;
        }
    }
    else {
        switch ([self.cdMessage.type intValue]) {
                
            case kCDMessageTypeTextGroup:
            case kCDMessageTypeText:
                aSheet	= [[UIActionSheet alloc]
                           initWithTitle:nil
                           delegate:self
                           cancelButtonTitle: cancelTitle
                           destructiveButtonTitle: deleteTitle
                           otherButtonTitles:forwardTitle, copyTitle, nil];            
                break;
                
            case kCDMessageTypeImage:
            case kCDMessageTypeLetter:
                aSheet	= [[UIActionSheet alloc]
                           initWithTitle:nil
                           delegate:self
                           cancelButtonTitle:cancelTitle
                           destructiveButtonTitle:deleteTitle
                           otherButtonTitles:nil];  
                break;
                
                // sticker, location
            default:
                aSheet	= [[UIActionSheet alloc]
                           initWithTitle:nil
                           delegate:self
                           cancelButtonTitle:cancelTitle
                           destructiveButtonTitle:deleteTitle
                           otherButtonTitles:forwardTitle, nil];  
                break;
        }
    }
    
    
    aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	
	[aSheet showInView:[[UIApplication sharedApplication] keyWindow]];
	[aSheet release];
    
    // maintain highlight after selection
    //
    UITableViewCell *cell = [self visibleCell];
    UIButton *bubble = (UIButton *)[cell viewWithTag:BUBBLE_TAG];
    [bubble setHighlighted:YES]; 
}

/*!
 @abstract press alert button
 
 */
- (void) pressAlert:(id)sender {
    
    
    NSString *retry = NSLocalizedString(@"Try Again", @"DialogMessage - button: try sending this message again");
    
    // don't allow message retry if account is deleted
    //
    CDContact *p2pContact = [self.cdMessage.chat p2pUser];
    if ([p2pContact isUserAccountedCanceled]) {
        retry = nil;
    }
    // don't allow message retry if no chat members
    //
    if ([self.cdMessage.chat isGroupChat]) {
        NSUInteger memberCount = [self.cdMessage.chat.participants count];
        if (memberCount == 0) {
            retry = nil;
        }
    }
    
    UIActionSheet *aSheet	= [[UIActionSheet alloc]
                               initWithTitle: NSLocalizedString(@"This message was not sent.", @"DialogMessage - actionsheet: title for retry and delete message options")
                               delegate:self
                               cancelButtonTitle:NSLocalizedString(@"Cancel", @"DialogMessage - button: cancel bubble long press")
                               destructiveButtonTitle:NSLocalizedString(@"Delete", @"DialogMessage - button: delete bubble")
                               otherButtonTitles:retry, nil]; 
    aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	
	[aSheet showInView:[[UIApplication sharedApplication] keyWindow]];
	[aSheet release];
    
    // maintain highlight after selection
    //
    UITableViewCell *cell = [self visibleCell];
    UIButton *bubble = (UIButton *)[cell viewWithTag:BUBBLE_TAG];
    [bubble setHighlighted:YES]; 
    
}


/*!
 @abstract Checks if timeout is for this message and refresh if needed
 
 */
- (void) handleSentTimeout:(NSNotification *)notification {
    
    NSString *messageID = [notification object];
    if ([self.cdMessage.mID isEqualToString:messageID]) {
        
        DDLogVerbose(@"DMC: got sent timeout st:%@ mID:%@", self.cdMessage.state, messageID);
        [self refreshCell];
    }
    
}


#pragma mark - Action Sheet: Long Press and Alert button actions


/*!
 @abstract Check if chat contact is blocked and show alert to unblock
 
 @return YES if blocked
 */
- (BOOL) isChatContactBlocked {
    
    CDContact *p2pContact = [self.cdMessage.chat p2pUser];
    if ([p2pContact isBlockedByMe]) {
        
        NSString *detMessage = [NSString stringWithFormat:NSLocalizedString(@"%@ is blocked. Unblock to send message.", @"ChatDialog - alert: Need to unblock in order to message"), [p2pContact displayName]];
        
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:nil
                                                         message:detMessage
                                                        delegate:self
                                               cancelButtonTitle:NSLocalizedString(@"Cancel", @"ChatDialog: Cancel button") 
                                               otherButtonTitles:NSLocalizedString(@"Unblock", @"ChatDialog: Unblock this user"), nil] autorelease];
        [alert show];
        return YES;
    }
    return NO;
}


/*!
 @abstract respond to actionsheet selection
 */
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // if not cancel
    BOOL didDelete = NO;
    if (buttonIndex != [actionSheet cancelButtonIndex]) {
        
		NSString *actionButtonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        // Deletes cell
        //
		if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Delete",nil)]) {
            if ([self.delegate respondsToSelector:@selector(DialogMessageCellController:deleteMessage:)]) {
                [self.delegate DialogMessageCellController:self deleteMessage:self.cdMessage];
                didDelete = YES;
            }
        }
        // Forward to single contact
        //
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Forward",nil)]) {
            
            if ([self.delegate respondsToSelector:@selector(DialogMessageCellController:forwardMessage:)]) {
                [self.delegate DialogMessageCellController:self forwardMessage:self.cdMessage];
            }
            
        }
        // Copy message content
        //
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Copy",nil)]) {
            
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = self.cdMessage.text;
                        
        }
        // try sending message again!
        //
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Try Again",nil)]) {
            
            // resend only if chat is not blocked
            //
            if (![self isChatContactBlocked]) {
                // change state back to create
                //
                [[MPChatManager sharedMPChatManager] markCDMessageCreated:self.cdMessage.mID];
                
                // refresh to get back MOC results
                // - merge does not seem to work automatically here...
                //
                [[AppUtility cdGetManagedObjectContext] refreshObject:self.cdMessage mergeChanges:YES];
                
                DDLogVerbose(@"CM: retry sending st: %@ mID: %@", self.cdMessage.state, self.cdMessage.mID);
                
                // refresh cell
                //
                [self refreshCell];
                
                // send message out
                //
                [[MPChatManager sharedMPChatManager] sendCDMessage:self.cdMessage requireSentConfirmation:YES enableAcceptRejectConfirmation:NO];
            }
            
        }
    }
    else {
        DDLogVerbose(@"Bubble long press cancelled");
    }
    
    // delete will dealloc this cell so don't 
    if (!didDelete) {
        UITableViewCell *cell = [self visibleCell];
        UIButton *bubble = (UIButton *)[cell viewWithTag:BUBBLE_TAG];
        [bubble setHighlighted:NO]; 
    }

}




#pragma mark - TKFileManager Delegate


/*!
 @abstract Called when data has completed loading and is ready to use.
 
 - ask the our delegate to show image
 
 */
- (void)TKFileManager:(TKFileManager *)fileManager finishLoadingWithData:(NSData *)data{
    
    // show time again and hide progress
    //[self showSentTime];
    
    UIProgressView *progressView = nil;
    UIButton *bubbleView = nil;
    
    UITableViewCell *cell = [self visibleCell];
    progressView = (UIProgressView *)[cell.contentView viewWithTag:PROGRESS_TAG];
    bubbleView = (UIButton *)[cell.contentView viewWithTag:BUBBLE_TAG];
    
    progressView.hidden = YES;
    progressView.alpha = 0.0;
    
    // enable bubble view again after download
    [bubbleView setEnabled:YES];
    
    // Show image automatically
    UIImage *fullImage = [UIImage imageWithData:data];
    if (fullImage) {
        
        // show image
        if ([self.cdMessage.type intValue] == kCDMessageTypeImage) {
            if ([self.delegate respondsToSelector:@selector(DialogMessageCellController:showImage:message:)]) {
                
                // make sure state is updated correctly in case update progress does not provide 100% download update
                //
                CDMessageState state = [self.cdMessage getStateValue];
                if (state == kCDMessageStateInRead ||
                    state == kCDMessageStateInDelivered) {
                    // if in read, then change state to read downloaded
                    self.cdMessage.state = [NSNumber numberWithInt:kCDMessageStateInReadDownloaded];
                    [AppUtility cdSaveWithIDString:@"msg download state" quitOnFail:NO];
                }
                
                
                [self.delegate DialogMessageCellController:self showImage:fullImage message:self.cdMessage];
            }
        }
        // show letter
        else if ([self.cdMessage.type intValue] == kCDMessageTypeLetter) {
            [bubbleView.imageView startAnimating];
            [self performSelector:@selector(showLetter:) withObject:fullImage afterDelay:bubbleView.imageView.animationDuration];
        }
    }
}

/*!
 @abstract Called regularly when data is regularly downloaded
 
 */
- (void)TKFileManager:(TKFileManager *)fileManager bytesDownloaded:(NSUInteger)bytes expectedContentLength:(NSUInteger)expectedContentLengthBytes{
    // update download progress
    [self updateProgress:bytes isIncreamental:NO];
}

/*! 
 @abstract Delegate called when error has occurred
 @discussion Handles connection error.  No further delegate calls will be made 
 for this connection. So reset connection and received data.
 
 */
- (void)TKFileManager:(TKFileManager *)fileManager didFailWithError:(NSError *)error {
    
    // download failed
    UIProgressView *progressView = nil;
    UIButton *bubbleView = nil;
    
    UITableViewCell *cell = [self visibleCell];
    progressView = (UIProgressView *)[cell.contentView viewWithTag:PROGRESS_TAG];
    bubbleView = (UIButton *)[cell.contentView viewWithTag:BUBBLE_TAG];
    
    progressView.hidden = YES;
    progressView.alpha = 0.0;
    
    // enable bubble view again - so we can try again
    [bubbleView setEnabled:YES];
}




@end
