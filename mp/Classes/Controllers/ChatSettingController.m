//
//  ChatSettingController.m
//  mp
//
//  Created by M Tsai on 11-12-25.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "ChatSettingController.h"
#import "MPFoundation.h"
#import "CDChat.h"
#import "ChatDialogController.h"
#import "CDMessage.h"
#import "MPChatManager.h"
#import "ChatNameController.h"
#import "MPImageManager.h"
#import "CDContact.h"
#import "SettingButton.h"
#import "MPContactManager.h"

#import "HiddenController.h"

NSString* const MP_CHATSETTING_DELETE_INVITE_NOTIFICATION = @"MP_CHATSETTING_DELETE_INVITE_NOTIFICATION";



@implementation ChatSettingController

@synthesize cdChat;
@synthesize pendingHiddenChatState;
@synthesize pendingInviteMessageID;
@synthesize pendingInviteContacts;
@synthesize pendingDeleteMessageID;

- (id)initWithCDChat:(CDChat *)newChat
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.cdChat = newChat;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    
    [cdChat release];
    [pendingInviteMessageID release];
    [pendingInviteContacts release];
    [pendingDeleteMessageID release];
    
    [super dealloc];
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - HC Request


/*!
 @abstract Tell M+ service if this chat is hidden or not
 - M+ will hide message previews for hidden chats
 
 */
- (void) requestHiddenPreviewUpdate { 
    
    [AppUtility startActivityIndicator];
    NSString *p2pUserID = [self.cdChat p2pUserID];
    [[MPHTTPCenter sharedMPHTTPCenter] setPNHiddenPreviewForUserID:p2pUserID groupID:self.cdChat.groupID hiddenStatus:self.pendingHiddenChatState disableAll:NO];
    
}



#pragma mark - View lifecycle

#define kYStart 10.0

