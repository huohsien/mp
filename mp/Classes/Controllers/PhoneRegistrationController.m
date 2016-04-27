//
//  PhoneRegistrationController.m
//  mp
//
//  Created by M Tsai on 11-10-14.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "PhoneRegistrationController.h"

#import "Utility.h"
#import "MPFoundation.h"
#import "VerifySMSCodeController.h"
#import "CountryInfo.h"

@implementation PhoneRegistrationController

@synthesize countryCodeField;
@synthesize countryButton;
@synthesize phoneField;

@synthesize countryDictionary;

//@synthesize urlConnection;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [countryCodeField release];
    [countryButton release];
    [phoneField release];
    [countryDictionary release];
    
    //[urlConnection release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}



/*! getter for country dictionary */
- (NSDictionary *)countryDictionary{
    
    if (countryDictionary) {
        return countryDictionary;
    }
    
	// read in country data
    //
    
    NSError *error = nil;
    
    // format of file:
    // country name, 2letter code, phone code
    //
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"CountryData" ofType:@"csv"];	
	NSString *readStrings = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
	
	NSArray *lines = [readStrings componentsSeparatedByString:@"\r\n"];
	NSLog(@"lines: %d %@", [lines	count], error);
    
    NSMutableArray *infos = [[[NSMutableArray alloc] init] autorelease];
    
    for (NSString *line in lines){
		
        NSArray *words = [line componentsSeparatedByString:@","];
        NSString *name = [words objectAtIndex:0];
        NSString *isoCode = [words objectAtIndex:1];
        NSString *phoneCode = [words objectAtIndex:2];
        
        CountryInfo *iCountryInfo = [[CountryInfo alloc] initWithName:name isoCode:isoCode phoneCountryCode:phoneCode];
        [infos addObject:iCountryInfo];
        [iCountryInfo release];
        
    }
    [readStrings release];
    
    // create dictionary for countries
    //
    countryDictionary = [[NSMutableDictionary alloc] init];
    for (CountryInfo *iInfo in infos){
        [countryDictionary setObject:iInfo forKey:iInfo.isoCode];
    }

    return countryDictionary;
}

#pragma mark - Utility Methods

/*!
 @abstract gets country code using the device's current IP
 
 */
- (NSString *)getCountryTwoLetterCodeWithIP {
   
    NSString *ipAddress = [[UIDevice currentDevice] getIPAddress3G];
    
    // perform network query to find the country for IP
    //
    
    NSString *urlString = [NSString stringWithFormat:@"http://api.ipinfodb.com/v3/ip-country/?key=6fba48c4c8e236bf967e14a4cfb59a0c3765e90df9ad562b9b4963ada58aab4d&format=raw&ip=%@", ipAddress]; 
    
    DDLogVerbose(@"PRC-gct: usrl %@", urlString);
    
    NSError* error = nil;
    NSString* resultText = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString] encoding:NSASCIIStringEncoding error:&error];

    DDLogVerbose(@"GeoLoc - result: %@", resultText);
    if ([resultText hasPrefix:@"OK"]) {
        NSArray *toks = [resultText componentsSeparatedByString:@";"];
        if ([toks count] == 5) {
            NSString *countryCode = [toks objectAtIndex:3];
            if ([countryCode length] == 2) {
                return countryCode;
            }
        }
    }
    else 
    {
        DDLogVerbose(@"Error = %@", error);
    }
    return nil;
}





/*!
 @abstract updates view given a new country code
 
 @param countryCode 2 letter ISO code
 
 Use:
 - updates country values from automatic IP query
 - or from manual selection
 */
