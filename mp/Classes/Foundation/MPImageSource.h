//
//  MPImageSource.h
//  mp
//
//  Created by M Tsai on 11-12-10.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//


/*!
 @header MPImageSource
 
 Protocol that for objects that can be fed into MPImageManager to get their images.
 
 For: CDContact and CDMessage
 
 @copyright TernTek
 @updated 2011-10-04
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

@protocol MPImageSource

/*! identify this basic image */
- (NSString *) imageName;

/*! what version should we try to get */
- (NSString *) imageVersion;

/*! where can we download this image for this context - indicates the image is downloadable */
- (NSString *) imageURLForContext:(NSString *)displayContext ignoreVersion:(BOOL)ignoreVersion;

@optional


@end
