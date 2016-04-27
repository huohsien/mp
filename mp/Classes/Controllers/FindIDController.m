//
//  FindIDController.m
//  mp
//
//  Created by M Tsai on 11-11-29.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "FindIDController.h"
#import "MPFoundation.h"
#import "MPContactManager.h"
#import "CDContact.h"
#import "CreateIDController.h" // import max min length values



@implementation FindIDController

@synthesize idField;
@synthesize resultView;

@synthesize foundContact;
@synthesize foundHeadshot;

@synthesize imageManager;


- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    idField.delegate = nil;
    imageManager.delegate = nil;
    
    [resultView release];
    [imageManager release];
    [idField release];
    [foundContact release];
    [foundHeadshot release];
    [super dealloc];
    
}
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


#define TEXTFIELD_TAG           18001
#define RESULTS_BACK_TAG        18002
#define POPUP_IMG_TAG           18003
#define HEADSHOT_IMAGE_TAG      18004
#define NAME_LABEL_TAG          18005
#define ADD_BTN_TAG             18006
#define ADDED_LABEL_TAG         18007
#define FIND_BTN_TAG            18008

#define COUNT_TAG               18009
#define CHECKMARK_TAG           18010
#define RESULT_LABEL_TAG        18011


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{

    //CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    self.title = NSLocalizedString(@"Find Friend", @"FindID - title: find friends using M+ID");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];

    // background
    //
    UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    backView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = backView;
    [backView release];            

    
    // intro text
    //
    UILabel *iLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 10.0, 250.0, 14.0)];
    [AppUtility configLabel:iLabel context:kAULabelTypeGrayMicroPlus];
    iLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    iLabel.text = NSLocalizedString(@"Find friend using his/her M+ ID", @"FindID - text: what does this search does");
    [self.view addSubview:iLabel];
    [iLabel release];
    
    
    // textfield background image
    //
    UIImageView *textBackImage = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, 26.0, 245.0, 45.0)];
    textBackImage.image = [Utility resizableImage:[UIImage imageNamed:@"std_icon_textbar.png"] leftCapWidth:9.0 topCapHeight:22.0];
    textBackImage.userInteractionEnabled = YES;
    [self.view addSubview:textBackImage];
    
    // textfield
    // 
    UITextField *tField = [[UITextField alloc] initWithFrame:CGRectMake(10.0, 10.0, 225.0, 25.0)];
    tField.placeholder = NSLocalizedString(@"Enter ID you want to find", @"FindID - text placeholder: ask users to enter a M+ ID that they want");
    [AppUtility configTextField:tField context:kAUTextFieldTypeBasic];
    tField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tField.delegate = self;
    tField.tag = TEXTFIELD_TAG;
    [textBackImage addSubview:tField];
    self.idField = tField;
    [self.idField becomeFirstResponder];
    [tField release];
    [textBackImage release];

    
    // find button
    //
    UIButton *submitButton = [[UIButton alloc] initWithFrame:CGRectMake(255.0, 26.0, 60.0, 45.0)];
    [AppUtility configButton:submitButton context:kAUButtonTypeGreen5];
    [submitButton addTarget:self action:@selector(pressSubmit:) forControlEvents:UIControlEventTouchUpInside];
    [submitButton setTitle:NSLocalizedString(@"Find", @"FindID - button: start searching for ID") forState:UIControlStateNormal];
    submitButton.enabled = NO;
    submitButton.tag = FIND_BTN_TAG;
    [self.view addSubview:submitButton];
    [submitButton release];
    
    
    // char count
    //
    UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(5.0, 71.0, 240.0, 20.0)];
    [AppUtility configLabel:countLabel context:kAULabelTypeBackgroundText];
    countLabel.textAlignment = UITextAlignmentRight;
    countLabel.text = [NSString stringWithFormat:@"%d/%d", [self.idField.text length], kMPParamIDLengthMax];
    countLabel.tag = COUNT_TAG;
    [self.view addSubview:countLabel];
    [countLabel release];
    
    // add observers
    
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processSearch:) name:MP_HTTPCENTER_SEARCHID_NOTIFICATION object:nil];    

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processGetUserInfo:) name:MP_HTTPCENTER_GETUSERINFO_NOTIFICATION object:nil];
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{

    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    DDLogInfo(@"FIC-vwa");
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Views

/*!
 @abstract Create result view
 */
- (UIView *)generateResultView {
    
    // **** Results view - hidden at first ****
    //
    UIImage *blackImage = [Utility resizableImage:[UIImage imageNamed:@"std_icon_background_black_transparent.png"] leftCapWidth:1.0 topCapHeight:1.0];
    UIImageView *resultsBackView = [[[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
    resultsBackView.image = blackImage;
    resultsBackView.userInteractionEnabled = YES;
    resultsBackView.hidden = YES;
    resultsBackView.opaque = NO;
    resultsBackView.alpha = 1.0;
    resultsBackView.tag = RESULTS_BACK_TAG;
    
    // Tap background to dismiss
    //
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(pressClose:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.delegate = self;
    [resultsBackView addGestureRecognizer:tapRecognizer];
    [tapRecognizer release];
    
    
    // popup background
    //
    UIImageView *popupView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_icon_bk_popup.png"]];
    popupView.userInteractionEnabled = YES;
    popupView.frame = CGRectMake(40.0, 95.0+45.0, 240.0, 200.0);
    popupView.tag = POPUP_IMG_TAG;
    [resultsBackView addSubview:popupView];
    
    // close view
    // - dismisses view    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(200.0, 0.0, 40.0, 40.0)];
    closeButton.contentMode = UIViewContentModeCenter;
    [closeButton setImage:[UIImage imageNamed:@"std_icon_delete2_nor.png"] forState:UIControlStateNormal];
    [closeButton setImage:[UIImage imageNamed:@"std_icon_delete2_prs.png"] forState:UIControlStateHighlighted];
    closeButton.backgroundColor = [UIColor clearColor];
    [closeButton addTarget:self action:@selector(pressClose:) forControlEvents:UIControlEventTouchUpInside];
    [popupView addSubview:closeButton];
    [closeButton release];
    
    // default photo button
    //
    UIImageView *frameView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"friend_icon_popup_frame.png"]];
    frameView.frame = CGRectMake(65.0, 10.0, 105.0, 105.0);
    [popupView addSubview:frameView];
    
    // photo image view
    //
    UIImageView *headShotView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"friend_icon_popup_bear.png"]];
    headShotView.frame = CGRectMake(11.0, 11.0, 85.0, 85.0);
    headShotView.tag = HEADSHOT_IMAGE_TAG;
    [frameView addSubview:headShotView];
    [headShotView release];
    [frameView release];
    
    // Name
    //
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 117.0, 210.0, 20.0)];
    [AppUtility configLabel:nameLabel context:kAULabelTypeBlackStandardPlus];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.textAlignment = UITextAlignmentCenter;
    nameLabel.tag = NAME_LABEL_TAG;
    [popupView addSubview:nameLabel];
    [nameLabel release];
    
    // Check image
    // - is underneath and represent this person is already a friend
    UIImage *checkImage = [UIImage imageNamed:@"std_icon_checked.png"];
    CGSize checkSize = [checkImage size];
    UIImageView *checkImageView = [[UIImageView alloc] initWithImage:checkImage];
    checkImageView.frame = CGRectMake(0.0, 152.0, checkSize.width, checkSize.height);
    checkImageView.tag = CHECKMARK_TAG;
    [popupView addSubview:checkImageView];
    [checkImageView release];
    
    UILabel *resultLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 152.0, 210.0, 20.0)];
    [AppUtility configLabel:resultLabel context:kAULabelTypeGreenStandardPlus];
    resultLabel.backgroundColor = [UIColor clearColor];
    resultLabel.textAlignment = UITextAlignmentCenter;
    resultLabel.tag = RESULT_LABEL_TAG;
    [popupView addSubview:resultLabel];
    [resultLabel release];
    
    
    // Add button
    //
    UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(82.5, 145.0, 75.0, 35.0)];
    [AppUtility configButton:addButton context:kAUButtonTypeGreen3];
    [addButton addTarget:self action:@selector(pressAdd:) forControlEvents:UIControlEventTouchUpInside];
    [addButton setTitle:NSLocalizedString(@"Add", @"FindID - button: add a new friend") forState:UIControlStateNormal];
    addButton.tag = ADD_BTN_TAG;
    [popupView addSubview:addButton];
    [addButton release];
    [popupView release];
    
    // Added Label - hidden at first until contact is added
    //
    /*UILabel *addedLabel = [[UILabel alloc] initWithFrame:CGRectMake(120.0, 80.0, 100.0, 20.0)];
     [AppUtility configLabel:addedLabel context:kAULabelTypeBackgroundText];
     addedLabel.hidden = YES;
     addedLabel.tag = ADDED_LABEL_TAG;
     [resultsBackImage addSubview:addedLabel];
     [addedLabel release];
     [resultsBackImage release];*/
    
    return resultsBackView;
}



