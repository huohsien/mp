//
//  TestingController.m
//  mp
//
//  Created by Min Tsai on 2/23/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "TestingController.h"
#import "MPFoundation.h"
#import "SettingButton.h"
#import "CDResource.h"
#import "asl.h"
#import "MPChatManager.h"
#import "AppUpdateView.h"
#import "DDFileLogger.h"
#import "mpAppDelegate.h"

@implementation TestingController

@synthesize asTextField;
@synthesize psTextField;
@synthesize nsTextField;

- (void) dealloc {
    
    [asTextField release];
    [psTextField release];
    [nsTextField release];
    
    [super dealloc];
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

#define kButtonStartY       28.0
#define kButtonHeightShift  55.0

#define FONT_LABEL_TAG      19001
#define CURRENT_LABEL_TAG   19002
#define LATEST_LABEL_TAG    19003
#define LATEST_ARROW_TAG    19004
#define LATEST_BTN_TAG      19005

#define CLEAR_HISTORY_ACTION_TAG    19006
#define DELETE_ACCOUNT_ACTION_TAG   19007


- (void) updateHostInfo {
    
    // AS textfield
    //
    NSString *asText = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingServerAS];
    self.asTextField.text = asText;
    
    
    // PS textfield
    //
    NSString *psText = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingServerPS];
    self.psTextField.text = psText;
    
    // PS textfield
    //
    NSString *nsText = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingServerNS];
    self.nsTextField.text = nsText;
    
}

#define CONSOLE_TAG 18001


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    // title
    //
    self.title = @"Testing";
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    
    // add next navigation button
    //
    UIBarButtonItem *actionButton = [AppUtility barButtonWithTitle:@"More"                                                 
                                                        buttonType:kAUButtonTypeBarNormal 
                                                            target:self action:@selector(pressAction:)];
    [self.navigationItem setRightBarButtonItem:actionButton animated:NO];
    

    // background
    //
    UIScrollView *setupView = [[UIScrollView alloc] initWithFrame:appFrame];
    setupView.scrollEnabled = NO;
    setupView.contentSize=CGSizeMake(appFrame.size.width, 400.0);
    setupView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = setupView;
    [setupView release];
    
    
    
    
    //UIImage *buttonImage = [[UIImage imageNamed:@"btn-std-option_black.png"] stretchableImageWithLeftCapWidth:7.0 topCapHeight:7.0];
    //UIImage *buttonPressedImage = [[UIImage imageNamed:@"btn-std-option_black-pressed.png"] stretchableImageWithLeftCapWidth:7.0 topCapHeight:7.0];
    
    
    // create console label and text view
    //
    NSString *userID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    NSString *phone = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingMSISDN];
    
    UILabel *consoleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 10.0, 300.0, 20.0)];
    [AppUtility configLabel:consoleLabel context:kAULabelTypeGrayMicroPlus];
    consoleLabel.font = [UIFont boldSystemFontOfSize:13];
    
    consoleLabel.text = [NSString stringWithFormat:@"%@ %@ UID:%@  PH:%@", 
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"],
                         [AppUtility getAppVersion],
                         userID, phone];
    
    consoleLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:consoleLabel];
    [consoleLabel release];
    
    
    UITextView *consoleText = [[UITextView alloc] initWithFrame:CGRectMake(10.0, 30.0, 300.0, 320.0)];
    consoleText.editable = NO;
    //consoleText.text = @"starting POC client..";
    consoleText.tag = CONSOLE_TAG;
    [self.view addSubview:consoleText];
    [consoleText release];
    
    /*
    // AS description
    //
    UILabel *asLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 10.0, 150.0, 15.0)];
    [AppUtility configLabel:asLabel context:kAULabelTypeBackgroundText];
    asLabel.text = @"AS Host:Port";
    [self.view addSubview:asLabel];
    [asLabel release];
    
    // AS textfield
    //
    UITextField *asTextF = [[UITextField alloc] initWithFrame:CGRectMake(5.0, 30.0, 310.0, 30.0)];
    [AppUtility configTextField:asTextF context:kAUTextFieldTypeName];
    asTextF.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    [self.view addSubview:asTextF];
    self.asTextField = asTextF;
    [asTextF release];
    
    
    // PS description
    //
    UILabel *psLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 70.0, 150.0, 15.0)];
    [AppUtility configLabel:psLabel context:kAULabelTypeBackgroundText];
    psLabel.text = @"PS Host:Port";
    [self.view addSubview:psLabel];
    [psLabel release];
    
    // PS textfield
    //
    UITextField *psTextF = [[UITextField alloc] initWithFrame:CGRectMake(5.0, 90.0, 310.0, 30.0)];
    [AppUtility configTextField:psTextF context:kAUTextFieldTypeName];
    psTextF.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    [self.view addSubview:psTextF];
    self.psTextField = psTextF;
    [psTextF release];
    
    
    
    // NS description
    //
    UILabel *nsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 130.0, 150.0, 15.0)];
    [AppUtility configLabel:nsLabel context:kAULabelTypeBackgroundText];
    nsLabel.text = @"NS Host:Port";
    [self.view addSubview:nsLabel];
    [nsLabel release];
    
    // NS textfield
    //
    UITextField *nsTextF = [[UITextField alloc] initWithFrame:CGRectMake(5.0, 150.0, 310.0, 30.0)];
    [AppUtility configTextField:nsTextF context:kAUTextFieldTypeName];
    nsTextF.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    [self.view addSubview:nsTextF];
    self.nsTextField = nsTextF;
    [nsTextF release];
    */
    
    

    /*SettingButton *saveButton = [[SettingButton alloc] initWithOrigin:CGPointMake(5.0, 190.0) 
                                                            buttonType:kSBButtonTypeSingle 
                                                                target:self 
                                                              selector:@selector(pressSaveHost:) 
                                                                 title:@"Save Host Info"
                                                             showArrow:NO];
    [self.view addSubview:saveButton];
    [saveButton release];*/
    
    
    
    
    
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


