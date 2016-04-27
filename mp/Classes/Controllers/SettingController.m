//
//  SettingController.m
//  mp
//
//  Created by M Tsai on 11-12-5.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "SettingController.h"
#import "MPFoundation.h"
#import "MyProfileController.h"
#import "BlockedController.h"
#import "FontController.h"
#import "CDChat.h"
#import "CDContact.h"
#import "HiddenChatSettingController.h"
#import "TellFriendController.h"
#import "SystemController.h"
#import "NotificationController.h"
#import "SettingButton.h"
#import "TestingController.h"
#import "TTWebViewController.h"
#import "MPContactManager.h"

@implementation SettingController


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

#define kButtonStartY       10.0
#define kButtonHeightShift  55.0
#define kButtonHeight       45.0

#define kButtonUpdateWidth  100.0
#define kButtonUpdateHeight 31.0

#define FONT_LABEL_TAG      19001
#define PRESENCE_SWITCH_TAG 19002
#define HIDDEN_CHAT_TAG     19003
#define MESSAGE_NOTIF_TAG   19004
#define GROUP_NOTIF_TAG     19005
#define VERSION_TAG         19006
#define UPDATE_BTN_TAG      19007
#define AUTOSYNC_BTN_TAG    19008
#define AUTOSYNC_ALERT_TAG  19009




// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    // title
    //
    self.title = NSLocalizedString(@"Settings", @"Settings - title: app user settings");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    // background
    //
    UIScrollView *setupView = [[UIScrollView alloc] initWithFrame:appFrame];
    setupView.scrollEnabled = YES;
    setupView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = setupView;
    
    
    // my profile button
    //
    CGFloat buttonStartY = kButtonStartY;
    UIButton *myProfileButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, buttonStartY, 310.0, kButtonHeight)];
    [AppUtility configButton:myProfileButton context:kAUButtonTypeTextBarSmall];
    [myProfileButton addTarget:self action:@selector(pressMyProfile:) forControlEvents:UIControlEventTouchUpInside];
    [myProfileButton setTitle:NSLocalizedString(@"My Profile", @"Settings - button: show my profile settings") forState:UIControlStateNormal];
    [self.view addSubview:myProfileButton];
    [myProfileButton release];
    
    
    
    // System button
    //
    buttonStartY += kButtonHeightShift;
    SettingButton *systemButton = [[SettingButton alloc] initWithOrigin:CGPointMake(5.0, buttonStartY) 
                                                              buttonType:kSBButtonTypeTop
                                                                  target:self 
                                                                selector:@selector(pressSystem:) 
                                                                   title:NSLocalizedString(@"System", @"Settings - button: System settings") 
                                                               showArrow:YES];
    [self.view addSubview:systemButton];
    [systemButton release];
    
    // Version button
    //
    buttonStartY += kButtonHeight;
    SettingButton *versionButton = [[SettingButton alloc] initWithOrigin:CGPointMake(5.0, buttonStartY) 
                                                             buttonType:kSBButtonTypeBottom
                                                                 target:self 
                                                                selector:@selector(pressUpdateVersion:)
                                                                  title:nil
                                                              showArrow:NO];
    versionButton.tag = VERSION_TAG;
    [self.view addSubview:versionButton];
    
    // add update button
    UIButton *updateButton = [[UIButton alloc] initWithFrame:CGRectMake(310.0-kButtonUpdateWidth-5.0, (kButtonHeight-kButtonUpdateHeight)/2.0, kButtonUpdateWidth, kButtonUpdateHeight)];
    [updateButton setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"std_btn_green7_nor.png"] leftCapWidth:24.0 topCapHeight:15.0] forState:UIControlStateNormal];
    //[updateButton setBackgroundImage:[UIImage imageNamed:@"std_btn_green7_prs.png"] forState:UIControlStateHighlighted];
    updateButton.backgroundColor = [UIColor clearColor];
    updateButton.opaque = YES;
    
    [updateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    updateButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
    [updateButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 17.0, 0.0, 0.0)];
    [updateButton setTitle:NSLocalizedString(@"Update", @"Settings - text: update to new version") forState:UIControlStateNormal];
    updateButton.userInteractionEnabled = NO;
    updateButton.tag = UPDATE_BTN_TAG;
    
    UIButton *updateBadge = [[UIButton alloc] initWithFrame:CGRectMake(3.0, 2.0, 26.0, 26.0)];
    [updateBadge setBackgroundImage:[UIImage imageNamed:@"std_icon_badge_nor.png"] forState:UIControlStateNormal];
    [updateBadge setBackgroundImage:[UIImage imageNamed:@"std_icon_badge_prs.png"] forState:UIControlStateHighlighted];
    updateBadge.backgroundColor = [UIColor clearColor];
    
    [updateBadge setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [updateBadge setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 2.0, 0.0, 0.0)];
    updateBadge.titleLabel.font = [UIFont systemFontOfSize:14]; //[AppUtility fontPreferenceWithContext:kAUFontBoldSmall]; 
    [updateBadge setTitle:NSLocalizedString(@"N", "Settings - text: new update is available") forState:UIControlStateNormal];
    [updateButton addSubview:updateBadge];
    [updateBadge release];
    
    [versionButton addSubview:updateButton];
    [versionButton release];
    [updateButton release];
    
    
    // Message notification button
    //
    buttonStartY += kButtonHeightShift;
    SettingButton *messageButton = [[SettingButton alloc] initWithOrigin:CGPointMake(5.0, buttonStartY) 
                                                                   buttonType:kSBButtonTypeTop
                                                                       target:self 
                                                                     selector:@selector(pressMessageNotification:) 
                                                                        title:NSLocalizedString(@"Message Notification", @"Settings - button: Modify notification settings") 
                                                                    showArrow:YES];
    messageButton.tag = MESSAGE_NOTIF_TAG;
    [self.view addSubview:messageButton];
    [messageButton release];
    
    
    // Group notification button
    //
    buttonStartY += kButtonHeight;
    SettingButton *groupButton = [[SettingButton alloc] initWithOrigin:CGPointMake(5.0, buttonStartY) 
                                                              buttonType:kSBButtonTypeBottom
                                                                  target:self 
                                                                selector:@selector(pressGroupNotification:) 
                                                                   title:NSLocalizedString(@"Group Notification", @"Settings - button: Modify notification settings") 
                                                               showArrow:YES];
    groupButton.tag = GROUP_NOTIF_TAG;
    [self.view addSubview:groupButton];
    [groupButton release];
    
    
    // auto sync button
    //
    buttonStartY += kButtonHeightShift;
    SettingButton *syncButton = [[SettingButton alloc] initWithOrigin:CGPointMake(5.0, buttonStartY) 
                                                            buttonType:kSBButtonTypeTop
                                                                target:self 
                                                              selector:@selector(pressAutoSync:) 
                                                                 title:NSLocalizedString(@"Auto Sync Friends", @"Settings - button: list of blocked users")
                                                             showArrow:YES];
    syncButton.tag = AUTOSYNC_BTN_TAG;
    [self.view addSubview:syncButton];
    [syncButton release];
    
    // block list button
    //
    buttonStartY += kButtonHeight;
    SettingButton *blockButton = [[SettingButton alloc] initWithOrigin:CGPointMake(5.0, buttonStartY) 
                                                            buttonType:kSBButtonTypeCenter
                                                                target:self 
                                                              selector:@selector(pressBlock:) 
                                                                 title:NSLocalizedString(@"Blocked Users", @"Settings - button: list of blocked users")
                                                             showArrow:YES];
    [self.view addSubview:blockButton];
    [blockButton release];
    
    // hidden chat button
    //
    buttonStartY += kButtonHeight;
    SettingButton *hiddenChatButton = [[SettingButton alloc] initWithOrigin:CGPointMake(5.0, buttonStartY) 
                                                            buttonType:kSBButtonTypeBottom
                                                                target:self 
                                                              selector:@selector(pressHiddenChat:) 
                                                                 title:NSLocalizedString(@"Enable Hidden Chat", @"Settings - button: change font size for chat messages")
                                                             showArrow:YES];
    hiddenChatButton.tag = HIDDEN_CHAT_TAG;
    [self.view addSubview:hiddenChatButton];
    [hiddenChatButton release];
    
    
    // Tell Friends
    //
    buttonStartY += kButtonHeightShift;
    SettingButton *tellButton = [[SettingButton alloc] initWithOrigin:CGPointMake(5.0, buttonStartY) 
                                                                 buttonType:kSBButtonTypeSingle
                                                                     target:self 
                                                                   selector:@selector(pressTell:) 
                                                                      title:NSLocalizedString(@"Tell Friends", @"AddFriend - button: tell friends about this app")
                                                                  showArrow:YES];
    [self.view addSubview:tellButton];
    [tellButton release];
    
    
    // help button
    //
    buttonStartY += kButtonHeightShift;
    SettingButton *helpButton = [[SettingButton alloc] initWithOrigin:CGPointMake(5.0, buttonStartY) 
                                                           buttonType:kSBButtonTypeSingle
                                                               target:self 
                                                             selector:@selector(pressHelp:) 
                                                                title:NSLocalizedString(@"Help", @"Settings-button: Help for M+ users")
                                                            showArrow:YES];
    [self.view addSubview:helpButton];
    [helpButton release];
    