#pragma mark - UIGestureRecognizer

/*!
 @abstract Determine is touch should be received
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    // don't accept is the touch is under the toolbar
    // - other wise we will dismiss toolbar instead recognize button press
    
    CGPoint pointInView = [touch locationInView:gestureRecognizer.view];
    CGRect popFrame = CGRectMake(40.0, 95.0+45.0, 240.0, 200.0);
    
    if ( [gestureRecognizer isMemberOfClass:[UITapGestureRecognizer class]] ) {
        if ( CGRectContainsPoint(popFrame, pointInView) ) {
            return NO;
        } 
    }
    return YES;
}



#pragma mark - Button


/*!
 @abstract has special characters
 */
- (BOOL)hasSpecialCharacters:(NSString *)testString {
    
    BOOL hasSC = YES;
    
    // can't have any symbols
    NSArray *symbolParts = [testString componentsSeparatedByCharactersInSet:[NSCharacterSet symbolCharacterSet]];
    NSArray *punctParts = [testString componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
    
    if ([symbolParts count] == 1 && [punctParts count] == 1) {
        hasSC = NO;
    }
    return hasSC;
}


/*!
 @abstract Check if M+ ID is valid
 - 5 characters
 - no special chars
 
 */
- (BOOL)isIDValid:(NSString *)testID{
    
    BOOL isValid = NO;
    
    NSInteger nameLen = [testID length];
    
    if (nameLen >= kMPParamIDLengthMin && 
        nameLen <= kMPParamIDLengthMax && 
        ![self hasSpecialCharacters:testID]
        ) 
    {
        isValid = YES;
    }
    return isValid;
}


/*!
 @abstract pressed submit button - checks for duplicates
 */
- (void)pressSubmit:(id) sender {
    
    // check if valid
    //
    if ([self isIDValid:self.idField.text]) {        

        [AppUtility startActivityIndicator];
        UITextField *tField = (UITextField *) [self.view viewWithTag:TEXTFIELD_TAG];
        [[MPHTTPCenter sharedMPHTTPCenter] searchID:[Utility trimWhiteSpace:tField.text]];
        
    }
    else {
        
        NSString *alertTitle = NSLocalizedString(@"Invalid ID", @"FindID - alert title");
        NSString *alertMessage = NSLocalizedString(@"ID cannot contain any special characters.",@"FindID - alert: ID is invalid");
        [Utility showAlertViewWithTitle:alertTitle message:alertMessage];
        
    }
}

/*!
 @abstract pressed add - add this found user as a friend!
 
 Submit presence query server first
 
 */
- (void)pressAdd:(id) sender {
    
    [AppUtility startActivityIndicator];
    
    // userID to tag this request
    // - so we can identify if response is for us
    [[MPHTTPCenter sharedMPHTTPCenter] getUserInformation:[NSArray arrayWithObject:self.foundContact.userID] action:kMPHCQueryTagAdd idTag:self.foundContact.userID itemType:kMPHCItemTypeUserID];
}

/*!
 @abstract Hides result view
  
 */
- (void)pressClose:(id) sender {
    
    // show search results
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionAllowUserInteraction
     
                     animations:^{
                         self.resultView.alpha = 0.0;
                     }
     
                     completion:^(BOOL completed){
                         [self.resultView removeFromSuperview];
                         self.resultView = nil;
                     }];
    
}

