//
//  TextEditController.m
//  mp
//
//  Created by Min Tsai on 2/16/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "TextEditController.h"
#import "MPFoundation.h"

@implementation TextEditController

@synthesize delegate;
@synthesize doneButtonTitle;
@synthesize originalText;

- (void)dealloc {
    
    [doneButtonTitle release];
    [originalText release];
    [super dealloc];
    
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


#define TEXTVIEW_TAG    13001

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{

    // setup buttons
    //
    // Nav buttons
    // - next step is required before sending
    //
    UIBarButtonItem *doneButton = [AppUtility barButtonWithTitle:self.doneButtonTitle 
                                                       buttonType:kAUButtonTypeBarHighlight 
                                                           target:self action:@selector(pressDone:)];
    doneButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UIBarButtonItem *cancelButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Cancel", @"TextEdit - button: cancel text edit") 
                                                        buttonType:kAUButtonTypeBarNormal 
                                                            target:self action:@selector(pressCancel:)];
    self.navigationItem.leftBarButtonItem = cancelButton;

    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    // background
    //
    UIView *setupView = [[UIView alloc] initWithFrame:appFrame];
    setupView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = setupView;
    [setupView release];
    
    
    // textfield background image
    //
    UIImageView *textBackImage = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, 10.0, 310.0, 115.0)];
    textBackImage.image = [Utility resizableImage:[UIImage imageNamed:@"std_icon_textbar.png"] leftCapWidth:9.0 topCapHeight:22.0];
    textBackImage.userInteractionEnabled = YES;
    [self.view addSubview:textBackImage];
    
    
    // create text view for message
    //
    UITextView *newTextView = [[UITextView alloc] initWithFrame:CGRectMake(5.0, 5.0, 300.0, 105.0)];
    newTextView.textColor = [UIColor blackColor];
    newTextView.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
    newTextView.backgroundColor = [UIColor whiteColor];
    newTextView.delegate = self;
    newTextView.text = self.originalText;
    newTextView.tag = TEXTVIEW_TAG;
    [textBackImage addSubview:newTextView];
    [textBackImage release];
    [newTextView release];

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Button


/*!
 @abstract Cancel location sharing
 */
- (void) pressDone:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(TextEditController:didEditText:)]) {
        UITextView *textView = (UITextView *)[self.view viewWithTag:TEXTVIEW_TAG];
        [self. delegate TextEditController:self didEditText:textView.text];
    }
}

/*!
 @abstract Cancel location sharing
 */
- (void) pressCancel:(id)sender {
    
    // if presented modally, we need to present done button
    if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
        [self dismissModalViewControllerAnimated:YES];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}

#pragma mark - TextView


/*!
 @abstract Enable and disabled send button depending if there is text
 */
- (BOOL)textView:(UITextView *)thisTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    NSString *newText = [thisTextView.text stringByReplacingCharactersInRange:range withString:text];
    
    if ([newText length] > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    return YES;
}



@end
