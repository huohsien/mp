//
//  NameRegistrationController.m
//  mp
//
//  Created by M Tsai on 11-10-19.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "NameRegistrationController.h"
#import "MPFoundation.h"
#import "CDContact.h"
#import "MPContactManager.h"

@implementation NameRegistrationController

NSInteger const kMPParamNameLengthMin = 2;
NSInteger const kMPParamNameLengthMax = 20;


@synthesize nameField;
@synthesize tempName;
@synthesize isRegistration;
@synthesize didDismissAlready;


- (void) dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [tempName release];
    [nameField release];
    [super dealloc];
    
}

/*!
 @abstract init with contacts who we will send broadcast to
 
 @param isRegistration is this shown during registration: yes show Done button instead of Save
 
 */
- (id)initIsRegistration:(BOOL)registration
{
    self = [super init];
    if (self) {
        self.isRegistration = registration;
        self.didDismissAlready = NO;
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

#define COUNT_TAG 13001

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{

    
    UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view = backView;
    [backView release];
    self.view.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    
    
    // name description label
    //
    UILabel *nameDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 10.0, 295.0, 30.0)];
    [AppUtility configLabel:nameDescriptionLabel context:kAULabelTypeGrayMicroPlus];
    nameDescriptionLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    nameDescriptionLabel.lineBreakMode = UILineBreakModeWordWrap;
    nameDescriptionLabel.numberOfLines = 2;
    nameDescriptionLabel.text = NSLocalizedString(@"<name description text>", @"Name Registration - Label: explain what this name is for");
    [self.view addSubview:nameDescriptionLabel];
    [nameDescriptionLabel release];
    
    
    // name textfield
    //
    NSString *name = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingNickName];
    UITextField *nField = [[UITextField alloc] initWithFrame:CGRectMake(5.0, 46.0, 310.0, 45.0)];
    [AppUtility configTextField:nField context:kAUTextFieldTypeName];
    nField.placeholder = NSLocalizedString(@"<myprofile: enter name>", @"Name Registration - Placeholder: enter user name here");
    nField.text = name;
    nField.delegate = self;
    nField.keyboardType = UIKeyboardTypeDefault;

    [self.view addSubview:nField];
    self.nameField = nField;
    [nField release];
    
    
    // char count
    //
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(appFrame.size.width - 300.0, 99.0, 290.0, 20.0)];
    [AppUtility configLabel:countLabel context:kAULabelTypeBackgroundText];
    countLabel.textAlignment = UITextAlignmentRight;
    countLabel.text = [NSString stringWithFormat:@"%d/%d", [self.nameField.text length], kMPParamNameLengthMax];
    countLabel.tag = COUNT_TAG;
    [self.view addSubview:countLabel];
    [countLabel release];
    
    // if registration, listen for auth results
    if (self.isRegistration) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processAuthentication:) name:MP_HTTPCENTER_AUTHENTICATION_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processBlockedRecovered:) name:MP_CONTACTMANAGER_BLOCKED_RECOVERED_NOTIFICATION object:nil];
    }
    
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Name", @"Update Name - Title: title for this view");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];

    
    // add next navigation button
    //    
    NSString *buttonTitle = NSLocalizedString(@"Save", @"UpdateName - button: saves nickname to server");
    if (self.isRegistration) {
        buttonTitle = NSLocalizedString(@"Done", @"UpateName - button: saves nickname to server");
        self.navigationItem.hidesBackButton = YES;
    }
    
    UIBarButtonItem *saveButton = [AppUtility barButtonWithTitle:buttonTitle
                                                      buttonType:kAUButtonTypeBarHighlight 
                                                          target:self action:@selector(pressSave:)];
    if ([self isNameValid:self.nameField.text]) {
        saveButton.enabled = YES;
    }
    else {
        saveButton.enabled = NO;
    }
    self.navigationItem.rightBarButtonItem = saveButton;
    
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processUpdateName:) name:MP_HTTPCENTER_UPDATE_NICKNAME_NOTIFICATION object:nil];
    
}


