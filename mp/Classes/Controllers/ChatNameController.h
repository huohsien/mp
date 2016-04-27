//
//  ChatNameController.h
//  mp
//
//  Created by M Tsai on 11-12-27.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString* const MP_CHATNAME_UPDATE_NAME_NOTIFICATION;


@class CDChat;


@interface ChatNameController : UIViewController <UITextFieldDelegate> {

    CDChat *cdChat;
    UITextField *nameField;
    
}

@property (nonatomic, retain) CDChat *cdChat;
@property (nonatomic, retain) UITextField *nameField;

- (id)initWithCDChat:(CDChat *)newChat;

@end