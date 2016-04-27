//
//  TKTableView.m
//  mp
//
//  Created by Min Tsai on 3/9/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "TKTableView.h"

@implementation TKTableView

- (void)reloadData {
    [super reloadData];
    if ([self.delegate respondsToSelector:@selector(dataDidReload)]) {
        [self.delegate performSelector:@selector(dataDidReload)];
    }
}

#define kBottomBase 0.0

/*!
 @abstract Fix to prevent 
 
 UIScrollView automatically calling _adjustForAutomaticKeyboardInfo
 when keyboard are shown and hidden.
 - This seems like a apple bug
 - Gets called when user sends out an image, letter or location
 - Also prevents bouncing tableview between emoticon and text keyboard
 
 Another case is when user receives an image, then sends out an image.
 - when you dismiss the keyboard the content inset is set to a negative number by _adjust...method
 
 This override essentially disables _adjustForAutomaticKeyboardInfo.
 
 */
- (void) setContentInset:(UIEdgeInsets)contentInset {
    
    //CGFloat bottom = contentInset.bottom;
    //NSLog(@"TKTV: bottom %f", bottom);
    
    if (contentInset.bottom < kBottomBase) {
        contentInset.bottom = kBottomBase;
    }
    
    
    /*
    // landscape - full
    if (contentInset.bottom == -124.0){
        contentInset.bottom = kBottomBase;
    }
    // portrait - full
    else if (contentInset.bottom == -178.0){
        contentInset.bottom = kBottomBase;
    }
    // landscape - half
    else if (contentInset.bottom == -124.0){
        contentInset.bottom = kBottomBase;
    }
    // portrait - half
    else if (contentInset.bottom == -178.0){
        contentInset.bottom = kBottomBase;
    }
    // portrait - w/ input accessory (zh keyboard)
    else if (contentInset.bottom == -214.0){
        contentInset.bottom = kBottomBase;
    }
    // landscape - w/ input accessory (zh keyboard)
    else if (contentInset.bottom == -160.0){
        contentInset.bottom = kBottomBase;
    }
     */
    
    [super setContentInset:contentInset];
}

/* testing - see if we should pass touches along
   - but does not detect before other recognizers, so not very useful
 
- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    
    if (self.isDecelerating) {
        return YES;
    }
    return NO;
    
}
- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
    
    if (self.isDecelerating) {
        return NO;
    }
    return YES;
}
*/
@end
