//
//  HiddenController.h
//  mp
//
//  Created by Min Tsai on 2/1/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HiddenChatView.h"


@class HiddenController;

@protocol HiddenControllerDelegate <NSObject>

@optional;

/*!
 @abstract Notifiy Delegate that unlock was successful
 */
- (void)HiddenController:(HiddenController *)controller unlockDidSucceed:(BOOL)didSucceed;

@end


@interface HiddenController : UIViewController <HiddenChatViewDelegate> {
    
    id <HiddenControllerDelegate> delegate;
    HCViewStatus hcStatus;
    HiddenChatView *hiddenChatView;
    
}

/*! delegate */
@property (nonatomic, assign) id <HiddenControllerDelegate> delegate;

/*! mode that we are using HC view */
@property (nonatomic, assign) HCViewStatus hcStatus;

/*! actual working view to manage hidden chat */
@property (nonatomic, retain) HiddenChatView *hiddenChatView;

- (id)initWithHCStatus:(HCViewStatus)newStatus;

@end
