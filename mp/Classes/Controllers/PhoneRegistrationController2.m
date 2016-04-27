//
//  PhoneRegistrationController.m
//  mp
//
//  Created by M Tsai on 11-10-14.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "PhoneRegistrationController2.h"

#import "Utility.h"
#import "MPFoundation.h"
#import "VerifySMSCodeController.h"
#import "CountryInfo.h"
#import "TTWebViewController.h"


#define kCountryButtonWidth 105.0
#define COUNTY_LABEL_TAG    17001

#define MULTIDEVICE_ALERT_TAG           16001
#define VERIFICATION_INTRO_ALERT_TAG    16002
#define CONTACTS_ACCESS_ALERT_TAG       16003

@implementation PhoneRegistrationController2

@synthesize countryCode;
@synthesize countryButton;
@synthesize phoneField;

@synthesize countryDictionary;
@synthesize didAllowContactsAccess;

//@synthesize urlConnection;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [countryCode release];
    [countryButton release];
    [phoneField release];
    [countryDictionary release];
    
    //[urlConnection release];
    
    [super dealloc];
}


/*!
 @abstract init 
 
 */



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
            NSString *countryCodeRes = [toks objectAtIndex:3];
            if ([countryCodeRes length] == 2) {
                return countryCodeRes;
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
- (void)setISOCountryCode:(NSString *)aCountryCode {
    
    CountryInfo *countryInfo = [self.countryDictionary objectForKey:aCountryCode];
    
    if (countryInfo) {
        NSString *name = countryInfo.name;
        NSString *phoneCode = countryInfo.phoneCountryCode;
        
        [self.countryButton setTitle:name forState:UIControlStateNormal];
        self.countryCode = phoneCode;
        
        UILabel *countryLabel = (UILabel *)[self.view viewWithTag:COUNTY_LABEL_TAG];
        countryLabel.text = phoneCode;
        
        // add default starter if phoneField is empty to help users
        // - 2 chars in case other default string was present
        //
        if ([self.phoneField.text length] < 3) {
            if ([aCountryCode isEqualToString:@"TW"]) {
                self.phoneField.text = @"09";
            }
            else if ([aCountryCode isEqualToString:@"CN"]) {
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
- (BOOL)isValidateCountryCode:(NSString *)aCountryCode phoneNumber:(NSString *)phoneNumber{
    
    BOOL isValid = NO;
    
    NSUInteger phoneLength = [phoneNumber length];
    NSUInteger countryLength = [aCountryCode length];
    
    // only if all numbers except the + sign in CC
    NSCharacterSet *nonDecimalSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSString *noPlusCC = [aCountryCode stringByReplacingOccurrencesOfString:@"+" withString:@""];
    NSArray *ccParts = [noPlusCC componentsSeparatedByCharactersInSet:nonDecimalSet];
    NSArray *phoneParts = [phoneNumber componentsSeparatedByCharactersInSet:nonDecimalSet];
    
    
    if ([ccParts count] == 1 && [phoneParts count] == 1) {
        
        // valid phone nubmer
        if (phoneLength > 6 && // at least 7 
            phoneLength+countryLength < 17  && // at most 15 and + char (ITU max international number)
            countryLength > 1 && // at least 2 characters e.g. "+1"
            countryLength < 6) // at most 4 and + char
        { 
            // valid country mobile phone
            if ([aCountryCode isEqualToString:@"886"] || [aCountryCode isEqualToString:@"+886"]) {
                if ([phoneNumber hasPrefix:@"9"] && [phoneNumber length] == 9) {
                    isValid = YES;
                }
                if ([phoneNumber hasPrefix:@"09"] && [phoneNumber length] == 10) {
                    isValid = YES;
                }
            }
            else if ([aCountryCode isEqualToString:@"86"] || [aCountryCode isEqualToString:@"+86"]) {
                if ([phoneNumber hasPrefix:@"1"] && [phoneNumber length] == 11) {
                    isValid = YES;
                }
            }
            else if ([aCountryCode isEqualToString:@"852"] || [aCountryCode isEqualToString:@"+852"]) {
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
    
    CGFloat lastViewYBottom = 0.0;
    
    UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view = backView;
    [backView release];
    self.view.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];

    
    // add country button
    //
    UIButton *cButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, 8.0, kCountryButtonWidth, 49.0)];

    [cButton setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"std_btn_country_nor.png"] leftCapWidth:14.0 topCapHeight:24.0] forState:UIControlStateNormal];
    [cButton setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"std_btn_country_prs.png"] leftCapWidth:14.0 topCapHeight:24.0] forState:UIControlStateHighlighted];
    cButton.backgroundColor = [UIColor clearColor];
    
    [cButton setTitleColor:[AppUtility colorForContext:kAUColorTypeGray1] forState:UIControlStateNormal];
    [cButton setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    [cButton setTitleEdgeInsets:UIEdgeInsetsMake(2.0, 5.0, 17.0, 5.0)];
    cButton.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
    cButton.titleLabel.textAlignment = UITextAlignmentCenter;
    cButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];

    [cButton setTitle:NSLocalizedString(@"United States", @"Phone Registration - Text default: default country for this language") forState:UIControlStateNormal];
    [cButton addTarget:self action:@selector(pressCountry:) forControlEvents:UIControlEventTouchUpInside];
    
    // add view description label
    //
    UILabel *cLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 22.0, kCountryButtonWidth, 20.0)];
    [AppUtility configLabel:cLabel context:kAULabelTypeGrayMicroPlus];
    cLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
    cLabel.backgroundColor = [UIColor clearColor];
    cLabel.textAlignment = UITextAlignmentCenter;
    cLabel.text = @"+1";
    cLabel.tag = COUNTY_LABEL_TAG;
    [cButton addSubview:cLabel];
    [cLabel release];
    
    [self.view addSubview:cButton];
    self.countryButton = cButton;
    [cButton release];
    
    
    // textfield background image
    //
    UIImageView *textBackImage = [[UIImageView alloc] initWithFrame:CGRectMake(kCountryButtonWidth-5.0, 10.0, 320.0-kCountryButtonWidth, 45.0)];
    textBackImage.image = [Utility resizableImage:[UIImage imageNamed:@"std_icon_textbar.png"] leftCapWidth:9.0 topCapHeight:22.0];
    textBackImage.userInteractionEnabled = YES;
    [self.view insertSubview:textBackImage atIndex:0];
    
    
    // add phone text field 
    //
    UITextField *pField = [[UITextField alloc] initWithFrame:CGRectMake(20.0, 12.0, textBackImage.frame.size.width-30.0, textBackImage.frame.size.height-20.0)];

    pField.autocorrectionType = UITextAutocorrectionTypeNo;
    pField.autocapitalizationType = UITextAutocapitalizationTypeNone;            
    pField.clearButtonMode = UITextFieldViewModeNever;
    pField.textColor = [UIColor blackColor];
    pField.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
    pField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    pField.backgroundColor = [UIColor whiteColor];
    
    pField.placeholder = NSLocalizedString(@"Cell Phone Number", "Phone Registration - Placeholder: instruct user to enter cell phone number");
    pField.keyboardType = UIKeyboardTypeNumberPad;
    [textBackImage addSubview:pField];
    self.phoneField = pField;
    [pField release];
    
    lastViewYBottom = textBackImage.frame.origin.y + textBackImage.frame.size.height;
    
    [textBackImage release];
    
    
    // View EULA Button
    //
    NSString *viewText = NSLocalizedString(@"View Licence Agreement", @"Phone Registration - button: View end user licence agreement");
    UIImageView *eyeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"app_icon_eye.png"]];
    CGSize fontSize = [viewText sizeWithFont:[AppUtility fontPreferenceWithContext:kAUFontSystemMicroPlus]];
    CGFloat eyeStart = (310 - eyeView.frame.size.width - fontSize.width)/2.0 - 5.0;
    CGFloat textStart = eyeStart + eyeView.frame.size.width + 10.0;
    eyeView.frame = CGRectMake(eyeStart, (31.0-eyeView.frame.size.height)/2.0, eyeView.frame.size.width, eyeView.frame.size.height);
    
    UIButton *viewButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, lastViewYBottom + 8.0, 310.0, 31.0)];
    
    // green button for find, ok, etc.
    //
    UIImage *viewImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_license.png"] leftCapWidth:15.0 topCapHeight:15.0];
    [viewButton setBackgroundImage:viewImage forState:UIControlStateNormal];
    viewButton.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    viewButton.opaque = YES;
    [viewButton setTitleColor:[AppUtility colorForContext:kAUColorTypeGray1] forState:UIControlStateNormal];
    viewButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
    [viewButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    viewButton.contentEdgeInsets = UIEdgeInsetsMake(0.0, textStart, 0.0, 0.0);
    
    [viewButton setTitle:viewText forState:UIControlStateNormal];
    [viewButton addTarget:self action:@selector(pressViewEULA:) forControlEvents:UIControlEventTouchUpInside];
    
    [viewButton addSubview:eyeView];
    [self.view addSubview:viewButton];
    lastViewYBottom = viewButton.frame.origin.y + viewButton.frame.size.height;
    [viewButton release];
    [eyeView release];
    
    
    // Agree and Submit button
    //
    UIButton *asButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, lastViewYBottom + 9.0, 310.0, 45.0)];
    [AppUtility configButton:asButton context:kAUButtonTypeGreen5];
    [asButton setTitle:NSLocalizedString(@"Agree and Submit", @"Phone Registration - button: Agree to EULA and submit phone number for registration") forState:UIControlStateNormal];
    [asButton addTarget:self action:@selector(pressNext:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:asButton];
    lastViewYBottom = asButton.frame.origin.y + asButton.frame.size.height;
    [asButton release];
    
    
    // add view description label
    //
    UILabel *viewLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, lastViewYBottom+8.0, 300.0, 30.0)];
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
    NSString *aCountryCode = [Utility currentLocalCountryCode];
    DDLogVerbose(@"PRC-lv: got country - %@", aCountryCode);
    [self setISOCountryCode:aCountryCode];
    
    
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

    self.didAllowContactsAccess = NO;
    
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
	
    
    /*UIBarButtonItem *nextButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Next", @"Phone Registration - Button: go to next step") 
                                                      buttonType:kAUButtonTypeBarHighlight 
                                                          target:self action:@selector(pressNext:)];
	self.navigationItem.rightBarButtonItem = nextButton;
    */
    
    // check if phone already registered, automatically push next view
    //
    NSString *msisdn = [[MPSettingCenter sharedMPSettingCenter] getMSISDN];
    if ([msisdn length] > 4) {
        
        // only push next VC if this is the top VC on the stack
        //
        if ([self.navigationController topViewController] == self) {
            VerifySMSCodeController *nextController = [[VerifySMSCodeController alloc] init];
            [self.navigationController pushViewController:nextController animated:NO];
            [nextController release];
        }

    }
    // phone not registered, then first time so reset settings
    else {
        // reset settings
        [[MPSettingCenter sharedMPSettingCenter] resetAllSettingsWithFullReset:YES];
        [AppUtility askAddressBookAccessPermissionAlertDelegate:self alertTag:CONTACTS_ACCESS_ALERT_TAG];
    }
    
    
    // start IP query - only after reset settings
    //
    [[MPHTTPCenter sharedMPHTTPCenter] ipQueryMsisdn];
    
    
    // 2 - If available, use phone found by reverse lookup
    // TODO: provide statistics to PS server for this TWM3GIP=Y
    
    NSString *cc = [[MPHTTPCenter sharedMPHTTPCenter] getCountryCode];
    NSString *phone = [[MPHTTPCenter sharedMPHTTPCenter] getPhoneNumber];
    
    if ([cc length] == 3 && [phone length] == 9) {
        
        DDLogInfo(@"PR: using reverse lookup ph# %@ %@", cc, phone);
        self.countryCode = cc;
        
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



/*!
 @abstract Submits phone number to get SMS
 */
- (void)submitMSISDNConfirmMultiDeviceRegistration:(BOOL)confirm {
    
    [[MPHTTPCenter sharedMPHTTPCenter] requestRegistrationCountryCode:self.countryCode phoneNumber:self.phoneField.text confirmMultiDeviceRegistration:confirm];
    
}

/*!
 @abstract Submits phone number to get SMS
 
 Use:
 - if msisdn is successful, then go to next view
 
 */
- (void)proceedToRegistration {
    
    // only push if we are viewing this controller
    if (self.view.window){
        
        // save agreement settings and push the next view
        //
        [[MPSettingCenter sharedMPSettingCenter] agreedToEULA];
        
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
    
    // if phone number already entered, don't overwrite with ipquery results
    if ([cc length] == 3 && [phone length] == 9 && [self.phoneField.text length] == 0) {
        
        DDLogInfo(@"PR: using reverse lookup ph# %@ %@", cc, phone);
        self.countryCode = cc;
        
        // prefix a 0 to the mobile number
        self.phoneField.text = [@"0" stringByAppendingString:phone];
    }
    /* no need to clear the textfield
    else {
        self.phoneField.text = @"";
    }
    */
}


/*!
 pushes a country selection tableview
 
 */
- (void)pressCountry:(id)sender {
    
    [self.phoneField resignFirstResponder];
    
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
 @abstract Show EULA view
 
 */
- (void)pressViewEULA:(id)sender {
    
    [self.phoneField resignFirstResponder];
    
    TTWebViewController *nextController = [[TTWebViewController alloc] init];
    
    
    NSString *language = [AppUtility devicePreferredLanguageCode];
    nextController.urlText = [kMPParamAppURLEndUserLicenceAgreement stringByAppendingString:language];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:nextController];
    
    nextController.title = NSLocalizedString(@"End User License Agreement", @"View Title: EULA title");
    [AppUtility setCustomTitle:nextController.title navigationItem:nextController.navigationItem];

    UIBarButtonItem *doneButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Close", @"EULA View: done viewing EULA") 
                                                      buttonType:kAUButtonTypeBarNormal 
                                                          target:self action:@selector(pressCloseEULA:)];
	nextController.navigationItem.rightBarButtonItem = doneButton;
    
    [nextController release];
    [AppUtility customizeNavigationController:navController];

    
    [self presentModalViewController:navController animated:YES];
    [navController release];
}

/*!
 submits phone registration and goes to the next step
 */
- (void) pressCloseEULA:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}


