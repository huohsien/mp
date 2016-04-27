//
//  MyProfileController.m
//  mp
//
//  Created by M Tsai on 11-11-23.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "MyProfileController.h"
#import "MPFoundation.h"
#import "CreateIDController.h"
#import "StatusMessageController.h"
#import "NameRegistrationController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "CDContact.h"
#import "TextEmoticonView.h"


@implementation MyProfileController

@synthesize pendingMessageID;
@synthesize tempSmallImage;
@synthesize tempLargeImage;
@synthesize imageManager;


- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [pendingMessageID release];
    [tempLargeImage release];
    [tempSmallImage release];
    [imageManager release];
    
    [super dealloc];
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


#define CREATEID_BTN_TAG    16000
#define MPID_LABEL_TAG      16001
#define MPID_DESCRIPTION_LABEL_TAG  16002
#define SEARCH_LABEL_TAG    16003
#define SEARCH_BTN_TAG      16004
#define NAME_BTN_TAG        16005
#define STATUS_BTN_TAG      16006
#define STATUS_LABEL_TAG    16007
#define CREATEID_HELP_BTN_TAG    16008


#define SEARCH_SWITCH_BTN_TAG   17000
#define HEADSHOT_BTN_TAG        17001
#define HEADSHOT_IMAGE_TAG      17002
#define PRESENCE_BTN_TAG        17003
#define PRESENCE_SWITCH_BTN_TAG 17004

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // title
    //
    self.title = NSLocalizedString(@"My Profile", @"MyProfile - title: view to change profile information");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];

    
    // background
    // 
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    UIScrollView *setupView = [[UIScrollView alloc] initWithFrame:appFrame];
    setupView.scrollEnabled = YES;
    setupView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = setupView;
    
    
    
    // default photo button
    //
    UIButton *headShotButton = [[UIButton alloc] initWithFrame:CGRectMake(4.0, 14.0, 100.0, 110.0)];
    [headShotButton setBackgroundImage:[UIImage imageNamed:@"profile_nophoto.png"] forState:UIControlStateNormal];
    [headShotButton addTarget:self action:@selector(pressHeadShot:) forControlEvents:UIControlEventTouchUpInside];
    headShotButton.tag = HEADSHOT_BTN_TAG;
    [self.view addSubview:headShotButton];
    
    // photo image view
    //
    UIImageView *headShotView = [[UIImageView alloc] initWithFrame:CGRectMake(7.0, 7.0, 85.0, 85.0)];
    headShotView.tag = HEADSHOT_IMAGE_TAG;
    [headShotButton addSubview:headShotView];
    [headShotView release];
    [headShotButton release];
    
    
    // phone description
    //
    UILabel *pdLabel = [[UILabel alloc] initWithFrame:CGRectMake(115.0, 16.0, 185.0, 14.0)];
    [AppUtility configLabel:pdLabel context:kAULabelTypeBackgroundText];
    pdLabel.text = NSLocalizedString(@"Phone Number", @"MyProfile - text: phone number of user");
    [self.view addSubview:pdLabel];
    [pdLabel release];
    
    
    // phone info
    //
    UILabel *pInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(115.0, 31.0, 185.0, 21.0)];
    [AppUtility configLabel:pInfoLabel context:kAULabelTypeBackgroundTextInfo];
    pInfoLabel.text = [NSString stringWithFormat:@"+%@ %@",
                    [[MPHTTPCenter sharedMPHTTPCenter] getCountryCode],
                    [[MPHTTPCenter sharedMPHTTPCenter] getPhoneNumber]];
    [self.view addSubview:pInfoLabel];
    [pInfoLabel release];
    
    
    // mpid description
    //
    UILabel *mdLabel = [[UILabel alloc] initWithFrame:CGRectMake(115.0, 66.0, 185.0, 14.0)];
    [AppUtility configLabel:mdLabel context:kAULabelTypeBackgroundText];
    mdLabel.text = NSLocalizedString(@"M+ ID", @"MyProfile - text: M+ID of user");
    mdLabel.hidden = YES;
    mdLabel.tag = MPID_DESCRIPTION_LABEL_TAG;
    [self.view addSubview:mdLabel];
    [mdLabel release];
    
    // mpid info
    //
    UILabel *mpidInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(115.0, 81.0, 185.0, 23.0)];
    [AppUtility configLabel:mpidInfoLabel context:kAULabelTypeBackgroundTextInfo];
    mpidInfoLabel.tag = MPID_LABEL_TAG;
    [self.view addSubview:mpidInfoLabel];
    [mpidInfoLabel release];
    
    
    // createID button
    //
    UIButton *createIDButton = [[UIButton alloc] initWithFrame:CGRectMake(115.0, 86.0, 140.0, 37.0)];
    [AppUtility configButton:createIDButton context:kAUButtonTypeOrange];
    [createIDButton addTarget:self action:@selector(pressCreateID:) forControlEvents:UIControlEventTouchUpInside];
    [createIDButton setTitle:NSLocalizedString(@"Create ID", @"MyProfile - Button: creates a new M+ ID") forState:UIControlStateNormal];
    createIDButton.tag = CREATEID_BTN_TAG;
    [self.view addSubview:createIDButton];
    [createIDButton release];    
    
    
    // createID Help button
    //
    UIButton *idHelpButton = [[UIButton alloc] initWithFrame:CGRectMake(255.0+10.0, 86.0, 37, 37.0)];
    [idHelpButton setBackgroundImage:[UIImage imageNamed:@"profile_createid_info_btn_nor.png"] forState:UIControlStateNormal];
    [idHelpButton setBackgroundImage:[UIImage imageNamed:@"profile_createid_info_btn_prs.png"] forState:UIControlStateHighlighted];
    idHelpButton.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    idHelpButton.opaque = YES;
    
    [idHelpButton addTarget:self action:@selector(pressCreateIDHelp:) forControlEvents:UIControlEventTouchUpInside];
    idHelpButton.tag = CREATEID_HELP_BTN_TAG;
    [self.view addSubview:idHelpButton];
    [idHelpButton release];    
    
    // name description
    //
    UILabel *ndLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 132.0, 150.0, 15.0)];
    [AppUtility configLabel:ndLabel context:kAULabelTypeBackgroundText];
    ndLabel.text = NSLocalizedString(@"Name", @"MyProfile - text: Name of user");
    [self.view addSubview:ndLabel];
    [ndLabel release];
    
    // name button
    //
    UIButton *nameButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, 150.0, 310.0, 45.0)];
    [AppUtility configButton:nameButton context:kAUButtonTypeTextBar];
    [nameButton addTarget:self action:@selector(pressName:) forControlEvents:UIControlEventTouchUpInside];
    nameButton.tag = NAME_BTN_TAG;
    [self.view addSubview:nameButton];
    [nameButton release];
    

    // status description
    //
    UILabel *sdLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 202.0, 150.0, 15.0)];
    [AppUtility configLabel:sdLabel context:kAULabelTypeBackgroundText];
    sdLabel.text = NSLocalizedString(@"Status Message", @"MyProfile - text: Status of user");
    [self.view addSubview:sdLabel];
    [sdLabel release];
    
    // status button
    //
    UIButton *statusButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, 220.0, 310.0, 45.0)];
    [AppUtility configButton:statusButton context:kAUButtonTypeTextBar];
    [statusButton addTarget:self action:@selector(pressStatus:) forControlEvents:UIControlEventTouchUpInside];
    statusButton.tag = STATUS_BTN_TAG;
    [self.view addSubview:statusButton];
    
    // create status text label - 3,41
    TextEmoticonView *statusLabel = [[TextEmoticonView alloc] initWithFrame:CGRectMake(10.0, 3.0, 280.0, 41.0)];
    statusLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandardPlus];
    statusLabel.numberOfLines = 1;
    statusLabel.lineBreakMode = UILineBreakModeTailTruncation;
    statusLabel.tag = STATUS_LABEL_TAG;
    [statusButton addSubview:statusLabel];
    [statusLabel release];
    [statusButton release];
    
    
    // presence button
    //
    NSString *presenceText = NSLocalizedString(@"Show My Presence", @"MyProfile - title: allow others to see my presence status");
    UIButton *presenceButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, 280.0, 310.0, 45.0)];
    [presenceButton setTitle:presenceText forState:UIControlStateNormal];
    [AppUtility configButton:presenceButton context:kAUButtonTypeTextBar];
    [presenceButton addTarget:self action:@selector(pressPresence:) forControlEvents:UIControlEventTouchUpInside];
    presenceButton.tag = PRESENCE_BTN_TAG;
    [self.view addSubview:presenceButton];
    
    // add switch to button
    //
    /*UIButton *presenceSwitchButton = [[UIButton alloc] initWithFrame:CGRectMake(221.0, 5.0, 80.0, 35.0)];
    [AppUtility configButton:presenceSwitchButton context:kAUButtonTypeSwitch];
    [presenceSwitchButton addTarget:self action:@selector(pressPresence:) forControlEvents:UIControlEventTouchUpInside];
    presenceSwitchButton.tag = PRESENCE_SWITCH_BTN_TAG;
    [presenceButton addSubview:presenceSwitchButton];
    [presenceButton release];
    [presenceSwitchButton release];*/
    UISwitch *presenceSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(207.0, 8.0, 80.0, 35.0)];
    // only for ios5.0 - switch size is also different
    if ([presenceSwitch respondsToSelector:@selector(onTintColor)]) {
        presenceSwitch.frame = CGRectMake(223.0, 8.0, 80.0, 35.0);
        presenceSwitch.onTintColor = [AppUtility colorForContext:kAUColorTypeGreen2];
    }
    [presenceSwitch addTarget:self action:@selector(pressPresence:) forControlEvents:UIControlEventValueChanged];
    presenceSwitch.tag = PRESENCE_SWITCH_BTN_TAG;
    [presenceButton addSubview:presenceSwitch];
    [presenceButton release];
    [presenceSwitch release];
    
    
    // presence description
    //
    UILabel *presenceLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 326.0, 295.0, 18.0)];
    [AppUtility configLabel:presenceLabel context:kAULabelTypeBackgroundTextHighlight];
    presenceLabel.text = NSLocalizedString(@"Allow others to see my online/offline status.", @"MyProfile - text: This button allows users to enable and disable others to view their current online presence status.");
    presenceLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:presenceLabel];
    [presenceLabel release];
    
    
    CGFloat shiftDown = 80.0;
    
    // search ID button
    //
    NSString *searchText = NSLocalizedString(@"Make M+ID Searchable", @"MyProfile - title: others can search your M+ ID to find you");
    UIButton *searchButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, 280.0+shiftDown, 310.0, 45.0)];
    [searchButton setTitle:searchText forState:UIControlStateNormal];
    [AppUtility configButton:searchButton context:kAUButtonTypeTextBar];
    [searchButton addTarget:self action:@selector(pressSearch:) forControlEvents:UIControlEventTouchUpInside];
    searchButton.hidden = YES;
    searchButton.tag = SEARCH_BTN_TAG;
    [self.view addSubview:searchButton];
    
    // add switch to button
    //
    /*UIButton *searchSwitchButton = [[UIButton alloc] initWithFrame:CGRectMake(221.0, 5.0, 80.0, 35.0)];
    [AppUtility configButton:searchSwitchButton context:kAUButtonTypeSwitch];
    [searchSwitchButton addTarget:self action:@selector(pressSearch:) forControlEvents:UIControlEventTouchUpInside];
    searchSwitchButton.tag = SEARCH_SWITCH_BTN_TAG;
    [searchButton addSubview:searchSwitchButton];
    [searchButton release];
    [searchSwitchButton release];*/

    UISwitch *searchSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(207.0, 8.0, 80.0, 35.0)];
    // only for ios5.0 - switch size is also different
    if ([searchSwitch respondsToSelector:@selector(onTintColor)]) {
        searchSwitch.frame = CGRectMake(223.0, 8.0, 80.0, 35.0);
        searchSwitch.onTintColor = [AppUtility colorForContext:kAUColorTypeGreen2];
    }
    [searchSwitch addTarget:self action:@selector(pressSearch:) forControlEvents:UIControlEventValueChanged];
    searchSwitch.tag = SEARCH_SWITCH_BTN_TAG;
    [searchButton addSubview:searchSwitch];
    [searchButton release];
    [searchSwitch release];
    
    
    // search description
    //
    CGRect sLabelFrame = CGRectMake(10.0, 326.0+shiftDown, 295.0, 18.0);
    UILabel *searchLabel = [[UILabel alloc] initWithFrame:sLabelFrame];
    [AppUtility configLabel:searchLabel context:kAULabelTypeBackgroundTextHighlight];
    searchLabel.text = NSLocalizedString(@"Allow others to search my M+ID.", @"MyProfile - text: Explain that search options allow users to control if other can search their IDs.");
    searchLabel.backgroundColor = [UIColor clearColor];
    searchLabel.hidden = YES;
    searchLabel.tag = SEARCH_LABEL_TAG;
    [self.view addSubview:searchLabel];
    [searchLabel release];
    
    setupView.contentSize=CGSizeMake(appFrame.size.width, sLabelFrame.origin.y+sLabelFrame.size.height+10.0);
    [setupView release];

    // listen for headshot update from PS server
    //
    //[[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processUpdateHeadshot:) name:MP_HTTPCENTER_UPDATE_HEADSHOT_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processSearch:) name:MP_HTTPCENTER_CLOSEID_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processPresence:) name:MP_HTTPCENTER_PRESENCEPERMISSION_NOTIFICATION object:nil];
    
    // if connection failure - for presence and search ID
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processConnectFailure:) name:MP_HTTPCENTER_CONNECT_FAILED_NOTIFICATION object:nil];
    
}


