//
//  PhoneBookInfoController.h
//  mp
//
//  Created by Min Tsai on 1/29/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import "HiddenController.h"

@class CDContact;
@class ContactProperty;

@interface PhoneBookInfoController : UIViewController <MFMessageComposeViewControllerDelegate, HiddenControllerDelegate, UIActionSheetDelegate> {
    
    ContactProperty *phoneProperty;
    CDContact *contact;
    NSNumber *operatorNumber;
}

/*! phone property that is represented by this cell */
@property(nonatomic, retain) ContactProperty *phoneProperty;

/*! the operator for this phone number */
@property(nonatomic, retain) NSNumber *operatorNumber;

/*! M+ friend info - if phone contact is also M+ member */
@property (nonatomic, retain) CDContact *contact;


- (id)initWithPhoneProperty:(ContactProperty *)property operatorNumber:(NSNumber *)operator mpContact:(CDContact *)newContact;

@end
