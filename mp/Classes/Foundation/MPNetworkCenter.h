//
//  MPNetworkCenter.h
//  mp
//
//  Created by M Tsai on 11-9-1.
//  Copyright 2011年 TernTek. All rights reserved.
//

/*!
 @header MPNetworkCenter
 
 Deprecated.  MPSocketCenter is used instead.
 Original code that access network via NSStream objects.
 
 @copyright TernTek
 @updated 2011-08-30
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <Foundation/Foundation.h>

@class MPMessage;
@class Reachability;

@interface MPNetworkCenter : NSObject <NSStreamDelegate> {
    
    
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    
    NSMutableArray *writeDataQueue;
    NSData *currentWriteData;
    NSUInteger byteIndex;
    BOOL hasWriteSpace;
    
    NSMutableData *readData;
    NSUInteger bytesRead;
    NSUInteger readMessageLength;

    Reachability *domainClusterReachable;
    BOOL isDomainClusterActive;
    CGFloat retrySeconds;
    NSTimer *retryLoginTimer;
    

}



/*! input stream to read from */
@property(nonatomic, retain) NSInputStream *inputStream;
/*! output stream to write to */
@property(nonatomic, retain) NSOutputStream *outputStream;

/*! 
 @abstract FIFO queue that accepts new data by appending to the end 
 
 */
@property(nonatomic, retain) NSMutableArray *writeDataQueue;

/*! 
 @abstract current data that is used to write out with. 
 
 @discussion Refers the the head of the writeDataQueue.  When we finishing writing
 the data to the outputStream, then we pop this item from the queue.
 
 */
@property(nonatomic, retain) NSData *currentWriteData;

/*! 
 @abstract position of currentWriteData that we left off at. 
 
 @discussion when writeStream is ready at accept new data, start reading the 
 currentWriteData from this byteIndex position.
 
 */
@property(nonatomic, assign) NSUInteger byteIndex;

/*!
 @abstract flags if we should write to stream directly
 
 @discussion set flag, when space is available, but we didn't have data to write.
 So next time we have data, just write to the buffer directly.
 
 */
@property (nonatomic, assign) BOOL hasWriteSpace;



/*! 
 @abstract buffer to store data read from input stream
 
 @discussion Only write a single message into readData. After message is completely
 recieved, then send message to be processed.
 
 */
@property(nonatomic, retain) NSMutableData *readData;

/*! 
 @abstract keeps count of the number of bytes read for this message 
 
 @discussion compare with readMessageLength to know when the message is done
 
 */
@property(nonatomic, assign) NSUInteger bytesRead;

/*! 
 @abstract total length of message
 
 @discussion 
 
 */
@property(nonatomic, assign) NSUInteger readMessageLength;



/*! @abstract helps track if network is reachable */
@property (nonatomic, retain) Reachability* domainClusterReachable;

/*! @abstract indicates if internet is currently available */
@property (nonatomic, assign) BOOL isDomainClusterActive;

/*! 
 @abstract retry seconds - when should we try reconnecting again
 @discussion this increases by 2x after each retry.
  - should reset whenever a successful connection occurs or when app becomes active
 */
@property (nonatomic, assign) CGFloat retrySeconds;

/*! @abstract timer to try login again */
@property (nonatomic, retain) NSTimer *retryLoginTimer;

// query
- (BOOL)isConnected;



/*!
 @abstract creates singleton object
 */
+ (MPNetworkCenter *)sharedMPNetworkCenter;

- (void) disconnect;
- (void) resetRetrySeconds;
- (void) setDomainClusterName:(NSString *)hostname;

/*!
 @abstract Setup connection to domain servers
 
 - check if connections are available
 ~ if not connect
 - check if logged in
 ~ if not login
 
 */
- (void) setupDomainConnectionAndLogin;

/*!
 @abstract Logout and disconnect
 */
- (void) logoutAndDisconnect;


/*!
 @abstract add data to write queue to send over the domain server connection
 
 */
- (void) addDataToWriteQueue:(NSData *)newData;

/*!
 @abstract writes data from queue to the network stream
 */
- (void)writeToStream:(NSStream *)stream;

/*!
 @abstract handles message related to this object
 */
- (void) handleMessage:(MPMessage *)newMessage;


// for testing
- (NSString *)connectionStatus;
- (void)readBytes;

@end
