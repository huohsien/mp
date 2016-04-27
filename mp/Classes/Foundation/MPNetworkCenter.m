//
//  MPNetworkCenter.m
//  mp
//
//  Created by M Tsai on 11-9-1.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "MPNetworkCenter.h"
#import "NSStream+TTUtilities.h"

#import "MPFoundation.h"

#import "SynthesizeSingleton.h"
#import "CDContact.h"
#import "Reachability.h"



CGFloat const kMPParamRetrySecondStart = 1.0;

// private methods
//
@interface MPNetworkCenter () 

- (void)disconnect;

@end


@implementation MPNetworkCenter

@synthesize inputStream;
@synthesize outputStream;

@synthesize writeDataQueue;
@synthesize currentWriteData;
@synthesize byteIndex;
@synthesize hasWriteSpace;

@synthesize readData;
@synthesize bytesRead;
@synthesize readMessageLength;
@synthesize domainClusterReachable;
@synthesize isDomainClusterActive;
@synthesize retrySeconds;
@synthesize retryLoginTimer;


SYNTHESIZE_SINGLETON_FOR_CLASS(MPNetworkCenter);



- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    
    /*inputStream.delegate = nil;
    outputStream.delegate = nil;
    
    [inputStream release];
    [outputStream release];*/
    
    [domainClusterReachable release];
    [self disconnect];
    [super dealloc];
}


/*!
 @abstract print out status
 */
- (NSString *) description {
    NSStreamStatus instatus = [self.inputStream streamStatus];
    NSStreamStatus outstatus = [self.outputStream streamStatus];
    
    NSString *status = [NSString stringWithFormat:@"InputStreamStatus: %d OutputStreamStatus: %d", instatus, outstatus];
    return status;
}

#pragma mark - Network Reachability

/*! 
 @abstract getter for domainClusterReachable
 @discussion creates instanace if not available
 
 */
- (Reachability *) domainClusterReachable {
    if (!domainClusterReachable) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];

        NSString *hostPort = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingDomainClusterName];
        NSArray *parts = [hostPort componentsSeparatedByString:@":"];
        
        domainClusterReachable = [[Reachability reachabilityWithHostName:[parts objectAtIndex:0]] retain];
        [domainClusterReachable startNotifier];
    }
    return domainClusterReachable;
}

/*! 
 @abstract Sets new DS cluster and also reset the reachability
 
 Use:
 - if new DS is obtained, always use this! otherwise reachability is not updated
 
 */
- (void) setDomainClusterName:(NSString *)hostname {
    
    // configure new DC
    //
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingDomainClusterName settingValue:hostname];

    // reset new reachable
    //
    [domainClusterReachable release];
    NSArray *parts = [hostname componentsSeparatedByString:@":"];
    domainClusterReachable = [[Reachability reachabilityWithHostName:[parts objectAtIndex:0]] retain];
    [domainClusterReachable startNotifier];
}

/*!
 @abstract handles network status changes
 */
- (void) checkNetworkStatus:(NSNotification *)notice
{
    // called after network status changes
    /*
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    switch (internetStatus)
    
    {
        case NotReachable:
        {
            DDLogVerbose(@"The internet is down.");
            self.isDomainClusterActive = NO;
            
            break;
            
        }
        case ReachableViaWiFi:
        {
            DDLogVerbose(@"The internet is working via WIFI.");
            self.isDomainClusterActive = YES;
            
            break;
            
        }
        case ReachableViaWWAN:
        {
            DDLogVerbose(@"The internet is working via WWAN.");
            self.isDomainClusterActive = YES;
            
            break;
            
        }
    }
    
    // if network is active again, try login
    //
    if (self.isDomainClusterActive){
        [self setupDomainConnectionAndLogin];
    }
    // if lose connection, close connections and inform users?
    //
    else {
        [Utility showAlertViewWithTitle:@"Reachability" message:@"Lost network..."];
        [self diconnect];
    }
    */
    
    
    
    NetworkStatus hostStatus = [domainClusterReachable currentReachabilityStatus];
    switch (hostStatus)
    
    {
        case NotReachable:
        {
            DDLogVerbose(@"A gateway to the host server is down.");
            self.isDomainClusterActive = NO;
            
            break;
            
        }
        case ReachableViaWiFi:
        {
            DDLogVerbose(@"A gateway to the host server is working via WIFI.");
            self.isDomainClusterActive = YES;
            
            break;
            
        }
        case ReachableViaWWAN:
        {
            DDLogVerbose(@"A gateway to the host server is working via WWAN.");
            self.isDomainClusterActive = YES;
            
            break;
            
        }
    }
    // if network is active again, try login
    //
    if (self.isDomainClusterActive){
        [self setupDomainConnectionAndLogin];
    }
    // if lose connection, close connections and inform users?
    //
    else {
        [Utility showAlertViewWithTitle:@"Reachability" message:@"Lost connection to DS."];
        [self disconnect];
    }
}


