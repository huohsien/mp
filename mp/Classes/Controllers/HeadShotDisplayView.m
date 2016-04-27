//
//  HeadShotDisplayView.m
//  mp
//
//  Created by Min Tsai on 2/20/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "HeadShotDisplayView.h"
#import "MPFoundation.h"
#import "CDContact.h"
#import "TextEmoticonView.h"


@implementation HeadShotDisplayView

@synthesize imageManager;
@synthesize contact;
@synthesize downloadProgress;
@synthesize currentProgress;

#define PHOTO_BACK_TAG      16001
#define STATUS_LABEL_TAG    16002
#define HEADSHOT_TAG        16003
#define ACTIVITY_TAG        16004

#define DOWNLOAD_LABEL_TAG  16005
#define BLACK_SHADE_TAG     16006


#define kProgressWidth      150.0
#define kProgressHeight     30.0
#define kBlackShadeAlpha    0.5

- (void) dealloc {
    
    imageManager.delegate = nil;
    
    [downloadProgress release];
    [contact release];
    [imageManager release];
    [super dealloc];
    
}

- (id)initWithFrame:(CGRect)frame contact:(CDContact *)newContact
{
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.contact = newContact;

        MPImageManager *newIM = [[MPImageManager alloc] init];
        newIM.delegate = self;
        self.imageManager = newIM;
        [newIM release];
        
        
        // hide view so it can fade in
        self.alpha = 0.0;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
        self.image = [UIImage imageNamed:@"friend_photo_bk.jpg"];
        self.userInteractionEnabled = YES;
        
        
        // Tap gesture to dismiss
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(pressClose:)];
        tapRecognizer.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tapRecognizer];
        [tapRecognizer release];
        
        
        // Add download label
        UILabel *downLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.frame.size.width-kProgressWidth)/2.0, 
                                                                       self.frame.size.height/2.0 - kProgressHeight, 
                                                                       kProgressWidth, kProgressHeight)];
        downLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldTiny];
        downLabel.textColor = [UIColor whiteColor];
        downLabel.textAlignment = UITextAlignmentCenter;
        downLabel.backgroundColor = [UIColor clearColor];
        downLabel.text = NSLocalizedString(@"Downloading...", @"HeadShot: Inform users that headshot image is downloading");
        downLabel.tag = DOWNLOAD_LABEL_TAG;
        downLabel.alpha = 0.0;
        [self addSubview:downLabel];
        
        UIProgressView *pView = [[UIProgressView alloc] initWithFrame:CGRectMake((self.frame.size.width-kProgressWidth)/2.0,
                                                                                 (self.frame.size.height)/2.0, kProgressWidth, kProgressHeight)];
        pView.progressViewStyle = UIProgressViewStyleDefault;
        pView.alpha = 0.0;
        [self addSubview:pView];
        self.downloadProgress = pView;
        [pView release];
        
        
        // Add name label
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 8.0, 280.0, 28.0)];
        [AppUtility configLabel:nameLabel context:kAULabelTypeNavTitle];
        nameLabel.text = [self.contact displayName];
        [self addSubview:nameLabel];
        [nameLabel release];
        
        
        // Add Photo backing
        //
        UIImageView *photoBack = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, 44.0, 310.0, 380.0)];
        photoBack.image = [UIImage imageNamed:@"friend_photo_base.png"];
        photoBack.tag = PHOTO_BACK_TAG;
        [self addSubview:photoBack];
        
        
        // Add Status Message
        //
        // create status text label
        TextEmoticonView *statusLabel = [[TextEmoticonView alloc] initWithFrame:CGRectMake(25.0, 302.0, 260.0, 41.0)];
        statusLabel.numberOfLines = 2;
        statusLabel.lineBreakMode = UILineBreakModeTailTruncation;
        statusLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
        statusLabel.textColor = [AppUtility colorForContext:kAUColorTypeLightGray1];
        statusLabel.backgroundColor = [UIColor clearColor];
        statusLabel.textAlignment = UITextAlignmentCenter;
        statusLabel.verticalAlignment = TETextVerticalAlignmentTop;
        statusLabel.tag = STATUS_LABEL_TAG;
        [statusLabel setText:self.contact.statusMessage];
        [photoBack addSubview:statusLabel];
        [statusLabel release];
        
        
        // Add Photo Image
        UIImageView *headView = [[UIImageView alloc] initWithFrame:CGRectMake(photoBack.frame.origin.x+25.0, 
                                                                              photoBack.frame.origin.y+26.0, 
                                                                              262.0, 262.0)];
                                    //CGRectMake(25.0, 26.0, 262.0, 262.0)];
        headView.tag = HEADSHOT_TAG;
        
        // Add black fade that cover photo if a new one is being downloaded
        //
        UIView *blackShadeView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 262.0, 262.0)];
        blackShadeView.backgroundColor = [UIColor blackColor];
        blackShadeView.alpha = 0.0;
        blackShadeView.tag = BLACK_SHADE_TAG;
        [headView addSubview:blackShadeView];
        [blackShadeView release];
        
        [self insertSubview:headView belowSubview:photoBack];
        
        NSString *url = [self.contact imageURLForContext:nil ignoreVersion:NO];
        
        // don't download for users own headshot
        BOOL ignoreVersion = NO; //[newContact isMySelf]?YES:NO; // @TEMP NO;  everyone should be the same
        
        UIImage *gotImage = [self.imageManager getImageForObject:self.contact context:nil ignoreVersion:ignoreVersion];
        // image already available
        if (gotImage) {
            headView.image = gotImage;
        }
        // no image to download
        else if (url == nil) {
            headView.image = [UIImage imageNamed:@"friend_headshot_large.png"];
        }
        else {
            downLabel.alpha = 1.0;
            self.downloadProgress.alpha = 1.0;
            headView.alpha = 0.0;
            photoBack.alpha = 0.0;
            
            [NSTimer scheduledTimerWithTimeInterval:25.0 target:self selector:@selector(showDownloadFailedAlert) userInfo:nil repeats:NO];
        }
        
        // bring progress views to front
        //
        [self bringSubviewToFront:downLabel];
        [self bringSubviewToFront:self.downloadProgress];
        
        [downLabel release];
        [headView release];
        [photoBack release];
    }
    return self;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */



