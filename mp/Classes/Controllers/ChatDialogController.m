//
//  ChatDialogController.m
//  mp
//
//  Created by M Tsai on 11-10-20.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "ChatDialogController.h"
#import "MPFoundation.h"

#import <MobileCoreServices/MobileCoreServices.h>  // for photo assets types
#import "ELCAlbumPickerController.h"

#import "MPChatManager.h"
#import "CDChat.h"
#import "CDMessage.h"
#import "CDContact.h"

#import "ChatSettingController.h"
#import "ChatNameController.h"
#import "NavigationTitleView.h"
#import "MPContactManager.h"


CGFloat const kMPParamTypingDisplayTimeoutSeconds = 4.0;

CGFloat const kTabBarHeight = 48.0;
CGFloat const kNavBarHeight = 44.0;
CGFloat const kEmoticonKeyboardHeight = 216.0;



@interface ChatDialogController (PrivateMethods)
- (void) registerForKeyboardNotifications;
- (void) showAttachOptions;
- (void) setToolBarFrameForKeyboardHeight:(CGFloat)kbHeight;
- (void) setButtons;

- (UIImage *) backgroundImageForCurrentStateCode;
- (UIImage *) buttonImageForCurrentStateCode;

- (void) updateDialogTitleAndStatus:(NSString *)statusText;

@end


@implementation ChatDialogController

@synthesize delegate;
@synthesize cdChat;
@synthesize tableController;
@synthesize toolBarView;
@synthesize chatScrollView;
@synthesize typingView;
@synthesize typingTimer;
@synthesize shakeViewEndTimer;
@synthesize locManager;
@synthesize viewDidAppearFlags;
@synthesize enableKeyboardAnimation;
@synthesize didPushAnotherView;


- (id)initWithCDChat:(CDChat *)newChat
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.cdChat = newChat;
        self.hidesBottomBarWhenPushed = YES;
        self.enableKeyboardAnimation = YES;
    }
    return self;
}

- (void) dealloc {

    toolBarView.delegate = nil;
    //chatScrollView.delegate = nil;
    
    [typingTimer invalidate];
    [typingTimer release];
    [shakeViewEndTimer invalidate];
    [shakeViewEndTimer release];
    
    [cdChat release];
    [toolBarView release];
    //[chatScrollView release];
    [tableController release];
    [typingView release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
    DDLogInfo(@"CDC: receive low memory warning");
}

#pragma mark - View lifecycle




// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    // background image
    //
    UIImageView *backImageV = [[UIImageView alloc] initWithImage:[self backgroundImageForCurrentStateCode]];
    backImageV.userInteractionEnabled = YES;
    backImageV.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    backImageV.frame = appFrame;
    
    self.view = backImageV;
    [backImageV release];
    
    // add typing pulsing image
    //
    UIImageView *typingImageV = [[UIImageView alloc] initWithImage:[self backgroundImageForCurrentStateCode]];
    typingImageV.frame = self.view.bounds;
    typingImageV.image = [UIImage imageNamed:@"chat_dialog_typing.png"];
    typingImageV.alpha = 0.0;
    self.typingView = typingImageV;
    [self.view addSubview:typingImageV];
    [typingImageV release];
    
    
    // add table view
    //
    DialogTableController *tController = [[DialogTableController alloc] initWithStyle:UITableViewStylePlain cdChat:self.cdChat parentController:self];
    tController.delegate = self;
    self.tableController = tController;
    [self.view addSubview:tController.tableView];
    [tController release];
    
    // background scroll view
    //
    //ChatDialogSrollView *scControl = [[ChatDialogSrollView alloc] initWithChat:self.cdChat parentController:self];
    //self.chatScrollView = scControl;
    //self.chatScrollView.delegate = self;
    //[self.view addSubview:self.chatScrollView];
    //[scControl release];
    
    // add light bulb button
    UIButton *bulbButton = [[UIButton alloc] initWithFrame:CGRectMake(appFrame.size.width-50.0, appFrame.size.height-kMPParamDialogToolBarHeight-55.0, 50.0, 45.0)];
    bulbButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [bulbButton setImage:[self buttonImageForCurrentStateCode] forState:UIControlStateNormal];
    
    // add fade transition when image is set
    /*CATransition *transition = [CATransition animation];
    transition.duration = kMPParamAnimationStdDuration;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;*/
    //[bulbButton.imageView.layer addAnimation:transition forKey:nil];
    [bulbButton addTarget:self action:@selector(pressBulb:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bulbButton];
    [bulbButton release];
    
    
    // resize table view
    //
    /*CGRect tableFrame = CGRectMake(0.0, 0.0, appFrame.size.width, appFrame.size.height - 30.0);
    self.messageTableController.view.frame = tableFrame;
    [self.view addSubview:self.messageTableController.view];
     */
    
    // place tool bar at the bottom of screen - 378
    CGFloat startY = appFrame.size.height - kMPParamDialogToolBarHeight;
    CGRect toolFrame = CGRectMake(0.0, startY, appFrame.size.width, kMPParamDialogToolBarHeight);
    
    // add toolbar view
    //
    ChatDialogToolBarView *tView = [[ChatDialogToolBarView alloc] initWithFrame:toolFrame];
    [self.view addSubview:tView];
    self.toolBarView = tView;
    self.toolBarView.delegate = self;
    [tView release];

    // check if account is cancelled
    // - if so, disable toolbar & settings..
    //
    CDContact *p2pContact = [self.cdChat p2pUser];
    if ([p2pContact isUserAccountedCanceled]) {
        [self.toolBarView disableControlsWithMessage:NSLocalizedString(@"Account Deleted", @"ChatDialog - text: inform that this p2p chat account is canceled, so can't send message to user")];
    }
    
    
    [self setButtons];
}

#define CHAT_BADGE_TAG  17001

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    DDLogInfo(@"CDC: vdl load");

}


- (void)viewDidUnload
{
    DDLogInfo(@"CDC: vdu unload");
    
    // reset the titleview
    // - so it gets regenerated next time
    //self.navigationItem.titleView = nil;

    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

 
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    DDLogInfo(@"CDC: vwa");

    self.didPushAnotherView = NO;
    
    // if pending text exits add it back
    if ([self.cdChat.pendingText length] > 0) {
        self.toolBarView.multiTextField.text = self.cdChat.pendingText;
        [self.toolBarView setSendButtonEnabled:YES ignoreCurrentTextLength:NO];
    }
    //[self.tableController scrollToStartPosition];

    //[self.chatScrollView reload];
    [self registerForKeyboardNotifications];
    
    // set title to name of chat - this may change, so update it every time
    //
    [self updateDialogTitleAndStatus:nil];
    
    
    // check if group chat is now empty
    // - if so, disable toolbar but not settings
    if ([self.cdChat isGroupChat]) {
        NSUInteger memberCount = [self.cdChat.participants count];
        if (memberCount == 0) {
            [self.toolBarView disableControlsWithMessage:NSLocalizedString(@"No Group Members", @"ChatDialog - text: inform that group chat has no members, so don't allow messaging")];
        }
        else {
            [self.toolBarView enableControls];
        }
    }
    
    // refresh tableview
    // - in case some messages were added this view was not showing
    [self.tableController.tableView reloadData];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processChatNameUpdate:) name:MP_CHATNAME_UPDATE_NAME_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processChatNameUpdate:) name:MP_DAILOG_UPDATE_NAME_NOTIFICATION object:nil];
    
    
    // always listen for connect or network loss event
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLostNetwork:) name:MP_SOCKETCENTER_NETWORK_NOTREACHABLE_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleConnectTry:) name:MP_SOCKETCENTER_CONNECT_TRY_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleConnectSuccess:) name:MP_SOCKETCENTER_CONNECT_SUCCESS_NOTIFICATION object:nil];
    
    // listen for presence state change
    // - so we can update when it changes
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadNavigationTitleStatus:) name:MP_CONTACTMANAGER_RELOAD_DATA_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadNavigationTitleStatus:) name:MP_CONTACTMANAGER_INDEX_NOTIFICATION object:nil];
    
    // listen for typing now messages
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(handleTypingNow:) name:MP_CHATMANAGER_TYPING_NOW_NOTIFICATION object:nil];
    
    
}



- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // let chat manager know this is chat is currently being viewed
    // - so don't consider it unread
    //
    [[MPChatManager sharedMPChatManager] assignCurrentDisplayedChat:self.cdChat];
    
    // if not first responder - set toolbar to the bottom
    if (![self.toolBarView.multiTextField.internalTextView isFirstResponder]) {
        [self setToolBarFrameForKeyboardHeight:0.0];
    }
    DDLogVerbose(@"CDC-vda");

    // add badge if it does not exists
    UIButton *badgeButton = (UIButton *)[self.navigationController.navigationBar viewWithTag:CHAT_BADGE_TAG];
    if (!badgeButton) {
        NSArray *views =  self.navigationController.navigationBar.subviews;
        for (UIView *iView in views){
            // find left button view
            CGFloat x = iView.frame.origin.x;
            if (x > 0.0 && x < 10.0) {
                
                CGSize buttonSize = iView.frame.size;
                
                badgeButton = [[UIButton alloc] initWithFrame:CGRectMake(buttonSize.width - 10.0, -6.0, 20.0, 20.0)];
                [AppUtility configButton:badgeButton context:kAUButtonTypeBadgeRed];
                badgeButton.hidden = YES;
                badgeButton.tag = CHAT_BADGE_TAG;
                [iView addSubview:badgeButton];  
                [badgeButton release];
            
                break;
            }
        }
    }
    // observer badge count updates
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUnreadChatBadge:) name:MP_CHATMANAGER_UPDATE_BADGECOUNT_NOTIFICATION object:nil];
    
    // call for an update
    //
    [[MPChatManager sharedMPChatManager] updateChatBadgeCount];  

    // handle flags
    if ([self.viewDidAppearFlags hasPrefix:@"showAlbumSingle"]) {
        [self displayPhotoAlbumTypeSingle];
        self.viewDidAppearFlags = nil;
    }
}


/*
 @abstract if chat number changes, also update badge
 */
- (void) updateUnreadChatBadge:(NSNotification *)notification {
    
    NSNumber *unreadNumber = [notification object];
    
    UIButton *badgeButton = (UIButton *)[self.navigationController.navigationBar viewWithTag:CHAT_BADGE_TAG];

    NSString *numString = [unreadNumber stringValue];
    
    [AppUtility setBadge:badgeButton text:numString];
}

- (void)viewWillDisappear:(BOOL)animated
{
    
    // end shake animation
    [self endShakeMainView];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    // Catch NSObjectInaccessibleException in case this chat is deleted when viewing the chat dialog
    // This can occur if the user account is installed on a different device, so we need to delete this 
    // user account on the old device.  This will initiate a reset that clears the entire all CD entities.
    //
    @try {
        if (![self.cdChat.pendingText isEqualToString:self.toolBarView.multiTextField.text]) {
            self.cdChat.pendingText = [Utility trimWhiteSpace:self.toolBarView.multiTextField.text];
            [AppUtility cdSaveWithIDString:@"CDC: save pending text" quitOnFail:NO];
        }
    }
    @catch (NSException *exception) {
        NSString *exceptionName = [exception name];
        DDLogWarn(@"CDC-vwd: Raised Exception %@: %@", exceptionName, [exception reason]);
    }
    

    [[MPChatManager sharedMPChatManager] assignCurrentDisplayedChat:nil];
    
    // no updates needed when not showing
    //
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MP_CHATMANAGER_UPDATE_BADGECOUNT_NOTIFICATION object:nil];
    
    UIButton *badgeButton = (UIButton *)[self.navigationController.navigationBar viewWithTag:CHAT_BADGE_TAG];
    [badgeButton removeFromSuperview];
    
    //[self.chatScrollView unload];
    [super viewWillDisappear:animated];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    
    DDLogInfo(@"CDC: vdd did disappear");
    
    [super viewDidDisappear:animated];
    
}


#pragma mark - Change orientations

/*!
 @abstract Updates view properly for given orientation
 */
- (void) updateLayoutForNewOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated duration:(NSTimeInterval)duration {
    
    if (animated) {
        [UIView animateWithDuration:duration
                         animations: ^{
                             if (UIInterfaceOrientationIsLandscape(orientation)) {
                                 
                                 // iOS 4.x will show part of nav bar in landscape mode since it is not resized properly
                                 // - hide and show it properly
                                 if (![self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)])
                                 {
                                     [UIView animateWithDuration:kMPParamAnimationStdDuration animations:^{
                                         self.navigationController.navigationBar.alpha = 0.0;
                                     }];                                 
                                 }

                                 [self.navigationController setNavigationBarHidden:YES animated:animated];
                                 // this does not work quite right when there is a view presented modally above the dailog
                                 // - disable for now
                                 //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated];
                             }
                             else {

                                 // iOS 4.x will show part of nav bar in landscape mode since it is not resized properly
                                 // - hide and show it properly
                                 if (![self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)])
                                 {
                                     [UIView animateWithDuration:kMPParamAnimationStdDuration animations:^{
                                         self.navigationController.navigationBar.alpha = 1.0;
                                     }];                                 
                                 }
                                 
                                 [self.navigationController setNavigationBarHidden:NO animated:animated];
                                 //[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:animated];
                             }
                             
                             // if not first responder - set toolbar to the bottom
                             if (![self.toolBarView.multiTextField.internalTextView isFirstResponder]) {
                                 [self setToolBarFrameForKeyboardHeight:0.0];
                             }
                         }]; 
    }
}


/*!
 @abstract just before rotation animation.  New bounds are already set
 */
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    
    //[self updateLayoutForNewOrientation:interfaceOrientation animated:YES duration:duration]; 
    
}

/*- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    DDLogInfo(@"rotating");   
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    DDLogInfo(@"did rotate");   

}*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    if (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown) {
        [self updateLayoutForNewOrientation:interfaceOrientation animated:YES duration:kMPParamAnimationStdDuration];
        return YES;
    }
    return NO;
}

#pragma mark - TitleView Update



/*!
 @abstract Updates the title status if new presence information comes in
 
 */
- (void) reloadNavigationTitleStatus:(NSNotification *)notification {
    
    NSSet *userIdSet = [notification object];
    
    // if update contains this contact
    // - or id are not specified - update all
    //
    if (userIdSet == nil || 
        [userIdSet containsObject:[self.cdChat p2pUserID]]) {
        
        self.title = [self.cdChat displayNameStyle:kCDChatNameStyleTitle];
        [(NavigationTitleView *)self.navigationItem.titleView setTitleText:self.title];
        
        NSString *status = [self currentStatusString];
        [(NavigationTitleView *)self.navigationItem.titleView setStatusText:status];
    }
    
}


/*!
 @abstract Gets the current status string that this dialog should show
 
 - if not connected, then try logging in
 
 */
