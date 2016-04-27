//
//  SystemController.m
//  mp
//
//  Created by Min Tsai on 2/21/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "SystemController.h"
#import "MPFoundation.h"
#import "MyProfileController.h"
#import "BlockedController.h"
#import "FontController.h"
#import "CDChat.h"
#import "CDContact.h"
#import "HiddenChatSettingController.h"
#import "TellFriendController.h"
#import "MPChatManager.h"
#import "SettingButton.h"

@implementation SystemController


- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

#define kViewStartY         10.0
#define kButtonHeightShift  55.0
#define kButtonHeight       45.0
#define kLabelHeightShift   18.0


#define FONT_LABEL_TAG      19001
#define CURRENT_LABEL_TAG   19002
#define LATEST_LABEL_TAG    19003
#define LATEST_ARROW_TAG    19004
#define LATEST_BTN_TAG      19005

#define CLEAR_HISTORY_ACTION_TAG    19006
#define DELETE_ACCOUNT_ACTION_TAG   19007



// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    // title
    //
    self.title = NSLocalizedString(@"System", @"System - title: app user settings");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    // background
    //
    UIScrollView *setupView = [[UIScrollView alloc] initWithFrame:appFrame];
    setupView.scrollEnabled = YES;
    setupView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = setupView;
    
    
    
    // Chat description
    //
    CGFloat viewStartY = kViewStartY;
    UILabel *chatLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, viewStartY, 150.0, 15.0)];
    [AppUtility configLabel:chatLabel context:kAULabelTypeBackgroundText];
    chatLabel.text = NSLocalizedString(@"Chat Settings", @"System - text: Chat settings");
    [self.view addSubview:chatLabel];
    [chatLabel release];
    
    // font size button
    //
    viewStartY += kLabelHeightShift;
    UIButton *fontButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, viewStartY, 310.0, 45.0)];
    [AppUtility configButton:fontButton context:kAUButtonTypeTextBarSmall];
    [fontButton addTarget:self action:@selector(pressFont:) forControlEvents:UIControlEventTouchUpInside];
    [fontButton setTitle:NSLocalizedString(@"Message Font Size", @"System - button: change font size for chat messages") forState:UIControlStateNormal];
    [self.view addSubview:fontButton];
    
    UILabel *fontLabel = [[UILabel alloc] initWithFrame:CGRectMake(207.0, (fontButton.frame.size.height-20.0)/2.0 - 1.0, 80.0, 20.0)];
    fontLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
    fontLabel.textColor = [AppUtility colorForContext:kAUColorTypeBlue2];
    fontLabel.textAlignment = UITextAlignmentRight;
    fontLabel.backgroundColor = [UIColor clearColor];
    fontLabel.tag = FONT_LABEL_TAG;
    [fontButton addSubview:fontLabel];
    [fontLabel release];
    [fontButton release];

    
    // Clear History button
    //
    viewStartY += kButtonHeightShift;
    SettingButton *clearHistoryButton = [[SettingButton alloc] initWithOrigin:CGPointMake(5.0, viewStartY) 
                                                           buttonType:kSBButtonTypeSingle 
                                                               target:self 
                                                             selector:@selector(pressClearHistory:) 
                                                                title:NSLocalizedString(@"Clear History", @"System - button: clear all chat history") 
                                                            showArrow:NO];
    [self.view addSubview:clearHistoryButton];
    [clearHistoryButton release];
    
    
    // System description
    //
    viewStartY += kButtonHeightShift;
    UILabel *systemLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, viewStartY, 150.0, 15.0)];
    [AppUtility configLabel:systemLabel context:kAULabelTypeBackgroundText];
    systemLabel.text = NSLocalizedString(@"System", @"System - text: System general settings");
    [self.view addSubview:systemLabel];
    [systemLabel release];

    /*
    // Current Version
    //
    UIButton *currentVersionButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, kButtonStartY+kButtonHeightShift*2.0+18.0, 310.0, 45.0)];
    [AppUtility configButton:currentVersionButton context:kAUButtonTypeTextBarTop];
    currentVersionButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
    [Utility removeSubviewsForView:currentVersionButton tag:kAUViewTagTextBarArrow];
    [currentVersionButton setTitle:NSLocalizedString(@"Current Version", @"Settings - button: Modify notification settings") forState:UIControlStateNormal];
    [self.view addSubview:currentVersionButton];
    
    UILabel *cvLabel = [[UILabel alloc] initWithFrame:CGRectMake(207.0, (currentVersionButton.frame.size.height-20.0)/2.0 - 1.0, 80.0, 20.0)];
    cvLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
    cvLabel.textColor = [AppUtility colorForContext:kAUColorTypeBlue2];
    cvLabel.textAlignment = UITextAlignmentRight;
    cvLabel.backgroundColor = [UIColor clearColor];
    cvLabel.tag = CURRENT_LABEL_TAG;
    [currentVersionButton addSubview:cvLabel];
    [cvLabel release];
    [currentVersionButton release];
    
    
    // Latest Version button
    //
    UIButton *latestVersionButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, kButtonStartY+kButtonHeightShift*2.0+45.0+18.0, 310.0, 45.0)];
    [AppUtility configButton:latestVersionButton context:kAUButtonTypeTextBarBottom];
    latestVersionButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
    [latestVersionButton addTarget:self action:@selector(pressUpdateVersion:) forControlEvents:UIControlEventTouchUpInside];
    [latestVersionButton setTitle:NSLocalizedString(@"Latest Version", @"Settings - button: Modify notification settings") forState:UIControlStateNormal];
    latestVersionButton.tag = LATEST_BTN_TAG;
    [self.view addSubview:latestVersionButton];
    
    UIView *arrowView = [latestVersionButton viewWithTag:kAUViewTagTextBarArrow];
    arrowView.tag = LATEST_ARROW_TAG;
    
    UILabel *lvLabel = [[UILabel alloc] initWithFrame:CGRectMake(207.0, (latestVersionButton.frame.size.height-20.0)/2.0 - 1.0, 80.0, 20.0)];
    lvLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
    lvLabel.textColor = [AppUtility colorForContext:kAUColorTypeBlue2];
    lvLabel.textAlignment = UITextAlignmentRight;
    lvLabel.backgroundColor = [UIColor clearColor];
    lvLabel.tag = LATEST_LABEL_TAG;
    [latestVersionButton addSubview:lvLabel];
    [lvLabel release];
    [latestVersionButton release];
    */
    
    // delete account button
    //
    viewStartY += kLabelHeightShift;
    NSString *phoneNumber = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPhoneNumber];
    NSString *cc = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPhoneCountryCode];
    
    NSString *deleteTitle = [NSString stringWithFormat:NSLocalizedString(@"Delete Account (%@)", @"Settings - button: list of blocked users"), [Utility formatPhoneNumber:phoneNumber countryCode:cc showCountryCode:YES]];
    
    UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, viewStartY, 310.0, 50.0)];
    
    UIImage *norImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_red_nor.png"] leftCapWidth:77.0 topCapHeight:24.0];
    UIImage *prsImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_red_prs.png"] leftCapWidth:77.0 topCapHeight:24.0];  
    
    [deleteButton setBackgroundImage:norImage forState:UIControlStateNormal];
    [deleteButton setBackgroundImage:prsImage forState:UIControlStateHighlighted];
    deleteButton.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    deleteButton.opaque = YES;
    
    [deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    deleteButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
    
    [deleteButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [deleteButton setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];    
    
    [deleteButton addTarget:self action:@selector(pressDeleteAccount:) forControlEvents:UIControlEventTouchUpInside];
    [deleteButton setTitle:deleteTitle forState:UIControlStateNormal];
    [self.view addSubview:deleteButton];
    [deleteButton release];
    
    setupView.contentSize=CGSizeMake(appFrame.size.width, viewStartY+kButtonHeightShift);
    [setupView release];
    

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

- (void)viewWillDisappear:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    DDLogInfo(@"SysC-vwa");
    [super viewWillAppear:animated];
    
    // update with current font setting
    //
    UILabel *fLabel = (UILabel *)[self.view viewWithTag:FONT_LABEL_TAG];
    NSString *fontString = NSLocalizedString(@"Normal", @"Settings - text: current font is normal");
    if ([[MPSettingCenter sharedMPSettingCenter] isFontSizeLarge]) {
        fontString = NSLocalizedString(@"Large", @"Settings - text: current font is large");
    }
    fLabel.text = fontString;
    
    
    // update current version
    //
    UILabel *cvLabel = (UILabel *)[self.view viewWithTag:CURRENT_LABEL_TAG];
    cvLabel.text = [AppUtility getAppVersion];
    
    
    // update latest version
    //
    UILabel *lvLabel = (UILabel *)[self.view viewWithTag:LATEST_LABEL_TAG];
    lvLabel.text = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingLatestAppVersion];
    
    // if a newer version exist
    //
    UIView *arrowView = [self.view viewWithTag:LATEST_ARROW_TAG];
    UIButton *latestButton = (UIButton *)[self.view viewWithTag:LATEST_BTN_TAG];
    if ([lvLabel.text compare:cvLabel.text] == NSOrderedDescending) {
        arrowView.hidden = NO;
        [latestButton setTitle:NSLocalizedString(@"Update to Latest Version", @"System - button: tap to update") forState:UIControlStateNormal];
    }
    else {
        arrowView.hidden = YES;
        [latestButton setTitle:NSLocalizedString(@"Latest Version", @"System - button: tap to update") forState:UIControlStateNormal];
    }
    
    // observe sync events
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(handleCancel:) name:MP_HTTPCENTER_CANCEL_NOTIFICATION object:nil];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Button