#pragma mark - Connection Methods


/*! 
 @abstract resets timer to 0.25 seconds 
 
 Use:
 - reset if login is successful
 - reset if app becomes active
 
 */
- (void) resetRetrySeconds {
    self.retrySeconds = kMPParamRetrySecondStart;
}


/*!
 connect to remote server and create streams
 
 */
- (void)getStreamsForHost:(NSString *)hostname port:(NSInteger)port {
    
    NSInputStream *inStream = nil;
    NSOutputStream *outStream = nil;
    
    [NSStream getStreamsToHostNamed:hostname port:port inputStream:&inStream outputStream:&outStream];
    
    self.inputStream = inStream;
    self.outputStream = outStream;
    
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    // connect to the host
    //
    [self.inputStream open];
    [self.outputStream open];
}


/*!
 @abstract disconnects from domain server by closing input and output streams
 */
- (void)disconnect {
    
    [self.inputStream close];
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                      forMode:NSDefaultRunLoopMode];
    self.inputStream = nil;
    
    [self.outputStream close];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                forMode:NSDefaultRunLoopMode];
    self.outputStream = nil;
    
    DDLogVerbose(@"NC-cs: streams CLOSED");
}

/*!
 @abstract Check that both the input and output streams are available.
 
 @discussion Makes sure that both connections are not closed or error status.
 
 Possible status includes
 
 typedef enum {
 NSStreamStatusNotOpen = 0,
 NSStreamStatusOpening = 1,
 NSStreamStatusOpen = 2,
 NSStreamStatusReading = 3,
 NSStreamStatusWriting = 4,
 NSStreamStatusAtEnd = 5,
 NSStreamStatusClosed = 6,
 NSStreamStatusError = 7
 };
 
 @return YES if connected, NO if error or closed
 */
- (BOOL)isConnected {
    
    NSStreamStatus inStatus = [self.inputStream streamStatus];
    NSStreamStatus outStatus = [self.outputStream streamStatus];
    
    // if streams don't exists
    // - not connected
    if (!(self.inputStream && self.outputStream)) {
        return NO;
    }
    
    // if error or closed
    // - not connected 
    if (inStatus == NSStreamStatusError || inStatus == NSStreamStatusClosed || 
        outStatus == NSStreamStatusError || outStatus == NSStreamStatusClosed ) {
        return NO;
    }
    
    // otherwise, connected and other status
    // - is connected
    //
    return YES;
}

/*
 NSStreamStatusNotOpen = 0,
 NSStreamStatusOpening = 1,
 NSStreamStatusOpen = 2,
 NSStreamStatusReading = 3,
 NSStreamStatusWriting = 4,
 NSStreamStatusAtEnd = 5,
 NSStreamStatusClosed = 6,
 NSStreamStatusError = 7
 */
- (NSString *)statusString:(NSStreamStatus)status {
    switch (status) {
        case NSStreamStatusNotOpen:
            return @"NOpen";
            break;
            
        case NSStreamStatusOpening:
            return @"Opening";
            break;
            
        case NSStreamStatusOpen:
            return @"Open";
            break;
            
        case NSStreamStatusReading:
            return @"Read";
            break;
            
        case NSStreamStatusWriting:
            return @"Write";
            break;
            
        case NSStreamStatusAtEnd:
            return @"AtEnd";
            break;
            
        case NSStreamStatusClosed:
            return @"Closed";
            break;
            
        case NSStreamStatusError:
            return @"Error";
            break;
            
        default:
            return @"na";
            break;
    }
}