- (NSString *) currentStatusString {
    
    NSString *status = @"";
    
    // get the current status
    if ([[AppUtility getSocketCenter] isNetworkReachable]) {
        // is connected?
        if ([[AppUtility getSocketCenter] isLoggedIn]) {
            
            status = [[self.cdChat p2pUser] presenceString];
            
        }
        // not connected
        // - request connection attempt
        //
        else {
            status = [NavigationTitleView descriptionForState:kNTStateConnecting];
            // consider reducting timer instead
            DDLogInfo(@"CDC: not CNTed, so try login now...");
            [[AppUtility getSocketCenter] loginAndConnect];
        }
    }
    // no network
    else {
        status = [NavigationTitleView descriptionForState:kNTStateNoNetwork];
    }
    return status;
}




/*!
 @abstract Updates the navigation title
 
 @param statusText If defined, update the status text below the title.
 
 
 Possible states:
 - No network
 - Connecting...
 - Presence:
    ~ Online
    ~ 2011/02/14
    ~ 15:30 AM
 
 Notification needed:
 - Try connecting   show connecting
 - Connected        show presence
 - Lost network     show no network
 
 Testing:
 - start chat
    ~ p2p - show presence string
    ~ group - show nothing
 - go online and offline with other p2p user - presence should change
 - shut down network - no network
 - restart network - connecting
 
 */
- (void) updateDialogTitleAndStatus:(NSString *)statusText {
    
    DDLogInfo(@"CDC-udts: updating status - %@", statusText);
    
    self.title = [self.cdChat displayNameStyle:kCDChatNameStyleTitle];

    // lazy load navigation titleView
    //
    if (!self.navigationItem.titleView) {
        
        NSString *status = [self currentStatusString];
        
        NavigationTitleView *titleView = [[NavigationTitleView alloc] initWithTitle:self.title status:status];
        self.navigationItem.titleView = titleView;
        [titleView release];
    
    }
    // update existing title and status
    //
    else {
        [(NavigationTitleView *)self.navigationItem.titleView setTitleText:self.title];
        
        NSString *status = statusText;
        if (status == nil) {
            status = [self currentStatusString];
        }
        [(NavigationTitleView *)self.navigationItem.titleView setStatusText:status];
    }
}


/*!
 @abstract Update title view for lost network
 
 - set status to no network
 - don't listen for presence updates
 - SC will try to reconnect automatically
 
 */
- (void) handleLostNetwork:(NSNotification *)notification {
    
    [self updateDialogTitleAndStatus:[NavigationTitleView descriptionForState:kNTStateNoNetwork]];
    
}


/*!
 @abstract Update title view connection retry
 
 - set status "connecting"
 - don't listen for presence updates
 
 */
- (void) handleConnectTry:(NSNotification *)notification {
    
    DDLogInfo(@"CDC-hct: got try connect notification - update title");
    [self updateDialogTitleAndStatus:[NavigationTitleView descriptionForState:kNTStateConnecting]];
    
}

/*!
 @abstract Update title view connection retry
 
 - listen for presence updates
 - set status to p2p presence or nil(group)
 
 */
- (void) handleConnectSuccess:(NSNotification *)notification {
    
    [self updateDialogTitleAndStatus:[[self.cdChat p2pUser] presenceString]];
    
}


/*!
 @abstract Start typing now visualizations
 
 - set to current status state
 
 */
- (void) stopTyping:(NSTimer *)timer {
    
    [self updateDialogTitleAndStatus:[self currentStatusString]];
    
    // stop animating
    UIViewAnimationOptions animationOptions = (UIViewAnimationOptionBeginFromCurrentState |
                                               UIViewAnimationOptionAllowUserInteraction);
    [UIView animateWithDuration:1.0 delay:0.0 options:animationOptions 
                     animations:^{
                         self.typingView.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                         if (finished) {
                             // nothing to do
                         }
                     }];
}

/*!
 @abstract Start typing now visualizations
 
 */
- (void) handleTypingNow:(NSNotification *)notification {
    
    NSManagedObjectID *notifChatID = [notification object];
    
    // typing now for this chat
    if ([[self.cdChat objectID] isEqual:notifChatID]) {
        
        
        // if typing already
        // - cancel timer to extend it
        if ([self.typingTimer isValid]) {
            [self.typingTimer invalidate];
        }
        // set typing message & start animation
        else {
            [self updateDialogTitleAndStatus:[NavigationTitleView descriptionForState:kNTStateTyping]];
            self.typingView.alpha = 0.0;
            // iOS 4.x needs to enable user interaction so the interface does not just freeze up during the animation
            //
            UIViewAnimationOptions animationOptions = (UIViewAnimationOptionRepeat | 
                                                       UIViewAnimationOptionAutoreverse |
                                                       UIViewAnimationOptionAllowUserInteraction); 
            [UIView animateWithDuration:1.0 delay:0.0 options:animationOptions 
                             animations:^{
                                 self.typingView.alpha = 1.0;
                             } 
                             completion:^(BOOL finished){
                                 if (finished) {
                                     // nothing to do
                                 }
                             }];
        }
        self.typingTimer = [NSTimer scheduledTimerWithTimeInterval:kMPParamTypingDisplayTimeoutSeconds  target:self selector:@selector(stopTyping:) userInfo:nil repeats:NO];
    }
}


/*!
 @abstract catch name change and update our name 
 */
- (void) processChatNameUpdate:(NSNotification *)notification {
   
    CDChat *notifChat = [notification object];
    
    if (self.cdChat == notifChat) {
        [self updateDialogTitleAndStatus:nil];
    }
    
}

#pragma mark - Keyboard Methods


/*!
 @abstract Standard method to hide keyboard if it is showing
 
 */
- (void)hideKeyboard {
    [self.toolBarView resignTextField];
    [self.toolBarView showEmoticonButton];
}


// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}


/*!
 @abstract Set Toolbar frame so it matches the keyboard height
 */
- (void) setToolBarFrameForKeyboardHeight:(CGFloat)kbHeight {
    
    //UIInterfaceOrientation testValue = self.interfaceOrientation;
    CGRect bounds = [self.view bounds];
    
    CGRect newToolRect = self.toolBarView.frame;
    //CGRect appFrame = [Utility appFrame];
    
    //newToolRect.origin.y = appFrame.size.height - kNavBarHeight - self.toolBarView.frame.size.height - kbHeight;
    newToolRect.origin.y = bounds.size.height - self.toolBarView.frame.size.height - kbHeight;
    newToolRect.size.width = bounds.size.width;
    
    self.toolBarView.frame = newToolRect;
    
}

/*!
 @abstract Adjust view to match keyboard height
 */
- (void)AdjustViewToMatchKeyBoardNotification:(NSNotification *)aNotification {
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    NSNumber *duration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];

    
    
    //DDLogInfo(@"CDC-avt: showing kbHeight: %f", kbSize.height);
    
	// animations settings
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
    
    
    // adjust toolbar to right location
    //
    CGFloat kbHeight = 0.0;
    
    /* Handle orientation
       - the actual width will depend on the orientation
       - but the orientation is not always reliable especially if subview forces the orientation to a different one
         e.g. petphrase enter edit view when in landscape
     
     // so this will not always work
     if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
     kbHeight = kbSize.width;
     }
     else {
     kbHeight = kbSize.height;
     }
     
       - instead KB height is always smaller then width ... unless we have a very different new device in the future
     */
    kbHeight = MIN(kbSize.width, kbSize.height);
    
    //[self.chatScrollView scrollToShowLastMessageWithKeyboardHeight:kbHeight animated:YES];
    
    // turn off dialog animation so that bounce effect does not appear when switching keyboards
    [self.tableController scrollToShowLastMessageWithKeyboardHeight:kbHeight animated:NO];
    [self setToolBarFrameForKeyboardHeight:kbHeight];
    
    [UIView commitAnimations];
}


