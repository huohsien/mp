//
//  TextEmoticonEditController.m
//  mp
//
//  Created by Min Tsai on 1/14/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "ComposerController.h"
#import "MPFoundation.h"
#import "MPResourceCenter.h"
#import "CDResource.h"
#import "TKImageLabel.h"
#import "StickerButton.h"
#import "CDContact.h"

CGFloat const kTEKeypadBtnWidth = 90.0;
CGFloat const kTEKeypadBtnHeight = 35.0;

CGFloat const kTEKeypadHeight = 216.0;


CGFloat const kTEStickerSize = 148.0;
CGFloat const kTEImageSizeMax = 225.0;

@interface  ComposerController (Private)
- (void)setKeypadForIndex:(NSInteger)tabIndex;
- (void)setToText;
- (void)registerForKeyboardNotifications;
- (void)updateCharacterCount:(NSString *)newText;
- (void)updateDate;
@end


@implementation ComposerController

@synthesize delegate;
@synthesize tempText;
@synthesize characterLimitMin;
@synthesize characterLimitMax;
@synthesize tabButtons;

@synthesize textView;
@synthesize emoticonKeypad;

@synthesize toContacts;
@synthesize sendImage;
@synthesize editMode;

@synthesize letterImage;
@synthesize letterID;

@synthesize locationText;
@synthesize locationImage;

@synthesize sendDate;
@synthesize datePicker;
@synthesize dateActionSheet;

@synthesize defaultTimeSinceNow;
@synthesize minimumTimeSinceNow;
@synthesize uiMinimumTimeSinceNow;

@synthesize saveButtonTitle;

