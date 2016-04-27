//
//  FindIDController.h
//  mp
//
//  Created by M Tsai on 11-11-29.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

/*!
 @header FindIDController
 
 Searches for a given M+ID from servers
 
 Process:
  - submit search to server and get userID
  - query for user info using userID and get Nickname
  - query for headshot
  - then display user that was found
 
 Test case:
  - no user ID
  - found user ID and Add
  - no network available
    ~ find ID
    ~ add contact - should not add if no network!
 
 @copyright TernTek
 @updated 2011-11-25
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <UIKit/UIKit.h>
#import "TKFileManager.h"
#import "MPImageManager.h"

@class MPPresence;
@class MPImageManager;
@class CDContact;

@interface FindIDController : UIViewController <UITextFieldDelegate, MPImageManagerDelegate, UIGestureRecognizerDelegate> {
    
    CDContact *foundContact;
    UIImage *foundHeadshot;
    
    UITextField *idField;
    UIView *resultView;
    
    MPImageManager *imageManager;
}

@property (nonatomic, retain) UITextField *idField;

/*! create a contact for the person found */
@property (nonatomic, retain) CDContact *foundContact;
@property (nonatomic, retain) UIImage *foundHeadshot;

@property (nonatomic, retain) UIView *resultView;

/*! helps access headshots for friends */
@property(nonatomic, retain) MPImageManager *imageManager;


@end