- (void)viewDidUnload
{
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Buttons

/*!
 @abstract check user name is valid
 
 Valid:
 
 */
- (BOOL)isNameValid:(NSString *)testName{
    
    BOOL isValid = NO;
    
    // can't have any symbols
    NSArray *symbolParts = [testName componentsSeparatedByCharactersInSet:[NSCharacterSet symbolCharacterSet]];
    NSArray *punctParts = [testName componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
    
    NSInteger nameLen = [testName length];
    
    if (nameLen >= kMPParamNameLengthMin && nameLen <= kMPParamNameLengthMax && 
        [symbolParts count] == 1 && [punctParts count] == 1) {
        isValid = YES;
    }
    return isValid;
}



/*!
 @abstract Starts name registration process
 
 For registration
 - Authenticate first
 - Process authentication
 - If blocked users exists, then query for blocked userInformation
 - Then register nickname
 - 
 
 */
- (void) pressSave:(id)sender {
            
    self.nameField.text = [Utility trimWhiteSpace:self.nameField.text];
    
    if ([self isNameValid:self.nameField.text]) {
        [AppUtility startActivityIndicator];
        
        self.tempName = [Utility trimWhiteSpace:self.nameField.text];

        if (self.isRegistration) {
            // Must authenticate before registering name!
            // - otherwise account will not have domainIP created
            //
            [[MPHTTPCenter sharedMPHTTPCenter] requestAuthenticationKey];
        }
        else {
            // request name update
            [[MPHTTPCenter sharedMPHTTPCenter] updateNickname:self.tempName];
        }
    }
    else {
        
        NSString *alertTitle = NSLocalizedString(@"Invalid Name", @"UpdateName - alert title");
        NSString *alertMessage = NSLocalizedString(@"Names cannot contain any special characters.",@"UpdateName - alert: name is invalid");
        [Utility showAlertViewWithTitle:alertTitle message:alertMessage];
        
    }
}



#pragma mark - Process Response Update

/*!
 @abstract process authentication results
 */
- (void) processAuthentication:(NSNotification *)notification {
    
    DDLogInfo(@"NR-pa: process authentication");
    
    NSDictionary *responseD = [notification object];
    
    MPCauseType cause = [MPHTTPCenter getCauseForResponseDictionary:responseD];
    
    NSString *title = NSLocalizedString(@"Update Name", @"UpdateName - alert title:");
    
    NSString *detMessage = nil;
    
    // autheniticate ok
    if (cause == kMPCauseTypeSuccess) {
        
        
        // recover blocked users
        //
        NSString *blockedString = [responseD valueForKey:@"BLOCK_USERS"];
        if ([blockedString length] > 0) {
            
            NSArray *blockedIDs = [blockedString componentsSeparatedByString:@","];
            
            [[MPHTTPCenter sharedMPHTTPCenter] getUserInformation:blockedIDs action:kMPHCQueryTagQuery idTag:kMPHCQueryIDTagBlockedRecovery itemType:kMPHCItemTypeUserID];
            
        }
        // if no blocked users, then update nickname
        else {
            // request name update
            [[MPHTTPCenter sharedMPHTTPCenter] updateNickname:self.tempName];
        }
        
    }
    // did not succeed
    else {
        detMessage = NSLocalizedString(@"Name update failed. Try again.", @"UpdateName - alert: inform of failure");
    }
    
    if (detMessage) {
        [AppUtility stopActivityIndicator];
        [Utility showAlertViewWithTitle:title message:detMessage];
    }
}


/*!
 @abstract process blocked recovered
 - continue with name update
 
 */
- (void) processBlockedRecovered:(NSNotification *)notification {
    
    DDLogInfo(@"NR-pbr: process block recovery");

    // request name update
    [[MPHTTPCenter sharedMPHTTPCenter] updateNickname:self.tempName];
    
    
}


/*!
 @abstract process udpate status results
 */
- (void) processUpdateName:(NSNotification *)notification {
        
    DDLogInfo(@"NR-pun: process update name - VC:%@", self);

    NSDictionary *responseD = [notification object];
    
    MPCauseType cause = [MPHTTPCenter getCauseForResponseDictionary:responseD];
    
    NSString *title = NSLocalizedString(@"Update Name", @"UpdateName - alert title:");
    
    NSString *detMessage = nil;
    
    // ask to confirm
    if (cause == kMPCauseTypeSuccess) {
        
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingNickName settingValue:self.tempName];

        self.nameField.text = self.tempName;
        
        // also update the my CDContact
        [CDContact updateMyNickname:self.tempName domainClusterName:nil domainServerName:nil statusMessage:nil];
        
    }
    // did not succeed
    else {
        detMessage = NSLocalizedString(@"Name update failed. Try again.", @"UpdateName - alert: inform of failure");
    }
    if (detMessage) {
        
        [Utility showAlertViewWithTitle:title message:detMessage];
       
    }
    // success, dismiss view
    else {
        
        // no more notification needed
        //
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        // only respond if we are the visiable VC
        if (self.navigationController.visibleViewController == self) {
            if (self.isRegistration) {
                
                // Login now since we are finished with registration
                // - will also send helper message
                //
                DDLogInfo(@"NR: name reg done so - start AALogin");
                //[[MPHTTPCenter sharedMPHTTPCenter] performSelector:@selector(authenticateAndLogin) withObject:nil afterDelay:0.2];
                [[MPHTTPCenter sharedMPHTTPCenter] authenticateAndLogin];
                
                if (!self.didDismissAlready) {
                    DDLogInfo(@"NR: dismissing view controller");
                    self.didDismissAlready = YES;
                    [self dismissModalViewControllerAnimated:YES];
                }
            }
            else {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    }
    
    [AppUtility stopActivityIndicator];
}

#pragma mark - TextViewDelegate


/*!
 @abstract called whenever text if modified
 */
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {  
    
    BOOL shouldChange = YES;
    
    // the preview string itself
    NSString *previewString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    previewString = [Utility trimWhiteSpace:previewString];
    
    // number of characters
    NSInteger previewCharCount = [previewString length]; // [textField.text length] + [string length] - range.length;
    NSInteger currentCharCount = [textField.text length];
    NSString *charString = [NSString stringWithFormat:@"%d/%d", previewCharCount, kMPParamNameLengthMax];
    NSString *countMessage = nil;

    
    UILabel *countLabel = (UILabel *)[self.view viewWithTag:COUNT_TAG];
    
    NSString *message = @"";
    
    // if at max, just warn so independent
    //
    if (previewCharCount == kMPParamNameLengthMax) {
        message = NSLocalizedString(@"Reached limit", @"Name - text: reached max length of name");
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
    }
    
    // over max, don't change
    if (previewCharCount > kMPParamNameLengthMax) {
        // don't go over max
        shouldChange = NO;
    }
    // if less than min, 
    else if (previewCharCount < kMPParamNameLengthMin) {
        message = [NSString stringWithFormat:NSLocalizedString(@"Min %d characters", @"Name - text: has not surpassed minimum"), kMPParamNameLengthMin];
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
    }
    else if (![self isNameValid:previewString]) {
        message = NSLocalizedString(@"Special characters not allowed", @"Name - text: warn about adding special characters");
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
    }
    // ok otherwise
    //
    else {
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeBackgroundText];
    }
    
    
    
    // if change, then upate message - otherwise we don't need to
    if (shouldChange) {
        countMessage = [NSString stringWithFormat:@"%@ %@", message, charString];
        countLabel.text = countMessage;
        
        // only if min char and format is valid, enable done button
        if ([self isNameValid:previewString]) {
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
        else {
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
    }
    // if no change allowed and already at the max - show red text
    else if ([textField.text length] == kMPParamNameLengthMax) {
        message = NSLocalizedString(@"Reached limit", @"Name - text: reached max length of name");
        NSString *charString = [NSString stringWithFormat:@"%d/%d", currentCharCount, kMPParamNameLengthMax];
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
        countMessage = [NSString stringWithFormat:@"%@ %@", message, charString];
        countLabel.text = countMessage;
    }
    // if increase but not at max.. this should not happen unless paste lots of text
    
    return shouldChange;
}



@end