// Called when the UIKeyboardDidShowNotification is sent.
//
- (void)keyboardWillShown:(NSNotification*)aNotification
{
    
    if (!self.enableKeyboardAnimation) {
        return;
    }
    
    [self AdjustViewToMatchKeyBoardNotification:aNotification];

}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{

    if (!self.enableKeyboardAnimation) {
        return;
    }
    
    NSDictionary* info = [aNotification userInfo];
    NSNumber *duration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    //DDLogInfo(@"CDC-kwh: hidding kbHeight: %f", kbSize.height);
    
    // animations settings
    [UIView animateWithDuration:[duration doubleValue] 
                          delay:0.0 
                        options:[curve intValue]|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.tableController clearContentInsets];

                         // adjust toolbar
                         //
                         [self setToolBarFrameForKeyboardHeight:0.0];
                     } 
                     completion:^(BOOL complete) {}];

}

#pragma mark - ToolBar Delegate

/*!
 @abstract Check if chat contact is blocked and show alert to unblock
 
 @return YES if blocked
 */
- (BOOL) isChatContactBlocked {
    
    CDContact *p2pContact = [self.cdChat p2pUser];
    if ([p2pContact isBlockedByMe]) {
        
        NSString *detMessage = [NSString stringWithFormat:NSLocalizedString(@"%@ is blocked. Unblock to send message.", @"ChatDialog - alert: Need to unblock in order to message"), [p2pContact displayName]];
        
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:nil
                                                         message:detMessage
                                                        delegate:self
                                               cancelButtonTitle:NSLocalizedString(@"Cancel", @"ChatDialog: Cancel button") 
                                               otherButtonTitles:NSLocalizedString(@"Unblock", @"ChatDialog: Unblock this user"), nil] autorelease];
        [alert show];
        return YES;
    }
    return NO;
}


/*!
 @abstract Play audio when new message is sent out
 
 */
- (void) playSentAudio {
        
    
    NSString *soundFile = @"sent.caf";
    [Utility asPlaySystemSoundFilename:soundFile];
    
    /*
    static ALuint soundID = 0;
    // play audio
    if (soundID) {
        [Utility audioStop:soundID];
    }        
    soundID = [Utility audioPlayEffect:soundFile];
    */
    
    
    // TODO: add failed message condition and vibrate phone when failure occurs
    //
    
    /*BOOL vibrateOn = [[[MPSettingCenter sharedMPSettingCenter] valueForID:isGroup?kMPSettingPushGroupInAppIsVibrateOn:kMPSettingPushP2PInAppIsVibrateOn] boolValue];
    
    if (vibrateOn) {
        [Utility vibratePhone];
    }*/
    
}


/*!
 @abstract Call when send button is pressed
 
 Delegate can takes text and helps send's this message
 
 */
- (BOOL)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView pressSendButtonWithText:(NSString *)text {
    
    // If not blocked sent text
    //
    if (![self isChatContactBlocked]) {
        //[self.chatScrollView sendText:text];
        [self.tableController sendText:text];
        
        //[self playSentAudio];
        
        // chat not blocked
        return NO;
    }
    // chat is blocked
    else {
        return YES;
    }
}

/*!
 @abstract Run out of sequence message test
 
 */
- (void)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView startOutOfSequenceMessageTest:(BOOL)start {
    [self.tableController sendOutOfSequenceText];
}

/*!
 @abstract Call when sticker is selected
 
 Delegate takes resource and creates a sticker CDMessage
 */
- (void)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView pressStickerResource:(CDResource *)resource {
    // If not blocked send sticker resource
    //
    if (![self isChatContactBlocked]) {
        //[self.chatScrollView sendStickerResource:resource];
        [self.tableController sendStickerResource:resource];
    }
}


/*!
 @abstract Call if tool bar wants to know if it is ok to do something
 
 @return YES if should proceeed, NO if action should not be taken
 
 */
- (BOOL)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView shouldProceedWithAction:(NSString *)actionTag {
    return ![self isChatContactBlocked];
}


/*!
 @abstract Call when keypad button is pressed
 
 Delegate should show default keypad
 
 */
- (void)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView pressKeypadButton:(UIButton *)button{
    
}

/*!
 @abstract Call when attach button is pressed
 
 Delegate should show attach action sheet
 
 */
- (void)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView pressAttachButton:(UIButton *)button{
    // If not blocked show options
    //
    if (![self isChatContactBlocked]) {
        [self showAttachOptions];
    }
}


/*!
 @abstract Call when a typing now message should be sent out - indicates toolbar is content is changing
 
 Delegate should send out the message
 */
- (void)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView isTypingNow:(BOOL)isTypingNow {
    
    // sends typing now message
    [[MPChatManager sharedMPChatManager] sendTypingNowMessageForChat:self.cdChat];
    
}

/*!
 @abstract Inform delegate to enable or disable keyboard animation adjustments
 
 Use:
 - This is used to temporarily disable chat dialog animation during quick emoticon/text keyboard changes
 
 */
- (void)ChatDialogToolBarView:(ChatDialogToolBarView *)toolBarView enableKeyboardAnimation:(BOOL)keyboardAnimation {
    
    self.enableKeyboardAnimation = keyboardAnimation;
    
}

#pragma mark - UIAlertViewDelegate and Unblock Methods


/*!
 @abstract User wants to unblock this p2p chat
 */
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // unblock user
	if (buttonIndex != [alertView cancelButtonIndex]) {
        
        CDContact *p2pContact = [self.cdChat p2pUser];
        if (p2pContact) {
            [AppUtility startActivityIndicator];
            
            // observe block events
            //
            [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(handleUnBlock:) name:MP_HTTPCENTER_UNBLOCK_NOTIFICATION object:nil];
            
            [[MPHTTPCenter sharedMPHTTPCenter] unBlockUser:p2pContact.userID];
        }
	}
}

/*!
 @abstract process block response
 
 Successful case
 <UnBlock>
 <cause>0</cause>
 </UnBlock>
 
 Exception case
 <UnBlock>
 <cause>602</cause>
 <text>invalid USERID!</text>
 </UnBlock>
 
 */
- (void) handleUnBlock:(NSNotification *)notification {
    
    // don't listen anymore
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MP_HTTPCENTER_UNBLOCK_NOTIFICATION object:nil];
    
    [AppUtility stopActivityIndicator];
    NSDictionary *responseD = [notification object];
    
    // go ahead and block user
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        // unblock user
        //
        CDContact *p2pContact = [self.cdChat p2pUser];
        
        NSManagedObjectID *blockUserObjectID = [p2pContact objectID];
        
        dispatch_async([AppUtility getBackgroundMOCQueue], ^{
            
            CDContact *blockContact = (CDContact *)[[AppUtility cdGetManagedObjectContext] objectWithID:blockUserObjectID];
            
            [blockContact unBlockUser];
            [AppUtility cdSaveWithIDString:@"unblock user" quitOnFail:NO];
            
        });
        
        
    }
    // inform of failure
    else {
        
        NSString *alertTitle = NSLocalizedString(@"Unblock Friend", @"ChatDialog - alert title:");
        NSString *alertMessage = NSLocalizedString(@"Unblock failed. Try again later.", @"ChatDialog - alert: Inform of failure");
        [Utility showAlertViewWithTitle:alertTitle message:alertMessage];
        
    }
}