- (void)viewDidUnload
{
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated {
    
    DDLogInfo(@"MPC-vwa");

    
    if (!self.imageManager) {
        MPImageManager *imageM = [[MPImageManager alloc] init];
        imageM.delegate = self;
        self.imageManager = imageM;
        [imageM release];
    }
    
    // photo
    UIImage *gotImage = [self.imageManager getImageForObject:[CDContact mySelf] context:kMPImageContextList ignoreVersion:YES];
    if (gotImage) {
        UIImageView *imageView = (UIImageView *)[self.view viewWithTag:HEADSHOT_IMAGE_TAG];
        imageView.image = gotImage;
    }
    
    TextEmoticonView *statusLabel = (TextEmoticonView *)[self.view viewWithTag:STATUS_LABEL_TAG];    
    NSString *myStatus = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingStatus];
    NSString *oneLineStatus = [myStatus stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    [statusLabel setText:oneLineStatus];
    
    UIButton *nameButton = (UIButton *)[self.view viewWithTag:NAME_BTN_TAG];
    NSString *nickName = [[MPSettingCenter sharedMPSettingCenter] getNickName];
    [nameButton setTitle:nickName forState:UIControlStateNormal];
    
    UISwitch *permissionSwitch = (UISwitch *)[self.view viewWithTag:PRESENCE_SWITCH_BTN_TAG];
    NSNumber *isPermissionOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPresencePermission];
    if ([isPermissionOn boolValue] == YES) {
        [permissionSwitch setOn:YES];
    }
    else {
        [permissionSwitch setOn:NO];
    }
    
    
    NSString *mpID = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingMPID];

    // if mpID exists, hide button and update mpid value!
    if ([mpID length] > 2) {
        UIButton *createIDButton = (UIButton *)[self.view viewWithTag:CREATEID_BTN_TAG];
        createIDButton.hidden = YES;
        
        UIButton *idHelpButton = (UIButton *)[self.view viewWithTag:CREATEID_HELP_BTN_TAG];
        idHelpButton.hidden = YES;
        
        UILabel *mpIDInfoLabel = (UILabel *)[self.view viewWithTag:MPID_LABEL_TAG];
        mpIDInfoLabel.text = mpID;
        
        UILabel *mpIDDescriptoinLabel = (UILabel *)[self.view viewWithTag:MPID_DESCRIPTION_LABEL_TAG];
        mpIDDescriptoinLabel.hidden = NO;
        
        UIButton *searchButton = (UIButton *)[self.view viewWithTag:SEARCH_BTN_TAG];
        searchButton.hidden = NO;
        
        UILabel *searchLabel = (UILabel *)[self.view viewWithTag:SEARCH_LABEL_TAG];
        searchLabel.hidden = NO;
        
        UISwitch *switchButton = (UISwitch *)[self.view viewWithTag:SEARCH_SWITCH_BTN_TAG];
        NSNumber *isIDSearchable = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingMPIDSearch];
        if ([isIDSearchable boolValue] == YES) {
            [switchButton setOn:YES];
        }
        else {
            [switchButton setOn:NO];
        }
    }    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Button

