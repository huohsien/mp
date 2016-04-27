    //
//  TTContainerViewController.m
//  ContactBook
//
//  Created by M Tsai on 9/9/10.
//  Copyright 2010 TernTek. All rights reserved.
//

#import "TTContainerViewController.h"
#import "ChatDialogController.h"
#import "BroadcastController.h"
#import "ComposerController.h"
#import "TKLog.h"


@implementation TTContainerViewController

@synthesize registeredControllers;

- (id) init {
	if ((self = [super init])) {
		NSMutableArray *mutArray = [[NSMutableArray alloc] init];
		self.registeredControllers = mutArray;
		[mutArray release];
	}
	return self;
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	/*if ([self.modalViewController isKindOfClass:[ChatDialogController class]] ||
		[self.modalViewController isKindOfClass:[BroadcastController class]] ||
        [self.modalViewController isKindOfClass:[ComposerController class]] ){
        
		return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	}
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
     */
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


/**
 Register a new view controller
 
 */
- (void) registerViewController:(UIViewController *)viewController {
	[self.registeredControllers addObject:viewController];
}

- (void) viewWillAppear:(BOOL)animated {
	DDLogVerbose(@"CONVC-VWA");
	for (UIViewController *iController in self.registeredControllers){
		if ([iController respondsToSelector:@selector(viewWillAppear:)]) {
			[iController viewWillAppear:animated];
		}
	}
}

- (void) viewDidAppear:(BOOL)animated {
	DDLogVerbose(@"CONVC-VDA");
	for (UIViewController *iController in self.registeredControllers){
		if ([iController respondsToSelector:@selector(viewDidAppear:)]) {
			[iController viewDidAppear:animated];
		}
	}
}

- (void) viewWillDisappear:(BOOL)animated {
    DDLogVerbose(@"CONVC-WD");
	for (UIViewController *iController in self.registeredControllers){
		if ([iController respondsToSelector:@selector(viewWillDisappear:)]) {
			[iController viewWillDisappear:animated];
		}
	}
}

- (void) viewDidDisappear:(BOOL)animated {
    DDLogVerbose(@"CONVC-DD");
	for (UIViewController *iController in self.registeredControllers){
		if ([iController respondsToSelector:@selector(viewDidDisappear:)]) {
			[iController viewDidDisappear:animated];
		}
	}
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[registeredControllers release];
    [super dealloc];
}




@end
