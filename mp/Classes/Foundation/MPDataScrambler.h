//
//  MPDataScrambler.h
//  mp
//
//  Created by Min Tsai on 5/30/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

/* 
 
 
 Example 
 
 //00189@chat?id=2012011300000035395640&from=00000035[Beer01]@192.168.1.119{61.66.229.119}&to=00000171[nickname1]@192.168.1.110{61.66.229.110}&text=0000000000000000000000000000000000000000000000000
 
 NSString *msg = @"@chat?id=2012011300000035395640&from=00000035[Beer01]@192.168.1.119{61.66.229.119}&to=00000171[nickname1]@192.168.1.110{61.66.229.110}&text=0000000000000000000000000000000000000000000000000";
 
 NSData *msgData = [msg dataUsingEncoding:NSUTF8StringEncoding];
 
 NSData *encodeLength = [MPDataScrambler encodeLengthHeader:[msgData length]];
 NSData *encodeMsg = [MPDataScrambler encodeMessage:msgData length:[msgData length] encodeLength:encodeLength];
 
 int decodeLength = [MPDataScrambler decodeLengthHeader:encodeLength];
 NSData *decodeMsg = [MPDataScrambler decodedMessage:encodeMsg length:decodeLength encodeLength:encodeLength];
 NSString *decodeString = [[NSString alloc] initWithData:decodeMsg encoding:NSUTF8StringEncoding];
 
 DDLogInfo(@"TEST: length:%d msg:%@", decodeLength, decodeString);
 
 */


#import <Foundation/Foundation.h>

@interface MPDataScrambler : NSObject {
    
}

// encode
+ (NSData *) encodeLengthHeader:(int)lengthOfMessage;
+ (NSData *) encodeMessage:(NSData *)messageData length:(int)messageLength encodeLength:(NSData *)encodedLengthData;

// decode
+ (int) decodeLengthHeader:(NSData *)encodedLength;
+ (NSData *) decodedMessage:(NSData *)encodedMesssage length:(int)messageLength encodeLength:(NSData *)encodedLengthData;

@end