/*!
 @abstract font setting
 */
- (void) pressFont:(id) sender {
    FontController *nextController = [[FontController alloc] init];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
}


/*!
 @abstract pressed invite button
 */
- (void) pressClearHistory:(id)sender {
    
    UIActionSheet *aSheet;
	
	aSheet	= [[UIActionSheet alloc]
               initWithTitle:NSLocalizedString(@"Delete all chat history.", @"System - Alert: confirm clear chat history")
               delegate:self
               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel contact group action")
               destructiveButtonTitle:NSLocalizedString(@"Delete", @"Alert: Delete button")
               otherButtonTitles:nil];
	
	aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	aSheet.tag = CLEAR_HISTORY_ACTION_TAG;
	[aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
	[aSheet release];
    
}


/*!
 @abstract open update app page
 */
- (void) pressUpdateVersion:(id)sender {
	    
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:kMPParamAppURLUpdate]];
  
}


/*!
 @abstract font setting
 */
- (void) pressDeleteAccount:(id) sender {
    // show confirmation alert first
    //
    
    UIActionSheet *aSheet;
	
	aSheet	= [[UIActionSheet alloc]
               initWithTitle:NSLocalizedString(@"Account and all related data will be removed.", @"Settings - Alert: confirm account deletion!")
               delegate:self
               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel contact group action")
               destructiveButtonTitle:NSLocalizedString(@"Delete", @"Alert: Delete button")
               otherButtonTitles:nil];
	
	aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	aSheet.tag = DELETE_ACCOUNT_ACTION_TAG;
	[aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
	[aSheet release];
    
    
    /*
     NSString *detailedMessage = NSLocalizedString(@"Account and all related data will be removed.", @"Settings - Alert: confirm account deletion!");
     UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Account", @"Settings - Alert: confirm delete title")
     message:detailedMessage
     delegate:nil
     cancelButtonTitle:NSLocalizedString(@"Cancel", @"Alert: Cancel button") 
     otherButtonTitles:NSLocalizedString(@"Delete", @"Alert: Delete button"), nil] autorelease];
     alert.delegate = self;
     [alert show];
     */
    
    
}


#pragma mark - Handlers

/*!
 @abstract handles cancel response
 */
- (void) handleCancel:(NSNotification *)notification {
    
    NSDictionary *responseD = [notification object];
    
    // get ready to start all over! - deleting everything!
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        DDLogInfo(@"HC: CANCEL successful - start local reset - VC:%@", self);
        
        // reset everything!
        [[AppUtility getAppDelegate] startFromScratchWithFullSettingReset:YES];
        
        // pop view so that it is deallocated
        // - otherwise it will persist 
        // - but properly removing [self.navigationController popToRootViewControllerAnimated:YES];
        
    }
    // ask to confirm
    else {
        [AppUtility stopActivityIndicator];
        
        DDLogWarn(@"HC: CANCEL FAILED - result: %@", responseD);
        
        
        NSString *title = NSLocalizedString(@"Delete Account", @"Settings - alert title:");
        NSString *detMessage = NSLocalizedString(@"Delete account failed. Try again later.", @"Settings - alert: Inform of failure");
        
        [Utility showAlertViewWithTitle:title message:detMessage];
    }
}




