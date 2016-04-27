//
//  TestingController.h
//  mp
//
//  Created by Min Tsai on 2/23/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>


@interface TestingController : UIViewController <UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
    UITextField *asTextField;
    UITextField *psTextField;
    UITextField *nsTextField;

}

@property (nonatomic, retain) UITextField *asTextField;
@property (nonatomic, retain) UITextField *psTextField;
@property (nonatomic, retain) UITextField *nsTextField;

@end