/*!
 @abstract go create an ID
 */
- (void) pressCreateID:(id)sender {
    
    CreateIDController *nextController = [[CreateIDController alloc] init];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
    
}


/*!
 @abstract createID help information
 */
- (void) pressCreateIDHelp:(id)sender {
    
    NSString *title = NSLocalizedString(@"Create M+ ID", @"MyProfile-alert: Create ID Help Title");
    NSString *message = NSLocalizedString(@"M+ ID lets others add you as a friend without sharing your phone number.\n\nYou can also add friends by searching for their M+ ID.", @"MyProfile-alert: Create ID Help Message");
    
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"Close", @"MyProfile-alert option: close alert")
                                           otherButtonTitles:NSLocalizedString(@"Create ID", @"MyProfile-alert option: create ID"),nil] autorelease];
    [alert show];
}




/*!
 @abstract change status message
 */
- (void) pressStatus:(id)sender {
    
    StatusMessageController *nextController = [[StatusMessageController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
    
}
   
/*!
 @abstract change status message
 */
- (void) pressName:(id)sender {
    
    NameRegistrationController *nextController = [[NameRegistrationController alloc] initIsRegistration:NO];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
}

     
/*!
 @abstract change status message
  
 */
- (void) pressSearch:(id)sender {
    
    NSNumber *isIDSearchable = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingMPIDSearch];
    // request opposite of current state
    BOOL requestIDSearchable = ![isIDSearchable boolValue];
    
    // prevent switch for moving
    //UISwitch *searchableSwitch = (UISwitch *)[self.view viewWithTag:SEARCH_SWITCH_BTN_TAG];
    //[searchableSwitch setOn:[isIDSearchable boolValue] animated:NO];
    
    
    // start indicator
    [AppUtility startActivityIndicator];
    
    //[AppUtility startActivityIndicator];
    [[MPHTTPCenter sharedMPHTTPCenter] setSearchID:requestIDSearchable idTag:kMPHCRequestTypeCloseMPID];

}

/*!
 @abstract change presence permission
 
 */
- (void) pressPresence:(id)sender {
    
    NSNumber *isPermissionOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPresencePermission];
    
    // request opposite of current state
    BOOL requestPermissionOn = ![isPermissionOn boolValue];
    
    // prevent switch from moving
    //UISwitch *permissionSwitch = (UISwitch *)[self.view viewWithTag:PRESENCE_SWITCH_BTN_TAG];
    //[permissionSwitch setOn:[isPermissionOn boolValue] animated:NO];
    
    // start indicator
    [AppUtility startActivityIndicator];
    
    //[AppUtility startActivityIndicator];
    [[MPHTTPCenter sharedMPHTTPCenter] setPresencePermission:requestPermissionOn idTag:kMPHCRequestTypePresencePermission];
}



