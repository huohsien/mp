//
//  ChatDialogMessageView.m
//  mp
//
//  Created by M Tsai on 11-12-12.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "ChatDialogMessageView.h"
#import "MPFoundation.h"
#import "CDMessage.h"
#import "CDContact.h"
#import "UIImage+TKUtilities.h"
#import "TextEmoticonView.h"
#import "StickerButton.h"
#import "AddFriendAlertView.h"

CGFloat const kMPParamChatFreshSeconds = 60.0;

CGFloat const kMPParmMarginBase = 5.0;

CGFloat const kMPParmMarginChat2Chat = 9.0;
CGFloat const kMPParmMarginChat2View = 5.0;

CGFloat const kMPParmBubblePaddingTail = 15.0;
CGFloat const kMPParmBubblePaddingHead = 10.0;
CGFloat const kMPParmBubblePaddingVertical = 5.0;

CGFloat const kMPParmBubbleWidthMaxMe = 200.0;
CGFloat const kMPParmBubbleWidthMaxOther = 160.0;


CGFloat const kMPParmHeadSize = 35.0;

CGFloat const kMPParmLabelHeight = 13.0;
CGFloat const kMPParmLabelWidth = 50.0;
CGFloat const kMPParmLabelMargin = 3.0;

CGFloat const kMPParmProgressHeight = 13.0;
CGFloat const kMPParmProgressWidth = 50.0;
CGFloat const kMPParmProgressMarginHead = 10.0;
CGFloat const kMPParmProgressMarginTail = 13.0;
CGFloat const kMPParmProgressMarginBottom = 7.0;


CGFloat const kMPParmJoinLeftWidthMax = 280.0;
CGFloat const kMPParmJoinLeftWidthMin = 150.0;

CGFloat const kMPParmPreviewImageWidthMax = 210.0;


@interface ChatDialogMessageView (Private)
- (void)showProgress;
- (void) hideProgress;

- (void) pressImageBubble:(id)sender;
- (void) pressLetterBubble:(id)sender;

@end


@implementation ChatDialogMessageView

@synthesize delegate;
@synthesize thisObject;
@synthesize lowestView;
@synthesize thisMessage;
@synthesize previousView;
@synthesize lastHeight;
@synthesize headView;
@synthesize bubbleView;
@synthesize statusLabel;
@synthesize timeLabel;
@synthesize progressView;
@synthesize currentProgress;
@synthesize fileManager;

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    delegate = nil;
    fileManager.delegate = nil;

    [lowestView release];
    [thisObject release];
    [thisMessage release];
    [previousView release];
    [headView release];
    [bubbleView release];
    [statusLabel release];
    [timeLabel release];
    [progressView release];
    [fileManager release];
    
    [super dealloc];
}

/*!
 @abstract initialize view
 
 @param thisMessage message to be represented
 @param previousMessage the previous msg will influence this one
 @param lastHeight help determine where we will place this message's frame
 
 */
- (id)initWithMessage:(CDMessage *)newThisMessage object:(id)newObject previousView:(ChatDialogMessageView *)newPreviousView lastHeight:(CGFloat)newLastHeight
{
    
    self = [super init];
    if (self) {
        // Initialization code
        self.userInteractionEnabled = YES;
        self.thisObject = newObject;
        self.thisMessage = newThisMessage;
        self.previousView = newPreviousView;
        self.lastHeight = newLastHeight;
        self.currentProgress = 0;
        
        // use notification since one alert view can broadcast to several message views
        //
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateHeadView:) name:MP_ADDFRIENDALERT_CONTACT_CHANGED_NOTIFICATION object:nil];
        
    }
    return self;
}

#pragma mark - UIView 

/*!
 @abstract return views that should respond to events given a point in the local frame
 
 This is needed since this parent frame is very small and does not hold all subviews within it's bounds.
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
    
    //CGFloat newHeight = self.lowestView.frame.origin.y + self.lowestView.frame.size.height+10.0;
    //CGRect extendedFrame = CGRectMake(0.0, 0.0, self.frame.size.width, newHeight);
    
    // allow bubble tap
    /*if (CGRectContainsPoint(self.bubbleView.frame, point)) {
        return self.bubbleView;
    }
    else if (CGRectContainsPoint(self.headView.frame, point)) {
        return self.headView;
    }
    
    return nil;*/
}


/*!
 @abstract
 
Edit 2: (After clarification:) In order to ensure that the button is treated as being within the parent's bounds, you need to override pointInside:withEvent: in the parent to include the button's frame.
 */
/*- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    
    if (CGRectContainsPoint(self.frame, point) ||
        CGRectContainsPoint(self.bubbleView.frame, point)){
        return YES;
    }
    return NO;
}*/


#pragma mark - Utilities

#define PLUS_VIEW_TAG       19001
#define DOWN_ARROW_TAG      19002
#define kArrowSize          27.0
#define kArrowMargin        10.0

/*!
 @abstract Get appropriate image for letter message state
 */
