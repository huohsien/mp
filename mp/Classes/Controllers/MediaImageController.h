//
//  MediaImageController.h
//  mp
//
//  Created by Min Tsai on 1/4/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MediaImageController;

/*!
 Delegate that handles input from this view's controls
 */
@protocol MediaImageControllerDelegate <NSObject>


@optional

/*!
 @abstract Asks delegate (table) to forward this message
 */
- (void)MediaImageController:(MediaImageController *)controller forwardImage:(UIImage *)image;

@end



@interface MediaImageController : UIViewController {
    
    id <MediaImageControllerDelegate> delegate;
    UIImage *image;
    NSString *filename;
    
    NSTimer *hideBarTimer;
}

@property (nonatomic, assign) id <MediaImageControllerDelegate> delegate;

@property(nonatomic, retain) UIImage *image;
@property(nonatomic, retain) NSString *filename;
@property(nonatomic, retain) NSTimer *hideBarTimer;


- (id)initWithImage:(UIImage *)newImage title:(NSString *)newTitle filename:(NSString *)newFilename;
@end