/*!
 @abstract allow users to select a new headshot
 */
- (void)pressHeadShot:(id)sender {
    
    
	UIActionSheet *aSheet = [[UIActionSheet alloc]
							 initWithTitle:@""
							 delegate:self
							 cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel headshot edit")
							 destructiveButtonTitle:nil
							 otherButtonTitles: NSLocalizedString(@"Take a Picture", @"Action label: take a new picture"), 
							 NSLocalizedString(@"Choose Existing", @"Action label: select an existing picture"),
							 nil];
	aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
	[aSheet release];

    

}

/**
 Respond to Action Sheet selection
 */
- (void)actionSheet:(UIActionSheet *)thisActionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // if not cancel
    if (buttonIndex != [thisActionSheet cancelButtonIndex]) {
		
        UIImagePickerController *imageController = [[UIImagePickerController alloc] init];
        imageController.allowsEditing = YES;

		NSString *actionButtonTitle = [thisActionSheet buttonTitleAtIndex:buttonIndex];
		if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Take a Picture", nil)]) {
            imageController.sourceType = UIImagePickerControllerSourceTypeCamera;
            if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
                imageController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
            }
		}
		else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Choose Existing", nil)]) {
            imageController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		}
        
        imageController.delegate = self;
        [self presentModalViewController:imageController animated:YES];
        [imageController release];
        
    }
    else {
        DDLogVerbose(@"Action select cancelled");
    }
}


