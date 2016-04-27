//
//  AddFriendController.m
//  mp
//
//  Created by M Tsai on 11-11-29.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "AddFriendController.h"
#import "MPFoundation.h"
#import "MPContactManager.h"

#import "FindIDController.h"

#import "TellFriendController.h"
#import "TKSpinButton.h"
#import "FriendSuggestionController.h"
#import "TKImageLabel.h"
#import "CDContact.h"
#import "SettingButton.h"


@interface AddFriendController (Private)
    
- (void) refreshSuggestionBadge;

@end




@implementation AddFriendController


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

#define kButtonStartY       11.0
#define kButtonHeightShift  55.0
#define kButtonHeight       45.0

#define SUGGESTION_BTN_TAG      18001
#define SYNC_ROW_TAG            18002
#define SYNC_BTN_TAG            18003
#define SUGGESTION_BADGE_TAG    18004
#define AUTOSYNC_BTN_TAG        18005
#define AUTOSYNC_ALERT_TAG      18006


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{

    // title
    //
    self.title = NSLocalizedString(@"Add New Friends", @"AddFriend - title: view to add new friends");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    // background
    //
    UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    backView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = backView;
    [backView release];            
    
    
    // suggestion button
    //
    CGFloat buttonStartY = kButtonStartY;
    UIButton *suggestionButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, buttonStartY, 310.0, 45.0)];
    [AppUtility configButton:suggestionButton context:kAUButtonTypeTextBarSmall];
    [suggestionButton addTarget:self action:@selector(pressSuggestion:) forControlEvents:UIControlEventTouchUpInside];
    [suggestionButton setTitle:NSLocalizedString(@"Friends Suggestions", @"AddFriend - button: provides friend suggestions to user") forState:UIControlStateNormal];
    suggestionButton.tag = SUGGESTION_BTN_TAG;
    //suggestionButton.enabled = NO;
    //suggestionButton.hidden = YES;
    [self.view addSubview:suggestionButton];
    
    // add red number indicator
    UIButton *sugBadge = [[UIButton alloc] initWithFrame:CGRectMake(266.0, (45-21.0)/2.0-1.0, 20.0, 20.0)];
    [AppUtility configButton:sugBadge context:kAUButtonTypeBadgeYellow];
    sugBadge.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
    sugBadge.hidden = YES;
    sugBadge.tag = SUGGESTION_BADGE_TAG;
    [suggestionButton addSubview:sugBadge];  
    [sugBadge release];
    [suggestionButton release];

    
    
    // find friend ID button
    //
    buttonStartY += kButtonHeightShift;
    UIButton *findIDButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, buttonStartY, 310.0, 45.0)];
    [AppUtility configButton:findIDButton context:kAUButtonTypeTextBarSmall];
    [findIDButton addTarget:self action:@selector(pressFindID:) forControlEvents:UIControlEventTouchUpInside];
    [findIDButton setTitle:NSLocalizedString(@"Find Friend with ID", @"AddFriend - button: find new friends with M+ID") forState:UIControlStateNormal];
    //findIDButton.hidden = NO;
    [self.view addSubview:findIDButton];
    [findIDButton release];
    
    // Tell Friends
    //
    buttonStartY += kButtonHeightShift;
    UIButton *tellButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, buttonStartY, 310.0, 45.0)];
    [AppUtility configButton:tellButton context:kAUButtonTypeTextBarSmall];
    [tellButton addTarget:self action:@selector(pressTell:) forControlEvents:UIControlEventTouchUpInside];
    [tellButton setTitle:NSLocalizedString(@"Tell Friends", @"AddFriend - button: tell friends about this app") forState:UIControlStateNormal];
    [self.view addSubview:tellButton];
    [tellButton release];
    
    // auto sync button
    //
    buttonStartY += kButtonHeightShift;
    SettingButton *syncButton = [[SettingButton alloc] initWithOrigin:CGPointMake(5.0, buttonStartY) 
                                                           buttonType:kSBButtonTypeSingle
                                                               target:self 
                                                             selector:@selector(pressAutoSync:) 
                                                                title:NSLocalizedString(@"Auto Sync Friends", @"AddFriends - button: list of blocked users")
                                                            showArrow:YES];
    syncButton.tag = AUTOSYNC_BTN_TAG;
    [self.view addSubview:syncButton];
    [syncButton release];
    
    // Sync row
    //
    buttonStartY += kButtonHeightShift;
    UIButton *syncRowButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, buttonStartY, 245.0, 45.0)];
    [AppUtility configButton:syncRowButton context:kAUButtonTypeTextBarSmall];
    [syncRowButton setTitle:NSLocalizedString(@"Not Synced Yet", @"AddFriend - button: friend has never been synced") forState:UIControlStateNormal];
    [syncRowButton setAdjustsImageWhenDisabled:NO];
    [syncRowButton setEnabled:NO];
    [Utility removeSubviewsForView:syncRowButton tag:kAUViewTagTextBarArrow];
    syncRowButton.tag = SYNC_ROW_TAG;
    [self.view addSubview:syncRowButton];
    [syncRowButton release];
    
    TKSpinButton *spinButton = [[TKSpinButton alloc] initWithFrame:CGRectMake(255.0, buttonStartY, 60.0, 45.0)
                                                       normalImage:[UIImage imageNamed:@"std_btn_green5_nor.png"]
                                                        pressImage:[UIImage imageNamed:@"std_btn_green5_prs.png"] disabledImage:[UIImage imageNamed:@"std_btn_green5_dis.png"] spinningImage:[UIImage imageNamed:@"friends_icon_sync.png"]];
    [spinButton addTarget:self action:@selector(pressSync:) forControlEvents:UIControlEventTouchUpInside];
    spinButton.tag = SYNC_BTN_TAG;
    [self.view addSubview:spinButton];
    [spinButton release];
    
    
    // observe sync events
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(handleSyncStart) name:MP_CONTACTMANAGER_PHONESYNC_START_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(handleSyncComplete) name:MP_CONTACTMANAGER_PHONESYNC_COMPLETE_NOTIFICATION object:nil];
    
}


