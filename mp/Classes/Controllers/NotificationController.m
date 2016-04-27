//
//  NotificationController.m
//  mp
//
//  Created by Min Tsai on 2/22/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "NotificationController.h"

#import "MPFoundation.h"
#import "SettingButton.h"

@implementation NotificationController

@synthesize isGroup;
@synthesize pendingTone;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

#define kStartX             5.0
#define kStartY             10.0

#define kButtonHeightShift  55.0
#define kButtonHeight       45.0
#define kLabelHeightShift   18.0

#define ALERT_BTN_TAG       17001
#define TONE_BTN_TAG        17002
#define PREVIEW_BTN_TAG     17003
#define PREVIEW_LABEL_TAG   17004

#define POPUP_BTN_TAG           17005
#define INAPP_VIBRATION_BTN_TAG 17006
#define INAPP_SOUND_BTN_TAG     17007


- (id)initIsGroupNotification:(BOOL)isGroupNotification
{
	self = [super init];
	if (self != nil)
	{
        self.isGroup = isGroupNotification;
	}
	return self;
}


/*!
 @abstract Reset to switches to actual values
 */
- (void)resetSettingDisplayValuesAnimated:(BOOL)animated {
    NSNumber *isOn = nil;
    
    SettingButton *alertButton = (SettingButton *)[self.view viewWithTag:ALERT_BTN_TAG];
    isOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:self.isGroup?kMPSettingPushGroupAlertIsOn:kMPSettingPushP2PAlertIsOn];
    [alertButton setValueBOOL:[isOn boolValue] animated:animated];
    
    SettingButton *toneButton = (SettingButton *)[self.view viewWithTag:TONE_BTN_TAG];
    NSString *toneValue = [[MPSettingCenter sharedMPSettingCenter] valueForID:self.isGroup?kMPSettingPushGroupRingTone:kMPSettingPushP2PRingTone];
    [toneButton setValueText:[ToneController nameForToneFilename:toneValue]];
    
    SettingButton *popButton = (SettingButton *)[self.view viewWithTag:POPUP_BTN_TAG];
    isOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPushPopUpIsOn];
    [popButton setValueBOOL:[isOn boolValue] animated:animated];
    
    SettingButton *previewButton = (SettingButton *)[self.view viewWithTag:PREVIEW_BTN_TAG];
    isOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:self.isGroup?kMPSettingPushGroupPreviewIsOn:kMPSettingPushP2PPreviewIsOn];
    [previewButton setValueBOOL:[isOn boolValue] animated:animated];
    
    SettingButton *inVibButton = (SettingButton *)[self.view viewWithTag:INAPP_VIBRATION_BTN_TAG];
    isOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:self.isGroup?kMPSettingPushGroupInAppIsVibrateOn:kMPSettingPushP2PInAppIsVibrateOn];
    [inVibButton setValueBOOL:[isOn boolValue] animated:animated];
    
    SettingButton *inSoundButton = (SettingButton *)[self.view viewWithTag:INAPP_SOUND_BTN_TAG];
    isOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:self.isGroup?kMPSettingPushGroupInAppIsSoundOn:kMPSettingPushP2PInAppIsSoundOn];
    [inSoundButton setValueBOOL:[isOn boolValue] animated:animated];
    
}


/*!
 @abstract Shows or Hide sub buttons depending on state of alert setting
 
 Use:
 - Make sure you sent the alert setting first and run this to show the buttons properly
 */