/*
 @abstract Get log level string
 */
- (NSString *) logLevelString:(NSString *)logLevel {
    
    if ([logLevel isEqualToString:@"0"]) {
        return @"Em";
    }
    else if ([logLevel isEqualToString:@"1"]) {
        return @"Al";
    }
    else if ([logLevel isEqualToString:@"2"]) {
        return @"Cr";
    }
    else if ([logLevel isEqualToString:@"3"]) {
        return @"Er";
    }
    else if ([logLevel isEqualToString:@"4"]) {
        return @"Wn";
    }
    else if ([logLevel isEqualToString:@"5"]) {
        return @"Nt";
    }
    else if ([logLevel isEqualToString:@"6"]) {
        return @"In";
    }
    else {
        return @"";
    }

}


- (void) appendToTextView:(NSString *)text {
    
    UITextView *consoleText = (UITextView *)[self.view viewWithTag:CONSOLE_TAG];
    consoleText.text = [consoleText.text stringByAppendingString:text];
}

/*
 
 */
- (void) updateNetStatus {
        
    [self appendToTextView:[[AppUtility getSocketCenter] connectionStatus]];
    
}


/* 
 
 http://developer.apple.com/library/ios/#DOCUMENTATION/System/Conceptual/ManPages_iPhoneOS/man3/asl_set_query.3.html
 
 Level 0 – “Emergency”
 Level 1 – “Alert”
 Level 2 – “Critical”
 Level 3 – “Error”
 Level 4 – “Warning”
 Level 5 – “Notice”
 Level 6 – “Info”
 Level 7 – “Debug”
 
 
 2012-03-28 15:10:33.951 mp[89546:1a603] {
 
 ASLMessageID = 1068310;
 "CFLog Local Time" = "2012-03-23 18:39:30.405";
 "CFLog Thread" = 1c187;
 Facility = "com.terntek.mp";
 GID = 20;
 Host = "Min-Tsais-MacBook-Pro";
 Level = 4;
 Message = "MC: write FIN - 2012032300000166000548";
 PID = 41145;
 ReadUID = 501;
 Sender = mp;
 Time = 1332499170;
 TimeNanoSec = 405439000;
 UID = 501;
 
 }
 
 */