#ifdef LOGGING_ON
    // debug tools button
    //
    buttonStartY += kButtonHeightShift;
    SettingButton *testButton = [[SettingButton alloc] initWithOrigin:CGPointMake(5.0, buttonStartY) 
                                                           buttonType:kSBButtonTypeSingle
                                                               target:self 
                                                             selector:@selector(pressTest:) 
                                                                title:@"Dev Testing"
                                                            showArrow:NO];
    [self.view addSubview:testButton];
    [testButton release];
#endif
    
    setupView.contentSize=CGSizeMake(appFrame.size.width, buttonStartY+kButtonHeightShift);
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


- (void)viewWillAppear:(BOOL)animated
{
    DDLogInfo(@"SetC-vwa");
    [super viewWillAppear:animated];
    
    NSString *onString = NSLocalizedString(@"On", @"Settings - text: setting is enabled");
    NSString *offString = NSLocalizedString(@"Off", @"Settings - text: setting is NOT enabled");
        
    // update notif status
    //
    SettingButton *messageButton = (SettingButton *)[self.view viewWithTag:MESSAGE_NOTIF_TAG];
    NSNumber *isMessageAlertOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPushP2PAlertIsOn];
    [messageButton setValueText:[isMessageAlertOn boolValue]?onString:offString];
    
    SettingButton *groupButton = (SettingButton *)[self.view viewWithTag:GROUP_NOTIF_TAG];
    NSNumber *isGroupAlertOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPushGroupAlertIsOn];
    [groupButton setValueText:[isGroupAlertOn boolValue]?onString:offString];
    
    // update hidden chat status
    //
    NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
    NSString *hiddenString = offString;    
    if (pin) {
        hiddenString = onString;
    }    
    SettingButton *hiddenChatButton = (SettingButton *)[self.view viewWithTag:HIDDEN_CHAT_TAG];
    [hiddenChatButton setValueText:hiddenString];
    
    // update version information
    //
    SettingButton *versionButton = (SettingButton *)[self.view viewWithTag:VERSION_TAG];
    NSString *currentVersion = [AppUtility getAppVersion];
    NSString *version = [NSString stringWithFormat:NSLocalizedString(@"Version %@", @"Settings - text: version of app installed"), currentVersion];
    [versionButton setTitle:version forState:UIControlStateNormal];
    
    // show update?
    //
    BOOL isUpToDate = [[MPSettingCenter sharedMPSettingCenter] isAppUpToDate];
    
    UIButton *updateButton = (UIButton *)[self.view viewWithTag:UPDATE_BTN_TAG];
    if (isUpToDate) {
        updateButton.hidden = YES;
    }
    else {
        updateButton.hidden = NO;
    }
    
    // set auto sync state
    SettingButton *syncButton = (SettingButton *)[self.view viewWithTag:AUTOSYNC_BTN_TAG];
    NSNumber *isOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingAddressBookIsAllowed];
    [syncButton setValueBOOL:[isOn boolValue] animated:animated];
    
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
- (void) pressMyProfile:(id) sender {
    
    MyProfileController *nextController = [[MyProfileController alloc] init];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
}

/*!
 @abstract System setting
 */
- (void) pressSystem:(id) sender {
    SystemController *nextController = [[SystemController alloc] init];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
}

/*!
 @abstract Notification Settings
 */
- (void) pressMessageNotification:(id) sender {
    NotificationController *nextController = [[NotificationController alloc] initIsGroupNotification:NO];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
}

/*!
 @abstract Notification Settings
 */
- (void) pressGroupNotification:(id) sender {
    NotificationController *nextController = [[NotificationController alloc] initIsGroupNotification:YES];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
}