#pragma mark - Dialog Background


/*!
 @abstract Background image for ChatDialogStateCode
 
 */
- (UIImage *) backgroundImageForCurrentStateCode{ //:(ChatDialogStateCode)stateCode {
    
    NSUInteger stateCode = [[[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingChatDialogStateCode] intValue];
    
    NSString *imageName = nil;
    
    switch (stateCode) {
        case kChatDialogStateCodeDay:
            imageName = @"chat_img_bk_light2.png";
            break;
            
        case kChatDialogStateCodeNight:
            imageName = @"chat_img_bk_dark.png";
            break;
            
        default:
            break;
    }
    return [UIImage imageNamed:imageName];
}


/*!
 @abstract Button image for ChatDialogStateCode
 
 */
- (UIImage *) buttonImageForCurrentStateCode{ //:(ChatDialogStateCode)stateCode {
    
    NSUInteger stateCode = [[[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingChatDialogStateCode] intValue];

    
    NSString *imageName = nil;
    
    switch (stateCode) {
        case kChatDialogStateCodeDay:
            imageName = @"chat_btn_bulb_dark.png";
            break;
            
        case kChatDialogStateCodeNight:
            imageName = @"chat_btn_bulb_light.png";
            break;
            
        default:
            break;
    }
    return [UIImage imageNamed:imageName];
}


/*!
 @abstract displays chat room settings
 
 */
- (void)pressBulb:(UIButton *)sender {
    
    // change state
    NSUInteger stateCode = [[[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingChatDialogStateCode] intValue];
    NSUInteger newState = stateCode?kChatDialogStateCodeDay:kChatDialogStateCodeNight;
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingChatDialogStateCode settingValue:[NSNumber numberWithInt:newState]];
    
    CATransition *transition = [CATransition animation];
    transition.duration = kMPParamAnimationStdDuration;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    
    // set new images
    [sender setImage:[self buttonImageForCurrentStateCode] forState:UIControlStateNormal];
    [sender.imageView.layer addAnimation:transition forKey:nil];

    [(UIImageView *)self.view setImage:[self backgroundImageForCurrentStateCode]];
    [self.view.layer addAnimation:transition forKey:nil];
    
}

#pragma mark - Button Methods


/*!
 @abstract Prepare to show new view
 
 Make sure shake animation is not running
 
 */
- (void) prepareToPresentNewView {
    
    self.didPushAnotherView = YES;
    [self endShakeMainView];
    
}


/*!
 @abstract sets up button for chat view
 
 */
// add edit and add button to navigation bar
- (void)setButtons {
    
    // settings button
    //
    UIBarButtonItem *settingButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Settings",  @"ChatDialog - Button: go to chat room settings") 
                                                         buttonType:kAUButtonTypeBarNormal 
                                                             target:self action:@selector(pressSetting:)];
    
    
    [self.navigationItem setRightBarButtonItem:settingButton animated:NO];
    
}

/*!
 @abstract displays chat room settings
 
 */
- (void)pressSetting:(id)sender {
    
    [self prepareToPresentNewView];
    
    ChatSettingController *newController = [[ChatSettingController alloc] initWithCDChat:self.cdChat];
    [self.navigationController pushViewController:newController animated:YES];
    [newController release];
    
}



/*!
 @abstract show action sheet for more options
 */
- (void) showAttachOptions {
    
    UIActionSheet *aSheet;
	
    CDContact* p2pContact = [self.cdChat p2pUser];
    
    // only text & image for helper
    //
    if (p2pContact && [MPContactManager isFriendAHelper:p2pContact]) {
        aSheet	= [[UIActionSheet alloc]
                   initWithTitle:@"" 
                   delegate:self
                   cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel contact group action")
                   destructiveButtonTitle:nil
                   otherButtonTitles:
                   NSLocalizedString(@"Album", @"ChatDialog: album image message"),
                   NSLocalizedString(@"Camera", @"ChatDialog: camera image message"),
                   nil];
    }
    else {
        aSheet	= [[UIActionSheet alloc]
                   initWithTitle:@"" 
                   delegate:self
                   cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel contact group action")
                   destructiveButtonTitle:nil
                   otherButtonTitles:
                   NSLocalizedString(@"Album", @"ChatDialog: album image message"),
                   NSLocalizedString(@"Camera", @"ChatDialog: camera image message"),
                   NSLocalizedString(@"<create letter message>", @"ChatDialog: letter message"),
                   NSLocalizedString(@"<create location message>", @"ChatDialog: location message"),
                   nil];
    }
	
	
	aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	
	[aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
	[aSheet release];
    
}



/*!
 @abstract select image to send
 */
- (void) pressCamera {
    
    [self prepareToPresentNewView];

    // startup camera
    //
    UIImagePickerController *imageController = [[UIImagePickerController alloc] init];
    //imageController.allowsEditing = YES;
    imageController.sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
        imageController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }
    imageController.delegate = self;
    [self presentModalViewController:imageController animated:YES];
    [imageController release];
    
}


/*!
 @abstract Show multi image album
 
 */
- (void) displayPhotoAlbumTypeMulti {
    
    [self prepareToPresentNewView];
    
    // multiple image picker
    //
    ELCAlbumPickerController *albumController = [[ELCAlbumPickerController alloc] initWithNibName:@"ELCAlbumPickerController" bundle:[NSBundle mainBundle]];     
    ELCImagePickerController *imagePicker = [[ELCImagePickerController alloc] initWithRootViewController:albumController];
    [albumController setParent:imagePicker];
    [imagePicker setDelegate:self];
    
    [AppUtility customizeNavigationController:imagePicker];
    
	[self presentModalViewController:imagePicker animated:YES];
    [imagePicker release];
    [albumController release];
    
}

/*!
 @abstract Show single image album
 
 */
- (void) displayPhotoAlbumTypeSingle {
    
    [self prepareToPresentNewView];

    UIImagePickerController *imageController = [[UIImagePickerController alloc] init];
    imageController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imageController.delegate = self;
    [self presentModalViewController:imageController animated:YES];
    [imageController release];
    
}


/*!
 @abstract Show photo album to select and send photo messages
 
 
 */
- (void) displayPhotoAlbumType:(ChatDialogAlbumType)albumType {
    
    if (albumType == kChatDialogAlbumTypeSingle) {
        [self displayPhotoAlbumTypeSingle];
    }
    else if (albumType == kChatDialogAlbumTypeMulti) {
        [self displayPhotoAlbumTypeMulti];
    }
    else {

        // is greater than 4.2?
        if ([CLLocationManager respondsToSelector:@selector(authorizationStatus)]) {
            
            CLAuthorizationStatus aStatus = [CLLocationManager authorizationStatus];
            
            // loc not enabled, start single album
            if (aStatus == kCLAuthorizationStatusDenied || aStatus == kCLAuthorizationStatusRestricted) {
                [self displayPhotoAlbumTypeSingle];
            }
            // try to start multi album
            else {
                [self displayPhotoAlbumTypeMulti];
            }
            
        }
        // start location update to see if location is available
        else {
            
            // if first time, show multi image welcom screen
            if ([[MPSettingCenter sharedMPSettingCenter] didNotRunFirstStartTag:kMPSettingFirstStartTagLoadPhotoAlbum]) {
                [self displayPhotoAlbumTypeMulti];
            }
            else {
                // create a lowest accuracy location manager to find out if loc service is available
                //
                CLLocationManager *lManager = [[CLLocationManager alloc] init];
                lManager.delegate = self;
                lManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
                [lManager startUpdatingLocation];
                self.locManager = lManager;
                [lManager release];
            }
            
        }
    }
    
}


/*!
 @abstract select image to send
 */
- (void) pressSelectImage {
    [self displayPhotoAlbumType:kChatDialogAlbumTypeQuery];
}

/*!
 @abstract respond to actionsheet selection
 */
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // if not cancel
    actionSheet.delegate = nil;
    if (buttonIndex != [actionSheet cancelButtonIndex]) {
        
        // hide keyboard and reset emoticon button
        [self hideKeyboard];
        
		NSString *actionButtonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
		if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Album", nil)]) {
			[self pressSelectImage];
		}
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Camera", nil)]) {
            [self pressCamera];
		}
        // show letter create controller
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"<create letter message>", nil)]) {
            
            [self prepareToPresentNewView];

            NSString *toName = nil;
            if (![self.cdChat isGroupChat]) {
                toName = [(CDContact *)[self.cdChat.participants anyObject] displayName];
            }
            
            UIImage *dialogBackView = [Utility imageFromUIView:self.view];
            
            LetterController *nextController = [[LetterController alloc] init];
            nextController.letterMode = kLCModeSend;
            nextController.toName = toName;
            nextController.backImage = dialogBackView;
            nextController.delegate = self;
            
            // Create nav controller to present modally
            UINavigationController *navigationController = [[UINavigationController alloc]
                                                            initWithRootViewController:nextController];            
            [AppUtility customizeNavigationController:navigationController];
            
            [self presentModalViewController:navigationController animated:YES];
            //navigationController.delegate = self;
            [navigationController release];
            [nextController release];
            
		}
        // show letter create controller
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"<create location message>", nil)]) {
            
            [self prepareToPresentNewView];
            
            LocationShareController *nextController = [[LocationShareController alloc] init];
            nextController.locationMode = kLSModeShare;
            nextController.delegate = self;
            // Create nav controller to present modally
            UINavigationController *navigationController = [[UINavigationController alloc]
                                                            initWithRootViewController:nextController];            
            [AppUtility customizeNavigationController:navigationController];
            
            [self presentModalViewController:navigationController animated:YES];
            [navigationController release];
            [nextController release];
            
		}
    }
    else {
        DDLogVerbose(@"Match select cancelled");
    }
}

