//
//  UIImage+TKUtilities.m
//  mp
//
//  Created by M Tsai on 11-10-5.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "UIImage+TKUtilities.h"
#import <QuartzCore/QuartzCore.h>



@implementation UIImage (UIImage_TKUtilities)

/*!
 @abstract Provides image context of given size
 @param maintainScale Should image be scaled for retina display? So the size is points not pixel
 */
+ (void)beginImageContextWithSize:(CGSize)size maintainSale:(BOOL)maintainScale
{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        if (maintainScale && [[UIScreen mainScreen] scale] == 2.0) {
            UIGraphicsBeginImageContextWithOptions(size, YES, 2.0);
        } else {
            UIGraphicsBeginImageContext(size);
        }
    } else {
        UIGraphicsBeginImageContext(size);
    }
}

+ (void)endImageContext
{
    UIGraphicsEndImageContext();
}

+ (UIImage*)imageFromView:(UIView*)view
{
    [self beginImageContextWithSize:[view bounds].size maintainSale:YES];
    BOOL hidden = [view isHidden];
    [view setHidden:NO];
    [[view layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    [self endImageContext];
    [view setHidden:hidden];
    return image;
}

+ (UIImage*)imageFromView:(UIView*)view scaledToSize:(CGSize)newSize
{
    UIImage *image = [self imageFromView:view];
    if ([view bounds].size.width != newSize.width ||
        [view bounds].size.height != newSize.height) {
        image = [self imageWithImage:image scaledToSize:newSize maintainScale:YES];
    }
    return image;
}

/*!
 @abstract Resize image
 @param maintainScale Should image be scaled for retina display? So the size is points not pixel
 */
+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize maintainScale:(BOOL)maintainScale
{
    [self beginImageContextWithSize:newSize maintainSale:maintainScale];
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    [self endImageContext];
    return newImage;
}

/*!
 @abstract Captures sharp images from views even on retina views
 */
+ (UIImage *) sharpImageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

/*!
 @abstract Mask a image with another
 
 @param maskImage must be an image with alpha channel entirely removed!
        - black leaves the image, white removes the image
 */
+ (UIImage*) maskImage:(UIImage *)image withMask:(UIImage *)maskImage {
    
	CGImageRef maskRef = maskImage.CGImage; 
    
	CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
	CGImageRef masked = CGImageCreateWithMask([image CGImage], mask);
    CGImageRelease(mask);
	UIImage *maskedImage = [UIImage imageWithCGImage:masked];
    CGImageRelease(masked);
    return maskedImage;
}


/*!
 @abstract Crops this image with a rect
 */
- (UIImage *)crop:(CGRect)rect {
    if (self.scale > 1.0f) {
        rect = CGRectMake(rect.origin.x * self.scale,
                          rect.origin.y * self.scale,
                          rect.size.width * self.scale,
                          rect.size.height * self.scale);
    }
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}

@end
