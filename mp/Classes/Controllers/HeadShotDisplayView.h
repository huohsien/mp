//
//  HeadShotDisplayView.h
//  mp
//
//  Created by Min Tsai on 2/20/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

/*!
 @header HeadShotDisplayView
 
 Shows a full screen headshot of specified contact.  This is an overlay view that fades in 
 when added and fades out when tapped.
 
 Usage:
 
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <UIKit/UIKit.h>
#import "MPImageManager.h"

@class CDContact;


@interface HeadShotDisplayView : UIImageView <MPImageManagerDelegate> {
    
    MPImageManager *imageManager;
    CDContact *contact;
        
    UIProgressView *downloadProgress;
    NSInteger currentProgress;
}

/*! helps access headshots images */
@property(nonatomic, retain) MPImageManager *imageManager;

/*! contact's image to show */
@property(nonatomic, retain) CDContact *contact;

/*! shows download progres */
@property(nonatomic, retain) UIProgressView *downloadProgress;

/*! keeps track of current progress levels */
@property (nonatomic, assign) NSInteger currentProgress;

/*!
 @abstract Initialize a Large Headshot View
 
 @param frame   Size of headshot view
 @param contact The contact whose headshot we want to display.
 
 */
- (id)initWithFrame:(CGRect)frame contact:(CDContact *)newContact;

@end