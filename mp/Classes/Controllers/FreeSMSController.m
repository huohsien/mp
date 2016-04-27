//
//  FreeSMSController.m
//  mp
//
//  Created by Min Tsai on 3/5/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "FreeSMSController.h"
#import "MPFoundation.h"
#import "ContactProperty.h"

@implementation FreeSMSController

@synthesize contactProperties;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

#define MESSAGE_LABEL_TAG   15001


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{

    self.title = NSLocalizedString(@"Free SMS", @"FreeSMS - title: free sms preview");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];

    
    // setup buttons
    //
    UIBarButtonItem *cancelButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Cancel", @"FreeSMS - button: close location view") 
                                                       buttonType:kAUButtonTypeBarNormal 
                                                           target:self action:@selector(pressCancel:)];
    cancelButton.enabled = YES;
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UIBarButtonItem *doneButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Send", @"FreeSMS - button: send out SMS") 
                                                        buttonType:kAUButtonTypeBarHighlight
                                                            target:self action:@selector(pressSend:)];
    doneButton.enabled = YES;
    self.navigationItem.rightBarButtonItem = doneButton;
    
    
    // background
    //
    UIScrollView *setupView = [[UIScrollView alloc] initWithFrame:appFrame];
    setupView.scrollEnabled = YES;
    setupView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = setupView;
    [setupView release];
    
    
    // recepient label
    //
    NSString *textString = [NSString stringWithFormat:NSLocalizedString(@"Recipients (%d):", @"FreeSMS - text: which contacts we will send free sms to"), [self.contactProperties count]];
    CGSize textSize = [textString sizeWithFont:[AppUtility fontPreferenceWithContext:kAUFontSystemMicroPlus]];
    UILabel *recipientLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 6.0, textSize.width, 20.0)];
    [AppUtility configLabel:recipientLabel context:kAULabelTypeGrayMicroPlus];
    recipientLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    recipientLabel.text = textString;
    [self.view addSubview:recipientLabel];

    CGFloat currentX = recipientLabel.frame.origin.x + recipientLabel.frame.size.width + 5.0;
    CGFloat currentY = 6.0;
    
    [recipientLabel release];
    

    // add recepient buttons
    //
    for (ContactProperty *iProperty in self.contactProperties) {

        // limit name width
        CGSize fullNameSize = [iProperty.name sizeWithFont:[AppUtility fontPreferenceWithContext:kAUFontSystemMicroPlus]];
        CGFloat nameWidth = MIN(fullNameSize.width+20.0, 150.0);
        
        // if not enough room, go to next line
        if (currentX + nameWidth > 310.0) {
            currentX = 10.0;
            currentY += 26.0;
        }
        
        UIButton *propertyButton = [[UIButton alloc] initWithFrame:CGRectMake(currentX, currentY, nameWidth, 20.0)];
                                    
        [propertyButton setBackgroundImage:[Utility resizableImage:[UIImage imageNamed:@"sms_icon.png"] leftCapWidth:15.0 topCapHeight:10.0] forState:UIControlStateNormal];
        
        propertyButton.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
        propertyButton.opaque = YES;
        
        [propertyButton setTitleEdgeInsets:UIEdgeInsetsMake(1.0, 0.0, 0.0, 0.0)];
        
        [propertyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        propertyButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicroPlus];
        propertyButton.titleLabel.textAlignment = UITextAlignmentCenter;
        propertyButton.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
        [propertyButton setTitle:iProperty.name forState:UIControlStateNormal];
        
        [self.view addSubview:propertyButton];
        [propertyButton release];
        // set to next location
        //
        currentX += nameWidth + 5.0;
    }
    
    // add separator
    //
    currentY += 23.0;
    UIImage *line = [Utility resizableImage:[UIImage imageNamed:@"sms_line.png"] leftCapWidth:1.0 topCapHeight:1.0];
    UIImageView *lineView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, currentY, appFrame.size.width, 2.0)];
    lineView.image = line;
    [self.view addSubview:lineView];
    [lineView release];

    
    // add sms content
    //
    /* Deprecated - read string from downloadable text files

    NSError *error = nil;
    NSString *contentPath = [AppUtility pathForDownloadableContentWithFilename:kMPFileTellFriendFree];
    
    NSStringEncoding enc;
    NSString *contentString = [NSString stringWithContentsOfFile:contentPath usedEncoding:&enc error:&error];
    
    if (error) {
        NSAssert1(0, @"Failed to read free sms msg file with error '%@'.", [error localizedDescription]);
    }
    */
    
    NSString *contentString = NSLocalizedString(@"<tell_friend_free>", @"Tell Friend: Free SMS default text");

    // add nickname limit so SMS is not too long
    NSString *fullNick = [[MPSettingCenter sharedMPSettingCenter] getNickName];
    NSString *shortenNick = fullNick;
    
    if ([fullNick length] > 7) {
        shortenNick = [NSString stringWithFormat:@"%@...", [fullNick substringToIndex:7]];
    }
    NSString *filledContent = [NSString stringWithFormat:contentString, shortenNick];

    UILabel *contentLabel = [[UILabel alloc] init];
    [AppUtility configLabel:contentLabel context:kAULabelTypeGrayMicroPlus];
    contentLabel.text = filledContent;
    contentLabel.backgroundColor = [UIColor whiteColor];
    contentLabel.lineBreakMode = UILineBreakModeWordWrap;
    
    // modify frame to just fit amount of text found
    CGSize maximumSize = CGSizeMake(250.0, 9999);
    CGSize stringSize = [filledContent sizeWithFont:contentLabel.font 
                                                 constrainedToSize:maximumSize 
                                                     lineBreakMode:contentLabel.lineBreakMode];
    CGRect instructionFrame = CGRectMake(20.0, 20.0, 250.0, stringSize.height);
    contentLabel.frame = instructionFrame;
    contentLabel.numberOfLines = 0;
    contentLabel.tag = MESSAGE_LABEL_TAG;
    
    
    // text background
    //
    currentY += 12.0;
    UIImage *paperImage = [Utility resizableImage:[UIImage imageNamed:@"sms_text.png"] leftCapWidth:20.0 topCapHeight:20.0];
    UIImageView *paperView = [[UIImageView alloc] initWithFrame:CGRectMake(15.0, currentY, 290.0, stringSize.height+40.0)];
    paperView.image = paperImage;
    [paperView addSubview:contentLabel];
    [contentLabel release];
    
    [self.view addSubview:paperView];
    
    
    // set content size
    //
    [(UIScrollView *)self.view setContentSize:CGSizeMake(appFrame.size.width, paperView.frame.origin.y+paperView.frame.size.height)];

    [paperView release];

    
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processSendSMS:) name:MP_HTTPCENTER_SMS_NOTIFICATION object:nil];    
    
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    DDLogInfo(@"FSC-vwa");

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Button 

