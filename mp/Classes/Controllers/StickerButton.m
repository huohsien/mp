//
//  StickerButton.m
//  mp
//
//  Created by Min Tsai on 1/13/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "StickerButton.h"
#import "TKFileManager.h"
#import "MPResourceCenter.h"
#import "CDResource.h"
#import "MPFoundation.h"

@implementation StickerButton

@synthesize stickerResource;

@synthesize animationTimer;
@synthesize animationFiles;
@synthesize animationDurations;

@synthesize currentAnimationIndex;
@synthesize totalNumberOfImages;

@synthesize nextImage;
@synthesize loadImage;
@synthesize fileManager;

@synthesize isMissingImageFile;
//@synthesize firstImageView;
//@synthesize lastImageView;

-(void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // stop animation
    [animationTimer invalidate];
    
    fileManager.delegate = nil;
    
    [nextImage release];
    [loadImage release];
    
    [animationTimer release];
    [animationFiles release];
	[animationDurations release];
    [stickerResource release];
    [fileManager release];
    
    //[firstImageView release];
    //[lastImageView release];
	[super dealloc];
}


/*!
 @abstract gets the UIImage for this index
 
 @return nil if fail, UIImage if successful
  
 */
- (id) imageForIndex:(NSUInteger)index
{
    if ([self.animationFiles count] > index) {
        NSString *imageName = [self.animationFiles objectAtIndex:index];
        
        if ([imageName length] > 0) {
            UIImage *resourceImage = [self.fileManager getImageForFilename:imageName];
            return resourceImage;
        }
    }
    return nil;
}


/*!
 @abstract Set sticker attribute
 */
- (void) setStickerResource:(CDResource *)newResource {

    // stop animation in case it was running
    // - and make sure it is visible for new cell
    [self.animationTimer invalidate];
    self.alpha = 1.0;
    
    [newResource retain];
    [stickerResource release];
    stickerResource = newResource;
    
    self.currentAnimationIndex = 0; // start at -1 so we will load the first image
    
    self.animationFiles = [newResource.animationFiles componentsSeparatedByString:@","];
    self.totalNumberOfImages = [self.animationFiles count];
    
    NSMutableArray *newArray = [[NSMutableArray alloc] init];
    self.animationDurations = newArray;
    [newArray release];
    
    NSArray *durations = [newResource.animationDuration componentsSeparatedByString:@","]; // ms time
    for (NSString *iDuration in durations) {
        CGFloat interval = [iDuration intValue]/1000.0;
        [self.animationDurations addObject:[NSNumber numberWithFloat:interval]];
    }
    
    UIImage *startImage = [self imageForIndex:0];
    
    // show temp sticker and mark as missing file
    // - resource must be valid first
    if (!startImage && self.stickerResource) {
        self.isMissingImageFile = YES;
        startImage = [UIImage imageNamed:@"stk_nosticker.png"];
        
        // check if we just downloaded my image
        //
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidDownload:) name:MP_RESOURCECENTER_DID_DOWNLOAD_RESOURCE_NOTIFICATION object:nil];
        
        // start download
        //
        [[MPResourceCenter sharedMPResourceCenter] downloadResource:self.stickerResource force:YES isRetry:NO addPending:YES];
    }
    
    if (startImage) {
        [self setImage:startImage forState:UIControlStateNormal];
        
        // resize button to fit image size
        //
        CGSize imageSize = [startImage size];
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, imageSize.width, imageSize.height);
        
        /*// setup first image view
        self.firstImageView.image = startImage;
        self.firstImageView.frame = CGRectMake(0.0, 0.0, imageSize.width, imageSize.height);
        
        // setup first image view
        self.lastImageView.frame = CGRectMake(0.0, 0.0, imageSize.width, imageSize.height);
        */
    }
    
    // load next 2 images - ideally animation will be smoother
    //
    self.nextImage = [self imageForIndex:self.currentAnimationIndex+1];
    self.loadImage = [self imageForIndex:self.currentAnimationIndex+2];
    
    [self addTarget:self action:@selector(runAnimation) forControlEvents:UIControlEventTouchUpInside];
    [self setNeedsDisplay];
}

/*!
 @abstract init method
 
 @param frame can set to any size, this method will resize so that it fits the image exactly
 
 */
- (id) initWithFrame:(CGRect)frame resource:(CDResource *)newResource
{
	if ((self = [super initWithFrame:frame])) {
        
        TKFileManager *newFM = [[TKFileManager alloc] initWithDirectory:kRCFileCenterDirectory];
        self.fileManager = newFM;
        [newFM release];
        
		self.stickerResource = newResource;
        
        [self setTitleColor:[AppUtility colorForContext:kAUColorTypeLightGray1] forState:UIControlStateNormal];
        self.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandard];
        
        self.isMissingImageFile = NO;
        
        /*UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        imageView.alpha = 0.0;
        [self addSubview:imageView];
        self.firstImageView = imageView;
        [imageView release];
        
        UIImageView *imageViewLast = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        imageViewLast.alpha = 0.0;
        [self addSubview:imageViewLast];
        self.lastImageView = imageViewLast;
        [imageViewLast release];*/
        
    }
	return self;	
}


