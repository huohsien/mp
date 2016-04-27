//
//  HiddenChatSettingController.m
//  mp
//
//  Created by Min Tsai on 2/1/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "HiddenChatSettingController.h"
#import "MPFoundation.h"
#import "CDChat.h"

#define HIDDEN_SWITCH_TAG   21001
#define CHANGE_PIN_TAG      21002

@implementation HiddenChatSettingController

@synthesize pendingHiddenChatState;


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Tool

/*!
 @abstract Reset Hidden Chat to original state
 
 - clear PIN
 - set isHiddenChat for all chat to NO
 - isLocked = NO
 
 */
- (void) resetHiddenChat {
    
    [[MPSettingCenter sharedMPSettingCenter] setHiddenChatPIN:@""];
    [[MPSettingCenter sharedMPSettingCenter] lockHiddenChat:YES];
    [CDChat clearAllHiddenChat];
    
}


#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    // title
    //
    self.title = NSLocalizedString(@"Hidden Chat", @"HiddenChatSettings - title: hidden chat setting view");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    // background
    //
    UIScrollView *setupView = [[UIScrollView alloc] initWithFrame:appFrame];
    setupView.scrollEnabled = NO;
    setupView.contentSize=CGSizeMake(appFrame.size.width, 500.0);
    setupView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = setupView;
    [setupView release];
    
    // enable/disable hidden chat
    //
    NSString *hideText = NSLocalizedString(@"Enable Hidden Chat", @"HCSetting - button: enable or disable hidden chat");
    UIButton *hideButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, 48.0, 310.0, 45.0)];
    [hideButton setTitle:hideText forState:UIControlStateNormal];
    [AppUtility configButton:hideButton context:kAUButtonTypeTextBarSmall];
    [hideButton addTarget:self action:@selector(pressHide:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:hideButton];
    
    // add switch to button
    //
    UISwitch *hideSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(207.0, 8.0, 80.0, 35.0)];
    // only for ios5.0 - switch size is also different
    if ([hideSwitch respondsToSelector:@selector(onTintColor)]) {
        hideSwitch.frame = CGRectMake(223.0, 8.0, 80.0, 35.0);
        hideSwitch.onTintColor = [AppUtility colorForContext:kAUColorTypeGreen2];
    }
    [hideSwitch addTarget:self action:@selector(pressHide:) forControlEvents:UIControlEventValueChanged];
    hideSwitch.tag = HIDDEN_SWITCH_TAG;
    [hideButton addSubview:hideSwitch];
    [hideButton release];
    [hideSwitch release];
    

    NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
    if (pin) {
        self.pendingHiddenChatState = YES;
    }
    else {
        self.pendingHiddenChatState = NO;
    }
    
    // hidden chat description
    //
    UILabel *hiddenLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 10.0, 295.0, 30.0)];
    [AppUtility configLabel:hiddenLabel context:kAULabelTypeBackgroundText];
    hiddenLabel.text = NSLocalizedString(@"Hide private chats from the Chat List. Select chats to hide in the chat room's settings.", @"HiddenChatSetting - text: This button allows users to enable and disable hidden chat feature.");
    hiddenLabel.numberOfLines = 2;
    hiddenLabel.textAlignment = UITextAlignmentLeft;
    hiddenLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    [self.view addSubview:hiddenLabel];
    [hiddenLabel release];
    
    // hidden chat warning
    //
    UILabel *warnLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 100.0, 295.0, 45.0)];
    [AppUtility configLabel:warnLabel context:kAULabelTypeBackgroundTextCritical];
    warnLabel.text = NSLocalizedString(@"If you forget your PIN, you will need to reinstall M+. Previous chat data and history will be lost.", @"HiddenChatSetting - text: This button allows users to enable and disable hidden chat feature.");
    warnLabel.numberOfLines = 3;
    warnLabel.textAlignment = UITextAlignmentLeft;
    warnLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    [self.view addSubview:warnLabel];
    
    
    
    // change PIN button
    //
    UIButton *changeButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, 153.0, 310.0, 45.0)];
    [AppUtility configButton:changeButton context:kAUButtonTypeTextBarSmall];
    [changeButton addTarget:self action:@selector(pressChangePIN:) forControlEvents:UIControlEventTouchUpInside];
    [changeButton setTitle:NSLocalizedString(@"Change PIN", @"Settings - button: change hidden chat PIN") forState:UIControlStateNormal];
    changeButton.tag = CHANGE_PIN_TAG;
    [self.view addSubview:changeButton];
    [changeButton release];
    
    [warnLabel release];

    
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
    DDLogInfo(@"HCS-vwa");
    [super viewWillAppear:animated];
    
    UISwitch *hiddenSwitch = (UISwitch *)[self.view viewWithTag:HIDDEN_SWITCH_TAG];
    UIView *changeView = [self.view viewWithTag:CHANGE_PIN_TAG];
    
    NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
    
    // set pending state to match current state
    BOOL hideChange = NO;
    if (pin) {
        [hiddenSwitch setOn:YES];
        hideChange = NO;
    }
    else {
        [hiddenSwitch setOn:NO];
        hideChange = YES;
    }
    changeView.hidden = hideChange; // hide if HC is not enabled
    
    // list for results
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processHiddenPreview:) name:MP_HTTPCENTER_SET_PN_HIDDEN_NOTIFICATION object:nil];
    
    // if connection failure - for presence and search ID
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processConnectFailure:) name:MP_HTTPCENTER_CONNECT_FAILED_NOTIFICATION object:nil];
    
}

