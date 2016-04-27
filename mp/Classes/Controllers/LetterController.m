//
//  LetterController.m
//  mp
//
//  Created by Min Tsai on 2/6/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "LetterController.h"
#import "MPFoundation.h"
#import "MPResourceCenter.h"
#import "CDResource.h"
#import "ResourceButton.h"
#import "TKFileManager.h"

#import "UIView+TKUtilities.h"
#import "TextEmoticonView.h"

CGFloat const kLCParamLetterWidthPreview = 100.0;
CGFloat const kLCParamLetterHeightPreview = 150.0;

NSUInteger const kLCParamBodyTextMaxChar = 150;

#define kTextBodyMaxLines   14 //10


#define kLCPageWidth 320.0
#define kLCPageHeight 416.0

// preview letter size
#define kLCLetterWidthPreview 270.0
#define kLCLetterHeightPreview 350.0

// letter select start corner
#define kLCPageStartX  42.0
#define kLCPageStartY  10.0

// letter select corner spacing
#define kLCPageShiftX  136.0
#define kLCPageShiftY  177.0

// letter select params
#define kLCLettersPerRow  2
#define kLCLettersPerPage 4

#define PREVIEW_TAG         12001
#define BACKGROUND_MASK_TAG 12002
#define LETTER_RESOURCE_TAG 12003
#define ACTIVITY_TAG        12004



@interface LetterController (Private) 

- (void)registerForKeyboardNotifications;

@end

@implementation LetterController

@synthesize delegate;
@synthesize letterMode;
@synthesize toName;
@synthesize backImage;

@synthesize letterResources;
@synthesize letterView;
@synthesize letterID;

// UI elements
//
@synthesize keyboardButton;
@synthesize emoticonKeypad;
@synthesize charCountLabel;

@synthesize baseScrollView;
@synthesize selectPageControl;
@synthesize pageControlUsed;

@synthesize toField;
@synthesize fromField;
@synthesize bodyTextView;

@synthesize bodyTEView;

@synthesize toBackView;
@synthesize fromBackView;
@synthesize bodyBackView;

