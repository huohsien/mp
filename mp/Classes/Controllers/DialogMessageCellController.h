//
//  DialogMessageCellController.h
//  mp
//
//  Created by Min Tsai on 3/7/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "CellController.h"
#import "TKFileManager.h"

extern CGFloat const kDMMarginBase;

extern CGFloat const kDMBubblePaddingTail;
extern CGFloat const kDMBubblePaddingHead;
extern CGFloat const kDMBubblePaddingVertical;

extern CGFloat const kDMBubbleWidthMaxMe;
extern CGFloat const kDMBubbleWidthMaxOther;

/*!
 @header DialogMessageCellController
 
 Cell controller that represents chat messages
 
 @copyright TernTek
 @updated 2011-08-30
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */


@class DialogMessageCellController;
@class CDMessage;
@class TKFileManager;
@class TextEmoticonView;

/*!
 Delegate that handles input from this view's controls
 */
@protocol DialogMessageCellControllerDelegate <NSObject>


@optional

/*!
 @abstract Gets visible table cell for this controller
 */
- (UITableViewCell *)DialogMessageCellController:(DialogMessageCellController *)cellControlller visibleCellForMessage:(CDMessage *)message;

/*!
 @abstract Asks delegate (table) to delete this message and cell controller
 */
- (void)DialogMessageCellController:(DialogMessageCellController *)cellControlller deleteMessage:(CDMessage *)message;

/*!
 @abstract Asks delegate (table) to forward this message
 */
- (void)DialogMessageCellController:(DialogMessageCellController *)cellControlller forwardMessage:(CDMessage *)message;



/*!
 @abstract User requested a larger view of the image from this message view
 */
- (void)DialogMessageCellController:(DialogMessageCellController *)cellControlller showImage:(UIImage *)image message:(CDMessage *)message;

/*!
 @abstract User requested to read a letter
 */
- (void)DialogMessageCellController:(DialogMessageCellController *)cellControlller showLetter:(UIImage *)letterImage message:(CDMessage *)message;

/*!
 @abstract User requested to show a location
 */
- (void)DialogMessageCellController:(DialogMessageCellController *)cellControlller showLocationLatitude:(CGFloat)latitude longitude:(CGFloat)longitude;

@end





@interface DialogMessageCellController : NSObject <CellController, TKFileManagerDelegate, UIActionSheetDelegate> {
    
    id <DialogMessageCellControllerDelegate> delegate;
    CDMessage *cdMessage;
    CDMessage *previousMessage;
    
    NSInteger currentProgress;
    TKFileManager *fileManager;
    
    BOOL shouldStartAnimation;
    
    TextEmoticonView *textEmoticonView;
    
}

@property (nonatomic, assign) id <DialogMessageCellControllerDelegate> delegate;

/*! message that is represented */
@property (nonatomic, retain) CDMessage *cdMessage;

/*! preceding message */
@property (nonatomic, retain) CDMessage *previousMessage;


/*! keeps track of current progress levels */
@property (nonatomic, assign) NSInteger currentProgress;

/*! FM to download attachments */
@property (nonatomic, retain) TKFileManager *fileManager;


/*! Should start animation after being displayed */
@property (nonatomic, assign) BOOL shouldStartAnimation;

/*! Used to calculate text row height - retain so we can reuse it */
@property (nonatomic, retain) TextEmoticonView *textEmoticonView;



- (id) initWithMessage:(CDMessage *)message previousMessage:(CDMessage *)prevMessage;
- (void) updateProgress:(NSInteger)bytes isIncreamental:(BOOL)isIncreamental;
- (void) refreshHeadViewForCell:(UITableViewCell *)refreshCell animated:(BOOL)animated;

@end