#define NAME_BTN_TAG        11001
#define CLEAR_BTN_TAG       11002
#define MEMBER_LIST_TAG     11003
#define HIDDEN_BTN_TAG      11004
#define LEAVE_BTN_TAG       11005

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    BOOL isGroupChat = [self.cdChat isGroupChat];
    
    // title
    //
    self.title = NSLocalizedString(@"Chat Room Settings", @"ChatSetting - title: Settings for this chat");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    // background
    //
    UIScrollView *setupView = [[UIScrollView alloc] initWithFrame:appFrame];
    setupView.scrollEnabled = YES;
    setupView.contentSize=CGSizeMake(appFrame.size.width, 416.0);
    setupView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = setupView;
    [setupView release];
    

    // setup button frames
    //
    CGPoint invitePoint = CGPointZero;
    CGPoint hidePoint = CGPointZero;
    CGPoint clearPoint = CGPointZero;
    CGPoint leavePoint = CGPointZero;
    
    
    if (isGroupChat) {
        
        // name description
        //
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, kYStart, 150.0, 15.0)];
        [AppUtility configLabel:nameLabel context:kAULabelTypeBackgroundText];
        nameLabel.text = NSLocalizedString(@"Chat Room Name", @"ChatSettings - text: Name of chat room");
        [self.view addSubview:nameLabel];
        [nameLabel release];
        
        // name button
        //
        SettingButton *nameButton = [[SettingButton alloc] initWithOrigin:CGPointMake(5.0, kYStart+18.0) 
                                                                 buttonType:kSBButtonTypeSingle 
                                                                     target:self 
                                                                   selector:@selector(pressName:) 
                                                                      title:@""
                                                                  showArrow:YES];
        nameButton.tag = NAME_BTN_TAG;
        [self.view addSubview:nameButton];
        [nameButton release];
        
        // set frames
        invitePoint = CGPointMake(5.0, kYStart+78.0);
        hidePoint = CGPointMake(5.0, kYStart+138.0);
        clearPoint = CGPointMake(5.0, kYStart+198.0+31.0);
        leavePoint = CGPointMake(5.0, kYStart+258.0+31.0);
        
    }
    // for p2p chats
    else {
        
        // check if account is cancelled
        // - if so, hide invite button
        //
        CDContact *p2pContact = [self.cdChat p2pUser];
        if ([p2pContact isUserAccountedCanceled]) {
            // set frames
            invitePoint = CGPointZero;
            hidePoint = CGPointMake(5.0, kYStart);
            clearPoint = CGPointMake(5.0, kYStart+60.0+31.0);
            leavePoint = CGPointMake(5.0, kYStart+120.0+31.0);

        }
        else {
            // set frames
            invitePoint = CGPointMake(5.0, kYStart);
            hidePoint = CGPointMake(5.0, kYStart+60);
            clearPoint = CGPointMake(5.0, kYStart+120.0+31.0);
            leavePoint = CGPointMake(5.0, kYStart+180.0+31.0);
        }
    }
    
    // invite
    // - only for valid accounts
    // 
    if (invitePoint.x != 0.0) {
        
        NSString *inviteText = nil;
        if ([self.cdChat isGroupChat]) {
            inviteText = NSLocalizedString(@"Invite Members", @"ChatSettings - button: add more friends to chat");
        }
        else {
            inviteText = NSLocalizedString(@"Create Group Chat", @"ChatSettings - button: create a new group chat");
        }
        
        SettingButton *inviteButton = [[SettingButton alloc] initWithOrigin:invitePoint 
                                                                buttonType:kSBButtonTypeSingle 
                                                                    target:self 
                                                                  selector:@selector(pressInvite:) 
                                                                     title:inviteText
                                                                 showArrow:NO];
        [self.view addSubview:inviteButton];
        
        if (!isGroupChat) {
            // disable create group for M+ helper
            CDContact *p2pContact = [self.cdChat p2pUser];
            if (p2pContact && [MPContactManager isFriendAHelper:p2pContact]) {
                inviteButton.enabled = NO;
            }
        }
        
        [inviteButton release];
    }
    
    
    // hidden chat
    //
    NSString *hideText = NSLocalizedString(@"Hide This Chat", @"ChatSettings - button: hide this chat room");
    
    SettingButton *hideButton = [[SettingButton alloc] initWithOrigin:hidePoint 
                                                             buttonType:kSBButtonTypeSingle 
                                                                 target:self 
                                                               selector:@selector(pressHide:) 
                                                                  title:hideText
                                                              showArrow:NO];
    hideButton.tag = HIDDEN_BTN_TAG;
    [self.view addSubview:hideButton];
    [hideButton release];
    
    
    // hidden chat description
    //
    UILabel *hiddenLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, hideButton.frame.origin.y+46.0, 295.0, 30.0)];
    [AppUtility configLabel:hiddenLabel context:kAULabelTypeBackgroundTextHighlight];
    hiddenLabel.text = NSLocalizedString(@"Hides this chat from Chat List. Hidden chats are revealed when the correct PIN is entered.", @"MyProfile - text: This button allows users to enable and disable others to view their current online presence status.");
    hiddenLabel.numberOfLines = 2;
    hiddenLabel.textAlignment = UITextAlignmentCenter;
    hiddenLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:hiddenLabel];
    [hiddenLabel release];
    
    
    // set pending state to match actual state
    self.pendingHiddenChatState = [self.cdChat.isHiddenChat boolValue];
    
    // clear history
    SettingButton *clearButton = [[SettingButton alloc] initWithOrigin:clearPoint 
                                                             buttonType:kSBButtonTypeSingle 
                                                                 target:self 
                                                               selector:@selector(pressClear:) 
                                                                  title:NSLocalizedString(@"Clear Chat History", @"ChatSettings - button: clear all messages for this chat")
                                                              showArrow:NO];
    clearButton.tag = CLEAR_BTN_TAG;
    [self.view addSubview:clearButton];
    [clearButton release];
    
    // leave chat, only for group chat
    if (isGroupChat) {
        SettingButton *leaveButton = [[SettingButton alloc] initWithOrigin:leavePoint 
                                                                buttonType:kSBButtonTypeSingle 
                                                                    target:self 
                                                                  selector:@selector(pressLeave:) 
                                                                     title:NSLocalizedString(@"Leave Chat Room", @"ChatSettings - button: leaves and deletes chat room")
                                                                 showArrow:NO];
        leaveButton.tag = LEAVE_BTN_TAG;
        [self.view addSubview:leaveButton];
        [leaveButton release];
    }

    
    // listen for results
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processHiddenPreview:) name:MP_HTTPCENTER_SET_PN_HIDDEN_NOTIFICATION object:nil];
    
    // if connection failure - for presence and search ID
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processConnectFailure:) name:MP_HTTPCENTER_CONNECT_FAILED_NOTIFICATION object:nil];
    
    
    // observe for message success and failure
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleConfirmation:) name:MP_MESSAGECENTER_SENT_CONFIRMATION_NOTIFICATION object:nil];
    
    // if message timeout
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(handleTimeout:) name:MP_MESSAGECENTER_SENT_TIMEOUT_NOTIFICATION object:nil];

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