- (void)dealloc {
    textView.delegate = nil;
    emoticonKeypad.delegate = nil;
    
    [locationImage release];
    [locationText release];
    
    [letterImage release];
    [letterID release];
    
    [saveButtonTitle release];
    [toContacts release];
    [sendImage release];
    [textView release];
    [emoticonKeypad release];
    [tabButtons release];
    [tempText release];

    [sendDate release];
    [datePicker release];
    [dateActionSheet release];
    
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

#define TEXTVIEW_TAG        15001
#define COUNT_TAG           15002
#define TEXTKP_BTN_TAG      15003
#define EMOTICONKP_BTN_TAG  15004

#define TO_BTN_TAG          16001
#define TO_NUMBER_BTN_TAG   16002
#define MSG_LABEL_TAG       16003
#define STICKER_TAG         16004
#define DATE_BTN_TAG        16005


/*!
 @abstract Gets the height of this view
 */
- (CGFloat) viewHeight {
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];

    if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
        return appFrame.size.height - kMPParamNavigationBarHeight - kMPParamTabBarHeight;
    }
    else {
        return appFrame.size.height - kMPParamNavigationBarHeight;
    }
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    //self.title = NSLocalizedString(@"Edit Status", @"StatusEdit - title: view to edit status message");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    // hides toolbar - if select controller was show before hand
    self.navigationController.toolbarHidden = YES;
    self.navigationItem.hidesBackButton = YES;
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];

    CGFloat viewHeight = [self viewHeight];
    
    // background
    //
    UIScrollView *setupView = [[UIScrollView alloc] initWithFrame:appFrame];
    setupView.scrollEnabled = YES;
    if (self.editMode == kCCEditModeSticker) {
        setupView.contentSize=CGSizeMake(appFrame.size.width, viewHeight + kTEKeypadHeight);
    }
    else {
        setupView.contentSize=CGSizeMake(appFrame.size.width, viewHeight);
    }
    setupView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = setupView;
    [setupView release];
    
    CGFloat startYOffset = 0.0;
    
    // add to contacts
    if (self.toContacts) {
                
        // To label
        UILabel *toLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 9.0, 80.0, 14.0)];
        [AppUtility configLabel:toLabel context:kAULabelTypeGrayMicroPlus];
        toLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
        toLabel.text = NSLocalizedString(@"To:", @"CreateScheduled - text: To which friends is scheduled messgae for");
        [self.view addSubview:toLabel];
        [toLabel release];
        
        
        // To button
        UIButton *toButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, 26.0, 310.0, 45.0)];
        [AppUtility configButton:toButton context:kAUButtonTypeTextEditBar];
        toButton.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
        [toButton addTarget:self action:@selector(pressTo:) forControlEvents:UIControlEventTouchUpInside];
        toButton.tag = TO_BTN_TAG;
        [self.view addSubview:toButton];
        
        startYOffset = toButton.frame.origin.y + toButton.frame.size.height;
        
        // add blue number indicator
        TKImageLabel *blueBadge = [[TKImageLabel alloc] initWithFrame:CGRectMake(271.0, 8.0, 30.0, 30.0)];
        blueBadge.backgroundImage = [Utility resizableImage:[UIImage imageNamed:@"std_icon_badge_bl.png"] leftCapWidth:14.0 topCapHeight:14.0];
        blueBadge.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
        blueBadge.textColor = [UIColor whiteColor];
        blueBadge.textEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
        blueBadge.backgroundColor = [UIColor clearColor];
        blueBadge.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
        blueBadge.tag = TO_NUMBER_BTN_TAG;
        [blueBadge setText:[NSString stringWithFormat:@"%d", [self.toContacts count]]];
        [toButton addSubview:blueBadge];
        [blueBadge release];
        [toButton release];
        
        [self setToText]; // sets to text
        
    }
    
    // if default date is defined
    // - allow time/date editing
    //
    if (self.defaultTimeSinceNow) {
        // Date label
        UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, startYOffset + 7.0, 80.0, 14.0)];
        [AppUtility configLabel:dateLabel context:kAULabelTypeGrayMicroPlus];
        dateLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
        dateLabel.text = NSLocalizedString(@"Date/Time:", @"CreateScheduled - text: When message should be sent for");
        [self.view addSubview:dateLabel];
        [dateLabel release];
        
        
        // Date Button
        UIButton *dateButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, startYOffset + 24.0, 310.0, 45.0)];
        [AppUtility configButton:dateButton context:kAUButtonTypeTextEditBar];
        dateButton.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
        [dateButton addTarget:self action:@selector(pressDate:) forControlEvents:UIControlEventTouchUpInside];
        dateButton.tag = DATE_BTN_TAG;
        [self.view addSubview:dateButton];
        
        startYOffset = dateButton.frame.origin.y + dateButton.frame.size.height;
        [dateButton release];
        self.sendDate = [NSDate dateWithTimeIntervalSinceNow:self.defaultTimeSinceNow];
        // adds default date text to button
        [self updateDate];
    }

    
    
    // Message label
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, startYOffset + 7.0, 80.0, 14.0)];
    [AppUtility configLabel:messageLabel context:kAULabelTypeGrayMicroPlus];
    messageLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    messageLabel.text = NSLocalizedString(@"Message:", @"CreateScheduled - text: message text");
    messageLabel.tag = MSG_LABEL_TAG;
    [self.view addSubview:messageLabel];
    [messageLabel release];
    
    
    // for text messages
    if (self.editMode == kCCEditModeText || self.editMode == kCCEditModeBasic) {
        
        [self registerForKeyboardNotifications];
        
        // textfield background image
        //
        UIImageView *textBackImage = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, startYOffset + 24.0, 310.0, 115.0)];
        textBackImage.image = [Utility resizableImage:[UIImage imageNamed:@"std_icon_textbar.png"] leftCapWidth:9.0 topCapHeight:22.0];
        textBackImage.userInteractionEnabled = YES;
        [self.view addSubview:textBackImage];
        
        
        // create text view for message
        //
        UITextView *newTextView = [[UITextView alloc] initWithFrame:CGRectMake(5.0, 5.0, 300.0, 105.0)];
        //[newTextView becomeFirstResponder];
        newTextView.textColor = [UIColor blackColor];
        newTextView.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
        newTextView.backgroundColor = [UIColor whiteColor];
        newTextView.delegate = self;
        newTextView.text = self.tempText;
        newTextView.enablesReturnKeyAutomatically = NO;
        newTextView.tag = TEXTVIEW_TAG;
        [textBackImage addSubview:newTextView];
        CGFloat textViewBottom = textBackImage.frame.origin.y + textBackImage.frame.size.height;
        [textBackImage release];
        self.textView = newTextView;
        [newTextView release];
        
        
        if (self.characterLimitMax > 0 || self.characterLimitMin > 0) {
            // char count
            //
            UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(appFrame.size.width - 170.0, textViewBottom + 5.0, 160.0, 20.0)];
            [AppUtility configLabel:countLabel context:kAULabelTypeBackgroundText];
            countLabel.textAlignment = UITextAlignmentRight;
            //countLabel.text = [NSString stringWithFormat:@"%d/%d", [self.tempText length], self.characterLimitMax];
            countLabel.tag = COUNT_TAG;
            [self.view addSubview:countLabel];
            [countLabel release];
            [self updateCharacterCount:self.textView.text];
        }
        
        CGRect tFrame = CGRectMake(appFrame.size.width/2.0-kTEKeypadBtnWidth, textViewBottom + 15.0, kTEKeypadBtnWidth, kTEKeypadBtnHeight);
        CGRect eFrame = CGRectMake(appFrame.size.width/2.0, textViewBottom + 15.0, kTEKeypadBtnWidth, kTEKeypadBtnHeight);
        
        // add emoticon and keypad button
        //
        TKTabButton *textButton = [[TKTabButton alloc] initWithFrame:tFrame normalImageFilename:@"std_btn_keyboard_nor.png" selectedImageFilename:@"std_btn_keyboard_hl.png" normalBackgroundImageFilename:nil selectedBackgroundImageFilename:nil];
        textButton.delegate = self;
        textButton.tag = TEXTKP_BTN_TAG;
        [self.view addSubview:textButton];
        
        TKTabButton *emoticonButton = [[TKTabButton alloc] initWithFrame:eFrame normalImageFilename:@"std_btn_emoti_nor.png" selectedImageFilename:@"std_btn_emoti_hl.png" normalBackgroundImageFilename:nil selectedBackgroundImageFilename:nil];
        emoticonButton.delegate = self;
        emoticonButton.tag = EMOTICONKP_BTN_TAG;
        [self.view addSubview:emoticonButton];
        
        self.tabButtons = [NSArray arrayWithObjects:textButton, emoticonButton, nil];
        [textButton setImagePressed:YES];
        [textButton release];
        [emoticonButton release];
        
        // show keypad immediately
        //[self setKeypadForIndex:0];
    }
    else if (self.editMode == kCCEditModeSticker) {
        
        // set inset to push the bottom of the view up
        /*UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, self.emoticonKeypad.frame.size.height, 0.0);
         [(UIScrollView *)self.view setContentInset:contentInsets];
         [(UIScrollView *)self.view setScrollIndicatorInsets:contentInsets];*/
        
        CGRect bounds = self.view.bounds;
        
        // scroll to show message view and controls
        UIView *messageLabel = [self.view viewWithTag:MSG_LABEL_TAG];
        CGPoint scrollPoint = CGPointMake(0.0, messageLabel.frame.origin.y - 5.0);
        
        [(UIScrollView *)self.view setContentOffset:scrollPoint animated:NO];
        [(UIScrollView *)self.view setScrollEnabled:NO]; // freeze scrolling
        
        // add sticker image view
        CGRect stickerRect = CGRectMake( (bounds.size.width - kTEStickerSize)/2.0, messageLabel.frame.origin.y + (bounds.size.height - kTEKeypadHeight - kTEStickerSize - 44.0)/2.0, kTEStickerSize, kTEStickerSize);
        StickerButton *stickerButton = [[StickerButton alloc] initWithFrame:stickerRect resource:nil];
        stickerButton.backgroundColor = [UIColor clearColor];
        [stickerButton setTitle:NSLocalizedString(@"Select Sticker", @"CreateSchedule - text: tell users to select a sticker to send") forState:UIControlStateNormal];
        stickerButton.tag = STICKER_TAG;
        [self.view addSubview:stickerButton];
        [stickerButton release];
        
        // show emoticon keypad
        CGRect kpRect = CGRectMake(0.0, scrollPoint.y + bounds.size.height - kTEKeypadHeight - 44.0, 320.0, 260.0);
        
        if (!self.emoticonKeypad) {
            EmoticonKeypad *newKP = [[EmoticonKeypad alloc] initWithFrame:kpRect displayMode:kEKModeDefault];
            newKP.delegate = self;
            newKP.autoresizingMask = UIViewAutoresizingNone;
            self.emoticonKeypad = newKP;
            [self.emoticonKeypad setMode:kEKModeHideEmoticonPetPhrase];
            [newKP release];
            
            /*
            self.emoticonKeypad = [EmoticonKeypad sharedEmoticonKeypad];
            self.emoticonKeypad.delegate = self;
            //[self.emoticonKeypad setFrameOrigin:CGPointMake(0.0, scrollPoint.y + bounds.size.height - kTEKeypadHeight - 44.0)];
            self.emoticonKeypad.frame = kpRect;
            [self.emoticonKeypad setMode:kEKModeHideEmoticonPetPhrase];
            */
            
            // set to first sticker set
            [self.emoticonKeypad setKeypadForIndex:2];
            
        }
        [self.view addSubview:self.emoticonKeypad];
        
        //CGRect testFrame = self.emoticonKeypad.frame;
        
        
    }
    else if (self.editMode == kCCEditModeImage) {
        // do nothing
    }
    else if (self.editMode == kCCEditModeLetter) {
                
    }
    
    /*
    
    // textfield background image
    //
    UIImageView *textBackImage = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, 5.0, 310.0, 90.0)];
    textBackImage.image = [Utility resizableImage:[UIImage imageNamed:@"std_icon_textbar.png"] leftCapWidth:9.0 topCapHeight:22.0];
    textBackImage.userInteractionEnabled = YES;
    [self.view addSubview:textBackImage];
    
    
    // create text view for message
    //
    UITextView *newTextView = [[UITextView alloc] initWithFrame:CGRectMake(5.0, 5.0, 300.0, 80.0)];
    //[newTextView becomeFirstResponder];
    newTextView.textColor = [UIColor blackColor];
    newTextView.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
    newTextView.backgroundColor = [UIColor whiteColor];
    newTextView.delegate = self;
    newTextView.text = self.tempText;
    newTextView.tag = TEXTVIEW_TAG;
    [textBackImage addSubview:newTextView];
    [textBackImage release];
    self.textView = newTextView;
    [newTextView release];
    
    if (self.characterLimitMax > 0 || self.characterLimitMin > 0) {
        // char count
        //
        UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(appFrame.size.width - 170.0, 95.0, 160.0, 20.0)];
        [AppUtility configLabel:countLabel context:kAULabelTypeBackgroundText];
        countLabel.textAlignment = UITextAlignmentRight;
        countLabel.text = [NSString stringWithFormat:@"%d/%d", [self.tempText length], self.characterLimitMax];
        countLabel.tag = COUNT_TAG;
        [self.view addSubview:countLabel];
        [countLabel release];
    }
    
    CGRect tFrame = CGRectMake(appFrame.size.width/2.0-kTEKeypadBtnWidth, 115.0, kTEKeypadBtnWidth, kTEKeypadBtnHeight);
    CGRect eFrame = CGRectMake(appFrame.size.width/2.0, 115.0, kTEKeypadBtnWidth, kTEKeypadBtnHeight);

    // add emoticon and keypad button
    //
    TKTabButton *textButton = [[TKTabButton alloc] initWithFrame:tFrame normalImageFilename:@"std_btn_keyboard_nor.png" selectedImageFilename:@"std_btn_keyboard_hl.png" normalBackgroundImageFilename:nil selectedBackgroundImageFilename:nil];
    textButton.delegate = self;
    textButton.tag = TEXTKP_BTN_TAG;
    [self.view addSubview:textButton];
    
    TKTabButton *emoticonButton = [[TKTabButton alloc] initWithFrame:eFrame normalImageFilename:@"std_btn_emoti_nor.png" selectedImageFilename:@"std_btn_emoti_hl.png" normalBackgroundImageFilename:nil selectedBackgroundImageFilename:nil];
    emoticonButton.delegate = self;
    emoticonButton.tag = EMOTICONKP_BTN_TAG;
    [self.view addSubview:emoticonButton];
    
    self.tabButtons = [NSArray arrayWithObjects:textButton, emoticonButton, nil];
    [textButton setImagePressed:YES];
    [textButton release];
    [emoticonButton release];
    
    // show keypad first
    //
    [self setKeypadForIndex:0];*/
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    // sticker select sticker first, then go to next step
    //
    if (self.editMode == kCCEditModeSticker) {
        
        UIBarButtonItem *nextButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Next", @"Composer - button: go to next step") 
                                                          buttonType:kAUButtonTypeBarHighlight 
                                                              target:self action:@selector(pressNext:)];
        nextButton.enabled = NO;
        self.navigationItem.rightBarButtonItem = nextButton;
        
    }
    // default - basic editing, provide Save button
    //
    else {
        NSString *buttonTitle = nil;
        
        if (self.saveButtonTitle) {
            buttonTitle = saveButtonTitle;
        }
        else {
            buttonTitle = NSLocalizedString(@"Save", @"Composer - button: saves status to server");
        }
        //NSLocalizedString(@"Send", @"Composer - button: saves status to server") 
        
        UIBarButtonItem *saveButton = [AppUtility barButtonWithTitle:buttonTitle
                                                          buttonType:kAUButtonTypeBarHighlight 
                                                              target:self action:@selector(pressSave:)];
        saveButton.enabled = NO;
        self.navigationItem.rightBarButtonItem = saveButton;
    }

    
    self.navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem *cancelButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Cancel", @"Composer - button: cancel status edit") 
                                                        buttonType:kAUButtonTypeBarNormal 
                                                            target:self action:@selector(pressCancel:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self registerForKeyboardNotifications];

    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    //return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    return (interfaceOrientation == UIInterfaceOrientationPortrait);

}

