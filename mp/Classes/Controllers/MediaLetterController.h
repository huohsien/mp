//
//  MediaLetterController.h
//  mp
//
//  Created by Min Tsai on 2/8/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

/*!
 @header MediaLetterController
 
 Viewing and saving letter images
 
 Usage:
 - allocate
 - set .title - same as previous dialog
 - set .backgroundImage - give it a background same as the dialog
 
 Example:
 
 
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */


#import <UIKit/UIKit.h>

@interface MediaLetterController : UIViewController {
    
    UIImage *letterImage;
    UIImage *backgroundImage;
    
}

/*! letter image to show */
@property (nonatomic, retain) UIImage *letterImage;

/*! background image behind letter */
@property (nonatomic, retain) UIImage *backgroundImage;


- (id)initWithLetterImage:(UIImage *)newImage;

@end
