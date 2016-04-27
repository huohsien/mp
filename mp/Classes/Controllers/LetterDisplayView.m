//
//  LetterDisplayView.m
//  mp
//
//  Created by Min Tsai on 2/17/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "LetterDisplayView.h"
#import "MPFoundation.h"

@implementation LetterDisplayView

@synthesize delegate;
@synthesize letterImage;
@synthesize bottomToolBar;
@synthesize topNavBar;

#define LETTER_BACK_VIEW    15701
#define ACTIVITY_TAG        15702

#define kLetterWidth        250.0
#define kLetterHeight       325.0
#define kButtonWidth        140.0


- (void) dealloc {
    
    
    [letterImage release];
    [topNavBar release];
    [bottomToolBar release];
    [super dealloc];
    
}

- (id)initWithFrame:(CGRect)frame letterImage:(UIImage *)newImage 
{
    //CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.letterImage = newImage;
        
        // hide view so it can fade in
        self.alpha = 0.0;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
        self.userInteractionEnabled = YES;
        
        // Add Letter background
        // - hide keypad when tapped
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(moveToolBar:)];
        tapRecognizer.numberOfTapsRequired = 1;
        tapRecognizer.delegate = self;
        [self addGestureRecognizer:tapRecognizer];
        [tapRecognizer release];
        
        
        // add letter view
        // - center of the view
        CGRect letterRect = CGRectMake((self.frame.size.width-kLetterWidth)/2.0, (self.frame.size.height-kLetterHeight)/2.0, kLetterWidth, kLetterHeight);
        UIImageView *letterView = [[UIImageView alloc] initWithFrame:letterRect];
        letterView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |  UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        letterView.image = newImage;
        [self addSubview:letterView];
        [letterView release];
        
        
        // add navbar
        //
        UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0, -44.0, self.frame.size.width, 44.0)];
        navBar.barStyle = UIBarStyleBlackTranslucent;
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                       initWithTitle:NSLocalizedString(@"Close", @"Button: done viewing photo")
                                       style:UIBarButtonItemStyleDone
                                       target:self 
                                       action:@selector(pressClose:)];
        /*if ([doneButton respondsToSelector:@selector(tintColor)]) {
         doneButton.tintColor = [AppUtility colorForContext:kAUColorTypeGreen2];
         }*/
        UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:@""];
        navItem.rightBarButtonItem = doneButton;
        [doneButton release];
        [navBar pushNavigationItem:navItem animated:NO];
        [navItem release];
        
        [self addSubview:navBar];
        self.topNavBar = navBar;
        [navBar release];
        
        
        // add toolbar
        //
        UIToolbar *newToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, self.frame.size.height, self.frame.size.width, 44.0)];
        newToolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        newToolbar.barStyle = UIBarStyleBlackTranslucent;
        
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        
        // Add Toolbar buttons
        UIBarButtonItem *closeButton = [[ UIBarButtonItem alloc ] initWithTitle: NSLocalizedString(@"Close", @"LetterDisplay - Button: close letter view") 
                                                                           style: UIBarButtonItemStyleBordered
                                                                          target: self
                                                                          action: @selector(pressClose:) ];
        closeButton.width = kButtonWidth;
        closeButton.enabled = YES;
        
        UIBarButtonItem *forwardButton = [[ UIBarButtonItem alloc ] initWithTitle: NSLocalizedString(@"Forward", @"LetterDisplay - Button: Forward letter to someone else") 
                                                                         style: UIBarButtonItemStyleBordered
                                                                        target: self
                                                                        action: @selector(pressForward:) ];
        forwardButton.width = kButtonWidth;
        forwardButton.enabled = YES;
        /*if ([forwardButton respondsToSelector:@selector(tintColor)]) {
            forwardButton.tintColor = [AppUtility colorForContext:kAUColorTypeGreen2];
        }*/
        
        
        UIBarButtonItem *saveButton = [[ UIBarButtonItem alloc ] initWithTitle: NSLocalizedString(@"Save", @"LetterDisplay - Button: Save letter to album") 
                                                                            style: UIBarButtonItemStyleBordered
                                                                           target: self
                                                                           action: @selector(pressSave:) ];
        saveButton.width = kButtonWidth;
        saveButton.enabled = YES;
        /*if ([saveButton respondsToSelector:@selector(tintColor)]) {
            saveButton.tintColor = [AppUtility colorForContext:kAUColorTypeGreen2];
        }*/
        
        [newToolbar setItems:[ NSArray arrayWithObjects: flexibleSpace, forwardButton, saveButton, flexibleSpace, nil ] animated:NO];
        [self addSubview:newToolbar];
        [flexibleSpace release];
        [closeButton release];
        [saveButton release];
        [forwardButton release];
        self.bottomToolBar = newToolbar;
        [newToolbar release];
        
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/