#pragma mark - CLLocationManager 

/*!
 @abstract Location is enabled, so start multi image album
 
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    // release location manager
    [self.locManager stopUpdatingLocation];
    self.locManager.delegate = nil;
    self.locManager = nil;
    
    [self displayPhotoAlbumTypeMulti];
}

/*!
 @abstract Show appropriate album
 
 */
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // release location manager
    [self.locManager stopUpdatingLocation];
    self.locManager.delegate = nil;
    self.locManager = nil;
    
    if ([error code] == kCLErrorDenied) {
        [self displayPhotoAlbumTypeSingle];
    }
    else {
        [self displayPhotoAlbumTypeMulti];
    }
}


#pragma mark - Scroll view methods

/**
 Determine if we should show source indicator at all
 - only show if more than one source present
 
 */
/*- (BOOL)shouldShowSourceByCheckingTableStatus:(BOOL)checkTableStatus tableView:(UITableView *)newTableView {
	
	// only query once to save cycles
	//
	static NSInteger sourceNumber = NSNotFound;
	if (sourceNumber == NSNotFound) {
		sourceNumber = [[AppUtility getABTool] getNumberOfSources];
	}
	
	BOOL showSource = NO;
	if (sourceNumber > 1 ) {
		
		if (checkTableStatus ) {
			if ( newTableView.dragging || newTableView.tracking || newTableView.decelerating ){
				showSource = YES;
			}
		}
		else {
			showSource = YES;
		}
	}
	return showSource;
}*/





/**
 Deselect rows that are selecting after scrolling ends
 */
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	/*[NSThread sleepForTimeInterval:0.2];
	NSIndexPath *selectedIP = [self.tableView indexPathForSelectedRow];
	if (selectedIP) {
		[self.tableView deselectRowAtIndexPath:selectedIP animated:YES];
	}*/
}


/**
 Show source when scrolling begins
 */
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	
    [self.toolBarView resignTextField];
    
	//DDLogVerbose(@"MVC: start dragging");
	//[self showSourceForVisibleCell:YES tableView:(UITableView *)scrollView];
}

/**
 Hides source when dragging is stopped by user
 */
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (!decelerate) {
		//DDLogVerbose(@"MVC: scroll drag stop");
		//[self showSourceForVisibleCell:NO tableView:(UITableView *)scrollView];
	}
	
}
/**
 Hides source when dragging stops from deceleration
 */
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	
	//DDLogVerbose(@"MVC: scroll decelerated");
	//[self showSourceForVisibleCell:NO tableView:(UITableView *)scrollView];
}



#pragma mark - Shake View 


/*!
 @abstract Make sure shake has ended properly
 
 */
- (void)endShakeMainView
{
    
    UIView *mainView = self.view.window;

    // already at rest state, so do nothing
    if (CGAffineTransformIsIdentity(mainView.transform)) {
        return;
    }
    
    
    CGAffineTransform keyBaseT;

    if (self.interfaceOrientation == UIInterfaceOrientationPortrait) {
        keyBaseT = CGAffineTransformIdentity;
    }
    // landscapes need to rotate view and translate it to right orientation and position
    //
    else if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        keyBaseT = CGAffineTransformRotate(CGAffineTransformIdentity, -1.57);
        keyBaseT = CGAffineTransformTranslate(keyBaseT, -80.0, -80.0);
    }
    else { //if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        keyBaseT = CGAffineTransformRotate(CGAffineTransformIdentity, 1.57);
        keyBaseT = CGAffineTransformTranslate(keyBaseT, 80.0, 80.0);
    }
    
    UIWindow *keyView = [self findKeyboardWindow];
    
    DDLogInfo(@"CDC-esmv: ending shake");
    [UIView animateWithDuration:0.13 delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseInOut
                     animations:^{
                         mainView.transform = CGAffineTransformIdentity;
                         keyView.transform = keyBaseT;
                     } completion:NULL];
}


/*!
 @abstract shake dialog view back and forth
 */
