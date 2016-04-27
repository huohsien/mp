//
//  BroadcastController.m
//  mp
//
//  Created by M Tsai on 11-10-31.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "BroadcastController.h"
#import "CDMessage.h"
#import "CDContact.h"
#import "MPChatManager.h"

@implementation BroadcastController

@synthesize delegate;
@synthesize contacts;



- (void)dealloc {
    [contacts release];
    [super dealloc];
}


/*!
 @abstract init with contacts who we will send broadcast to
 */
- (id)initWithContacts:(NSArray *)selectedContacts
{
    self = [super init];
    if (self) {
        self.contacts = selectedContacts;
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

#define TEXT_VIEW_TAG   14000

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    
    UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view = backView;
    [backView release];
    self.view.backgroundColor = [UIColor colorWithRed:0.804 green:0.91 blue:0.835 alpha:1.0];
    
    
    NSMutableString *toString = [[NSMutableString alloc] init];
    for (CDContact *iContact in self.contacts){
        if ([toString length] > 0) {
            [toString appendFormat:@", %@", [iContact displayName] ];
        }
        else {
            [toString appendFormat:@"%@", [iContact displayName] ];
        }
    }
    
    // create To label
    //
    UILabel *toLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 10.0, 290.0, 20.0)];
    toLabel.font = [UIFont systemFontOfSize:14];
    toLabel.backgroundColor = [UIColor clearColor];
    toLabel.text = toString;
    [self.view addSubview:toLabel];
    [toLabel release];
    [toString release];
    
    
    // create text view for message
    //
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(10.0, 40.0, 300.0, 100.0)];
    [textView becomeFirstResponder];
    textView.tag = TEXT_VIEW_TAG;
    [self.view addSubview:textView];
    [textView release];
    


    
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
                                     initWithTitle:NSLocalizedString(@"Cancel", @"Broadcast - Button: cancel broadcast")
                                     style:UIBarButtonItemStyleBordered
                                     target:self 
                                     action:@selector(pressCancel:)];
    
	self.navigationItem.leftBarButtonItem = cancelButton;
	[cancelButton release]; 
    
	UIBarButtonItem *sendButton = [[UIBarButtonItem alloc]
                                        initWithTitle:NSLocalizedString(@"Send", @"Broadcast - Button: send out broadcast")
                                        style:UIBarButtonItemStyleDone
                                        target:self 
                                        action:@selector(pressSend:)];
    
	self.navigationItem.rightBarButtonItem = sendButton;
	[sendButton release]; 
    
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

#pragma mark - Button Methods

/*!
 @abstract cancel broadcast and return to chat list
 */
- (void) pressCancel:(id)sender {

    // ask delegate to dismiss us and other modal views
    //
	if ([delegate respondsToSelector:@selector(broadcastController:)]) {
		[delegate broadcastController:self];
	}
	// otherwise just dismiss this view
	else {
		[self dismissModalViewControllerAnimated:YES];
	}
}

/*!
 @abstract sends out broadcast messages
 
 Create a CDMessage for each contact.
 
 */
- (void) pressSend:(id)sender {
    
    UITextView *textView = (UITextView *)[self.view viewWithTag:TEXT_VIEW_TAG];
    
    // send out a text message for each contact
    //
    for (CDContact *iContact in self.contacts){
        
        CDMessage *newCDMessage = [CDMessage outCDMessageForContacts:[NSArray arrayWithObject:iContact] messageType:kCDMessageTypeText text:textView.text attachmentData:nil shouldSave:YES];
                
        // sends this message
        //
        [[MPChatManager sharedMPChatManager] sendCDMessage:newCDMessage];
    }
    
    [self pressCancel:sender];
}
@end