@synthesize selectionView;
@synthesize selectLetterButtons;

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.emoticonKeypad.delegate = nil;
    
    [toName release];
    
    [letterResources release];
    [letterView release];
    [letterID release];
    
    [keyboardButton release];
    [emoticonKeypad release];
    
    [selectPageControl release];
    [toField release];
    [fromField release];
    [bodyTextView release];
    
    [bodyTEView release];
    
    [toBackView release];
    [fromBackView release];
    [bodyBackView release];
    
    [selectionView release];
    [selectLetterButtons release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Tool


/*!
 @abstract Gets the default letter image
 
 */
- (UIImage *)defaultLetterImage {
    
    if (!self.letterResources) {
        // get letter resources from DB
        self.letterResources = [CDResource resourcesForType:kRCTypeLetter setID:0 onlyRecent:NO];
    }
    
    //UIImage *testImage = [UIImage imageNamed:@"letter_bg_a_s.jpg"];
    //return testImage;
    
    if ([self.letterResources count] > 0) {
        CDResource *defaultLetter = [self.letterResources objectAtIndex:0];
        self.letterID = defaultLetter.resourceID;
        return [defaultLetter getImageForType:kRSImageTypeLetterFull];
    }
    return nil;
    
}

/*!
 @abstract Hide keyboard for entire view
 */
- (void)hideKeyboard {
    UIView *firstR = [self.view findFirstResponder];
    [firstR resignFirstResponder];
    //[self resignFirstResponder];
    //self.keyboardButton.hidden = NO;
}


/*!
 @abstract Configure the keyboard button
 
 @param isEmoticon Should emoticon mode be set
 
 */
- (void)setKeyboardButtonIsEmoticon:(BOOL)isEmoticon{
    
    if (isEmoticon) {
        [self.keyboardButton setImage:[UIImage imageNamed:@"letter_emoti_andr_nor.png"] forState:UIControlStateNormal];
        [self.keyboardButton setImage:[UIImage imageNamed:@"letter_emoti_andr_prs.png"] forState:UIControlStateHighlighted];
        [self.keyboardButton addTarget:self action:@selector(pressKeyboardEmoticon:) forControlEvents:UIControlEventTouchUpInside];
    }
    else {
        [self.keyboardButton setImage:[UIImage imageNamed:@"letter_txtkp_nor.png"] forState:UIControlStateNormal];
        [self.keyboardButton setImage:[UIImage imageNamed:@"letter_txtkp_prs.png"] forState:UIControlStateHighlighted];
        [self.keyboardButton addTarget:self action:@selector(pressKeyboardText:) forControlEvents:UIControlEventTouchUpInside];
    }
}


/*!
 @abstract Set toolbar for letter edit mode
 
 */
- (void)setToolBarLetterEditAnimated:(BOOL)animated {
    
    // tool bar
    //    
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    // Add Toolbar buttons
    UIBarButtonItem *letterButton = [[ UIBarButtonItem alloc ] initWithTitle: NSLocalizedString(@"Select Letter", @"Letter - Button: change letter paper image") 
                                                                       style: UIBarButtonItemStyleBordered
                                                                      target: self
                                                                      action: @selector(pressOpenSelect:) ];
    letterButton.width = 140.0;
    letterButton.enabled = YES;
    
    UIBarButtonItem *previewButton = [[ UIBarButtonItem alloc ] initWithTitle: NSLocalizedString(@"Preview", @"Letter - Button: Preview letter before sending") 
                                                                        style: UIBarButtonItemStyleBordered
                                                                       target: self
                                                                       action: @selector( pressPreview: ) ];
    previewButton.width = 140.0;
    previewButton.enabled = YES;
    
    [self setToolbarItems:[ NSArray arrayWithObjects: flexibleSpace, letterButton, previewButton, flexibleSpace, nil ] animated:animated];
    
    [flexibleSpace release];
    [letterButton release];
    [previewButton release];
    
}


/*!
 @abstract Set toolbar for letter selection mode
 
 */
- (void)setToolBarLetterSelectAnimated:(BOOL)animated {
    
    // tool bar
    //    
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    // Add Toolbar buttons
    UIBarButtonItem *closeSelectButton = [[ UIBarButtonItem alloc ] initWithTitle: NSLocalizedString(@"Close", @"Letter - Button: hide letter selection view") 
                                                                            style: UIBarButtonItemStyleBordered
                                                                           target: self
                                                                           action: @selector(pressCloseSelect:) ];
    closeSelectButton.width = 140.0;
    closeSelectButton.enabled = YES;
    
    [self setToolbarItems:[ NSArray arrayWithObjects: flexibleSpace, closeSelectButton, flexibleSpace, nil ] animated:animated];
    
    [flexibleSpace release];
    [closeSelectButton release];
}





#define kTextPadding        6.0     // padding between text and border

#define kTextWidthMargin    20.0    // margin to edge of screen
#define kTextHeightMargin   15.0    // margin between text

#define kTextHeightMin      25.0    // textfield 1 line height
#define kTextHeightMax      330.0   //230.0   // body max height

#define kTextWidthMax       280.0   // width for to & body
#define kTextWidthMin       204.0   // width for from

#define kTextHeightBodyCenter   195.0


/*!
 @abstract Sets text to the bodyTEView
 
 @return YES if text is within height limit, NO if text is over limit
 
 */
- (BOOL) setBodyText:(NSString *)newText {
    
    // create text view
    CGRect maxRect = CGRectMake(0.0, 0.0, kTextWidthMax, 9999.0);
    self.bodyTEView.textAlignment = UITextAlignmentLeft;
    self.bodyTEView.frame = maxRect;
    [self.bodyTEView setText:newText];
    [self.bodyTEView sizeToFit];
    CGFloat newHeight = self.bodyTEView.frame.size.height;
    
    if (newHeight > kTextHeightMax) {
        return NO;
    }
    else {
        return YES;
    }
    
}


/*!
 @abstract Layout the proper position  of letter subviews
 
 */
- (void)layoutLetterElementsAnimated:(BOOL)animated {
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    
    // layout body view first
    //
    /*CGSize size = CGSizeMake(kTextWidthMax-5.0, kTextHeightMax);
     CGSize newBodySize = [self.bodyTextView.text sizeWithFont:self.bodyTextView.font
     constrainedToSize:size lineBreakMode:UILineBreakModeWordWrap];    
     CGRect newBodyFrame = CGRectMake(kTextWidthMargin, 
     kTextHeightBodyCenter-newBodySize.height/2.0,
     kTextWidthMax, 
     MAX(kTextHeightMin, newBodySize.height+10.0));*/
    
    CGRect newBodyFrame = CGRectMake(kTextWidthMargin, 
                                     kTextHeightBodyCenter-kTextHeightMax/2.0,
                                     kTextWidthMax, 
                                     kTextHeightMax);
    
    
    // toField
    //
    CGRect newToFrame = CGRectMake(kTextWidthMargin, newBodyFrame.origin.y-kTextHeightMargin-kTextHeightMin, kTextWidthMax, kTextHeightMin);
    
    // from field
    //
    CGRect newFromFrame = CGRectMake(appFrame.size.width-kTextWidthMargin-kTextWidthMin, newBodyFrame.origin.y+newBodyFrame.size.height+kTextHeightMargin, kTextWidthMin, kTextHeightMin);
    
    
    // body border
    //
    CGRect bodyBorderRect = CGRectMake(newBodyFrame.origin.x-kTextPadding, 
                                       newBodyFrame.origin.y-kTextPadding, 
                                       newBodyFrame.size.width+2.0*kTextPadding, 
                                       newBodyFrame.size.height+2.0*kTextPadding);
    
    // to border
    //
    CGRect toBorderRect = CGRectMake(newToFrame.origin.x-kTextPadding, 
                                     newToFrame.origin.y-kTextPadding, 
                                     newToFrame.size.width+2.0*kTextPadding, 
                                     newToFrame.size.height+2.0*kTextPadding);
    
    // from border
    //
    CGRect fromBorderRect = CGRectMake(newFromFrame.origin.x-kTextPadding, 
                                       newFromFrame.origin.y-kTextPadding, 
                                       newFromFrame.size.width+2.0*kTextPadding, 
                                       newFromFrame.size.height+2.0*kTextPadding);
    
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            self.bodyTextView.frame = newBodyFrame;
            self.toField.frame = newToFrame;
            self.fromField.frame = newFromFrame;
            
            self.bodyBackView.frame = bodyBorderRect;
            self.toBackView.frame = toBorderRect;
            self.fromBackView.frame = fromBorderRect;
        }];
    }
    else {
        self.bodyTextView.frame = newBodyFrame;
        self.toField.frame = newToFrame;
        self.fromField.frame = newFromFrame;
        
        self.bodyBackView.frame = bodyBorderRect;
        self.toBackView.frame = toBorderRect;
        self.fromBackView.frame = fromBorderRect;
    }
}



/*!
 @abstract Create the preview of the letter to send out
 
 */
- (UIImage *)getPreviewLetterImage {
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    UIFont *textFont = [AppUtility fontPreferenceWithContext:kAUFontSystemStandardPlus];
    
    UIImageView *previewLetter = [[UIImageView alloc] initWithFrame:self.letterView.bounds];
    previewLetter.image = self.letterView.image;
    
    // generate and position the TEView
    //
    [self setBodyText:self.bodyTextView.text];
    
    CGSize size = self.bodyTEView.frame.size;   
    CGRect newBodyFrame = CGRectMake(kTextWidthMargin, 
                                     kTextHeightBodyCenter-size.height/2.0,
                                     kTextWidthMax, 
                                     MAX(kTextHeightMin, size.height+10.0));
    
    // if only one line then center it
    if (newBodyFrame.size.height < 2.0*kTextHeightMin) {
        self.bodyTEView.textAlignment = UITextAlignmentCenter;
        [self.bodyTEView setText:self.bodyTextView.text];
    }
    
    [self.bodyTEView setFrame:newBodyFrame];
    [previewLetter addSubview:self.bodyTEView];
    
    // toField
    //
    CGRect newToFrame = CGRectMake(kTextWidthMargin, newBodyFrame.origin.y-kTextHeightMargin-kTextHeightMin, kTextWidthMax, kTextHeightMin);
    
    TextEmoticonView *toView = [[TextEmoticonView alloc] initWithFrame:newToFrame];
    toView.numberOfLines = 1;
    toView.font = textFont;
    [toView setText:self.toField.text];
    [previewLetter addSubview:toView];
    [toView release];
    
    
    // from field
    //
    CGRect newFromFrame = CGRectMake(appFrame.size.width-kTextWidthMargin-kTextWidthMin, newBodyFrame.origin.y+newBodyFrame.size.height+kTextHeightMargin, kTextWidthMin, kTextHeightMin);
    
    TextEmoticonView *fromView = [[TextEmoticonView alloc] initWithFrame:newFromFrame];
    fromView.numberOfLines = 1;
    fromView.textAlignment = UITextAlignmentRight;
    fromView.font = textFont;
    [fromView setText:self.fromField.text];
    [previewLetter addSubview:fromView];
    [fromView release];
    
    UIImage *previewImage = [Utility imageFromUIView:previewLetter];
    
    [previewLetter release];
    return previewImage;
    
}


