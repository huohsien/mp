//
//  ProgressOverlayView.m
//  mp
//
//  Created by Min Tsai on 5/1/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "ProgressOverlayView.h"
#import "MPFoundation.h"

#define kProgressWidth      150.0
#define kProgressHeight     30.0

@implementation ProgressOverlayView

@synthesize messageID;
@synthesize progressView;

@synthesize currentBytes;
@synthesize totalBytes;


- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [messageID release];
    [progressView release];
    
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame messageID:(NSString *)msgID totalSize:(NSUInteger)totalSize
{
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.currentBytes = 0;
        self.totalBytes = totalSize;
        
        self.messageID = msgID;
        
        // upload progress updates
        //
        [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(updateMessageProgress:) name:MP_SOCKETCENTER_WRITE_PROGRESS_NOTIFICATION object:nil];
        
        
        // setup background
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        
        // Add message label
        //
        UILabel *msgLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.frame.size.width-kProgressWidth)/2.0, 
                                                                       self.frame.size.height/2.0 - kProgressHeight, 
                                                                       kProgressWidth, kProgressHeight)];
        msgLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldTiny];
        msgLabel.textColor = [UIColor whiteColor];
        msgLabel.textAlignment = UITextAlignmentCenter;
        msgLabel.backgroundColor = [UIColor clearColor];
        msgLabel.text = NSLocalizedString(@"Uploading...", @"ProgressOverlay: Inform users of upload progress");
        //msgLabel.tag = DOWNLOAD_LABEL_TAG;
        [self addSubview:msgLabel];
        [msgLabel release];
        
        // add progress view
        //
        UIProgressView *pView = [[UIProgressView alloc] initWithFrame:CGRectMake((self.frame.size.width-kProgressWidth)/2.0,
                                                                                 (self.frame.size.height)/2.0, kProgressWidth, kProgressHeight)];
        pView.progressViewStyle = UIProgressViewStyleDefault;
        pView.alpha = 1.0;
        [self addSubview:pView];
        self.progressView = pView;
        [pView release];
    
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

#pragma mark - Progress


/*!
 @abstract Update the progress bar
 
 @param bytes amount of data already sent or received
 @param isIncreamental bytes will add incrementally, NO if bytes are the amount downloaded so far
 Note:
 - if 0 or 100% then bar will disappear
 
 */
- (void)updateProgress:(NSInteger)bytes isIncreamental:(BOOL)isIncreamental{
    
    if (isIncreamental) {
        self.currentBytes += bytes;
    }
    else {
        self.currentBytes = bytes;
    }
    
    CGFloat ratio = (CGFloat)self.currentBytes/(CGFloat)self.totalBytes;
    
    // write complete sends -1 as bytes
    //
    if (bytes == -1) {
        ratio = 1.0;
    }
    
    DDLogVerbose(@"POV-up: progress %d : %d/%d = %f", bytes, self.currentBytes, self.totalBytes, ratio);
    
    // only animated for 5.0
    if ([self.progressView respondsToSelector:@selector(setProgress:animated:)]) {
        [self.progressView setProgress:ratio animated:YES];
    }
    else {
        [self.progressView setProgress:ratio];
    }
}


/*!
 @abstract Search for a matching message and update it's progress
 
 */
- (void) updateMessageProgress:(NSNotification *)notification {
    
    
    NSDictionary *userInfo  = [notification userInfo];
    
    NSNumber *tag = [userInfo valueForKey:kMPSCUserInfoKeyTag];
    NSNumber *bytes = [userInfo valueForKey:kMPSCUserInfoKeyBytes];
    
    if ([self.messageID hasSuffix:[tag stringValue]]) {
        [self updateProgress:[bytes integerValue] isIncreamental:YES];
    }
}


@end