/*!
 @abstract updates sync button for sync start
 */
- (void)handleSyncStart {
    
    UIButton *rowButton = (UIButton *)[self.view viewWithTag:SYNC_ROW_TAG];
    TKSpinButton *syncButton = (TKSpinButton *)[self.view viewWithTag:SYNC_BTN_TAG];

    
    // disables sync button
    //
    syncButton.enabled = NO;
    [syncButton startSpinning];
    
    // update button text
    //
    [rowButton setTitle:NSLocalizedString(@"Synchronizing...", @"AddFriend - text: friend synchronizing in progress") forState:UIControlStateNormal];
    
}
 

/*!
 @abstract updates sync button for sync complete
 */
- (void)handleSyncComplete {
    DDLogVerbose(@"AF-hsc: got complete notification");
    UIButton *rowButton = (UIButton *)[self.view viewWithTag:SYNC_ROW_TAG];
    TKSpinButton *syncButton = (TKSpinButton *)[self.view viewWithTag:SYNC_BTN_TAG];
    
    
    // enable sync button again
    //
    syncButton.enabled = YES;
    [syncButton stopSpinning];
    
    // update button text
    //
    NSDate *lastDate = [[MPSettingCenter sharedMPSettingCenter] getPhoneSyncCompleteDate];
    
    // only show sync if date is valid
    if ([lastDate compare:[NSDate dateWithTimeIntervalSince1970:0.0]] == NSOrderedDescending) {
        NSString *dateString = [Utility shortStyleTimeDate:lastDate];
        NSString *text = [NSString stringWithFormat:NSLocalizedString(@"%@ Synced", @"AddFriend - text: friend synchronizing in progress"), dateString];
        [rowButton setTitle:text forState:UIControlStateNormal];
        [rowButton setNeedsDisplay];
    }
    
    // update suggestion badge as well
    //
    [self refreshSuggestionBadge];
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
    
    DDLogInfo(@"AFC-vwa");
    
    [self refreshSuggestionBadge];
    
    
    // *** check memory of background CM
    BOOL isSyncRunning = [[AppUtility getBackgroundContactManager] isSyncRunning];
    
    // Update sync button text
    //
    // if syncn in progress
    //
    //if ([[MPSettingCenter sharedMPSettingCenter] isPhoneSyncRunning]) {
    if (isSyncRunning) {
        [self handleSyncStart];
    }
    // not running - get last sync time
    //
    else {
        [self handleSyncComplete];
    }
    
    // set auto sync state
    SettingButton *autoSyncButton = (SettingButton *)[self.view viewWithTag:AUTOSYNC_BTN_TAG];
    BOOL isAutoSyncOn = [[[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingAddressBookIsAllowed] boolValue];
    [autoSyncButton setValueBOOL:isAutoSyncOn animated:animated];
    
    // hide sync row if auto sync is off
    UIView *syncRow = [self.view viewWithTag:SYNC_ROW_TAG];
    UIView *syncButton = [self.view viewWithTag:SYNC_BTN_TAG];
    syncRow.alpha = isAutoSyncOn?1.0:0.0;
    syncButton.alpha = isAutoSyncOn?1.0:0.0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
    
}


- (void)viewWillDisappear:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];

    // reset animation when leaving
    //
    TKSpinButton *syncButton = (TKSpinButton *)[self.view viewWithTag:SYNC_BTN_TAG];
    [syncButton viewWillDisappear];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