/*!
 @abstract Update character counter
 
 @return Should body text keep adding text
 
 Use:
 When letter body text changes
 */
- (BOOL) updateCharacterCount:(NSString *)newText {
    
    BOOL shouldAddText = YES;
    
    UITextView *testView = [[UITextView alloc] initWithFrame:CGRectMake(480.0, 0.0, self.bodyTextView.frame.size.width, self.bodyTextView.frame.size.height)];
    testView.font = self.bodyTextView.font;
    testView.contentInset = self.bodyTextView.contentInset;
    testView.text = newText;
    [self.view addSubview:testView];
    CGFloat currentTextHeight = testView.contentSize.height;
    [testView removeFromSuperview];
    [testView release];
    
    //CGFloat currentTextHeight = self.bodyTextView.contentSize.height;
    CGFloat lineHeight = self.bodyTextView.font.lineHeight;
    NSUInteger numberOfLines = currentTextHeight/lineHeight;
    
    // check if we surpassed max height, add 10 since content height seems larger than expected
    if (currentTextHeight > kTextHeightMax+10) {
        shouldAddText = NO;
    }
    
    NSInteger cCount = [[MPResourceCenter sharedMPResourceCenter] charCountInText:newText];
    NSInteger currentCount = kLCParamBodyTextMaxChar - cCount;
    //self.charCountLabel.text = [NSString stringWithFormat:@"%d", currentCount];
    NSInteger linesLeft = kTextBodyMaxLines - numberOfLines;
    self.charCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d lines", @"Letter - text: line count"), (linesLeft > -1)?linesLeft:0];
    
    CGFloat pointSize = self.charCountLabel.font.pointSize;
    
    // If limit reached, mark red bold
    if (shouldAddText == NO) {
        self.charCountLabel.font = [UIFont boldSystemFontOfSize:pointSize];
        self.charCountLabel.textColor = [AppUtility colorForContext:kAUColorTypeRed1];
    }
    else if (currentCount < 0) {
        self.charCountLabel.font = [UIFont systemFontOfSize:pointSize];
        self.charCountLabel.textColor = [AppUtility colorForContext:kAUColorTypeOrange];
    }
    else {
        self.charCountLabel.font = [UIFont systemFontOfSize:pointSize];
        self.charCountLabel.textColor = [UIColor whiteColor];
    }
    return shouldAddText;
}



/*!
 @abstract Create and Add Letter Select Buttons to scroll view
 
 */
- (void) loadSelectLetterButtons {
    
    // only load letters once
    //
    if (!self.selectLetterButtons) {
        
        NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:[self.letterResources count]];
        self.selectLetterButtons = buttons;
        [buttons release];
        
        BOOL didEncounterMissingImage = NO;
        CGPoint missingLetterImageCenterPoint = CGPointZero;
        
        // load select images
        //
        int i=0;
        for (CDResource *iResource in self.letterResources) {
            
            CGRect resourceRect = [self rectForButtonAtIndex:i];
            
            ResourceButton *resourceButton = [[ResourceButton alloc] initWithFrame:resourceRect resource:iResource];
            [resourceButton addTarget:self action:@selector(pressResourceButton:) forControlEvents:UIControlEventTouchUpInside]; 
            [resourceButton addShadow];
            resourceButton.tag = LETTER_RESOURCE_TAG;
            
            // Hide missing downloads
            //
            if (didEncounterMissingImage == NO) {
                UIImage *image = [resourceButton imageForState:UIControlStateNormal];
                if (!image) {
                    didEncounterMissingImage = YES;
                    missingLetterImageCenterPoint = resourceButton.center;
                }
            }
            
            // hide remaining buttons
            if (didEncounterMissingImage) {
                resourceButton.alpha = 0.0;
            }
            
            [self.selectLetterButtons addObject:resourceButton];
            [self.selectionView addSubview:resourceButton];
            [resourceButton release];
            
            // Add name tag
            UIFont *nameFont = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
            /*
             letter name are formated: en, zh, cn
             !! if add additional lang in the future, should not keep adding it here.
             Better to have the server provide the correct letter name in the first place.
             */
            NSArray *letterNames = [iResource.text componentsSeparatedByString:@","];
            NSString *letterName = nil;
            NSString *lang = [AppUtility devicePreferredLanguageCode];
            if ([letterNames count] == 3) {
                if ([lang isEqualToString:@"zh"]) {
                    letterName = [letterNames objectAtIndex:1];
                }
                else if ([lang isEqualToString:@"cn"]) {
                    letterName = [letterNames objectAtIndex:2];
                }
                else {
                    letterName = [letterNames objectAtIndex:0];
                }
            }
            // in case name is not split by "," - take the whole text as the name
            else{
                letterName = iResource.text;
            }
            
            
            CGSize nameSize = [letterName sizeWithFont:nameFont];
            // Add padding
            nameSize = CGSizeMake(nameSize.width + 12.0, nameSize.height + 3.0);
            
            UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(resourceRect.origin.x + (resourceRect.size.width-nameSize.width)/2.0, resourceRect.origin.y+resourceRect.size.height+6.0, nameSize.width, nameSize.height)];
            nameLabel.font = nameFont;
            nameLabel.textAlignment = UITextAlignmentCenter;
            nameLabel.textColor = [UIColor whiteColor];
            nameLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
            
            nameLabel.text = letterName;
            [nameLabel addRoundedCornerRadius:4.0];
            [self.selectionView addSubview:nameLabel];
            [nameLabel release];
            
            i++;
        }
        
        
        // add activity indicator
        if (didEncounterMissingImage) {
            
            UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            //activityIndicator.backgroundColor = [UIColor blueColor];
            activityIndicator.center = missingLetterImageCenterPoint;
            activityIndicator.hidesWhenStopped = YES;
            activityIndicator.tag = ACTIVITY_TAG;
            [self.selectionView addSubview:activityIndicator];
            [activityIndicator startAnimating];
            [activityIndicator release];
        }
    }

    
}


