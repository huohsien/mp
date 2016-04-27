//
//  CreateIDController.m
//  mp
//
//  Created by M Tsai on 11-11-23.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "CreateIDController.h"
#import "MPFoundation.h"

NSUInteger const kMPParamIDLengthMin = 5;
NSUInteger const kMPParamIDLengthMax = 20;



@implementation CreateIDController

@synthesize idField;
@synthesize tempMPID;
@synthesize didPressSubmit;


- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    idField.delegate = nil;
    
    [idField release];
    [tempMPID release];
    [super dealloc];
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


#define TEXTFIELD_TAG       15000
#define COUNT_TAG           15001
#define SUBMIT_BUTTON_TAG   15002
#define CREATEOK_ALERT_TAG  15003

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    self.didPressSubmit = NO;
    
    self.title = NSLocalizedString(@"Create ID", @"CreateID - title");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];

    
    // background
    //
    UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    backView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = backView;
    [backView release];            
    
    // bear image
    //
    UIImageView *bearImage = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, 5.0, 90.0, 75.0)];
    bearImage.image = [UIImage imageNamed:@"std_icon_bear_sayhi.png"];
    [self.view addSubview:bearImage];
    [bearImage release];
                    
    
    // intro text
    //
    UILabel *iLabel = [[UILabel alloc] initWithFrame:CGRectMake(100.0, 10.0, 205.0, 70.0)];
    [AppUtility configLabel:iLabel context:kAULabelTypeBackgroundText];
    iLabel.text = NSLocalizedString(@"<create id description>", @"CreateID - text: describes what M+ID is for");
    iLabel.numberOfLines = 5;
    [self.view addSubview:iLabel];
    [iLabel release];
    
    
    // textfield background image
    //
    UIImageView *textBackImage = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, 90.0, 245.0, 45.0)];
    textBackImage.image = [Utility resizableImage:[UIImage imageNamed:@"std_icon_textbar.png"] leftCapWidth:9.0 topCapHeight:22.0];
    textBackImage.userInteractionEnabled = YES;
    [self.view addSubview:textBackImage];
    
    // textfield
    // 
    UITextField *tField = [[UITextField alloc] initWithFrame:CGRectMake(10.0, 10.0, 225.0, 25.0)];
    tField.placeholder = NSLocalizedString(@"Enter ID you want to create", @"CreateID - text placeholder: ask users to enter a M+ ID that they want");
    [AppUtility configTextField:tField context:kAUTextFieldTypeBasic];
    tField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tField.delegate = self;
    tField.tag = TEXTFIELD_TAG;
    [textBackImage addSubview:tField];
    self.idField = tField;
    [self.idField becomeFirstResponder];
    [textBackImage release];
    
    
    // char count
    //
    //CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(5.0, 135.0, 240.0, 20.0)];
    [AppUtility configLabel:countLabel context:kAULabelTypeBackgroundText];
    countLabel.textAlignment = UITextAlignmentRight;
    countLabel.text = [NSString stringWithFormat:@"%d/%d", [self.idField.text length], kMPParamIDLengthMax];
    countLabel.tag = COUNT_TAG;
    [self.view addSubview:countLabel];
    [countLabel release];
    
    // restriction label
    //
    /*
    UILabel *restrictionLabel1 = [[UILabel alloc] init];
    [AppUtility configLabel:restrictionLabel1 context:kAULabelTypeBackgroundTextHighlight];
    restrictionLabel1.text = NSLocalizedString(@"ID must be ", @"CreateID - text: M+ID restriction text part 1");
    
    UILabel *restrictionLabel2 = [[UILabel alloc] init];
    [AppUtility configLabel:restrictionLabel2 context:kAULabelTypeBackgroundTextCritical];
    restrictionLabel2.text = NSLocalizedString(@"3", @"CreateID - text: M+ID restriction text part 2");
    
    
    UILabel *restrictionLabel3 = [[UILabel alloc] init];
    [AppUtility configLabel:restrictionLabel3 context:kAULabelTypeBackgroundTextHighlight];
    restrictionLabel3.text = NSLocalizedString(@" - ", @"CreateID - text: M+ID restriction text part 3");
    
    
    UILabel *restrictionLabel4 = [[UILabel alloc] init];
    [AppUtility configLabel:restrictionLabel4 context:kAULabelTypeBackgroundTextCritical];
    restrictionLabel4.text = NSLocalizedString(@"20", @"CreateID - text: M+ID restriction text part 4");
    
    
    UILabel *restrictionLabel5 = [[UILabel alloc] init];
    [AppUtility configLabel:restrictionLabel5 context:kAULabelTypeBackgroundTextHighlight];
    restrictionLabel5.text = NSLocalizedString(@" characters", @"CreateID - text: M+ID restriction text part 5");
    
    NSArray *labels = [NSArray arrayWithObjects:restrictionLabel1, restrictionLabel2, restrictionLabel3, restrictionLabel4, restrictionLabel5, nil];

    [restrictionLabel1 release];
    [restrictionLabel2 release];
    [restrictionLabel3 release];
    [restrictionLabel4 release];
    [restrictionLabel5 release];
    
    UIView *restrictionView = [[UIView alloc] initWithFrame:CGRectMake(15.0, 140.0, 295.0, 10.0)];
    restrictionView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    restrictionView.opaque = YES;
    [Utility addLabelsToView:restrictionView labelArray:labels textAlignment:UITextAlignmentLeft];
    [self.view addSubview:restrictionView];
    [restrictionView release];
     */

    
    // submit button
    //
    UIButton *submitButton = [[UIButton alloc] initWithFrame:CGRectMake(255.0, 90.0, 60.0, 45.0)];
    [AppUtility configButton:submitButton context:kAUButtonTypeGreen5];
    [submitButton addTarget:self action:@selector(pressSubmit:) forControlEvents:UIControlEventTouchUpInside];
    [submitButton setTitle:NSLocalizedString(@"Create", @"CreateID - button: ok to submit ID") forState:UIControlStateNormal];
    submitButton.enabled = NO;
    submitButton.tag = SUBMIT_BUTTON_TAG;
    [self.view addSubview:submitButton];
    [submitButton release];
    
    // submit button - old location
    //
    /*UIButton *submitButton = [[UIButton alloc] initWithFrame:CGRectMake(115.0, 160.0, 90.0, 30.0)];
    [AppUtility configButton:submitButton context:kAUButtonTypeGreen];
    [submitButton addTarget:self action:@selector(pressSubmit:) forControlEvents:UIControlEventTouchUpInside];
    [submitButton setTitle:NSLocalizedString(@"Create", @"CreateID - button: ok to submit ID") forState:UIControlStateNormal];
    submitButton.tag = SUBMIT_BUTTON_TAG;
    submitButton.enabled = NO;
    [self.view addSubview:submitButton];
    [submitButton release];*/

    
    // add observers
    
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processSearch:) name:MP_HTTPCENTER_SEARCHID_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processCreate:) name:MP_HTTPCENTER_CREATEID_NOTIFICATION object:nil];
    
    
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
    DDLogInfo(@"CIC-vwa");
    [super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Button



/*!
 @abstract has special characters
 */
- (BOOL)hasSpecialCharacters:(NSString *)testString {
    
    BOOL hasSC = YES;
    
    // can't have any symbols
    NSArray *symbolParts = [testString componentsSeparatedByCharactersInSet:[NSCharacterSet symbolCharacterSet]];
    NSArray *punctParts = [testString componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
    
    if ([symbolParts count] == 1 && [punctParts count] == 1) {
        hasSC = NO;
    }
    return hasSC;
}


/*!
 @abstract Check if M+ ID is valid
 - 5 characters
 - no special chars
 
 */
- (BOOL)isIDValid:(NSString *)testID{
    
    BOOL isValid = NO;
    
    NSInteger nameLen = [testID length];
    
    if (nameLen >= kMPParamIDLengthMin && 
        nameLen <= kMPParamIDLengthMax && 
        ![self hasSpecialCharacters:testID]
        ) 
    {
        isValid = YES;
    }
    return isValid;
}


/*!
 @abstract pressed submit button - checks for duplicates
 */
- (void)pressSubmit:(id) sender {
        
    // check if valid
    //
    if ([self isIDValid:self.idField.text]) {
        if (self.didPressSubmit == NO) {
            self.didPressSubmit = YES;
            // get rid of white space
            self.tempMPID = [Utility trimWhiteSpace:self.idField.text];
            [[MPHTTPCenter sharedMPHTTPCenter] searchID:self.tempMPID];
        }
    }
    else {
        NSString *alertTitle = NSLocalizedString(@"Invalid ID", @"CreateID - alert title");
        NSString *alertMessage = NSLocalizedString(@"ID cannot contain any special characters.",@"CreateID - alert: ID is invalid");
        [Utility showAlertViewWithTitle:alertTitle message:alertMessage];
    }
}

#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
        
    // dismiss view after create succeeded
    //
    if (alertView.tag == CREATEOK_ALERT_TAG) {
        self.didPressSubmit = NO;
        // dismiss this view
        [self.navigationController popViewControllerAnimated:YES];
    }
    // confirm new ID to be created
	else if (buttonIndex != [alertView cancelButtonIndex]) {
		[[MPHTTPCenter sharedMPHTTPCenter] createID:self.tempMPID];
	}
    // pressed cancel
    else {
        self.didPressSubmit = NO;
    }
}


#pragma mark - Handle Response

/*!
 @abstract process search command
 
 - used to check if duplicate exists, check before submiting
 - ask user to confirm the ID creation
 
 */
- (void) processSearch:(NSNotification *)notification {
    
    NSDictionary *responseD = [notification object];
    
    NSString *presence = [responseD valueForKey:@"text"];
    
    MPPresence *searchPresence = [[MPPresence alloc] initWithPresenceString:presence];
    
    // notify user of duplicate
    if ([AppUtility isUserIDValid:searchPresence.aUserID]) {
        
        // allow submit button to work again
        self.didPressSubmit = NO;
        
        NSString *alertTitle = NSLocalizedString(@"ID Already Exists", @"CreateID - alert title: inform user that id already exits");
        NSString *alertMessage = NSLocalizedString(@"Try a different ID.", @"CreateID - alert message: ask user to try entering a different ID");
        [Utility showAlertViewWithTitle:alertTitle message:alertMessage];
        
    }
    // ask to confirm
    else {
        
        
        NSString *alertTitle = NSLocalizedString(@"Confirm ID", @"CreateID - alert title:");
        NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Do you want to create the ID: '%@'? Once you confirm, you will not be able to change it later.", @"CreateID - alert: Confirm id creation with user"), self.tempMPID];
        
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:alertTitle
                                                         message:alertMessage
                                                        delegate:self
                                               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Alert: Cancel button") 
                                               otherButtonTitles:NSLocalizedString(@"Confirm", @"Alert: Confirm button"), nil] autorelease];
        [alert show];
        
        
    }
    [searchPresence release];
}


