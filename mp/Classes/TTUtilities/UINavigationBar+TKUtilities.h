//
//  UINavigationBar+TKUtilities.h
//  mp
//
//  Created by M Tsai on 11-11-24.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationBar (TKUtilities)

- (void)tkInsertSubview:(UIView *)view atIndex:(NSInteger)index;
- (void)tkSendSubviewToBack:(UIView *)view;

@end


