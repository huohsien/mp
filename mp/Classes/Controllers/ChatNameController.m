//
//  ChatNameController.m
//  mp
//
//  Created by M Tsai on 11-12-27.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "ChatNameController.h"
#import "MPFoundation.h"
#import "CDChat.h"

NSString* const MP_CHATNAME_UPDATE_NAME_NOTIFICATION = @"MP_CHATNAME_UPDATE_NAME_NOTIFICATION";


@implementation ChatNameController

@synthesize cdChat;
@synthesize nameField;


- (id)initWithCDChat:(CDChat *)newChat
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.cdChat = newChat;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}


- (void) dealloc {
    
    nameField.delegate = nil;
    
    [cdChat release];
    [nameField release];
    
    [super dealloc];
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    
    UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view = backView;
    [backView release];
    self.view.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    
    
    // name description label
    //
    /*UILabel *nameDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 10.0, 295.0, 30.0)];
    [AppUtility configLabel:nameDescriptionLabel context:kAULabelTypeGrayMicroPlus];
    nameDescriptionLabel.lineBreakMode = UILineBreakModeWordWrap;
    nameDescriptionLabel.numberOfLines = 2;
    nameDescriptionLabel.text = NSLocalizedString(@"<name description text>", @"Name Registration - Label: explain what this name is for");
    [self.view addSubview:nameDescriptionLabel];
    [nameDescriptionLabel release];*/
    
    
    // name textfield
    //
    UITextField *nField = [[UITextField alloc] initWithFrame:CGRectMake(5.0, 10.0, 310.0, 45.0)];
    [AppUtility configTextField:nField context:kAUTextFieldTypeName];
    nField.placeholder = NSLocalizedString(@"<chat: enter name>", @"ChatName - Placeholder: enter chat room name here");
    nField.text = self.cdChat.name;
    nField.delegate = self;
    nField.keyboardType = UIKeyboardTypeDefault;
    
    [self.view addSubview:nField];
    self.nameField = nField;
    [nField release];
    
}




// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Chat Room Name", @"ChatName - Title: title for this view");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
        
    // add next navigation button
    //    
    NSString *buttonTitle = NSLocalizedString(@"Save", @"UpdateName - button: saves nickname to server");
    
    UIBarButtonItem *saveButton = [AppUtility barButtonWithTitle:buttonTitle
                                                      buttonType:kAUButtonTypeBarHighlight 
                                                          target:self action:@selector(pressSave:)];
    saveButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = saveButton;
    
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated {
    DDLogInfo(@"CNC-vwa");
    [super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Button

/*!
 @abstract sets nickname and login to system
 */
- (void) pressSave:(id)sender {
    
    self.cdChat.name = self.nameField.text;
    [AppUtility cdSaveWithIDString:@"save chat name" quitOnFail:NO];
    
    // post notification so chat dialog can update's its name
    // - this is helpful to update the chat setting back button so it has the right name
    [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATNAME_UPDATE_NAME_NOTIFICATION object:self.cdChat];
    
    
    [self.navigationController popViewControllerAnimated:YES];
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

    // only if min char and format is valid, enable done button
    if (previewCharCount > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else {
        // always enable for now - allow for blanks so you can go back to auto naming !
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    
    return shouldChange;
}





@end
