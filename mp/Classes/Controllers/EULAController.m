//
//  EULAController.m
//  mp
//
//  Created by M Tsai on 11-11-16.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "EULAController.h"
#import "MPFoundation.h"
#import "PhoneRegistrationController.h"

@implementation EULAController

/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}*/

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


/*!
 @abstract generated bar buttons
 */
- (UIBarButtonItem *) barButtonItemAgree:(BOOL)isAgree {
    
    NSString *title = nil;
    
    UIImage *norImage = nil;
    UIImage *prsImage = nil;
    
    if (isAgree){
        title = NSLocalizedString(@"Agree", @"EULA - Button: agree to EULA");
        norImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_green2_nor.png"] leftCapWidth:70.0 topCapHeight:15.0];
        prsImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_green2_prs.png"] leftCapWidth:70.0 topCapHeight:15.0];
    }
    else {
        title = NSLocalizedString(@"EULA Cancel", @"EULA - Button: don't agree with EULA");
        norImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_black_nor.png"] leftCapWidth:70.0 topCapHeight:15.0];
        prsImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_black_prs.png"] leftCapWidth:70.0 topCapHeight:15.0];
    }
    
    
    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [customButton setBackgroundImage:norImage forState:UIControlStateNormal];
    [customButton setBackgroundImage:prsImage forState:UIControlStateHighlighted];
    [customButton setEnabled:YES];
    
    
    customButton.backgroundColor = [UIColor clearColor];
    customButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicroPlus];
    
    [customButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [customButton setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    
    [customButton setFrame:CGRectMake(0,0,150.0,33.0)];
    [customButton setTitle:title forState:UIControlStateNormal];
    
    if (isAgree){
        [customButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [customButton addTarget:self action:@selector(pressAgree:) forControlEvents:UIControlEventTouchUpInside];
    }
    else {
        [customButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [customButton addTarget:self action:@selector(pressCancel:) forControlEvents:UIControlEventTouchUpInside];
    }
    UIBarButtonItem* barButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:customButton] autorelease];
    return barButtonItem;
}


#define TEXT_VIEW_TAG   15000

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    
    // if already agreed
    //
    if ([[MPSettingCenter sharedMPSettingCenter] didAgreeToEULA]) {
        // push next view onto navigation stack
        //
        PhoneRegistrationController *nextController = [[PhoneRegistrationController alloc] init];
        [self.navigationController pushViewController:nextController animated:NO];
        [nextController release];
    }
    // have not agreed, then first time so reset settings
    else {
        // reset settings
        [[MPSettingCenter sharedMPSettingCenter] resetAllSettingsWithFullReset:YES];
    }
    
    UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view = backView;
    [backView release];
    self.view.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    
    
    // create text view for EULA
    //
    CGRect appRect = [[UIScreen mainScreen] applicationFrame];
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(10.0, 10.0, appRect.size.width-20.0, appRect.size.height-105.0)];
    textView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    textView.font = [AppUtility fontPreferenceWithContext:kAUFontBoldMicroPlus];
    textView.textColor = [AppUtility colorForContext:kAUColorTypeGray1];
    textView.text = NSLocalizedString(@"<EULA detailed text>", @"EULA - textview: detailed EULA agreement");
    textView.editable = NO;
    textView.tag = TEXT_VIEW_TAG;
    [self.view addSubview:textView];
    [textView release];
    
    self.title = NSLocalizedString(@"End User License Agreement", @"View Title: EULA title");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    
    self.navigationController.toolbarHidden = NO;
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    // Add Toolbar buttons
    /* UIBarButtonItem *agreeButton = [[ UIBarButtonItem alloc ] initWithTitle: NSLocalizedString(@"Agree", @"EULA - Button: agree to EULA") 
     style: UIBarButtonItemStyleBordered
     target: self
     action: @selector( pressAgree: ) ];
     agreeButton.width = 140.0;*/
    //agreeButton.enabled = NO;
    
    /*UIBarButtonItem *cancelButton = [[ UIBarButtonItem alloc ] initWithTitle: NSLocalizedString(@"Cancel", @"EULA - Button: don't agree with EULA") 
     style: UIBarButtonItemStyleBordered
     target: self
     action: @selector( pressCancel: ) ];
     cancelButton.width = 140.0;*/
    //cancelButton.enabled = NO;
    
    self.toolbarItems = [ NSArray arrayWithObjects: flexibleSpace, [self barButtonItemAgree:NO], [self barButtonItemAgree:YES], flexibleSpace, nil ];
    [flexibleSpace release];
    
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[MPHTTPCenter sharedMPHTTPCenter] ipQueryMsisdn];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Buttons

/*! 
 @abstract agree to EULA
 */
- (void) pressAgree:(id)sender {
    
    // save agreement settings and push the next view
    //
    [[MPSettingCenter sharedMPSettingCenter] agreedToEULA];
    
    // push next view onto navigation stack
    //
    PhoneRegistrationController *nextController = [[PhoneRegistrationController alloc] init];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
    
}

/*! 
 @abstract disagree to EULA
 */
- (void) pressCancel {
    
    // exit app
    //
}

@end