#pragma mark - View lifecycle




// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    
    //CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    // in case it is pushed onto stack, this view should not go backwards in a wizard flow
    self.navigationItem.hidesBackButton = YES;
    
    self.title = NSLocalizedString(@"Letter", @"Letter - Title: view title");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    
    // setup nav buttons
    // - next step is required before sending
    if (letterMode == kLCModeCreate) {
        UIBarButtonItem *nextButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Next", @"Letter - button: go to next step") 
                                                          buttonType:kAUButtonTypeBarHighlight 
                                                              target:self action:@selector(pressNext:)];
        nextButton.enabled = YES;
        self.navigationItem.rightBarButtonItem = nextButton;
        
    }
    // if sending right away
    //
    else {
        NSString *buttonTitle = NSLocalizedString(@"Send", @"Letter - button: sends letter");
        UIBarButtonItem *sendButton = [AppUtility barButtonWithTitle:buttonTitle
                                                          buttonType:kAUButtonTypeBarHighlight 
                                                              target:self action:@selector(pressNext:)];
        sendButton.enabled = YES;
        self.navigationItem.rightBarButtonItem = sendButton;
    }
    
    UIBarButtonItem *cancelButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Cancel", @"Composer - button: cancel status edit") 
                                                        buttonType:kAUButtonTypeBarNormal 
                                                            target:self action:@selector(pressCancel:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    
    
    
    // Add background
    // - use backImage as background
    //
    UIImageView *backView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, kLCPageWidth, kLCPageHeight)];
    backView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    backView.image = self.backImage;
    backView.userInteractionEnabled = YES;
    self.view = backView;
    [backView release];
    
    
    // add a black mask to fade out/in when entering and out of preview mode
    //
    UIView *maskView = [[UIView alloc] initWithFrame:self.view.bounds];
    maskView.backgroundColor = [UIColor blackColor];
    maskView.tag = BACKGROUND_MASK_TAG;
    [self.view addSubview:maskView];
    [maskView release];
    
    
    // scroll background
    //
    UIScrollView *setupView = [[UIScrollView alloc] initWithFrame:backView.bounds];
    setupView.scrollEnabled = YES;
    setupView.pagingEnabled = NO;
    setupView.contentSize = CGSizeMake(kLCPageWidth, kLCPageHeight);
    setupView.backgroundColor = [UIColor clearColor];
    setupView.delegate = self;
    [self.view addSubview:setupView];
    self.baseScrollView = setupView;
    [setupView release];
    
    
    // Add Letter background
    // - hide keypad when tapped
    UITapGestureRecognizer *tapLetter = [[UITapGestureRecognizer alloc]
                                         initWithTarget:self action:@selector(hideKeyboard)];
    tapLetter.numberOfTapsRequired = 1;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, kLCPageWidth, kLCPageHeight)];
    imageView.contentMode = UIViewContentModeScaleToFill;
    imageView.image = [self defaultLetterImage];
    imageView.userInteractionEnabled = YES;
    [imageView addGestureRecognizer:tapLetter];
    [tapLetter release];
    self.letterView = imageView;
    [imageView release];
    [self.baseScrollView addSubview:self.letterView];
    
    
    // Add text edit background views
    // - for to field
    /*UIImageView *newToImage = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, kTextWidthMax, kTextHeightMin)];
    newToImage.image = [Utility resizableImage:[UIImage imageNamed:@"letter_text.png"] leftCapWidth:10.0 topCapHeight:10.0];
    [self.letterView addSubview:newToImage];
    self.toBackView = newToImage;
    [newToImage release];
    */
    
    // body background image
    //
    UIImageView *newBodyImage = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, kTextWidthMax, kTextHeightMax)];
    newBodyImage.image = [Utility resizableImage:[UIImage imageNamed:@"letter_text.png"] leftCapWidth:10.0 topCapHeight:10.0];
    [self.letterView addSubview:newBodyImage];
    self.bodyBackView = newBodyImage;
    [newBodyImage release];
    
    
    // from background image
    //
    /*UIImageView *newFromImage = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, kTextWidthMax, kTextHeightMin)];
    newFromImage.image = [Utility resizableImage:[UIImage imageNamed:@"letter_text.png"] leftCapWidth:10.0 topCapHeight:10.0];
    [self.letterView addSubview:newFromImage];
    self.fromBackView = newFromImage;
    [newFromImage release];
    */
    UIFont *textFont = [AppUtility fontPreferenceWithContext:kAUFontSystemStandardPlus];
    
    NSString *salutation = [NSString stringWithFormat:NSLocalizedString(@"Dear %@,", @"Letter - text: salutation for letter"), [self.toName length] > 0?self.toName:@""];
    
    // to field
    //
    /*UITextField *newToField = [[UITextField alloc] initWithFrame:CGRectMake(0.0, 0.0, kTextWidthMax, kTextHeightMin)];

    newToField.placeholder = NSLocalizedString(@"Greeting", @"Letter - placeholder: tells users provide a greeting");
    newToField.font = textFont;
    newToField.text = salutation;
    newToField.returnKeyType = UIReturnKeyDone;
    newToField.delegate = self;
    newToField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.toField = newToField;
    [self.letterView addSubview:self.toField];
    [newToField release];
     */
    
    // body field
    //
    UITextView *newBodyField = [[UITextView alloc] initWithFrame:CGRectMake(0.0, 0.0, kTextWidthMax, kTextHeightMax)];
    newBodyField.textColor = [UIColor blackColor];
    newBodyField.font = textFont;
    newBodyField.backgroundColor = [UIColor clearColor];
    newBodyField.delegate = self;
    newBodyField.scrollEnabled = NO;
    newBodyField.contentInset = UIEdgeInsetsMake(-4.0,-8.0,0,0);
    newBodyField.text = salutation;
    self.bodyTextView = newBodyField;
    [newBodyField release];
    [self.letterView addSubview:self.bodyTextView];
    
    // hidden body field
    // - with actual text
    // create text view
    // - not added as a subview anywhere 
    CGRect maxRect = CGRectMake(0.0, 0.0, kTextWidthMax, kTextHeightMax);
    TextEmoticonView *newTEView = [[TextEmoticonView alloc] initWithFrame:maxRect];
    newTEView.font = textFont;
    self.bodyTEView = newTEView;
    [newTEView release];
    
    // from field
    //
    /*UITextField *newFromField = [[UITextField alloc] initWithFrame:CGRectMake(0.0, 0.0, kTextWidthMax, kTextHeightMin)];
    newFromField.font = textFont;
    newFromField.placeholder = NSLocalizedString(@"Signature", @"Letter - placeholder: tells users to sign the letter");
    newFromField.textAlignment = UITextAlignmentRight;
    newFromField.returnKeyType = UIReturnKeyDone;
    newFromField.delegate = self;
    self.fromField = newFromField;
    [self.letterView addSubview:self.fromField];
    [newFromField release];
     
    
    // fill in nickname
    NSString *yourNick = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingNickName];
    if (yourNick) {
        self.fromField.text = yourNick;
    }
    */
    
    [self layoutLetterElementsAnimated:NO];
    
    // show toolbar
    self.navigationController.toolbarHidden = NO;
    self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
    [self setToolBarLetterEditAnimated:NO];
    
    
    
    // add selection view background
    //
    UIImageView *selectBackView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, kLCPageHeight, kLCPageWidth, kLCPageHeight)];
    selectBackView.image = [UIImage imageNamed:@"friend_photo_bk.jpg"];
    [self.baseScrollView addSubview:selectBackView];
    [selectBackView release];
    
    // add letter selection view
    //
    NSUInteger selectPageNumber = ceil([self.letterResources count]/(CGFloat)kLCLettersPerPage);
    UIScrollView *newScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, kLCPageHeight, kLCPageWidth, kLCPageHeight)];
    newScrollView.scrollEnabled = YES;
    newScrollView.pagingEnabled = YES;
    newScrollView.contentSize = CGSizeMake(kLCPageWidth*selectPageNumber, kLCPageHeight);
    newScrollView.backgroundColor = [UIColor clearColor];
    newScrollView.delegate = self;
    [self.baseScrollView addSubview:newScrollView];
    self.selectionView = newScrollView;
    [newScrollView release];
    
    
    // add page indicator
    //
    UIPageControl *pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(60.0, kLCPageHeight*2.0-65.0, 200.0, 20.0)];
	[pageControl setBackgroundColor:[UIColor clearColor]];
    pageControl.numberOfPages = selectPageNumber;
    pageControl.currentPage = 0;
	[pageControl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventTouchUpInside];	
    self.selectPageControl = pageControl;
	[pageControl release];
	[self.baseScrollView addSubview:self.selectPageControl];
    
    
    // add keyboard button
    //
    UIButton *newKeyButton = [[UIButton alloc] initWithFrame:CGRectMake(272.0, kLCPageHeight, 48.0, 48.0)]; // bottom right
    //UIButton *newKeyButton = [[UIButton alloc] initWithFrame:CGRectMake(272.0, 152.0, 48.0, 48.0)];
    //UIButton *newKeyButton = [[UIButton alloc] initWithFrame:CGRectMake(270.0, 0.0, 48.0, 48.0)]; // top right
    //UIButton *newKeyButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, kLCPageHeight, 51.0, 42.0)]; // bottom left
    newKeyButton.backgroundColor = [UIColor clearColor];
    newKeyButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:newKeyButton];
    self.keyboardButton = newKeyButton;
    [newKeyButton release];
    self.keyboardButton.alpha = 0.0;
    [self setKeyboardButtonIsEmoticon:YES];
    
    // body char count label
    //
    CGRect countRect = CGRectMake(276.0, kLCPageHeight, 40.0, 14.0);
    //CGRect countRect = CGRectMake(276.0, 138.0, 40.0, 14.0);
    
    UILabel *countLabel = [[UILabel alloc] initWithFrame:countRect];
    countLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
    countLabel.textAlignment = UITextAlignmentCenter;
    countLabel.textColor = [UIColor whiteColor];
    countLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
    [countLabel addRoundedCornerRadius:4.0];
    countLabel.alpha = 0.0;
    countLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d lines", @"Letter - text: line count"), kTextBodyMaxLines];
    //countLabel.text = [NSString stringWithFormat:@"%d", kLCParamBodyTextMaxChar];
    countLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    self.charCountLabel = countLabel;
    [self.view addSubview:countLabel];
    [countLabel release];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidDownload:) name:MP_RESOURCECENTER_DID_DOWNLOAD_RESOURCE_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleButtonSetPreviewImage:) name:MP_RESOURCEBUTTON_DID_SET_PREVIEW_IMAGE_NOTIFICATION object:nil];
    
    
    // make sure select buttons exists
    [self loadSelectLetterButtons];
    
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self registerForKeyboardNotifications];
}


