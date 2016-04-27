//
//  VerifySMSCodeController.m
//  mp
//
//  Created by M Tsai on 11-10-18.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "VerifySMSCodeController.h"
#import "MPFoundation.h"
#import "NameRegistrationController.h"

/*! beyond this we use longer timer */
NSInteger const kMPParamVerifyRetryThreshold = 3;

/*! how long to wait until we can press resend again */
CGFloat const kMPParamVerifyWaitTimerResendShort = 30.0;
CGFloat const kMPParamVerifyWaitTimerResendLong = 300.0;


@implementation VerifySMSCodeController

@synthesize smsCodeField;
@synthesize resendCount;

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.smsCodeField.delegate = nil;
    
    [smsCodeField release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#define NEXT_BTN_TAG        15001
#define RESEND_BTN_TAG      15002

#pragma mark - Throttle Resend



#pragma mark - View lifecycle


/*!
 @abstract Enable resend button to allow users to tap again
 
 */
- (void) enableResendButton {
    
    UIButton *resendButton = (UIButton *)[self.view viewWithTag:RESEND_BTN_TAG];
    resendButton.enabled = YES;
    
}

/*!
 @abstract Disable resend button and start timer to enable it again
 
 */
- (void) startResendTimer {
    
    UIButton *resendButton = (UIButton *)[self.view viewWithTag:RESEND_BTN_TAG];
    resendButton.enabled = NO;
    
    CGFloat waitInterval = (self.resendCount > kMPParamVerifyRetryThreshold)?kMPParamVerifyWaitTimerResendLong:kMPParamVerifyWaitTimerResendShort;
    
    [NSTimer scheduledTimerWithTimeInterval:waitInterval target:self selector:@selector(enableResendButton) userInfo:nil repeats:NO];
    
    self.resendCount++;
}



#pragma mark - View lifecycle

/*!
 @abstract adds name controller
 
 Registration requires
  - Authenticate w/o login
  - register nickname
  - then login
 
 */
- (void) pushNameControllerAnimated:(BOOL)animated {
    
    // pushes next view - if this is the top VC
    //
    // only push next VC if this is the top VC on the stack
    //
    if ([self.navigationController topViewController] == self) {
        NameRegistrationController *nextController = [[NameRegistrationController alloc] initIsRegistration:YES];
        [self.navigationController pushViewController:nextController animated:animated];
        [nextController release];
    }

}


/*!
 @abstract goes to the next setup step
 */
- (void)proceedToNextView:(NSNotification *)notification {
    DDLogInfo(@"VSCC: push next view - name registration VC: %@", self);
    [self pushNameControllerAnimated:YES];
    
}





// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{

    // if user already registered go to next step
    //
    if ([[MPHTTPCenter sharedMPHTTPCenter] isUserRegistered]){
        [self pushNameControllerAnimated:NO];
    }
    
    UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view = backView;
    [backView release];
    self.view.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];

    
    // bear image
    //
    UIImageView *bearImage = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, 5.0, 60.0, 60.0)];
    bearImage.image = [UIImage imageNamed:@"std_icon_bear_post.png"];
    [self.view addSubview:bearImage];
    [bearImage release];
    
    
    // text bubble image
    //
    UIImageView *bubbleView = [[UIImageView alloc] initWithFrame:CGRectMake(75.0, 11.0, 230.0, 55.0)];
    bubbleView.image = [UIImage imageNamed:@"std_icon_textbar2.png"];
    [self.view addSubview:bubbleView];
    
    // add phone reminder label
    //
    UILabel *phoneReminderLabel = [[UILabel alloc] initWithFrame:CGRectMake(25.0, 10.0, 190.0, 14.0)];
    [AppUtility configLabel:phoneReminderLabel context:kAULabelTypeGrayMicroPlus];
    phoneReminderLabel.backgroundColor = [UIColor clearColor];
    phoneReminderLabel.textAlignment = UITextAlignmentCenter;
    phoneReminderLabel.text = NSLocalizedString(@"A verification code was sent to", @"Verify SMS - Label: remind user which number was is being registered");
    [bubbleView addSubview:phoneReminderLabel];
    [phoneReminderLabel release];
    
    
    // add phone number label
    //
    UILabel *phoneNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(25.0, 28.0, 190.0, 19.0)];
    [AppUtility configLabel:phoneNumberLabel context:kAULabelTypeBlackStandardPlusBold];
    phoneNumberLabel.backgroundColor = [UIColor clearColor];
    phoneNumberLabel.textAlignment = UITextAlignmentCenter;
    /*phoneNumberLabel.text = [NSString stringWithFormat:@"+%@ %@",
                             [[MPHTTPCenter sharedMPHTTPCenter] getCountryCode],
                             [[MPHTTPCenter sharedMPHTTPCenter] getPhoneNumber]];*/
    //phoneNumberLabel.text = [Utility formatPhoneNumber:@"sdkjf*.()2323aa23" countryCode:[[MPHTTPCenter sharedMPHTTPCenter] getCountryCode]]; 
    phoneNumberLabel.text = [Utility formatPhoneNumber:[[MPHTTPCenter sharedMPHTTPCenter] getPhoneNumber] countryCode:[[MPHTTPCenter sharedMPHTTPCenter] getCountryCode] showCountryCode:YES]; 
    [bubbleView addSubview:phoneNumberLabel];
    [phoneNumberLabel release];
    [bubbleView release];

    
    // add verification label
    //
    UILabel *verificationLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 79.0, 240.0, 14.0)];
    [AppUtility configLabel:verificationLabel context:kAULabelTypeGrayMicroPlus];
    verificationLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    verificationLabel.text = NSLocalizedString(@"Enter verification code", @"Verify SMS - Label: instruct user to enter verification code");
    [self.view addSubview:verificationLabel];
    [verificationLabel release];
    
    
    // add code textfield
    //
    UITextField *codeField = [[UITextField alloc] initWithFrame:CGRectMake(5.0, 96.0, 245.0, 45.0)];
    [AppUtility configTextField:codeField context:kAUTextFieldTypePhone];
    codeField.keyboardType = UIKeyboardTypeNumberPad;
    codeField.placeholder = NSLocalizedString(@"Enter SMS Verification Code", @"Verify SMS - Placeholder: enter sms verification code here");
    codeField.delegate = self;
    [self.view addSubview:codeField];
    self.smsCodeField = codeField;
    [codeField release];
    
    
    // next button
    //
    UIButton *nextButton = [[UIButton alloc] initWithFrame:CGRectMake(255.0, 96.0, 60.0, 45.0)];
    [AppUtility configButton:nextButton context:kAUButtonTypeGreen5];
    [nextButton addTarget:self action:@selector(pressNext:) forControlEvents:UIControlEventTouchUpInside];
    [nextButton setTitle:NSLocalizedString(@"Next", @"VerifySMS - button: submit code") forState:UIControlStateNormal];
    nextButton.enabled = NO;
    nextButton.tag = NEXT_BTN_TAG;
    [self.view addSubview:nextButton];
    [nextButton release];
    
    
    // add resend sms button
    //
    UIButton *resendButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, 146.0, 154.0, 50.0)];
    [AppUtility configButton:resendButton context:kAUButtonTypeBlueDark];  
    [resendButton setTitle:NSLocalizedString(@"Resend SMS\nVerification Code", @"Verify SMS - Button: button will resend code via sms again") forState:UIControlStateNormal];
    [resendButton addTarget:self action:@selector(pressResend:) forControlEvents:UIControlEventTouchUpInside];
    resendButton.tag = RESEND_BTN_TAG;
    [self.view addSubview:resendButton];
    [resendButton release];
    
    // set resend Count and start resend timer
    self.resendCount = 0;
    [self startResendTimer];
    

    // add change phone button
    //
    UIButton *changeButton = [[UIButton alloc] initWithFrame:CGRectMake(162.0, 146.0, 154.0, 50.0)];
    [AppUtility configButton:changeButton context:kAUButtonTypeBlueDark]; // was Orange2
    [changeButton setTitle:NSLocalizedString(@"Change Phone Number", @"Verify SMS - Button: allow user to change phone number") forState:UIControlStateNormal];
    [changeButton addTarget:self action:@selector(pressChangePhone:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:changeButton];
    [changeButton release];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(proceedToNextView:) name:MP_HTTPCENTER_CODE_VERIFICATION_SUCCESS object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(showInvalidAlert:) name:MP_HTTPCENTER_CODE_VERIFICATION_FAILURE object:nil];

}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *title = NSLocalizedString(@"Enter Verification Code", @"Verify SMS - Title: title for this view");
    [AppUtility setCustomTitle:title navigationItem:self.navigationItem];
    
    // add next navigation button
    //	
    /*UIBarButtonItem *nextButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Next", @"Verify SMS - Button: go to next step") 
                                                      buttonType:kAUButtonTypeBarHighlight 
                                                          target:self action:@selector(pressNext:)];
    nextButton.enabled = NO; // start disabled
	self.navigationItem.rightBarButtonItem = nextButton;*/
    
	/*UIBarButtonItem *nextButton = [[UIBarButtonItem alloc]
								   initWithTitle:NSLocalizedString(@"Next", @"Verify SMS - Button: go to next step")
								   style:UIBarButtonItemStyleDone
								   target:self 
								   action:@selector(pressNext:)];
    
	self.navigationItem.rightBarButtonItem = nextButton;*/
    
    self.navigationItem.hidesBackButton = YES;
    
    // make pass first responder
    [self.smsCodeField becomeFirstResponder];
    
}


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

