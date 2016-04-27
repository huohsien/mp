//
//  ResourceButton.m
//  mp
//
//  Created by Min Tsai on 1/9/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "ResourceButton.h"
#import "CDResource.h"
#import "MPResourceCenter.h"
#import "MPFoundation.h"
#import "TextEmoticonView.h"


NSString* const MP_RESOURCEBUTTON_DID_SET_PREVIEW_IMAGE_NOTIFICATION = @"MP_RESOURCEBUTTON_DID_SET_PREVIEW_IMAGE_NOTIFICATION";


CGFloat const kPPBEditSize = 27.0;


@implementation ResourceButton

@synthesize resource;

#define TEXT_LABEL_TAG 15001





- (id) initWithFrame:(CGRect)frame resource:(CDResource *)newResource
{
	if ((self = [super initWithFrame:frame])) {
		[self setCDResource:newResource];
    }
	return self;	
}

/*!
 @abstract Sets the image for the resource button
 - only for emoticon and stickers
 - to check if image was just downloaded for this button
 
 @return YES if image was set successfully
 
 */
- (BOOL) setPreviewImage {
    
    BOOL didSetImage = NO;
    
    RCType thisType = [self.resource.type intValue];
    if (thisType != kRCTypePetPhrase) {
        
        NSString *previewImageFilename = [self.resource getImageFilenameForType:kRSImageTypePreview];

        // get image in background thread for faster ui performance
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            UIImage *resourceImage = nil;
            
            if ([previewImageFilename length] > 0) {
                TKFileManager *newFM = [[TKFileManager alloc] initWithDirectory:kRCFileCenterDirectory];
                resourceImage = [newFM getImageForFilename:previewImageFilename];  
                [newFM release];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (resourceImage) {
                        [self setImage:resourceImage forState:UIControlStateNormal];
                        self.alpha = 1.0;
                        
                        // let other views know that we have set the view
                        [[NSNotificationCenter defaultCenter] postNotificationName:MP_RESOURCEBUTTON_DID_SET_PREVIEW_IMAGE_NOTIFICATION object:self userInfo:nil];
                         
                    }
                    // if image is not available, then download it
                    else {
                        [[MPResourceCenter sharedMPResourceCenter] downloadResource:self.resource force:NO isRetry:NO addPending:YES];
                    }

                });
                
                
            }
        });
        
        /*
        UIImage *previewImage = [self.resource getImageForType:kRSImageTypePreview];
        if (previewImage) {
            [self setImage:previewImage forState:UIControlStateNormal];
            didSetImage = YES;
        }*/
    }
    
    return didSetImage;
}


/*!
 @abstract Sets the resource associated to this button
 */
- (void)setCDResource:(CDResource *)newResource {
    
    self.resource = newResource;
    
    RCType thisType = [self.resource.type intValue];
    
    // create petphrase button
    if (thisType == kRCTypePetPhrase) {
                
        // set background image
        UIImage *buttonImage = [Utility resizableImage:[UIImage imageNamed:@"chat_attach_phrase_btn_nor.png"] leftCapWidth:27.0 topCapHeight:13.0];
        [self setBackgroundImage:buttonImage forState:UIControlStateNormal];
        
        // add text view
        //
        TextEmoticonView *textView = [[TextEmoticonView alloc] initWithFrame:CGRectMake(12.0, 1.5, 253.0, 25.0)];
        textView.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
        textView.lineBreakMode = UILineBreakModeTailTruncation;
        textView.numberOfLines = 1;
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [textView setText:self.resource.text];
        textView.userInteractionEnabled = NO;
        textView.tag = TEXT_LABEL_TAG;
        [self addSubview:textView];
        [textView release];
        
        // add edit button
        //
        CGRect editFrame = CGRectMake(self.frame.size.width - kPPBEditSize -1.0, (self.frame.size.height - kPPBEditSize)/2.0, kPPBEditSize, kPPBEditSize);
        UIButton *editButton = [[UIButton alloc] initWithFrame:editFrame];
        [editButton setImage:[UIImage imageNamed:@"chat_attach_phrase_edit_nor.png"] forState:UIControlStateNormal];
        [editButton setImage:[UIImage imageNamed:@"chat_attach_phrase_edit_prs.png"] forState:UIControlStateNormal];
        [editButton addTarget:self action:@selector(pressEdit:) forControlEvents:UIControlEventTouchUpInside];
        editButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:editButton];
        [editButton release];
    }
    // Sticker and emoticon buttons
    else {
        [self setPreviewImage];
    }
    
    // record last usage
    //
    [self addTarget:self action:@selector(pressButton:) forControlEvents:UIControlEventTouchUpInside];
    
}


-(void) dealloc {
	
	[resource release];
	[super dealloc];
    
}





#pragma mark - Button


/*!
 @abstract Record usage so we can generate recent keypad
 */
- (void) pressButton:(id)sender {
    [self.resource updateLastUsedAndSave];
}

/*!
 @abstract Bring up edit view modally
 */
- (void) pressEdit:(id)sender {
    
    ComposerController *nextController = [[ComposerController alloc] init];
    nextController.characterLimitMin = 1;
    nextController.characterLimitMax = 2500;
    nextController.tempText = self.resource.text;
    nextController.title = NSLocalizedString(@"Pet Phrase", @"Pet Phrase - title: view to edit pet phrases");
    nextController.delegate = self;

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:nextController];
    [AppUtility customizeNavigationController:navController];
    [nextController release];
    
    // get the top controller to show on top of 
    UIViewController *containerVC = [[AppUtility getAppDelegate] containerController];
    if (containerVC.modalViewController) {
        containerVC = containerVC.modalViewController;
    }
    [containerVC presentModalViewController:navController animated:YES];
    [navController release];
}



#pragma mark - UIView 


/*!
 @abstract Redraw the text view
 
 Use:
 - call this when the text view is stretched - e.g. keypad goes into landscape mode
 
 */
- (void) redrawTextView {
    
    if ([self.resource.type intValue] == kRCTypePetPhrase) {
        TextEmoticonView *textView = (TextEmoticonView *)[self viewWithTag:TEXT_LABEL_TAG];
        [textView setNeedsDisplay];
    }
 
 }





#pragma mark - ComposerController

/*!
 @abstract User pressed saved with new text string - so update CD and text view
 */
- (void)ComposerController:(ComposerController *)composerController didSaveWithText:(NSString *)text {
    
    self.resource.text = text;
    [AppUtility cdSaveWithIDString:@"save petphrase edit" quitOnFail:NO];
    
    // update text for text view
    TextEmoticonView *textView = (TextEmoticonView *)[self viewWithTag:TEXT_LABEL_TAG];
    [textView setText:text];
    
    // update text view with new string
    [composerController dismissModalViewControllerAnimated:YES];
}


@end