- (void)viewDidUnload
{
    
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    DDLogInfo(@"LC-vwa");
    [super viewWillAppear:animated];
    
    
    
}

- (void) viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Button



/*!
 @abstract check if the download resource is ours and udpate view appropriately
 */
- (void) handleDidDownload:(NSNotification *)notification {
    
    
    NSManagedObjectID *resourceID = [notification object];

    // check if hidden letter buttons views have images now
    //
    for (ResourceButton *iButton in self.selectLetterButtons) {

        // if hidden
        //
        if (iButton.alpha == 0.0) {
            
            // for downloaded resource set it's image
            if ([resourceID isEqual:[iButton.resource objectID]]) {
                [iButton setPreviewImage];
                
                // check if default image is now downloaded
                //
                if ([iButton.resource.resourceID isEqualToString:self.letterID]) {
                    self.letterView.image = [self defaultLetterImage];
                }
                break;
            }
        
        }
    }
}


/*!
 @abstract Check if we need to move the activity indicator and stop it
 */
- (void) handleButtonSetPreviewImage:(NSNotification *)notification {
    
    BOOL stillDownloading = NO;
    UIActivityIndicatorView *actView = (UIActivityIndicatorView *)[self.selectionView viewWithTag:ACTIVITY_TAG];
    
    // check if hidden views have images now
    //
    for (ResourceButton *iButton in self.selectLetterButtons) {
        
        // for first hidden button encountered, then set indicator location here
        //
        if (iButton.alpha == 0.0) {
            
            actView.center = iButton.center;
            stillDownloading = YES;
            break;
            
        }
    }
    
    // if no more buttons are downloading, then stop indicator
    if (!stillDownloading) {
        [actView stopAnimating];
    }
}



/*!
 @abstract Rect for resource Button
 
 */