/*!
 @abstract are connections strictly in open state
 */
- (NSString *)connectionStatus {
    
    NSStreamStatus inStatus = [self.inputStream streamStatus];
    NSStreamStatus outStatus = [self.outputStream streamStatus];
    BOOL hasBytes = [self.inputStream hasBytesAvailable];
    
    NSString *statusString = [NSString stringWithFormat:@"NSTAT-IN:%@ OUT:%@ HB:%@", [self statusString:inStatus], [self statusString:outStatus], hasBytes?@"yes":@"no"];
    
    return statusString;
}


/*!
 @abstract are connections strictly in open state
 */
- (BOOL)areConnectionOpened {
    
    NSStreamStatus inStatus = [self.inputStream streamStatus];
    NSStreamStatus outStatus = [self.outputStream streamStatus];

    DDLogVerbose(@"NC: %@", [self connectionStatus]);
    
    if (inStatus == NSStreamStatusOpen && outStatus == NSStreamStatusOpen) {
        return YES;
    }
    return NO;
}



/*!
 @abstract Setup connection to domain servers
 
 - check if connections are available
  ~ if not, connect
 - check if logged in
  ~ if not, login
 
 */
- (void) setupDomainConnectionAndLogin {
    
    // make sure reachability is started
    [self domainClusterReachable];
    
    
    // make sure retry is valid
    if (self.retrySeconds < kMPParamRetrySecondStart) {
        [self resetRetrySeconds];
    }
    
    
    // initialized
    //
    self.hasWriteSpace = NO;
    
    NSString *hostPort = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingDomainClusterName];
    NSArray *parts = [hostPort componentsSeparatedByString:@":"];
    
    // if not connnected, connect
    //
    if (![self areConnectionOpened]) {
        [self disconnect];
        [self getStreamsForHost:[parts objectAtIndex:0] port:[[parts objectAtIndex:1] integerValue] ];
    }
    
    // if not logged in, login
    // - create login message and send it
    //
    MPMessage *loginMessage = [MPMessage messageLoginIsSuspend:NO];
    [self addDataToWriteQueue:[loginMessage rawNetworkData]];
}


/*!
 @abstract Logout and disconnect
 */
- (void) logoutAndDisconnect {
        
    // reset retry timer, so we can retry quickly next time
    //
    [self resetRetrySeconds];
    
    // only send logout if connected
    //
    if ([self isConnected]) {
        // create and send logout message
        //
        MPMessage *logoutMessage = [MPMessage messageLogoutIsSuspend:YES];
        [self addDataToWriteQueue:[logoutMessage rawNetworkData]];
    }
    
}





/*!
 @abstract handle login failure - helps us keep trying but back off so we dont do this too frequently
 
 @discussion checks if we should try to login again after a failure occurs
 
 Use:
 - call after TCP connection failure - TCP error occurred
 - call after being rejected by server - REJECT message :P
 
 Psuedo Code:
 
 - Is network reachable? 
    * Y - try reconnect - start a timer to login again
    * N - do nothing - wait until network is available then retry!
 
 
 */
- (void) handleLoginFailure:(MPCauseType)cause {
    
    // close streams until next retry
    //
    [self disconnect];
    
    // only retry if net is available
    //
    if ([self.domainClusterReachable currentReachabilityStatus] != NotReachable) {
        
        // double value
        self.retrySeconds = self.retrySeconds *2.0;
        
        // invalidate old timer and create a new one
        [self.retryLoginTimer invalidate];
        
        // authen and then retry
        if (cause == kMPCauseTypeInvalidAKey) {
            self.retryLoginTimer = [NSTimer scheduledTimerWithTimeInterval:self.retrySeconds target:[MPHTTPCenter sharedMPHTTPCenter] selector:@selector(authenticateAndLogin) userInfo:nil repeats:NO];
        }
        else {
            self.retryLoginTimer = [NSTimer scheduledTimerWithTimeInterval:self.retrySeconds target:self selector:@selector(setupDomainConnectionAndLogin) userInfo:nil repeats:NO];
        }        
        
        DDLogVerbose(@"NC-hcf: try connecting in %f secs", self.retrySeconds);
        //NSString *debug = [NSString stringWithFormat:@"Retry in %f secs", self.retrySeconds];

    }
    // net not available - reset time secs
    else{
        [self resetRetrySeconds];
    }
}


