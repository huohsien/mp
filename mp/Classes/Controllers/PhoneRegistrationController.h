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



@interface PhoneRegistrationController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, CountrySelectControllerDelegate> {
    
    UITextField *countryCodeField;
    UIButton *countryButton;
    UITextField *phoneField;

    //TTURLConnection *urlConnection;
    NSMutableDictionary *countryDictionary;
    
    
}

@property(nonatomic, retain) UITextField *countryCodeField;
@property(nonatomic, retain) UIButton *countryButton;
@property(nonatomic, retain) UITextField *phoneField;


/*! dictionary to convert country code to name and phone code */
@property(nonatomic, retain) NSMutableDictionary *countryDictionary;


//@property(nonatomic, retain) TTURLConnection *urlConnection;

@end