#pragma mark - Utility

/*!
 @abstract check pass code is valid
 
 Valid:
  - 4 digits only
 
 */
- (BOOL)isPassValid{
    
    BOOL isValid = NO;
    
    // only if all numbers except the + sign in CC
    NSCharacterSet *nonDecimalSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSArray *passParts = [self.smsCodeField.text componentsSeparatedByCharactersInSet:nonDecimalSet];
    
    
    if ([passParts count] == 1) {
        
        if ([self.smsCodeField.text length] == 4) {
            isValid = YES;
        }
    }
    return isValid;
}

#pragma mark - Buttons


/*!
 @abstract submit verification code
 */
- (void) showInvalidAlert:(NSNotification *)notification {
    
    // present an alert view to explain further
    //
    NSString *title = NSLocalizedString(@"Incorrect Pass Code", @"VerifySMS - Alert: title");
    NSString *detMessage = NSLocalizedString(@"Incorrect pass code entered. Try again.", @"VerifySMS - Alert: sms pass code is invalid");
    
    
    // if expired
    NSDictionary *responseD = [notification object];
    if (responseD) {
        NSInteger causeResult = [MPHTTPCenter getCauseForResponseDictionary:responseD];
        if (causeResult == kMPCauseTypePassCodeExpired) {
            title = NSLocalizedString(@"Pass Code Expired", @"VerifySMS - Alert: title");
            detMessage = NSLocalizedString(@"Pass code entered has expired. Request another verification code.", @"VerifySMS - Alert: sms pass code has expired");
        }
    }
    [Utility showAlertViewWithTitle:title message:detMessage];
}