#pragma mark - Tools






#pragma mark - TextViewDelegate

/*!
 @abstract Updates the character count
 
 */
- (void)updateCharacterCount:(NSString *)newText {
    
    //NSInteger currentCharCount = [newText length];
    NSInteger currentCharCount = [[MPResourceCenter sharedMPResourceCenter] charCountInText:newText];
    
    BOOL canSave = NO;
    
    if (self.characterLimitMax || self.characterLimitMin) {
        
        
        // number of characters
        NSString *charString = nil;
        
        UILabel *countLabel = (UILabel *)[self.view viewWithTag:COUNT_TAG];
        
        // close to or at max limit (valid count)
        if (self.characterLimitMax && 
            currentCharCount <= self.characterLimitMax &&
            currentCharCount > self.characterLimitMax - 100 && 
            currentCharCount >= self.characterLimitMin) // must over min
        {
            charString = [NSString stringWithFormat:@"%d", self.characterLimitMax - currentCharCount];
            countLabel.textColor = [AppUtility colorForContext:kAUColorTypeBackgroundText];
            canSave = YES;
        }
        // over max
        else if (self.characterLimitMax && currentCharCount > self.characterLimitMax) {
            charString = [NSString stringWithFormat:@"%d", self.characterLimitMax - currentCharCount];
            countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
            canSave = NO;
        }
        // under minimum
        else if (self.characterLimitMin && currentCharCount < self.characterLimitMin) {
            charString = @"";
            //countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
            canSave = NO;
        }
        else {
            charString = @"";
            countLabel.textColor = [AppUtility colorForContext:kAUColorTypeBackgroundText];
            canSave = YES;
        }
        countLabel.text = charString;
        
        
        /* - x/x format
        // number of characters
        NSString *charString = [NSString stringWithFormat:@"%d/%d", currentCharCount, self.characterLimitMax];
        NSString *countMessage = nil;
        
        UILabel *countLabel = (UILabel *)[self.view viewWithTag:COUNT_TAG];
        
        NSString *message = @"";
        
        
        // at max
        if (self.characterLimitMax && currentCharCount == self.characterLimitMax) {
            message = NSLocalizedString(@"Reached limit", @"TextEdit - text: reached max length of text");
            countLabel.textColor = [AppUtility colorForContext:kAUColorTypeBackgroundText];
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
        // over max
        else if (self.characterLimitMax && currentCharCount > self.characterLimitMax) {
            message = NSLocalizedString(@"Over limit", @"TextEdit - text: over max length of text");
            countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
        // under minimum
        else if (self.characterLimitMin && currentCharCount < self.characterLimitMin) {
            message = NSLocalizedString(@"Under limit", @"TextEdit - text: less thab min length of text");
            countLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
        else {
            countLabel.textColor = [AppUtility colorForContext:kAUColorTypeBackgroundText];
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
        
        countMessage = [NSString stringWithFormat:@"%@ %@", message, charString];
        countLabel.text = countMessage;
        */
    }
    // no limit - so after any change allow save
    // - even for empty text
    else {
        canSave = YES;
    }
    
    
    // check if there are contacts to send to
    if (canSave && ( (self.toContacts && [self.toContacts count] > 0) || self.toContacts == nil) ) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}


