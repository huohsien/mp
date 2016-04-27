//
//  PhoneBookInfoController.m
//  mp
//
//  Created by Min Tsai on 1/29/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "PhoneBookInfoController.h"

#import "MPFoundation.h"
#import "CDContact.h"
#import "CDChat.h"
#import "MPFoundation.h"
#import "MPContactManager.h"
#import "TextEmoticonView.h"

#import "ContactProperty.h"
#import "OperatorInfoCenter.h"
#import "TKImageLabel.h"


@implementation PhoneBookInfoController

@synthesize phoneProperty;
@synthesize operatorNumber;
@synthesize contact;


- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [phoneProperty release];
    [operatorNumber release];
    [contact release];
    [super dealloc];
}

- (id)initWithPhoneProperty:(ContactProperty *)property operatorNumber:(NSNumber *)operator mpContact:(CDContact *)newContact
{
	self = [super init];
	if (self != nil)
	{
        self.phoneProperty = property;
        self.operatorNumber = operator;
        self.contact = newContact;
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

#define PHOTO_IMG_TAG       18001
#define OPERATOR_VIEW_TAG   18002
#define OPERATOR_LABEL_TAG  18003
#define STATUS_LABEL_TAG    18004
#define PRESENCE_LABEL_TAG  18005

#define SMS_WARNING_TAG     18008
#define CALL_WARNING_TAG    18009
#define INVITE_WARNING_TAG  18010


#define kFIButtonWidth  140.0
#define kFIButtonHeight 100.0
#define kFIButtonMargin 10.0
#define kFIButtonStartX 15.0
#define kFIButtonStartY 143.0

#define kNameYStart     15.0

/*!
 @abstract Loads contact information using current contact information
 */
- (void) loadContactInfo {
    
    if (self.contact) {
        UILabel *statusLabel = (UILabel *)[self.view viewWithTag:STATUS_LABEL_TAG];
        UILabel *presenceLabel = (UILabel *)[self.view viewWithTag:PRESENCE_LABEL_TAG];
        
        [statusLabel setText:self.contact.statusMessage];
        
        NSString *presenceString = [self.contact presenceString];
        
        if ([self.contact isOnline]) {
            presenceLabel.text = presenceString;
        }
        else if ([presenceString length] > 0){
            presenceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"last seen %@", @"FriendInfo - text: indicates when user was last logged in"), [self.contact presenceString]];
        }
        // not presence, so show blank
        else {
            presenceLabel.text = @"";
        }
    }
}

/*!
 @abstract Updates the title status if new presence information comes in
 
 */
