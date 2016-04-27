//
//  SettingButton.h
//  mp
//
//  Created by Min Tsai on 2/22/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

/*!
 @header SettingButton
 
 Standard settings button for M+.
 
 Format:
 - Title:           Title is on the left side of button
 - setValueText:    Shows a text label on the right side
 - setValueBOOL:    Shows a switch control on right side
 - setCheckOn:      Shows a check view on right side
 
 Usage:
 
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <UIKit/UIKit.h>

extern CGFloat const kSBButtonWidth;
extern CGFloat const kSBButtonHeight;

/*!
 @abstract Visual Type of Button
 
 Single     Independent row
 Top        Top row in group
 Center     Center row in group
 Bottom     Bottom row in group
 
 */
typedef enum {
    
    kSBButtonTypeSingle,
    kSBButtonTypeTop,
    kSBButtonTypeCenter,
    kSBButtonTypeBottom,
    
} SBButtonType;

@interface SettingButton : UIButton{
    
    //SBButtonType buttonType;
    
    id sbTarget;
    SEL sbSelector;
    UILabel *valueLabel;
    UISwitch *valueSwitch;
    
    UIImageView *arrowView;
    UIImageView *checkView;
}


/*! Target for button */
@property (nonatomic, assign) id sbTarget;

/*! Selector to perform on target */
@property (nonatomic, assign) SEL sbSelector;

/*! How button background should look */
//@property (nonatomic, assign) SBButtonType buttonType;

/*! Label showing the string value of setting row */
@property (nonatomic, retain) UILabel *valueLabel;

/*! Switch representing bool values */
@property (nonatomic, retain) UISwitch *valueSwitch;

/*! Disclosure arrow - indicate another view behind this row */
@property (nonatomic, retain)  UIImageView *arrowView;

/*! Check mark - indicate that this row is selected */
@property (nonatomic, retain)  UIImageView *checkView;


- (id) initWithOrigin:(CGPoint)originPoint buttonType:(SBButtonType)buttonType target:(id)newTarget selector:(SEL)newSelector title:(NSString *)newTitle showArrow:(BOOL)showArrow;

- (void) setButtonType:(SBButtonType)buttonType;
- (void) setValueText:(NSString *)valueText;
- (void) setValueBOOL:(BOOL)valueBOOL animated:(BOOL)animated;
- (void) setCheckOn:(BOOL)checkBOOL;

@end