/*!
 @abstract Enable and disabled send button depending if there is text
 */
- (BOOL)textView:(UITextView *)thisTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    
    // check if it is an emoticon - if so delete the entire emoticon
    NSString *currentText = thisTextView.text;
    
    NSRange selectedRange = thisTextView.selectedRange;
    NSString *startText = [currentText substringToIndex:selectedRange.location];
    NSString *endText = [currentText substringFromIndex:selectedRange.location + selectedRange.length];
    
    // if deleting a ")" char
    if ([startText hasSuffix:@")"] && [text isEqualToString:@""]) {
        
        // search backwards to find "("
        NSRange startRange = [startText rangeOfString:@"(" options:NSBackwardsSearch];
        
        if (startRange.location != NSNotFound) {
            NSString *isEmoticonText = [startText substringFromIndex:startRange.location];
            CDResource *emoticon = [[MPResourceCenter sharedMPResourceCenter] emoticonForText:isEmoticonText];
            if (emoticon) {
                
                NSString *newStartText = [startText substringToIndex:startRange.location];
                NSString *finalText = nil;
                if (endText) {
                    finalText = [newStartText stringByAppendingString:endText];
                }
                else {
                    finalText = newStartText;
                }
                thisTextView.text = finalText;
                thisTextView.selectedRange = NSMakeRange(startRange.location, 0);
                
                [self updateCharacterCount:thisTextView.text];

                return NO; // we modified text manually
            }
        }
    }
    
    
    // if deleting end, check if it is an emoticon - if so delete the entire emoticon
    /*NSString *currentText = thisTextView.text;
    if ([[currentText substringWithRange:range] isEqualToString:@")"] && [text isEqualToString:@""]) {
        
        // search backwards to find "("
        NSRange startRange = [currentText rangeOfString:@"(" options:NSBackwardsSearch];
        if (startRange.location != NSNotFound) {
            NSString *isEmoticonText = [currentText substringFromIndex:startRange.location];
            CDResource *emoticon = [[MPResourceCenter sharedMPResourceCenter] emoticonForText:isEmoticonText];
            if (emoticon) {
                // delete emoticon text manually
                thisTextView.text = [currentText substringToIndex:startRange.location];
                [self updateCharacterCount:thisTextView.text];
                return NO; // we changed manually
            }
        }
    }*/
    
    NSString *newText = [thisTextView.text stringByReplacingCharactersInRange:range withString:text];
    
    // don't allow to go over max limit characters
    //
    if (self.characterLimitMax) {
        NSInteger newCharCount = [[MPResourceCenter sharedMPResourceCenter] charCountInText:newText];
        if (newCharCount > self.characterLimitMax) {
            return NO;
        }
    }
    
    [self updateCharacterCount:newText];
    return YES;
}


/*!
 @abstract called whenever text if modified
 
- (void)textViewDidChange:(UITextView *)textView {
    
}*/

#pragma mark - TKTabButton

/*!
 @abstract Show the proper keypad view and lazy load views
 */
- (void)setKeypadForIndex:(NSInteger)tabIndex {
        
    // text keypad
    if (tabIndex == 0) {
        if ([self.textView isFirstResponder]) {
            // dismiss the emoticon and show default keypad
            [self.textView resignFirstResponder];
            self.textView.inputView = nil;
        }
        [self.textView becomeFirstResponder];
    }
    
    // emoticon keypad
    if (tabIndex == 1) {
        // lazy create emoticon view
        // add it as a subview
        //
        if (!self.emoticonKeypad) {
            
            // don't use shared instance here
            // - petphrase edit will affect chat dialog emoticon keypad
            //
            EmoticonKeypad *newKP = [[EmoticonKeypad alloc] initWithFrame:CGRectMake(0.0, 0.0, 1.0, 1.0) displayMode:kEKModeDefault];
            newKP.delegate = self;
            self.emoticonKeypad = newKP;
            
            if ([self.title isEqualToString:NSLocalizedString(@"Pet Phrase", nil)]) {
                [self.emoticonKeypad setMode:kEKModeEmoticonOnly];
            }
            else {
                [self.emoticonKeypad setMode:kEKModeHideSticker];
            }
            
            [newKP release];
            
            /*
            self.emoticonKeypad = [EmoticonKeypad sharedEmoticonKeypad];
            self.emoticonKeypad.delegate = self;
            [self.emoticonKeypad setFrameOrigin:CGPointMake(0.0, 0.0)];
            [self.emoticonKeypad setMode:kEKModeHideSticker];
            */
            
            // set emoticon first
            [self.emoticonKeypad setKeypadForIndex:0];  
        }
        
        // dismiss the keypad and set the new emoticon keypad!
        [self.textView resignFirstResponder];
        self.textView.inputView = self.emoticonKeypad;
        [self.textView becomeFirstResponder];
    }
}


/*!
 @abstract Tab Button got a control event - delegate should control how tabs images changes
 */
- (void)TKTabButton:(TKTabButton *)tabButton gotControlEvent:(UIControlEvents)controlEvent {
    
    // if tap down
    // - set that button as selected and clear the rest
    //
    if (controlEvent == UIControlEventTouchDown) {
        
        int buttonIndex = 0;
        int i = 0;
        for (TKTabButton *iButton in self.tabButtons){
            if (iButton == tabButton) {
                [iButton setImagePressed:YES];
                buttonIndex = i;
            }
            else {
                [iButton setImagePressed:NO];
            }
            i++;
        }
        [self setKeypadForIndex:buttonIndex];
        
    }
}



