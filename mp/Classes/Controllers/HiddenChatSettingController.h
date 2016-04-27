//
//  HiddenChatSettingController.h
//  mp
//
//  Created by Min Tsai on 2/1/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HiddenController.h"

@interface HiddenChatSettingController : UIViewController <HiddenControllerDelegate> {
    
    BOOL pendingHiddenChatState;
    
}


/*! Requested Hidden state - handled when view appears */
@property (nonatomic, assign) BOOL pendingHiddenChatState;

@end