#pragma mark -
#pragma mark Read Stream Methods

/*!
 @abstract send read data for processing by message center
 
 */
- (void) processReadData {
    
    NSData *messageData = [self.readData copy];
    
    // send to message center
    //
    [[MPMessageCenter sharedMPMessageCenter] processInComingMessageData:messageData];
    [messageData release];
    
    // reset read data
    // - so the next message can be read in
    //
    self.readData = nil;
    self.bytesRead = 0;
    self.readMessageLength = 0;
}

/*!
 @abstract checks if ping message and reply with ack, also reset read counters
 
 */
- (void) processNetworkMessage:(NSString *)networkMessage {
    
    if ([networkMessage isEqualToString:kMPMessageNetworkPing]) {
        DDLogVerbose(@"NC-pnm: got ping, sending ack");
        NSData *ackData = [kMPMessageNetworkAck dataUsingEncoding:NSUTF8StringEncoding];
        [self addDataToWriteQueue:ackData];
    }
    
    // reset read data
    // - so the next message can be read in
    //
    self.readData = nil;
    self.bytesRead = 0;
    self.readMessageLength = 0;
}

#pragma mark -
#pragma mark Write Stream Methods

/*!
 @abstract add data to write queue to send over the domain server connection
 
 TODO: should we protect write queue so only add or pop can only occur serially
 
 */
- (void) addDataToWriteQueue:(NSData *)newData {
    
    if (!self.writeDataQueue) {
        NSMutableArray *newArray = [[NSMutableArray alloc] init];
        self.writeDataQueue = newArray;
        [newArray release];
    }
    
    [self.writeDataQueue addObject:newData];
    
    if ([self.writeDataQueue count] == 1) {
        self.currentWriteData = [self.writeDataQueue objectAtIndex:0];
    }
    
    // check if space is already available
    // - if so write to the output stream directly
    //
    if (self.hasWriteSpace) {
        self.hasWriteSpace = NO;
        [self writeToStream:self.outputStream];
    }
}

/*!
 @abstract pop the current write data from the writeDataQueue
 
 */
- (void) popCurrentWriteData {
    
    [self.writeDataQueue removeObject:self.currentWriteData];
    
    // reset the currentWriteData to the next item
    //
    if ([self.writeDataQueue count] > 0) {
        self.currentWriteData = [self.writeDataQueue objectAtIndex:0];
        self.byteIndex = 0;
    }
    // if nothing to write
    else {
        self.currentWriteData = nil;
        self.byteIndex = 0;
    }
}


unsigned int const kMPNetworkHeaderBytes = 5;

#pragma mark - 
#pragma mark Stream Delegates


/*!
 @abstract writes data from queue to the network stream
 */
- (void)writeToStream:(NSStream *)stream {
    
    // if there is data that needs to be sent
    //
    if (self.currentWriteData) {
        // get mutable data to read from
        //
        uint8_t *readBytes = (uint8_t *)[self.currentWriteData bytes];
        
        // resume from where we left off!
        //
        readBytes += self.byteIndex; // instance variable to move pointer
        
        // total length of data
        int data_len = [self.currentWriteData length];
        
        // determine amount of data to write
        //
        unsigned int len = ((data_len - self.byteIndex >= 1024) ?
                            1024 : (data_len-self.byteIndex));
        
        // create buffer for data to write
        //
        uint8_t buf[len];
        (void)memcpy(buf, readBytes, len);
        
        // determine the actual amount written
        // - update byte index position
        //
        len = [(NSOutputStream *)stream write:(const uint8_t *)buf maxLength:len];
        self.byteIndex += len;
        
        DDLogVerbose(@"NC-se: wrote %d bytes - byteIndex: %d - data_len: %d", len, self.byteIndex, data_len);
        
        // if we reached the end of that data
        // - remove current data from the queue
        //
        if (self.byteIndex == data_len) {
            [self popCurrentWriteData];
        }
    }
    else {
        DDLogVerbose(@"NC-se: try to write, but nothing available");
    }
}

