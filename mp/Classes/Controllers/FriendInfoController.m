//
//  FriendInfoController.m
//  mp
//
//  Created by M Tsai on 11-12-3.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "FriendInfoController.h"
#import "MPFoundation.h"
#import "CDContact.h"
#import "CDChat.h"
#import "MPFoundation.h"
#import "MPContactManager.h"
#import "TextEmoticonView.h"
#import "HeadShotDisplayView.h"
#import "TKImageLabel.h"
#import "OperatorInfoCenter.h"


@implementation FriendInfoController

@synthesize contact;
@synthesize operatorNumber;


- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [operatorNumber release];
    [contact release];
    [super dealloc];
}
- (id)initWithContact:(CDContact *)newContact
{
	self = [super init];
	if (self != nil)
	{
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

#pragma mark - Operator

/*!
 @abstract getter for operator number
 
 - if not exists, then request for it
 
 */
- (NSNumber *) operatorNumber {
    
    if (operatorNumber) {
        return operatorNumber;
    }
    
    // request operator information
    //
    operatorNumber = [[OperatorInfoCenter sharedOperatorInfoCenter] requestOperatorForPhoneNumber:self.contact.registeredPhone];
    
    if (operatorNumber) {
        [operatorNumber retain];
    }
    // if no local cache, listen for remote query results
    else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processOperatorInfo:) name:MP_OPERATORINFO_UPDATE_SINGLE_NOTIFICATION object:nil];
    }
    return operatorNumber;
}


#define PHOTO_IMG_TAG       18001
#define OPERATOR_VIEW_TAG   18002
#define STATUS_LABEL_TAG    18004
#define PRESENCE_LABEL_TAG  18005
#define PHONE_LABEL_TAG     18006
#define SMS_BTN_TAG         18007

#define SMS_WARNING_TAG     18008
#define CALL_WARNING_TAG    18009


/*!
 @abstract process operator information that was requested
 */
- (void) processOperatorInfo:(NSNotification *) notification {
    
    NSDictionary *operatorDictionary = [notification object];
    
    NSNumber *resultNumber = [operatorDictionary valueForKey:self.contact.registeredPhone];
    
    // if got results then set operatorNumber and remove observer
    if (resultNumber) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [resultNumber retain];
        [operatorNumber release];
        operatorNumber = resultNumber;
        
        // update the operator badge
        //
        UIButton *operatorButton = (UIButton *)[self.view viewWithTag:OPERATOR_VIEW_TAG];
        
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
        
        // Phone Number
        //
        UILabel *phoneLabel = (UILabel *)[self.view viewWithTag:PHONE_LABEL_TAG];
        CGRect phoneFrame = phoneLabel.frame;
        phoneFrame.origin.x = 108.0 + tWidth + 1.0;
        phoneLabel.frame = phoneFrame;
    }
    // otherwise, this notif was not for me - ignore it
}



#pragma mark - View lifecycle


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



/*!
 @abstract Request phone number string from contact manager and updates UI with data
 
 */
