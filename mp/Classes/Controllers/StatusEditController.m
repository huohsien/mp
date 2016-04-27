//
//  StatusEditController.m
//  mp
//
//  Created by M Tsai on 11-11-28.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "StatusEditController.h"
#import "MPFoundation.h"

NSInteger const kMPParamStatusLengthMax = 60;


@implementation StatusEditController

@synthesize tempStatus;

- (void)dealloc {
    [tempStatus release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

#define TEXTVIEW_TAG   15001
#define COUNT_TAG       15002

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    self.title = NSLocalizedString(@"Edit Status", @"StatusEdit - title: view to edit status message");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];

    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    // background
    //
    UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    backView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = backView;
    [backView release];            
    
    // textfield background image
    //
    UIImageView *textBackImage = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, 10.0, 310.0, 90.0)];
    textBackImage.image = [Utility resizableImage:[UIImage imageNamed:@"std_icon_textbar.png"] leftCapWidth:9.0 topCapHeight:22.0];
    textBackImage.userInteractionEnabled = YES;
    [self.view addSubview:textBackImage];

    
    // create text view for message
    //
    NSString *status = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingStatus];
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(5.0, 10.0, 300.0, 80.0)];
    [textView becomeFirstResponder];
    textView.textColor = [UIColor blackColor];
    textView.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandardPlus];
    textView.backgroundColor = [UIColor whiteColor];
    textView.delegate = self;
    textView.text = status;
    textView.tag = TEXTVIEW_TAG;
    [textBackImage addSubview:textView];
    [textBackImage release];
    [textView release];
    
    // char count
    //
    UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(appFrame.size.width - 170.0, 103.0, 160.0, 20.0)];
    [AppUtility configLabel:countLabel context:kAULabelTypeBackgroundText];
    countLabel.textAlignment = UITextAlignmentRight;
        countLabel.text = [NSString stringWithFormat:@"%d/%d", [status length], kMPParamStatusLengthMax];
    countLabel.tag = COUNT_TAG;
    [self.view addSubview:countLabel];
    [countLabel release];
    
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *saveButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Save", @"StatusEdit - button: saves status to server") 
                                                      buttonType:kAUButtonTypeBarHighlight 
                                                          target:self action:@selector(pressSave:)];
    saveButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = saveButton;
    
    self.navigationItem.hidesBackButton = YES;

    UIBarButtonItem *cancelButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Cancel", @"StatusEdit - button: cancel status edit") 
                                                      buttonType:kAUButtonTypeBarNormal 
                                                          target:self action:@selector(pressCancel:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated {
    DDLogInfo(@"SEC-vwa");
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processUpdateStatus:) name:MP_HTTPCENTER_UPDATE_STATUS_NOTIFICATION object:nil];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - TextViewDelegate

/*!
 @abstract called whenever text if modified
 */
- (void)textViewDidChange:(UITextView *)textView {
        
    // number of characters
    NSInteger currentCharCount = [textView.text length];
    NSString *charString = [NSString stringWithFormat:@"%d/%d", currentCharCount, kMPParamStatusLengthMax];
    NSString *countMessage = nil;
    
    UILabel *countLabel = (UILabel *)[self.view viewWithTag:COUNT_TAG];
    
    NSString *message = @"";
    
    
    // at max
    if (currentCharCount == kMPParamStatusLengthMax) {
        message = NSLocalizedString(@"Reached limit", @"StatusEdit - text: reached max length of name");
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeBackgroundText];
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    // over max
    else if (currentCharCount > kMPParamStatusLengthMax) {
        message = NSLocalizedString(@"Over limit", @"StatusEdit - text: reached max length of name");
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    // no text .. should all for this too!
    /*else if (currentCharCount == 0) {
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }*/
    // ok otherwise
    //
    else {
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeBackgroundText];
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    
    countMessage = [NSString stringWithFormat:@"%@ %@", message, charString];
    countLabel.text = countMessage;
    
}

#pragma mark - Button

/*!
 @abstract save status
 */
- (void)pressSave:(id)sender {
    
    UITextView *tView = (UITextView *)[self.view viewWithTag:TEXTVIEW_TAG];
    NSInteger charsLeft = kMPParamStatusLengthMax - [tView.text length];
    
    if (charsLeft >= 0) {
        //[AppUtility startActivityIndicator:self.navigationController];
        self.tempStatus = tView.text;
        [[MPHTTPCenter sharedMPHTTPCenter] updateStatus:self.tempStatus];
    }
    else {
        
        NSString *title = NSLocalizedString(@"Invalid Status", @"StatusEdit - alert title");
        NSString *detMessage = NSLocalizedString(@"Status messages must be less than 60 chracters.",@"StatusEdit - alert: status is too long");
        
        [Utility showAlertViewWithTitle:title message:detMessage];
        
    }
}


/*!
 @abstract save status
 */
- (void)pressCancel:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
    
}

#pragma mark - Process Response Update


/*!
 @abstract process udpate status results
 */
- (void) processUpdateStatus:(NSNotification *)notification {
    
    //[AppUtility stopActivityIndicator:self.navigationController];
    
    NSDictionary *responseD = [notification object];
    
    
    NSString *title = NSLocalizedString(@"Update Status", @"StatusMessage - alert title:");
    
    NSString *detMessage = nil;
    
    // ask to confirm
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        [[MPSettingCenter sharedMPSettingCenter] setMyStatusMessage:self.tempStatus];
        
        UITextView *tView = (UITextView *)[self.view viewWithTag:TEXTVIEW_TAG];
        tView.text = self.tempStatus;

    }
    // did not succeed
    else {
        detMessage = NSLocalizedString(@"Status update failed. Try again.", @"StatusMessage - alert: inform of failure");
    }
    
    if (detMessage) {
        [Utility showAlertViewWithTitle:title message:detMessage];
    }
    // success, pop view
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}



@end