- (void) viewWillDisappear:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



#pragma mark - HC Request


/*!
 @abstract Tell M+ service to disable HC for all chats
 
 */
- (void) requestDisableAllHiddenChats { 
    
    [AppUtility startActivityIndicator];
    [[MPHTTPCenter sharedMPHTTPCenter] setPNHiddenPreviewForUserID:nil groupID:nil hiddenStatus:NO disableAll:YES];
    
}




#pragma mark - Process HTTP responses

/*!
 @abstract Process hidden preview setting
 
 Output
 
 Successful case
 <SetPNHidden>
 <cause>0</cause>
 </SetPNHidden>
 
 Exception case
 <SetPNHidden>
 <cause>602</cause>
 <text>Invalid USERID!</text>
 </SetPNHidden>
 
 */
- (void) processHiddenPreview:(NSNotification *)notification {
    
    [AppUtility stopActivityIndicator];
    
    NSDictionary *responseD = [notification object];
    
    NSString *title = NSLocalizedString(@"Disable Hidden Chat", @"HiddenChatSetting - alert title:");
    
    NSString *detMessage = nil;
    
    UISwitch *hiddenSwitch = (UISwitch *)[self.view viewWithTag:HIDDEN_SWITCH_TAG];
    
    
    // success
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        // clears the old PIN!
        [self resetHiddenChat];
        [hiddenSwitch setOn:self.pendingHiddenChatState animated:YES];
        
        // if HC turned off, hide change pin
        if (self.pendingHiddenChatState == NO) {
            
            UIView *changeView = [self.view viewWithTag:CHANGE_PIN_TAG];
            changeView.alpha = 1.0;
            [UIView animateWithDuration:kMPParamAnimationStdDuration 
                             animations:^{
                                 changeView.alpha = 0.0;
                             }];
        }
        
    }
    // failed
    else {
        detMessage = NSLocalizedString(@"Disable Hidden Chat failed. Try again.", @"HiddenChatSetting - alert: inform of failure");
    }
    
    if (detMessage) {
        
        NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
        BOOL pinState = ([pin length] > 0)?YES:NO;
        
        [hiddenSwitch setOn:pinState animated:YES];
        self.pendingHiddenChatState = pinState;
        
        [Utility showAlertViewWithTitle:title message:detMessage];
    }
}



/*!
 @abstract handle connection failure and reset switch back to original values
 
 */
