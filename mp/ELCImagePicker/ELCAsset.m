//
//  Asset.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAsset.h"
#import "ELCAssetTablePicker.h"
#import "UIImage+Resize.h"

#define IMAGE_TAG   15001


CGFloat const kASPhotoSize = 75.0;
CGFloat const kASOveralaySize = 26.0;

@implementation ELCAsset

@synthesize delegate;
@synthesize asset;
@synthesize parent;

-(id)initWithAsset:(ALAsset*)_asset {
	
	if (self = [super initWithFrame:CGRectMake(0, 0, 0, 0)]) {
		
		self.asset = _asset;
		
		CGRect viewFrames = CGRectMake(0, 0, kASPhotoSize, kASPhotoSize);
        
        // 75x75 for non-retina, 150x150 for retina
		UIImage * bigThumb = [[UIImage alloc] initWithCGImage: [self.asset thumbnail]];
                
        //Don't resize since the bigtumb size is correct already! - this wastes memory
        //
        //UIImage * littleThumb = [bigThumb resizedImage: viewFrames.size interpolationQuality: kCGInterpolationLow];
		
        UIImageView *assetImageView = [[UIImageView alloc] initWithFrame:viewFrames];
		[assetImageView setContentMode:UIViewContentModeScaleToFill];
        [assetImageView setImage:bigThumb];
        
        [bigThumb release];
		[self addSubview:assetImageView];
		[assetImageView release];
		
		overlayView = [[UIImageView alloc] initWithFrame:CGRectMake(kASPhotoSize-kASOveralaySize, kASPhotoSize-kASOveralaySize, kASOveralaySize, kASOveralaySize)];
		[overlayView setImage:[UIImage imageNamed:@"std_icon_checkbox2_prs.png"]];
		[overlayView setHidden:YES];
		[self addSubview:overlayView];

        UITapGestureRecognizer * recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSelection)];
        [self addGestureRecognizer:recognizer];
        [recognizer release];

    }
    
	return self;	
}

-(void)toggleSelection {
    
    BOOL shouldProceedToSelect = YES;
    // can I change select status?  - check if limit exists
    //
    if ([self.delegate respondsToSelector:@selector(ELCAsset:isAllowedToSelect:)]) {
        shouldProceedToSelect = [self.delegate ELCAsset:self isAllowedToSelect:!self.selected];
    }
    
    if (!shouldProceedToSelect) {
        return;
    }
    
    // same as chaning select status!
	overlayView.hidden = !overlayView.hidden;
    
    UIView *imageView = [self viewWithTag:IMAGE_TAG];
    
    if (self.selected) {
        imageView.alpha = 0.5;
    }
    else {
        imageView.alpha = 1.0;
    }
    
    // tell delegate about the change
    //
    if ([self.delegate respondsToSelector:@selector(ELCAsset:toggleSelection:)]) {
        [self.delegate ELCAsset:self toggleSelection:self.selected];
    }
    [self setNeedsDisplay];
    
    
//    if([(ELCAssetTablePicker*)self.parent totalSelectedAssets] >= 10) {
//        
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Maximum Reached" message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
//		[alert show];
//		[alert release];	
//
//        [(ELCAssetTablePicker*)self.parent doneAction:nil];
//    }
}

-(BOOL)selected {
	return !overlayView.hidden;
}

-(void)setSelected:(BOOL)_selected {
    
	[overlayView setHidden:!_selected];
    
    UIView *imageView = [self viewWithTag:IMAGE_TAG];
    
    if (_selected) {
        imageView.alpha = 0.5;
    }
    else {
        imageView.alpha = 1.0;
    }
}

- (void)dealloc 
{    
    UIGestureRecognizer * recognizer = [self.gestureRecognizers objectAtIndex: 0];
    [self removeGestureRecognizer: recognizer];

    [self removeFromSuperview];
    self.asset = nil;
	[overlayView release];
    [super dealloc];
}

@end