- (void) reloadContactInfo:(NSNotification *)notification {
    
    NSSet *userIdSet = [notification object];
    
    // if update contains this contact
    if ([userIdSet containsObject:self.contact.userID]) {
        [self loadContactInfo];
    }
    
}


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    
    //CGRect appFrame = [Utility appFrame];
    
    // title
    //
    self.title = NSLocalizedString(@"Info", @"PhoneBookInfo - title: detailed info about friend");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    // background
    //
    UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    backView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = backView;
    [backView release];            
    
    
    // photo view
    //
    UIImageView *headShotView = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, 15.0, 98.0, 98.0)];
    headShotView.image = [UIImage imageNamed:@"profile_headshot_bear3.png"];
    [self.view addSubview:headShotView];
    
    // actual image
    //
    UIImageView *photoView = [[UIImageView alloc] initWithFrame:CGRectMake(6.5, 5.5, 85.0, 85.0)];
    photoView.backgroundColor = [UIColor clearColor];
    //photoView.alpha = 0.5;
    photoView.tag = PHOTO_IMG_TAG;
    [headShotView addSubview:photoView];
    
    MPImageManager *imageM = [[MPImageManager alloc] init];
    UIImage *gotImage = [imageM getImageForObject:self.contact context:kMPImageContextList];
	if (gotImage) {
        photoView.image = gotImage;
    }
    // if M+ photo does not exists, get AB photo instead
    //
    else {
        dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
        dispatch_async(back_queue, ^{
            
            // load data from AB
            //
            MPContactManager *backCM = [AppUtility getBackgroundContactManager];
            UIImage *abImage = [backCM personImageWithRecordID:self.phoneProperty.abRecordID];
            
            if (abImage) {
                // update in main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    photoView.image = abImage;
                });
            }
        });
    }
    [imageM release];
    [photoView release];
    [headShotView release];

    CGFloat nameWidth = 190.0;
    
    
    // name
    //
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(115.0, kNameYStart, nameWidth, 19.0)];
    [AppUtility configLabel:nameLabel context:kAULabelTypeBlackStandardPlus];
    nameLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    nameLabel.text =  self.phoneProperty.name; //[self.contact displayName];
    [self.view addSubview:nameLabel];
    [nameLabel release];

    // align left
    CGRect phoneNumberRect = CGRectMake(115.0, kNameYStart+26.0, 140.0, 15.0);
    
    // add operator image and label
    //
    if (self.operatorNumber) {
        //UIButton *operatorButton = [[UIButton alloc] initWithFrame:CGRectMake(265.0, kNameYStart-6.0, 47.0, 28.0)];
        UIButton *operatorButton = [[UIButton alloc] initWithFrame:CGRectMake(108.0, kNameYStart+18.0, 47.0, 28.0)];
        [AppUtility configButton:operatorButton context:kAUButtonTypeOperator];
        
        UIImage *opImage = [[OperatorInfoCenter sharedOperatorInfoCenter] backImageForOperatorNumber:self.operatorNumber];
        NSString *opText = [[OperatorInfoCenter sharedOperatorInfoCenter] nameForOperatorNumber:self.operatorNumber];
        
        [operatorButton setBackgroundImage:opImage forState:UIControlStateNormal];
        [operatorButton setTitle:opText forState:UIControlStateNormal];
        CGSize textSize = [opText sizeWithFont:operatorButton.titleLabel.font];
        CGFloat tWidth = textSize.width + 32.0;
        CGRect opFrame = operatorButton.frame;
        //opFrame.origin.x = opFrame.origin.x+opFrame.size.width - tWidth;
        opFrame.size.width = tWidth;
        operatorButton.frame = opFrame;
        
        [self.view addSubview:operatorButton];
        [operatorButton release];  
        
        phoneNumberRect = CGRectMake(108.0 + tWidth + 1.0, kNameYStart+26.0, 140.0, 15.0);
    }
    
    
    // Phone Number
    //
    /*NSString *cc = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPhoneCountryCode];
    NSString *phoneString = [Utility formatPhoneNumber:self.phoneProperty.value countryCode:cc showCountryCode:NO];
    */
    UILabel *phoneLabel = [[UILabel alloc] initWithFrame:phoneNumberRect];
    [AppUtility configLabel:phoneLabel context:kAULabelTypeGrayMicroPlus];
    phoneLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    // - don't format for now phoneLabel.text = phoneString;
    // use iOS format;
    phoneLabel.text = self.phoneProperty.valueString; 
    [self.view addSubview:phoneLabel];
    [phoneLabel release];
    
    

    if (self.contact) {
        // status
        //
        TextEmoticonView *statusLabel = [[TextEmoticonView alloc] initWithFrame:CGRectMake(115.0, kNameYStart+44.0, 190.0, 51.0)];
        [AppUtility configLabel:(UILabel *)statusLabel context:kAULabelTypeGrayMicroPlus];
        statusLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
        statusLabel.numberOfLines = 3;
        statusLabel.tag = STATUS_LABEL_TAG;
        [self.view addSubview:statusLabel];
        [statusLabel release];
        
        
        // last seen
        //
        UILabel *lastLabel = [[UILabel alloc] initWithFrame:CGRectMake(115.0, kNameYStart+97.0, 120.0, 12.0)];
        [AppUtility configLabel:lastLabel context:kAULabelTypeLightGrayNanoPlus];
        lastLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
        lastLabel.tag = PRESENCE_LABEL_TAG;
        [self.view addSubview:lastLabel];
        [lastLabel release];
        
        [self loadContactInfo];
    }
    
    
    
    // add button background
    // 
    UIImage *backImage = [UIImage imageNamed:@"info_bk.png"];
    CGSize backSize = [backImage size];
    UIImageView *backImageView = [[UIImageView alloc] initWithImage:backImage];
    backImageView.frame = CGRectMake(0.0, 128.0, backSize.width, backSize.height);
    backImageView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:backImageView];
    [backImageView release];
    
    // setup buttons
    //
    CGRect rect1 = CGRectMake(kFIButtonStartX, kFIButtonStartY, kFIButtonWidth, kFIButtonHeight);
    CGRect rect2 = CGRectMake(kFIButtonStartX+kFIButtonWidth+kFIButtonMargin, kFIButtonStartY, kFIButtonWidth, kFIButtonHeight);
    CGRect rect3 = CGRectMake(kFIButtonStartX, kFIButtonStartY+kFIButtonHeight+kFIButtonMargin, kFIButtonWidth, kFIButtonHeight);
    CGRect rect4 = CGRectMake(kFIButtonStartX+kFIButtonWidth+kFIButtonMargin, kFIButtonStartY+kFIButtonHeight+kFIButtonMargin, kFIButtonWidth, kFIButtonHeight);
    
    
    UIEdgeInsets buttonInsets = UIEdgeInsetsMake(69.0, 10.0, 11.0, 10.0);
    
    
    // call button
    UIButton *callButton = [[UIButton alloc] initWithFrame:rect1];
    [callButton setBackgroundImage:[UIImage imageNamed:@"info_btn_phone_nor.png"] forState:UIControlStateNormal];
    [callButton setBackgroundImage:[UIImage imageNamed:@"info_btn_phone_prs.png"] forState:UIControlStateHighlighted];
    callButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
    callButton.titleLabel.textColor = [UIColor whiteColor];
    callButton.contentEdgeInsets = buttonInsets;
    [callButton setTitle:NSLocalizedString(@"Call", @"FriendInfo- button: call friend") forState:UIControlStateNormal];
    [callButton addTarget:self action:@selector(pressCall:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:callButton];
    [callButton release];
    

    BOOL enableSMS = YES;
    if ([Utility isTWFixedLinePhoneNumber:self.phoneProperty.value]) {
        enableSMS = NO;
    }
    
    // sms button
    UIButton *smsButton = [[UIButton alloc] initWithFrame:rect2];
    [smsButton setBackgroundImage:[UIImage imageNamed:@"info_btn_paysms_nor.png"] forState:UIControlStateNormal];
    [smsButton setBackgroundImage:[UIImage imageNamed:@"info_btn_paysms_prs.png"] forState:UIControlStateHighlighted];
    smsButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
    smsButton.titleLabel.textColor = [UIColor whiteColor];
    smsButton.contentEdgeInsets = buttonInsets;
    [smsButton setTitle:NSLocalizedString(@"SMS", @"FriendInfo- button: text friend") forState:UIControlStateNormal];
    [smsButton addTarget:self action:@selector(pressSMS:) forControlEvents:UIControlEventTouchUpInside];
    smsButton.enabled = enableSMS;
    [self.view addSubview:smsButton];
    [smsButton release];
    
    // blank disabled button
    UIButton *blankButton = [[UIButton alloc] initWithFrame:rect3];
    [blankButton setBackgroundImage:[UIImage imageNamed:@"info_btn_dis.png"] forState:UIControlStateDisabled];
    blankButton.enabled = NO;
    [self.view addSubview:blankButton];
    [blankButton release];

    if (self.contact) {
        // chat button
        UIButton *chatButton = [[UIButton alloc] initWithFrame:rect4];
        [chatButton setBackgroundImage:[UIImage imageNamed:@"info_btn_chat_nor.png"] forState:UIControlStateNormal];
        [chatButton setBackgroundImage:[UIImage imageNamed:@"info_btn_chat_prs.png"] forState:UIControlStateHighlighted];
        chatButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
        chatButton.titleLabel.textColor = [UIColor whiteColor];
        chatButton.contentEdgeInsets = buttonInsets;
        [chatButton setTitle:NSLocalizedString(@"<chat info view>", @"FriendInfo- button: start M+ chat") forState:UIControlStateNormal];
        [chatButton addTarget:self action:@selector(pressChat:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:chatButton];
        [chatButton release];
    }
    else {
        
        // invite button
        UIButton *inviteButton = [[UIButton alloc] initWithFrame:rect4];
        [inviteButton setBackgroundImage:[UIImage imageNamed:@"info_btn_invite_nor.png"] forState:UIControlStateNormal];
        [inviteButton setBackgroundImage:[UIImage imageNamed:@"info_btn_invite_prs.png"] forState:UIControlStateHighlighted];
        inviteButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
        inviteButton.titleLabel.textColor = [UIColor whiteColor];
        inviteButton.contentEdgeInsets = buttonInsets;
        [inviteButton setTitle:NSLocalizedString(@"Invite", @"FriendInfo- button: invite to use this app") forState:UIControlStateNormal];
        [inviteButton addTarget:self action:@selector(pressInvite:) forControlEvents:UIControlEventTouchUpInside];
        inviteButton.enabled = enableSMS; // since invite requires sms feature
        [self.view addSubview:inviteButton];
        [inviteButton release];
        
    }

    
    // block button
    /*UIButton *blockButton = [[UIButton alloc] initWithFrame:rect3];
    [blockButton setBackgroundImage:[UIImage imageNamed:@"info_btn_block_nor.png"] forState:UIControlStateNormal];
    [blockButton setBackgroundImage:[UIImage imageNamed:@"info_btn_block_prs.png"] forState:UIControlStateHighlighted];
    blockButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
    blockButton.titleLabel.textColor = [UIColor whiteColor];
    blockButton.contentEdgeInsets = buttonInsets;
    [blockButton setTitle:NSLocalizedString(@"Block", @"FriendInfo- button: block friend") forState:UIControlStateNormal];
    [blockButton addTarget:self action:@selector(pressBlock:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:blockButton];
     [blockButton release];
     */
    

    
    
    // setup buttons
    //
    
   /* CGRect rect1 = CGRectMake(5.0, 141.0, 310.0, 50.0);
    CGRect rect2 = CGRectMake(5.0, 196.0, 310.0, 50.0);
    CGRect rect3 = CGRectMake(5.0, 251.0, 310.0, 50.0);
    //CGRect rect4 = CGRectMake(5.0, 306.0, 310.0, 50.0);
    
    
    // call button
    UIButton *callButton = [[UIButton alloc] initWithFrame:rect1];
    [AppUtility configInfoButton:callButton context:kAUInfoButtonTypeCall];
    [callButton addTarget:self action:@selector(pressCall:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:callButton];
    [callButton release];
    
    // sms button
    UIButton *smsButton = [[UIButton alloc] initWithFrame:rect2];
    [AppUtility configInfoButton:smsButton context:kAUInfoButtonTypeSMS];
    [smsButton addTarget:self action:@selector(pressSMS:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:smsButton];
    [smsButton release];
    
    if (self.contact) {
        // chat button
        UIButton *chatButton = [[UIButton alloc] initWithFrame:rect3];
        [AppUtility configInfoButton:chatButton context:kAUInfoButtonTypeChat];
        [chatButton addTarget:self action:@selector(pressChat:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:chatButton];
        [chatButton release];
    }
    else {
        // invite button
        UIButton *inviteButton = [[UIButton alloc] initWithFrame:rect3];
        [AppUtility configInfoButton:inviteButton context:kAUInfoButtonTypeChatInvite];
        [inviteButton addTarget:self action:@selector(pressInvite:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:inviteButton];
        [inviteButton release];
    }*/
    
    
    // listen for presence state change
    // - so we can update when it changes
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadContactInfo:) name:MP_CONTACTMANAGER_RELOAD_DATA_NOTIFICATION object:nil];
    
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
    
    //
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}






