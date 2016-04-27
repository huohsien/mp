//
//  ELCImagePickerController.m
//  ELCImagePickerDemo
//
//  Created by Collin Ruffenach on 9/9/10.
//  Copyright 2010 ELC Technologies. All rights reserved.
//

#import "ELCImagePickerController.h"
#import "ELCAsset.h"
#import "ELCAssetCell.h"
#import "ELCAlbumPickerController.h"
#import "TKLog.h"


@implementation ELCImagePickerController

@synthesize delegate;

-(void)cancelImagePicker {
	if([delegate respondsToSelector:@selector(elcImagePickerControllerDidCancel:)]) {
		[delegate performSelector:@selector(elcImagePickerControllerDidCancel:) withObject:self];
	}
}

-(void)failedLocationDenied {
	if([delegate respondsToSelector:@selector(elcImagePickerControllerFailedLocationDenied:)]) {
		[delegate performSelector:@selector(elcImagePickerControllerFailedLocationDenied:) withObject:self];
	}
}

-(void)updateInterface:(NSArray*)returnArray{
    
    [self popToRootViewControllerAnimated:NO];
    
    [[self parentViewController] dismissModalViewControllerAnimated:YES];
    
	if([delegate respondsToSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:)]) {
		[delegate performSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:) withObject:self withObject:[NSArray arrayWithArray:returnArray]];
	}
}

-(void)calculateDictionary:(NSArray*)_assets{
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];

	NSMutableArray *returnArray = [[NSMutableArray alloc] init];
	
	for(ALAsset *asset in _assets) {
		NSMutableDictionary *workingDictionary = [[NSMutableDictionary alloc] init];
        
        id mediaType = [asset valueForProperty:ALAssetPropertyType];
        if (mediaType) {
            [workingDictionary setObject:mediaType forKey:@"UIImagePickerControllerMediaType"];
        }
        else {
            DDLogWarn(@"ELC: missing ref mediaType - skipping it");
            [workingDictionary release];
            continue;
        }
        
        
        /* corrects orientation for iOS4.0
        ALAssetRepresentation *assetRep = [asset defaultRepresentation];
        CGImageRef imgRef = [assetRep fullScreenImage];
        UIImage *img = [UIImage imageWithCGImage:imgRef 
                                           scale:assetRep.scale
                                     orientation:(UIImageOrientation)assetRep.orientation];
        [workingDictionary setObject:img forKey:@"UIImagePickerControllerOriginalImage"];
        */
        
        [workingDictionary setObject:[UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]] forKey:@"UIImagePickerControllerOriginalImage"];
		
        // ensure refURL exists
        id refURL = [[asset valueForProperty:ALAssetPropertyURLs] valueForKey:[[[asset valueForProperty:ALAssetPropertyURLs] allKeys] objectAtIndex:0]];
        if (refURL) {
            [workingDictionary setObject:refURL forKey:@"UIImagePickerControllerReferenceURL"];
        }
        else {
            DDLogWarn(@"ELC: missing ref URL - skipping it");
        }
		
		[returnArray addObject:workingDictionary];
		
		[workingDictionary release];	
    }
    [self performSelectorOnMainThread:@selector(updateInterface:) withObject:returnArray waitUntilDone:YES];
    [returnArray release];
    [pool release];
}

-(void)selectedAssets:(NSArray*)_assets {
    [NSThread detachNewThreadSelector:@selector(calculateDictionary:) toTarget:self withObject:_assets];    
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {    
    DDLogVerbose(@"ELC Image Picker received memory warning.");
    
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}


- (void)dealloc {
    [super dealloc];
}

@end
