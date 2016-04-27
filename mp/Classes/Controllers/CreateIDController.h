//
//  CreateIDController.h
//  mp
//
//  Created by M Tsai on 11-11-23.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSUInteger const kMPParamIDLengthMin;
extern NSUInteger const kMPParamIDLengthMax;

@interface CreateIDController : UIViewController <UIAlertViewDelegate, UITextFieldDelegate> {
    
    UITextField *idField;
    NSString *tempMPID;
    BOOL didPressSubmit;
    
}

@property (nonatomic, retain) UITextField *idField;

@property (nonatomic, retain) NSString *tempMPID;

/*! Indicate that submit was already pressed, don't respond to multiple taps */
@property (nonatomic, assign) BOOL didPressSubmit;


@end
