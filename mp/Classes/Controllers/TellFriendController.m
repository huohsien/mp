//
//  TellFriendController.m
//  mp
//
//  Created by M Tsai on 11-12-2.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "TellFriendController.h"
#import "MPFoundation.h"
#import "SelectContactPropertyController.h"
#import "ContactProperty.h"
#import "SettingButton.h"
#import "FreeSMSController.h"


@implementation TellFriendController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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

#define kStartX             5.0
#define kStartY             10.0
#define kShiftY             55.0

#define EMAIL_BTN_TAG   13301
#define SMS_BTN_TAG     13302
#define FREE_BTN_TAG    13303

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{

    
    
    // title
    //
    self.title = NSLocalizedString(@"Tell a Friend", @"TellFriend - title: tell friends about M+");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];

    // background
    //
    UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    backView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = backView;
    [backView release];            
    
    
    // email button
    //
    SettingButton *emailButton = [[SettingButton alloc] initWithOrigin:CGPointMake(kStartX, kStartY) 
                                                           buttonType:kSBButtonTypeTop 
                                                               target:self 
                                                             selector:@selector(pressEmail:) 
                                                                title:NSLocalizedString(@"Email", @"AddFriend - button: email friends about M+") 
                                                            showArrow:YES];
    emailButton.tag = EMAIL_BTN_TAG;
    [self.view addSubview:emailButton];
    [emailButton release];
    
    // sms button
    //
    SettingButton *smsButton = [[SettingButton alloc] initWithOrigin:CGPointMake(kStartX, kStartY+kSBButtonHeight) 
                                                            buttonType:kSBButtonTypeBottom 
                                                                target:self 
                                                              selector:@selector(pressSMS:) 
                                                                 title:NSLocalizedString(@"<sms tell friend>", @"AddFriend - button: send sms to friends about M+")
                                                             showArrow:YES];
    smsButton.tag = SMS_BTN_TAG;
    [self.view addSubview:smsButton];
    [smsButton release];
    
    
    // free sms button
    //
    SettingButton *freeButton = [[SettingButton alloc] initWithOrigin:CGPointMake(kStartX, kStartY+kSBButtonHeight*2.0) 
                                                          buttonType:kSBButtonTypeBottom 
                                                              target:self 
                                                            selector:@selector(pressFree:) 
                                                               title:NSLocalizedString(@"Free SMS", @"AddFriend - button: email friends about M+")
                                                           showArrow:YES];
    freeButton.tag = FREE_BTN_TAG;
    [self.view addSubview:freeButton];
    [freeButton release];
    
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


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    DDLogInfo(@"TFC-vwa");

    // if free sms available show free button
    //
    SettingButton *smsButton = (SettingButton *)[self.view viewWithTag:SMS_BTN_TAG];
    SettingButton *freeButton = (SettingButton *)[self.view viewWithTag:FREE_BTN_TAG];
    
    NSNumber *freeNum = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingFreeSMSLeftNumber];
    //CountryCodeLocale locale = [[MPSettingCenter sharedMPSettingCenter] getUserCountryCodeLocale];
    NSString *cCode = [[MPHTTPCenter sharedMPHTTPCenter] getCountryCode];

    // this section only gets run once per session 
    // - check phone country code: more reliable than region settings
    // 
    // free sms available
    if ([freeNum intValue] > 0 && [cCode isEqualToString:@"886"]) {
        [smsButton setButtonType:kSBButtonTypeCenter];
        [freeButton setButtonType:kSBButtonTypeBottom];
        [freeButton setValueText:[freeNum stringValue]];
        freeButton.hidden = NO;
    }
    // no free sms
    else {
        [smsButton setButtonType:kSBButtonTypeBottom];
        freeButton.hidden = YES;
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



#pragma mark - Button


/*!
 @abstract select properties given property type
 */
- (void)selectPropertyOfType:(SelectContactPropertyType)propertyType {
    
    SelectContactPropertyController *nextController = [[SelectContactPropertyController alloc] initWithStyle:UITableViewStylePlain type:propertyType];
    nextController.delegate = self;
    
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
    
    
    /*UINavigationController *navigationController = [[UINavigationController alloc]
													initWithRootViewController:nextController];
    [AppUtility customizeNavigationController:navigationController];
	[self presentModalViewController:navigationController animated:YES];
	[nextController release];
	[navigationController release];*/
    
}

/*!
 @abstract pressed submit button - checks for duplicates
 */
- (void)pressEmail:(id) sender {
    
    [self selectPropertyOfType:kSelectContactPropertyTypeEmail];

}


/*!
 @abstract pressed submit button - checks for duplicates
 */
- (void)pressSMS:(id) sender {
    
    [self selectPropertyOfType:kSelectContactPropertyTypeSMS];
}


/*!
 @abstract pressed submit button - checks for duplicates
 */
- (void)pressFree:(id) sender {

    [self selectPropertyOfType:kSelectContactPropertyTypeFreeSMS];
    
}

#pragma mark - SelectContactPropertyController

/*!
 @abstract Called after user has completed selection
 */
- (void)SelectContactPropertyController:(SelectContactPropertyController *)controller selectedProperties:(NSArray *)properties propertyType:(SelectContactPropertyType)propertyType{
    
    [self.navigationController popViewControllerAnimated:NO];
    //[self dismissModalViewControllerAnimated:NO];
    
    NSMutableArray *toArray = [[NSMutableArray alloc] init];
    for (ContactProperty *iProperty in properties){
        [toArray addObject:iProperty.value];
    }
    
    if (propertyType == kSelectContactPropertyTypeEmail) {
        // check if can send email first
        if ([MFMailComposeViewController canSendMail]) {
            
            /* Deprecated - read string from downloadable text files
            NSError *error = nil;
            NSString *contentPath = [AppUtility pathForDownloadableContentWithFilename:kMPFileTellFriendEmail];
            
            NSStringEncoding enc;
            NSString *emailString = [NSString stringWithContentsOfFile:contentPath usedEncoding:&enc error:&error];
            
            if (error) {
                NSAssert1(0, @"Failed to read email msg file with error '%@'.", [error localizedDescription]);
            }*/
            
            NSString *emailString = NSLocalizedString(@"<tell_friend_email>", @"Tell Friend: Email default text");
            NSArray *lines = [emailString componentsSeparatedByString:@"\n"];
            
            NSString *subject = nil;
            NSMutableArray *bodyArray = [[NSMutableArray alloc] init];
            
            // first line is subject and reset is body
            if ([lines count] > 1) {
                int i = 0;
                for (NSString *iLine in lines){
                    if (i == 0) {
                        subject = iLine;
                    }
                    else{
                        [bodyArray addObject:iLine];
                    }
                    i++;
                }
            }
            NSString *body = [bodyArray componentsJoinedByString:@"\n"];
            [bodyArray release];
            
            
            MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
            composer.mailComposeDelegate = self;
            [composer setToRecipients:toArray];
            [composer setSubject:subject];
            [composer setMessageBody:body isHTML:NO];
            
            UIViewController *baseVC = [AppUtility getAppDelegate].containerController;
            
            // present with root container to allow rotation
            //
            [baseVC presentModalViewController:composer animated:YES];
            [composer release];
        }
        else {
            // alert users that mail is not setup yet
            [AppUtility showAlert:kAUAlertTypeEmailNoAccount];
        }

    }
    else if (propertyType == kSelectContactPropertyTypeSMS ){
        
        /* Deprecated - read string from downloadable text files

        NSError *error = nil;
        NSString *contentPath = [AppUtility pathForDownloadableContentWithFilename:kMPFileTellFriendSMS];
        
        NSStringEncoding enc;
        NSString *contentString = [NSString stringWithContentsOfFile:contentPath usedEncoding:&enc error:&error];
        
        if (error) {
            NSAssert1(0, @"Failed to read sms msg file with error '%@'.", [error localizedDescription]);
        }
         */
        
        NSString *contentString = NSLocalizedString(@"<tell_friend_sms>", @"Tell Friend: SMS default text");
                
        // check if sms is available
        if ([MFMessageComposeViewController canSendText]) {
            MFMessageComposeViewController *composer = [[MFMessageComposeViewController alloc] init];
            composer.messageComposeDelegate = self;
            composer.recipients = toArray;
            [composer setBody:contentString];
            
            // present with root container to allow rotation
            //
            [[AppUtility getAppDelegate].containerController presentModalViewController:composer animated:YES];
            [composer autorelease]; // autorelease?
        }
        else {
            [AppUtility showAlert:kAUAlertTypeNoTelephonySMS];
            
        }
        
    }
    else if (propertyType == kSelectContactPropertyTypeFreeSMS) {
        
        
        FreeSMSController *nextController = [[FreeSMSController alloc] init];
        nextController.contactProperties = properties;
        
        
        // Create nav controller to present modally
        UINavigationController *navigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:nextController];        
        [AppUtility customizeNavigationController:navigationController];
        
        [self presentModalViewController:navigationController animated:YES];
        [navigationController release];
        [nextController release];

        //[[AppUtility getAppDelegate].containerController presentModalViewController:controller animated:YES];
        
    }
    [toArray release];

}


#pragma mark - Mail Methods

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{   
	if (result == MFMailComposeResultFailed) {
		DDLogVerbose(@"MFMail: mail failed");
        
        NSString *title = NSLocalizedString(@"Compose Email Failure", @"Email - alert title");
        NSString *detMessage = [NSString stringWithFormat:@"%@", [error localizedDescription]];
        
        [Utility showAlertViewWithTitle:title message:detMessage];
    
	}
    [[[AppUtility getAppDelegate] containerController] dismissModalViewControllerAnimated:YES];
}


#pragma mark - SMS Methods

// Dismisses the message composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result 
{   
	if (result == MessageComposeResultFailed) {
        [AppUtility showAlert:kAUAlertTypeComposeFailsureSMS];
        
    }
    [[[AppUtility getAppDelegate] containerController] dismissModalViewControllerAnimated:YES];
	
	//[self.navigationController.parentViewController dismissModalViewControllerAnimated:YES];
}


@end