- (void)shakeMainView2:(UIView *)mainView keypadView:(UIView *)keypadView
{
    // don't animate if another view is being shown
    // - otherwise next view could be shifted by the shake
    //
    if (self.didPushAnotherView) {
        DDLogInfo(@"CDC-smv2: another view being shown - skip shake");
        return;
    }
    
    if ([self.shakeViewEndTimer isValid]) {
        [self.shakeViewEndTimer invalidate];
    }
    self.shakeViewEndTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(endShakeMainView) userInfo:nil repeats:NO];
    
    CGFloat t = 25.0;
    CGAffineTransform m1;
    CGAffineTransform m2;
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        m1 = CGAffineTransformTranslate(CGAffineTransformIdentity, 0.0, -t);
        m2  = CGAffineTransformTranslate(CGAffineTransformIdentity, 0.0, t);
    }
    else {
        m1 = CGAffineTransformTranslate(CGAffineTransformIdentity, -t, 0.0);
        m2  = CGAffineTransformTranslate(CGAffineTransformIdentity, t, 0.0);
    }
    
    // setup keypad transforms
    
    CGAffineTransform keyBaseT;
    CGAffineTransform k1;
    CGAffineTransform k2;
    
    if (self.interfaceOrientation == UIInterfaceOrientationPortrait) {
        keyBaseT = CGAffineTransformIdentity;
        k1 = m1;
        k2 = m2;
    }
    // landscapes need to rotate view and translate it to right orientation and position
    //
    else if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        keyBaseT = CGAffineTransformRotate(CGAffineTransformIdentity, -1.57);
        keyBaseT = CGAffineTransformTranslate(keyBaseT, -80.0, -80.0);
        k1 = CGAffineTransformTranslate(keyBaseT, t, 0.0);
        k2 = CGAffineTransformTranslate(keyBaseT, -t, 0.0);
    }
    else { //if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        keyBaseT = CGAffineTransformRotate(CGAffineTransformIdentity, 1.57);
        keyBaseT = CGAffineTransformTranslate(keyBaseT, 80.0, 80.0);
        k1 = CGAffineTransformTranslate(keyBaseT, -t, 0.0);
        k2 = CGAffineTransformTranslate(keyBaseT, t, 0.0);
    }
    
    mainView.transform = m1;
    keypadView.transform = k1;
    
    CGFloat duration = 0.13;
    DDLogInfo(@"CDC-smv2: start");
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat
                     animations:^{
                         [UIView setAnimationRepeatCount:2.5];
                         mainView.transform = m2;
                         keypadView.transform = k2;
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             DDLogInfo(@"CDC-smv2: ending");
                             [UIView animateWithDuration:duration delay:0.0
                                                 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseInOut
                                              animations:^{
                                                  mainView.transform = CGAffineTransformIdentity;
                                                  keypadView.transform = keyBaseT;
                                              } completion:NULL];
                         }
                     }];
}




#pragma mark - DialogTableController 

/*!
 @abstract Informs delegate to hide keypad
 
 */
- (void)DialogTableController:(DialogTableController *)controller hideKeypad:(BOOL)hideKeypad {
    
    [self hideKeyboard];
    
}

/*!
 @abstract Informs delegate to show another chat
 
 */
- (void)DialogTableController:(DialogTableController *)controller showChat:(CDChat *)newChat {
    
    // ask chat list to swap in new chat
    //
    if ([self.delegate respondsToSelector:@selector(ChatDialogController:showChat:)]) {
        [self.delegate ChatDialogController:self showChat:newChat];
    }
}

/*!
 @abstract Finds the window that the keyboard is using
 */
- (UIWindow *) findKeyboardWindow {
    
    // Locate non-UIWindow.
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows]) {
        if (![[testWindow class] isEqual:[UIWindow class]]) {
            keyboardWindow = testWindow;
            break;
        }
    }
    
    return keyboardWindow;
    
    /*
    // Locate UIKeyboard.  
    UIView *foundKeyboard = nil;
    for (UIView *possibleKeyboard in [keyboardWindow subviews]) {
        
        // iOS 4 sticks the UIKeyboard inside a UIPeripheralHostView.
        if ([[possibleKeyboard description] hasPrefix:@"<UIPeripheralHostView"]) {
            possibleKeyboard = [[possibleKeyboard subviews] objectAtIndex:0];
        }                                                                                
        
        if ([[possibleKeyboard description] hasPrefix:@"<UIKeyboard"]) {
            foundKeyboard = possibleKeyboard;
            break;
        }
    }
    return foundKeyboard;*/
}  


/*!
 @abstract Informs delegate to shake view
 
 */
- (void)DialogTableController:(DialogTableController *)controller shouldShake:(BOOL)shouldShake {
    
    
    UIWindow *keyView = [self findKeyboardWindow];
   
    [self shakeMainView2:self.view.window keypadView:keyView];
    [Utility vibratePhone];
    
    //[AppUtility shakeViews:[NSArray arrayWithObjects:self.view.window, keyView, nil] isLandscape:self.navigationController.navigationBarHidden?YES:NO];
    //[AppUtility shakeView:[AppUtility getAppDelegate].containerController.view];
    
}

#pragma mark - Image General 


/*!
 @abstract Sends out an image message
 
 */
- (void) sendImage:(UIImage *)sendImage {
    
    UIImage *compressedImage;

    CGSize imageSize = [sendImage size];
    //DDLogVerbose(@"CD-image: h:%f w:%f", imageSize.height, imageSize.width);
    
    // compress image
    // - use scale so we can compress to pixels not just points
    //
    if (imageSize.width*sendImage.scale > kMPParamSendImageWidthMax) {
        // new height scaled proportionally
        //
        CGFloat newHeight = imageSize.height * kMPParamSendImageWidthMax/imageSize.width;
        CGSize newSize = CGSizeMake(kMPParamSendImageWidthMax, newHeight);
        
        compressedImage = [UIImage imageWithImage:sendImage scaledToSize:newSize maintainScale:NO];
    }
    // small image, no need to compress
    else {
        compressedImage = sendImage;
    }
    DDLogVerbose(@"CD-ip: scaled image");
    
    // sent to background to create message
    NSManagedObjectID *chatObjectID = [self.cdChat objectID];
    
    // create a new CD message to add to this chat
    //
    CDMessage *newCDMessage = [CDMessage outCDMessageForChatObjectID:chatObjectID 
                                                         messageType:kCDMessageTypeImage 
                                                                text:nil 
                                                      attachmentData:compressedImage
                                                          shouldSave:YES];
    
    
    //DDLogVerbose(@"CD-ip: create msg");
    
    NSManagedObjectID *objectID = [newCDMessage objectID];
    
    // post notification for scroll view to show new message
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_NEW_MESSAGE_NOTIFICATION object:[NSArray arrayWithObject:objectID]];
    });
    
    // sends this message
    // - require confirmation and progress notification for images
    [[MPChatManager sharedMPChatManager] sendCDMessage:newCDMessage requireSentConfirmation:YES enableAcceptRejectConfirmation:NO];
    
}


#pragma mark - ELCImagePickerControllerDelegate Methods

/*!
 @abstract Finished selecting images to send out
 
 */
- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
	
    //[[AppUtility getAppDelegate].tabBarFacade pressedIndex:kMPTabIndexSetting];
    //[[AppUtility getAppDelegate].tabBarFacade pressedIndex:kMPTabIndexChat];
    
    picker.delegate = nil;
    // dismiss picker
    [self dismissModalViewControllerAnimated:YES];
    
    DDLogVerbose(@"CD-ip: start - info %@", info);
    
    dispatch_queue_t backQ = [AppUtility getBackgroundMOCQueue]; 
    
    dispatch_async(backQ, ^{
    
        for(NSDictionary *dict in info) {
            
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            NSString *mediaType = [dict objectForKey: UIImagePickerControllerMediaType];
            UIImage *originalImage, *editedImage, *imageToSave;
            
            // Handle a still image capture
            if ([mediaType isEqualToString:ALAssetTypePhoto]){   //(CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
                
                editedImage = (UIImage *) [dict objectForKey:
                                           UIImagePickerControllerEditedImage];
                originalImage = (UIImage *) [dict objectForKey:
                                             UIImagePickerControllerOriginalImage];
                
                if (editedImage) {
                    imageToSave = editedImage;
                } else {
                    imageToSave = originalImage;
                }
                
                // create and sent image
                [self sendImage:imageToSave];

            }
            
            
            // Handle a movie capture
            //if (CFStringCompare ((CFStringRef) mediaType, kUTTypeMovie, 0)
            //    == kCFCompareEqualTo) {
            /*if ([mediaType isEqualToString:ALAssetTypeVideo]){
             NSString *moviePath = [[dict objectForKey:
             UIImagePickerControllerMediaURL] path];
             
             if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (moviePath)) {
             UISaveVideoAtPathToSavedPhotosAlbum (
             moviePath, nil, nil, nil);
             }
             }*/
            
            [pool drain];

        }
    
    });
    
    DDLogVerbose(@"CD-ip: Done sending images");
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
    
    picker.delegate = nil;
	[self dismissModalViewControllerAnimated:YES];
}