- (void) getAddressBookPhoneString {
    
    dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
    
    dispatch_async(back_queue, ^{
        
        NSString *rawPhoneString = [[AppUtility getBackgroundContactManager] getMatchingPhoneString:self.contact.registeredPhone abRecordID:self.contact.abRecordID];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UILabel* phoneLabel = (UILabel *)[self.view viewWithTag:PHONE_LABEL_TAG];
            phoneLabel.text = rawPhoneString;
            
            UIButton* smsButton = (UIButton *)[self.view viewWithTag:SMS_BTN_TAG];
            
            if ([Utility isTWFixedLinePhoneNumber:rawPhoneString]) {
                smsButton.enabled = NO;
            }
            else {
                smsButton.enabled = YES;
            }
            
        });
    });
}


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{

    //CGRect appFrame = [Utility appFrame];

    // title
    //
    self.title = NSLocalizedString(@"Info", @"FriendInfo - title: detailed info about friend");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];

    // background
    //
    UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    backView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    backView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = backView;
    [backView release];            
    
    
    // photo view
    //
    UIImageView *headShotView = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, 15.0, 98.0, 98.0)];
    headShotView.userInteractionEnabled = YES;
    headShotView.image = [UIImage imageNamed:@"profile_headshot_bear3.png"];
    [self.view addSubview:headShotView];
    
    // actual image
    //
    UIButton *photoView = [[UIButton alloc] initWithFrame:CGRectMake(6.5, 5.5, 85.0, 85.0)];
    photoView.imageView.contentMode = UIViewContentModeScaleAspectFill;
    photoView.backgroundColor = [UIColor clearColor];
    //photoView.alpha = 0.5;
    [photoView addTarget:self action:@selector(pressHeadShot:) forControlEvents:UIControlEventTouchUpInside];
    photoView.tag = PHOTO_IMG_TAG;
    [headShotView addSubview:photoView];
    
    MPImageManager *imageM = [[MPImageManager alloc] init];
    UIImage *gotImage = [imageM getImageForObject:self.contact context:kMPImageContextList];
	if (gotImage) {
        [photoView setBackgroundImage:gotImage forState:UIControlStateNormal];
        //[photoView setImage:gotImage forState:UIControlStateNormal];
        //photoView.image = gotImage;
    }
    [imageM release];
    
    [photoView release];
    [headShotView release];
    
    
    // name
    //
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(115.0, kNameYStart, 190.0, 19.0)];
    [AppUtility configLabel:nameLabel context:kAULabelTypeBlackStandardPlus];
    nameLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    nameLabel.text = [self.contact displayName];
    [self.view addSubview:nameLabel];
    [nameLabel release];

    CGFloat operatorHeight = 5.0;
    
    // show phone number info if in address book
    if ([self.contact isInAddressBook] && [self.contact.registeredPhone length] > 2) {
        operatorHeight = 28.0;
        
        UIButton *operatorButton = [[UIButton alloc] initWithFrame:CGRectMake(108.0, kNameYStart+18.0, 47.0, operatorHeight)];
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
        operatorButton.tag = OPERATOR_VIEW_TAG;
        [self.view addSubview:operatorButton];
        [operatorButton release];  
        
        
        //NSString *cc = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPhoneCountryCode];
        //NSString *phoneString = [Utility formatPhoneNumber:self.contact.registeredPhone countryCode:cc showCountryCode:NO];
        
        // Phone Number
        //
        UILabel *phoneLabel = [[UILabel alloc] initWithFrame:CGRectMake(108.0 + tWidth + 1.0, kNameYStart+26.0, 140.0, 15.0)];
        [AppUtility configLabel:phoneLabel context:kAULabelTypeGrayMicroPlus];
        phoneLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
        //phoneLabel.text =  phoneString;
        phoneLabel.tag = PHONE_LABEL_TAG;
        [self.view addSubview:phoneLabel];
        [phoneLabel release];
        
        [self getAddressBookPhoneString];
    }

    
    // status
    //
    TextEmoticonView *statusLabel = [[TextEmoticonView alloc] initWithFrame:CGRectMake(115.0, kNameYStart+operatorHeight+16.0, 190.0, 50.0)];
    [AppUtility configLabel:(UILabel *)statusLabel context:kAULabelTypeGrayMicroPlus];
    //statusLabel.lineBreakMode = UILineBreakModeTailTruncation;
    statusLabel.numberOfLines = 3;
    statusLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    statusLabel.tag = STATUS_LABEL_TAG;
    [self.view addSubview:statusLabel];
    [statusLabel release];
    
    
    // last seen
    //
    UILabel *lastLabel = [[UILabel alloc] initWithFrame:CGRectMake(115.0, kNameYStart + operatorHeight + 69.0, 120.0, 12.0)];
    [AppUtility configLabel:lastLabel context:kAULabelTypeLightGrayNanoPlus];
    lastLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    lastLabel.tag = PRESENCE_LABEL_TAG;
    [self.view addSubview:lastLabel];
    [lastLabel release];
    
    [self loadContactInfo];
    
    
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
    
    // block button
    UIButton *blockButton = [[UIButton alloc] initWithFrame:rect3];
    [blockButton setBackgroundImage:[UIImage imageNamed:@"info_btn_block_nor.png"] forState:UIControlStateNormal];
    [blockButton setBackgroundImage:[UIImage imageNamed:@"info_btn_block_prs.png"] forState:UIControlStateHighlighted];
    blockButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
    blockButton.titleLabel.textColor = [UIColor whiteColor];
    blockButton.contentEdgeInsets = buttonInsets;
    [blockButton setTitle:NSLocalizedString(@"Block", @"FriendInfo- button: block friend") forState:UIControlStateNormal];
    [blockButton addTarget:self action:@selector(pressBlock:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:blockButton];
    
    // show call and sms options - if phonebook contact and has phone number
    if ([self.contact isInAddressBook] && [self.contact.registeredPhone length] > 2) {
        
        
        // sms button
        UIButton *smsButton = [[UIButton alloc] initWithFrame:rect2];
        [smsButton setBackgroundImage:[UIImage imageNamed:@"info_btn_paysms_nor.png"] forState:UIControlStateNormal];
        [smsButton setBackgroundImage:[UIImage imageNamed:@"info_btn_paysms_prs.png"] forState:UIControlStateHighlighted];
        smsButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
        smsButton.titleLabel.textColor = [UIColor whiteColor];
        smsButton.contentEdgeInsets = buttonInsets;
        [smsButton setTitle:NSLocalizedString(@"SMS", @"FriendInfo- button: text friend") forState:UIControlStateNormal];
        [smsButton addTarget:self action:@selector(pressSMS:) forControlEvents:UIControlEventTouchUpInside];
        smsButton.tag = SMS_BTN_TAG;
        [self.view addSubview:smsButton];
        [smsButton release];
        
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
        
        
    }
    else {
        
        // blank disabled button
        UIButton *blankButton = [[UIButton alloc] initWithFrame:rect2];
        [blankButton setBackgroundImage:[UIImage imageNamed:@"info_btn_dis.png"] forState:UIControlStateDisabled];
        blankButton.enabled = NO;
        [self.view addSubview:blankButton];
        [blankButton release];
        
        // delete button
        UIButton *deleteButton = [[UIButton alloc] initWithFrame:rect1];
        [deleteButton setBackgroundImage:[UIImage imageNamed:@"info_btn_del_nor.png"] forState:UIControlStateNormal];
        [deleteButton setBackgroundImage:[UIImage imageNamed:@"info_btn_del_prs.png"] forState:UIControlStateHighlighted];
        deleteButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontBoldStandard];
        deleteButton.titleLabel.textColor = [UIColor whiteColor];
        deleteButton.contentEdgeInsets = buttonInsets;
        [deleteButton setTitle:NSLocalizedString(@"Delete", @"FriendInfo- button: delete ID friend") forState:UIControlStateNormal];
        [deleteButton addTarget:self action:@selector(pressDelete:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:deleteButton];
        [deleteButton release];
        
    }
    [blockButton release];
    
    /* horzontal buttons 
    CGRect rect1 = CGRectMake(5.0, 121.0, 310.0, 50.0);
    CGRect rect2 = CGRectMake(5.0, 176.0, 310.0, 50.0);
    CGRect rect3 = CGRectMake(5.0, 231.0, 310.0, 50.0);
    CGRect rect4 = CGRectMake(5.0, 286.0, 310.0, 50.0);

    // chat button
    UIButton *chatButton = [[UIButton alloc] initWithFrame:rect1];
    [AppUtility configInfoButton:chatButton context:kAUInfoButtonTypeChat];
    [chatButton addTarget:self action:@selector(pressChat:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:chatButton];
    [chatButton release];
    
    // block button
    UIButton *blockButton = [[UIButton alloc] init];
    [AppUtility configInfoButton:blockButton context:kAUInfoButtonTypeBlock];
    [blockButton addTarget:self action:@selector(pressBlock:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:blockButton];

    // show call and sms options - if phonebook contact and has phone number
    if ([self.contact isSyncedFromPhoneBook] && [self.contact.registeredPhone length] > 2) {
        
        // sms button
        UIButton *smsButton = [[UIButton alloc] initWithFrame:rect2];
        [AppUtility configInfoButton:smsButton context:kAUInfoButtonTypeSMS];
        [smsButton addTarget:self action:@selector(pressSMS:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:smsButton];
        [smsButton release];
        
        // sms button
        UIButton *callButton = [[UIButton alloc] initWithFrame:rect3];
        [AppUtility configInfoButton:callButton context:kAUInfoButtonTypeCall];
        [callButton addTarget:self action:@selector(pressCall:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:callButton];
        [callButton release];
        
        blockButton.frame = rect4;
        
    }
    else {
        blockButton.frame = rect2;
        
        // delete button
        UIButton *deleteButton = [[UIButton alloc] initWithFrame:rect3];
        [AppUtility configInfoButton:deleteButton context:kAUInfoButtonTypeDelete];
        [deleteButton addTarget:self action:@selector(pressDelete:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:deleteButton];
        [deleteButton release];
        
    }
    [blockButton release];
    */
    
    // observe block events
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(handleBlock:) name:MP_HTTPCENTER_BLOCK_NOTIFICATION object:nil];
    
    // delete response
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processGetUserInfo:) name:MP_HTTPCENTER_GETUSERINFO_NOTIFICATION object:nil];

    // listen for presence state change
    // - so we can update when it changes
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadContactInfo:) name:MP_CONTACTMANAGER_RELOAD_DATA_NOTIFICATION object:nil];
    
}

