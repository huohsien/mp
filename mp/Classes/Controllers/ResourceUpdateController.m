//
//  ResourceUpdateController.m
//  mp
//
//  Created by Min Tsai on 1/9/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "ResourceUpdateController.h"
#import "MPFoundation.h"

@implementation ResourceUpdateController

@synthesize progressView;

- (void)dealloc {
    [[MPResourceCenter sharedMPResourceCenter] setDelegate:nil];
    [progressView release];
    [super dealloc];
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


#define kMessageWidth 200.0
#define kMessageHeight 20.0


- (void) loadView {
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    UIView *backView = [[UIView alloc] initWithFrame:appFrame];
    self.view = backView;
    [backView release];
    self.view.backgroundColor = [UIColor blackColor];
    
    
    
    // wait label
    //
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake((appFrame.size.width-kMessageWidth)/2.0, appFrame.size.height/2.0 - kMessageHeight, kMessageWidth, kMessageHeight)];
    messageLabel.textColor = [UIColor whiteColor];
    messageLabel.backgroundColor = [UIColor blackColor];
    messageLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandard];
    messageLabel.textAlignment = UITextAlignmentCenter;
    messageLabel.text = NSLocalizedString(@"Please wait while resources are udpating...", @"ResourceUpdate - text: ask users to wait while downloading");
    [self.view addSubview:messageLabel];
    [messageLabel release];
    
    
    // progress bar
    //
    UIProgressView *pView = [[UIProgressView alloc] initWithFrame:CGRectMake((appFrame.size.width-kMessageWidth)/2.0, appFrame.size.height/2.0, kMessageWidth, kMessageHeight)];
    pView.progressViewStyle = UIProgressViewStyleDefault;
    pView.hidden = NO;
    [self.view addSubview:pView];
    self.progressView = pView;
    [pView release];
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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


#pragma mark - MPResourceCenter Delegate

- (void)MPResourceCenter:(MPResourceCenter *)resourceCenter progress:(CGFloat)progressRatio {
    
    // only animated for 5.0
    if ([self.progressView respondsToSelector:@selector(setProgress:animated:)]) {
        [self.progressView setProgress:progressRatio animated:YES];
    }
    else {
        [self.progressView setProgress:progressRatio];
    }
    
    // we are done, clear delegate and dismiss view
    //
    if (progressRatio == 1.0) {
        resourceCenter.delegate = nil;
        [self dismissModalViewControllerAnimated:YES];
    }
}

@end