- (UIImage *) letterImageForCurrentState {
    
    NSString *sendLetterImageName = @"letter_stk_uploading.png";
    NSInteger messageState = [self.thisMessage.state intValue];
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
 @abstract should show headshot for this message
 
 Check if message is from same person: N->show headshot
 Check if message is within XX seconds: > X sec -> show headshot
 
 For chats from same person that are close together, don't show headshots
 */
- (BOOL) shouldShowHeadShot {
    
    if (!self.previousView) {
        return YES;
    }
    
    BOOL shouldShow = YES;
    
    NSString *thisID = self.thisMessage.contactFrom.userID;
    NSString *previousID = self.previousView.thisMessage.contactFrom.userID;
    
    // same person, check time
    if ([thisID isEqualToString:previousID]) {
        CGFloat thisTime = [self.thisMessage.sentDate timeIntervalSince1970];
        CGFloat previousTime = [self.previousView.thisMessage.sentDate timeIntervalSince1970];
        if ((thisTime - previousTime) < kMPParamChatFreshSeconds) {
            shouldShow = NO;
        }
    }
    // diff person, YES
    return shouldShow;
}


/*!
 @abstract get the height of the bottom edge of this view
 
 Use:
 - to determine where the next view shoud go
 
 Get the lowest edge of the bubble view
 
 */
- (CGFloat) getBottomHeight {
    
    CGFloat bottomHeight = 0.0;
    if (self.lowestView) {
        CGRect lowFrame = self.lowestView.frame;
        bottomHeight = self.frame.origin.y + lowFrame.origin.y + lowFrame.size.height;
    }
    // some strange empty view
    else {
        bottomHeight = self.frame.origin.y;
    }
    return bottomHeight;
}



/*!
 @abstract get starting height for this view
 */
- (CGFloat)getYstartForThisView {
    
    CGFloat yStart = kMPParmMarginChat2View;
    
    if (self.thisMessage) {
        if (self.previousView) {
            yStart = [self.previousView getBottomHeight] + kMPParmMarginChat2Chat;
        }
        else if (self.lastHeight){
            yStart = self.lastHeight + kMPParmMarginChat2Chat;
        }
    }
    else if (self.thisObject) {
        if (self.previousView) {
            yStart = [self.previousView getBottomHeight] + kMPParmMarginChat2View;
        }
        else if (self.lastHeight){
            yStart = self.lastHeight + kMPParmMarginChat2View;
        }
    }
    //DDLogVerbose(@"**CDMV: YStart: %f  Prev: %f", yStart, [self.previousView getBottomHeight]);
    return yStart;
}




/*!
 @abstract adds status indicators
 
 */
- (void) addStatusViewsIsRightSide:(BOOL)isRightSide {
    
    // sets time, status and upload download status
    //
    // from others
    CGRect timeFrame = CGRectNull;
    CGRect statusFrame = CGRectNull;
    CGRect progressFrame = CGRectNull;
    CGRect bubbleFrame = self.bubbleView.frame;
    CGFloat bubbleHeightCenter = bubbleFrame.size.height/2.0;
    CGFloat bubbleHeightBottom = bubbleFrame.size.height - kMPParmProgressMarginBottom - kMPParmProgressHeight;
    CGFloat progressWidth = bubbleFrame.size.width - kMPParmProgressMarginHead - kMPParmProgressMarginTail;
    
    // bubble head is on the right
    if (isRightSide) {
        statusFrame = CGRectMake(bubbleFrame.origin.x+bubbleFrame.size.width+kMPParmLabelMargin, bubbleHeightCenter-kMPParmLabelHeight, kMPParmLabelWidth, kMPParmLabelHeight);
        timeFrame = CGRectMake(bubbleFrame.origin.x+bubbleFrame.size.width+kMPParmLabelMargin, bubbleHeightCenter, kMPParmLabelWidth, kMPParmLabelHeight);
        progressFrame = CGRectMake(bubbleFrame.origin.x+kMPParmProgressMarginTail, bubbleHeightBottom, progressWidth, kMPParmProgressHeight);
    }
    // bubble head is on the left
    else {
        statusFrame = CGRectMake(bubbleFrame.origin.x-kMPParmLabelMargin-kMPParmLabelWidth, bubbleHeightCenter-kMPParmLabelHeight, kMPParmLabelWidth, kMPParmLabelHeight);
        timeFrame = CGRectMake(bubbleFrame.origin.x-kMPParmLabelMargin-kMPParmLabelWidth, bubbleHeightCenter, kMPParmLabelWidth, kMPParmLabelHeight);
        progressFrame = CGRectMake(bubbleFrame.origin.x+kMPParmProgressMarginHead, bubbleHeightBottom, progressWidth, kMPParmProgressHeight);
        
        //progressFrame = CGRectMake(bubbleFrame.origin.x-kMPParmProgressMargin-kMPParmProgressWidth, bubbleHeightCenter, kMPParmProgressWidth, kMPParmProgressHeight);
    }
    
    UILabel *newTimeLabel = [[UILabel alloc] initWithFrame:timeFrame];
    [AppUtility configLabel:newTimeLabel context:kAULabelTypeBlueNanoPlus];
    NSString *timeString = [self.thisMessage getSentTimeString];
    if ([timeString length] > 0) {
        newTimeLabel.text = timeString;
    }
    else {
        // hide if no text available - helps with animation
        newTimeLabel.alpha = 0.0;   
    }
    [self addSubview:newTimeLabel];
    
    UILabel *newStatusLabel = [[UILabel alloc] initWithFrame:statusFrame];
    [AppUtility configLabel:newStatusLabel context:kAULabelTypeBlueNanoPlus];
    newStatusLabel.text = [self.thisMessage getStateString];
    // hide status unless we need to show it - for animation
    newStatusLabel.alpha = 0.0;                                 
    [self addSubview:newStatusLabel];
    
    if (!isRightSide) {
        newTimeLabel.textAlignment = UITextAlignmentRight;
        newStatusLabel.textAlignment = UITextAlignmentRight;
    }
    self.timeLabel = newTimeLabel;
    self.statusLabel = newStatusLabel;
    
    [newTimeLabel release];    
    [newStatusLabel release];
    
    
    // add progress only for messages that upload and download
    //
    if ([self.thisMessage.type intValue] == kCDMessageTypeImage ||
        [self.thisMessage.type intValue] == kCDMessageTypeLetter ) {
        UIProgressView *pView = [[UIProgressView alloc] initWithFrame:progressFrame];
        pView.progressViewStyle = UIProgressViewStyleDefault;
        pView.hidden = YES;
        [self addSubview:pView];
        self.progressView = pView;
        [pView release];
    }
}


/*!
 @abstract Adds headshot button
 
 */
- (void) addHeadshotButton {
  
    // add headshot
    if ([self shouldShowHeadShot]) {
        
        CDContact *thisContact = self.thisMessage.contactFrom;
        
        // bear image
        //
        UIButton *headButton = [[UIButton alloc] initWithFrame:CGRectMake(kMPParmMarginBase, 0.0, kMPParmHeadSize, kMPParmHeadSize)];
        [headButton setImage:[UIImage imageNamed:@"profile_headshot_bear.png"] forState:UIControlStateNormal];
        [headButton addTarget:self action:@selector(pressHeadShot:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:headButton];
        
        NSString *thisID = thisContact.userID;
        MPImageManager *imageM = [[MPImageManager alloc] init];
        UIImage *headImage = [imageM getImageForFilename:thisID context:kMPImageContextList];
        [imageM release];
        
        // my photo exists, then add it
        if (headImage) {
            UIImageView *headShotView = [[UIImageView alloc] initWithFrame:CGRectMake(2.0, 2.0, 31.0, 31.0)];
            headShotView.image = headImage;
            [headButton addSubview:headShotView];
            [headShotView release];
        }
        // plus sign - for non friends
        if (![thisContact isFriend] && ![thisContact isBlockedByMe] && ![thisContact isUserAccountedCanceled]){
            UIImageView *plusView = [[UIImageView alloc] initWithFrame:CGRectMake(25, 21.0, 15.0, 15.0)];
            plusView.image = [UIImage imageNamed:@"chat_icon_addfriend.png"];
            plusView.tag = PLUS_VIEW_TAG;
            [headButton addSubview:plusView];
            [plusView release];
        }
        // add name label to the bottom
        UILabel *nLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 37.0, 45.0, 20.0)];
        nLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
        nLabel.textColor = [UIColor whiteColor];
        nLabel.backgroundColor = [UIColor clearColor];
        nLabel.shadowColor = [UIColor darkGrayColor];
        nLabel.shadowOffset = CGSizeMake(0, 1);
        nLabel.text = thisMessage.contactFrom.displayName;
        [headButton addSubview:nLabel];
        [nLabel release];
        self.headView = headButton;
        [headButton release];
    }
}


