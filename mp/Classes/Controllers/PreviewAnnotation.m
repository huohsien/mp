//
//  PreviewAnnotation.m
//  mp
//
//  Created by Min Tsai on 2/14/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "PreviewAnnotation.h"

@implementation PreviewAnnotation

@synthesize coordinate;
@synthesize name;
@synthesize address;

- (void)dealloc
{    
    [name release];
    [address release];
    [super dealloc];
}

/*!
 @abstract call out title
 */
- (NSString *)title
{
    return self.name;
}

/*!
 @abstract Detailed text for this annotation
 
 */
- (NSString *)subtitle
{
    return address;
}

@end