- (void)showOrHideSubButtonsAnimated:(BOOL)animated {

    // should we show other buttons?
    BOOL isAlertOn = [[[MPSettingCenter sharedMPSettingCenter] valueForID:self.isGroup?kMPSettingPushGroupAlertIsOn:kMPSettingPushP2PAlertIsOn] boolValue];
    BOOL shouldHideSubButtons = !isAlertOn;
    
    
    SettingButton *toneButton = (SettingButton *)[self.view viewWithTag:TONE_BTN_TAG];
    SettingButton *popButton = (SettingButton *)[self.view viewWithTag:POPUP_BTN_TAG];
    SettingButton *previewButton = (SettingButton *)[self.view viewWithTag:PREVIEW_BTN_TAG];
    UILabel *previewLabel = (UILabel *)[self.view viewWithTag:PREVIEW_LABEL_TAG];
    SettingButton *inVibButton = (SettingButton *)[self.view viewWithTag:INAPP_VIBRATION_BTN_TAG];
    SettingButton *inSoundButton = (SettingButton *)[self.view viewWithTag:INAPP_SOUND_BTN_TAG];

    // for showing
    CGFloat startAlpha = 0.0;
    CGFloat endAlpha = 1.0;
    
    if (shouldHideSubButtons) {
        startAlpha = 1.0;
        endAlpha = 0.0;
    }
    
    if (animated) {
        
        toneButton.alpha = startAlpha;
        popButton.alpha = startAlpha;
        previewButton.alpha = startAlpha;
        previewLabel.alpha = startAlpha;
        inVibButton.alpha = startAlpha;
        inSoundButton.alpha = startAlpha;
        
        [UIView animateWithDuration:kMPParamAnimationStdDuration 
                         animations:^{
                             toneButton.alpha = endAlpha;
                             popButton.alpha = endAlpha;
                             previewButton.alpha = endAlpha;
                             previewLabel.alpha = endAlpha;
                             inVibButton.alpha = endAlpha;
                             inSoundButton.alpha = endAlpha;
                         } 
                         completion:^(BOOL finished) {
                             if (finished) {
                                 
                             }
                         }];
    }
    else {
        toneButton.alpha = endAlpha;
        popButton.alpha = endAlpha;
        previewButton.alpha = endAlpha;
        previewLabel.alpha = endAlpha;
        inVibButton.alpha = endAlpha;
        inSoundButton.alpha = endAlpha;
    }
}

#pragma mark - ViewController



// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    // title
    //
    if (self.isGroup) {
        self.title = NSLocalizedString(@"Group Notification", @"Notif - title: group notification settings");
    }
    else {
        self.title = NSLocalizedString(@"Message Notification", @"Notif - title: p2p notification settings");
    }
    
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    
    // background
    //
    UIScrollView *setupView = [[UIScrollView alloc] initWithFrame:appFrame];
    setupView.scrollEnabled = YES;
    setupView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = setupView;
    

    
    // Alert ON button
    //
    CGFloat viewStartY = kStartY;
    SettingButton *alertButton = [[SettingButton alloc] initWithOrigin:CGPointMake(kStartX, viewStartY) 
                                                            buttonType:kSBButtonTypeSingle 
                                                                target:self 
                                                              selector:@selector(pressAlert:) 
                                                                 title:NSLocalizedString(@"Alerts", @"Notif - button: turn notification alert on") 
                                                             showArrow:NO];
    alertButton.tag = ALERT_BTN_TAG;
    [self.view addSubview:alertButton];
    [alertButton release];

    

    // tone button
    //
    viewStartY += kButtonHeightShift;
    SettingButton *toneButton = [[SettingButton alloc] initWithOrigin:CGPointMake(kStartX, viewStartY)
                                                           buttonType:kSBButtonTypeTop
                                                               target:self
                                                             selector:@selector(pressTone:)
                                                                title:NSLocalizedString(@"Tone", @"Notif - button: sound to play during alert")
                                                            showArrow:YES];
    toneButton.tag = TONE_BTN_TAG;
    [self.view addSubview:toneButton];
    [toneButton release];
    

    
    
    // preview button
    //
    viewStartY += kButtonHeight;
    SettingButton *previewButton = [[SettingButton alloc] initWithOrigin:CGPointMake(kStartX, viewStartY) 
                                                           buttonType:kSBButtonTypeBottom
                                                               target:self 
                                                             selector:@selector(pressPreview:) 
                                                                title:NSLocalizedString(@"Message Preview", @"Notif - button: should show message preview") 
                                                            showArrow:YES];
    previewButton.tag = PREVIEW_BTN_TAG;
    [self.view addSubview:previewButton];
    [previewButton release];
    
    
    // preview description
    //
    viewStartY += kButtonHeight+2.0;
    UILabel *previewLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, viewStartY, 295.0, kLabelHeightShift)];
    [AppUtility configLabel:previewLabel context:kAULabelTypeBackgroundTextHighlight];
    previewLabel.text = NSLocalizedString(@"Show message preview text for push notifications.", @"Notif - text: Explains that Message Preview enables preview text for push notifications.");
    previewLabel.backgroundColor = [UIColor clearColor];
    previewLabel.tag = PREVIEW_LABEL_TAG;
    [self.view addSubview:previewLabel];
    [previewLabel release];
    

    
    // in-app sound button
    //
    viewStartY += kLabelHeightShift+12.0;
    SettingButton *inAppSoundButton = [[SettingButton alloc] initWithOrigin:CGPointMake(kStartX, viewStartY) 
                                                                 buttonType:kSBButtonTypeTop
                                                                     target:self 
                                                                   selector:@selector(pressInAppSound:) 
                                                                      title:NSLocalizedString(@"In-App Sound", @"Notif - button: play sound if new msg arrives") 
                                                                  showArrow:YES];
    inAppSoundButton.tag = INAPP_SOUND_BTN_TAG;
    [self.view addSubview:inAppSoundButton];
    [inAppSoundButton release];
    
    // in-app vibration button
    //
    viewStartY += kButtonHeight;
    SettingButton *inAppVibButton = [[SettingButton alloc] initWithOrigin:CGPointMake(kStartX, viewStartY) 
                                                               buttonType:kSBButtonTypeBottom
                                                                   target:self 
                                                                 selector:@selector(pressInAppVibration:) 
                                                                    title:NSLocalizedString(@"In-App Vibration", @"Notif - button: vibration in-app if new msg arrives") 
                                                                showArrow:YES];
    inAppVibButton.tag = INAPP_VIBRATION_BTN_TAG;
    [self.view addSubview:inAppVibButton];
    [inAppVibButton release];
    
    [self showOrHideSubButtonsAnimated:NO];
    
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







