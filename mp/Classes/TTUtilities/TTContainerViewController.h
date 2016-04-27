//
//  TTContainerViewController.h
//  ContactBook
//
//  Created by M Tsai on 9/9/10.
//  Copyright 2010 TernTek. All rights reserved.
//

/**
 A container view controller
 - forwards view_XXX_appear methods to registered view controllers
 
 Usage:
 This is used so that we have a UIViewController that acts like a container to the entire app.
 This is needed if subviews require a UIViewController as a parent view, for example Ad Views.
 
 Controllers are registered to tell these sub controllers that the parent controller identified
 a change in state.
 
 Attributes:
 
 registeredControllers		controllers that where Appear methods should be forwarded to
 */

#import <UIKit/UIKit.h>


@interface TTContainerViewController : UIViewController {
	NSMutableArray *registeredControllers;
}

@property (nonatomic, retain) NSMutableArray *registeredControllers;

- (void) registerViewController:(UIViewController *)viewController;

@end