#pragma mark - Action Sheet Methods

/*!
 @abstract respond to actionsheet selection
 */
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // if not cancel
    if (buttonIndex != [actionSheet cancelButtonIndex]) {
        
        
		NSString *actionButtonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
		if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Delete",nil)]) {
            
            if (actionSheet.tag == CLEAR_HISTORY_ACTION_TAG) {
                
                [AppUtility startActivityIndicator];
                [CDChat clearAllChatHistory];
                [AppUtility stopActivityIndicator];
                
                [Utility showAlertViewWithTitle:nil message:NSLocalizedString(@"All chat history cleared.", @"System - alert: inform use that chat history is cleared")];
                
                // update badge
                [[MPChatManager sharedMPChatManager] updateChatBadgeCount];
                
            }
            else if (actionSheet.tag == DELETE_ACCOUNT_ACTION_TAG) {
                
                [AppUtility startActivityIndicator];
                [[MPHTTPCenter sharedMPHTTPCenter] requestCancelAccount];
            
            }
		}
        
    }
    else {
        DDLogVerbose(@"Delete account cancelled");
    }
}

/*
 - (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
 NSInteger cancelIndex = [alertView cancelButtonIndex];
 
 // delete all chats
 if (buttonIndex != cancelIndex && [alertView.title isEqualToString:NSLocalizedString(@"Delete Account", nil)]) {
 [[MPHTTPCenter sharedMPHTTPCenter] requestCancelAccount];
 }
 
 }*/




@end