/*!
 submits phone registration and goes to the next step
 */
- (void) pressNext:(id)sender {
    
    // only proceed if permission is allowed
    /*if (!self.didAllowContactsAccess) {
        [AppUtility askAddressBookAccessPermissionAlertDelegate:self alertTag:CONTACTS_ACCESS_ALERT_TAG];
        return;
    }*/
    
    // Check if country code and phone number makes sense
    //
    NSString *processedCC = [self stripExtraChars:self.countryCode];
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
        
        // show alert
        //
        NSString *strippedPhone = [AppUtility stripZeroPrefixForString:self.phoneField.text];
        NSString *phoneNumber = [Utility formatPhoneNumber:strippedPhone countryCode:self.countryCode showCountryCode:YES];
        
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



#pragma mark - UIAlertViewDelegate Methods

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
    else if (buttonIndex != cancelIndex && alertView.tag == CONTACTS_ACCESS_ALERT_TAG) {
        
        // flag access allowed
        //self.didAllowContactsAccess = YES;
        
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingAddressBookIsAllowed settingValue:[NSNumber numberWithBool:YES]];
        
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
    
    [self setISOCountryCode:isoCode];
    [self dismissModalViewControllerAnimated:YES];
    
    // selected right country, so we should now let user modify phone field
    //
    [self.phoneField becomeFirstResponder];
}


@end