/*!
 @abstract submit verification code
 */
- (void) pressNext:(id)sender {
    
    
    // not valid - show alert and don't proceed
    //
    if (![self isPassValid]) {
        
        // present an alert view to explain further
        //
        [self showInvalidAlert:nil];
        
    }
    // submit passcode
    else {
        //[self.smsCodeField resignFirstResponder];
        [[MPHTTPCenter sharedMPHTTPCenter] verifyRegistration:self.smsCodeField.text];
    }
}

/*!
 @abstract resend another SMS verification code
 */
- (void) pressResend:(id)sender {
    
    [[MPHTTPCenter sharedMPHTTPCenter] resendRegistration];
    [self startResendTimer];
    
}

/*!
 @abstract change phone number to register
 */
- (void) pressChangePhone:(id)sender {
    
    // clear phone number and try again
    //
    [[MPSettingCenter sharedMPSettingCenter] resetMSISDN];
    [self.navigationController popViewControllerAnimated:YES];
    
}


#pragma mark - text field delegate
/*!
 @abstract called whenever text if modified
 
 Don't go over 4 digits
 
 */
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {  
    
    BOOL shouldChange = YES;
    
    // number of characters
    NSInteger previewCharCount = [textField.text length] + [string length] - range.length;    
    // if over max length
    //
    if (previewCharCount > 4) {
        // don't go over max
        shouldChange = NO;
    }
    
    UIButton *nextButton = (UIButton *)[self.view viewWithTag:NEXT_BTN_TAG];
    
    // if will become 4 or is already at 4 & increasing, then allow submit
    if (previewCharCount == 4 || (previewCharCount > 4 && [textField.text length] == 4)) {
        nextButton.enabled = YES;
        //self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else {
        nextButton.enabled = NO;
        //self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    return shouldChange;
}




@end
