//
//  TabBarFacade.m
//  ContactBook
//
//  Created by M Tsai on 4/6/10.
//  Copyright 2010 TernTek. All rights reserved.
//

#import "TabBarFacade.h"
#import "TabBarItemController.h"
#import "mpAppDelegate.h"

@implementation TabBarFacade
@synthesize delegate;
@synthesize tabBarController;
@synthesize tabBarItemControllers;
@synthesize containerView;

//
// To use:
// * generate the item controllers first pass array to create the facade
// * add the facade containerView to show above the real tabbar controller
// .. done
//


- (id) initWithTabBarController:(UITabBarController *)newTabBarController 
		  tabBarItemControllers:(NSArray *)newControllers
{
	if ((self = [super init])) {
		self.tabBarController = newTabBarController;
		self.tabBarItemControllers = newControllers;
		
		// add controller buttons to container
		UIView *newContainerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 460.0-kTabBarItemHeight, 320.0, kTabBarItemHeight)];
		newContainerView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
		
		//UIView *newContainerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, kTabBarItemHeight)];
		NSUInteger i = 0;
		for (TabBarItemController *tController in self.tabBarItemControllers){
			
			// tab bars width are not all equal!
			// 107, 106, 107
			if (i == 0) {
				tController.button.frame = CGRectMake(0.0, 0.0, kTabBarItemWidth, kTabBarItemHeight);
			}
			else if (i == 1) {
				tController.button.frame = CGRectMake(kTabBarItemWidth, 0.0, kTabBarItemWidth, kTabBarItemHeight);
			}
			else if (i == 2) {
				tController.button.frame = CGRectMake(kTabBarItemWidth*2.0, 0.0, kTabBarItemWidth, kTabBarItemHeight);
			}
            else if (i == 3) {
				tController.button.frame = CGRectMake(kTabBarItemWidth*3.0, 0.0, kTabBarItemWidth, kTabBarItemHeight);
			}
            else if (i == 4) {
				tController.button.frame = CGRectMake(kTabBarItemWidth*4.0, 0.0, kTabBarItemWidth, kTabBarItemHeight);
			}
			
			[newContainerView addSubview:tController.button];
			tController.tabBarFacade = self;
			i++;
		}
		self.containerView = newContainerView;
		self.containerView.backgroundColor = [UIColor blackColor];
		[newContainerView release];
	}
	return self;
}

-(void) dealloc {
	[tabBarController release];
	[tabBarItemControllers release];
	[containerView release];
	[super dealloc];
}



#pragma mark - Tab Bar Methods

/*!
 @abstract get the class of the current visible view controller
 
 @return if navC, return top controller, otherwise it will just return whatever VC is the currently selected
 
 Use:
 helps figure which view the user is looking at now
 
 */
- (UIViewController *) currentVisibleViewController {

    UIViewController *currentVC = self.tabBarController.selectedViewController;
    if ([currentVC respondsToSelector:@selector(topViewController)]) {
        return [currentVC performSelector:@selector(topViewController)];
    }
    return currentVC;
}


/*!
 @abstract returns current index that is selected
 
 - Index is from the from the view of the facade and not the actual tabbarcontroller
 
 @return 0 if none is found, otherwise return the index of current tab
 
 */
- (NSUInteger) currentIndex {
	// rotate through all buttons
	//
    NSUInteger i = 0;
    
	for (TabBarItemController *tController in self.tabBarItemControllers){
		UILabel *titleLabel = (UILabel *)[tController.button viewWithTag:TITLE_LABEL_TAG];
		
        if ([titleLabel.textColor isEqual:[UIColor whiteColor]]) {
            return i;
        }
        i++;
	}
    return 0;
}



/*!
 @abstract makes sure this controller is initialized and available without animation
 
 @return returns the index of this controller in the real tabbarcontroller
 */
- (NSUInteger) warmUpTabBarItem:(NSUInteger)facadTabIndex {
	
	// rotate through all buttons
	//
	//for (TabBarItemController *tController in self.tabBarItemControllers){
    
    TabBarItemController *tController = [self.tabBarItemControllers objectAtIndex:facadTabIndex];
    
    // update tabBarController
    // - get navigation controller
    // - is it already in tabBarController
    //  * if NO - add the new view
    // - get index of this controller
    //  * then select it
    //
    
    // call getter to get or create object
    //
    mpAppDelegate *appDelegate = (mpAppDelegate *)[[UIApplication sharedApplication] delegate];
    UINavigationController *pressNavController = [appDelegate performSelector:tController.navigationControllerSelector];
    
    // Add controller if it is not already added
    //
    // - iOS 5.0 viewController returns nil instead of empty array
    //
    NSArray *realTabViewControllers = self.tabBarController.viewControllers;
    if (!realTabViewControllers || [realTabViewControllers indexOfObject:pressNavController] == NSNotFound) {
        NSArray *newTabViewControllers = nil;
        if (realTabViewControllers) {
            newTabViewControllers = [realTabViewControllers arrayByAddingObject:pressNavController];
        }
        else {
            newTabViewControllers = [NSArray arrayWithObject:pressNavController];
        }
        [self.tabBarController setViewControllers:newTabViewControllers];
    }
    
    
    // set backend tab bar controller
    NSUInteger index = [self.tabBarController.viewControllers indexOfObject:pressNavController];
    return index;
    //self.tabBarController.selectedIndex = index;
    
    
    // change button appearance
    //titleLabel.textColor = [UIColor whiteColor];
    //[tController setImagePressed:YES];
}