/*!
 @abstract handle events from input and output stream objects
 
 
 
 */
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    // for debugging
    [self areConnectionOpened];
    
    //NSStreamStatus inStatus = [self.inputStream streamStatus];
    //NSStreamStatus outStatus = [self.outputStream streamStatus];
    //NSString *debugMessage = [NSString stringWithFormat:@"in:%d out:%d e:%d", inStatus, outStatus, eventCode];
    
    switch(eventCode) {
            
        // bytes are available to read
        //
        case NSStreamEventHasBytesAvailable:
        {

            if(!self.readData) {
                DDLogVerbose(@"NC-se: HASBytes - reset data for new message ");
                NSMutableData *newData = [[NSMutableData alloc] init];
                self.readData = newData;
                [newData release];
                
                self.bytesRead = 0;
                self.readMessageLength = 0;
            }
            
            DDLogVerbose(@"NC-se: HasBytes - read:%d msgLen:%d", self.bytesRead, self.readMessageLength);
            
            // if nothing read yet
            // - try to get the message length first
            //
            NSUInteger bytesToRead = 0;
            if (self.bytesRead < kMPNetworkHeaderBytes){
                bytesToRead = kMPNetworkHeaderBytes - self.bytesRead;
            }
            // else message length is known
            else {
                bytesToRead = readMessageLength + kMPNetworkHeaderBytes - self.bytesRead;
            }
            
            // read in bytes
            uint8_t buf[bytesToRead];
            NSInteger len = 0;
            len = [(NSInputStream *)stream read:buf maxLength:bytesToRead];
            
            // if data was read in
            //
            if(len > 0) {
                [self.readData appendBytes:(const void *)buf length:len];
                
                // Debug
                NSData *readDataChunck = [NSData dataWithBytes:buf length:len];
                NSString *readDataChunkString = [[NSString alloc] initWithData:readDataChunck encoding:NSUTF8StringEncoding];
                //DDLogVerbose(@"NC-se: read data chunk len:%d dataString:%@",len, readDataChunkString);
                [readDataChunkString release];
                // end debug
                
                // bytesRead is an instance variable of type NSNumber.
                self.bytesRead += len;
                
                // if header was just read in
                // - set the message length
                //
                if (self.bytesRead == kMPNetworkHeaderBytes) {

                    NSData *readHeaderData = [NSData dataWithBytes:buf length:len];
                    NSString *readHeaderString = [[NSString alloc] initWithData:readHeaderData encoding:NSUTF8StringEncoding];
                    DDLogVerbose(@"NC-se: read data header %@",readHeaderString);

                    if ([readHeaderString isEqualToString:kMPMessageNetworkPing]) {
                        [self processNetworkMessage:readHeaderString];
                    }
                    // if normal numeric message
                    //
                    else {
                        //self.readMessageLength = atoi([self.readData bytes]);  // atoi does not give consistent results
                        self.readMessageLength = [readHeaderString intValue];
                    }
                    [readHeaderString release];
                    DDLogVerbose(@"NC-se: HasBytes - header data:%@ msgLen:%d", self.readData, self.readMessageLength);
                    
                }
                // if message is complete!
                // - then send message for processing
                //
                else if (self.bytesRead == kMPNetworkHeaderBytes+self.readMessageLength){
                    [self processReadData]; 
                }
                // if too many bytes read
                //
                else if (self.bytesRead > kMPNetworkHeaderBytes+self.readMessageLength){
                    DDLogVerbose(@"MPN-ERROR: too many bytes read in - extends beyond one message");
                }
                // TODO: can we make the read more robust, what if bytes read exceed read length...
            } 
            else {
                DDLogVerbose(@"End of buffer or operations failed: len %d, %@", len, self);
            }
            break;
        }
            
            
        // space is available to write to output sream
        //
        case NSStreamEventHasSpaceAvailable:
        {
            DDLogVerbose(@"NC-se: HAS SPACE");

            if (self.currentWriteData) {
                [self writeToStream:stream];
            }
            // no data to write, so set flag
            // - next time just write to stream directly
            //
            else {
                self.hasWriteSpace = YES;
            }
            
            break;
        }
            
        case NSStreamEventErrorOccurred:
        {
            NSError *theError = [stream streamError];
            DDLogInfo(@"NC-se: ERROR encountered! - %i: %@ - %@", [theError code], [theError localizedDescription], self);
            // try reconnection
            [self handleLoginFailure:kMPCauseTypeSuccess];
            
            /*
            NSAlert *theAlert = [[NSAlert alloc] init]; // modal delegate releases
            [theAlert setMessageText:@"Error reading stream!"];
            [theAlert setInformativeText:[NSString stringWithFormat:@"Error %i: %@",
                                          [theError code], [theError localizedDescription]]];
            [theAlert addButtonWithTitle:@"OK"];
            [theAlert beginSheetModalForWindow:[NSApp mainWindow]
                                 modalDelegate:self
                                didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                                   contextInfo:nil];
             
            [stream close];
            [stream release];*/
            break;
        }
        case NSStreamEventNone:
        {
            DDLogVerbose(@"NC-se: NO EVENT occurred");
        }
        case NSStreamEventOpenCompleted:
        {
            DDLogVerbose(@"NC-se: OPEN completed");
        }
        case NSStreamEventEndEncountered:
        {
            DDLogVerbose(@"XXXxxxxxxxxxxxxNC-se: END encountered: %@", self);
            
            if (![self areConnectionOpened]) {
                DDLogVerbose(@"XXX**************NC-se: END but not opend!");
                [self handleLoginFailure:kMPCauseTypeSuccess];
            }
            
            // if connections are closed
            // - try authenticating again
            //
            /*BOOL opened = [self areConnectionOpened];
            if (!opened) {
                [self diconnect];
                [[MPSecurityCenter sharedMPSecurityCenter] authenticateAndLogin];
            }*/
            
            
        }
            // continued ...
    }
}