- (void) processConnectFailure:(NSNotification *)notification {
    
    
    //[AppUtility stopActivityIndicator];
    NSDictionary *responseD = [notification object];
    
    NSString *queryType = [responseD valueForKey:kTTXMLTypeTag];
    
    // if search setting failed
    if ([queryType isEqualToString:kMPHCRequestTypeSetPNHidden]) {
        
        UISwitch *hiddenSwitch = (UISwitch *)[self.view viewWithTag:HIDDEN_SWITCH_TAG];
        NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
        BOOL pinState = ([pin length] > 0)?YES:NO;
        
        [hiddenSwitch setOn:pinState animated:YES];
        self.pendingHiddenChatState = pinState;
    }
    
}





#pragma mark - Button




/*!
 @abstract pressed hide chat switch
 
 
 */
- (void) pressHide:(id)sender {
    
    NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
    //BOOL isLocked = [[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];
    
    // if currently enabled - we want to turn off
    //
    if (pin) {
        self.pendingHiddenChatState = NO;
        
        // always ask for old passcode first
        HiddenController *nextController = [[HiddenController alloc] initWithHCStatus:kHCViewStatusUnlockPIN];
        
        //nextController.title = NSLocalizedString(@"New Schedule", @"Schedule - title: view to edit status message");            
        UINavigationController *navigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:nextController];
        [AppUtility customizeNavigationController:navigationController];
        nextController.delegate = self;
        [self presentModalViewController:navigationController animated:YES];
        [navigationController release];
        [nextController release];
        
        
        /*
        // if locked
        // - unlock first
        //
        if (isLocked) {
            HiddenController *nextController = [[HiddenController alloc] initWithHCStatus:kHCViewStatusUnlockPIN];
            
            //nextController.title = NSLocalizedString(@"New Schedule", @"Schedule - title: view to edit status message");            
            UINavigationController *navigationController = [[UINavigationController alloc]
                                                            initWithRootViewController:nextController];
            [AppUtility customizeNavigationController:navigationController];
            nextController.delegate = self;
            [self presentModalViewController:navigationController animated:YES];
            [navigationController release];
            [nextController release];
        }
        else {
            // unlocked go ahead and turn off HC
            //
            [self resetHiddenChat];
            UIView *changeView = [self.view viewWithTag:CHANGE_PIN_TAG];
            [UIView animateWithDuration:0.3 
                             animations:^{
                                 changeView.alpha = 0.0;
                             } 
                             completion:^(BOOL finished){
                                 if (finished) {
                                     changeView.hidden = YES;
                                     changeView.alpha = 1.0;
                                 }
                             }];
        }*/      
    }
    // if currently disabled - we want to turn on
    // - set NEW PIN
    else {
        self.pendingHiddenChatState = YES;
        
        HiddenController *nextController = [[HiddenController alloc] initWithHCStatus:kHCViewStatusChangePIN];
        
        //nextController.title = NSLocalizedString(@"New Schedule", @"Schedule - title: view to edit status message");            
        UINavigationController *navigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:nextController];
        [AppUtility customizeNavigationController:navigationController];
        [self presentModalViewController:navigationController animated:YES];
        [navigationController release];
        [nextController release];
    }
    
}

/*!
 @abstract pressed change PIN
 
 */
- (void) pressChangePIN:(id)sender {
    
    HiddenController *nextController = [[HiddenController alloc] initWithHCStatus:kHCViewStatusChangePIN];
    
    //nextController.title = NSLocalizedString(@"New Schedule", @"Schedule - title: view to edit status message");            
    UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:nextController];
    [AppUtility customizeNavigationController:navigationController];
    [self presentModalViewController:navigationController animated:YES];
    [navigationController release];
    [nextController release];
    
}

#pragma mark - HiddenController

/*!
 @abstract Notifiy Delegate that unlock was successful
 */
- (void)HiddenController:(HiddenController *)controller unlockDidSucceed:(BOOL)didSucceed {
    
    if (didSucceed) {
        
        NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
        BOOL isLocked = [[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];
        
        // if unlocked and pending does not match current state
        // - then turn off HC
        if (!isLocked && self.pendingHiddenChatState == NO && pin) {
            [self requestDisableAllHiddenChats];
            
        }
        // reset pending
        else {
            
            if (pin) {
                self.pendingHiddenChatState = YES;
            }
            else {
                self.pendingHiddenChatState = NO;
            }
        }
    }
}

@end