// gets notification that a tab has been pressed
// * reset other buttons
// * switch views
//
- (void) pressed:(TabBarItemController *)pressedController showContainer:(BOOL)showContainer{
	
	// make sure facade is always shows if pressed: is called
	// - sometime this is called programmtically, so the facade may be hidden at that time
	// - particular when the store is showing (facade is hidden), then switching to another tab shows old tabs below
	//
	if (self.containerView.alpha == 0.0 && showContainer) {
		self.containerView.alpha = 1.0;
	}
	
	// rotate through all buttons
	//
	for (TabBarItemController *tController in self.tabBarItemControllers){
		UILabel *titleLabel = (UILabel *)[tController.button viewWithTag:TITLE_LABEL_TAG];
		
		// change image to highlighted version
		if ([tController isEqual:pressedController] ) {
			
			// update tabBarController
			// - get navigation controller
			// - is it already in tabBarController
			//  * if NO - add the new view
			// - get index of this controller
			//  * then select it
			//
			mpAppDelegate *appDelegate = (mpAppDelegate *)[[UIApplication sharedApplication] delegate];
			UINavigationController *pressNavController = [appDelegate performSelector:tController.navigationControllerSelector];
            
            // iOS 5.0 viewController returns nil instead of empty array
            //
            NSArray *realTabViewControllers = self.tabBarController.viewControllers;
			if (!realTabViewControllers || [realTabViewControllers indexOfObject:pressNavController] == NSNotFound) {
				NSArray *newTabViewControllers = nil;
                if (realTabViewControllers) {
                    newTabViewControllers = [realTabViewControllers arrayByAddingObject:pressNavController];
                }
                else {
                    newTabViewControllers = [NSArray arrayWithObject:pressNavController];
                }
				[self.tabBarController setViewControllers:newTabViewControllers];
			}
            
			
			// set backend tab bar controller
			NSUInteger index = [self.tabBarController.viewControllers indexOfObject:pressNavController];
			self.tabBarController.selectedIndex = index;
			
			
			// change button appearance
			titleLabel.textColor = [UIColor whiteColor];
			[tController setImagePressed:YES];
			
		}
		// reset remaining buttons - use normal image
		else {
			titleLabel.textColor = [UIColor grayColor];
			[tController setImagePressed:NO];
		}
	}
}


- (void) pressed:(TabBarItemController *)pressedController{
    
    UINavigationController *fromController = (UINavigationController *)self.tabBarController.selectedViewController;
    [self pressed:pressedController showContainer:YES];
    
    // Inform delegate of the transition
    if ([self.delegate respondsToSelector:@selector(TabBarFacade:didTransitionFromController:toController:)]) {
        UINavigationController *toController = (UINavigationController *)self.tabBarController.selectedViewController;
        [self.delegate TabBarFacade:self didTransitionFromController:fromController toController:toController];
    }
}

/*!
 @abstract press using index
 */
- (void) pressedIndex:(NSUInteger)pressedIndex {
    
    TabBarItemController *tController = [self.tabBarItemControllers objectAtIndex:pressedIndex];    
    [self pressed:tController showContainer:NO];
}

// gets notification that a tab has been pressed twice
// * pop this navigation controller to rootview
//
- (void) pressedRepeat:(TabBarItemController *)pressedController {
	
	// set tab bar
	//NSUInteger index = [self.tabBarItemControllers indexOfObject:pressedController];
	
	UINavigationController *selectedViewController = (UINavigationController *)self.tabBarController.selectedViewController;
	
	// if already at root view, scroll and animate to the top
	if ([selectedViewController.visibleViewController isEqual:[selectedViewController.viewControllers objectAtIndex:0]]) {
		
		if ([selectedViewController.visibleViewController respondsToSelector:@selector(tableView)]) {
			UITableViewController *rootTableViewController = (UITableViewController *)selectedViewController.visibleViewController;
			NSUInteger sections = [[rootTableViewController tableView] numberOfSections];
			if (sections > 0){
				NSUInteger rows = [[rootTableViewController tableView] numberOfRowsInSection:0];
				if (rows > 0) {
					[[rootTableViewController tableView]
						scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] 
						atScrollPosition:UITableViewScrollPositionTop animated:YES];
				}
			}
		}
	}
	else {
		[selectedViewController popToRootViewControllerAnimated:YES];
	}
}

#pragma mark - Badge Count Methods

/*!
 @abstract Sets the badge count for this tab bar item
 
 @discussion setting to zero, hides the badge view completely
 
 @param count           The badge count number
 @param stringCount     Use this string if defined instead of count
 @param controllerIndex The index of the tab button to set
 
 */
- (void) setBadgeCount:(NSUInteger)count stringCount:(NSString *)stringCount controllerIndex:(NSUInteger)controllerIndex {
    
    if (controllerIndex < [self.tabBarItemControllers count]) {
        NSString *countText = nil;
        if (stringCount) {
            countText = stringCount;
        }
        else {
            if (count > 0) {
                countText = [NSString stringWithFormat:@"%d", count];
            }
        }
        
        TabBarItemController *item = [self.tabBarItemControllers objectAtIndex:controllerIndex];
        [item setBadgeCount:countText];
    }
}


@end