- (void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    DDLogInfo(@"FI-vwa");
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
    DDLogInfo(@"FI-unload");
    
    
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
 @abstract Pressed HeadShot
 */
- (void)pressHeadShot:(id)sender {
    
    NSString *url = [self.contact imageURLForContext:nil ignoreVersion:NO];
    
    // only show if there is a file to download
    if (url) {
        CGRect appFrame = [Utility appFrame];
            
        HeadShotDisplayView *headShotView = [[HeadShotDisplayView alloc] initWithFrame:appFrame contact:self.contact];
        UIViewController *containerVC = [[AppUtility getAppDelegate] containerController];
        [containerVC.view addSubview:headShotView];
        [headShotView release];
    }
}



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
                   otherButtonTitles:NSLocalizedString(@"<proceed sms>", @"Proceed to compose sms"), 
                   NSLocalizedString(@"Disable Warning", @"Alert: Disable this warning"), nil
                   ];
        
        aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        aSheet.tag = SMS_WARNING_TAG;
        
        [aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
        [aSheet release];
    }
    else {
        [self.contact smsRegisteredPhone];
    }
    
}

/*!
 @abstract cell friend
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
        [self.contact callRegisteredPhone];
    }
}



/*!
 @abstract delete friend
 
 - Request remove for this friend
 - if success then unfriend this contact 
 - leave contact since it may be referenced by chat history
 
 */