/*!
 @abstract Update the progress bar
 
 @param bytes amount of data already sent or received
 @param isIncreamental bytes will add incrementally, NO if bytes are the amount downloaded so far
 Note:
 - if 0 or 100% then bar will disappear
 
 */
- (void)upateProgress:(NSUInteger)bytes isIncreamental:(BOOL)isIncreamental{

    CDMessageState state = [self.thisMessage.state intValue];
    //DDLogVerbose(@"CDM-up: progress bytes: %d %d", bytes, state);

    // only if progress view exists and message is in the right state
    //
    if (self.progressView && (state == kCDMessageStateOutCreated || 
                              state == kCDMessageStateInRead || 
                              state == kCDMessageStateInReadDownloaded )) {
        NSUInteger fullSize = [self.thisMessage.attachLength integerValue];
        
        if (self.progressView.hidden) {
            [self showProgress];
            self.currentProgress = 0;
        }
        
        if (isIncreamental) {
            self.currentProgress += bytes;
        }
        else {
            self.currentProgress = bytes;
        }
        
        CGFloat ratio = (CGFloat)self.currentProgress/(CGFloat)fullSize;

        DDLogVerbose(@"CDM-up: progress %d : %d/%d = %f", bytes, self.currentProgress, fullSize, ratio);

        // only animated for 5.0
        if ([self.progressView respondsToSelector:@selector(setProgress:animated:)]) {
            [self.progressView setProgress:ratio animated:YES];
        }
        else {
            [self.progressView setProgress:ratio];
        }
        
        // hide progress when done
        if (ratio == 1.0) {
            [self hideProgress];
            
            // for inbound messages
            if (state == kCDMessageStateInRead || 
                state == kCDMessageStateInReadDownloaded) {
                
                // if in read, then change state to read downloaded
                self.thisMessage.state = [NSNumber numberWithInt:kCDMessageStateInReadDownloaded];
                [AppUtility cdSaveWithIDString:@"msg download state" quitOnFail:NO];
                
                
                // image
                // - hide download image
                //
                if ([self.thisMessage.type intValue] == kCDMessageTypeImage) {
                    UIView *arrowView = [self.bubbleView viewWithTag:DOWN_ARROW_TAG];
                    [UIView animateWithDuration:kMPParamAnimationStdDuration 
                                     animations:^{
                                         arrowView.alpha = 0.0;
                                     }
                                     completion:^(BOOL finished){
                                         [arrowView removeFromSuperview];
                                     }];
                }
                // letter
                // - update to new image
                //
                else if ([self.thisMessage.type intValue] == kCDMessageTypeLetter) {
                    UIImage *letterImage = [self letterImageForCurrentState];
                    CGSize newSize = [letterImage size];
                    CGRect oldFrame = self.bubbleView.frame;
                    [self.bubbleView setImage:letterImage forState:UIControlStateNormal];
                    self.bubbleView.frame = CGRectMake(oldFrame.origin.x+(oldFrame.size.width-newSize.width), 
                                                       oldFrame.origin.y, 
                                                       newSize.width, newSize.height);
                }
            }
        }
    }
}

#pragma mark - Build Views


/*!
 @abstract create a date time view that splits messages from different dates
 
 */
- (void)buildDateViewDialogWidth:(CGFloat)dialogWidth {
    
    CGFloat yStart = [self getYstartForThisView];
    
    // start from x=0 easier to calc
    //
    self.frame = CGRectMake(0.0, yStart, 1.0, 1.0);
    self.backgroundColor = [UIColor clearColor];
    self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    NSString *dateString = [Utility stringForDate:self.thisObject componentString:@"yMdEEEE"];
    
    // create view
    //
    UIImage *backImage = [Utility resizableImage:[UIImage imageNamed:@"chat_icon_dialog_timestamp.png"] leftCapWidth:15.0 topCapHeight:10.0];
    UIImageView *backView = [[UIImageView alloc] initWithImage:backImage];
    backView.backgroundColor = [UIColor clearColor];

    backView.frame = CGRectMake((dialogWidth - 170.0)/2.0, 0.0, 170.0, 20.0);
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 170.0, 20.0)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = UITextAlignmentCenter;
    label.text = dateString;
    [backView addSubview:label];
    [label release];
    
    [self addSubview:backView];
    self.lowestView = backView;
    [backView release];

}

/*!
 @abstract create a date time view that splits messages from different dates
 
 */