#pragma mark - EmoticonKeypad Delegate

/*!
 @abstract User pressed delete key
 */
- (void)EmoticonKeypad:(EmoticonKeypad *)emoticonKeypad pressDelete:(id)sender {
    
    // check if it is an emoticon - if so delete the entire emoticon
    NSString *currentText = self.textView.text;
    
    NSRange selectedRange = self.textView.selectedRange;
    
    // if at start nothing to do
    if (selectedRange.location == 0 && selectedRange.length == 0) {
        return;
    }
    
    NSString *startText = [currentText substringToIndex:selectedRange.location];
    NSString *endText = [currentText substringFromIndex:selectedRange.location + selectedRange.length];
    
    // if selected, just delete that selected text
    if (selectedRange.length > 0) {
        
        self.textView.text = [startText stringByAppendingString:endText];
        self.textView.selectedRange = NSMakeRange(selectedRange.location, 0);
        
    }
    // zero length selected range
    else {
        
        NSString *newStartText = nil;
        NSRange newSelectedRange = NSMakeRange(0, 0);
        
        // if possible emoticon
        if ([startText hasSuffix:@")"]) {
            // search backwards to find "("
            NSRange startRange = [startText rangeOfString:@"(" options:NSBackwardsSearch];
            if (startRange.location != NSNotFound) {
                NSString *isEmoticonText = [startText substringFromIndex:startRange.location];
                CDResource *emoticon = [[MPResourceCenter sharedMPResourceCenter] emoticonForText:isEmoticonText];
                if (emoticon) {
                    newSelectedRange = NSMakeRange(startRange.location, 0);
                    newStartText = [startText substringToIndex:startRange.location];
                }
            }
        }
        
        // just delete on char at cursor
        // - if emoticon was not found above
        if ([currentText length] > 0 && !newStartText) {
            newSelectedRange = NSMakeRange([startText length]-1, 0);
            newStartText = [startText substringToIndex:newSelectedRange.location];
        }
        
        if (newStartText) {
            NSString *finalText = nil;
            if (endText) {
                finalText = [newStartText stringByAppendingString:endText];
            }
            else {
                finalText = newStartText;
            }
            self.textView.text = finalText;
            self.textView.selectedRange = newSelectedRange;
        }
    }

    
    /*
    // if deleting end, check if it is an emoticon - if so delete the entire emoticon
    NSString *currentText = self.textView.text;
    if ([currentText hasSuffix:@")"]) {
        
        // search backwards to find "("
        NSRange startRange = [currentText rangeOfString:@"(" options:NSBackwardsSearch];
        if (startRange.location != NSNotFound) {
            NSString *isEmoticonText = [currentText substringFromIndex:startRange.location];
            CDResource *emoticon = [[MPResourceCenter sharedMPResourceCenter] emoticonForText:isEmoticonText];
            if (emoticon) {
                self.textView.text = [currentText substringToIndex:startRange.location];
            }
        }
    }
    // just delete one char otherwise
    else if ([currentText length] > 0) {
        self.textView.text = [currentText substringToIndex:[currentText length]-1];
    }
     */
    [self updateCharacterCount:self.textView.text];
}

/*!
 @abstract User pressed this resource
 
 - emoticon & petphrase: appends text
 - sticker: send resource to chat scroll view to display
 
 */
- (void)EmoticonKeypad:(EmoticonKeypad *)emoticonKeypad resource:(CDResource *)resource {
    
    // text based: emoticons and petphrase
    //
    RCType rcType = [resource rcType];
    
    switch (self.editMode) {
        case kCCEditModeBasic:
        case kCCEditModeText:
            // emoticon and petphrase, just append the new text
            //
            if (rcType == kRCTypeEmoticon || rcType == kRCTypePetPhrase) {
                
                // don't allow to go over max limit characters
                //
                if (self.characterLimitMax) {
                    NSString *newText = [self.textView.text stringByAppendingString:resource.text];
                    NSInteger newCharCount = [[MPResourceCenter sharedMPResourceCenter] charCountInText:newText];
                    if (newCharCount <= self.characterLimitMax) {
                        // insert text at cursor
                        [self.textView insertText:resource.text];
                        [self updateCharacterCount:self.textView.text];
                    }
                }
            }
            break;
            
        case kCCEditModeSticker:
            // get sticker image and set image and text
            //
            if (rcType == kRCTypeSticker) {
                self.tempText = resource.text;
                StickerButton *stickerButton = (StickerButton *)[self.view viewWithTag:STICKER_TAG];
                [stickerButton setTitle:@"" forState:UIControlStateNormal];
                stickerButton.stickerResource = resource;
                
                // reframe sticker since it can vary in size
                CGPoint offsetPoint =  [(UIScrollView *)self.view contentOffset];
                
                // add sticker image view
                CGRect stickerRect = CGRectMake( (self.view.bounds.size.width - kTEStickerSize)/2.0, offsetPoint.y + (self.view.bounds.size.height - kTEKeypadHeight - kTEStickerSize)/2.0, kTEStickerSize, kTEStickerSize);
                stickerButton.frame = stickerRect;
                self.navigationItem.rightBarButtonItem.enabled = YES;
            }
            break;
            
        default:
            break;
    }
    
}



#pragma mark - Images

/*!
 @abstract configure image to send out
 
 @param image The original image that user would like to send out
 
 Use:
 - set image from album and camera
 
 */