/*!
 @abstract starts phone sync
 */
- (void) pressTell:(id)sender {
    
    TellFriendController *nextController = [[TellFriendController alloc] init];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
    
}


/*!
 @abstract hidden chat setting
 */
- (void) pressHiddenChat:(id) sender {
    HiddenChatSettingController *nextController = [[HiddenChatSettingController alloc] init];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
}


/*!
 @abstract presence permission
 */
/*- (void) pressPresence:(id) sender {
    
    NSNumber *isPresenceOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingUserPresencePermission];

    // request the opposite
    [[MPHTTPCenter sharedMPHTTPCenter] setPresencePermission:![isPresenceOn boolValue]];
    
}*/

/*!
 @abstract Alert switch 
 */
- (void) pressAutoSync:(id) sender {
    
    NSNumber *isOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingAddressBookIsAllowed];
    
    // request opposite of current state
    BOOL newValue = ![isOn boolValue];
    
    // if turn on
    if (newValue) {
        [AppUtility askAddressBookAccessPermissionAlertDelegate:self alertTag:AUTOSYNC_ALERT_TAG];
    }
    // if turn off
    else {
        
        // also make sure addressbook is flushed
        [[AppUtility getBackgroundContactManager] markAddressBookAsChangedFromABCallBack:NO];
        
        // move switch to desired position
        SettingButton *syncButton = (SettingButton *)[self.view viewWithTag:AUTOSYNC_BTN_TAG];
        [syncButton setValueBOOL:newValue animated:YES];
        
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingAddressBookIsAllowed settingValue:[NSNumber numberWithBool:newValue]];
    }
}


/*!
 @abstract show block list
 */
- (void) pressBlock:(id) sender {
    BlockedController *nextController = [[BlockedController alloc] init];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
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

/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	NSInteger cancelIndex = [alertView cancelButtonIndex];
    
    // delete all chats
    if (buttonIndex != cancelIndex && [alertView.title isEqualToString:NSLocalizedString(@"Delete Account", nil)]) {
        [[MPHTTPCenter sharedMPHTTPCenter] requestCancelAccount];
    }
    
}*/



/*!
 @abstract open update app page
 */
- (void) pressUpdateVersion:(id)sender {
    
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:kMPParamAppURLUpdate]];
    
}


/*!
 @abstract Show EULA view
 
 */
- (void)pressHelp:(id)sender {
    
    
    TTWebViewController *nextController = [[TTWebViewController alloc] init];
    
    NSString *language = [AppUtility devicePreferredLanguageCode];
    nextController.urlText = [kMPParamAppURLHelp stringByAppendingString:language];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:nextController];
    
    nextController.title = NSLocalizedString(@"Help", @"HelpWeb: M+ FAQ page");
    [AppUtility setCustomTitle:nextController.title navigationItem:nextController.navigationItem];
    
    UIBarButtonItem *doneButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Close", @"HelpWeb: done viewing help") 
                                                      buttonType:kAUButtonTypeBarNormal 
                                                          target:self action:@selector(pressCloseHelp:)];
	nextController.navigationItem.rightBarButtonItem = doneButton;
    
    [nextController release];
    [AppUtility customizeNavigationController:navController];
    
    [self presentModalViewController:navController animated:YES];
    [navController release];
}

/*!
 submits phone registration and goes to the next step
 */
- (void) pressCloseHelp:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

/*!
 @abstract Show test view
 */
- (void) pressTest:(id) sender {
        
    TestingController *testC = [[TestingController alloc] init];
    [self.navigationController pushViewController:testC animated:YES];
    [testC release];
    
}



#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	NSInteger cancelIndex = [alertView cancelButtonIndex];
    
    if (alertView.tag == AUTOSYNC_ALERT_TAG) {
        SettingButton *syncButton = (SettingButton *)[self.view viewWithTag:AUTOSYNC_BTN_TAG];

        if (buttonIndex != cancelIndex) {
            
            // move switch to desired position
            [syncButton setValueBOOL:YES animated:YES];
            
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingAddressBookIsAllowed settingValue:[NSNumber numberWithBool:YES]];
            
            [MPContactManager tryStartingPhoneBookSyncForceStart:YES delayed:NO];
            
        }
        else {
            // sync cancelled
            [syncButton setValueBOOL:NO animated:YES];
        }
    }
    
}

@end
