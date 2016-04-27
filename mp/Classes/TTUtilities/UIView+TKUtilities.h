//
//  UIView+TKUtilities.h
//  mp
//
//  Created by Min Tsai on 2/7/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (TKUtilities)

- (UIView *)findFirstResponder;
- (void) addRoundedCornerRadius:(CGFloat)radius;
- (void) addShadow;
@end