- (void)setCountryCode:(NSString *)countryCode {
    
    CountryInfo *countryInfo = [self.countryDictionary objectForKey:countryCode];
    
    if (countryInfo) {
        NSString *name = countryInfo.name;
        NSString *phoneCode = countryInfo.phoneCountryCode;
        
        [self.countryButton setTitle:name forState:UIControlStateNormal];
        self.countryCodeField.text = phoneCode;
        
        // add default starter if phoneField is empty to help users
        // - 2 chars in case other default string was present
        //
        if ([self.phoneField.text length] < 3) {
            if ([countryCode isEqualToString:@"TW"]) {
                self.phoneField.text = @"09";
            }
            else if ([countryCode isEqualToString:@"CN"]) {
                self.phoneField.text = @"1";
            }
            else {
                self.phoneField.text = @"";
            }
        }
    }
}


/*!
 @abstract check if numbers are valid mobile numbers
 
 Use:
 - only digits except + sign in CC
 - check total length
 - check phone length
 - check starting number for TW, CN, HK
 - check if non numbers present
 
 */
- (BOOL)isValidateCountryCode:(NSString *)countryCode phoneNumber:(NSString *)phoneNumber{
    
    BOOL isValid = NO;
    
    NSUInteger phoneLength = [phoneNumber length];
    NSUInteger countryLength = [countryCode length];
    
    // only if all numbers except the + sign in CC
    NSCharacterSet *nonDecimalSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSString *noPlusCC = [countryCode stringByReplacingOccurrencesOfString:@"+" withString:@""];
    NSArray *ccParts = [noPlusCC componentsSeparatedByCharactersInSet:nonDecimalSet];
    NSArray *phoneParts = [phoneNumber componentsSeparatedByCharactersInSet:nonDecimalSet];
    
    
    if ([ccParts count] == 1 && [phoneParts count] == 1) {
        
        // valid phone nubmer
        if (phoneLength > 6 && // at least 7 
            phoneLength+countryLength < 17  && // at most 15 and + char (ITU max international number)
            countryLength > 2 && // at least 3
            countryLength < 6) // at most 4 and + char
        { 
            // valid country mobile phone
            if ([countryCode isEqualToString:@"886"] || [countryCode isEqualToString:@"+886"]) {
                if ([phoneNumber hasPrefix:@"9"] && [phoneNumber length] == 9) {
                    isValid = YES;
                }
                if ([phoneNumber hasPrefix:@"09"] && [phoneNumber length] == 10) {
                    isValid = YES;
                }
            }
            else if ([countryCode isEqualToString:@"86"] || [countryCode isEqualToString:@"+86"]) {
                if ([phoneNumber hasPrefix:@"1"] && [phoneNumber length] == 11) {
                    isValid = YES;
                }
            }
            else if ([countryCode isEqualToString:@"852"] || [countryCode isEqualToString:@"+852"]) {
                if ([phoneNumber length] == 8 &&
                    ([phoneNumber hasPrefix:@"5"] || 
                     [phoneNumber hasPrefix:@"6"] || 
                     [phoneNumber hasPrefix:@"9"]) 
                    ) 
                {
                    isValid = YES;
                }
            }
            else {
                isValid = YES;
            }
        }
    }
                          
                          
                          
   
    return isValid;
}