#pragma mark - Button

/*!
 @abstract start chat with friend
 */
- (void)pressChat:(id)sender {

    
    CDChat *chat = [CDChat chatWithCDContacts:[NSArray arrayWithObject:self.contact] groupID:nil shouldSave:YES];
    
    BOOL isLocked = [[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];
    
    // if hidden chat then ask for PIN unlock first
    if (isLocked && [chat.isHiddenChat boolValue] ) {
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
        [AppUtility pushNewChat:chat];
    }
    
    
}

/*!
 @abstract sms friend
 */
- (void)pressSMS:(id)sender {
    
    NSNumber *showWarning = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingEnablePaySMSWarning];
    
    if ([showWarning boolValue]) {
        NSString *warning = NSLocalizedString(@"Send SMS through phone carrier.", @"FriendInfo - alert: Warn users that this call will cost money");
        
        UIActionSheet *aSheet;
        
        aSheet	= [[UIActionSheet alloc]
                   initWithTitle:warning
                   delegate:self
                   cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel sms")
                   destructiveButtonTitle:nil
                   otherButtonTitles:NSLocalizedString(@"<proceed sms>", @"Proceed with sms"), 
                   NSLocalizedString(@"Disable Warning", @"Alert: Disable this warning"), nil
                   ];
        
        aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        aSheet.tag = SMS_WARNING_TAG;
        
        [aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
        [aSheet release];
    }
    else {
        [AppUtility sms:self.phoneProperty.value delegate:self];
    }

}

/*!
 @abstract call friend
 */
- (void)pressCall:(id)sender {

    NSNumber *showWarning = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingEnablePayCallWarning];
    
    if ([showWarning boolValue]) {
        NSString *warning = NSLocalizedString(@"Call through your phone carrier.", @"FriendInfo - alert: Warn users that this call will cost money");
        
        UIActionSheet *aSheet;
        
        aSheet	= [[UIActionSheet alloc]
                   initWithTitle:warning
                   delegate:self
                   cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel phone call")
                   destructiveButtonTitle:nil
                   otherButtonTitles:NSLocalizedString(@"<proceed call>", @"Proceed with call"), 
                   NSLocalizedString(@"Disable Warning", @"Alert: Disable this warning"), nil
                   ];
        
        aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        aSheet.tag = CALL_WARNING_TAG;
        
        [aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
        [aSheet release];
    }
    else {
        [AppUtility call:self.phoneProperty.value];
    }
    
}


/*!
 @abstract invite friend to M+
 */
- (void) composeInviteSMS {
    NSString *contentString = NSLocalizedString(@"<tell_friend_sms>", @"Tell Friend: SMS default text");
    
    // check if sms is available
    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *composer = [[MFMessageComposeViewController alloc] init];
        composer.messageComposeDelegate = self;
        composer.recipients = [NSArray arrayWithObject:self.phoneProperty.value];
        [composer setBody:contentString];
        
        // present with root container to allow rotation
        //
        [[AppUtility getAppDelegate].containerController presentModalViewController:composer animated:YES];
        [composer release]; // autorelease?
    }
    else {
        [AppUtility showAlert:kAUAlertTypeNoTelephonySMS];
        
    }
}

