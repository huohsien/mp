//
//  FriendInfoController.h
//  mp
//
//  Created by M Tsai on 11-12-3.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HiddenController.h"

@class CDContact;

@interface FriendInfoController : UIViewController <UIActionSheetDelegate, HiddenControllerDelegate> {

    CDContact *contact;
    
    NSNumber *operatorNumber;
}

/*! contact that is being represented */
@property (nonatomic, retain) CDContact *contact;

/*! the operator for this phone number */
@property(nonatomic, retain) NSNumber *operatorNumber;

- (id)initWithContact:(CDContact *)newContact;
@end
