//
//  NameRegistrationController.h
//  mp
//
//  Created by M Tsai on 11-10-19.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NameRegistrationController : UIViewController <UITextFieldDelegate> {
    
    UITextField *nameField;
    NSString *tempName;
    BOOL isRegistration;
    
    BOOL didDismissAlready;
    
}
@property (nonatomic, retain) UITextField *nameField;

/*! stores candidate name during server update attempt */
@property (nonatomic, retain) NSString *tempName;

/*! is this part of the registration process */
@property (nonatomic, assign) BOOL isRegistration;

/*! prevents view from being dismissed twice */
@property (nonatomic, assign) BOOL didDismissAlready;

- (id)initIsRegistration:(BOOL)registration;

@end
