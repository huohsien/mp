//
//  LetterDisplayView.h
//  mp
//
//  Created by Min Tsai on 2/17/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LetterDisplayView;

/*!
 Delegate that handles input from this view's controls
 */
@protocol LetterDisplayViewDelegate <NSObject>


@optional

/*!
 @abstract Asks delegate (table) to forward this message
 */
- (void)LetterDisplayView:(LetterDisplayView *)view forwardImage:(UIImage *)image;

@end


@interface LetterDisplayView : UIView <UIGestureRecognizerDelegate> {
    
    id <LetterDisplayViewDelegate> delegate;
    UIImage *letterImage;
    UINavigationBar *topNavBar;
    UIToolbar *bottomToolBar;
    
}

/*! helps forward letter */
@property (nonatomic, assign) id <LetterDisplayViewDelegate> delegate;

/*! letter image to show */
@property (nonatomic, retain) UIImage *letterImage;

/*! top nav bar - used as a title bar for more controls buttons */
@property (nonatomic, retain) UINavigationBar *topNavBar;

/*! toobar to dismiss or save view */
@property (nonatomic, retain) UIToolbar *bottomToolBar;


- (id)initWithFrame:(CGRect)frame letterImage:(UIImage *)newImage;

@end