#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    
    UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view = backView;
    [backView release];
    self.view.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];

        
    // add country label
    //
    UILabel *countryLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 7.0, 150.0, 16.0)];
    [AppUtility configLabel:countryLabel context:kAULabelTypeGrayMicroPlus];
    //countryLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    countryLabel.text = NSLocalizedString(@"Country code", @"Phone Registration - Label: for country code info");
    countryLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    [self.view addSubview:countryLabel];
    [countryLabel release];
    

    
    // add country code textfield
    //
    UITextField *ccField = [[UITextField alloc] initWithFrame:CGRectMake(5.0, 27.0, 60.0, 45.0)];
    [AppUtility configTextField:ccField context:kAUTextFieldTypePhone];
    ccField.text = NSLocalizedString(@"+1", @"Phone Registration - Text: default country code for this language");
    ccField.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:ccField];
    self.countryCodeField = ccField;
    [ccField release];
    
    
    // add country button
    //
    UIButton *cButton = [[UIButton alloc] initWithFrame:CGRectMake(70.0, 27.0, 245.0, 45.0)];
    [AppUtility configButton:cButton context:kAUButtonTypeTextBar];
    [cButton setTitle:NSLocalizedString(@"United States", @"Phone Registration - Text default: default country for this language") forState:UIControlStateNormal];
    
    cButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
    [cButton addTarget:self action:@selector(pressCountry:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cButton];
    self.countryButton = cButton;
    [cButton release];
    
    
    // add phone description label
    //
    UILabel *phoneLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 77.0, 200.0, 16.0)];
    [AppUtility configLabel:phoneLabel context:kAULabelTypeGrayMicroPlus];
    phoneLabel.text = NSLocalizedString(@"Enter your cell phone number", @"Phone Registration - Label: command to enter phone number");
    phoneLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    [self.view addSubview:phoneLabel];
    [phoneLabel release];
    
    
    // add phone text field 
    //
    UITextField *pField = [[UITextField alloc] initWithFrame:CGRectMake(5.0, 97.0, 150.0, 45.0)];
    [AppUtility configTextField:pField context:kAUTextFieldTypePhone];
    pField.placeholder = NSLocalizedString(@"Cell Phone Number", "Phone Registration - Placeholder: instruct user to enter cell phone number");
    pField.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:pField];
    self.phoneField = pField;
    [pField release];
    
    
    // add view description label
    //
    UILabel *viewLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 145.0, 300.0, 30.0)];
    viewLabel.font = [UIFont systemFontOfSize:12];
    viewLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    viewLabel.textColor = [AppUtility colorForContext:kAUColorTypeBlue2];
    viewLabel.numberOfLines = 2;
    viewLabel.lineBreakMode = UILineBreakModeWordWrap;
    viewLabel.text = NSLocalizedString(@"To verify user identification, a SMS message will be sent to your phone.", @"Phone Registration - Label: describes purpose of phone registration");
    [self.view addSubview:viewLabel];
    [viewLabel release];
    
    
    // get the country for this device's IP
    //
    //NSString *countryCode = [self getCountryTwoLetterCodeWithIP];
    
    // 1 - Use locale information instead
    //
    NSString *countryCode = [Utility currentLocalCountryCode];
    DDLogVerbose(@"PRC-lv: got country - %@", countryCode);
    [self setCountryCode:countryCode];

    
    // allow editing of phone number immediately
    //
    [self.phoneField becomeFirstResponder];
    
    // listen for success
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(proceedToRegistration) name:MP_HTTPCENTER_MSISDN_SUCCESS_NOTIFICATION object:nil];
    
    // listen if already registered on another phone
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(confirmMultiDevice) name:MP_HTTPCENTER_MSISDN_MULTIDEVICE_NOTIFICATION object:nil];
    
    // ip query is done - fail or success
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(handleIPQueryMSISDN:) name:MP_HTTPCENTER_IPQUERY_MSISDN_NOTIFICATION object:nil];
    
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    // set title of the page
    //
    self.title = NSLocalizedString(@"Enter Phone Number", @"Phone Registration - Title: navigation title this view");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    // don't show EULA back button
    //
    self.navigationItem.hidesBackButton = YES;
    
    // add next navigation button
    //
	
    UIBarButtonItem *nextButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Next", @"Phone Registration - Button: go to next step") 
                                                      buttonType:kAUButtonTypeBarHighlight 
                                                          target:self action:@selector(pressNext:)];
	self.navigationItem.rightBarButtonItem = nextButton;
    
    // if phone already registered push next view
    //
    NSString *msisdn = [[MPSettingCenter sharedMPSettingCenter] getMSISDN];
    if ([msisdn length] > 4) {

        VerifySMSCodeController *nextController = [[VerifySMSCodeController alloc] init];
        [self.navigationController pushViewController:nextController animated:NO];
        [nextController release];
        
    }
    
    // 2 - If available, use phone found by reverse lookup
    // TODO: provide statistics to PS server for this TWM3GIP=Y
    
    NSString *cc = [[MPHTTPCenter sharedMPHTTPCenter] getCountryCode];
    NSString *phone = [[MPHTTPCenter sharedMPHTTPCenter] getPhoneNumber];
    
    if ([cc length] == 3 && [phone length] == 9) {
        
        DDLogInfo(@"PR: using reverse lookup ph# %@ %@", cc, phone);
        self.countryCodeField.text = cc;
        
        // prefix a 0 to the mobile number
        self.phoneField.text = [@"0" stringByAppendingString:phone];
    }
    else {
        self.phoneField.text = @"";
    }
}


