//
//  NotificationController.h
//  mp
//
//  Created by Min Tsai on 2/22/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ToneController.h"


@interface NotificationController : UIViewController <ToneControllerDelegate> {
    
    BOOL isGroup;
    NSString *pendingTone;
    
}

/*! Is group notification - if not then P2P notification settings */
@property (nonatomic, assign) BOOL isGroup;

/*! Ring tone that we submitted to servers */
@property (nonatomic, retain) NSString *pendingTone;

- (id)initIsGroupNotification:(BOOL)isGroupNotification;

@end
