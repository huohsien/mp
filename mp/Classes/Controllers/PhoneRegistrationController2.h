//
//  PhoneRegistrationController.h
//  mp
//
//  Created by M Tsai on 11-10-14.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTURLConnection.h"
#import "CountrySelectController.h"



@interface PhoneRegistrationController2 : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, CountrySelectControllerDelegate> {
    
    NSString *countryCode;
    UIButton *countryButton;
    UITextField *phoneField;
    
    //TTURLConnection *urlConnection;
    NSMutableDictionary *countryDictionary;
    
    BOOL didAllowContactsAccess;
    
}

@property(nonatomic, retain) NSString *countryCode;
@property(nonatomic, retain) UIButton *countryButton;
@property(nonatomic, retain) UITextField *phoneField;


/*! dictionary to convert country code to name and phone code */
@property(nonatomic, retain) NSMutableDictionary *countryDictionary;

/*! did users give us permission to access contacts - must have permission to proceed */
@property(nonatomic, assign) BOOL didAllowContactsAccess;


@end
