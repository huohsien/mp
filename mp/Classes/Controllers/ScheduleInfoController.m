//
//  ScheduleInfoController.m
//  mp
//
//  Created by Min Tsai on 1/21/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "ScheduleInfoController.h"
#import "CDMessage.h"
#import "MPFoundation.h"
#import "TKImageLabel.h"
#import "CDResource.h"
#import "StickerButton.h"
#import "TextEmoticonView.h"

#import "DialogMessageCellController.h"


CGFloat const kSIContentSizeMax = 195.0;


@interface ScheduleInfoController (Private)

- (void)setToText:(NSString *)newToString;

@end



@implementation ScheduleInfoController

@synthesize scheduledMessage;

- (void) dealloc {
    
    [scheduledMessage release];
    [super dealloc];
}

/*!
 @abstract initilizes view controller
 
 @param scheduldMessage The message's info to review
 */
- (id) initWithScheduledMessage:(CDMessage *)newScheduledMessage {
    
    self = [super init];
    if (self) {
        self.scheduledMessage = newScheduledMessage;
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

#define TEXTVIEW_TAG        15001
#define COUNT_TAG           15002
#define TEXTKP_BTN_TAG      15003
#define EMOTICONKP_BTN_TAG  15004

#define TO_NUMBER_BTN_TAG   16001
#define TO_BTN_TAG          16002
#define DATE_BTN_TAG        16003
#define MSG_LABEL_TAG       16006

#define STICKER_TAG         17001


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    self.title = NSLocalizedString(@"Schedule Info", @"ScheduleInfo - title: view a scheduled message information");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    
    // background
    //
    UIScrollView *setupView = [[UIScrollView alloc] initWithFrame:appFrame];
    setupView.scrollEnabled = YES;
    setupView.contentSize=CGSizeMake(appFrame.size.width, appFrame.size.height-kMPParamNavigationBarHeight - kMPParamTabBarHeight);
    setupView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = setupView;
    [setupView release];
    
    
    // To label
    UILabel *toLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 9.0, 80.0, 14.0)];
    [AppUtility configLabel:toLabel context:kAULabelTypeGrayMicroPlus];
    toLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    toLabel.text = NSLocalizedString(@"To:", @"ScheduleInfo - text: To which friends is scheduled messgae for");
    [self.view addSubview:toLabel];
    [toLabel release];
    
    
    // To button
    UIButton *toButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, 24.0, 310.0, 50.0)];
    [AppUtility configButton:toButton context:kAUButtonTypeGray1];
    toButton.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    // TODO: add this back
    [toButton addTarget:self action:@selector(pressTo:) forControlEvents:UIControlEventTouchUpInside];
    toButton.tag = TO_BTN_TAG;
    [self.view addSubview:toButton];
    
    
    // add blue number indicator
    TKImageLabel *blueBadge = [[TKImageLabel alloc] initWithFrame:CGRectMake(271.0, 10.0, 30.0, 30.0)];
    blueBadge.backgroundImage = [Utility resizableImage:[UIImage imageNamed:@"std_icon_badge_bl.png"] leftCapWidth:14.0 topCapHeight:14.0];
    blueBadge.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
    blueBadge.textColor = [UIColor whiteColor];
    blueBadge.textEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    blueBadge.backgroundColor = [UIColor clearColor];
    blueBadge.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
    [blueBadge setText:[NSString stringWithFormat:@"%d", [self.scheduledMessage.contactsTo count]]];
    blueBadge.tag = TO_NUMBER_BTN_TAG;
    [toButton addSubview:blueBadge];
    [blueBadge release];
    [toButton release];
    
    // set to information
    [self setToText:[self.scheduledMessage displayName]];
    
    
    // Date label
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 83.0, 80.0, 14.0)];
    [AppUtility configLabel:dateLabel context:kAULabelTypeGrayMicroPlus];
    dateLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    dateLabel.text = NSLocalizedString(@"Date/Time:", @"ScheduleInfo - text: When message should be sent for");
    [self.view addSubview:dateLabel];
    [dateLabel release];
    
    
    // Date Button
    UIButton *dateButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, 91.0, 310.0, 45.0)];
    [AppUtility configButton:dateButton context:kAUButtonTypeTextEditBar];
    [dateButton setBackgroundImage:nil forState:UIControlStateNormal];
    dateButton.backgroundColor = [UIColor clearColor];//[AppUtility colorForContext:kAUColorTypeBackground];
    dateButton.tag = DATE_BTN_TAG;
    [self.view addSubview:dateButton];
        
    NSString *dateText = [Utility shortStyleTimeDate:self.scheduledMessage.dateScheduled];
    [dateButton setTitle:dateText forState:UIControlStateNormal];
    //dateButton.enabled = NO;
    [dateButton release];
    
    
    // Message label
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 140.0, 80.0, 14.0)];
    [AppUtility configLabel:messageLabel context:kAULabelTypeGrayMicroPlus];
    messageLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    messageLabel.text = NSLocalizedString(@"Message:", @"ScheduleInfo - text: message text");
    messageLabel.tag = MSG_LABEL_TAG;
    [self.view addSubview:messageLabel];
    [messageLabel release];
    
    UIView *contentView = nil;
    CDMessageType msgType = [self.scheduledMessage.type intValue];
    
    // sticker message
    // - get sticker image
    if (msgType == kCDMessageTypeSticker) {
        
        // get sticker image and set image and text
        //
        CDResource *stickerResource = [CDResource stickerForText:self.scheduledMessage.text];
        
        CGRect stickerRect = CGRectMake(0.0, 0.0, 100.0, 100.0);
        StickerButton *stickerButton = [[StickerButton alloc] initWithFrame:stickerRect resource:stickerResource];
        stickerButton.backgroundColor = [UIColor clearColor];
        [stickerButton setTitle:NSLocalizedString(@"Select Sticker", @"CreateSchedule - text: tell users to select a sticker to send") forState:UIControlStateNormal];
        stickerButton.tag = STICKER_TAG;
        [self.view addSubview:stickerButton];
        contentView = stickerButton;
        [stickerButton release];
        
    }
    else if (msgType == kCDMessageTypeImage ||
             msgType == kCDMessageTypeLetter) {
        
        UIImage *previewImage = nil;
        
        if (msgType == kCDMessageTypeImage) {
            previewImage = self.scheduledMessage.previewImage;
        }
        // letter image
        else {
            TKFileManager *newFileManager = [[TKFileManager alloc] init];
            
            NSData *imageData = [newFileManager getFileDataForFilename:self.scheduledMessage.filename url:nil];
            previewImage = [UIImage imageWithData:imageData];
            [newFileManager release];
        }
        
        /*
         provide smaller frame to display
         */
        CGSize imageSize = [previewImage size];           
        
        // get the size of frame to show image
        //
        CGFloat imageWidth = 0.0;
        CGFloat imageHeight = 0.0;
        // - if landscape
        if (imageSize.width > imageSize.height) {
            if (imageSize.width > kSIContentSizeMax) {
                imageWidth = kSIContentSizeMax;
                imageHeight = imageSize.height * kSIContentSizeMax/imageSize.width;
            }
        }
        // - if portrait
        else {
            if (imageSize.height > kSIContentSizeMax) {
                imageHeight = kSIContentSizeMax;
                imageWidth = imageSize.width * kSIContentSizeMax/imageSize.height;
            }
        }
        // small image, then no change
        if (imageWidth == 0) {
            imageWidth = imageSize.width;
            imageHeight = imageSize.height;
        }
        
        CGRect imageRect = CGRectMake(0.0, 0.0, imageWidth, imageHeight);
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:previewImage];
        imageView.frame = imageRect;
        [imageView addShadow];
        [self.view addSubview:imageView];
        contentView = imageView;
        [imageView release];

    }
    else if (msgType == kCDMessageTypeText) {
        
        
        TextEmoticonView *textView = [[TextEmoticonView alloc] initWithFrame:CGRectZero];
        textView.backgroundColor = [UIColor clearColor];
        textView.autoresizingMask = UIViewAutoresizingNone;
        textView.userInteractionEnabled = YES;              // want data detection!
        
        UIButton *bubble = [[UIButton alloc] initWithFrame:CGRectZero];
        bubble.backgroundColor = [UIColor clearColor];
        [bubble addSubview:textView];        
                
                
        UIFont *bubbleFont = nil;
        if ([[MPSettingCenter sharedMPSettingCenter] isFontSizeLarge]) {
            bubbleFont = [AppUtility fontPreferenceWithContext:kAUFontSystemStandardPlus];
        }
        else {
            bubbleFont = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
        }
        textView.font = bubbleFont;
        
        CGFloat maxWidthBubble = 295.0;
        
        // create text view
        CGRect maxRect = CGRectMake(kDMBubblePaddingHead, kDMBubblePaddingVertical, maxWidthBubble - kDMBubblePaddingTail, 15000.0);

        textView.frame = maxRect;
        [textView setText:self.scheduledMessage.text];
        [textView sizeToFit];
        CGSize expectedLabelSize = textView.frame.size;        
        
        CGFloat bubbleWidth = expectedLabelSize.width + kDMBubblePaddingHead + kDMBubblePaddingTail;
        CGFloat bubbleHeight = expectedLabelSize.height + kDMBubblePaddingVertical*2.0;
        // don't go beyond min and max size, otherwise bubble will deform
        if (bubbleHeight < 32.0) {
            bubbleHeight = 32.0;
            
            // if text is smaller than center text vertically in bubble
            //
            CGRect newTextFrame = textView.frame;
            newTextFrame.origin.y = (32.0 - expectedLabelSize.height)/2.0;
            textView.frame = newTextFrame;
        }
        if (bubbleWidth < 40) {
            bubbleWidth = 40.0;
        }
        
        if (bubbleWidth > maxWidthBubble) {
            bubbleWidth = maxWidthBubble;
        }
        
        UIImage *myImage = [Utility resizableImage:[UIImage imageNamed:@"chat_icon_bubble_wh.png"] leftCapWidth:15.0 rightCapWidth:24.0 topCapHeight:15.0 bottomCapHeight:15.0];
        
        bubble.frame = CGRectMake(16.0, 175.0, bubbleWidth, bubbleHeight);
        [bubble setBackgroundImage:myImage forState:UIControlStateNormal];
        
        // extend scroll view for large bubbles
        UIScrollView *backScrollView = (UIScrollView *)self.view;
        CGFloat bubbleBottomHeight = bubble.frame.origin.y + bubble.frame.size.height + 15.0;
        if (bubbleBottomHeight > backScrollView.contentSize.height) {
            backScrollView.contentSize = CGSizeMake(appFrame.size.width, bubbleBottomHeight);
        }
        
        [self.view addSubview:bubble];
        [textView release];
        [bubble release];
        
        
        // textfield background image
        //
        /* old text background 
        UIImageView *textBackImage = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, 165.0, 310.0, kSIContentSizeMax)];
        textBackImage.image = [Utility resizableImage:[UIImage imageNamed:@"std_icon_textbar.png"] leftCapWidth:9.0 topCapHeight:22.0];
        textBackImage.userInteractionEnabled = YES;
        [self.view addSubview:textBackImage];
        
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(5.0, 5.0, 300.0, kSIContentSizeMax-10.0)];
        scrollView.scrollEnabled = YES;
        [textBackImage addSubview:scrollView];
        [textBackImage release];
        
        TextEmoticonView *textLabel = [[TextEmoticonView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 9999.0)];
        [AppUtility configLabel:(UILabel *)textLabel context:kAULabelTypeBlackSmall];
        textLabel.verticalAlignment = TETextVerticalAlignmentTop;
        //statusLabel.lineBreakMode = UILineBreakModeTailTruncation;
        //textLabel.numberOfLines = 3;
        [textLabel setText:self.scheduledMessage.text];
        [textLabel sizeToFit];
        [scrollView setContentSize:CGSizeMake(scrollView.frame.size.width, textLabel.frame.size.height)];
        [scrollView addSubview:textLabel];
        [scrollView release];
        [textLabel release];
         */
        
    }
    
    
    // center content view at the bottom: sticker & image only
    if (contentView) {

        CGSize boundsSize = self.view.bounds.size;
        CGSize contentSize = contentView.frame.size;

        UIView *messageLabel = [self.view viewWithTag:MSG_LABEL_TAG];
        CGFloat topY = messageLabel.frame.origin.y;
        
        
        CGRect contentRect = CGRectMake((boundsSize.width - contentSize.width)/2.0, topY + (boundsSize.height - topY - contentSize.height - 44.0-48.0)/2.0 , contentSize.width, contentSize.height);
        
        contentView.frame = contentRect;
    }
    
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*UIBarButtonItem *doneButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Done", @"ScheduleInfo - button: done viewing scheduled messsage") 
                                                      buttonType:kAUButtonTypeBarHighlight 
                                                          target:self action:@selector(pressDone:)];
    doneButton.enabled = YES;
    self.navigationItem.rightBarButtonItem = doneButton;
    */
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated {
    DDLogInfo(@"SIC-vwa");
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
        
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
    
}


