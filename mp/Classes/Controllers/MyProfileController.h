//
//  MyProfileController.h
//  mp
//
//  Created by M Tsai on 11-11-23.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPImageManager.h"

@class MPMessage;
@class MPImageManager;

@interface MyProfileController : UIViewController <UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MPImageManagerDelegate, UIAlertViewDelegate> {
    

    NSString *pendingMessageID;
    UIImage *tempSmallImage;    
    UIImage *tempLargeImage;
    
    MPImageManager *imageManager;
    
    
}

/*! save message and images until confirmation is received from DS */
@property (nonatomic, retain) NSString *pendingMessageID;
@property (nonatomic, retain) UIImage *tempSmallImage;    
@property (nonatomic, retain) UIImage *tempLargeImage;

@property (nonatomic, retain) MPImageManager *imageManager;

@end