#pragma mark - UIAlertViewDelegate Methods

/*!
 @abstract User confirms to send out letter without body
 */
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // confirm submit ID
	if (buttonIndex != [alertView cancelButtonIndex]) {
		[self pressCreateID:nil];
	}
}

#pragma mark - Image Picker Delegates


// For responding to the user tapping Cancel.
- (void) imagePickerControllerDidCancel: (UIImagePickerController *) picker {
    
    [self dismissModalViewControllerAnimated:YES];    

}


// For responding to the user accepting a newly-captured picture or movie
- (void) imagePickerController: (UIImagePickerController *) picker
 didFinishPickingMediaWithInfo: (NSDictionary *) info {
    
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    UIImage *originalImage, *editedImage, *imageToSave;
    
    // Handle a still image capture
    if (CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0)
        == kCFCompareEqualTo) {
        
        // default is 320x320 image
        //
        editedImage = (UIImage *) [info objectForKey:
                                   UIImagePickerControllerEditedImage];
        originalImage = (UIImage *) [info objectForKey:
                                     UIImagePickerControllerOriginalImage];
        CGSize eSize = editedImage.size;
        //CGSize oSize = originalImage.size;
        
        DDLogInfo(@"Image size: %f %f", eSize.width, eSize.height);
        if (editedImage) {
            imageToSave = editedImage;
        } else {
            imageToSave = originalImage;
        }
        
        // only save for camera images
        //
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            // save image to album automatically
            UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil);
        }

        
        // small preview image
        CGSize smallerSize = CGSizeMake(80.0, 80.0);
        UIImage *smallImage = [UIImage imageWithImage:imageToSave scaledToSize:smallerSize maintainScale:NO];
        
        // large detailed image
        CGSize largeSize = CGSizeMake(320.0, 320.0);
        UIImage *largeImage = [UIImage imageWithImage:imageToSave scaledToSize:largeSize maintainScale:NO];
        
        DDLogVerbose(@"MP: headshot %f %f - %f %f", smallImage.size.width, smallImage.scale, largeImage.size.width, largeImage.scale);
        
        
        // listen for message confirmations
        // - to delete group chats
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processConfirmations:) name:MP_MESSAGECENTER_SENT_CONFIRMATION_NOTIFICATION object:nil];
        
        // listen for socket write failures
        // - to delete group chats
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processWriteTimeouts:) name:MP_SOCKETCENTER_WRITE_TIMEOUT_NOTIFICATION object:nil];
        
        // if message timeout
        [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processMessageTimeout:) name:MP_MESSAGECENTER_SENT_TIMEOUT_NOTIFICATION object:nil];
        
        
        // first send a ping to reset idle connection timer
        // - so headshot has enough time to be sent out
        //
        [[AppUtility getSocketCenter] sendPing];
        
        // submit files to DS
        MPMessage *headShotMessage = [MPMessage messageHeadshotSmallImage:smallImage largeImage:largeImage];
        
        //[AppUtility startActivityIndicator];
        self.pendingMessageID = headShotMessage.mID;
        self.tempSmallImage = smallImage;
        self.tempLargeImage = largeImage;
        
        [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessageWithConfirmation:headShotMessage  enableAcceptRejectConfirmation:NO];
        NSUInteger totalSize = [[headShotMessage rawNetworkData] length];
        
        [AppUtility showProgressOverlayForMessageID:self.pendingMessageID totalSize:totalSize];
    }
}





