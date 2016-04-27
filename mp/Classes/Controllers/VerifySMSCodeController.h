//
//  VerifySMSCodeController.h
//  mp
//
//  Created by M Tsai on 11-10-18.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VerifySMSCodeController : UIViewController <UITextFieldDelegate> {
    
    UITextField *smsCodeField;
    NSInteger resendCount;
    
}

@property (nonatomic, retain) UITextField *smsCodeField;

/*! Keep track of number of times resend was pressed - throttle this so user don't abuse */
@property (nonatomic, assign) NSInteger resendCount;

@end