/*!
 @abstract invite friend to M+
 */
- (void) pressInvite:(id) sender {
    
    /* Deprecated - read string from downloadable text files
     
     NSError *error = nil;
     NSString *contentPath = [AppUtility pathForDownloadableContentWithFilename:kMPFileTellFriendSMS];
     
     NSStringEncoding enc;
     NSString *contentString = [NSString stringWithContentsOfFile:contentPath usedEncoding:&enc error:&error];
     
     if (error) {
     NSAssert1(0, @"Failed to read sms msg file with error '%@'.", [error localizedDescription]);
     }
     */
    
    
    NSNumber *showWarning = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingEnablePayInviteWarning];
    
    if ([showWarning boolValue]) {
        NSString *warning = NSLocalizedString(@"Send SMS invitation through phone carrier.", @"PhoneInfo - alert: Warn users that this call will cost money");
        
        UIActionSheet *aSheet;
        
        aSheet	= [[UIActionSheet alloc]
                   initWithTitle:warning
                   delegate:self
                   cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel invite")
                   destructiveButtonTitle:nil
                   otherButtonTitles:NSLocalizedString(@"<proceed invite>", @"Proceed with invite (sms)"),
                   NSLocalizedString(@"Disable Warning", @"Alert: Disable this warning"), nil
                   ];
        
        aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        aSheet.tag = INVITE_WARNING_TAG;
        
        [aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
        [aSheet release];
    }
    else {
        [self composeInviteSMS];
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
        
        if (actionSheet.tag == CALL_WARNING_TAG) {
            if ([actionButtonTitle isEqualToString:NSLocalizedString(@"<proceed call>",nil)]) {
                [AppUtility call:self.phoneProperty.value];
            }
            else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Disable Warning",nil)]) {
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingEnablePayCallWarning settingValue:[NSNumber numberWithBool:NO]];
            }
        }
        else if (actionSheet.tag == SMS_WARNING_TAG) {
            if ([actionButtonTitle isEqualToString:NSLocalizedString(@"<proceed sms>",nil)]) {
                [AppUtility sms:self.phoneProperty.value delegate:self];
            }
            else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Disable Warning",nil)]) {
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingEnablePaySMSWarning settingValue:[NSNumber numberWithBool:NO]];
            }
        }
        else if (actionSheet.tag == INVITE_WARNING_TAG) {
            if ([actionButtonTitle isEqualToString:NSLocalizedString(@"<proceed invite>",nil)]) {
                [self composeInviteSMS];
            }
            else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Disable Warning",nil)]) {
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingEnablePayInviteWarning settingValue:[NSNumber numberWithBool:NO]];
            }
        }
    }
    else {
        DDLogVerbose(@"PhoneInfo Cancel Actionsheet");
    }
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