/*!
 @abstract Inform delegate the location service is not available
 - so start single image selection instead
 */
- (void)elcImagePickerControllerFailedLocationDenied:(ELCImagePickerController *)picker {
    self.viewDidAppearFlags = @"showAlbumSingle";
}



#pragma mark - Image Picker Delegates: Camera photos


// For responding to the user tapping Cancel.
- (void) imagePickerControllerDidCancel: (UIImagePickerController *) picker {
    
    if ([AppUtility getAppDelegate].didLastSessionGetLowMemoryWarning) {
        NSUInteger currentIndex = [[AppUtility getAppDelegate].tabBarFacade currentIndex];
        [[AppUtility getAppDelegate].tabBarFacade pressedIndex:kMPTabIndexSetting];
        [[AppUtility getAppDelegate].tabBarFacade pressedIndex:currentIndex];
    }
    
    picker.delegate = nil;
    [self dismissModalViewControllerAnimated: YES];
}

// For responding to the user accepting a newly-captured picture or movie
- (void) imagePickerController: (UIImagePickerController *) picker
 didFinishPickingMediaWithInfo: (NSDictionary *) info {
    
    // @TEST low memory
    //[[UIApplication sharedApplication] performSelector:@selector(_performMemoryWarning)];
    //[NSThread sleepForTimeInterval:1.0];
    
    if ([AppUtility getAppDelegate].didLastSessionGetLowMemoryWarning) {
        NSUInteger currentIndex = [[AppUtility getAppDelegate].tabBarFacade currentIndex];
        [[AppUtility getAppDelegate].tabBarFacade pressedIndex:kMPTabIndexSetting];
        [[AppUtility getAppDelegate].tabBarFacade pressedIndex:currentIndex];
    }
    
    picker.delegate = nil;
    [self dismissModalViewControllerAnimated: YES];
    
    
    dispatch_queue_t backQ = [AppUtility getBackgroundMOCQueue]; 
    dispatch_async(backQ, ^{
        
        NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
        UIImage *originalImage, *editedImage, *imageToSave;
        
        // Handle a still image capture
        if (CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0)
            == kCFCompareEqualTo) {
            
            editedImage = (UIImage *) [info objectForKey:
                                       UIImagePickerControllerEditedImage];
            originalImage = (UIImage *) [info objectForKey:
                                         UIImagePickerControllerOriginalImage];
            
            if (editedImage) {
                imageToSave = editedImage;
            } else {
                imageToSave = originalImage;
            }
            
            if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
                // save image to album automatically
                UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil);
            }
            
            [self sendImage:imageToSave];
            
            
            // send notification
            // - so tableview can update itself
            //
            // - [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATDIALOGCELL_SEND_TEXT_NOTIFICATION object:nil];
            
        }
        
        // Handle a movie capture
        if (CFStringCompare ((CFStringRef) mediaType, kUTTypeMovie, 0)
            == kCFCompareEqualTo) {
            
            NSString *moviePath = [[info objectForKey:
                                    UIImagePickerControllerMediaURL] path];
            
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (moviePath)) {
                UISaveVideoAtPathToSavedPhotosAlbum (
                                                     moviePath, nil, nil, nil);
            }
        }
        
    });

}

#pragma mark - LetterController

/*!
 @abstract Call when letter creation is complete and ready to send
 - create letter message and send out
 */
- (void)LetterController:(LetterController *)view letterImage:(UIImage *)letterImage letterID:(NSString *)letterID {
    
    
    CDMessage *letterMessage = [CDMessage outCDMessageForChat:self.cdChat 
                                                  messageType:kCDMessageTypeLetter 
                                                         text:nil 
                                               attachmentData:letterImage 
                                                  isMulticast:NO 
                                           multicastParentMID:nil 
                                          multicastToContacts:nil 
                                                dateScheduled:nil 
                                                  hideMessage:NO 
                                                     typeInfo:letterID 
                                                   shouldSave:YES];
    
    // Post notification for scroll view to show new message
    // - must be done before message is sent otherwise a race condition will result
    //   ~ message may be in sent status when notification is received, so will not be added to chat dialog!
    //
    NSManagedObjectID *objectID = [letterMessage objectID];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_NEW_MESSAGE_NOTIFICATION object:[NSArray arrayWithObject:objectID]];
    });
    
    // sends this message
    // - require confirmation and progress notification for images
    [[MPChatManager sharedMPChatManager] sendCDMessage:letterMessage requireSentConfirmation:YES enableAcceptRejectConfirmation:NO];

    
    [NSThread sleepForTimeInterval:5.0];
    
    [self dismissModalViewControllerAnimated:YES];
    

}

#pragma mark - Location Share

/*!
 @abstract Call when user wants to share location
 
 location message:
 @location?id=x&form=A&to=B&text=Latitude, Longitude, Accuracy, Altitude, Time, Speed,Bearing&icon=xxxx...

 */
- (void)LocationShareController:(LocationShareController *)controller shareCoordinate:(CLLocationCoordinate2D)coordinate previewImage:(UIImage *)previewImage {
    
    NSString *textString = [LocationShareController locationMessageTextForCoordinate:coordinate];
    
    CDMessage *locationMessage = [CDMessage outCDMessageForChat:self.cdChat 
                                                  messageType:kCDMessageTypeLocation
                                                         text:textString
                                               attachmentData:previewImage 
                                                  isMulticast:NO 
                                           multicastParentMID:nil 
                                          multicastToContacts:nil 
                                                dateScheduled:nil 
                                                  hideMessage:NO 
                                                     typeInfo:nil 
                                                   shouldSave:YES];
    
    // inform chat view of new message
    //
    NSManagedObjectID *objectID = [locationMessage objectID];
    
    // post notification for scroll view to show new message
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_NEW_MESSAGE_NOTIFICATION object:[NSArray arrayWithObject:objectID]];
    });
    
    // sends this message
    //
    [[MPChatManager sharedMPChatManager] sendCDMessage:locationMessage requireSentConfirmation:YES enableAcceptRejectConfirmation:NO];
    
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark - NavigationController 

/*!
 @abstract forwards nav controller so app delelgate can customize it
 */
- (void)navigationController:(UINavigationController *)navigationController 
      willShowViewController:(UIViewController *)viewController 
					animated:(BOOL)animated {
	
    [[AppUtility getAppDelegate] navigationController:navigationController willShowViewController:viewController animated:animated];
	
}

#pragma mark - Hidden Chat

/*!
 @abstract Informs if this dialog is showing a hidden chat
 
 Use:
 - used to check if hidden chat is showing, if so we should hide it when entering background
 
 */
- (BOOL) isShowingHiddenChat {
    if ([self.cdChat.isHiddenChat boolValue]) {
        return YES;
    }
    return NO;
}

@end