- (void)viewWillAppear:(BOOL)animated
{
    DDLogInfo(@"NC-vwa");
    [super viewWillAppear:animated];
    
    [self resetSettingDisplayValuesAnimated:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processAlert:) name:MP_HTTPCENTER_SET_PUSH_NOTIFY_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processTone:) name:MP_HTTPCENTER_SET_PUSH_RINGTONE_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processPreview:) name:MP_HTTPCENTER_SET_PN_PREVIEW_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processPop:) name:MP_APPDELEGATE_REGISTER_PUSH_NOTIFICATION object:nil];
    
    // if connection failure - for presence and search ID
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processConnectFailure:) name:MP_HTTPCENTER_CONNECT_FAILED_NOTIFICATION object:nil];
    
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Button



/*!
 @abstract Alert switch 
 */
- (void) pressAlert:(id) sender {
    
    NSNumber *isAlertOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:self.isGroup?kMPSettingPushGroupAlertIsOn:kMPSettingPushP2PAlertIsOn];
    
    // request opposite of current state
    BOOL newValue = ![isAlertOn boolValue];
    
    // move switch to desired position
    SettingButton *alertButton = (SettingButton *)[self.view viewWithTag:ALERT_BTN_TAG];
    [alertButton setValueBOOL:newValue animated:YES];
        
    [AppUtility startActivityIndicator];
    [[MPHTTPCenter sharedMPHTTPCenter] setPushNotify:newValue isGroup:self.isGroup];
}


/*!
 @abstract Allow user to select a new notification tone 
 
 - save canidate tone in self.pendingTone
 
 */
- (void) pressTone:(id) sender {
    
    ToneController *nextController = [[ToneController alloc] initIsGroupNotification:self.isGroup];
    nextController.delegate = self;
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
}


/*!
 @abstract Popup switch 
 */
- (void) pressPop:(id) sender {
    
    NSNumber *isOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPushPopUpIsOn];
    
    // request opposite of current state
    BOOL newValue = ![isOn boolValue];
    
    // move switch to desired position
    SettingButton *setButton = (SettingButton *)[self.view viewWithTag:POPUP_BTN_TAG];
    [setButton setValueBOOL:newValue animated:YES];
    
    [AppUtility startActivityIndicator];
    [[AppUtility getAppDelegate] tryRegisterPushNotificationForceStart:YES enableAlertPopup:newValue];
}