#define kMemberCellWidth 309.0
#define kMemberCellHeight 44.0

- (void)viewWillAppear:(BOOL)animated
{
    DDLogInfo(@"CSC-vwa");
    [super viewWillAppear:animated];
    
    
    // refresh name
    SettingButton *nameButton = (SettingButton *)[self.view viewWithTag:NAME_BTN_TAG];
    [nameButton setTitle:[self.cdChat displayNameStyle:kCDChatNameStyleFull]  forState:UIControlStateNormal];
    
    
    // update hidden chat status
    //
    SettingButton *hiddenButton = (SettingButton *)[self.view viewWithTag:HIDDEN_BTN_TAG];
    NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
    BOOL isLocked = [[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];
    
    // if was just unlocked
    // - request M+ service to set chat to hidden or not
    //
    if (pin && !isLocked && [self.cdChat.isHiddenChat boolValue] != self.pendingHiddenChatState) {
        [self requestHiddenPreviewUpdate];
    }
    [hiddenButton setValueBOOL:[self.cdChat.isHiddenChat boolValue] animated:NO];
    
    
    // for group chat show members
    if ([self.cdChat isGroupChat]) {

        CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
        
        NSArray *sortedMembers = [self.cdChat sortedParticipants];
        NSArray *allMembers = [sortedMembers arrayByAddingObject:[CDContact mySelf]];
        
        int i = 0;
        

        // clear out old views
        //
        [Utility removeSubviewsForView:self.view tag:MEMBER_LIST_TAG];
        
        // find starting location
        UIButton *lastButton = (UIButton *)[self.view viewWithTag:LEAVE_BTN_TAG];
        CGFloat startY = lastButton.frame.origin.y + lastButton.frame.size.height + 15.0;
        
        
        // Member description
        //
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, startY, 150.0, 15.0)];
        [AppUtility configLabel:nameLabel context:kAULabelTypeBackgroundText];
        nameLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Members (%d)", @"ChatSettings - text: Member listing"), [self.cdChat totalParticipantCount]];
        [self.view addSubview:nameLabel];
        [nameLabel release];
        
        startY += 18.0;
        
        for (CDContact *iMember in allMembers){
            
            
            
            // back view
            //
            NSString *backName = nil;
            if (i == 0) {
                backName = @"profile_statusfield_top_nor.png";
            }
            else if (i == [allMembers count]-1) {
                backName = @"profile_statusfield_bottom_nor.png";
            }
            else {
                backName = @"profile_statusfield_center_nor.png";
            }
            i++;
            
            UIImageView *backView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:backName]];
            backView.frame = CGRectMake((appFrame.size.width - kMemberCellWidth)/2.0, startY, kMemberCellWidth, kMemberCellHeight);
            backView.tag = MEMBER_LIST_TAG;
            startY += kMemberCellHeight;
            
            // photo view
            UIImageView *photoView = [[UIImageView alloc] initWithFrame:CGRectMake(4.0, 4.0, 36.0, 36.0)];
            
            MPImageManager *imageM = [[MPImageManager alloc] init];
            
            // photo
            UIImage *gotImage = [imageM getImageForObject:iMember context:kMPImageContextList];
            if (gotImage) {
                photoView.image = gotImage;
            }
            else {
                photoView.image = [UIImage imageNamed:@"profile_headshot_bear_black.png"];
            }
            [photoView addRoundedCornerRadius:5.0];
            [backView addSubview:photoView];
            [photoView release];
            [imageM release];
            
            // name
            UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(50.0, 12.0, 200.0, 20.0)];
            [AppUtility configLabel:nameLabel context:kAULabelTypeBlackSmall];
            nameLabel.text = [iMember displayName];
            [backView addSubview:nameLabel];
            [nameLabel release];
            
            [self.view addSubview:backView];
            
            // increase height if needed
            CGFloat desiredHeight = backView.frame.origin.y + backView.frame.size.height + 20.0;
            UIScrollView *contentScrollView = (UIScrollView *)self.view;
            if (desiredHeight > contentScrollView.contentSize.height) {
                [contentScrollView setContentSize:CGSizeMake(contentScrollView.contentSize.width, desiredHeight)];
            }
            
            [backView release];
        }
    }

}

