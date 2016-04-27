//
//  AddFriendAlertView.h
//  mp
//
//  Created by Min Tsai on 2/24/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

/*!
 @header AddFriendAlertView
 
 Shows an overlay alert view that gives users an option to add or block a person that is 
 not already a friend.
 
 Usage:
 
 
 @copyright TernTek
 @updated 2011-10-20
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */


#import <UIKit/UIKit.h>

extern NSString* const MP_ADDFRIENDALERT_CONTACT_CHANGED_NOTIFICATION;


@class CDContact;

@interface AddFriendAlertView : UIView <UIGestureRecognizerDelegate> {
    
    CDContact *contact;
    
}

/*! toobar to dismiss or save view */
@property (nonatomic, retain)  CDContact *contact;

- (id)initWithFrame:(CGRect)frame contact:(CDContact *)contact;

@end