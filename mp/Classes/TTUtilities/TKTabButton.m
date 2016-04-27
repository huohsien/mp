//
//  TKTabButton.m
//  mp
//
//  Created by Min Tsai on 1/9/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "TKTabButton.h"

@implementation TKTabButton

@synthesize normalFilename;
@synthesize selectedFilename;
@synthesize normalBackgroundFilename;
@synthesize selectedBackgroundFilename;

@synthesize delegate;

- (id) initWithFrame:(CGRect)frame 
 normalImageFilename:(NSString *)newNormalFilename 
selectedImageFilename:(NSString *)newSelectedFilename 
normalBackgroundImageFilename:(NSString *)newNormalBackgroundFilename 
selectedBackgroundImageFilename:(NSString *)newSelectedBackgroundFilename
{
    
	if ((self = [super initWithFrame:frame])) {

		self.normalFilename = newNormalFilename;
		self.selectedFilename = newSelectedFilename;
        self.normalBackgroundFilename = newNormalBackgroundFilename;
        self.selectedBackgroundFilename = newSelectedBackgroundFilename;
		
		self.adjustsImageWhenHighlighted = NO;
		
		[self addTarget:self action:@selector(pressButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
		[self addTarget:self action:@selector(pressButtonTouchDownRepeat:) forControlEvents:UIControlEventTouchDownRepeat];
        
        [self setImagePressed:NO];
    }
	return self;	
}


-(void) dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[normalFilename release];
    [selectedFilename release];
	[super dealloc];
}


#pragma mark - Button Methods


/**
 Set button image
 */
- (void) setImagePressed:(BOOL)pressed {
	if (pressed) {
		[self setImage:[UIImage imageNamed:self.selectedFilename] forState:UIControlStateNormal];
        [self setBackgroundImage:[UIImage imageNamed:self.selectedBackgroundFilename] forState:UIControlStateNormal];

	}
	else {
		[self setImage:[UIImage imageNamed:self.normalFilename] forState:UIControlStateNormal];
        [self setBackgroundImage:[UIImage imageNamed:self.normalBackgroundFilename] forState:UIControlStateNormal];
	}
}


/**
 Remove highlight from tab button
 */
- (void) setNormalImage {
	[self setImagePressed:NO];
}


/**
 Reacts to tab button press
 - change the index of actual tab bar controller to switch views
 - notify facade so it can coordinate changes with other buttons
 
 For keypad tab
 - show highlight tab button for 1 second and revert back
 - also bring up keypad modally
 
 */
- (void) pressButtonTouchDown:(id)sender {
	// keypad exception
	
    if ([self.delegate respondsToSelector:@selector(TKTabButton:gotControlEvent:)]) {
        
        [self.delegate TKTabButton:self gotControlEvent:UIControlEventTouchDown];
    }
}


- (void) pressButtonTouchDownRepeat:(id)sender {

    if ([self.delegate respondsToSelector:@selector(TKTabButton:gotControlEvent:)]) {
        
        [self.delegate TKTabButton:self gotControlEvent:UIControlEventTouchDownRepeat];
    }
}

@end