#pragma mark - UIView

/*!
 @abstract Show letter animated
 
 Use:
 - call adding letter as an overlay to fade in
 */
- (void) showLetterAnimated:(BOOL)animated {
    DDLogInfo(@"LDV: show animated");
    if (animated) {
        [UIView animateWithDuration:kMPParamAnimationStdDuration 
                         animations:^{
                             self.alpha = 1.0;
                         }];
    }
    else {
        self.alpha = 1.0;
    }
}



/*!
 @abstract Called after view added as subview
 */
- (void)didAddSubview:(UIView *)subview {
    [self showLetterAnimated:YES];
}


#pragma mark - Button


/*!
 @abstract Dismiss this view
 */
- (void) moveToolBar:(id)sender {
    
    CGRect navFrame = self.topNavBar.frame;
    CGRect toolFrame = self.bottomToolBar.frame;
    
    // if visible, hide it
    if (toolFrame.origin.y < self.frame.size.height) {
        toolFrame.origin.y = self.frame.size.height + toolFrame.size.height;
    }
    // if not visible, show it
    else {
        toolFrame.origin.y = self.frame.size.height - toolFrame.size.height;
    }
    
    // if visible, hide it
    if (navFrame.origin.y < 0.0) {
        navFrame.origin.y = 0.0;
    }
    // if not visible, show it
    else {
        navFrame.origin.y = -navFrame.size.height;
    }
    
    
    [UIView animateWithDuration:kMPParamAnimationStdDuration 
                     animations:^{
                         self.topNavBar.frame = navFrame;
                         self.bottomToolBar.frame = toolFrame;
                     } 
     ];
}


/*!
 @abstract Dismiss this view
 */
- (void) pressClose:(id)sender {
    [UIView animateWithDuration:kMPParamAnimationStdDuration 
                     animations:^{
                         self.alpha = 0.0;
                     } 
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self removeFromSuperview];
                         }
                     }
     ];
}


/*!
 @abstract Saves image finished saving to Album
 */
- (void) image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(UIBarButtonItem *)contextInfo {
    
    UIBarButtonItem *saveButton = contextInfo;
    UIActivityIndicatorView *saveIndicator = (UIActivityIndicatorView *)[self.bottomToolBar viewWithTag:ACTIVITY_TAG];
    [saveIndicator stopAnimating];
    [saveIndicator removeFromSuperview];
    
    // if error encountered
    if (error) {
        saveButton.enabled = YES;
        [Utility showAlertViewWithTitle:NSLocalizedString(@"Save Letter", @"LetterDisplay - alert title") message:NSLocalizedString(@"Save letter failed. Please try again", @"LetterDisplay - alert msg: Save letter failed")];
    }
    // if success
    else {
        [saveButton setTitle:NSLocalizedString(@"Save Complete", @"LetterDisplay - button: save to photo album is done")];
        if ([saveButton respondsToSelector:@selector(tintColor)]) {
            saveButton.tintColor = nil;
        }
    }
}

/*!
 @abstract Save letter image to album
 */
- (void) pressSave:(id)sender {

    UIBarButtonItem *saveButton = sender;
    CGSize barSize = self.bottomToolBar.frame.size;
    
    UIImageWriteToSavedPhotosAlbum(self.letterImage, self, @selector(image:didFinishSavingWithError:contextInfo:), saveButton);
    
    UIActivityIndicatorView *saveIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    // place indicator on save button
    saveIndicator.frame = CGRectMake( (barSize.width-saveIndicator.frame.size.width)/2.0+75.0, 
                                     (barSize.height-saveIndicator.frame.size.height)/2.0,
                                     saveIndicator.frame.size.width, 
                                     saveIndicator.frame.size.height);
    saveIndicator.tag = ACTIVITY_TAG;
    [self.bottomToolBar addSubview:saveIndicator];
    [saveIndicator startAnimating];
    [saveIndicator release];
    [saveButton setEnabled:NO];
}


/*!
 @abstract Ask delegate to forward this image
 */
- (void) pressForward:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(LetterDisplayView:forwardImage:)]) {
        [self.delegate LetterDisplayView:self forwardImage:self.letterImage];
    }
    [self pressClose:nil];
}

#pragma mark - UIGestureRecognizer

/*!
 @abstract Determine is touch should be received
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    // don't accept is the touch is under the toolbar
    // - other wise we will dismiss toolbar instead recognize button press
    
    CGPoint pointInView = [touch locationInView:gestureRecognizer.view];
    
    if ( [gestureRecognizer isMemberOfClass:[UITapGestureRecognizer class]] ) {
        if ( CGRectContainsPoint(self.bottomToolBar.frame, pointInView) || 
            CGRectContainsPoint(self.topNavBar.frame, pointInView) ) {
            return NO;
        } 
    }
    return YES;
}




@end