#pragma mark - Handle Response

/*!
 @abstract process block response
 
 Successful case
 <Block>
 <cause>0</cause>
 </Block>
 
 Exception case
 <Block>
 <cause>602</cause>
 <text>invalid USERID!</text>
 </Block>
 
 */
- (void) handleBlock:(NSNotification *)notification {
    //[AppUtility stopActivityIndicator:self.navigationController];
    
    NSDictionary *responseD = [notification object];
    
    // go ahead and block user
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        NSManagedObjectID *blockUserObjectID = [self.contact objectID];
        
        // block user
        //
        dispatch_async([AppUtility getBackgroundMOCQueue], ^{
            
            CDContact *blockContact = (CDContact *)[[AppUtility cdGetManagedObjectContext] objectWithID:blockUserObjectID];
            
            [blockContact blockUser];
            [AppUtility cdSaveWithIDString:@"PBI: blocked users" quitOnFail:NO];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // update badge in case this was a new friend
                [MPContactManager updateFriendBadgeCount];
                
                // pop view
                //
                [self.navigationController popViewControllerAnimated:YES];
                
            });
        });
        
    }
    // ask to confirm
    else {
        
        NSString *alertTitle = NSLocalizedString(@"Block Friend", @"FriendInfo - alert title:");
        NSString *alertMessage = NSLocalizedString(@"Block failed. Try again later.", @"FriendInfo - alert: Inform of failure");
        [Utility showAlertViewWithTitle:alertTitle message:alertMessage];
        
    }
}