- (void)viewDidUnload
{
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

/*!
 @abstract loads phone number from reverse lookup if provided
 
 */
- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    
    //[AppUtility startActivityIndicator];
    //[[MPHTTPCenter sharedMPHTTPCenter] ipQueryMsisdn];
    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Button Methods

#define MULTIDEVICE_ALERT_TAG 16001
#define VERIFICATION_INTRO_ALERT_TAG    16002

/*!
 @abstract Submits phone number to get SMS
 */
- (void)submitMSISDNConfirmMultiDeviceRegistration:(BOOL)confirm {
    
    [[MPHTTPCenter sharedMPHTTPCenter] requestRegistrationCountryCode:self.countryCodeField.text phoneNumber:self.phoneField.text confirmMultiDeviceRegistration:confirm];

}

/*!
 @abstract Submits phone number to get SMS
 
 Use:
 - if msisdn is successful, then go to next view
 
 */
- (void)proceedToRegistration {
    
    // only push if we are viewing this controller
    if (self.navigationController.visibleViewController == self){
        
        // push next view onto navigation stack
        //
        VerifySMSCodeController *nextController = [[VerifySMSCodeController alloc] init];
        [self.navigationController pushViewController:nextController animated:YES];
        [nextController release];
    }
    

}


/*!
 @abstract Confirm is user wants to install on another device and disable previous accout
 
 Use:
 - if server informs of multi device registration
 
 */
- (void)confirmMultiDevice {
    NSString *message = NSLocalizedString(@"<multi device warning message>", @"PhoneRegistration - alert: Asks users if they really want to register on a another device, since their old account will be disabled");
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:nil
                                                     message:message
                                                    delegate:nil
                                           cancelButtonTitle:NSLocalizedString(@"Cancel", @"Alert: Cancel button") 
                                           otherButtonTitles:NSLocalizedString(@"OK", @"Alert: OK button"), nil] autorelease];
    alert.tag = MULTIDEVICE_ALERT_TAG;
    alert.delegate = self;
    [alert show];
    
}

/*
 @abstract Handle IPQueryMSISDN query response
 - done quering
 - if phone values are available fill them in for the user

 */
- (void) handleIPQueryMSISDN:(NSNotification *)notification {
    [AppUtility stopActivityIndicator];
    
    NSString *cc = [[MPHTTPCenter sharedMPHTTPCenter] getCountryCode];
    NSString *phone = [[MPHTTPCenter sharedMPHTTPCenter] getPhoneNumber];
    
    if ([cc length] == 3 && [phone length] == 9) {
        
        DDLogInfo(@"PR: using reverse lookup ph# %@ %@", cc, phone);
        self.countryCodeField.text = cc;
        
        // prefix a 0 to the mobile number
        self.phoneField.text = [@"0" stringByAppendingString:phone];
    }
    else {
        self.phoneField.text = @"";
    }
}


/*!
 pushes a country selection tableview
 
 */
- (void)pressCountry:(id)sender {
    
    [self.phoneField resignFirstResponder];
    [self.countryCodeField resignFirstResponder];
    
    CountrySelectController *nextController = [[CountrySelectController alloc] initWithStyle:UITableViewStylePlain];
    nextController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:nextController];
    [nextController release];
    [AppUtility customizeNavigationController:navController];
    
    [self presentModalViewController:navController animated:YES];
    [navController release];
}

