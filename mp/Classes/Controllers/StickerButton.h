//
//  StickerButton.h
//  mp
//
//  Created by Min Tsai on 1/13/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CDResource;
@class TKFileManager;

@interface StickerButton : UIButton {
    
    CDResource *stickerResource;
    
    NSTimer *animationTimer;
    
    NSArray *animationFiles;
    NSMutableArray *animationDurations;
    
    NSUInteger totalNumberOfImages;
    NSUInteger currentAnimationIndex;
    
    UIImage *nextImage;
    UIImage *loadImage;
        
    TKFileManager *fileManager;
    //UIImageView *animationView;
    
    BOOL isMissingImageFile;
    
    //UIImageView *firstImageView;
    //UIImageView *lastImageView;
    
}

@property (nonatomic, retain) CDResource *stickerResource;
@property (nonatomic, retain) NSArray *animationFiles;


/*! timer to run animation */
@property (nonatomic, retain) NSTimer *animationTimer;

/*! view that will run the animation */
//@property (nonatomic, retain) UIImageView *animationView;

/*! how long each frame will show for - no duration for last frame */
@property (nonatomic, retain) NSMutableArray *animationDurations;

/*! number of images to animate */
@property (nonatomic, assign) NSUInteger totalNumberOfImages;

/*! the current file index that is showing */
@property (nonatomic, assign) NSUInteger currentAnimationIndex;

/*! view to set as the next image */
@property (nonatomic, retain) UIImage *nextImage;

/*! view to preload as 3rd image */
@property (nonatomic, retain) UIImage *loadImage;

/*! file manager to help download files */
@property (nonatomic, retain) TKFileManager *fileManager;

/*! Image file is not available - probably not downloaded yet */
@property (nonatomic, assign) BOOL isMissingImageFile;

/*! Used to fade back to first image */
//@property (nonatomic, retain) UIImageView *firstImageView;
//@property (nonatomic, retain) UIImageView *lastImageView;



- (id) initWithFrame:(CGRect)frame resource:(CDResource *)newResource;
- (void) runAnimation;

@end
