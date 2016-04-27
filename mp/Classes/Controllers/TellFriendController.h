//
//  TellFriendController.h
//  mp
//
//  Created by M Tsai on 11-12-2.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

/*!
 @header TellFriendController
 
 Provides tell friend options
 
 Process:
 
 
 Test case:
 - send email
 - send sms
 - send free
 - if no free, then free button should not show
 
 @copyright TernTek
 @updated 2011-11-25
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <UIKit/UIKit.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "SelectContactPropertyController.h"

@interface TellFriendController : UIViewController <SelectContactPropertyControllerDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate> {

}


@end
