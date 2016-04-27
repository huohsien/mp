//
//  ScheduleInfoController.h
//  mp
//
//  Created by Min Tsai on 1/21/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

/*!
 @header ScheduleInfoController
 
 View a new scheduled message
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <UIKit/UIKit.h>
#import "SelectContactController.h"

@class CDMessage;

@interface ScheduleInfoController : UIViewController <SelectContactsControllerDelegate> {
    
    CDMessage *scheduledMessage;

}

/*! scheduled message to display */
@property (nonatomic, retain) CDMessage *scheduledMessage;

- (id) initWithScheduledMessage:(CDMessage *)newScheduledMessage;

@end