#pragma mark - UpateHeadshot 


/*!
 @abstract process turn off id search 
 */
- (void) processSearch:(NSNotification *)notification {
    
    [AppUtility stopActivityIndicator];
    
    NSDictionary *responseD = [notification object];
    
    NSString *title = NSLocalizedString(@"Change M+ID Search", @"MyProfile - alert title:");
    
    NSString *detMessage = nil;
    
    NSNumber *isSearchOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingMPIDSearch];
    
    // ask to confirm
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        if ([isSearchOn boolValue]) {
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingMPIDSearch settingValue:[NSNumber numberWithBool:NO]];
        }
        else {
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingMPIDSearch settingValue:[NSNumber numberWithBool:YES]];
        }
        
    }
    // did not succeed
    else {
        detMessage = NSLocalizedString(@"Change M+ID search. Try again.", @"MyProfile - alert: inform of failure");
        [Utility showAlertViewWithTitle:title message:detMessage];

    }
    
    // set switch to current position
    UISwitch *switchButton = (UISwitch *)[self.view viewWithTag:SEARCH_SWITCH_BTN_TAG];
    isSearchOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingMPIDSearch];
    
    if ([isSearchOn boolValue]) {
        [switchButton setOn:YES animated:YES];
    }
    else {
        [switchButton setOn:NO animated:YES];
    }
    
    
}


