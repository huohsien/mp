//
//  UIImage+TKUtilities.h
//  mp
//
//  Created by M Tsai on 11-10-5.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @header UIImage TKUtilies Category
 
 Provides some convenience methods for UIImage
 
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 
 From: http://www.icab.de/blog/2010/10/01/scaling-images-and-creating-thumbnails-from-uiviews/
 
 */
@interface UIImage (UIImage_TKUtilities)
+ (UIImage*) imageFromView:(UIView*)view;
+ (UIImage*) imageFromView:(UIView*)view scaledToSize:(CGSize)newSize;
+ (UIImage*) imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize maintainScale:(BOOL)maintainScale;

+ (UIImage *) sharpImageWithView:(UIView *)view;
+ (UIImage*) maskImage:(UIImage *)image withMask:(UIImage *)maskImage;

/*!
 @abstract Crops this image with a rect
 */
- (UIImage *)crop:(CGRect)rect;

@end