- (CGRect)rectForButtonAtIndex:(NSUInteger)index {
    
    CGFloat thisPage =  floor(index/(CGFloat)kLCLettersPerPage);
    CGPoint leftCorner = CGPointMake(kLCPageWidth*thisPage, 0.0);
    
    NSUInteger pageIndex = index%kLCLettersPerPage;   
    
    CGFloat originX = pageIndex%kLCLettersPerRow*kLCPageShiftX + leftCorner.x + kLCPageStartX;
    CGFloat originY = (pageIndex/kLCLettersPerRow)*kLCPageShiftY + leftCorner.y + kLCPageStartY;
    CGRect resourceRect = CGRectMake(originX, originY, kLCParamLetterWidthPreview, kLCParamLetterHeightPreview);
    
    return resourceRect;    
}




/*!
 @abstract Pressed Select Letter button
 */
- (void) pressOpenSelect:(id)sender {
    
    [self hideKeyboard];
    
    //UIView *previouslyLoadedLetter = [self.baseScrollView viewWithTag:LETTER_RESOURCE_TAG];
    
    
    // expand view and scroll down
    [self.baseScrollView setContentSize:CGSizeMake(kLCPageWidth, kLCPageHeight*2.0)];
    [UIView animateWithDuration:0.3 
                     animations:^{
                         [self.baseScrollView setContentOffset:CGPointMake(0.0, kLCPageHeight) animated:NO];
                     } 
                     completion:^(BOOL finished){
                         self.baseScrollView.scrollEnabled = NO;
                     }];
    
    // change tool bar buttons
    //
    [self setToolBarLetterSelectAnimated:YES];
    

    
}




/*!
 @abstract Edit Select Letter Mode
 
 */
- (void) pressCloseSelect:(id)sender {
    
    self.baseScrollView.scrollEnabled = YES;
    
    // shrink view and scroll up
    [UIView animateWithDuration:0.3 
                     animations:^{
                         [self.baseScrollView setContentOffset:CGPointMake(0.0, 0.0) animated:NO];
                     } 
                     completion:^(BOOL finished){
                         [self.baseScrollView setContentSize:CGSizeMake(kLCPageWidth, kLCPageHeight)];
                     }];
    
    // change tool bar buttons
    //
    [self setToolBarLetterEditAnimated:YES];
}


/*!
 @abstract Pressed Select Letter resource button
 - So load the new letter image and close select view
 */
- (void) pressResourceButton:(id)sender {
    
    CDResource *selectedLetter = [(ResourceButton *)sender resource];
    
    UIImage *letterImage = [selectedLetter getImageForType:kRSImageTypeLetterFull];
    
    // update with new letter image
    if (letterImage) {
        self.letterID = selectedLetter.resourceID;
        self.letterView.image = letterImage;
    }
    
    [self pressCloseSelect:nil];
}

/*!
 @abstract Show preview version of the letter
 */
- (void) pressPreview:(id)sender {
    
    // create final letter image
    //
    UIImage *previewImage = [self getPreviewLetterImage];
    UIView *maskView = [self.view viewWithTag:BACKGROUND_MASK_TAG];
    
    UIImageView *previewView = [[[UIImageView alloc] initWithFrame:self.letterView.frame] autorelease];
    previewView.image = previewImage;
    previewView.alpha = 0.0;
    previewView.userInteractionEnabled = YES;
    
    [previewView addShadow];
    
    /*previewView.layer.masksToBounds = NO;
     previewView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
     previewView.layer.shadowRadius = 4.0;
     previewView.layer.shadowOpacity = 1.0;*/
    //previewView.layer.shadowPath = [UIBezierPath bezierPathWithRect:previewView.bounds].CGPath;
    
    
    previewView.tag = PREVIEW_TAG;
    [self.baseScrollView addSubview:previewView];
    
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc]
                                               initWithTarget:self action:@selector(handlePreviewSingleTap:)];
    singleFingerTap.numberOfTapsRequired = 1;
    [previewView addGestureRecognizer:singleFingerTap];
    [singleFingerTap release];
    
    
    CGRect newFrame = CGRectMake((kLCPageWidth-kLCLetterWidthPreview)/2.0, (kLCPageHeight-kLCLetterHeightPreview)/2.0, kLCLetterWidthPreview, kLCLetterHeightPreview);
    
    
    [UIView animateWithDuration:0.3 
                     animations:^{
                         previewView.alpha = 1.0;
                         [self.navigationController setToolbarHidden:YES animated:YES];
                     }
                     completion:^(BOOL finished){
                         if (finished) {
                             
                             // hide editing views
                             self.letterView.hidden = YES;
                             self.toField.hidden = YES;
                             self.fromField.hidden = YES;
                             self.bodyTextView.hidden = YES;
                             self.toBackView.hidden = YES;
                             self.fromBackView.hidden = YES;
                             self.bodyBackView.hidden = YES;
                             
                             [UIView animateWithDuration:0.3 
                                              animations:^{
                                                  previewView.frame = newFrame;
                                                  maskView.alpha = 0.75;
                                              }
                                              completion:^(BOOL finished){
                                                  if (finished) {
                                                  } 
                                              }];
                         } 
                     }];
}

/*!
 @abstract Ends preview mode
 
 - enlarge preivew
 - show edit views below and fade out preview
 
 */
- (void) endPreview { 
    
    UIView *previewView = [self.baseScrollView viewWithTag:PREVIEW_TAG];
    UIView *maskView = [self.view viewWithTag:BACKGROUND_MASK_TAG];
    
    [UIView animateWithDuration:0.3 
                     animations:^{
                         previewView.frame = self.letterView.frame;
                         maskView.alpha = 1.0;
                     }
                     completion:^(BOOL finished){
                         if (finished) {
                             
                             // hide editing views
                             self.letterView.hidden = NO;
                             self.toField.hidden = NO;
                             self.fromField.hidden = NO;
                             self.bodyTextView.hidden = NO;
                             self.toBackView.hidden = NO;
                             self.fromBackView.hidden = NO;
                             self.bodyBackView.hidden = NO;
                             
                             [UIView animateWithDuration:0.3 
                                              animations:^{
                                                  previewView.alpha = 0.0;
                                                  [self.navigationController setToolbarHidden:NO animated:YES];
                                              }
                                              completion:^(BOOL finished){
                                                  if (finished) {
                                                      [previewView removeFromSuperview];
                                                  } 
                                              }];
                         } 
                     }];
}

