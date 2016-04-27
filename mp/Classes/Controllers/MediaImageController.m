//
//  MediaImageController.m
//  mp
//
//  Created by Min Tsai on 1/4/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "MediaImageController.h"
#import "MPFoundation.h"

NSTimeInterval const kMPParamMediaImageHideBarTime = 5.0;
@interface MediaImageController (Private)
- (void) showBarsAnimated:(BOOL)animated;
@end

@implementation MediaImageController

@synthesize delegate;
@synthesize image;
@synthesize filename;
@synthesize hideBarTimer;

- (void) dealloc {
    
    [image release];
    [filename release];
    [hideBarTimer release];
    [super dealloc];
}

- (id)initWithImage:(UIImage *)newImage title:(NSString *)newTitle filename:(NSString *)newFilename
{    
    // must call initWithFrame!
    self = [super init];
    if (self) {
        
        // Custom initialization
        self.title = newTitle;
        self.image = newImage;
        self.filename = newFilename;
        
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

/*!
 @abstract contruct view programmatically
 */
- (void)loadView {
    
    self.wantsFullScreenLayout = YES;
    
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackTranslucent];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
								   initWithTitle:NSLocalizedString(@"Close", @"Button: done viewing photo")
								   style:UIBarButtonItemStyleDone
								   target:self 
								   action:@selector(pressDone:)];
    /*if ([doneButton respondsToSelector:@selector(tintColor)]) {
        doneButton.tintColor = [AppUtility colorForContext:kAUColorTypeGreen2];
    }*/
	self.navigationItem.rightBarButtonItem = doneButton;
	[doneButton release];
    
    
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    // Add Toolbar buttons
    UIBarButtonItem *forwardButton = [[ UIBarButtonItem alloc ] initWithTitle: NSLocalizedString(@"Forward", @"MediaImage - Button: forward image to others") 
                                                                          style: UIBarButtonItemStyleBordered
                                                                         target: self
                                                                         action: @selector( pressForward: ) ];
    forwardButton.width = 140.0;
    
    UIBarButtonItem *saveButton = [[ UIBarButtonItem alloc ] initWithTitle: NSLocalizedString(@"Save", @"MediaImage - Button: save chat to album") 
                                                                     style: UIBarButtonItemStyleBordered
                                                                    target: self
                                                                    action: @selector( pressSave: ) ];
    saveButton.width = 140.0;
    /*if ([saveButton respondsToSelector:@selector(tintColor)]) {
        saveButton.tintColor = [AppUtility colorForContext:kAUColorTypeGreen2];
    }*/
    
    self.toolbarItems = [ NSArray arrayWithObjects: flexibleSpace, forwardButton, saveButton, flexibleSpace, nil ];
    [flexibleSpace release];
    [forwardButton release];
    [saveButton release];
    
    // show toolbar
    self.navigationController.toolbarHidden = NO;
    self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
    
    UIImageView *backImage = [[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    backImage.image = self.image;
    backImage.backgroundColor = [UIColor blackColor];
    backImage.contentMode = UIViewContentModeScaleAspectFit;
    backImage.userInteractionEnabled = YES;
    self.view = backImage;
    [backImage release];
    
    CGRect buttonFrame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
    UIButton *clearButton = [[UIButton alloc] initWithFrame:buttonFrame];
    clearButton.backgroundColor = [UIColor clearColor];
    [clearButton addTarget:self action:@selector(pressClearButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:clearButton];
    [clearButton release];
    
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

- (void) viewWillAppear:(BOOL)animated {
    DDLogInfo(@"MIC-vwa");
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self showBarsAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self showBarsAnimated:NO];
    [self.hideBarTimer invalidate];

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
- (void) pressDone:(id)sender {
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self dismissModalViewControllerAnimated:YES];
}

/*!
 @abstract Ask delegate to forward this image
 */
- (void) pressForward:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(MediaImageController:forwardImage:)]) {
        [self.delegate MediaImageController:self forwardImage:self.image];
    }
    
}

#define ACTIVITY_TAG 14001

/*!
 @abstract Saves image finished saving to Album
 */
- (void) image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(UIBarButtonItem *)contextInfo {
    
    UIBarButtonItem *saveButton = contextInfo;
    UIActivityIndicatorView *saveIndicator = (UIActivityIndicatorView *)[self.navigationController.toolbar viewWithTag:ACTIVITY_TAG];
    [saveIndicator stopAnimating];
    [saveIndicator removeFromSuperview];
    
    // if error encountered
    if (error) {
        saveButton.enabled = YES;
        [Utility showAlertViewWithTitle:NSLocalizedString(@"Save Image", @"MediaImage - alert title") message:NSLocalizedString(@"Save image failed. Please try again", @"MediaImage - alert msg: Save letter failed")];
    }
    // if success
    // - change title and color
    else {
        [saveButton setTitle:NSLocalizedString(@"Save Complete", @"MediaImage - button: save to photo album is done")];
        if ([saveButton respondsToSelector:@selector(tintColor)]) {
            saveButton.tintColor = nil;
        }
    }
}

/*!
 @abstract Saves image to user's camera roll
 */
- (void) pressSave:(id)sender {
        
    //[saveButton setTitle:NSLocalizedString(@"Save Complete", @"MediaImage - button: save to photo album is done")];
    

    UIBarButtonItem *saveButton = sender;
    CGSize barSize = self.navigationController.toolbar.frame.size;
    
    UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(image:didFinishSavingWithError:contextInfo:), saveButton);
    
    UIActivityIndicatorView *saveIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    // place indicator on save button
    saveIndicator.frame = CGRectMake( (barSize.width-saveIndicator.frame.size.width)/2.0+75.0, 
                                     (barSize.height-saveIndicator.frame.size.height)/2.0,
                                     saveIndicator.frame.size.width, 
                                     saveIndicator.frame.size.height);
    saveIndicator.tag = ACTIVITY_TAG;
    [self.navigationController.toolbar addSubview:saveIndicator];
    [saveIndicator startAnimating];
    [saveIndicator release];
    [saveButton setEnabled:NO];
    
}


/*!
 @abstract hide all controls
 */
- (void) hideBars {
    [self.hideBarTimer invalidate];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController setToolbarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

/*!
 @abstract show all controls
 
 [UINavigationBar beginAnimations:@"NavBarFade" context:nil];
 self.navigationController.navigationBar.alpha = 1;
 [self.navigationController setNavigationBarHidden:YES animated:NO]; //Animated must be NO!
 [UINavigationBar setAnimationCurve:UIViewAnimationCurveEaseIn]; 
 [UINavigationBar setAnimationDuration:1.5];
 self.navigationController.navigationBar.alpha = 0;
 [UINavigationBar commitAnimations];
 
 */
- (void) showBarsAnimated:(BOOL)animated {
    [self.hideBarTimer invalidate];
    self.hideBarTimer = [NSTimer scheduledTimerWithTimeInterval:kMPParamMediaImageHideBarTime target:self selector:@selector(hideBars) userInfo:nil repeats:NO];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setToolbarHidden:NO animated:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];

}
                         
/*!
 @abstract 
 */
- (void) pressClearButton:(id)sender {
    if (self.navigationController.navigationBarHidden == YES) {
        [self showBarsAnimated:YES];
    }
    else {
        [self hideBars];
    }
}

@end
