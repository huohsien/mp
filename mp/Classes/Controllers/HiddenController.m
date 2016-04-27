//
//  HiddenController.m
//  mp
//
//  Created by Min Tsai on 2/1/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "HiddenController.h"
#import "MPFoundation.h"

@implementation HiddenController

@synthesize delegate;
@synthesize hcStatus;
@synthesize hiddenChatView;

- (void) dealloc {
    
    [hiddenChatView release];
    [super dealloc];
}


/**
 Initialize this view
 - setup all components
 */
- (id)initWithHCStatus:(HCViewStatus)newStatus {
    if ((self = [super init]))
	{
        self.hcStatus = newStatus;
    }
    return self;
}



- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
    
    switch (self.hcStatus) {
        case kHCViewStatusUnlockPIN:
            self.title = NSLocalizedString(@"Unlock", @"HiddenVC - title: Unlock hidden chat to proceed");
            break;
            
        case kHCViewStatusChangePIN:
            if (pin) {
                self.title = NSLocalizedString(@"Change PIN", @"HiddenVC - title: Change PIN number");
            }
            else {
                self.title = NSLocalizedString(@"Enable Hidden Chat", @"HiddenVC - title: Set New PIN number");
            }
            break;
            
        default:
            break;
    }
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    // add next navigation button
    //
    UIBarButtonItem *cancelButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Cancel",  @"Select Country - Button: cancel selection") 
                                                        buttonType:kAUButtonTypeBarNormal 
                                                            target:self action:@selector(pressCancel:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    HiddenChatView *newView = [[HiddenChatView alloc] initWithFrame:
                               CGRectMake(0.0f, 0.0f, appFrame.size.width, appFrame.size.height) isAlignedToTop:YES];
    newView.delegate = self;
    self.hiddenChatView = newView;
    [self.hiddenChatView setStatus:self.hcStatus];
    [newView release];
    
    self.hiddenChatView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    self.view = self.hiddenChatView;
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



#pragma mark - Button

/*!
 @abstract cancel and dismiss controller
 
 */
- (void)pressCancel:(id)sender {
    if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
        [self dismissModalViewControllerAnimated:YES];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark - HiddenChatView

/*!
 @abstract Call when header view wants to close itself
 */
- (void)HiddenChatView:(HiddenChatView *)view closeWithAnimation:(BOOL)animated {
    
    [self pressCancel:nil];
    
}

/*!
 @abstract Call when PIN display should be shown
 */
- (void)HiddenChatView:(HiddenChatView *)view showPINDisplayWithHeight:(CGFloat)height {
    
   // nothing to do here since the whole container view should be showing
    
}

/*!
 @abstract Notifiy Delegate that unlock was successful
 */
- (void)HiddenChatView:(HiddenChatView *)view unlockDidSucceed:(BOOL)didSucceed{
    
    if ([self.delegate respondsToSelector:@selector(HiddenController:unlockDidSucceed:)]) {
        [self.delegate HiddenController:self unlockDidSucceed:didSucceed];
    }
}


@end
