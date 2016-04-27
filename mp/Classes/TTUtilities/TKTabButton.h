//
//  TKTabButton.h
//  mp
//
//  Created by Min Tsai on 1/9/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//


/*!
 @header TKTabButton
 
 Simple tab button that can be incorporated with complex views.  This class informs its
 delegate when touchDown and touchDownRepeat happens.
 
 The delegate is responsible for changing the state of these tab views.
 
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <UIKit/UIKit.h>

@class TKTabButton;


/*!
 Delegate that can be notified when TKTabButton has interactions
 
 */
@protocol TKTabButtonDelegate <NSObject>

/*!
 @abstract Tab Button got a control event - delegate should control how tabs images changes
 */
- (void)TKTabButton:(TKTabButton *)tabButton gotControlEvent:(UIControlEvents)controlEvent;

@end




@interface TKTabButton : UIButton {
    
    id <TKTabButtonDelegate> delegate;
    NSString *normalFilename;
    NSString *selectedFilename;
    NSString *normalBackgroundFilename;
    NSString *selectedBackgroundFilename;
}

@property (nonatomic, assign) id <TKTabButtonDelegate> delegate;

/*! image when tab not selected */
@property (nonatomic, retain) NSString *normalFilename;

/*! image when tab is selected */
@property (nonatomic, retain) NSString *selectedFilename;

/*! image when tab not selected */
@property (nonatomic, retain) NSString *normalBackgroundFilename;

/*! image when tab is selected */
@property (nonatomic, retain) NSString *selectedBackgroundFilename;


- (id) initWithFrame:(CGRect)frame 
 normalImageFilename:(NSString *)newNormalFilename 
selectedImageFilename:(NSString *)newSelectedFilename 
normalBackgroundImageFilename:(NSString *)newNormalBackgroundFilename 
selectedBackgroundImageFilename:(NSString *)newSelectedBackgroundFilename;

- (void) setImagePressed:(BOOL)pressed;
- (void) setNormalImage;

@end
