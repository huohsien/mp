//
//  FontController.h
//  mp
//
//  Created by M Tsai on 11-12-6.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

/*!
 @header FontController
 
 Allow users to font size of chat messages.
 
 Sends out notification when font size is change to let chat dialog VC to reload with different font.
 
 @copyright TernTek
 @updated 2011-11-25
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <UIKit/UIKit.h>

extern NSString* const MP_FONT_CHANGE_NOTIFICATION;

@interface FontController : UIViewController

@end