- (void) setImage:(UIImage *)image {
    
    
    // compress the original image so it does not exceed max limits
    //
    
    CGSize rawSize = [image size];
    //DDLogVerbose(@"CD-image: h:%f w:%f", imageSize.height, imageSize.width);
    
    // compress image
    // - use scale so we can compress to pixels not just points
    //
    if (rawSize.width*image.scale > kMPParamSendImageWidthMax) {
        // new height scaled proportionally
        //
        CGFloat newHeight = rawSize.height * kMPParamSendImageWidthMax/rawSize.width;
        CGSize newSize = CGSizeMake(kMPParamSendImageWidthMax, newHeight);
        
        self.sendImage = [UIImage imageWithImage:image scaledToSize:newSize maintainScale:NO];
    }
    // small image, no need to compress
    else {
        self.sendImage = image;
    }
    DDLogVerbose(@"CD-ip: scaled image");
    
    
    
    /*
     provide smaller frame to display
     */
    CGSize imageSize = [self.sendImage size];
    CGSize boundsSize = self.view.bounds.size;
    
    // scroll to show message view and controls
    UIView *messageLabel = [self.view viewWithTag:MSG_LABEL_TAG];    
    
    // get the size of frame to show image
    //
    CGFloat imageWidth = 0.0;
    CGFloat imageHeight = 0.0;
    // - if landscape
    if (imageSize.width > imageSize.height) {
        if (imageSize.width > kTEImageSizeMax) {
            imageWidth = kTEImageSizeMax;
            imageHeight = imageSize.height * kTEImageSizeMax/imageSize.width;
        }
    }
    // - if portrait
    else {
        if (imageSize.height > kTEImageSizeMax) {
            imageHeight = kTEImageSizeMax;
            imageWidth = imageSize.width * kTEImageSizeMax/imageSize.height;
        }
    }
    // small image, then no change
    if (imageWidth == 0) {
        imageWidth = imageSize.width;
        imageHeight = imageSize.height;
    }
    
    CGRect imageRect = CGRectMake((boundsSize.width - imageWidth)/2.0, messageLabel.frame.origin.y + (boundsSize.height - messageLabel.frame.origin.y - imageHeight - 44.0)/2.0 , imageWidth, imageHeight);
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.sendImage];
    imageView.frame = imageRect;
    [imageView addShadow];
    [self.view addSubview:imageView];
    [imageView release];
    
    if ([self.toContacts count] > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
}




#pragma mark - Letters

/*!
 @abstract configure letter image to send out
 
 @param image The letter image to be sent
 @param letterID ID of the letter paper to send
 
 */
- (void) setLetterImage:(UIImage *)image letterID:(NSString *)idString {
    
    self.letterID = idString;
    
    // compress the original image so it does not exceed max limits
    //
    
    CGSize rawSize = [image size];
    //DDLogVerbose(@"CD-image: h:%f w:%f", imageSize.height, imageSize.width);
    
    // compress image
    // - use scale so we can compress to pixels not just points
    //
    if (rawSize.width*image.scale > kMPParamSendImageWidthMax) {
        // new height scaled proportionally
        //
        CGFloat newHeight = rawSize.height * kMPParamSendImageWidthMax/rawSize.width;
        CGSize newSize = CGSizeMake(kMPParamSendImageWidthMax, newHeight);
        
        self.letterImage = [UIImage imageWithImage:image scaledToSize:newSize maintainScale:NO];
    }
    // small image, no need to compress
    else {
        self.letterImage = image;
    }
    DDLogVerbose(@"CD-ip: scaled image");
    
    
    
    /*
     provide smaller frame to display
     */
    CGSize imageSize = [self.letterImage size];
    CGSize boundsSize = self.view.bounds.size;
    
    // scroll to show message view and controls
    UIView *messageLabel = [self.view viewWithTag:MSG_LABEL_TAG];    
    
    // get the size of frame to show image
    //
    CGFloat imageWidth = 0.0;
    CGFloat imageHeight = 0.0;
    // - if landscape
    if (imageSize.width > imageSize.height) {
        if (imageSize.width > kTEImageSizeMax) {
            imageWidth = kTEImageSizeMax;
            imageHeight = imageSize.height * kTEImageSizeMax/imageSize.width;
        }
    }
    // - if portrait
    else {
        if (imageSize.height > kTEImageSizeMax) {
            imageHeight = kTEImageSizeMax;
            imageWidth = imageSize.width * kTEImageSizeMax/imageSize.height;
        }
    }
    // small image, then no change
    if (imageWidth == 0) {
        imageWidth = imageSize.width;
        imageHeight = imageSize.height;
    }
    
    CGRect imageRect = CGRectMake((boundsSize.width - imageWidth)/2.0, messageLabel.frame.origin.y + (boundsSize.height - messageLabel.frame.origin.y - imageHeight - 44.0)/2.0 , imageWidth, imageHeight);
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.letterImage];
    imageView.frame = imageRect;
    [imageView addShadow];
    [self.view addSubview:imageView];
    [imageView release];
    
    if ([self.toContacts count] > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
}



#pragma mark - Location

/*!
 @abstract configure location message to send out
 
 @param image The letter image to be sent
 @param letterID ID of the letter paper to send
 
 */
- (void) setLocationPreviewImage:(UIImage *)image coordinateText:(NSString *)coordinateText {
    
    self.locationImage = image;
    self.locationText = coordinateText;
    
    // compress the original image so it does not exceed max limits
    //
    
    self.sendImage = image;
    
    /*
     provide smaller frame to display
     */
    CGSize imageSize = [self.sendImage size];
    CGSize boundsSize = self.view.bounds.size;
    
    // scroll to show message view and controls
    UIView *messageLabel = [self.view viewWithTag:MSG_LABEL_TAG];    
    
    // get the size of frame to show image
    //
    CGFloat imageWidth = 0.0;
    CGFloat imageHeight = 0.0;
    // - if landscape
    if (imageSize.width > imageSize.height) {
        if (imageSize.width > kTEImageSizeMax) {
            imageWidth = kTEImageSizeMax;
            imageHeight = imageSize.height * kTEImageSizeMax/imageSize.width;
        }
    }
    // - if portrait
    else {
        if (imageSize.height > kTEImageSizeMax) {
            imageHeight = kTEImageSizeMax;
            imageWidth = imageSize.width * kTEImageSizeMax/imageSize.height;
        }
    }
    // small image, then no change
    if (imageWidth == 0) {
        imageWidth = imageSize.width;
        imageHeight = imageSize.height;
    }
    
    CGRect imageRect = CGRectMake((boundsSize.width - imageWidth)/2.0, messageLabel.frame.origin.y + (boundsSize.height - messageLabel.frame.origin.y - imageHeight - 44.0)/2.0 , imageWidth, imageHeight);
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.sendImage];
    imageView.frame = imageRect;
    [imageView addShadow];
    [self.view addSubview:imageView];
    [imageView release];
    
    if ([self.toContacts count] > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}


#pragma mark - SelectContactsControllerDelegate




/*!
 @abstract open up chat dialog for selected contacts
 - create new chat with the selected contacts
 
 */
