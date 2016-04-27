//
//  MediaLetterController.m
//  mp
//
//  Created by Min Tsai on 2/8/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "MediaLetterController.h"
#import "MPFoundation.h"

@implementation MediaLetterController

@synthesize letterImage;
@synthesize backgroundImage;

- (void) dealloc {
    
    [letterImage release];
    [backgroundImage release];
    
    [super dealloc];
    
}

- (id)initWithLetterImage:(UIImage *)newImage
{    
    // must call initWithFrame!
    self = [super init];
    if (self) {
        
        // Custom initialization
        self.letterImage = newImage;        
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

#define LETTER_BACK_VIEW    15701
#define kLetterWidth    250.0
#define kLetterHeight   300.0

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    // add close navigation button
    //
    UIBarButtonItem *cancelButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Close",  @"MediaLetter - Button: close letter view") 
                                                        buttonType:kAUButtonTypeBarNormal 
                                                            target:self action:@selector(pressClose:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    // add save navigation button
    //
    UIBarButtonItem *saveButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Save",  @"MediaLetter - Button: save letter image to album") 
                                                        buttonType:kAUButtonTypeBarNormal 
                                                            target:self action:@selector(pressSave:)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    CGRect viewFrame = CGRectMake(0.0, 0.0, appFrame.size.width, appFrame.size.height);
    
    if (self.backgroundImage) {
        UIImageView *backImageView = [[UIImageView alloc] initWithFrame:viewFrame];
        backImageView.image = self.backgroundImage; // [UIImage imageNamed:@"letter_bg_a_s.jpg"]; //  
        backImageView.backgroundColor = [UIColor greenColor];
        self.view = backImageView;
        [backImageView release];
    }
    else {
        UIView *backView = [[UIView alloc] initWithFrame:viewFrame];
        backView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
        self.view = backView;
        [backView release];
    }
    
    UIView *maskView = [[UIView alloc] initWithFrame:viewFrame];
    maskView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    [self.view addSubview:maskView];
    [maskView release];
    
    UIImageView *letterView = [[UIImageView alloc] initWithFrame:CGRectMake((viewFrame.size.width-kLetterWidth)/2.0, 40.0, kLetterWidth, kLetterHeight)];
    letterView.image = letterImage;
    [self.view addSubview:letterView];
    [letterView release];
    
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

- (void) viewWillAppear:(BOOL)animated {
    DDLogInfo(@"MLC-vwa");
    [super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



#pragma mark - Button

/*!
 @abstract 
 */
- (void) pressClose:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

/*!
 @abstract Saves image to user's camera roll
 */
- (void) pressSave:(id)sender {
    
    UIImageWriteToSavedPhotosAlbum(self.letterImage, nil, nil, nil);
    
    UIBarButtonItem *saveButton = sender;
    [saveButton setTitle:NSLocalizedString(@"Save Complete", @"MediaLetter - button: save to photo album is done")];
    [saveButton setEnabled:NO];
}



@end