#pragma mark - UIAlertViewDelegate Methods



#pragma mark - Handle Response


/*!
 @abstract process get info command
 
 - get the user's Nickname to display
 
 */
- (void) processSearchPresence:(MPPresence *)presence {
    
    // create a contact for the presence
    //
    self.foundContact = [CDContact contactForPresence:presence create:YES addAsFriend:NO onlyAddIfCreated:NO updateBadgeCount:NO updatePhoneNumber:YES save:YES];
    
    if (self.foundContact) {
        
        // create the result view
        self.resultView = [self generateResultView];
        

        // create IM if it does not exists
        if (!self.imageManager) {
            MPImageManager *newIM = [[MPImageManager alloc] init];
            newIM.delegate = self;
            self.imageManager = newIM;
            [newIM release];
        }
        
        self.foundHeadshot = [self.imageManager getImageForObject:self.foundContact context:kMPImageContextList];
        
        // show search results
        UILabel *nameLabel = (UILabel *)[self.resultView viewWithTag:NAME_LABEL_TAG];
        UIButton *addButton = (UIButton *)[self.resultView viewWithTag:ADD_BTN_TAG];
        UIImageView *headView = (UIImageView *)[self.resultView viewWithTag:HEADSHOT_IMAGE_TAG];  
        
        UILabel *resultLabel = (UILabel *)[self.resultView viewWithTag:RESULT_LABEL_TAG];
        UIImageView *checkView = (UIImageView *)[self.resultView viewWithTag:CHECKMARK_TAG];   
        
        resultView.hidden = NO;
        if (self.foundHeadshot) {
            headView.image = self.foundHeadshot;
        }
        nameLabel.text = [self.foundContact displayName];
        
        // if not friend, show add button
        if ([self.foundContact isFriend]) {
            addButton.hidden = YES;
            resultLabel.hidden = NO;
            checkView.hidden = NO;
            
            resultLabel.text = NSLocalizedString(@"Added", @"FindID - text: ID is already a friend");
            CGRect resFrame = resultLabel.frame;
            CGSize resSize = [resultLabel sizeThatFits:resFrame.size];
            CGPoint resCenter = resultLabel.center;
            CGSize checkSize = checkView.frame.size;
            
            CGRect checkFrame = CGRectMake(resCenter.x - resSize.width/2.0 - checkSize.width, 
                                           resCenter.y - checkSize.height/2.0 - 3.0, 
                                           checkSize.width, checkSize.height);
            checkView.frame = checkFrame;
            
        }
        else if ([self.foundContact isMySelf]) {
            addButton.hidden = YES;
            resultLabel.hidden = NO;
            checkView.hidden = YES;
            
            resultLabel.text = NSLocalizedString(@"My M+ ID", @"FindID - text: This is your own M+ ID");
        }
        else {
            addButton.hidden = NO;
            resultLabel.hidden = YES;
            checkView.hidden = YES;
        }
        
		UIView *containerView = [[[AppUtility getAppDelegate].containerController view] window];
		[containerView addSubview:self.resultView];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.6];
        
        self.resultView.alpha = 1.0;
        
        [UIView commitAnimations];
    }
}


