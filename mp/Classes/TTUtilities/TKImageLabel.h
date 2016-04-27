//
//  TKBadgeView.h
//  mp
//
//  Created by Min Tsai on 1/17/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//



/*!
 @header TKImageLabel
 
 Simple image view that holds a text in the middle.  If the text is updated the view should expand 
 to accomodate the new text.
 
 This can be used for badge like images label combinations that need to expand to fit the text.
 
 e.g.
 
 // add blue number indicator
 TKImageLabel *blueBadge = [[TKImageLabel alloc] initWithFrame:CGRectMake(271.0, 8.0, 30.0, 30.0)];
 blueBadge.backgroundImage = [Utility resizableImage:[UIImage imageNamed:@"std_icon_badge_bl.png"] leftCapWidth:14.0 topCapHeight:14.0];
 blueBadge.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
 blueBadge.textColor = [UIColor whiteColor];
 blueBadge.textEdgeInsets = UIEdgeInsetsMake(0.0, 5.0, 0.0, 5.0);
 blueBadge.backgroundColor = [UIColor clearColor];
 blueBadge.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
 blueBadge.tag = TO_NUMBER_BTN_TAG;
 [blueBadge setText:[NSString stringWithFormat:@"%d", [self.toContacts count]]];
 
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */


#import <UIKit/UIKit.h>

@interface TKImageLabel : UIView {
    
    NSString *text;
    UIFont *font;
    UIColor *textColor;
    UIImage *backgroundImage;
    CGFloat maxWidth;
    UIEdgeInsets textEdgeInsets;
    
}

/*! text to show in view */
@property (nonatomic, retain) NSString *text;

/*! text font used */
@property (nonatomic, retain) UIFont *font;

/*! text color */
@property (nonatomic, retain) UIColor *textColor;

/*! background image */
@property (nonatomic, retain) UIImage *backgroundImage;

/*! text to show in view */
@property (nonatomic, assign) CGFloat maxWidth;

/*! text to show in view */
@property (nonatomic, assign) UIEdgeInsets textEdgeInsets;


@end