/*!
 @abstract process turn on search id
 
- (void) processOpenID:(NSNotification *)notification {
    
    [AppUtility stopActivityIndicator];
    
    NSDictionary *responseD = [notification object];
    
    NSString *title = NSLocalizedString(@"Turn On M+ID Search", @"MyProfile - alert title:");
    
    NSString *detMessage = nil;
    
    // ask to confirm
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        UIButton *switchButton = (UIButton *)[self.view viewWithTag:SEARCH_SWITCH_BTN_TAG];
        
        [switchButton setSelected:YES];
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingMPIDSearch settingValue:[NSNumber numberWithBool:YES]];
        
    }
    // did not succeed
    else {
        detMessage = NSLocalizedString(@"Turn on M+ID search failed. Try again.", @"MyProfile - alert: inform of failure");
    }
    if (detMessage) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:title   
                                                         message:detMessage
                                                        delegate:nil 
                                               cancelButtonTitle:@"OK" 
                                               otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}*/



/*!
 @abstract process turn on search id
 
 */
- (void) processPresence:(NSNotification *)notification {
    
    [AppUtility stopActivityIndicator];
    
    NSDictionary *responseD = [notification object];
    
    NSString *title = NSLocalizedString(@"Change Presence", @"MyProfile - alert title:");
    
    NSString *detMessage = nil;
    
    NSNumber *isPermissionOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPresencePermission];

    // ask to confirm
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        // change value
        if ([isPermissionOn boolValue] == YES) {
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPresencePermission settingValue:[NSNumber numberWithBool:NO]];
        }
        else {
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPresencePermission settingValue:[NSNumber numberWithBool:YES]];
        }
        
    }
    // did not succeed
    else {
        detMessage = NSLocalizedString(@"Change presence failed. Try again.", @"MyProfile - alert: inform of failure");
        [Utility showAlertViewWithTitle:title message:detMessage];
    }

    // set switch to current value
    UISwitch *permissionSwitch = (UISwitch *)[self.view viewWithTag:PRESENCE_SWITCH_BTN_TAG];
    isPermissionOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPresencePermission];
    
    // change value
    if ([isPermissionOn boolValue] == YES) {
        [permissionSwitch setOn:YES animated:YES];
    }
    else {
        [permissionSwitch setOn:NO animated:YES];
    }
    
}



/*!
 @abstract handle connection failure and reset switch back to original values
 
 */
- (void) processConnectFailure:(NSNotification *)notification {
    
    [AppUtility stopActivityIndicator];
    
    NSDictionary *responseD = [notification object];
    
    NSString *queryType = [responseD valueForKey:kTTXMLTypeTag];
    
    // if search setting failed
    if ([queryType isEqualToString:kMPHCRequestTypeCloseMPID]) {
        
        // reset since failed
        UISwitch *switchButton = (UISwitch *)[self.view viewWithTag:SEARCH_SWITCH_BTN_TAG];
        NSNumber *isSearchOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingMPIDSearch];
        
        if ([isSearchOn boolValue]) {
            [switchButton setOn:YES animated:YES];
        }
        else {
            [switchButton setOn:NO animated:YES];
        }
        
    }
    else if ([queryType isEqualToString:kMPHCRequestTypePresencePermission]) {
        
        // reset since failed
        UISwitch *permissionSwitch = (UISwitch *)[self.view viewWithTag:PRESENCE_SWITCH_BTN_TAG];
        NSNumber *isPermissionOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPresencePermission];
        
        // change value
        if ([isPermissionOn boolValue] == YES) {
            [permissionSwitch setOn:YES animated:YES];
        }
        else {
            [permissionSwitch setOn:NO animated:YES];
        }
    }
}



/*!
 @abstract process udpate status results
 */
- (void) processUpdateStatus:(NSNotification *)notification {
    
    //[AppUtility stopActivityIndicator:self.navigationController];
    
    NSDictionary *responseD = [notification object];
    
    NSString *title = NSLocalizedString(@"Update Headshot", @"MyProfile - alert title:");
    
    NSString *detMessage = nil;
    
    // ask to confirm
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        // nothing to do here, carry on

    }
    // did not succeed
    else {
        detMessage = NSLocalizedString(@"Headshot update failed. Try again.", @"StatusMessage - alert: inform of failure");
    }
    if (detMessage) {
        
        [Utility showAlertViewWithTitle:title message:detMessage];

    }
}




