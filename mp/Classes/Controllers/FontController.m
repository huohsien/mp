//
//  FontController.m
//  mp
//
//  Created by M Tsai on 11-12-6.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "FontController.h"
#import "MPFoundation.h"

NSString* const MP_FONT_CHANGE_NOTIFICATION = @"MP_FONT_CHANGE_NOTIFICATION";


@implementation FontController

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
    // title
    //
    self.title = NSLocalizedString(@"Chat Font Size", @"FontSize - title: change chat font size");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    // background
    //
    UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    backView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = backView;
    [backView release];            
    
    
    // normal button
    //
    UIButton *normalButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, 10.0, 310.0, 45.0)];
    [AppUtility configButton:normalButton context:kAUButtonTypeTextBarTop];
    normalButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
    [normalButton addTarget:self action:@selector(pressNormal:) forControlEvents:UIControlEventTouchUpInside];
    [normalButton setTitle:NSLocalizedString(@"Normal", @"FontSize - button: standard font size") forState:UIControlStateNormal];
    // remove arrow view
    [Utility removeSubviewsForView:normalButton tag:kAUViewTagTextBarArrow];
    [self.view addSubview:normalButton];
    [normalButton release];
    
    
    // large button
    //
    UIButton *largeButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, 55.0, 310.0, 45.0)];
    [AppUtility configButton:largeButton context:kAUButtonTypeTextBarBottom];
    largeButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandardPlus];
    [largeButton addTarget:self action:@selector(pressLarge:) forControlEvents:UIControlEventTouchUpInside];
    [largeButton setTitle:NSLocalizedString(@"Large", @"FontSize - button: large font size") forState:UIControlStateNormal];
    // remove arrow view
    [Utility removeSubviewsForView:largeButton tag:kAUViewTagTextBarArrow];
    [self.view addSubview:largeButton];
    [largeButton release];

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

- (void) viewWillAppear:(BOOL)animated {
    DDLogInfo(@"FontC-vwa");
    [super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Button


/*!
 @abstract selected normal font size
 */
- (void) pressNormal:(id)sender {
    
    [[MPSettingCenter sharedMPSettingCenter] setFontSizeToLarge:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:MP_FONT_CHANGE_NOTIFICATION object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}


/*!
 @abstract selected normal font size
 */
- (void) pressLarge:(id)sender {
    
    [[MPSettingCenter sharedMPSettingCenter] setFontSizeToLarge:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:MP_FONT_CHANGE_NOTIFICATION object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}


@end