-(void) viewWillDisappear:(BOOL)animated {
    

    [super viewWillDisappear:animated];
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
- (void) pressName:(id)sender {
    
    ChatNameController *newController = [[ChatNameController alloc] initWithCDChat:self.cdChat];
    [self.navigationController pushViewController:newController animated:YES];
    [newController release];

}


/*!
 @abstract pressed invite button
 */
- (void) pressInvite:(id)sender {
    
    SelectContactController *nextController = [[SelectContactController alloc] 
                                               initWithTableStyle:UITableViewStylePlain 
                                               type:kMPSelectContactTypeInviteGroup
                                               viewContacts:self.cdChat.participants];
    
    
    // Create nav controller to present modally
    UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:nextController];
    nextController.delegate = self;

    
    [AppUtility customizeNavigationController:navigationController];
    
    
    [self presentModalViewController:navigationController animated:YES];
    [navigationController release];
    [nextController release];
    
}




/*!
 @abstract pressed hide chat switch
 
 
 */
- (void) pressHide:(id)sender {
 
    NSString *pin = [[MPSettingCenter sharedMPSettingCenter] hiddenChatPIN];
    BOOL isLocked = [[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];
    
    // toggle pending state
    // - set when unlocked
    //
    self.pendingHiddenChatState = ![self.cdChat.isHiddenChat boolValue];
    
    // Check if HC is enabled
    //
    if (pin) {
        
        // if locked, unlock first
        //
        if (isLocked) {
            
            HiddenController *nextController = [[HiddenController alloc] initWithHCStatus:kHCViewStatusUnlockPIN];
            
            //nextController.title = NSLocalizedString(@"New Schedule", @"Schedule - title: view to edit status message");            
            UINavigationController *navigationController = [[UINavigationController alloc]
                                                            initWithRootViewController:nextController];
            [AppUtility customizeNavigationController:navigationController];
            [self presentModalViewController:navigationController animated:YES];
            [navigationController release];
            [nextController release];
            
        }
        // else already unlocked, so change HC state
        else {
            [self requestHiddenPreviewUpdate];
        }
        
    }
    // HC not enabled, set PIN first
    //
    else {
        
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
 @abstract pressed invite button
 */
- (void) pressClear:(id)sender {
    
    UIActionSheet *aSheet;
	
	aSheet	= [[UIActionSheet alloc]
               initWithTitle:NSLocalizedString(@"Delete all message in this chat room.", @"ChatSettings - Alert: confirm clear chat history")
               delegate:self
               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel contact group action")
               destructiveButtonTitle:NSLocalizedString(@"Delete", @"Alert: Delete button")
               otherButtonTitles:nil];
	
	aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	
	[aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
	[aSheet release];    
}

/*!
 @abstract pressed invite button
 */
- (void) pressLeave:(id)sender {
    
    UIActionSheet *aSheet;
	
	aSheet	= [[UIActionSheet alloc]
               initWithTitle:NSLocalizedString(@"Exit and delete all message in this chat room.", @"ChatSettings - Alert: confirm leave and delete chat")
               delegate:self
               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel contact group action")
               destructiveButtonTitle:NSLocalizedString(@"Leave Chat Room", @"Alert: leave and delete chat button")
               otherButtonTitles:nil];
	
	aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	
	[aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
	[aSheet release];    
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
    
    NSString *title = NSLocalizedString(@"Set Hidden Chat", @"ChatSetting - alert title:");
    
    NSString *detMessage = nil;
    
    SettingButton *hiddenButton = (SettingButton *)[self.view viewWithTag:HIDDEN_BTN_TAG];
        
    // success
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        self.cdChat.isHiddenChat = [NSNumber numberWithBool:self.pendingHiddenChatState];
        [AppUtility cdSaveWithIDString:@"save hidden chat state" quitOnFail:NO];
        [hiddenButton setValueBOOL:self.pendingHiddenChatState animated:YES];

    
    }
    // failed
    else {
        detMessage = NSLocalizedString(@"Hidden chat update failed. Try again.", @"ChatSetting - alert: inform of failure");
    }
    
    if (detMessage) {

        [hiddenButton setValueBOOL:[self.cdChat.isHiddenChat boolValue] animated:YES];
        self.pendingHiddenChatState = [self.cdChat.isHiddenChat boolValue];
        
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
        
        SettingButton *hiddenButton = (SettingButton *)[self.view viewWithTag:HIDDEN_BTN_TAG];
        [hiddenButton setValueBOOL:[self.cdChat.isHiddenChat boolValue] animated:YES];
        self.pendingHiddenChatState = [self.cdChat.isHiddenChat boolValue];
        
        /*NSString *title = NSLocalizedString(@"Set Hidden Chat", @"ChatSetting - alert title:");
        
        NSString *detMessage = NSLocalizedString(@"Hidden chat update failed. Try again.", @"ChatSetting - alert: inform of failure");
        
        [Utility showAlertViewWithTitle:title message:detMessage];*/
    }
    
}



#pragma mark - SelectContactsControllerDelegate


/*!
 @abstract Called after invite selection
 
 P2P - create new group chat and show view
 Group - invite more contacts into this group chat
 
 */
- (void)selectContactsController:(SelectContactController *)selectContactsController chatContacts:(NSArray *)contacts{
    
    // invite to group and create group
    BOOL didInvite = NO;
    
    // if P2P chat
    // - create new dialog with group chat
    // - insert on to stack
    // - pop the rest off
    // - dismiss modal view
    //
    if (![self.cdChat isGroupChat]) {
        
        // chat list, p2p chat dialog, chat settings
        //
        NSArray *originalControllers = self.navigationController.viewControllers;
        
        NSMutableArray *newChatParitcipants = [[NSMutableArray alloc] initWithArray:[self.cdChat.participants allObjects]];
        [newChatParitcipants addObjectsFromArray:contacts];
        
        CDChat *chat = [CDChat chatWithCDContacts:newChatParitcipants groupID:nil shouldSave:YES];
        [newChatParitcipants release];
        
        // only add if brand new chats
        //
        if (chat.isBrandNew) {
            chat.isBrandNew = NO;
            // add a add control message so we can add join noticies
            // - for group chat only
            // - no need for sent time - this will help maintain it as the first message
            //
            [[MPChatManager sharedMPChatManager] addGroupChatControlAddMessageForChat:chat shouldSend:NO];
        }
        
        ChatDialogController *newController = [[ChatDialogController alloc] initWithCDChat:chat];
        
        // new stack: chat list, new group chat
        NSArray *newControllers = [NSArray arrayWithObjects:[originalControllers objectAtIndex:0], newController, nil];
        
        [self.navigationController setViewControllers:newControllers animated:NO];
        [newController release];
        
        
    }
    /*
     invite into existing group chat
     - add new participants
     - pop off setting
     */
    else {
        
        // add new participants into group chat
        //
        [self.cdChat addContactsToGroupChat:contacts];
        
        // send invite add-control message
        // - inform others that friend added to chat
        //
        CDMessage *inviteMessage = [[MPChatManager sharedMPChatManager] addGroupChatControlAddMessageForChat:self.cdChat shouldSend:YES];
        
        if (inviteMessage) {  
            didInvite = YES;
            self.pendingInviteMessageID = inviteMessage.mID;
            self.pendingInviteContacts = contacts;
            [AppUtility startActivityIndicator];
        }
        
    }
    
    // don't dismiss for invite - since we need to wait for confirmation
    //
    if (!didInvite) {
        [selectContactsController dismissModalViewControllerAnimated:YES];
    }

}



#pragma mark - Delete Chats


/*!
 @abstract process incoming confirmations
 
 */
- (void) handleConfirmation:(NSNotification *)notification {
    
    NSString *messageID = [notification object];
    
    // if invite sent out ok
    if ([self.pendingInviteMessageID isEqualToString:messageID]) {
        [AppUtility cdSaveWithIDString:@"group invite: save added contacts" quitOnFail:NO];
        [self.cdChat printParticipantIDs];
        
        [AppUtility stopActivityIndicator];
        
        // dismiss modal first!
        // - otherwise we can't dismiss after poping the modal parent (this viewC)
        //
        [self dismissModalViewControllerAnimated:YES];
        [self.navigationController popViewControllerAnimated:NO];
        
        self.pendingInviteMessageID = nil;
    }
    else if ([self.pendingDeleteMessageID isEqualToString:messageID]) {
        [AppUtility stopActivityIndicator];

        [CDChat deleteChat:self.cdChat];
        //[[MPChatManager sharedMPChatManager] deleteChat:self.cdChat];
        
        [AppUtility cdSaveWithIDString:@"CSC: leave and delete group chat" quitOnFail:NO];
        [[MPChatManager sharedMPChatManager] updateChatBadgeCount]; 
        self.pendingDeleteMessageID = nil;

        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}


/*!
 @abstract process message timeouts
 
 Use:
 - can cancel pending image updates
 
 */
- (void) handleTimeout:(NSNotification *)notification {
    
    NSString *messageID = [notification object];
    
    // if invite sent failed
    if ([self.pendingInviteMessageID isEqualToString:messageID]) {
        
        // remove contacts added
        //
        [self.cdChat removeContactsFromGroupChat:self.pendingInviteContacts];
        [AppUtility cdSaveWithIDString:@"group invite: remove invited since invite msg failed" quitOnFail:NO];

        // remove chat message, so it does not look like an invite
        // - this also saves
        [CDMessage deleteMessageWithID:messageID];
        
        // ask dialog to reload
        // - so invite message does not show up
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATSETTING_DELETE_INVITE_NOTIFICATION object:[self.cdChat objectID]];
        
        self.pendingInviteMessageID = nil;
        self.pendingInviteContacts = nil;
        
        [AppUtility stopActivityIndicator];
        [AppUtility showAlert:kAUAlertTypeNetwork];
    }
    else if ([self.pendingDeleteMessageID isEqualToString:messageID]) {
    
        [AppUtility stopActivityIndicator];

        self.pendingDeleteMessageID = nil;

        // delete leave message since it failed
        //
        [CDMessage deleteMessageWithID:messageID];
        
        [AppUtility showAlert:kAUAlertTypeNetwork];
    }
}


#pragma mark - Action Sheet: Clear Chat History

/*!
 @abstract respond to actionsheet selection
 */
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // if not cancel
    if (buttonIndex != [actionSheet cancelButtonIndex]) {
        
		NSString *actionButtonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
		if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Delete",nil)]) {
            [self.cdChat clearChatHistory];
            
            // usually done with setting so go back to dialog
            [self.navigationController popViewControllerAnimated:YES];
		}
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Leave Chat Room", nil)]) {
            
            CDChat *deleteChat = self.cdChat;
            
            // request deletion from CM
            NSString *messageID = [[MPChatManager sharedMPChatManager] requestDeleteChat:deleteChat];
            
            // Delete is pending, so save state
            if ([messageID length] > 0) {
                
                [AppUtility startActivityIndicator];
                self.pendingDeleteMessageID = messageID;
                
            }
            // p2p chat was deleted
            else {
                // save afterwards
                [AppUtility cdSaveWithIDString:@"CSC: deleting a chat" quitOnFail:NO];
                [[MPChatManager sharedMPChatManager] updateChatBadgeCount];  
                [self.navigationController popToRootViewControllerAnimated:YES];
                
            }
        }
    }
    else {
        DDLogVerbose(@"Delete history or leave chat cancelled");
    }
}



@end