/*!
 @abstract Cancel 
 */
- (void) pressCancel:(id)sender {
    
    [self dismissModalViewControllerAnimated:YES];
    
}

/*!
 @abstract Send message
 */
- (void) pressSend:(id)sender {
    
    NSMutableArray *phoneArray = [[NSMutableArray alloc] init];
    for (ContactProperty *iProperty in self.contactProperties){
        [phoneArray addObject:iProperty.value];
    }
    
    UILabel *messageLabel = (UILabel *)[self.view viewWithTag:MESSAGE_LABEL_TAG];
    
    [AppUtility startActivityIndicator];
    [[MPHTTPCenter sharedMPHTTPCenter] sendFreeSMS:phoneArray messageContent:messageLabel.text];
    [phoneArray release];
}


/*!
 @abstract Send message
 
 Output
 Successful case
 
 <SMS>
    <cause>0</cause>
    <quota>10</quota>
 </SMS>
 
 Exception case
 
 <SMS>
    <cause>602</cause>
    <text>Invalid USERID!</text>
 </SMS>
 
 */
- (void) processSendSMS:(NSNotification *)notification {
    
    [AppUtility stopActivityIndicator];
    
    NSDictionary *responseD = [notification object];
    
    NSString *quotaString = [responseD valueForKey:@"quota"];
    
    // if query successful
    //
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        // save quota
        //
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingFreeSMSLeftNumber settingValue:[NSNumber numberWithInt:[quotaString intValue]]];
        
        [self dismissModalViewControllerAnimated:YES];
    }
    // no user found!
    else {       
        NSString *title = NSLocalizedString(@"Send Free SMS", @"FreeSMS - alert title: informs of failure");
        NSString *detMessage = NSLocalizedString(@"Send free sms failed. Try again.", @"FreeSMS - alert text: informs of failure");
        
        [Utility showAlertViewWithTitle:title message:detMessage];
    }
}


@end