/*!
 @abstract Preview switch 
 */
- (void) pressPreview:(id) sender {
    
    NSNumber *isOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:self.isGroup?kMPSettingPushGroupPreviewIsOn:kMPSettingPushP2PPreviewIsOn];
    
    // request opposite of current state
    BOOL newValue = ![isOn boolValue];
    
    // move switch to desired position
    SettingButton *setButton = (SettingButton *)[self.view viewWithTag:PREVIEW_BTN_TAG];
    [setButton setValueBOOL:newValue animated:YES];
    
    [AppUtility startActivityIndicator];
    [[MPHTTPCenter sharedMPHTTPCenter] setPNPreview:newValue isGroup:self.isGroup];
}

/*!
 @abstract Alert switch 
 */
- (void) pressInAppVibration:(id) sender {
    
    NSString *valueKey = self.isGroup?kMPSettingPushGroupInAppIsVibrateOn:kMPSettingPushP2PInAppIsVibrateOn;
    
    NSNumber *isOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:valueKey];
    
    // request opposite of current state
    BOOL newValue = ![isOn boolValue];
    
    // move switch to desired position
    SettingButton *setButton = (SettingButton *)[self.view viewWithTag:INAPP_VIBRATION_BTN_TAG];
    [setButton setValueBOOL:newValue animated:YES];
    
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:valueKey  settingValue:[NSNumber numberWithBool:newValue]];
}

/*!
 @abstract Alert switch 
 */
- (void) pressInAppSound:(id) sender {
    
    NSString *valueKey = self.isGroup?kMPSettingPushGroupInAppIsSoundOn:kMPSettingPushP2PInAppIsSoundOn;
    
    NSNumber *isOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:valueKey];
    
    // request opposite of current state
    BOOL newValue = ![isOn boolValue];
    
    // move switch to desired position
    SettingButton *setButton = (SettingButton *)[self.view viewWithTag:INAPP_SOUND_BTN_TAG];
    [setButton setValueBOOL:newValue animated:YES];
    
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:valueKey  settingValue:[NSNumber numberWithBool:newValue]];

}




#pragma mark - Handlers


/*!
 @abstract process alert request result
 
 - TODO: account for M+ PNS failure.  Right now we only check if Apple service is successful
 
 */
- (void) processPop:(NSNotification *)notification {
    [AppUtility stopActivityIndicator];
    NSNumber *registrationSucceeded = [notification object];
    
    SettingButton *popButton = (SettingButton *)[self.view viewWithTag:POPUP_BTN_TAG];
    BOOL isOn = [[[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPushPopUpIsOn] boolValue];
    
    // success
    if ([registrationSucceeded boolValue] == YES) {
        
        // set opposite value
        [popButton setValueBOOL:!isOn animated:NO];
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPushPopUpIsOn settingValue:[NSNumber numberWithBool:!isOn]];
        
    }
    // did not succeed
    else {
        
        // make sure switch position is correct
        [popButton setValueBOOL:isOn animated:NO];
        
        NSString *detMessage = NSLocalizedString(@"Set Alert Popup failed. Try again.", @"Notif - alert: inform of failure");
        [Utility showAlertViewWithTitle:nil message:detMessage];
    }
}


/*!
 @abstract process alert request result
 
 */
- (void) processAlert:(NSNotification *)notification {
        
    [AppUtility stopActivityIndicator];
    NSDictionary *responseD = [notification object];
    
    SettingButton *alertButton = (SettingButton *)[self.view viewWithTag:ALERT_BTN_TAG];
    NSString *valueKey = self.isGroup?kMPSettingPushGroupAlertIsOn:kMPSettingPushP2PAlertIsOn;
    BOOL isOn = [[[MPSettingCenter sharedMPSettingCenter] valueForID:valueKey] boolValue];
    
    // ask to confirm
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        // set opposite value
        [alertButton setValueBOOL:!isOn animated:NO];
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:valueKey settingValue:[NSNumber numberWithBool:!isOn]];
        
        [self showOrHideSubButtonsAnimated:YES];
    }
    // did not succeed
    else {
        
        // make sure switch position is correct
        [alertButton setValueBOOL:isOn animated:NO];
        
        NSString *title = NSLocalizedString(@"Set Alert", @"MyProfile - alert title:");
        NSString *detMessage = NSLocalizedString(@"Set Alert failed. Try again.", @"Notif - alert: inform of failure");
    
        [Utility showAlertViewWithTitle:title message:detMessage];
    }
}