/*!
 @abstract strip non critical chars
 */
- (NSString *)stripExtraChars:(NSString *)numberString {
    
    NSCharacterSet *extraSet = [NSCharacterSet characterSetWithCharactersInString:@"()-. "];
    NSString *strippedString = [[numberString componentsSeparatedByCharactersInSet:extraSet] componentsJoinedByString:@""];   
    return strippedString;
}


/*!
 submits phone registration and goes to the next step
 */
- (void) pressNext:(id)sender {
    
    // Check if country code and phone number makes sense
    //
    NSString *processedCC = [self stripExtraChars:self.countryCodeField.text];
    NSString *processedPhone = [self stripExtraChars:self.phoneField.text];
    
    // not valid - show alert and don't proceed
    //
    if (![self isValidateCountryCode:processedCC phoneNumber:processedPhone]) {
        
        // present an alert view to explain further
        //
        NSString *alertTitle = NSLocalizedString(@"Invalid Phone Number", @"PhoneRegistration - Alert: title");
        NSString *alertMessage = NSLocalizedString(@"The phone number you entered is invalid. Please try again.", @"Phone Registration - Alert: phone number is invalid");
        [Utility showAlertViewWithTitle:alertTitle message:alertMessage];
        
    }
    else {
        
        [self.phoneField resignFirstResponder];
        [self.countryCodeField resignFirstResponder];
        
        // show alert
        //
        NSString *strippedPhone = [AppUtility stripZeroPrefixForString:self.phoneField.text];
        NSString *phoneNumber = [Utility formatPhoneNumber:strippedPhone countryCode:self.countryCodeField.text showCountryCode:YES];
        
        // present an alert view to explain further
        //
        NSString *detailedMessage = NSLocalizedString(@"<detailed phone registration explanation>", @"Phone Registration - Alert: detail explaination about phone registration");
        
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:phoneNumber
                                                         message:detailedMessage
                                                        delegate:nil
                                               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Alert: Cancel button") 
                                               otherButtonTitles:NSLocalizedString(@"<ok-phone registration>", @"Alert: OK to proceed with phone registration"), nil] autorelease];
        alert.tag = VERIFICATION_INTRO_ALERT_TAG;
        alert.delegate = self;
        [alert show];
        
    }
}



#pragma mark -
#pragma mark UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	NSInteger cancelIndex = [alertView cancelButtonIndex];
    
    if (buttonIndex != cancelIndex && alertView.tag == VERIFICATION_INTRO_ALERT_TAG) {
        
        // don't confirm multi device yet, let server tell us
        //
        [self submitMSISDNConfirmMultiDeviceRegistration:NO];
    }
    else if (buttonIndex != cancelIndex && alertView.tag == MULTIDEVICE_ALERT_TAG) {
        
        // confirmation received from user, so go ahead
        //
        [self submitMSISDNConfirmMultiDeviceRegistration:YES];
    }
    
}


#pragma mark -
#pragma mark UITextFieldDelegate Methods

//
// Save group name after textField is entered
//  * note: this will be a problem if other textfields are added - tag controls to differentiate
//
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	// end the textfield editing
	[textField resignFirstResponder];
    return YES;
}

/**
 If editing starts
 - change text color: so that magnify glass can still show text!
 
 */
/*- (void) textFieldDidBeginEditing:(UITextField *)textField {
	textField.textColor = [UIColor lightGrayColor];
}*/

/**
 If editing ends
 - update the group's name
 - restore the text color
 */
/*- (void) textFieldDidEndEditing:(UITextField *)textField {

}*/

#pragma mark - CountrySelectController Delegate

- (void)countrySelectController:(CountrySelectController *)cellController selectedCountryIsoCode:(NSString *)isoCode {
    
    [self setCountryCode:isoCode];
    [self dismissModalViewControllerAnimated:YES];
    
    // selected right country, so we should now let user modify phone field
    //
    [self.phoneField becomeFirstResponder];
}


@end
