//
//  SettingButton.m
//  mp
//
//  Created by Min Tsai on 2/22/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "SettingButton.h"
#import "AppUtility.h"


CGFloat const kSBButtonWidth = 310.0;
CGFloat const kSBButtonHeight = 45.0;


@implementation SettingButton 

//@synthesize buttonType;

@synthesize sbTarget;
@synthesize sbSelector;

@synthesize valueLabel;
@synthesize valueSwitch;
@synthesize arrowView;
@synthesize checkView;

- (void) dealloc {
    
    [valueLabel release];
    [valueSwitch release];
    [arrowView release];
    [checkView release];
    
    [super dealloc];
}



/*!
 @abstract Configures the button type and appearance
 
 */
- (void) setButtonType:(SBButtonType)buttonType {
    
    NSString *normalString = @"std_icon_textbar_nor.png";
    NSString *pressString = @"std_icon_textbar_prs.png";
    
    switch (buttonType) {
        case kSBButtonTypeTop:
            normalString = @"profile_statusfield_top_nor.png";
            pressString = @"profile_statusfield_top_prs.png";
            break;
        case kSBButtonTypeCenter:
            normalString = @"profile_statusfield_center_nor.png";
            pressString = @"profile_statusfield_center_prs.png";
            break;
        case kSBButtonTypeBottom:
            normalString = @"profile_statusfield_bottom_nor.png";
            pressString = @"profile_statusfield_bottom_prs.png";
            break;
        default:
            break;
    }
    
    [self setBackgroundImage:[UIImage imageNamed:normalString] forState:UIControlStateNormal];
    [self setBackgroundImage:[UIImage imageNamed:pressString] forState:UIControlStateHighlighted];
    
}

/*!
 @abstract Button Init
 
 @param offsetPoint     The origin of button - size is fixed using constants
 @param target          Button target for selector
 @param selector        Action to perform on target
 @param title           Title of button
 @param showArrow       Should show detailed disclosure arrow
 
 */
- (id) initWithOrigin:(CGPoint)originPoint buttonType:(SBButtonType)buttonType target:(id)newTarget selector:(SEL)newSelector title:(NSString *)newTitle showArrow:(BOOL)showArrow
{
    CGRect frame = CGRectMake(originPoint.x, originPoint.y, kSBButtonWidth, kSBButtonHeight);
    
	if ((self = [super initWithFrame:frame])) {
        
        self.sbTarget = newTarget;
        self.sbSelector = newSelector;
        
        [self addTarget:newTarget action:newSelector forControlEvents:UIControlEventTouchUpInside];
        [self setTitle:newTitle forState:UIControlStateNormal];
        
        [self setButtonType:buttonType];
        
        self.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
        self.opaque = YES;
        
        [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
        
        [self setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [self setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [self setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 20.0)];
        self.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
        
        if (showArrow) {
            // add arrow view
            UIImageView *arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_icon_arrow.png"]];
            CGFloat arrowStartX = kSBButtonWidth - 18.0;
            arrow.frame = CGRectMake(arrowStartX, 15.0, 8.0, 14.0);
            arrow.backgroundColor = [UIColor clearColor];
            //arrow.opaque = YES;
            [self addSubview:arrow];
            self.arrowView = arrow;
            [arrow release];
        }
    }
	return self;	
}

/*!
 @abstract Sets the bool value for setting
 
 @param valueBOOL   Bool value for setting
 
 */
- (void) setCheckOn:(BOOL)checkBOOL {
    
    if (!self.checkView) {
        // old check icon UIImage *checkImage = [UIImage imageNamed:@"std_icon_checkbox2_prs.png"];
        UIImage *checkImage = [UIImage imageNamed:@"std_icon_check.png"];
        CGSize checkSize = [checkImage size];
        
        UIImageView *check = [[UIImageView alloc] initWithImage:checkImage];
        
        CGFloat arrowStartX = kSBButtonWidth - checkSize.width - 10.0;
        check.frame = CGRectMake(arrowStartX, (kSBButtonHeight-checkSize.height)/2.0, checkSize.width, checkSize.height);
        check.backgroundColor = [UIColor clearColor];
        [self addSubview:check];
        self.checkView = check;
        [check release];
    }

    if (checkBOOL) {
        [self.checkView setHidden:NO];
    }
    else {
        [self.checkView setHidden:YES];
    }
}




/*!
 @abstract Sets the value string for setting
 
 @param valueText   The string value for setting
 
 */
- (void) setValueText:(NSString *)valueText {
    
    // add label lazily
    if (!self.valueLabel) {
        UILabel *vLabel = [[UILabel alloc] initWithFrame:CGRectMake(207.0, (kSBButtonHeight-20.0)/2.0 - 1.0, 80.0, 20.0)];
        vLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
        vLabel.textColor = [AppUtility colorForContext:kAUColorTypeBlue2];
        vLabel.textAlignment = UITextAlignmentRight;
        vLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:vLabel];
        self.valueLabel = vLabel;
        [vLabel release];        
    }
    
    self.valueLabel.text = valueText;
}


/*!
 @abstract Sets the bool value for setting
 
 @param valueBOOL   Bool value for setting
 
 */
- (void) setValueBOOL:(BOOL)valueBOOL animated:(BOOL)animated {
    
    // add label lazily
    if (!self.valueSwitch) {
        
        UISwitch *vSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(207.0, 8.0, 80.0, 35.0)];
        // only for ios5.0 - switch size is also different
        if ([vSwitch respondsToSelector:@selector(onTintColor)]) {
            vSwitch.frame = CGRectMake(223.0, 8.0, 80.0, 35.0);
            vSwitch.onTintColor = [AppUtility colorForContext:kAUColorTypeGreen2];
        }
        [vSwitch addTarget:self.sbTarget action:self.sbSelector forControlEvents:UIControlEventValueChanged];
        self.valueSwitch = vSwitch;
        [self addSubview:vSwitch];
        [vSwitch release];
        
        // if button pressed also change switch position
        //[self addTarget:self action:@selector(changeSwitchPosition:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.valueSwitch setOn:valueBOOL animated:animated];
}

/*!
 @abstract Change the position of uiswitch
 
 Use:
 - When user presses button, also change switch position
 
 */
- (void) changeSwitchPosition:(id)sender {
    
    // controller should do this for us
    //[self.valueSwitch setOn:!self.valueSwitch.on animated:YES];
    
}


@end