/*
 @abstract Reset to first image
 */
- (void) resetToStart {
    
    self.currentAnimationIndex = 0;
    UIImage *startImage = [self imageForIndex:0];
    if (startImage) {
        [self setImage:startImage forState:UIControlStateNormal];
    }
    
    // load next 2 images - ideally animation will be smoother
    //
    self.nextImage = [self imageForIndex:self.currentAnimationIndex+1];
    self.loadImage = [self imageForIndex:self.currentAnimationIndex+2];
    
}

/*!
 @abstract
 */
- (void) runAnimation {
    
    // animation is not needed
    if (self.totalNumberOfImages < 2) {
        return;
    }
    
    // if not last image yet
    // - keep going
    //
    if (self.currentAnimationIndex < self.totalNumberOfImages) {
        
        // update images
        //
        [self setImage:self.nextImage forState:UIControlStateNormal];
        self.currentAnimationIndex++;
        self.nextImage = self.loadImage;
        
        // Setup next animation
        // - still animation durations left
        // - next frame is available
        //
        if ([self.animationDurations count] > self.currentAnimationIndex &&
            self.nextImage ) {
            CGFloat frameDuration = [[self.animationDurations objectAtIndex:self.currentAnimationIndex] floatValue];
            
            // start timer
            [self.animationTimer invalidate];
            self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:frameDuration 
                                                                   target:self 
                                                                 selector:@selector(runAnimation) 
                                                                 userInfo:nil 
                                                                  repeats:NO];
            DDLogVerbose(@"SB: duration: %f", frameDuration);
            
            // preloads next-next image
            self.loadImage = [self imageForIndex:self.currentAnimationIndex+2];
        }
        // Can't animate further: at last frame
        // - no more images or durations left
        //
        else {
            
            // use last animation duration
            CGFloat lastDuration = [[self.animationDurations lastObject] floatValue];
            
            if (lastDuration < 0.01) {
                lastDuration = kMPParamAnimationStdDuration;
            }
            //lastDuration = 0.7;
            
            // start timer
            [self.animationTimer invalidate];
            self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:lastDuration 
                                                                   target:self 
                                                                 selector:@selector(resetToStart) 
                                                                 userInfo:nil 
                                                                  repeats:NO];
            
            
            /*lastImageView.image = self.imageView.image;
            lastImageView.alpha = 1.0;
            [self setImage:nil forState:UIControlStateNormal];
            
            
            // fade to last image
            [UIView animateWithDuration:lastDuration
                             animations: ^{
                                 self.firstImageView.alpha = 1.0;
                                 self.lastImageView.alpha = 0.0;
                                 self.alpha = 1.0;
                             }
             
                             completion:^(BOOL finished) {
                                 if (finished) {
                                     
                                     [self resetToStart];
                                     //self.firstImageView.alpha = 0.0;            
                                 }
                             }]; */
            
           /* - fade out and fade in first image

            [UIView animateWithDuration:1.0
                             animations: ^{
                                 self.alpha = 0.0;
                             }
             
                             completion:^(BOOL finished) {
                                 if (finished) {
                                     
                                     self.currentAnimationIndex = 0;
                                     UIImage *startImage = [self imageForIndex:0];
                                     if (startImage) {
                                         [self setImage:startImage forState:UIControlStateNormal];
                                     }
                                     
                                     // load next 2 images - ideally animation will be smoother
                                     //
                                     self.nextImage = [self imageForIndex:self.currentAnimationIndex+1];
                                     self.loadImage = [self imageForIndex:self.currentAnimationIndex+2];
                                     
                                     [UIView animateWithDuration:1.0
                                                      animations: ^{
                                                          self.alpha = 1.0;
                                                      }];             
                                 }
                             }];*/
        }
        
    }
    // reset to start
    else {
        [self resetToStart];
    }
}

#pragma mark - Download

/*!
 @abstract Try loading the resource we have again
 */
- (void) reloadResource {
    
    if (self.isMissingImageFile) {
        [self setStickerResource:self.stickerResource];
    }
    
}

/*!
 @abstract check if the download resource is ours and udpate view appropriately
 */
- (void) handleDidDownload:(NSNotification *)notification {
    
    NSManagedObjectID *resourceID = [notification object];
    
    if ([resourceID isEqual:[self.stickerResource objectID]]) {
        
        DDLogVerbose(@"SB: reloading sticker %@", self.stickerResource.text);
        
        // reset sticker since images are now available
        // - add delay since unzip may be threaded, so the file may not be available right away
        //
        [self performSelector:@selector(reloadResource) withObject:nil afterDelay:1.0];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}


@end