/*!
 @abstract process create command
 
 - if sucessful, save ID to settings
 
 Example URL:
 
 HTTP get : https://61.66.229.118/CreateMPID?USERID=20114567&MPID=NaturalTel-Julian 
 
 USERID : Message Plus user-ID : 8 digits ( 00000001 ~ 99999999 ) , unique number of system . MPID : User defined unique ID for searching purpose . Max 24 bytes . This id is unique in system
 and cannot be changed or removed by the User .
 
 HTTP response :
 
 Success:
 < CreateMPID > <cause>0</cause>
 </ CreateMPID >
 
 Error:
 < CreateMPID > <cause>705</cause>
 <text>MPID duplicated !</text> </ CreateMPID >
 
 
 */
- (void) processCreate:(NSNotification *)notification {
    
    NSDictionary *responseD = [notification object];
    

    NSString *detMessage = nil;

    // ask to confirm
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingMPID settingValue:self.tempMPID];
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingMPIDSearch settingValue:[NSNumber numberWithBool:YES]];
        
        NSString *title = NSLocalizedString(@"Create ID Succeeded", @"CreateID - alert title: create succeeded");
        detMessage = [NSString stringWithFormat:NSLocalizedString(@"Your M+ ID '%@' is created. Now people can find you with this ID", @"CreateID - alert: inform of success"), self.tempMPID];
        
        //[Utility showAlertViewWithTitle:title message:detMessage];
        [Utility showAlertViewWithTitle:title message:detMessage delegate:self tag:CREATEOK_ALERT_TAG];
        
        // dismiss this view
        //[self.navigationController popViewControllerAnimated:YES];
    }
    // did not succeed
    else {
        NSString *title = NSLocalizedString(@"Create ID Failed", @"CreateID - alert tiltle: create failed");
        detMessage = [NSString stringWithFormat:NSLocalizedString(@"ID creation failed. Try again.", @"CreateID - alert: inform of failure")];
        [Utility showAlertViewWithTitle:title message:detMessage];
    }

}