/*!
 @abstract Handle tap on preview - close preview 
 
 - enlarge preivew
 - show edit views below and fade out preview
 
 */
- (void)handlePreviewSingleTap:(UITapGestureRecognizer *)sender {     
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self endPreview];
    } 
}

/*!
 @abstract Sends out letter
 */
- (void) sendOutLetter {
    
    // take picture of letter image
    //
    UIImage *letterFinishedImage = [self getPreviewLetterImage];
    NSString *newLetterID = self.letterID; // @"1"; // 
    
    if ([self.delegate respondsToSelector:@selector(LetterController:letterImage:letterID:)]) {
        [self.delegate LetterController:self letterImage:letterFinishedImage letterID:newLetterID];
    }
    
}

/*!
 @abstract Finished creating letter and ready to go to next step
 - same for "next" or "send"
 - the delegate is responsible for what to do with letter image and letterID
 
 */
- (void) pressNext:(id)sender {
    
    
    if ([self.bodyTextView.text length] > 0) {
        [self sendOutLetter];
    }
    else {
        NSString *title = NSLocalizedString(@"Send Letter", @"Letter - alert title: confirm empty fields");
        NSString *detMsg = NSLocalizedString(@"Send this letter without a body?", @"Letter - alert text: confirm empty body");
        
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                         message:detMsg
                                                        delegate:self
                                               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Letter: cancel")
                                               otherButtonTitles:NSLocalizedString(@"Send", @"Letter: send w/o body"), nil] autorelease];
        [alert show];
    }
}


/*!
 @abstract Cancel letter creation process
 */
- (void) pressCancel:(id)sender {
    
    UIView *previewView = [self.baseScrollView viewWithTag:PREVIEW_TAG];
    
    // if preview is still showing, end preview instead of exiting
    if (previewView) {
        [self endPreview];
    }
    else {
        [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark - UIAlertViewDelegate Methods

/*!
 @abstract User confirms to send out letter without body
 */
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // confirm submit ID
	if (buttonIndex != [alertView cancelButtonIndex]) {
		[self sendOutLetter];
	}
}


#pragma mark - Scroll Methods


- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    if (sender == self.baseScrollView) {
        
    }
    else {
        
        // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
        // which a scroll event generated from the user hitting the page control triggers updates from
        // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
        if (self.pageControlUsed)
        {
            // do nothing - the scroll was initiated from the page control, not the user dragging
            return;
        }
        
        // Switch the indicator when more than 50% of the previous/next page is visible
        CGFloat pageWidth = kLCPageWidth;
        int page = floor((sender.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
        self.selectPageControl.currentPage = page;
    }
}

// At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView == self.baseScrollView) {
        UIView *first = [self.view findFirstResponder];
        if (first) {
            [first resignFirstResponder];
        }
    }
    else if (scrollView == self.selectionView) {
        self.pageControlUsed = NO;
    }
    
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == self.selectionView) {
        self.pageControlUsed = NO;
    }
}


- (void)changePage:(id)sender
{
    int page = self.selectPageControl.currentPage;
    
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    /*[self loadScrollViewWithPage:page - 1];
     [self loadScrollViewWithPage:page];
     [self loadScrollViewWithPage:page + 1];
     */
	
    // update the scroll view to the appropriate page
    CGRect frame = self.selectionView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [self.selectionView scrollRectToVisible:frame animated:YES];
    
    // Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above
    self.pageControlUsed = YES;
}



#pragma mark - TextViewDelegate


/*!
 @abstract Enable and disabled send button depending if there is text
 
 - (BOOL)textView:(UITextView *)thisTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
 
 // if deleting end, check if it is an emoticon - if so delete the entire emoticon
 NSString *currentText = thisTextView.text;
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
 
 }
 
 NSString *newText = [thisTextView.text stringByReplacingCharactersInRange:range withString:text];
 [self updateCharacterCount:newText];
 return YES;
 }*/


/*!
 @abstract called before text will change
 */
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    
    // check if it is an emoticon - if so delete the entire emoticon
    NSString *currentText = textView.text;
    
    NSRange selectedRange = textView.selectedRange;
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
                textView.text = finalText;
                textView.selectedRange = NSMakeRange(startRange.location, 0);
                
                [self updateCharacterCount:textView.text];
                
                return NO; // we modified text manually
            }
        }
    }
    
    
    
    NSString *previewString = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    //BOOL isUnderHeightLimit = [self setBodyText:previewString];
    //[self layoutLetterElementsAnimated:YES];
    
    BOOL isUnderLimit = [self updateCharacterCount:previewString];
    
    // always allow delete
    if ([text length] == 0) {
        return YES;
    }
    else {
        return isUnderLimit;
    }
    
    //return YES;
    
    //return isUnderHeightLimit;
}

/*!
 @abstract Make sure right keyboard button is showing
 */
- (void)textViewDidBeginEditing:(UITextView *)textView{
    
    BOOL isEmoticon = YES;
    if (textView.inputView && textView.inputView == self.emoticonKeypad) {
        isEmoticon = NO;
    }
    [self setKeyboardButtonIsEmoticon:isEmoticon];
    
    [UIView animateWithDuration:kMPParamAnimationStdDuration animations:^{
        self.charCountLabel.alpha = 1.0;
    }];
}


- (void) textViewDidEndEditing:(UITextView *)textView {
    [UIView animateWithDuration:kMPParamAnimationStdDuration animations:^{
        self.charCountLabel.alpha = 0.0;
    }];
}


#pragma mark - UITextField

/*!
 @abstract Make sure right keyboard button is showing
 */
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    BOOL isEmoticon = YES;
    if (textField.inputView && textField.inputView == self.emoticonKeypad) {
        isEmoticon = NO;
    }
    [self setKeyboardButtonIsEmoticon:isEmoticon];
}

/*!
 @abstract When return entered, hide keyboard
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self hideKeyboard];
    return YES;
}




#pragma mark - Keyboard Methods


/*!
 @abstract Show emoticon keyboard
 */
