//
//  TabBarItemController.m
//  ContactBook
//
//  Created by M Tsai on 4/6/10.
//  Copyright 2010 TernTek. All rights reserved.
//

#import "TabBarItemController.h"
#import "TabBarFacade.h"
#import "AppUtility.h"

@implementation TabBarItemController

@synthesize notPressedFilename;
@synthesize pressedFilename;
@synthesize button;
@synthesize tabBarFacade;
@synthesize navigationControllerSelector;

#define BADGE_IMAGE_TAG 16001
#define BADGE_LABEL_TAG 16002

CGFloat const kBadgeViewSize = 20.0;


- (id) initWithButtonTitle:(NSString *)buttonTitle 
		notPressedFilename:(NSString *)newNotPressed 
		   pressedFilename:(NSString *)newPressed 
navigationControllerSelector:(SEL)newSelector
{
	if ((self = [super init])) {
		//DDLogVerbose(@"TI-INIT01: Start");
		self.notPressedFilename = newNotPressed;
		self.pressedFilename = newPressed;
		
		UIButton *newButton = [[UIButton alloc] init];
		newButton.adjustsImageWhenHighlighted = NO;
		//DDLogVerbose(@"TI-INIT01: After button alloc");
		
		[newButton addTarget:self action:@selector(pressButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
		[newButton addTarget:self action:@selector(pressButtonTouchDownRepeat:) forControlEvents:UIControlEventTouchDownRepeat];
		//newButton.showsTouchWhenHighlighted = YES;
		newButton.tag = TAB_BUTTON_TAG;
		//DDLogVerbose(@"TI-INIT02: After add targets");
		
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 31.0, kTabBarItemWidth, 18.0)];
		titleLabel.textAlignment = UITextAlignmentCenter;
		titleLabel.textColor = [UIColor grayColor];
		titleLabel.backgroundColor = [UIColor clearColor];
		titleLabel.font = [UIFont systemFontOfSize:10.0];
		titleLabel.text = buttonTitle;
		titleLabel.tag = TITLE_LABEL_TAG;
		//DDLogVerbose(@"TI-INIT03: After title alloc");
		
		[newButton addSubview:titleLabel];
	
		self.navigationControllerSelector = newSelector;
		self.button = newButton;
		[titleLabel release];
		[newButton release];
		//DDLogVerbose(@"TI-INIT04: END");
        
        
        UIButton *badgeButton = [[UIButton alloc] initWithFrame:CGRectMake(kTabBarItemWidth*0.57, kTabBarItemHeight*0.1, kBadgeViewSize, kBadgeViewSize)];
        [AppUtility configButton:badgeButton context:kAUButtonTypeBadgeRed];
        badgeButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        badgeButton.hidden = YES;
        badgeButton.tag = BADGE_IMAGE_TAG;
        [self.button addSubview:badgeButton];  
        [badgeButton release];
        
	}
	return self;	
}

-(void) dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[notPressedFilename release];
	[pressedFilename release];
	[button release];
	[tabBarFacade release];
	[super dealloc];
}


#pragma mark - Badge Methods

/*!
 @abstract Sets the badge count for this tab bar item
 
 @param countString show badge if string is defined
 
 @discussion setting to zero, hides the badge view completely
 
 */
- (void) setBadgeCount:(NSString *) countString {
    
    UIButton *badgeButton = (UIButton *)[self.button viewWithTag:BADGE_IMAGE_TAG];
    [AppUtility setBadge:badgeButton text:countString];
    
}

#pragma mark - Button Methods



/**
 Set button image
 */
- (void) setImagePressed:(BOOL)pressed {
	if (pressed) {
		[self.button setImage:[UIImage imageNamed:self.pressedFilename] forState:UIControlStateNormal];
	}
	else {
		[self.button setImage:[UIImage imageNamed:self.notPressedFilename] forState:UIControlStateNormal];
	}
}


/**
 Remove highlight from tab button
 */
- (void) setNormalImage {
	[self.button setImage:[UIImage imageNamed:self.notPressedFilename] forState:UIControlStateNormal];
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
	
	if ([self.notPressedFilename isEqualToString:@"btn-tab-keypad.png"] || [self.notPressedFilename isEqualToString:@"btn-tab-keypad_locked.png"]) {
		
		[[UIApplication sharedApplication].delegate performSelector:self.navigationControllerSelector];
		[self.button setImage:[UIImage imageNamed:self.pressedFilename] forState:UIControlStateNormal];
		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(setNormalImage) userInfo:nil repeats:NO];
	}
	else {
		[self.tabBarFacade pressed:self];
	}

}


- (void) pressButtonTouchDownRepeat:(id)sender {
	//DDLogVerbose(@"pressed repeat");
	[self.tabBarFacade pressedRepeat:self];
}

@end