/*!
 @abstract process search command
 
 - get user ID, then query for it's presence data & headshot
 
 */
- (void) processSearch:(NSNotification *)notification {
    
    // got results, so stop
    [AppUtility stopActivityIndicator];
    
    NSDictionary *responseD = [notification object];
    
    NSString *presenceText = [responseD valueForKey:@"text"];
    MPPresence *presence = [[MPPresence alloc] initWithPresenceString:presenceText];
    
    // found user, so go query for user info
    if ([AppUtility isUserIDValid:presence.aUserID]) {
    
        // dismiss keyboard
        [self.idField resignFirstResponder];
        [self processSearchPresence:presence];
        
    }
    // no user found!
    else {
        //[AppUtility stopActivityIndicator:self.navigationController];
        
        NSString *alertTitle = NSLocalizedString(@"No Results", @"FindID - alert title:");
        NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"ID does not exist. Enter a different ID.", @"FindID - alert: inform that search returned no results"), @""];
        [Utility showAlertViewWithTitle:alertTitle message:alertMessage];
        
    }
    [presence release];
}


- (void) showFailureAlert {
    
    NSString *alertTitle = NSLocalizedString(@"Add Friend", @"FindID - alert title:");
    NSString *alertMessage = NSLocalizedString(@"Add friend failed. Try again later.", @"FindID - alert: Inform of failure");
    [Utility showAlertViewWithTitle:alertTitle message:alertMessage];
    
}

/*!
 @abstract Did add friend process succeed for the M+ ID friend?

 If successful, then add this person as a friend in the DB, update new friend badge
 
 // notification object
 //
 NSMutableDictionary *newD = [[NSMutableDictionary alloc] initWithDictionary:responseDictionary];
 [newD setValue:presenceArray forKey:@"array"];
 
 */