#pragma mark - Utility

/*!
 @abstract modify To recipients
 */
- (void)setToText:(NSString *)newToString {
    
    UIButton *toButton = (UIButton *)[self.view viewWithTag:TO_BTN_TAG];
    
    UIColor *textColor = [UIColor blackColor];
    // update name button
    if ([newToString length] == 0) {
        textColor = [AppUtility colorForContext:kAUColorTypeLightGray1];
        [toButton setTitle:NSLocalizedString(@"Recipients", @"CreateSchedule - placeholder: press to select contacts to send to") forState:UIControlStateNormal];
    }
    else {
        [toButton setTitle:newToString forState:UIControlStateNormal];
    }
    
    [toButton setTitleColor:textColor forState:UIControlStateNormal];
}

#pragma mark - Button

/*!
 @abstract cancel edit
 */
- (void)pressDone:(id)sender {
    
    // if presented modally, we need to present done button
    if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
        [self dismissModalViewControllerAnimated:YES];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}



/*!
 @abstract show list of recipients
 
 */
- (void)pressTo:(id)sender {
    
    SelectContactController *nextController = [[SelectContactController alloc] 
                                               initWithTableStyle:UITableViewStylePlain 
                                               type:kMPSelectContactTypeReadOnly
                                               viewContacts:self.scheduledMessage.contactsTo];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
    
}

@end    