/*!
 @abstract Refresh badge when entering foreground
 */
- (void) applicationWillEnterForeground:(NSNotification *)notification {
    [self refreshSuggestionBadge];
}

#pragma mark - Button

/*!
 @abstract 
 */
- (void) refreshSuggestionBadge {
    
    NSInteger count = [CDContact newSuggestedContactsCount];
    UIButton *badgeButton = (UIButton *)[self.view viewWithTag:SUGGESTION_BADGE_TAG];
    NSString *numString = [NSString stringWithFormat:@"%d", count];
    [AppUtility setBadge:badgeButton text:numString];

}


/*!
 @abstract starts phone sync
 */
- (void) pressSuggestion:(id)sender {
    
    FriendSuggestionController *nextController = [[FriendSuggestionController alloc] init];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
    
}

/*!
 @abstract show find ID view
 */
- (void) pressFindID:(id)sender {
    
    FindIDController *nextController = [[FindIDController alloc] init];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
    
}


/*!
 @abstract starts phone sync
 */
- (void) pressSync:(id)sender {
    
    [MPContactManager tryStartingPhoneBookSyncForceStart:YES delayed:NO];
    
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
        SettingButton *autoSyncButton = (SettingButton *)[self.view viewWithTag:AUTOSYNC_BTN_TAG];
        [autoSyncButton setValueBOOL:newValue animated:YES];
        
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingAddressBookIsAllowed settingValue:[NSNumber numberWithBool:newValue]];
        
        UIView *syncRow = [self.view viewWithTag:SYNC_ROW_TAG];
        UIView *syncButton = [self.view viewWithTag:SYNC_BTN_TAG];
        [UIView animateWithDuration:kMPParamAnimationStdDuration animations:^{
            syncRow.alpha = 0.0;
            syncButton.alpha = 0.0;
        }];
        
    }
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
            
            UIView *syncRow = [self.view viewWithTag:SYNC_ROW_TAG];
            UIView *syncButton = [self.view viewWithTag:SYNC_BTN_TAG];
            [UIView animateWithDuration:kMPParamAnimationStdDuration animations:^{
                syncRow.alpha = 1.0;
                syncButton.alpha = 1.0;
            }];
            
        }
        else {
            // sync cancelled
            [syncButton setValueBOOL:NO animated:YES];
        }
    }
    
}


@end