- (void) pressKeyboardEmoticon:(id)sender {
    
    
    // lazy create emoticon view
    // add it as a subview
    //
    if (!self.emoticonKeypad) {
        EmoticonKeypad *newKP = [[EmoticonKeypad alloc] initWithFrame:CGRectMake(0.0, 0.0, 1.0, 1.0) displayMode:kEKModeHideSticker];
        newKP.delegate = self;
        [newKP setMode:kEKModeHideSticker];
        self.emoticonKeypad = newKP;
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
    
    UITextField *firstView = (UITextField *)[self.view findFirstResponder];
    
    if (firstView) {
        // dismiss the keypad and set the new emoticon keypad!
        [firstView resignFirstResponder];
        firstView.inputView = self.emoticonKeypad;
        [firstView becomeFirstResponder];
    }
    
    // change to text keyboard mode
    [self setKeyboardButtonIsEmoticon:NO];
}


/*!
 @abstract Show emoticon keyboard
 */
- (void) pressKeyboardText:(id)sender {
    
    UITextField *firstView = (UITextField *)[self.view findFirstResponder];
    
    if (firstView) {
        // dismiss the keypad and set the new emoticon keypad!
        [firstView resignFirstResponder];
        firstView.inputView =nil;
        [firstView becomeFirstResponder];
    }
    
    // change to emoticon keyboard mode
    [self setKeyboardButtonIsEmoticon:YES];    
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
    
    
    // get the right KB height
    //
    CGFloat kbHeight = 0.0;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        kbHeight = kbSize.width;
    }
    else {
        kbHeight = kbSize.height;
    }
    
    // set inset to push the bottom of the view up
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbHeight, 0.0);
    [self.baseScrollView setContentInset:contentInsets];
    [self.baseScrollView setScrollIndicatorInsets:contentInsets];
    
    if (kbHeight > 0.0) {
        // find the first responder and make sure it is showing
        // - only needed for textfields
        // - textview scroll automatically into view
        UIView *firstResponder = [self.view findFirstResponder];
        
        if (firstResponder && [firstResponder isKindOfClass:[UITextField class]]) {
            // scroll to show message view and controls
            
            CGFloat yPoint = MIN(kLCPageHeight - kbHeight, firstResponder.frame.origin.y+firstResponder.frame.size.height-kTextHeightMin*2.0);
            
            CGPoint scrollPoint = CGPointMake(0.0, yPoint);
            [self.baseScrollView setContentOffset:scrollPoint animated:NO];
        }
        // show keyboard button
        self.keyboardButton.alpha = 1.0;
        CGRect newRect = self.keyboardButton.frame;
        CGFloat viewHeight = self.view.frame.size.height; //kLCPageHeight
        self.keyboardButton.frame = CGRectMake(newRect.origin.x, viewHeight-kbHeight-newRect.size.height, newRect.size.width, newRect.size.height);
        
        CGRect countRect = self.charCountLabel.frame;
        self.charCountLabel.frame = CGRectMake(countRect.origin.x, self.keyboardButton.frame.origin.y - 14.0, countRect.size.width, countRect.size.height);
    }
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
    [self.baseScrollView setContentInset:contentInsets];
    [self.baseScrollView setScrollIndicatorInsets:contentInsets];
    
    // show keyboard button
    self.keyboardButton.alpha = 0.0;
    
    self.keyboardButton.frame = CGRectMake(272.0, kLCPageHeight, 48.0, 48.0);
    self.charCountLabel.frame = CGRectMake(276.0, kLCPageHeight, 40.0, 14.0);
    
    [UIView commitAnimations];
}



#pragma mark - EmoticonKeypad Delegate

/*!
 @abstract User pressed delete key
 */
- (void)EmoticonKeypad:(EmoticonKeypad *)emoticonKeypad pressDelete:(id)sender {
    
    UITextView *first = (UITextView *)[self.view findFirstResponder];
    
    if (first) {
        
        // check if it is an emoticon - if so delete the entire emoticon
        NSString *currentText = first.text;
        
        NSRange selectedRange = first.selectedRange;
        
        // if at start nothing to do
        if (selectedRange.location == 0 && selectedRange.length == 0) {
            return;
        }
        
        NSString *startText = [currentText substringToIndex:selectedRange.location];
        NSString *endText = [currentText substringFromIndex:selectedRange.location + selectedRange.length];
        
        // if selected, just delete that selected text
        if (selectedRange.length > 0) {
            
            first.text = [startText stringByAppendingString:endText];
            first.selectedRange = NSMakeRange(selectedRange.location, 0);
            
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
                first.text = finalText;
                first.selectedRange = newSelectedRange;
            }
        }

        
        /*
        // if deleting end, check if it is an emoticon - if so delete the entire emoticon
        NSString *currentText = first.text;
        if ([currentText hasSuffix:@")"]) {
            
            // search backwards to find "("
            NSRange startRange = [currentText rangeOfString:@"(" options:NSBackwardsSearch];
            if (startRange.location != NSNotFound) {
                NSString *isEmoticonText = [currentText substringFromIndex:startRange.location];
                CDResource *emoticon = [[MPResourceCenter sharedMPResourceCenter] emoticonForText:isEmoticonText];
                if (emoticon) {
                    first.text = [currentText substringToIndex:startRange.location];
                }
            }
        }
        // just delete one char otherwise
        else if ([currentText length] > 0) {
            first.text = [currentText substringToIndex:[currentText length]-1];
        }
        
        if ((UITextView *)first == self.bodyTextView) {
            [self updateCharacterCount:first.text];
        }
        */
        //[self updateCharacterCount:self.textView.text];
    }
}

/*!
 @abstract User pressed this resource
 
 - emoticon & petphrase: appends text
 - sticker: send resource to chat scroll view to display
 
 */
- (void)EmoticonKeypad:(EmoticonKeypad *)emoticonKeypad resource:(CDResource *)resource {
    
    
    UITextField *first = (UITextField *)[self.view findFirstResponder];
    
    if (first) {
        if ((UITextView *)first == self.bodyTextView) {
            
            UITextView *textView = (UITextView *)first;
            
            // check if under limit first
            NSString *previewContent = [textView.text stringByReplacingCharactersInRange:[textView selectedRange] withString:resource.text];
            
            BOOL isUnderLimit = [self updateCharacterCount:previewContent];
            
            if (isUnderLimit) {
                // text based: emoticons and petphrase
                //
                RCType rcType = [resource rcType];
                
                // emoticon and petphrase, just append the new text
                //
                if (rcType == kRCTypeEmoticon || rcType == kRCTypePetPhrase) {
                    
                    [first insertText:resource.text];
                    //[self updateCharacterCount:self.textView.text];
                }
            }
        }
        // always insert for uitextfields
        else {
            [first insertText:resource.text];
        }
    }
}




@end