#pragma mark - UIView

/*!
 @abstract Show view animated
 
 Use:
 - fades in view like an overaly
 
 */
- (void) showAnimated:(BOOL)animated {
    
    if (animated) {
        [UIView animateWithDuration:kMPParamAnimationStdDuration 
                         animations:^{
                             self.alpha = 1.0;
                         }];
    }
    else {
        self.alpha = 1.0;
    }
}



/*!
 @abstract Called after view added as subview
 */
- (void)didAddSubview:(UIView *)subview {
    [self showAnimated:YES];
}




#pragma mark - Button


/*!
 @abstract Dismiss this view
 */
- (void) pressClose:(id)sender {
    [UIView animateWithDuration:kMPParamAnimationStdDuration 
                     animations:^{
                         self.alpha = 0.0;
                     } 
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self removeFromSuperview];
                         }
                     }
     ];
}

#pragma mark - Image 




/*!
 @abstract Show alert if image failed to download
 */
- (void) showDownloadFailedAlert {
    
    //UIActivityIndicatorView *downloadIndicator = (UIActivityIndicatorView *)[self viewWithTag:ACTIVITY_TAG];
    //[downloadIndicator stopAnimating];
    
    UIImageView *photoView = (UIImageView *)[self viewWithTag:PHOTO_BACK_TAG];

    // if still not loaded
    if (photoView.alpha == 0.0) {
        /*[Utility showAlertViewWithTitle:nil message:NSLocalizedString(@"Image currently not available.", @"HeadShot: tell users that the image failed to download")];
        [self pressClose:nil];*/
        
        UILabel *downLabel = (UILabel *)[self viewWithTag:DOWNLOAD_LABEL_TAG];
        downLabel.text = NSLocalizedString(@"Download failed.", @"HeadShot: tell users that the image failed to download");
    }
}


/*!
 @abstract Inform delegate that we started downloading image
 
 */