/*!
 @abstract For testing
 */
- (void)readBytes {
    [self stream:self.inputStream handleEvent:NSStreamEventHasBytesAvailable];
}

#pragma mark - 
#pragma mark Message Handling

/*!
 @abstract handles message related to this object
 */
- (void) handleMessage:(MPMessage *)newMessage {
    

    // if login was accepted - successful!
    //
    if ([newMessage.mType isEqualToString:kMPMessageTypeAccept]) {
        // save the internal IP of the actual domain server used
        //
        NSString *domainIP = [newMessage valueForProperty:kMPMessageKeyFromAddress];
        
        // successful login!
        if ([domainIP length] > 0) {
            DDLogVerbose(@"NC-hm: LOGIN SUCCESS");
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingDomainServerName settingValue:domainIP];
            
            // also update the my CDContact
            [CDContact updateMyNickname:nil domainClusterName:nil domainServerName:domainIP statusMessage:nil];
            
            // reset timer
            //
            [self resetRetrySeconds];
            
        }
        else {
            DDLogVerbose(@"NC-hm: ERROR - domain IP not found in login accept message!! %@", newMessage);
        }
    }
    // handle login rejection
    else if ([newMessage.mType isEqualToString:kMPMessageTypeReject]) {
        
        DDLogVerbose(@"NC-hm: LOGIN REJECTED");
        // if cause == 603 (invalid aKey), then
        // - reset aKey
        // - get new akey again (authenticate)
        //
        MPCauseType cause = [[newMessage valueForProperty:kMPMessageKeyCause] intValue];
        if (cause == kMPCauseTypeInvalidAKey) {
            // debug
            [Utility showAlertViewWithTitle:@"Login Failed" message:@"Invalid aKey"];
            [[MPSettingCenter sharedMPSettingCenter] setSecureValueForID:kMPSettingAuthKey settingValue:@""];
        }
        // what to do next?? - retry?
        // - do this at the nsstream end event section - 
        [self handleLoginFailure:cause];
    }
}

@end
