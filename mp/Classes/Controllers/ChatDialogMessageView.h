//
//  ChatDialogMessageView.h
//  mp
//
//  Created by M Tsai on 11-12-12.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

/*!
 @header ChatDialogMessageView
 
 Creates view that represents a CDMessage
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <UIKit/UIKit.h>
#import "TKFileManager.h"




@class ChatDialogMessageView;

/*!
 Delegate that handles input from this view's controls
 
 */
@protocol ChatDialogMessageViewDelegate <NSObject>


@optional
/*!
 @abstract User requested a larger view of the image from this message view
 */
- (void)ChatDialogMessageView:(ChatDialogMessageView *)messageView showImage:(UIImage *)image;

/*!
 @abstract User requested to read a letter
 */
- (void)ChatDialogMessageView:(ChatDialogMessageView *)messageView showLetter:(UIImage *)letterImage;

/*!
 @abstract User requested to show a location
 */
- (void)ChatDialogMessageView:(ChatDialogMessageView *)messageView showLocationLatitude:(CGFloat)latitude longitude:(CGFloat)longitude;

@end



@class CDMessage;
@class TKFileManager;

@interface ChatDialogMessageView : UIView <TKFileManagerDelegate> {
    
    id <ChatDialogMessageViewDelegate> delegate;
    id thisObject;
    UIView *lowestView;
    
    CDMessage *thisMessage;
    ChatDialogMessageView *previousView;
    
    CGFloat lastHeight;
    
    UIButton *headView;
    UIButton *bubbleView;
    
    UILabel *statusLabel;
    UILabel *timeLabel;
    UIProgressView *progressView;
    NSInteger currentProgress;
    
    TKFileManager *fileManager;
    
}

/*! delegate to call if message needs to do something with it's content */
@property (nonatomic, assign) id <ChatDialogMessageViewDelegate> delegate;

/*! alternative to message - this object is represented by this message view */
@property (nonatomic, retain) id thisObject;

/*! what is the lowest view - used to measure bottom of view */
@property (nonatomic, retain) UIView *lowestView;


/*! message that is represented */
@property (nonatomic, retain) CDMessage *thisMessage;

/*! message written just before this one */
@property (nonatomic, retain) ChatDialogMessageView *previousView;

/*! the bottom of the previous view - used to calc where we should start */
@property (nonatomic, assign) CGFloat lastHeight;

/*! headshot view */
@property (nonatomic, retain) UIButton *headView;

/*! bubble for text */
@property (nonatomic, retain) UIButton *bubbleView;

/*! status indicator */
@property (nonatomic, retain) UILabel *statusLabel;

/*! sent time indicator */
@property (nonatomic, retain) UILabel *timeLabel;

/*! progress of upload or download */
@property (nonatomic, retain) UIProgressView *progressView;

/*! keeps track of current progress levels */
@property (nonatomic, assign) NSInteger currentProgress;

/*! FM to download attachments */
@property (nonatomic, retain) TKFileManager *fileManager;


- (CGFloat) getBottomHeight;

- (id)initWithMessage:(CDMessage *)newThisMessage object:(id)newObject previousView:(ChatDialogMessageView *)newPreviousView lastHeight:(CGFloat)newLastHeight;

- (void) configureViewDialogWidth:(CGFloat)dialogWidth;


// animation
- (void) hideStatus;
- (void) showStatus;
- (void) showSentTime;
- (void) upateProgress:(NSUInteger)bytes isIncreamental:(BOOL)isIncreamental;

- (void) startAnimation;

@end
