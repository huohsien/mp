//
//  TTUITextField.m
//  ContactBook
//
//  Created by M Tsai on 8/10/10.
//  Copyright 2010 TernTek. All rights reserved.
//

#import "TTUITextField.h"


@implementation TTUITextField


/**
 draws placeholder with custom color
 
 - make it darker so it looks more like a placeholder
 
 */

- (void) drawPlaceholderInRect:(CGRect)rect {
	
	UIFont *placeholderFont = [UIFont systemFontOfSize:17]; //[AppUtility fontPreferenceWithContext:@"modify_detailed"];
	
    //[[UIColor colorWithRed:0.184 green:0.169 blue:0.173 alpha:1.0] setFill];
	[[UIColor colorWithRed:0.234 green:0.219 blue:0.223 alpha:1.0] setFill];
    [[self placeholder] drawInRect:rect withFont:placeholderFont lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentRight];
}

@end