- (void)buildJoinLeftViewDialogWidth:(CGFloat)dialogWidth {
    
    UIFont *font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
    
    CGFloat yStart = [self getYstartForThisView];
    
    // start from x=0 easier to calc
    //
    self.frame = CGRectMake(0.0, yStart, 1.0, 1.0);
    self.backgroundColor = [UIColor clearColor];
    self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

    
    CGFloat bubbleYStart = 0.0;
    
    NSSet *contacts = nil;
    CDMessageType thisType = [self.thisMessage.type intValue];
    
    if ([self.thisObject isKindOfClass:[NSArray class]]) {
        contacts = self.thisObject;
    }
    else {
        contacts = [NSSet setWithObject:self.thisMessage.contactFrom];
    }
    
    
    // one bubble for each contact
    //
    for (CDContact *iContact in contacts) {
        
        // create view
        //
        NSString *actionString = nil;
        UIImage *backImage = nil;
        
        if (thisType != kCDMessageTypeGroupLeave) {
            actionString = [NSString stringWithFormat:NSLocalizedString(@"%@ joined", @"DialogMessage - text: User joined group chat"), [iContact displayName]];
            backImage = [Utility resizableImage:[UIImage imageNamed:@"chat_dialog_icon_join.png"] leftCapWidth:14.0 topCapHeight:9.0];
        }
        else {
            actionString = [NSString stringWithFormat:NSLocalizedString(@"%@ left", @"DialogMessage - text: User left group chat"), [iContact displayName]];
            backImage = [Utility resizableImage:[UIImage imageNamed:@"chat_dialog_icon_leave.png"] leftCapWidth:14.0 topCapHeight:9.0];
        }
        
        CGSize fontSize = [actionString sizeWithFont:font];
        
        CGFloat width = kMPParmJoinLeftWidthMin;
        if (fontSize.width > kMPParmJoinLeftWidthMax) {
            width = kMPParmJoinLeftWidthMax;
        }
        else if (fontSize.width > kMPParmJoinLeftWidthMin) {
            width = fontSize.width; 
        }
        width += 20.0; // add padding for label
        
        UIImageView *backView = [[UIImageView alloc] initWithImage:backImage];
        backView.backgroundColor = [UIColor clearColor];

        backView.frame = CGRectMake((dialogWidth - width)/2.0, bubbleYStart, width, 20.0);
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, width-20.0, 20.0)];
        label.backgroundColor = [UIColor clearColor];
        label.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = UITextAlignmentCenter;
        label.text = actionString;
        [backView addSubview:label];
        [label release];
        
        [self addSubview:backView];
        self.lowestView = backView;
        [backView release];
        
        //CGRect lowFrame = self.lowestView.frame;
        
        // for next view increment yStart
        bubbleYStart += self.lowestView.frame.size.height + kMPParmMarginChat2View;
    }
}





/*!
 @abstract build a Image bubble view
 
 - Image bubbleView
 - headshot
 - message status & time
 
 */
- (void) buildImageViewDialogWidth:(CGFloat)dialogWidth {

    
    CGFloat yStart = [self getYstartForThisView];
        
    // start from x=0 easier to calc
    //
    self.frame = CGRectMake(0.0, yStart, dialogWidth, 1.0);
    self.backgroundColor = [UIColor clearColor];

    
    // is bubble from others? - helps format other status labels
    BOOL doesBubbleStartFromRight = YES;
    
    // find the right size for this bubble
    UIImage *thisImage = self.thisMessage.previewImage;
    CGSize thisSize = [thisImage size];
    
    // resize location messages
    if ([self.thisMessage.type intValue] == kCDMessageTypeLocation) {
        thisSize = CGSizeMake(170.0, 160.0);
    }
    
    CGSize newImageSize = thisSize;
    
    // if image is too large
    //
    if (thisSize.width > kMPParmPreviewImageWidthMax) {
        // new height scaled proportionally
        //
        CGFloat newHeight = thisSize.height * kMPParmPreviewImageWidthMax/thisSize.width;
        newImageSize = CGSizeMake(kMPParmPreviewImageWidthMax, newHeight);
    }
    
    //DDLogVerbose(@"CDMV-cv: config image height:%f state:%@", newImageSize.height, self.thisMessage.state);
    
    // my own image message!
    if ([self.thisMessage isSentFromSelf]) {
        
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

        
        // from myself
        doesBubbleStartFromRight = NO;
        
        CGFloat bubbleWidth = newImageSize.width;
        CGFloat bubbleStartX = dialogWidth - kMPParmMarginBase - bubbleWidth;
        CGFloat bubbleHeight = newImageSize.height;
        
        UIImage *bubbleImage = [Utility resizableImage:[UIImage imageNamed:@"chat_dialog_sendphoto_bubble_wh.png"] leftCapWidth:15.0 rightCapWidth:15.0 topCapHeight:13.0 bottomCapHeight:13.0];
        
        
        UIButton *myBubble = [[UIButton alloc] initWithFrame:CGRectMake(bubbleStartX, 0.0, bubbleWidth, bubbleHeight)];
        [myBubble setBackgroundImage:bubbleImage forState:UIControlStateNormal];
        myBubble.backgroundColor = [UIColor clearColor];
        [myBubble addTarget:self action:@selector(pressImageBubble:) forControlEvents:UIControlEventTouchUpInside];

        
        // create mask
        // - same size as image!
        UIImage *maskImage = [Utility resizableImage:[UIImage imageNamed:@"chat_dialog_sendphoto_mask2.png"] leftCapWidth:15.0 rightCapWidth:15.0 topCapHeight:13.0 bottomCapHeight:13.0];
        UIImageView *maskView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, thisSize.width, thisSize.height)];
        maskView.image = maskImage;
        UIImage *resizedMaskImage = [UIImage sharpImageWithView:maskView];
        [maskView release];
        
        UIImage *maskedImage = [UIImage maskImage:thisImage withMask:resizedMaskImage];
        
        // acutalImage
        UIImageView *previewImageView = [[UIImageView alloc] initWithImage:maskedImage];
        previewImageView.frame = CGRectMake(0.0, 0.0, bubbleWidth, bubbleHeight);
        [myBubble addSubview:previewImageView];
        [previewImageView release];
        
        //[myBubble addTarget:self action:@selector(pressSuggestion:) forControlEvents:UIControlEventTouchUpInside];
        //[myBubble setTitle:self.thisMessage.text forState:UIControlStateNormal];

        self.bubbleView = myBubble;
        [self addSubview:myBubble];
        [myBubble release];
    }
    // text message from others!
    else {
        
        self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;

        // from other
        doesBubbleStartFromRight = YES;
        
        CGFloat bubbleWidth = newImageSize.width;
        CGFloat bubbleStartX = kMPParmMarginBase*2 + kMPParmHeadSize;
        CGFloat bubbleHeight = newImageSize.height;
        
        UIImage *bubbleImage = [Utility resizableImage:[UIImage imageNamed:@"chat_dialog_sendphoto_bubble_y.png"] leftCapWidth:15.0 rightCapWidth:15.0 topCapHeight:13.0 bottomCapHeight:13.0];
        
        
        UIButton *myBubble = [[UIButton alloc] initWithFrame:CGRectMake(bubbleStartX, 0.0, bubbleWidth, bubbleHeight)];
        [myBubble setBackgroundImage:bubbleImage forState:UIControlStateNormal];
        myBubble.backgroundColor = [UIColor clearColor];
        myBubble.enabled = YES;


        // create mask
        // - the same exact size as image
        //
        UIImage *maskImage = [Utility resizableImage:[UIImage imageNamed:@"chat_dialog_sendphoto_mask1.png"] leftCapWidth:15.0 rightCapWidth:15.0 topCapHeight:13.0 bottomCapHeight:13.0];
        UIImageView *maskView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, thisSize.width, thisSize.height)];        
        maskView.image = maskImage;
        UIImage *resizedMaskImage = [UIImage sharpImageWithView:maskView];
        [maskView release];
        
        // acutalImage
        UIImage *maskedImage = [UIImage maskImage:thisImage withMask:resizedMaskImage];
        UIImageView *previewImageView = [[UIImageView alloc] initWithImage:maskedImage];
        previewImageView.frame = CGRectMake(0.0, 0.0, bubbleWidth, bubbleHeight);
        [myBubble addSubview:previewImageView];
        [previewImageView release];
        
        // add download arrow
        // - if only read or delivered
        CDMessageState state = [self.thisMessage.state intValue];
        if (state == kCDMessageStateInRead ||
            state == kCDMessageStateInDelivered) {
            UIImageView *arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_dialog_icon_dl_nor.png"]];
            arrowImageView.frame = CGRectMake(bubbleWidth-kArrowSize-kArrowMargin, bubbleHeight-kArrowSize-kArrowMargin, kArrowSize, kArrowSize);
            arrowImageView.tag = DOWN_ARROW_TAG;
            [myBubble addSubview:arrowImageView];
            [arrowImageView release];
        }
        
        
        //[myBubble addTarget:self action:@selector(pressSuggestion:) forControlEvents:UIControlEventTouchUpInside];
        //[myBubble setTitle:self.thisMessage.text forState:UIControlStateNormal];
        
        self.bubbleView = myBubble;
        [self addSubview:myBubble];
        [myBubble release];
        
        [self addHeadshotButton];
        
    }
    [self.bubbleView addTarget:self action:@selector(pressImageBubble:) forControlEvents:UIControlEventTouchUpInside];


    [self addStatusViewsIsRightSide:doesBubbleStartFromRight];
    
    // mark lowest view to measure height
    self.lowestView = self.bubbleView;
    
    
    // extend frame to encompass the lowest view, so buttons are enabled
    /*CGRect myFrame = self.frame;
    myFrame.size.height = self.lowestView.frame.origin.y + self.lowestView.frame.size.height+10.0;
    self.frame = myFrame;
    self.backgroundColor = [UIColor greenColor];*/
    
    //label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
}





