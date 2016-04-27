//
//  UISpinButton.h
//  mp
//
//  Created by M Tsai on 11-12-24.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TKSpinButton : UIButton {
    
    UIImageView *spinView;
    BOOL isSpinning;
    BOOL disableWhenSpinning;
    
}

/*! the view that spins */
@property (nonatomic, retain) UIImageView *spinView;;
@property (nonatomic, assign) BOOL isSpinning;
@property (nonatomic, assign) BOOL disableWhenSpinning;


- (id)initWithFrame:(CGRect)frame normalImage:(UIImage *)normalImage pressImage:(UIImage *)pressImage disabledImage:(UIImage *)disabledImage spinningImage:(UIImage *)spinningImage;

- (void) startSpinning;
- (void) stopSpinning;
- (void) viewWillDisappear;

@end
