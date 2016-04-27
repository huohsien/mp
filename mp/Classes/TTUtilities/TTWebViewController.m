    //
//  TTWebViewController.m
//  ContactBook
//
//  Created by M Tsai on 11-3-14.
//  Copyright 2011 TernTek. All rights reserved.
//

#import "TTWebViewController.h"
#import "Utility.h"


@implementation TTWebViewController


@synthesize webView;
@synthesize urlText;


- (void)dealloc {
    [super dealloc];
	
	[webView release];
	[urlText release];
}


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

#define ACT_VIEW_TAG    13001

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	
	CGRect fullScreenRect=[[UIScreen mainScreen] applicationFrame];

	if (!self.webView) {
		UIWebView *wView = [[UIWebView alloc] initWithFrame:fullScreenRect];
        wView.scalesPageToFit = YES;
        wView.delegate = self;
		self.webView = wView;
		[wView release];
		self.view = self.webView;
		
        // activity indicator
        UIActivityIndicatorView *actView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        actView.tag = ACT_VIEW_TAG;
        [self.view addSubview:actView];
        actView.center = self.view.center;
        [actView release];
        
        NSLog(@"WebView: showing %@", self.urlText);
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.urlText]];
		[self.webView loadRequest:request];
	}
}


/**
 Set url Text
 - done before loading
 
 */
- (void)setURLText:(NSString *)uText {
	
	self.urlText = uText;
							 
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark - Delegate 

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
    UIActivityIndicatorView *actView = (UIActivityIndicatorView *)[self.view viewWithTag:ACT_VIEW_TAG];
    [actView startAnimating];
    
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    UIActivityIndicatorView *actView = (UIActivityIndicatorView *)[self.view viewWithTag:ACT_VIEW_TAG];
    [actView stopAnimating];
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    UIActivityIndicatorView *actView = (UIActivityIndicatorView *)[self.view viewWithTag:ACT_VIEW_TAG];
    [actView stopAnimating];
    
    [Utility showAlertViewWithTitle:nil message:[error localizedDescription]];
}


@end