#pragma mark - TextViewDelegate


/*!
 @abstract called whenever text if modified
 */

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
    NSString *charString = nil;
    NSString *countMessage = nil;
    
    
    UILabel *countLabel = (UILabel *)[self.view viewWithTag:COUNT_TAG];
    
    NSString *message = @"";
    
    // if at max, just warn so independent
    //
    if (previewCharCount == kMPParamIDLengthMax) {
        message = NSLocalizedString(@"Reached limit", @"FindID - text: reached max length of name");
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
    }
    
    // over max, don't change
    if (previewCharCount > kMPParamIDLengthMax) {
        // don't go over max
        shouldChange = NO;
    }
    else if ([self hasSpecialCharacters:previewString]) {
        message = NSLocalizedString(@"Special characters not allowed", @"FindID - text: warn about adding special characters");
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
        shouldChange = NO;
    }
    // if less than min, 
    else if (previewCharCount < kMPParamIDLengthMin) {
        message = [NSString stringWithFormat:NSLocalizedString(@"Min %d characters", @"FindID - text: has not surpassed minimum"), kMPParamIDLengthMin];
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
    }
    // ok otherwise
    //
    else {
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeBackgroundText];
    }
    
    // if change, then upate message - otherwise we don't need to
    if (shouldChange) {
        charString = [NSString stringWithFormat:@"%d/%d", previewCharCount, kMPParamIDLengthMax];
        
        UIButton *submitB = (UIButton *)[self.view viewWithTag:SUBMIT_BUTTON_TAG];
        
        // only if min char and format is valid, enable done button
        if (previewCharCount > 2 && [self isIDValid:previewString]) {
            submitB.enabled = YES;
        }
        else {
            submitB.enabled = NO;
        }
    }
    else {
        charString = [NSString stringWithFormat:@"%d/%d", currentCharCount, kMPParamIDLengthMax];
        
        // if no change allowed and already at the max - show red text
        if ([textField.text length] == kMPParamIDLengthMax) {
            message = NSLocalizedString(@"Reached limit", @"Name - text: reached max length of name");
            countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
        }
    }
    
    countMessage = [NSString stringWithFormat:@"%@ %@", message, charString];
    countLabel.text = countMessage;
    
    // if increase but not at max.. this should not happen unless paste lots of text
    
    return shouldChange;
}


