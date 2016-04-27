//
//  TabBarFacade.h
//  ContactBook
//
//  Created by M Tsai on 4/6/10.
//  Copyright 2010 TernTek. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TabBarItemController;
@class TabBarFacade;

/*!
 Delegate that handles input from this view's controls
 */
@protocol TabBarFacadeDelegate <NSObject>
@optional
/*!
 @abstract Inform users tabbar will transition to another tab
 
 Use:
 - Delegate an react to changes in tab bar
 */
- (void)TabBarFacade:(TabBarFacade *)tabBarFacade didTransitionFromController:(UINavigationController *)fromController toController:(UINavigationController *)toController;

@end


/*
 This control acts as a facade for a real UITabBarController which allows for
 fully custom tabbar items (not just blue ones that the SDK generates).  This
 object serves to:
  * coordinate the tab bar items states
  * switch to the correct tabbar view
 
 
 tabBarController		the underlying controller that switches betweens views
 tabBarItemControllers	array that holds each tabbar item
 containerView			holds the UIbutton views of each tabbar item

 
 */

@interface TabBarFacade : NSObject {
    id <TabBarFacadeDelegate> delegate;
	UITabBarController *tabBarController;
	NSArray *tabBarItemControllers;
	UIView *containerView;
}

@property (nonatomic, assign) id <TabBarFacadeDelegate> delegate;
@property (nonatomic, retain) UITabBarController *tabBarController;
@property (nonatomic, retain) NSArray *tabBarItemControllers;
@property (nonatomic, retain) UIView *containerView;


- (id) initWithTabBarController:(UITabBarController *)newTabBarController 
		  tabBarItemControllers:(NSArray *)newControllers;

- (UIViewController *) currentVisibleViewController;
- (NSUInteger) currentIndex;
- (NSUInteger) warmUpTabBarItem:(NSUInteger)facadTabIndex;
- (void) pressed:(TabBarItemController *)pressedController;
- (void) pressedIndex:(NSUInteger)pressedIndex;
- (void) pressedRepeat:(TabBarItemController *)pressedController;

- (void) setBadgeCount:(NSUInteger)count stringCount:(NSString *)stringCount controllerIndex:(NSUInteger)controllerIndex;
@end
