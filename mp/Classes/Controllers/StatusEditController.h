//
//  StatusEditController.h
//  mp
//
//  Created by M Tsai on 11-11-28.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StatusEditController : UIViewController <UITextViewDelegate> {
    NSString *tempStatus;
    
}

/*! save pending status update value here */
@property (nonatomic, retain) NSString *tempStatus;

@end
