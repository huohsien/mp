//
//  NSStream+TTUtilities.h
//  mp
//
//  Created by M Tsai on 11-9-1.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import <Foundation/Foundation.h>


/*!
 @header NSStream TTUtilies Category
 
 NSStream in iOS does not allow you to connect to hosts directly.  CFStream
 provides this feature.  This category takes advantage of toll-free bridging
 so that NSStream can connect to a host using CFStream.
 
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 
 From: https://developer.apple.com/library/ios/#qa/qa1652/_index.html
 
 */
@interface NSStream (TTUtilities)

+ (void)getStreamsToHostNamed:(NSString *)hostName 
                         port:(NSInteger)port 
                  inputStream:(NSInputStream **)inputStreamPtr
                 outputStream:(NSOutputStream **)outputStreamPtr;

@end