/*!
 @abstract build a Letter bubble view
 
 - Letter bubbleView
 - headshot
 - message status & time
 
 */
- (void) buildLetterViewDialogWidth:(CGFloat)dialogWidth {
    
    
    CGFloat yStart = [self getYstartForThisView];
    
    // start from x=0 easier to calc
    //
    self.frame = CGRectMake(0.0, yStart, dialogWidth, 1.0);
    self.backgroundColor = [UIColor clearColor];
    
    
    // is bubble from others? - helps format other status labels
    BOOL doesBubbleStartFromRight = YES;
        
    // my own image message!
    if ([self.thisMessage isSentFromSelf]) {
        
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        
        // letter view
        //
        
        // from myself
        doesBubbleStartFromRight = NO;
        

        UIImage *bubbleImage = [self letterImageForCurrentState];
        CGSize letterSize = bubbleImage.size;
        
        CGFloat bubbleWidth = letterSize.width;
        CGFloat bubbleStartX = dialogWidth - kMPParmMarginBase - bubbleWidth;
        CGFloat bubbleHeight = letterSize.height;

        
        UIButton *myBubble = [[UIButton alloc] initWithFrame:CGRectMake(bubbleStartX, 0.0, bubbleWidth, bubbleHeight)];
        [myBubble.imageView setContentMode:UIViewContentModeRight];
        [myBubble setImage:bubbleImage forState:UIControlStateNormal];
        myBubble.backgroundColor = [UIColor clearColor];
        
        self.bubbleView = myBubble;
        [self addSubview:myBubble];
        [myBubble release];
    }
    // message from others!
    else {
        
        self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        
        // from other
        doesBubbleStartFromRight = YES;
        
        UIImage *bubbleImage = [self letterImageForCurrentState];
        CGSize letterSize = bubbleImage.size;
        
        CGFloat bubbleWidth = letterSize.width;
        CGFloat bubbleStartX = kMPParmMarginBase*2 + kMPParmHeadSize;
        CGFloat bubbleHeight = letterSize.height;
        
        UIButton *myBubble = [[UIButton alloc] initWithFrame:CGRectMake(bubbleStartX, 0.0, bubbleWidth, bubbleHeight)];
        [myBubble setImage:bubbleImage forState:UIControlStateNormal];
        myBubble.backgroundColor = [UIColor clearColor];
        myBubble.enabled = YES;
        // NEVER set image direction - use setImage: instead
        myBubble.imageView.animationDuration = 1.0;
        myBubble.imageView.animationRepeatCount = 1;
        myBubble.imageView.animationImages = [NSArray arrayWithObjects:
                                              [UIImage imageNamed:@"letter_ani_01.png"],
                                              [UIImage imageNamed:@"letter_ani_02.png"],
                                              [UIImage imageNamed:@"letter_ani_03.png"],
                                              [UIImage imageNamed:@"letter_ani_04.png"],
                                              [UIImage imageNamed:@"letter_ani_04.png"], nil];
        self.bubbleView = myBubble;
        [self addSubview:myBubble];
        [myBubble release];
        
        // add headshot
        [self addHeadshotButton];

        /*
        if ([self shouldShowHeadShot]) {
            
            // bear image
            //
            UIButton *headButton = [[UIButton alloc] initWithFrame:CGRectMake(kMPParmMarginBase, 0.0, kMPParmHeadSize, kMPParmHeadSize)];
            [headButton setImage:[UIImage imageNamed:@"profile_headshot_bear.png"] forState:UIControlStateNormal];
            [headButton addTarget:self action:@selector(pressHeadShot:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:headButton];
            
            NSString *thisID = self.thisMessage.contactFrom.userID;
            MPImageManager *imageM = [[MPImageManager alloc] init];
            UIImage *headImage = [imageM getImageForFilename:thisID context:kMPImageContextList];
            [imageM release];
            
            // my photo exists, then add it
            if (headImage) {
                UIImageView *headShotView = [[UIImageView alloc] initWithFrame:CGRectMake(2.0, 2.0, 31.0, 31.0)];
                headShotView.image = headImage;
                [headButton addSubview:headShotView];
                [headShotView release];
            }
            // plus sign - for non friends
            if (![self.thisMessage.contactFrom isFriend]){
                UIImageView *plusView = [[UIImageView alloc] initWithFrame:CGRectMake(25, 21.0, 15.0, 15.0)];
                plusView.image = [UIImage imageNamed:@"chat_icon_addfriend.png"];
                [headButton addSubview:plusView];
                [plusView release];
            }
            // add name label to the bottom
            UILabel *nLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 37.0, 45.0, 20.0)];
            nLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
            nLabel.textColor = [UIColor whiteColor];
            nLabel.backgroundColor = [UIColor clearColor];
            nLabel.shadowColor = [UIColor darkGrayColor];
            nLabel.shadowOffset = CGSizeMake(0, 1);
            nLabel.text = thisMessage.contactFrom.displayName;
            [headButton addSubview:nLabel];
            [nLabel release];
            self.headView = headButton;
            [headButton release];
        }*/
    }
    [self.bubbleView addTarget:self action:@selector(pressLetterBubble:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addStatusViewsIsRightSide:doesBubbleStartFromRight];
    
    // mark lowest view to measure height
    self.lowestView = self.bubbleView;
    
}




/*!
 @abstract build a Sticker bubble view
 
 */
- (void) buildStickerViewDialogWidth:(CGFloat)dialogWidth {
    
    CGFloat yStart = [self getYstartForThisView];
        
    // start from x=0 easier to calc
    //
    self.frame = CGRectMake(0.0, yStart, 1.0, 1.0);
    self.backgroundColor = [UIColor clearColor];
    
    
    // is bubble from others? - helps format other status labels
    BOOL doesBubbleStartFromRight = YES;
    
    // find the right size for this bubble
    CDResource *stickerResource = self.thisMessage.stickerResource;
    
    // make some randown frame
    StickerButton *stickerButton = [[StickerButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 10.0) resource:stickerResource];
    stickerButton.backgroundColor = [UIColor clearColor];
    
    CGSize stickerSize = stickerButton.frame.size;
    
    //DDLogVerbose(@"CDMV-cv: config image height:%f state:%@", newImageSize.height, self.thisMessage.state);
    
    // my own image message!
    if ([self.thisMessage isSentFromSelf]) {
        
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

        // from myself
        doesBubbleStartFromRight = NO;
        
        CGFloat bubbleWidth = stickerSize.width;
        CGFloat bubbleStartX = dialogWidth - kMPParmMarginBase - bubbleWidth;
        CGFloat bubbleHeight = stickerSize.height;
        stickerButton.frame = CGRectMake(bubbleStartX, 0.0, bubbleWidth, bubbleHeight);
    
        self.bubbleView = stickerButton;
        [self addSubview:stickerButton];
        [stickerButton release];
    }
    // text message from others!
    else {
        self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;

        // from other
        doesBubbleStartFromRight = YES;
        
        CGFloat bubbleWidth = stickerSize.width;
        CGFloat bubbleStartX = kMPParmMarginBase*2 + kMPParmHeadSize;
        CGFloat bubbleHeight = stickerSize.height;
        
        stickerButton.frame = CGRectMake(bubbleStartX, 0.0, bubbleWidth, bubbleHeight);
        
        self.bubbleView = stickerButton;
        [self addSubview:stickerButton];
        [stickerButton release];
        
        // add headshot
        [self addHeadshotButton];
    }    
    
    [self addStatusViewsIsRightSide:doesBubbleStartFromRight];
    
    // mark lowest view to measure height
    self.lowestView = self.bubbleView;
    
    
    // extend frame to encompass the lowest view, so buttons are enabled
    /*CGRect myFrame = self.frame;
     myFrame.size.height = self.lowestView.frame.origin.y + self.lowestView.frame.size.height+10.0;
     self.frame = myFrame;
     self.backgroundColor = [UIColor greenColor];*/
    
    //label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
}



/*!
 @abstract configure frame using attributes
 
 - bubbleView
 - headshot
 - message status & time
 
 */
- (void) configureViewDialogWidth:(CGFloat)dialogWidth {

    NSInteger messageType = [self.thisMessage.type intValue];
    
    // Date bubbles
    if ([self.thisObject isKindOfClass:[NSDate class]]) {
        [self buildDateViewDialogWidth:dialogWidth];
        return;
    }
    // Check if sticker and create sticker bubble
    //
    else if (messageType == kCDMessageTypeSticker || messageType == kCDMessageTypeStickerGroup){
        [self buildStickerViewDialogWidth:dialogWidth];
        return;
    }
    // Join and Left bubbles
    // - array for join messages
    // - leave use regular message format
    //
    else if ([self.thisObject isKindOfClass:[NSArray class]] || messageType == kCDMessageTypeGroupLeave){
        [self buildJoinLeftViewDialogWidth:dialogWidth];
        return;
    }
    // Image & Location bubbles
    // - why array?? not needed
    //
    else if ([self.thisObject isKindOfClass:[NSArray class]] || 
             messageType == kCDMessageTypeImage || 
             messageType == kCDMessageTypeLocation){
        [self buildImageViewDialogWidth:dialogWidth];
        return;
    }
    // Letter bubbles
    //
    else if (messageType == kCDMessageTypeLetter){
        [self buildLetterViewDialogWidth:dialogWidth];
        return;
    }
    
    
    // TEXT or Group Text messages below
    
    CGFloat yStart = [self getYstartForThisView];
    
    // start from x=0 easier to calc
    //
    self.frame = CGRectMake(0.0, yStart, 1.0, 1.0);
    self.backgroundColor = [UIColor clearColor];
    
    
    UIFont *bubbleFont = nil;
    if ([[MPSettingCenter sharedMPSettingCenter] isFontSizeLarge]) {
        bubbleFont = [AppUtility fontPreferenceWithContext:kAUFontSystemStandardPlus];
    }
    else {
        bubbleFont = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
    }
    
        
    // is bubble from others? - helps format other status labels
    BOOL doesBubbleStartFromRight = YES;
    
    //DDLogVerbose(@"CDMV-cv: config message text:%@ state:%@", self.thisMessage.text, self.thisMessage.state);
    
    // my own text message!
    if ([self.thisMessage isSentFromSelf]) {
        
        self.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin;

        // from myself
        doesBubbleStartFromRight = NO;
        
        // create text view
        CGRect maxRect = CGRectMake(kMPParmBubblePaddingHead, kMPParmBubblePaddingVertical, kMPParmBubbleWidthMaxMe, 9999.0); // 225max - tail and head = 200
        TextEmoticonView *textView = [[TextEmoticonView alloc] initWithFrame:maxRect];
        //textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        textView.font = bubbleFont;
        [textView setText:self.thisMessage.text];
        [textView sizeToFit];
        CGSize expectedLabelSize = textView.frame.size;
        
        CGFloat bubbleWidth = expectedLabelSize.width + kMPParmBubblePaddingHead + kMPParmBubblePaddingTail;
        CGFloat bubbleHeight = expectedLabelSize.height + kMPParmBubblePaddingVertical*2.0;
        // don't go beyond min and max size, otherwise bubble will deform
        if (bubbleHeight < 32.0) {
            bubbleHeight = 32.0;
        }
        if (bubbleWidth < 40) {
            bubbleWidth = 40.0;
        }
        if (bubbleWidth > 225.0) {
            bubbleWidth = 225.0;
        }
        CGFloat bubbleStartX = dialogWidth - kMPParmMarginBase - bubbleWidth;
        
        
        UIImage *myImage = [Utility resizableImage:[UIImage imageNamed:@"chat_icon_bubble_wh.png"] leftCapWidth:15.0 rightCapWidth:24.0 topCapHeight:15.0 bottomCapHeight:15.0];

        
        UIButton *myBubble = [[UIButton alloc] initWithFrame:CGRectMake(bubbleStartX, 0.0, bubbleWidth, bubbleHeight)];
        [myBubble setBackgroundImage:myImage forState:UIControlStateNormal];
        myBubble.backgroundColor = [UIColor clearColor];
        //myBubble.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [myBubble addSubview:textView];
        [textView release];
        
        // add bubble gloss
        /*UIImage *glossImage = [Utility resizableImage:[UIImage imageNamed:@"chat_icon_bubble_wh2.png"] leftCapWidth:15.0 rightCapWidth:24.0 topCapHeight:15.0 bottomCapHeight:15.0];
        UIImageView *glossView = [[UIImageView alloc] initWithImage:glossImage];
        glossView.frame = myBubble.bounds;
        glossView.backgroundColor = [UIColor clearColor];
        [myBubble addSubview:glossView];
        [glossView release];*/
        
        self.bubbleView = myBubble;
        [self addSubview:myBubble];
        [myBubble release];
    }
    // text message from others!
    else {
        
        self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;

        
        // create text view
        CGRect maxRect = CGRectMake(kMPParmBubblePaddingTail, kMPParmBubblePaddingVertical, kMPParmBubbleWidthMaxOther, 9999.0); // 225max - tail and head = 200
        TextEmoticonView *textView = [[TextEmoticonView alloc] initWithFrame:maxRect];
        textView.font = bubbleFont;
        [textView setText:self.thisMessage.text];
        [textView sizeToFit];
        CGSize expectedLabelSize = textView.frame.size;
        
        CGFloat bubbleWidth = expectedLabelSize.width + kMPParmBubblePaddingHead + kMPParmBubblePaddingTail;
        CGFloat bubbleHeight = expectedLabelSize.height + kMPParmBubblePaddingVertical*2.0;
        // min bubble Height
        if (bubbleHeight < 32.0) {
            bubbleHeight = 32.0;
        }
        if (bubbleWidth < 40) {
            bubbleWidth = 40.0;
        }
        if (bubbleWidth > 185.0) {
            bubbleWidth = 185.0;
        }
        CGFloat bubbleStartX = kMPParmMarginBase*2 + kMPParmHeadSize;

        
        UIImage *myImage = [Utility resizableImage:[UIImage imageNamed:@"chat_icon_bubble_y.png"] leftCapWidth:22.0 rightCapWidth:17.0 topCapHeight:15.0 bottomCapHeight:15.0];
        
        UIButton *myBubble = [[UIButton alloc] initWithFrame:CGRectMake(bubbleStartX, 0.0, bubbleWidth, bubbleHeight)];
        [myBubble setBackgroundImage:myImage forState:UIControlStateNormal];
        myBubble.backgroundColor = [UIColor clearColor];
        [myBubble addSubview:textView];
        [textView release];
        
        // add bubble gloss
        /*UIImage *glossImage = [Utility resizableImage:[UIImage imageNamed:@"chat_icon_bubble_y2.png"] leftCapWidth:22.0 rightCapWidth:17.0 topCapHeight:15.0 bottomCapHeight:15.0];
        UIImageView *glossView = [[UIImageView alloc] initWithImage:glossImage];
        glossView.frame = myBubble.bounds;
        glossView.backgroundColor = [UIColor clearColor];
        [myBubble addSubview:glossView];
        [glossView release];*/
        
        self.bubbleView = myBubble;
        [self addSubview:myBubble];
        [myBubble release];
        
        // add headshot
        [self addHeadshotButton];

    }

    [self addStatusViewsIsRightSide:doesBubbleStartFromRight];
    
    // mark lowest view to measure height
    self.lowestView = self.bubbleView;
    
    //label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
}


/*!
 @abstract For status animation
 
 - hides old status
 
 */
- (void) hideStatus {
    //DDLogVerbose(@"CDMV-st: hiding status %f", self.statusLabel.alpha);
    self.statusLabel.alpha = 0.0;
    
}


/*!
 @abstract For status animation
 
 - update status label & shows it
 - may need to update object?
 
 */
- (void) showStatus {
    //DDLogVerbose(@"CDMV-st: show status %f", self.statusLabel.alpha);
    self.statusLabel.text = [self.thisMessage getStateString];
    self.statusLabel.alpha = 1.0;
}

/*!
 @abstract Hide Sent Time
 
 */
- (void) showProgress {
    //self.timeLabel.alpha = 0.0;
    self.progressView.hidden = NO;
    self.progressView.alpha = 1.0;
}

/*!
 @abstract Hide Sent Time
 
 */
- (void) hideProgress {
    self.progressView.hidden = YES;
    self.progressView.alpha = 0.0;
}


/*!
 @abstract For status animation
 
 - called everytime state change occurs
 - sets status & shows it
 - may need to update object?
 
 */
- (void) showSentTime {
    
    // hide progress since upload is done
    self.progressView.alpha = 0.0;
    self.progressView.hidden = YES;
    
    // show sent time
    self.timeLabel.text = [self.thisMessage getSentTimeString];
    self.timeLabel.alpha = 1.0;
    
    // if letter change 
    // - letter changes size so adjust view positions!
    //
    if ([self.thisMessage.type intValue] == kCDMessageTypeLetter) {
        UIImage *letterImage = [self letterImageForCurrentState];
        CGSize newSize = [letterImage size];
        CGRect oldFrame = self.bubbleView.frame;
        CGFloat xOffset = oldFrame.size.width-newSize.width;
        [self.bubbleView setImage:letterImage forState:UIControlStateNormal];
        self.bubbleView.frame = CGRectMake(oldFrame.origin.x+xOffset, 
                                           oldFrame.origin.y, 
                                           newSize.width, newSize.height);
        self.timeLabel.frame = CGRectOffset(self.timeLabel.frame,xOffset, 0.0);
        self.statusLabel.frame = CGRectOffset(self.statusLabel.frame,xOffset, 0.0);
    }
    
}

#pragma mark - Button and Actions

/*!
 @abstract start action for this message
 
 Use:
 - for sticker views, start animation
 */
- (void) startAnimation {
    
    if ([self.bubbleView respondsToSelector:@selector(runAnimation)]) {
        [self.bubbleView performSelector:@selector(runAnimation)];
    }
}


/*!
 @abstract Press headshot
 - Show add friend alert view
 
 */
- (void) pressHeadShot:(id)sender{
    
    // For non friends - show pop up to add/block
    //
    CDContact *thisContact = self.thisMessage.contactFrom;
    if (![thisContact isFriend] && ![thisContact isBlockedByMe]){
        
        CGRect appFrame = [Utility appFrame];
        AddFriendAlertView *alertView = [[AddFriendAlertView alloc] initWithFrame:appFrame contact:self.thisMessage.contactFrom];
        
        UIViewController *containerVC = [[AppUtility getAppDelegate] containerController];
        [containerVC.view addSubview:alertView];
        [alertView release];
    }
}

/*!
 @abstract Press headshot
 - Show add friend alert view
 
 */
- (void) updateHeadView:(NSNotification *)notification {
    
    CDContact *updateContact = [notification object];
    
    if (self.headView && self.thisMessage.contactFrom == updateContact ) {
        UIView *plusView = [self.headView viewWithTag:PLUS_VIEW_TAG];
        plusView.hidden = YES;
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
    
    NSInteger messageType = [self.thisMessage.type intValue];

    if (messageType == kCDMessageTypeImage) {
        if (!self.fileManager) {
            TKFileManager *newFileManager = [[TKFileManager alloc] init];
            newFileManager.delegate = self;
            self.fileManager = newFileManager;
            [newFileManager release];
        }
        
        NSString *url = [self.thisMessage getDownloadURL];
        
        UIImage *fullImage = nil;
        if (url) {
            NSData *imageData = [fileManager getFileDataForFilename:self.thisMessage.filename url:url];
            fullImage = [UIImage imageWithData:imageData];
        }
        
        // ask delegate to show this image
        if (fullImage) {
            if ([self.delegate respondsToSelector:@selector(ChatDialogMessageView:showImage:)]) {
                [self.delegate ChatDialogMessageView:self showImage:fullImage];
            }
        }
        else {
            // disable button until download if finished
            [self.bubbleView setEnabled:NO];
        }
    }
    // 
    else if (messageType == kCDMessageTypeLocation) {
        
        // ask delegate to show this location coordinate
        //
        NSArray *locationInfo = [self.thisMessage.text componentsSeparatedByString:@","];
        
        // first two elements are lat and long
        if ([locationInfo count] > 1) {
            CGFloat lat = [[locationInfo objectAtIndex:0] floatValue];
            CGFloat lng = [[locationInfo objectAtIndex:1] floatValue];
            
            if ([self.delegate respondsToSelector:@selector(ChatDialogMessageView:showLocationLatitude:longitude:)]) {
                [self.delegate ChatDialogMessageView:self showLocationLatitude:lat longitude:lng];
            }
        }
    }
}

/*!
 @abstract Show Letter
 */
- (void) showLetter:(UIImage *)fullImage {
    if ([self.delegate respondsToSelector:@selector(ChatDialogMessageView:showLetter:)]) {
        [self.delegate ChatDialogMessageView:self showLetter:fullImage];
    }
}



/*!
 @abstract Press Image Bubble
 
 - If image downloaded, then get it now
 - If image available call delegate to show image
 
 */
- (void) pressLetterBubble:(id)sender {
        
    if (!self.fileManager) {
        TKFileManager *newFileManager = [[TKFileManager alloc] init];
        newFileManager.delegate = self;
        self.fileManager = newFileManager;
        [newFileManager release];
    }
    
    NSString *url = [self.thisMessage getDownloadURL];
    
    UIImage *fullImage = nil;
    if (url) {
        NSData *imageData = [fileManager getFileDataForFilename:self.thisMessage.filename url:url];
        fullImage = [UIImage imageWithData:imageData];
    }
    
    // ask delegate to show this image
    if (fullImage) {
        // un-highlight - otherwise image remains dark after being pressed
        // - maybe cause by starting animation
        [self.bubbleView setHighlighted:NO];
        [self.bubbleView.imageView startAnimating];
        [self performSelector:@selector(showLetter:) withObject:fullImage afterDelay:self.bubbleView.imageView.animationDuration];
    }
    else {
        // disable button until download if finished
        [self.bubbleView setEnabled:NO];
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
    
    [self hideProgress];
    
    // enable bubble view again after download
    [self.bubbleView setEnabled:YES];
    
    // Show image automatically
    UIImage *fullImage = [UIImage imageWithData:data];
    if (fullImage) {
        
        // show image
        if ([self.thisMessage.type intValue] == kCDMessageTypeImage) {
            if ([self.delegate respondsToSelector:@selector(ChatDialogMessageView:showImage:)]) {
                [self.delegate ChatDialogMessageView:self showImage:fullImage];
            }
        }
        // show letter
        else if ([self.thisMessage.type intValue] == kCDMessageTypeLetter) {
            [self.bubbleView.imageView startAnimating];
            [self performSelector:@selector(showLetter:) withObject:fullImage afterDelay:self.bubbleView.imageView.animationDuration];
        }
    }
}

/*!
 @abstract Called regularly when data is regularly downloaded
 
 */
- (void)TKFileManager:(TKFileManager *)fileManager bytesDownloaded:(NSUInteger)bytes expectedContentLength:(NSUInteger)expectedContentLengthBytes{
    // update download progress
    [self upateProgress:bytes isIncreamental:NO];
}

/*! 
 @abstract Delegate called when error has occurred
 @discussion Handles connection error.  No further delegate calls will be made 
 for this connection. So reset connection and received data.
 
 */
- (void)TKFileManager:(TKFileManager *)fileManager didFailWithError:(NSError *)error {
    
    // download failed
    [self hideProgress];
    
    // enable bubble view again - so we can try again
    [self.bubbleView setEnabled:YES];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/




@end