- (void) updateConsoleInterface {
    
    
    NSMutableString *logString = [[NSMutableString alloc] init];
    
    // add client basic info
    
    NSString *userID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    NSString *phone = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingMSISDN];

    
    NSString *baseInfo = [NSString stringWithFormat:@"%@ %@\nUID: %@\nPH: %@\nNK:%@\n%@\n\n", 
                          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"],
                          [AppUtility getAppVersion],
                          userID, 
                          phone,
                          [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingNickName],
                          [[AppUtility getSocketCenter] connectionStatus]
                          ];
    
    [logString appendString:baseInfo];
    
    
    
    aslmsg q, m;
    int i;
    const char *key, *val;
    
    NSDate *cutOffTime = [NSDate dateWithTimeIntervalSinceNow:-3600.0];
    NSString *cutString = [NSString stringWithFormat:@"%f", [cutOffTime timeIntervalSince1970]];
    
    // show log from mp with INFO and up
    q = asl_new(ASL_TYPE_QUERY);
    asl_set_query(q, ASL_KEY_SENDER, "mp", ASL_QUERY_OP_EQUAL);
    asl_set_query(q, ASL_KEY_LEVEL, "6",
                  ASL_QUERY_OP_LESS_EQUAL | ASL_QUERY_OP_NUMERIC);
    asl_set_query(q, ASL_KEY_TIME, [cutString cStringUsingEncoding:NSASCIIStringEncoding],
                  ASL_QUERY_OP_GREATER );
    
    aslresponse r = asl_search(NULL, q);
    while (NULL != (m = aslresponse_next(r)))
    {
        NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
        
        for (i = 0; (NULL != (key = asl_key(m, i))); i++)
        {
            NSString *keyString = [NSString stringWithUTF8String:(char *)key];
            
            val = asl_get(m, key);
            
            NSString *string = [NSString stringWithUTF8String:val];
            [tmpDict setObject:string forKey:keyString];
        }
        
        NSDate *time = [NSDate dateWithTimeIntervalSince1970:[[tmpDict valueForKey:@"Time"] doubleValue]];
        
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"hh:mm:ss"];    
        NSString *dateString = [NSString stringWithFormat:@"%@", [formatter stringFromDate:time]];
        [formatter release];
        
        
        //NSString *dateString = [Utility terseDateString:time];  //[tmpDict valueForKey:@"CFLog Local Time"];
        //NSString *thread = [tmpDict valueForKey:@"CFLog Thread"];
        NSString *msg = [tmpDict valueForKey:@"Message"];
        NSString *level = [self logLevelString:[tmpDict valueForKey:@"Level"]];
        //NSString *sec = [[tmpDict valueForKey:@"TimeNanoSec"] substringToIndex:3];

        
        NSString *lineString = [NSString stringWithFormat:@"%@:%@: %@\n", dateString, level, msg];
        [logString appendString:lineString];
        
        /*if ([cutOffTime compare:time] == NSOrderedAscending) {
            
        }*/
        
        //NSLog(@"%@", lineString);
    }
    aslresponse_free(r);
    
    UITextView *consoleText = (UITextView *)[self.view viewWithTag:CONSOLE_TAG];
    consoleText.text = logString;
    [consoleText scrollRangeToVisible:NSMakeRange([logString length], 0)];
    [logString release];
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self updateHostInfo];
    
    //[self updateConsoleInterface];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    UITextView *consoleText = (UITextView *)[self.view viewWithTag:CONSOLE_TAG];
    consoleText.text = nil;

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Button



/*!
 @abstract pressed invite button
 */
- (void) pressSaveHost:(id)sender {
    
    UIActionSheet *aSheet;
	
	aSheet	= [[UIActionSheet alloc]
               initWithTitle:@"Save host info and account will also be RESET!"
               delegate:self
               cancelButtonTitle:@"Cancel"
               destructiveButtonTitle:@"Save"
               otherButtonTitles:nil];
	
	aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	[aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
	[aSheet release];

}

- (void) pressEmailLog {
    //UITextView *consoleText = (UITextView *) [self.view viewWithTag:CONSOLE_TAG];                      
    
    // check if can send email first
    if ([MFMailComposeViewController canSendMail]) {
    
        // get list of log paths
        // - create nsdata for each one
        //
        NSArray *paths = [[AppUtility getAppDelegate].fileLogger.logFileManager sortedLogFilePaths];
        NSString *nickName = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingNickName];
        NSString *model = [[ UIDevice currentDevice ] modelDetailedName];
        
        
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeStyle:NSDateFormatterMediumStyle];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        //NSString *dateString = [NSString stringWithFormat:@"%@", [formatter stringFromDate:[NSDate date]]];
        [formatter release];   
        NSString *sysVersion = [[ UIDevice currentDevice ] systemVersion];
        
        MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
        composer.mailComposeDelegate = self;
        [composer setToRecipients:[NSArray arrayWithObjects:@"msgplusapp@gmail.com", nil]];
        
        //[composer setCcRecipients:[NSArray arrayWithObject:@"mtsai@terntek.com"]];
        
        [composer setSubject:[NSString stringWithFormat:@"M+ Log from: %@", nickName]];
        
        // body
        //
        NSString *userID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
        NSString *phone = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingMSISDN];
        
        NSString *baseInfo = [NSString stringWithFormat:@"Please enter following information.\nDescription:\n\n\nTicket ID: \nDate and Time: \n\nModel: %@\niOS: %@\n%@ %@\nUID: %@\nPH: %@\nNK:%@\n%@\n\n",
                              model,
                              sysVersion,
                              [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"],
                              [AppUtility getAppVersion],
                              userID, 
                              phone,
                              nickName,
                              [[AppUtility getSocketCenter] connectionStatus]
                              ];
        [composer setMessageBody:baseInfo isHTML:NO];
        
        
        // attachemnts
        //
        for (NSString *iPath in paths) {
            NSData *iData = [NSData dataWithContentsOfFile:iPath];
            NSArray *parts = [iPath pathComponents];
            [composer addAttachmentData:iData mimeType:@"text/plain" fileName:[parts lastObject]];
        }
        
        // present with root container to allow rotation
        //
        [[AppUtility getAppDelegate].containerController presentModalViewController:composer animated:YES];
        [composer release];  
    }
    else {
        // alert users that mail is not setup yet
        [AppUtility showAlert:kAUAlertTypeEmailNoAccount];
    }
}


