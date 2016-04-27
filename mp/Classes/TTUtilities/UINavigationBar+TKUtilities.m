//
//  UINavigationBar+TKUtilities.m
//  mp
//
//  Created by M Tsai on 11-11-24.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "UINavigationBar+TKUtilities.h"
#import "AppUtility.h"
@implementation UINavigationBar (TKUtilities)


- (void)tkInsertSubview:(UIView *)view atIndex:(NSInteger)index
{
    [self tkInsertSubview:view atIndex:index];
    
    UIView *backgroundImageView = [self viewWithTag:kMPNavBarImageTag];
    if (backgroundImageView != nil)
    {
        [self tkSendSubviewToBack:backgroundImageView];
    }
}

- (void)tkSendSubviewToBack:(UIView *)view
{
    [self tkSendSubviewToBack:view];
    
    UIView *backgroundImageView = [self viewWithTag:kMPNavBarImageTag];
    if (backgroundImageView != nil)
    {
        [self tkSendSubviewToBack:backgroundImageView];
    }
}

@end