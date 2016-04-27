//
//  UIView+TKUtilities.m
//  mp
//
//  Created by Min Tsai on 2/7/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "UIView+TKUtilities.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIView (TKUtilities)

/*!
 @abstract Finds the current first responder if it is a subview
 */
- (UIView *)findFirstResponder
{
    if (self.isFirstResponder) {        
        return self;     
    }
    
    for (UIView *subView in self.subviews) {
        UIView *firstResponder = [subView findFirstResponder];
        
        if (firstResponder != nil) {
            return firstResponder;
        }
    }
    
    return nil;
}

/*!
 @abstract Adds rounded corners to this view
 */
- (void) addRoundedCornerRadius:(CGFloat)radius
{
    if (radius > 0.0) {
        [self.layer setMasksToBounds:YES];
        [self.layer setCornerRadius:radius];        
        //[self.layer setBorderColor:[RGB(180, 180, 180) CGColor]];
        //[self.layer setBorderWidth:1.0f];
    }
    return;
}

/*!
 @abstract Adds shadow
 */
- (void) addShadow
{
    [self.layer setShadowColor:[[UIColor blackColor] CGColor] ];
    [self.layer setShadowOffset:CGSizeMake(0, 0)];
    [self.layer setShadowOpacity:1];
    [self.layer setShadowRadius:2.0];
    
    self.layer.masksToBounds = NO;
    
    return;
}

@end