- (void)pressStartEchoTest {
    [[MPChatManager sharedMPChatManager] runEchoTest];
    [self appendToTextView:@"Start Load Test\n"];
}

- (void)pressStopEchoTest {
    [MPChatManager sharedMPChatManager].isEchoTestOn = NO;
    [self appendToTextView:@"Stop Load Test\n"];
}

/**
 Open Action for Group's "more action" button
 */
- (void)pressAction:(id)sender {
    UIActionSheet *aSheet;
	
	aSheet	= [[UIActionSheet alloc]
               initWithTitle:@"" 
               delegate:self
               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel contact group action")
               destructiveButtonTitle:nil
               otherButtonTitles:
               @"Email Log",
               @"Update Log",
               @"Delete Resources",
               @"Net Status",
               @"Test Update",
               //@"Info",
               //@"Network",
               //@"Start Load Test",
               //@"Stop Load Test",
               //@"Login",
               //@"Disconnect",
               //@"Get Token",
               //@"Read Bytes",
               //@"Reset",
               //@"Nickname",
               //@"Find Friend",
               //@"Group Chat",
               //@"Image Test",
               nil];
	
	aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	
	[aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
	[aSheet release];
}



#pragma mark - Action Sheet Methods

/*!
 @abstract respond to actionsheet selection
 */
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // if not cancel
    if (buttonIndex != [actionSheet cancelButtonIndex]) {
        
        
		NSString *actionButtonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
		if ([actionButtonTitle isEqualToString:@"Save"]) {
            
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingServerAS settingValue:self.asTextField.text];
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingServerPS settingValue:self.psTextField.text];
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingServerNS settingValue:self.nsTextField.text];
            
            // update HC with new info!
            [[MPHTTPCenter sharedMPHTTPCenter] loadServerHostInfo];
            
            // don't overwrite the server info we just saved
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingServerDontResetMarker settingValue:[NSNumber numberWithBool:YES]];
            
            // reset everything!
            [[AppUtility getAppDelegate] startFromScratchWithFullSettingReset:NO];
		}
        else if ([actionButtonTitle isEqualToString:@"Delete Resources"]) {
			[CDResource resetStickerDownload];
		}
        else if ([actionButtonTitle isEqualToString:@"Update Log"]) {
			[self updateConsoleInterface];
		}
        else if ([actionButtonTitle isEqualToString:@"Email Log"]) {
			[self pressEmailLog];
		}
        else if ([actionButtonTitle isEqualToString:@"Net Status"]) {
			[self updateNetStatus];
		}
        else if ([actionButtonTitle isEqualToString:@"Start Load Test"]) {
			[self pressStartEchoTest];
		}
        else if ([actionButtonTitle isEqualToString:@"Stop Load Test"]) {
			[self pressStopEchoTest];
		}
        else if ([actionButtonTitle isEqualToString:@"Test Update"]) {
            UIViewController *containerVC = [[AppUtility getAppDelegate] containerController];
            
            DDLogCWarn(@"App force update is showing!");
            AppUpdateView *updateView = [[AppUpdateView alloc] initWithFrame:CGRectZero];            
            [containerVC.view addSubview:updateView];
            [updateView release];
        }
    }
    else {
        DDLogVerbose(@"Save host cancelled");
    }
}



#pragma mark - Mail Methods

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{   
	if (result == MFMailComposeResultFailed) {
		DDLogVerbose(@"MFMail: mail failed");
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Compose Email Failure" 
														 message:[NSString stringWithFormat:@"Error: %@", [error localizedDescription]] 
														delegate:nil
											   cancelButtonTitle:@"OK" 
											   otherButtonTitles:nil] autorelease];
		[alert show];
	}
    [[[AppUtility getAppDelegate] containerController] dismissModalViewControllerAnimated:YES];
}





@end