/*!
 @abstract process alert request result
 
 */
- (void) processTone:(NSNotification *)notification {
    
    [AppUtility stopActivityIndicator];
    NSDictionary *responseD = [notification object];
    
    SettingButton *toneButton = (SettingButton *)[self.view viewWithTag:TONE_BTN_TAG];
    NSString *valueKey = self.isGroup?kMPSettingPushGroupRingTone:kMPSettingPushP2PRingTone;
    NSString *currentFilename = [[MPSettingCenter sharedMPSettingCenter] valueForID:valueKey];

    // ask to confirm
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        // set opposite value
        if (self.pendingTone) {
            [toneButton setValueText:[ToneController nameForToneFilename:self.pendingTone]];
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:valueKey settingValue:self.pendingTone];
            self.pendingTone = nil;
        }
    }
    // did not succeed
    else {
        
        //NSString *title = NSLocalizedString(@"Set Alert", @"MyProfile - alert title:");
        NSString *detMessage = NSLocalizedString(@"Set Ring Tone failed. Try again.", @"Notif - alert: inform of failure");
        [Utility showAlertViewWithTitle:nil message:detMessage];

        [toneButton setValueText:[ToneController nameForToneFilename:currentFilename]];
    }
}


/*!
 @abstract process message preview request result
 
 */
- (void) processPreview:(NSNotification *)notification {
    
    [AppUtility stopActivityIndicator];
    NSDictionary *responseD = [notification object];
    
    SettingButton *previewButton = (SettingButton *)[self.view viewWithTag:PREVIEW_BTN_TAG];
    NSString *valueKey = self.isGroup?kMPSettingPushGroupPreviewIsOn:kMPSettingPushP2PPreviewIsOn;
    BOOL isOn = [[[MPSettingCenter sharedMPSettingCenter] valueForID:valueKey] boolValue];
    
    // ask to confirm
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        // set opposite value
        [previewButton setValueBOOL:!isOn animated:NO];
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:valueKey settingValue:[NSNumber numberWithBool:!isOn]];
        
    }
    // did not succeed
    else {
        
        // make sure switch position is correct
        [previewButton setValueBOOL:isOn animated:NO];
        
        //NSString *title = NSLocalizedString(@"Set Message Preview", @"Notif - alert title:");
        NSString *detMessage = NSLocalizedString(@"Set Message Preview Failed. Try again.", @"Notif - alert: inform of failure");
        
        [Utility showAlertViewWithTitle:nil message:detMessage];
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
    if ([queryType isEqualToString:kMPHCRequestTypeSetPushNotify] || 
        [queryType isEqualToString:kMPHCRequestTypeSetPushRingTone] ||
        [queryType isEqualToString:kMPHCRequestTypeSetPNPreview]) {
        
        [self resetSettingDisplayValuesAnimated:YES];
        
    }
}

#pragma mark - ToneController

/*!
 @abstract Used to notify parent view which tone was selected
 
 - change to new tone name
 - submit tone change request
 
 */
- (void)ToneController:(ToneController *)controller selectedToneFilename:(id)filename {
    
    self.pendingTone = filename;
    
    SettingButton *toneButton = (SettingButton *)[self.view viewWithTag:TONE_BTN_TAG];
    [toneButton setValueText:[ToneController nameForToneFilename:self.pendingTone]];
    
    NSString *p2pTone = nil;
    NSString *groupTone = nil;
    
    if (self.isGroup) {
        groupTone = filename;
    }
    else {
        p2pTone = filename;
    }
    
    [AppUtility startActivityIndicator];
    [[MPHTTPCenter sharedMPHTTPCenter] setPushRingToneP2P:p2pTone groupTone:groupTone];
}


@end

