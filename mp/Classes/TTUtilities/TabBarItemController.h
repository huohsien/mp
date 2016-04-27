//
//  TabBarItemController.h
//  ContactBook
//
//  Created by M Tsai on 4/6/10.
//  Copyright 2010 TernTek. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 This objects represents a UITabBarItem of a functioning but hiddend UITabBarController.
 Using a custom uibutton control, this object allows you to fully customize
 the graphics used for each tabbar item.  Coordination between TabBarItemControllers is
 accomplished using the TabBarFacade.
 
 
 button					button that represents this tab
 tabBarFacade			coordinates actions of each TabBarItemController
 
 */

#define TAB_BUTTON_TAG		11000
#define TITLE_LABEL_TAG		12000

// 3 button tab bar
//#define kTabBarItemHeight	48.0
//#define kTabBarItemWidth	107.0

// 5 button
#define kTabBarItemHeight	49.0
#define kTabBarItemWidth	64.0

@class TabBarFacade;

/**
 Represents an individual tab bar button
 
 Attributes:
 
 notPressedFilename				used to lazy load images
 pressedFilename
 
 notPressedImage				cached Images
 pressImage			
 
 
 navigationControllerSelector	app delegate selector access nav controller for associated to this button
 button							reference to button that is controlled
 tabBarFacade					the tab bar facade that serves as the container
 
 */
@interface TabBarItemController : NSObject {

	NSString *notPressedFilename;
	NSString *pressedFilename;
	
    
	SEL navigationControllerSelector;
	UIButton *button;
	TabBarFacade *tabBarFacade;
}

@property (nonatomic, retain) NSString *notPressedFilename;
@property (nonatomic, retain) NSString *pressedFilename;

@property (nonatomic) SEL navigationControllerSelector;
@property (nonatomic, retain) UIButton *button;
@property (nonatomic, retain) TabBarFacade *tabBarFacade;

- (id) initWithButtonTitle:(NSString *)buttonTitle 
		notPressedFilename:(NSString *)newNotPressed 
		   pressedFilename:(NSString *)newPressed 
navigationControllerSelector:(SEL)newSelector;

- (void) setImagePressed:(BOOL)pressed;

- (void) setBadgeCount:(NSString *) countString;

@end
