//
//  ResourceButton.h
//  mp
//
//  Created by Min Tsai on 1/9/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ComposerController.h"

/*! when a resource was just downloaded - object ID of resource */
extern NSString* const MP_RESOURCEBUTTON_DID_SET_PREVIEW_IMAGE_NOTIFICATION;


@class CDResource;

@interface ResourceButton : UIButton < ComposerControllerDelegate> {
    
    CDResource *resource;
    
}

@property (nonatomic, retain) CDResource *resource;



- (id) initWithFrame:(CGRect)frame resource:(CDResource *)newResource;
- (BOOL) setPreviewImage;
- (void) setCDResource:(CDResource *)newResource;
- (void) redrawTextView;

@end