/*
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {  
    
    BOOL shouldChange = YES;
    
    // the preview string itself
    NSString *previewString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    // number of characters
    NSInteger previewCharCount = [previewString length]; // [textField.text length] + [string length] - range.length;
    NSInteger currentCharCount = [textField.text length];
    NSString *charString = [NSString stringWithFormat:@"%d/%d", previewCharCount, kMPParamIDLengthMax];
    NSString *countMessage = nil;
    
    
    UILabel *countLabel = (UILabel *)[self.view viewWithTag:COUNT_TAG];
    
    NSString *message = @"";
    
    // if at max, just warn so independent
    //
    if (previewCharCount == kMPParamIDLengthMax) {
        message = NSLocalizedString(@"Reached limit", @"CreateID - text: reached max length of name");
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
    }
    
    // over max, don't change
    if (previewCharCount > kMPParamIDLengthMax) {
        // don't go over max
        shouldChange = NO;
    }
    // if less than min, 
    else if (previewCharCount < kMPParamIDLengthMin) {
        message = [NSString stringWithFormat:NSLocalizedString(@"Min %d characters", @"CreateID - text: has not surpassed minimum"), kMPParamIDLengthMin];
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
    }
    else if (![self isIDValid:previewString]) {
        message = NSLocalizedString(@"Special characters not allowed", @"CreateID - text: warn about adding special characters");
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
    }
    // ok otherwise
    //
    else {
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeBackgroundText];
    }
    
    
    
    // if change, then upate message - otherwise we don't need to
    if (shouldChange) {
        
        UIButton *submitB = (UIButton *)[self.view viewWithTag:SUBMIT_BUTTON_TAG];
        
        countMessage = [NSString stringWithFormat:@"%@ %@", message, charString];
        countLabel.text = countMessage;
        
        // only if min char and format is valid, enable done button
        if (previewCharCount > 2 && [self isIDValid:previewString]) {
            submitB.enabled = YES;
        }
        else {
            submitB.enabled = NO;
        }
    }
    // if no change allowed and already at the max - show red text
    else if ([textField.text length] == kMPParamIDLengthMax) {
        message = NSLocalizedString(@"Reached limit", @"Name - text: reached max length of name");
        NSString *charString = [NSString stringWithFormat:@"%d/%d", currentCharCount, kMPParamIDLengthMax];
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
        countMessage = [NSString stringWithFormat:@"%@ %@", message, charString];
        countLabel.text = countMessage;
    }
    // if increase but not at max.. this should not happen unless paste lots of text
    
    return shouldChange;
}
*/



@end