- (void)MPImageManager:(MPImageManager *)imageManager didStartImageDownload:(NSString *)url {
    
    UILabel *downLabel = (UILabel *)[self viewWithTag:DOWNLOAD_LABEL_TAG];
    UIImageView *headView = (UIImageView *)[self viewWithTag:HEADSHOT_TAG];
    
    if (self.downloadProgress.alpha == 0) {
        self.downloadProgress.alpha = 1.0;
        self.currentProgress = 0;
        downLabel.alpha = 1.0;
        
        // if old headvew is showing, add shade while downloading new view
        if (headView.alpha == 1.0) {
            UIView *blackView = [self viewWithTag:BLACK_SHADE_TAG];
            blackView.alpha = kBlackShadeAlpha;
        }
    }
    
}

/*!
 @abstract Called regularly when data is regularly downloaded
 
 */
- (void)MPImageManager:(MPImageManager *)imageManager bytesDownloaded:(NSUInteger)bytes expectedContentLength:(NSUInteger)expectedContentLengthBytes {
    
    UILabel *downLabel = (UILabel *)[self viewWithTag:DOWNLOAD_LABEL_TAG];
    UIImageView *headView = (UIImageView *)[self viewWithTag:HEADSHOT_TAG];
    
    if (self.downloadProgress.alpha == 0) {
        self.downloadProgress.alpha = 1.0;
        self.currentProgress = 0;
        downLabel.alpha = 1.0;
        
        // if old headvew is showing, add shade while downloading new view
        if (headView.alpha == 1.0) {
            UIView *blackView = [self viewWithTag:BLACK_SHADE_TAG];
            blackView.alpha = kBlackShadeAlpha;
        }
    }
    
    self.currentProgress = bytes;
    
    CGFloat ratio = (CGFloat)self.currentProgress/(CGFloat)expectedContentLengthBytes;
    
    DDLogVerbose(@"HSD-up: progress %d : %d/%d = %f", bytes, self.currentProgress, expectedContentLengthBytes, ratio);
    
    // only animated for 5.0
    if ([self.downloadProgress respondsToSelector:@selector(setProgress:animated:)]) {
        [self.downloadProgress setProgress:ratio animated:YES];
    }
    else {
        [self.downloadProgress setProgress:ratio];
    }
    
    // hide progress when done
    if (ratio == 1.0) {
        self.downloadProgress.alpha = 0.0;
        downLabel.alpha = 0.0;
        headView.alpha = 1.0;
        
        UIView *blackView = [self viewWithTag:BLACK_SHADE_TAG];
        blackView.alpha = 0.0;
    }
}


/*!
 @abstract Called when data has completed loading and is ready to use.
 
 - load into headshot view
 - fade in photo
 
 */
- (void)MPImageManager:(MPImageManager *)imageManager finishLoadingImage:(UIImage *)image{
    
    if (image) {
        
        self.downloadProgress.alpha = 0.0;
        //UIActivityIndicatorView *downloadIndicator = (UIActivityIndicatorView *)[self viewWithTag:ACTIVITY_TAG];
        UIImageView *photoView = (UIImageView *)[self viewWithTag:PHOTO_BACK_TAG];
        UIImageView *headView = (UIImageView *)[self viewWithTag:HEADSHOT_TAG];
        UILabel *downLabel = (UILabel *)[self viewWithTag:DOWNLOAD_LABEL_TAG];
        UIView *blackView = [self viewWithTag:BLACK_SHADE_TAG];
        
        downLabel.hidden = YES;
        
        //[downloadIndicator stopAnimating];
        headView.image = image;
        
        [UIView animateWithDuration:kMPParamAnimationStdDuration 
                         animations:^{
                             headView.alpha = 1.0;
                             photoView.alpha = 1.0;
                             blackView.alpha = 0.0;
                         }];
    }
}

/*! 
 @abstract Delegate called when error has occurred
 @discussion Handles connection error.  No further delegate calls will be made 
 for this connection. So reset connection and received data.
 */
- (void)MPImageManager:(MPImageManager *)imageManager didFailWithError:(NSError *)error {
    
    [self showDownloadFailedAlert];
    
}


@end