- (void) processGetUserInfo:(NSNotification *)notification {
    
    [AppUtility stopActivityIndicator];

    BOOL didAdd = [MPContactManager processAddFriendNotification:notification contactToAdd:self.foundContact];
    
    if (didAdd) {
        // hide add button & show results
        //
        UIButton *addButton = (UIButton *)[self.resultView viewWithTag:ADD_BTN_TAG];
        UILabel *resultLabel = (UILabel *)[self.resultView viewWithTag:RESULT_LABEL_TAG];
        UIImageView *checkView = (UIImageView *)[self.resultView viewWithTag:CHECKMARK_TAG];   
        
        resultLabel.text = NSLocalizedString(@"Added", @"FindID - text: ID is already a friend");
        CGRect resFrame = resultLabel.frame;
        CGSize resSize = [resultLabel sizeThatFits:resFrame.size];
        CGPoint resCenter = resultLabel.center;
        CGSize checkSize = checkView.frame.size;
        
        CGRect checkFrame = CGRectMake(resCenter.x - resSize.width/2.0 - 3.0 - checkSize.width, 
                                       resCenter.y - checkSize.height/2.0, 
                                       checkSize.width, checkSize.height);
        checkView.frame = checkFrame;
        resultLabel.hidden = NO;
        resultLabel.alpha = 0.0;
        checkView.hidden = NO;
        checkView.alpha = 0.0;
        
        [UIView animateWithDuration:kMPParamAnimationStdDuration
                         animations:^{
                         
                             addButton.alpha = 0.0;
                             resultLabel.alpha = 1.0;
                             checkView.alpha = 1.0;
                         
                         }];
    }
}



#pragma mark - Image 

/*!
 @abstract Called when data has completed loading and is ready to use.
 
 - find my cell and update the image!
 
 */
- (void)MPImageManager:(MPImageManager *)imageManager finishLoadingImage:(UIImage *)image{
    
    self.foundHeadshot = image;    
    
    // only replace if headshot was found
    if (self.foundHeadshot) {
        UIImageView *headView = (UIImageView *)[self.view viewWithTag:HEADSHOT_IMAGE_TAG];
        headView.image = self.foundHeadshot;
    }
}



#pragma mark - TextViewDelegate


/*!
 @abstract called whenever text if modified
 */
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {  
    
    BOOL shouldChange = YES;
    
    // the preview string itself
    NSString *previewString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    // number of characters
    NSInteger previewCharCount = [previewString length]; // [textField.text length] + [string length] - range.length;
    NSInteger currentCharCount = [textField.text length];
    NSString *charString = nil;
    NSString *countMessage = nil;
    
    
    UILabel *countLabel = (UILabel *)[self.view viewWithTag:COUNT_TAG];
    
    NSString *message = @"";
    
    // if at max, just warn so independent
    //
    if (previewCharCount == kMPParamIDLengthMax) {
        message = NSLocalizedString(@"Reached limit", @"FindID - text: reached max length of name");
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
    }
    
    // over max, don't change
    if (previewCharCount > kMPParamIDLengthMax) {
        // don't go over max
        shouldChange = NO;
    }
    else if ([self hasSpecialCharacters:previewString]) {
        message = NSLocalizedString(@"Special characters not allowed", @"FindID - text: warn about adding special characters");
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
        shouldChange = NO;
    }
    // if less than min, 
    else if (previewCharCount < kMPParamIDLengthMin) {
        message = [NSString stringWithFormat:NSLocalizedString(@"Min %d characters", @"FindID - text: has not surpassed minimum"), kMPParamIDLengthMin];
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
    }
    // ok otherwise
    //
    else {
        countLabel.textColor = [AppUtility colorForContext:kAUColorTypeBackgroundText];
    }
    
    // if change, then upate message - otherwise we don't need to
    if (shouldChange) {
        charString = [NSString stringWithFormat:@"%d/%d", previewCharCount, kMPParamIDLengthMax];
        
        UIButton *submitB = (UIButton *)[self.view viewWithTag:FIND_BTN_TAG];
                
        // only if min char and format is valid, enable done button
        if (previewCharCount > 2 && [self isIDValid:previewString]) {
            submitB.enabled = YES;
        }
        else {
            submitB.enabled = NO;
        }
    }
    else {
        charString = [NSString stringWithFormat:@"%d/%d", currentCharCount, kMPParamIDLengthMax];
        
        // if no change allowed and already at the max - show red text
        if ([textField.text length] == kMPParamIDLengthMax) {
            message = NSLocalizedString(@"Reached limit", @"Name - text: reached max length of name");
            countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
        }
    }
    
    countMessage = [NSString stringWithFormat:@"%@ %@", message, charString];
    countLabel.text = countMessage;

    // if increase but not at max.. this should not happen unless paste lots of text
    
    return shouldChange;
}

/*
 @abstract When clear button is tapped
 */
- (BOOL)textFieldShouldClear:(UITextField *)textField {
    
    UILabel *countLabel = (UILabel *)[self.view viewWithTag:COUNT_TAG];
    NSString *charString = [NSString stringWithFormat:@"0/%d", kMPParamIDLengthMax];
    countLabel.text = charString;
    
    UIButton *submitB = (UIButton *)[self.view viewWithTag:FIND_BTN_TAG];
    submitB.enabled = NO;
    
    return YES;
}


@end
