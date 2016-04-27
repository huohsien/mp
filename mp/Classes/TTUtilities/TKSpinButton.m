//
//  UISpinButton.m
//  mp
//
//  Created by M Tsai on 11-12-24.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "TKSpinButton.h"
#import <QuartzCore/QuartzCore.h>

@implementation TKSpinButton

@synthesize spinView;
@synthesize isSpinning;
@synthesize disableWhenSpinning;

- (void) dealloc {
    
    [spinView.layer removeAllAnimations];
    [spinView release];
    [super dealloc];
    
}

/*!
 @abstract initialize the spinning button
 
 @param spinningImage the image we should start spinning after pressing this
 */
- (id)initWithFrame:(CGRect)frame normalImage:(UIImage *)normalImage pressImage:(UIImage *)pressImage disabledImage:(UIImage *)disabledImage spinningImage:(UIImage *)spinningImage 
{
    
    // must call initWithFrame!
    self = [super initWithFrame:frame];
    if (self) {
        
        self.isSpinning = NO;
        
        // set background images
        [self setBackgroundImage:normalImage forState:UIControlStateNormal];
        [self setBackgroundImage:pressImage forState:UIControlStateHighlighted];
        [self setBackgroundImage:disabledImage forState:UIControlStateDisabled];

        UIImageView *newSpinView = [[UIImageView alloc] initWithImage:spinningImage];
        newSpinView.frame = CGRectMake(0.0, 0.0, 30.0, 20.0);
        newSpinView.center = CGPointMake(self.frame.size.width/2.0, self.frame.size.height/2.0);
        newSpinView.userInteractionEnabled = NO;
        self.spinView = newSpinView;
        [self addSubview:self.spinView];
        [newSpinView release];
        
    }
    return self;
}

#define RADIANS(degrees) ((degrees * M_PI) / 180.0)

NSString* const kSpinAnimationKey = @"rotationAnimation";


/*!
 @abstract Pauses the spin animation
 */
- (void) pauseAnimation {
    CFTimeInterval pausedTime = [self.spinView.layer convertTime:CACurrentMediaTime() fromLayer:nil];
    self.spinView.layer.speed = 0.0;
    self.spinView.layer.timeOffset = pausedTime;
}

/*!
 @abstract Resume animation
 */
- (void) resumeAnimation {
    CFTimeInterval pausedTime = [self.spinView.layer timeOffset];
    self.spinView.layer.speed = 1.0;
    self.spinView.layer.timeOffset = 0.0;
    self.spinView.layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [self.spinView.layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    self.spinView.layer.beginTime = timeSincePause;
}

/*!
 @abstract Start spinning
 */
- (void) addSpinAnimation {
    
    [self.spinView.layer removeAllAnimations];
    
    // Rotate about the z axis
    CABasicAnimation* rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    
    // specify rotation angle
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 ];
    
    rotationAnimation.duration = 1.0;    
    rotationAnimation.repeatCount = HUGE_VALF;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    // Add animation to the layer and make it so
    [self.spinView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    
    // resume layer animation in case it was paused for some reason
    [self resumeAnimation];
}

/*!
 @abstract Start spinning
 */
- (void) startSpinning {
    
    self.isSpinning = YES;
    
    
    CABasicAnimation* rotationAnimation = (CABasicAnimation *)[self.spinView.layer animationForKey:kSpinAnimationKey];

    // resume rotation
    if (rotationAnimation) {
        [self resumeAnimation];
    }
    // add one if not present
    else {
        [self addSpinAnimation];
    }

}



/*!
 @abstract Stops spinning
 */
- (void) stopSpinning {
    
    // only stop if needed
    if (self.isSpinning) {
        // Add a delay so fast replies still rotate a little
        //
        [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(pauseAnimation) userInfo:nil repeats:NO];
    }
    
    self.isSpinning = NO;
}


/*!
 @abstract Call this if view will disappear
 - We need to remove the animation otherwise it will be broken when we the view shows again.
 
 */
- (void) viewWillDisappear {
    
    [self.spinView.layer removeAllAnimations];
}


@end