- (void)selectContactsController:(SelectContactController *)selectContactsController chatContacts:(NSArray *)contacts{
    
    
    self.toContacts = contacts;
    
    [self setToText];

    // allow save if recipients are selected
    //
    if (self.editMode == kCCEditModeSticker || 
        self.editMode == kCCEditModeImage || 
        self.editMode == kCCEditModeLetter ||
        self.editMode == kCCEditModeLocation ) {
        if ([self.toContacts count] > 0) {
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
        else {
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
    }
    else if (self.editMode == kCCEditModeText) {
        [self updateCharacterCount:self.textView.text];
    }
    
    //[self dismissModalViewControllerAnimated:YES];
    [self.navigationController popViewControllerAnimated:YES];

}





#pragma mark - Date


/*!
 @abstract update Date button
 */
- (void)updateDate {
    
    UIButton *dateButton = (UIButton *)[self.view viewWithTag:DATE_BTN_TAG];    
    NSString *dateText = [Utility shortStyleTimeDate:self.sendDate];
    [dateButton setTitle:dateText forState:UIControlStateNormal];
}

/*!
 @abstract generated bar buttons
 
 */
- (UIButton *) dateButtonWithFrame:(CGRect)rect isDone:(BOOL)isDone {
    
    NSString *title = nil;
    
    UIImage *norImage = nil;
    UIImage *prsImage = nil;
    
    if (isDone){
        title = NSLocalizedString(@"Done", @"CreateSchedule - Button: done with date");
        norImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_green2_nor.png"] leftCapWidth:70.0 topCapHeight:15.0];
        prsImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_green2_prs.png"] leftCapWidth:70.0 topCapHeight:15.0];
    }
    else {
        title = NSLocalizedString(@"Cancel", @"CreateSchedule - Button: cancel date setting");
        norImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_black_nor.png"] leftCapWidth:70.0 topCapHeight:15.0];
        prsImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_black_prs.png"] leftCapWidth:70.0 topCapHeight:15.0];
    }
    
    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [customButton setBackgroundImage:norImage forState:UIControlStateNormal];
    [customButton setBackgroundImage:prsImage forState:UIControlStateHighlighted];
    [customButton setEnabled:YES];
    
    
    customButton.backgroundColor = [UIColor clearColor];
    customButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicroPlus];
    
    [customButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [customButton setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    
    [customButton setFrame:rect];
    [customButton setTitle:title forState:UIControlStateNormal];
    
    if (isDone){
        [customButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [customButton addTarget:self action:@selector(pressDateDone:) forControlEvents:UIControlEventTouchUpInside];
    }
    else {
        [customButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [customButton addTarget:self action:@selector(pressDateCancel:) forControlEvents:UIControlEventTouchUpInside];
    }
    return customButton;
}



/*!
 @abstract Show date view
 */
- (void) showDateView {
    
    
    UIActionSheet *aSheet = [[UIActionSheet alloc] initWithTitle:nil 
                                                        delegate:nil
                                               cancelButtonTitle:nil
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:nil];
    
    [aSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
    
    self.dateActionSheet = aSheet;
    [aSheet release];
    
    // date view buttons
    UIButton *dateCancelButton = [self dateButtonWithFrame:CGRectMake(5.0, 5.0, 150.0, 33.0) isDone:NO];
    UIButton *dateDoneButton = [self dateButtonWithFrame:CGRectMake(165.0, 5.0, 150.0, 33.0) isDone:YES];
    [self.dateActionSheet addSubview:dateCancelButton];
    [self.dateActionSheet addSubview:dateDoneButton];
    
    // add date picker
    UIDatePicker *dPicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0.0, 43.0, 1.0, 1.0)];
    self.datePicker = dPicker;
    [dPicker release];
    self.datePicker.date = self.sendDate;
    self.datePicker.minimumDate = [NSDate dateWithTimeIntervalSinceNow:self.uiMinimumTimeSinceNow]; // at least 15 minute
    self.datePicker.maximumDate = [NSDate dateWithTimeIntervalSinceNow:86400.0*59.9]; // 60 days
    [self.dateActionSheet addSubview:datePicker];
    
    [self.dateActionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationCurveEaseInOut 
                     animations:^{
                         [self.dateActionSheet setBounds:CGRectMake(0, 0, 320.0, 485.0)];
                     }
                     completion:NULL
     ];
    
}


/*!
 @abstract Save date
 */
- (void) pressDateDone:(id)sender {
    if (self.datePicker) {
        
        /*
         Date picker provides seconds information (probably based on current time)
         chop off seconds info since users may not expect this behavior
         */
        self.sendDate = [Utility stripSecondsFromDate:self.datePicker.date];
        [self updateDate];
    }
    [self.dateActionSheet dismissWithClickedButtonIndex:0 animated:YES];
}

/*!
 @abstract Cancel date selection
 */
- (void) pressDateCancel:(id)sender {
    [self.dateActionSheet dismissWithClickedButtonIndex:0 animated:YES];
}


/*!
 @abstract configure send date
 
 */
- (void)pressDate:(id)sender {
    [self.textView resignFirstResponder];
    [self showDateView];
}





#pragma mark - Button


/*!
 @abstract modify To recipients
 */
- (void)setToText {
        
    NSMutableString *nameString = [[NSMutableString alloc] init];
    for (CDContact *iContact in self.toContacts) {
        if ([nameString length]>0) {
            [nameString appendString:@", "];
        }
        [nameString appendString:[iContact displayName]];
    }
    
    
    UIButton *toButton = (UIButton *)[self.view viewWithTag:TO_BTN_TAG];
    
    UIColor *textColor = [UIColor blackColor];
    // update name button
    if ([nameString length] == 0) {
        textColor = [AppUtility colorForContext:kAUColorTypeLightGray1];
        [toButton setTitle:NSLocalizedString(@"Recipients", @"CreateSchedule - placeholder: press to select contacts to send to") forState:UIControlStateNormal];
    }
    else {
        [toButton setTitle:nameString forState:UIControlStateNormal];
    }
    [nameString release];
    [toButton setTitleColor:textColor forState:UIControlStateNormal];
    
    TKImageLabel *toBadge = (TKImageLabel *)[self.view viewWithTag:TO_NUMBER_BTN_TAG];
    NSInteger count = [self.toContacts count];
    if (count) {
        [toBadge setText:[NSString stringWithFormat:@"%d", count]];
    }
    else {
        [toBadge setText:nil];
    }
}


/*!
 @abstract modify To recipients
 
 */
- (void)pressTo:(id)sender {
    
    [self.textView resignFirstResponder];
    
    SelectContactController *nextController = [[SelectContactController alloc] 
                                               initWithTableStyle:UITableViewStylePlain 
                                               type:kMPSelectContactTypeBasic
                                               viewContacts:[NSSet setWithArray:self.toContacts]];
    [self.navigationController pushViewController:nextController animated:YES];
    nextController.delegate = self;
    [nextController release];
    
    
    // Create nav controller to present modally
    /*UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:nextController];
    nextController.delegate = self;
    
    
    [AppUtility customizeNavigationController:navigationController];
    
    [self presentModalViewController:navigationController animated:YES];
    [navigationController release];
    [nextController release];*/
    
}


/*!
 @abstract save status
 */
- (void)pressSave:(id)sender {
    
    
    // Check if we meet minimum time requirements
    // - give 2 minute room
    //
    NSDate *minDate = [NSDate dateWithTimeIntervalSinceNow:self.minimumTimeSinceNow];
    if ([self.sendDate compare:minDate] == NSOrderedAscending) {
        
        NSString *detMessage = [NSString stringWithFormat:NSLocalizedString(@"Message time should be at least %d minutes from now.", @"CreateSchedule - title: users to increase scheduele time"), (NSInteger)(kMPParamScheduleUIMinimumTimeSinceNow/60.0)];
        
        [Utility showAlertViewWithTitle:NSLocalizedString(@"Change Date", @"CreateSchedule - title: users to increase scheduele time") message:detMessage];
        
        return;
    }
    
    
    BOOL shouldSave = NO;
    if (self.characterLimitMax > 0) {
        NSInteger charsLeft = self.characterLimitMax - [[MPResourceCenter sharedMPResourceCenter] charCountInText:self.textView.text]; // [self.textView.text length];
        if (charsLeft >= 0) {
            shouldSave = YES;
        }
        else {
            shouldSave = NO;
            // alert user that they are over limit, but this should never happen since enable button is not active
        }
    }
    else {
        shouldSave = YES;
    }
    
    
    if (shouldSave) {
        // only overwrite if text exists, otherwise sticker text will already be in temptext
        if ([self.textView.text length] > 0) {
            self.tempText = self.textView.text;
        }
        
        // inform delegate of saves
        // - if contacts exists, then we composed a SM or broadcast message
        //
        if ([self.toContacts count] > 0) {
            if ([self.delegate respondsToSelector:@selector(ComposerController:text:contacts:image:date:letterImage:letterID:locationImage:locationText:)]) {
                [self.delegate ComposerController:self text:self.tempText contacts:self.toContacts image:self.sendImage date:self.sendDate letterImage:self.letterImage letterID:self.letterID locationImage:self.locationImage locationText:self.locationText];
            }
        }
        // just text editing
        //
        else if ([self.delegate respondsToSelector:@selector(ComposerController:didSaveWithText:)]) {
            [self.delegate ComposerController:self didSaveWithText:self.textView.text];
        }
    }
    
}





/*!
 @abstract Scroll to top of the view and show other parameters to update
 
 */
- (void)pressNext:(id)sender {
    
    NSString *buttonTitle = nil;
    if (self.saveButtonTitle) {
        buttonTitle = saveButtonTitle;
    }
    else {
        buttonTitle = NSLocalizedString(@"Save", @"Composer - button: saves status to server");
    }
    
    
    //[(UIScrollView *)self.view setScrollEnabled:YES];
    [UIView animateWithDuration:0.3 
                     animations: ^{
                         CGRect eFrame = self.emoticonKeypad.frame;
                         eFrame = CGRectOffset(eFrame, 0.0, kTEKeypadHeight);
                         self.emoticonKeypad.frame = eFrame;
                         
                         [(UIScrollView *)self.view setContentOffset:CGPointMake(0.0, 0.0) animated:YES];
                         
                     }
     
                     completion:^(BOOL finished) {
                         if (finished) {
                             
                             // replace next with save button
                             UIBarButtonItem *saveButton = [AppUtility barButtonWithTitle:buttonTitle
                                                                               buttonType:kAUButtonTypeBarHighlight 
                                                                                   target:self action:@selector(pressSave:)];
                             
                             if ([self.toContacts count] > 0) {
                                 saveButton.enabled = YES;
                             }
                             else {
                                 saveButton.enabled = NO;
                             }
                             self.navigationItem.rightBarButtonItem = saveButton;
                             self.emoticonKeypad.hidden = YES;
                         }
                     }];
}


/*!
 @abstract cancel edit
 */
- (void)pressCancel:(id)sender {
        
    // if presented modally, we need to present done button
    if (self.editMode == kCCEditModeBasic) {
        if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
            [self dismissModalViewControllerAnimated:YES];
        }
        else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    // for other edit modes we just dismiss modally
    else {
        [self dismissModalViewControllerAnimated:YES];
    }
    
}



#pragma mark - Keyboard Methods

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
 @abstract Adjust view to match keyboard height
 */
- (void)AdjustViewToMatchKeyBoardNotification:(NSNotification *)aNotification {
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    NSNumber *duration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    DDLogVerbose(@"CDC-avt: showing kbHeight: %f", kbSize.height);
    
	// animations settings
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
    
    //[UIView beginAnimations:nil context:NULL];
    //[UIView setAnimationDelay:0.7]; // delay so keypad will look like it pushes toolbar up
    //[UIView setAnimationBeginsFromCurrentState:YES];
    // The kKeyboardAnimationDuration I am using is 0.3
    //[UIView setAnimationDuration:0.3];
    
    // get the right KB height
    //
    CGFloat kbHeight = 0.0;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        kbHeight = kbSize.width;
    }
    else {
        kbHeight = kbSize.height;
    }
    
    // if tab bar is showing, inset does not need to be that large
    if ([self.navigationController.viewControllers objectAtIndex:0] != self) {
        kbHeight = kbHeight - kMPParamTabBarHeight;
    }
    
    
    // set inset to push the bottom of the view up
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbHeight, 0.0);
    [(UIScrollView *)self.view setContentInset:contentInsets];
    [(UIScrollView *)self.view setScrollIndicatorInsets:contentInsets];
    
    //CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    UIView *messageLabel = [self.view viewWithTag:MSG_LABEL_TAG];
    
    CGFloat contentHeight = 0.0;
    if (kbHeight == 0.0) {
        contentHeight = [self viewHeight];
    }
    // smaller content size so that we don't scroll down too far
    else {
        contentHeight = messageLabel.frame.origin.y + 195.0;
    }
    [(UIScrollView *)self.view setContentSize:CGSizeMake(self.view.bounds.size.width, contentHeight)];
    
    // scroll to show message view and controls
    CGPoint scrollPoint = CGPointMake(0.0, messageLabel.frame.origin.y - 5.0);
    [(UIScrollView *)self.view setContentOffset:scrollPoint animated:NO];
    
    [UIView commitAnimations];
}


// Called when the UIKeyboardDidShowNotification is sent.
//
- (void)keyboardWillShown:(NSNotification*)aNotification
{
    [self AdjustViewToMatchKeyBoardNotification:aNotification];
    
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    
    NSDictionary* info = [aNotification userInfo];
    //CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    NSNumber *duration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    //DDLogVerbose(@"CDC-kwh: hidding kbHeight: %f", kbSize.height);
    
    // animations settings
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    [(UIScrollView *)self.view setContentInset:contentInsets];
    [(UIScrollView *)self.view setScrollIndicatorInsets:contentInsets];
    
    [UIView commitAnimations];
}



@end