/*!
 @abstract process incoming confirmations
 
 Headshot successfully uploaded, but still need to inform PS to increment headshot count
 
 */
- (void) processConfirmations:(NSNotification *)notification {
    
    NSString *messageID = [notification object];
    
    // DS got message, so set the images
    if ([messageID isEqualToString:self.pendingMessageID]) {

        // erase immediately so timeout will not find this mID laying around
        self.pendingMessageID = nil;

        
        // submit headshot update message - Not needed any more since DS message already updates the headshot serial number
        //[[MPHTTPCenter sharedMPHTTPCenter] updateHeadshotIsFromFaceBook:NO];
        
        
        /*
         DS already got headshot, so set it now
         - we don't really care if PS got the update, since it is consider best effort service
         
         The problem is that this is a two step process. But the first step already updates the image so
         if new users try downloading they will get the new image. Best solution is to have DS update 
         the PS headshot count, since it should be more reliable network wise.
         
         */
        NSString *userID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
        
        MPImageManager *imageM = [[MPImageManager alloc] init];
        
        // save small and large images
        // - version fixed at "1"
        //
        NSString *version = @"1"; 
        
        // increament headshot number locally
        CDContact *mySelf = [CDContact mySelf];
        NSInteger myHeadShotNumber = [mySelf.headshotSerialNumber intValue];
        version = [NSString stringWithFormat:@"%d", myHeadShotNumber + 1];
        mySelf.headshotSerialNumber = [NSNumber numberWithInt:myHeadShotNumber + 1];
        [AppUtility cdSaveWithIDString:@"Update my headshot number" quitOnFail:NO];
        
        [imageM setImage:self.tempSmallImage forFilename:userID context:kMPImageContextList version:version];
        [imageM setImage:self.tempLargeImage forFilename:userID context:nil version:version];
        [imageM release];
        
        self.tempSmallImage = nil;
        self.tempLargeImage = nil;
        
        //[AppUtility stopActivityIndicator];
        [AppUtility removeProgressOverlay];
        [self dismissModalViewControllerAnimated:YES]; 
    }
}

/*!
 @abstract process write socket failures
 
 Use:
 - can cancel pending image updates
 
 */
- (void) processMessageTimeout:(NSNotification *)notification {
    
    NSString *messageID = [notification object];
    
    // DS message send timed out, so cancel headshot upload
    //
    if ([messageID isEqualToString:self.pendingMessageID]) {
        
        DDLogVerbose(@"MY-pwt: headshot message timeout");
        
        self.pendingMessageID = nil;
        self.tempSmallImage = nil;
        self.tempLargeImage = nil;
        
        //[AppUtility stopActivityIndicator];
        [AppUtility removeProgressOverlay];
        [AppUtility showAlert:kAUAlertTypeNetwork];  
        
        [self dismissModalViewControllerAnimated:YES];  
    }
}


/*!
 @abstract process write socket failures
 
 Use:
 - can cancel pending image updates
 
 */
- (void) processWriteTimeouts:(NSNotification *)notification {
    
    NSNumber *longTagNumber = [notification object];
    NSString *tagString = [longTagNumber stringValue];
    
    // network failure
    if ([self.pendingMessageID hasSuffix:tagString]) {
        DDLogVerbose(@"MY-pwt: headshot net failure");
        
        self.pendingMessageID = nil;
        self.tempSmallImage = nil;
        self.tempLargeImage = nil;
        
        //[AppUtility stopActivityIndicator];
        [AppUtility removeProgressOverlay];
        [AppUtility showAlert:kAUAlertTypeNetwork];  
        
        [self dismissModalViewControllerAnimated:YES];    
    }
}



#pragma mark - Image - Headshot downloaded

/*!
 @abstract Called my head shot has finished downloading
 
 */
- (void)MPImageManager:(MPImageManager *)imageManager finishLoadingImage:(UIImage *)image{
    
    if (image) {
        UIImageView *imageView = (UIImageView *)[self.view viewWithTag:HEADSHOT_IMAGE_TAG];
        imageView.image = image;
    }
}

         



@end
