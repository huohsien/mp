//
//  main.m
//  mp
//
//  Created by M Tsai on 11-8-26.
//  Copyright 2011年 TernTek. All rights reserved.

#import <UIKit/UIKit.h>
#import "Utility.h"

int main(int argc, char *argv[])
{
    
    /* swizzle to customize nav bar */
    [Utility swizzleSelector:@selector(insertSubview:atIndex:)
                          ofClass:[UINavigationBar class]
                     withSelector:@selector(tkInsertSubview:atIndex:)];
    [Utility swizzleSelector:@selector(sendSubviewToBack:)
                          ofClass:[UINavigationBar class]
                     withSelector:@selector(tkSendSubviewToBack:)];
    
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}