- (void)pressDelete:(id)sender {
    
    UIActionSheet *aSheet;
	
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Delete %@", @"Settings - Alert: confirm account deletion!"), [self.contact displayName]];
    
	aSheet	= [[UIActionSheet alloc]
               initWithTitle:title
               delegate:self
               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel contact group action")
               destructiveButtonTitle:NSLocalizedString(@"Delete", @"Alert: Delete button")
               otherButtonTitles:nil];
	
	aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	
	[aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
	[aSheet release];
    
}


/*!
 @abstract block friend
 
 - (void)pressBlock:(id)sender {
 
 }*/
- (void) pressBlock:(id)sender {
    
    UIActionSheet *aSheet;
	
	aSheet	= [[UIActionSheet alloc]
               initWithTitle:nil
               delegate:self
               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel actionsheet")
               destructiveButtonTitle:NSLocalizedString(@"Block", @"Alert: block button")
               otherButtonTitles:nil];
	
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
        
        if (actionSheet.tag == CALL_WARNING_TAG) {
            if ([actionButtonTitle isEqualToString:NSLocalizedString(@"<proceed call>",nil)]) {
                [self.contact callRegisteredPhone];	
            }
            else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Disable Warning",nil)]) {
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingEnablePayCallWarning settingValue:[NSNumber numberWithBool:NO]];
            }
        }
        else if (actionSheet.tag == SMS_WARNING_TAG) {
            if ([actionButtonTitle isEqualToString:NSLocalizedString(@"<proceed sms>",nil)]) {
                [self.contact smsRegisteredPhone];
            }
            else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Disable Warning",nil)]) {
                [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingEnablePaySMSWarning settingValue:[NSNumber numberWithBool:NO]];
            }
        }
        else {
            if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Delete",nil)]) {
                
                // send and wait for response
                //
                [AppUtility startActivityIndicator];
                [[MPHTTPCenter sharedMPHTTPCenter] getUserInformation:[NSArray arrayWithObject:self.contact.userID] action:kMPHCQueryTagRemove idTag:self.contact.userID itemType:kMPHCItemTypeUserID];		
            }
            else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Block", nil)]) {
                
                [AppUtility startActivityIndicator];
                [[MPHTTPCenter sharedMPHTTPCenter] blockUser:self.contact.userID];
            }
        }
    }
    else {
        DDLogVerbose(@"FriendInfo Cancel Actionsheet");
    }
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
    [AppUtility stopActivityIndicator];
    
    NSDictionary *responseD = [notification object];
        
    // go ahead and block user
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        NSManagedObjectID *blockUserObjectID = [self.contact objectID];
        
        // block user
        //
        dispatch_async([AppUtility getBackgroundMOCQueue], ^{
        
            CDContact *blockContact = (CDContact *)[[AppUtility cdGetManagedObjectContext] objectWithID:blockUserObjectID];
            
            [blockContact blockUser];
            [AppUtility cdSaveWithIDString:@"FI: blocked users" quitOnFail:NO];
            
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
            // - CM performs so that badge count is also accurate
            [MPContactManager unFriend:self.contact.userID updateBadgeCount:YES];

            // pop this view away
            //
            [self.navigationController popViewControllerAnimated:YES];
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