/*!
 @abstract Handle remove friend response
 
 if successful, unfriend this person
 
 // notification object
 //
 NSMutableDictionary *newD = [[NSMutableDictionary alloc] initWithDictionary:responseDictionary];
 [newD setValue:presenceArray forKey:@"array"];
 
 */
- (void) processGetUserInfo:(NSNotification *)notification {
    
    [AppUtility stopActivityIndicator];
    
    NSDictionary *responseD = [notification object];
    
    NSString *queryIDTag = [responseD valueForKey:kTTXMLIDTag];
    
    // if this is my response
    if ([queryIDTag isEqualToString:self.contact.userID]) {
        if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
            
            // un friend
            [self.contact unFriend];
            
            [MPContactManager updateFriendBadgeCount];
            [AppUtility cdSaveWithIDString:@"unfriend m+id friend" quitOnFail:NO];
            
            // pop this view away
            //
            [self.navigationController popViewControllerAnimated:YES];
            // in case this was a new friend, remove the new friend count!
            [MPContactManager updateFriendBadgeCount];
        }
        // must have failed
        else {
            
            NSString *alertTitle = NSLocalizedString(@"Delete Friend", @"FriendInfo - alert title:");
            NSString *alertMessage = NSLocalizedString(@"Delete friend failed. Try again later.", @"FriendInfo - alert: Inform of failure");
            [Utility showAlertViewWithTitle:alertTitle message:alertMessage];
            
        }
    }
    // not my response, then ignore it
}

#pragma mark - HiddenController

/*!
 @abstract Notifiy Delegate that unlock was successful
 - proceed to open hidden chat after unlocking
 */
- (void)HiddenController:(HiddenController *)controller unlockDidSucceed:(BOOL)didSucceed {
    
    CDChat *chat = [CDChat chatWithCDContacts:[NSArray arrayWithObject:self.contact] groupID:nil shouldSave:YES];    
    [AppUtility pushNewChat:chat];
    
}

@end

