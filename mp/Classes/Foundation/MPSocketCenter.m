//
//  MPSocketCenter.m
//  mp
//
//  Created by M Tsai on 11-12-18.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//


#import "MPSocketCenter.h"
#import "GCDAsyncSocket.h"
#import "MPFoundation.h"
#import "CDContact.h"
#import "Reachability.h"
#import "MPChatManager.h"
#import "MPContactManager.h"

#import "MPDataScrambler.h"

CGFloat const kMPParamSCRetrySecondStart = 1.0;   // how fast should we retry after login failure
CGFloat const kMPParamSCDSConnectTimeout = 7.0;  // how long to wait for ds connection to establish
CGFloat const kMPParamSCDSMessageTimeout = 10.0;  // how long to wait for login reply message to return

CGFloat const kMPParamSCLoginWaitTimeout = 5.0; // how long to wait for login response to return


// time consider connection is to be idle
CGFloat const kMPParamSCKeepIdleTimeout = 49.0;

// how often to check for idle
CGFloat const kMPParamSCKeepIdleCheckPeriod = 10.0;

// time to wait for keep alive ack to return
CGFloat const kMPParamSCKeepAckWait = 30.0;

// Size of write message considered to be large (bytes)
// - if large then try to extend keep alive timer to allow for it to finish writing
NSUInteger const kMPParamSCKeepLargeWriteMinimum = 15000;


NSString* const MP_SOCKETCENTER_WRITE_TIMEOUT_NOTIFICATION = @"MP_SOCKETCENTER_WRITE_TIMEOUT_NOTIFICATION";
NSString* const MP_SOCKETCENTER_WRITE_PROGRESS_NOTIFICATION = @"MP_SOCKETCENTER_WRITE_PROGRESS_NOTIFICATION";

NSString* const MP_SOCKETCENTER_DISCONNECT_NOTIFICATION = @"MP_SOCKETCENTER_DISCONNECT_NOTIFICATION";
NSString* const MP_SOCKETCENTER_DISCONNECT_LOGIN_NOTIFICATION = @"MP_SOCKETCENTER_DISCONNECT_LOGIN_NOTIFICATION";


NSString* const MP_SOCKETCENTER_NETWORK_NOTREACHABLE_NOTIFICATION = @"MP_SOCKETCENTER_NETWORK_NOTREACHABLE_NOTIFICATION";

NSString* const MP_SOCKETCENTER_CONNECT_TRY_NOTIFICATION = @"MP_SOCKETCENTER_CONNECT_TRY_NOTIFICATION";
NSString* const MP_SOCKETCENTER_CONNECT_SUCCESS_NOTIFICATION = @"MP_SOCKETCENTER_CONNECT_SUCCESS_NOTIFICATION";


NSString* const kMPSCUserInfoKeyTag = @"kMPSCUserInfoKeyTag";
NSString* const kMPSCUserInfoKeyBytes = @"kMPSCUserInfoKeyBytes";


unsigned int const kMPSCHeaderBytes = 5;
unsigned int const kMPSCBodyMaxLength = 50000;

long const kMPSCTagNone = 0;
long const kMPSCTagHeader = 1;
long const kMPSCTagBody = 2;
long const kMPSCTagAttachment = 3;



// private methods
//
@interface MPSocketCenter (Private) 

- (void)disconnect;
- (void) readHeaderUseTimeout:(BOOL)useTimeout;
- (Reachability *) domainClusterReachable;
- (void) connectAndLoginPrivate;


@end


@implementation MPSocketCenter


@synthesize domainClusterReachable;
@synthesize isDomainClusterActive;
@synthesize retrySeconds;
@synthesize retryLoginTimer;
@synthesize waitLoginTimer;

@synthesize loginState;
@synthesize lastLoginMessageID;
@synthesize logoutBGTask;
@synthesize disableRetry;

@synthesize keepTimer;
@synthesize keepLastReadDate;
@synthesize keepDidExtendLastReadDate;

@synthesize encodedHeader;

@synthesize lastConnectedDate;

/*!
 @abstract initialized cell controller with related CDMessage
 
 if CDMessage is not available, then this is an blank message where user 
 can write a new message.
 
 */
- (id)init
{
	self = [super init];
	if (self != nil)
	{
        //asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

        // initialize socket to process delegates in the network queue
        //
        dispatch_queue_t netQueue = [AppUtility getQueueNetwork];
        asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:netQueue];
        
        // protect attributes in netQueue
        //
        dispatch_async(netQueue, ^{
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            
            // we are not logging out now
            self.loginState = kSCStateLoggedOut;
            
            // allow retry
            self.disableRetry = NO;
            
            // if app restart, set to now
            self.lastConnectedDate = [NSDate date];
            
            [pool drain];
        });
        
        self.keepDidExtendLastReadDate = NO;
        
        // listen on mainthread where we are created
        //
        if ([AppUtility isMainQueue]) {
            
            // listen to notification, so we can logout
            self.logoutBGTask = UIBackgroundTaskInvalid;
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(startLogoutTask:)
                                                         name:UIApplicationWillResignActiveNotification object:nil];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(startLoginTask:)
                                                         name:UIApplicationDidBecomeActiveNotification object:nil];

        }
        
        // init reachability
        [self domainClusterReachable];
        

        
	}
	return self;
}




- (void)dealloc {
    
    DDLogInfo(@"SC: deallocated");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // disconnect and release socket 
    
    // don't respond to delegate calls since we are disconnecting
    [asyncSocket setDelegate:nil delegateQueue:NULL];
    [self disconnect];
    [asyncSocket release];
    
    [lastLoginMessageID release];
    [domainClusterReachable release];
    
    [keepTimer release];
    [keepLastReadDate release];
    
    [super dealloc];
}


/*!
 @abstract print out status
 */
- (NSString *) description {
    return [self connectionStatus];
}

#pragma mark - Network Reachability

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
    // - no need to reset since we are only checking default route now
    /*[domainClusterReachable release];
    NSArray *parts = [hostname componentsSeparatedByString:@":"];
    domainClusterReachable = [[Reachability reachabilityWithHostName:[parts objectAtIndex:0]] retain];
    [domainClusterReachable startNotifier];
     */
}


/*! 
 @abstract getter for domainClusterReachable
 @discussion creates instanace if not available
 
 */
- (Reachability *) domainClusterReachable {
        
    if (!domainClusterReachable) {
        
        // The route may not be avialable in some networks, but still reachable?
        // - happened to Ben in NanJing
        //
        /*NSString *hostPort = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingDomainClusterName];
        NSArray *parts = [hostPort componentsSeparatedByString:@":"];
        
        domainClusterReachable = [[Reachability reachabilityWithHostName:[parts objectAtIndex:0]] retain];*/
        
        // get default route is available
        //
        domainClusterReachable = [[Reachability reachabilityForInternetConnection] retain];
        [domainClusterReachable startNotifier];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
    }
    return domainClusterReachable;
}



/*!
 @abstract handles network status changes
 */
- (void) checkNetworkStatus:(NSNotification *)notice
{
    
    // called after network status changes
    NetworkStatus internetStatus = [domainClusterReachable currentReachabilityStatus];
    switch (internetStatus)
    
    {
        case NotReachable:
        {
            DDLogWarn(@"The internet is down.");
            self.isDomainClusterActive = NO;
            
            break;
            
        }
        case ReachableViaWiFi:
        {
            DDLogInfo(@"The internet is working via WIFI.");
            self.isDomainClusterActive = YES;
            
            break;
            
        }
        case ReachableViaWWAN:
        {
            DDLogInfo(@"The internet is working via WWAN.");
            self.isDomainClusterActive = YES;
            
            break;
            
        }
    }
    
    // if network is active again, try login right away!
    //
    if (self.isDomainClusterActive){
        DDLogInfo(@"SC: Net available, start login");
        [self setupDomainConnectionAndLogin];
    }
    // if lose connection, close connections and inform users?
    //
    else {
        
        // inform others that network went down
        // - chat dialog status needs this
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_SOCKETCENTER_NETWORK_NOTREACHABLE_NOTIFICATION object:nil];
        
        //[Utility showAlertViewWithTitle:@"Reachability" message:@"Lost network..."];
        [self disconnect];
    }
    
    
    
    /*
    NetworkStatus hostStatus = [domainClusterReachable currentReachabilityStatus];
    switch (hostStatus)
    
    {
        case NotReachable:
        {
            DDLogVerbose(@"SC: host server is down.");
            self.isDomainClusterActive = NO;
            
            break;
            
        }
        case ReachableViaWiFi:
        {
            DDLogVerbose(@"SC: host server is working via WIFI.");
            self.isDomainClusterActive = YES;
            
            break;
            
        }
        case ReachableViaWWAN:
        {
            DDLogVerbose(@"SC: host server is working via WWAN.");
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
        // TODO: notify users
        //[Utility showAlertViewWithTitle:@"Reachability" message:@"Lost connection to DS."];
        [self disconnect];
    }
     */
}


/*!
 @abstract check if default route is available
 
 */
- (BOOL) isNetworkReachable {
    if ([self.domainClusterReachable currentReachabilityStatus] == NotReachable) {
        return NO;
    }
    return YES;
}



#pragma mark - Status Query Methods

/*!
 @abstract Is socket connected - simple response
 
 @return YES if connected, NO if error or closed
 */
- (BOOL)isConnected {
    return [asyncSocket isConnected];
}


/*!
 @abstract Check is connection state is logged in
 
 @return YES if logged in, NO if not
 
 Use:
 - used by chat title status to check if we are logged in
 
 */
- (BOOL) isLoggedIn {
    if (self.loginState == kSCStateLoggedIn && [self isConnected]) {
        return YES;
    }
    return NO;
}


/*!
 @abstract Is socket connected - simple response
 
 @return YES if connected, NO if error or closed
 */
- (BOOL) isDisconnectFresh {
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");
    
    if (self.lastConnectedDate) {
        NSDate *freshDate = [NSDate dateWithTimeInterval:kMPParamNetworkTimeoutFreshDisconnect sinceDate:self.lastConnectedDate];
        
        NSTimeInterval time = [freshDate timeIntervalSinceDate:[NSDate date]];
        DDLogInfo(@"SC-idf: fresh time: %f", time);
        
        if ([freshDate compare:[NSDate date]] == NSOrderedDescending) {
            return YES;
        }
    }
    return NO;
}



#pragma mark - Connection Methods


/*!
 @abstract Check if it is ok to login now?
 
 
 */
- (BOOL) shouldTryLogin {
        
    // don't connect if already loggedin and connected
    // - mainly prevents a retry timer that will fire after we connect, don't want to disconnect and connect again
    // - however if loggedin but not connected, this is a bad state so we should proceed
    //
    if ([self isLoggedIn]) {

        DDLogInfo(@"SC: Don't CNT&LOG - already logged in & connected");

        return NO;
    }
    
    // don't connect if we are preparing to login
    //
    if (self.loginState == kSCStateLoggingIn) {
        
        DDLogInfo(@"SC: Don't CNT&LOG - login in progress");

        return NO;
    }
    
    // if waiting for login response
    // - & timer is alive, then don't try login
    // - if timer is dead, we should try to login
    //
    if (self.loginState == kSCStateWaitLogin) {
        __block BOOL isWaiting = NO; 
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ([self.waitLoginTimer isValid]) {
                isWaiting = YES;
            }
        });
        
        if (isWaiting) {
            DDLogInfo(@"SC: Don't CNT&LOG - waiting for login response");
            return NO;
        }
    }
    
    // If akey is invalid, authenticate instead of logging
    // - check akey right before trying to login and not when setting up retry timer
    //   too much time may pass between that and the akey may become invalid
    //
    if (![[MPSettingCenter sharedMPSettingCenter] isAkeyAndClusterValid]) {
        
        DDLogWarn(@"SC: Don't CNT&LOG - invalid akey, re-authenticate");
        dispatch_async(dispatch_get_main_queue(), ^{
            [[MPHTTPCenter sharedMPHTTPCenter] authenticateAndLogin];
        });
        
        return NO;
    }
    
    return YES;
}


/*! 
 @abstract resets timer to 0.25 seconds 
 
 Use:
 - reset if login is successful
 - reset if app becomes active
 
 */
- (void) resetRetrySeconds {
    NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");
    
    self.retrySeconds = kMPParamSCRetrySecondStart;
}

/*!
 @abstract Disable login retries
 
 Use:
 - used to logout for good
 
 */
- (void) shutdownRetry {
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");

    DDLogInfo(@"SC: Shut down retry!");

    
    // disable for now
    self.disableRetry = YES;
    
    // reset retry timer, so we can retry quickly next time
    //
    [self resetRetrySeconds];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.retryLoginTimer invalidate];
    });
    
}


/*!
 @abstract Enable login retries
 
 Use:
 - enable if we should provide retry again
 
 */
- (void) startupRetry {

    DDLogInfo(@"SC: Start retry again");
    
    dispatch_queue_t netQueue = [AppUtility getQueueNetwork];    
    
    // protect attributes in netQueue
    //
    dispatch_async(netQueue, ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        // disable for now
        self.disableRetry = NO;
        
        // reset retry timer, so we can retry quickly next time
        //
        [self resetRetrySeconds];
        
        [pool drain];
    });
}


/*!
 @abstract Shorten login retries
 
 Use:
 - When we want to retry asap instead of waiting
 - When user wants to send messages but we are not logged in yet
 
 */
- (void) resetRetry {
    
    dispatch_queue_t netQueue = [AppUtility getQueueNetwork];    
    
    // protect attributes in netQueue
    //
    dispatch_async(netQueue, ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        // reset retry timer, so we can retry quickly next time
        // - only if retry is long enough
        // - we don't want to keep resetting the timer, otherwise the it will never fire
        // - also restart timer, since it timer could be very long
        //
        if (self.retrySeconds > 8.0) {
            [self resetRetrySeconds];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([self.retryLoginTimer isValid]) {
                    [self.retryLoginTimer invalidate];
                    
                    DDLogInfo(@"AD: retry AALogin in %f secs.", self.retrySeconds);
                    
                    self.retryLoginTimer = [NSTimer scheduledTimerWithTimeInterval:self.retrySeconds target:[MPHTTPCenter sharedMPHTTPCenter] selector:@selector(authenticateAndLogin) userInfo:nil repeats:NO];
                }
            });
        }
        
        [pool drain];
    });
}



/*!
 @abstract disconnects from domain server by closing input and output streams
 */
- (void)disconnect {
    
    BOOL connected = [asyncSocket isConnected];
    if (connected) {
        DDLogWarn(@"SC-WARN: disconnect when already connected!");
    }
    DDLogInfo(@"SC: disconnecting..");
    
    // disconnect immediately - ignore pending reads and writes
    [asyncSocket disconnect];    
}

/*!
 @abstract connect to remote server and create streams
 
 @return YES if connect process started ok, NO if error
 */
- (BOOL)connectToHost:(NSString *)hostname port:(NSInteger)port {
   
    NSError *error = nil;
    
    // make sure we disconnect before connecting
    if ([self isConnected]) {
        [self disconnect];
    }
    
    if ([asyncSocket connectToHost:hostname onPort:port withTimeout:kMPParamSCDSConnectTimeout error:&error]){
        DDLogInfo(@"SC-cth: Connecting to \"%@\" on port %d ...", hostname, port);
        return YES;
    }
    else {
        DDLogError(@"SC-cth: Unable to connect to due to invalid config: %@", [error localizedDescription]);
        return NO;
    }
}





/*!
 @abstract check status - for debugging
 */
- (NSString *) connectionStatus {
    
    NSString *loginString = nil;
    switch (self.loginState) {
        case kSCStateLoggedIn:
            loginString = @"LoggedIn";
            break;
        case kSCStateLoggingIn:
            loginString = @"LoggingIn";
            break;
        case kSCStateWaitLogin:
            loginString = @"LoggingWait";
            break; 
        case kSCStateLoggedOut:
            loginString = @"LoggedOut";
            break;
        case kSCStateLoggingOut:
            loginString = @"LoggingOut";
            break;
        default:
            break;
    }
    
    NSString *statusString = [NSString stringWithFormat:@"NET-NetAvail:%@ Connection:%@ LoginState:%@", 
                              [domainClusterReachable currentReachabilityStatus]?@"YES":@"NO", 
                              [self isConnected]?@"YES":@"NO", loginString];
    return statusString;
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
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");
    
    DDLogInfo(@"SC-hlf: Handle Failure, status: %@ ", [self connectionStatus]);
    
    // only retry if net is reachable && not connected && we are not trying to logout now
    //
    // - still try if no routing is available: 
    //   [self.domainClusterReachable currentReachabilityStatus] != NotReachable &&
    //   do this anyways since cost of retry is not expensive
    //
    if (![self isConnected] &&
        self.loginState != kSCStateLoggingOut &&
        self.disableRetry == NO ) {
        
        // no need to wait for login any more
        // - we are going in the process of retrying anyways
        // - also stop old retry timer as well
        //
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.waitLoginTimer invalidate];
            [self.retryLoginTimer invalidate];
        });
    
        if (self.loginState == kSCStateWaitLogin) {
            DDLogInfo(@"SC-hlf: change state - loginWait => loggedout");
            self.loginState = kSCStateLoggedOut;
        }
        
        // double value
        self.retrySeconds = self.retrySeconds *2.0;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.retryLoginTimer = [NSTimer scheduledTimerWithTimeInterval:self.retrySeconds target:self selector:@selector(setupDomainConnectionAndLogin) userInfo:nil repeats:NO];
        });
        
        
        // ** too early to check for invalid akey, to this right before login attempt
        //
        //NSTimeInterval delay_in_seconds = self.retrySeconds;
        //dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, delay_in_seconds * NSEC_PER_SEC);
        
        // authen and then retry
        // - if invalid key
        //
        /*NSString *aKey = [[MPSettingCenter sharedMPSettingCenter] secureValueForID:kMPSettingAuthKey];
        NSString *cluster = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingDomainClusterName];
        if (cause == kMPCauseTypeInvalidAKey || [aKey length] < 3 || [cluster length] < 3) {
    
            DDLogWarn(@"SC-hlf: invalid key - so reauthenticating on next retry");
            
            dispatch_async(dispatch_get_main_queue(), ^{
            
                self.retryLoginTimer = [NSTimer scheduledTimerWithTimeInterval:self.retrySeconds target:[MPHTTPCenter sharedMPHTTPCenter] selector:@selector(authenticateAndLogin) userInfo:nil repeats:NO];
                
            });
        }
        else {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.retryLoginTimer = [NSTimer scheduledTimerWithTimeInterval:self.retrySeconds target:self selector:@selector(setupDomainConnectionAndLogin) userInfo:nil repeats:NO];
                
            });
        }*/        
        
        DDLogInfo(@"SC-hlf: try connecting in %f secs", self.retrySeconds);
    }
    // net not available - reset time secs, so when net recovers we retry quickly after failure
    else{
        if ([self isConnected]) {
            DDLogWarn(@"SC-hlf: dont' retry - already connected");
        }
        else if (self.loginState == kSCStateLoggingOut) {
            DDLogWarn(@"SC-hlf: dont' retry - currently logging out");
        }
        // reset timer
        [self resetRetrySeconds];
    }
}


/*!
 @abstract Timeout Wait Login
 
 If after submiting login request, we don't get a response after X seconds:
 - change state to logged out
 - disconnected if connected
 */
- (void)timeoutWaitLogin {
    
    dispatch_queue_t netQueue = [AppUtility getQueueNetwork];    
    
    // protect attributes in netQueue
    //
    dispatch_async(netQueue, ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        // still waiting and this is the same login that we are waitin for
        // - otherwise if user leaves and enters, there is a chance that this will timeout another login
        //
        if (self.loginState == kSCStateWaitLogin) {
            DDLogWarn(@"SC-twl: Wait too long for LOGIN reply - timing out! - disCNT & try again");
            
            self.loginState = kSCStateLoggedOut;
            if ([self isConnected]) {
                [self disconnect];
            }
            else {
                [self handleLoginFailure:kMPCauseTypeSuccess];
            }
        }
        
        [pool drain];
    });
}

/*!
 @abstract Connect to DS and attempt login
 
 Should not login if:
 - if logged in and already connected
 - if this method is already running
 
 Should login even when:
 - logging out - this may be the state left when going into background
 - etc.
 
 */
- (void) connectAndLoginPrivate {
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");
    
    DDLogInfo(@"SC-clp: Attemp Login, status: %@ ", [self connectionStatus]);
    
    // test if we should login, if not then do nothing
    if (![self shouldTryLogin]) {
        return;
    }
    
    // if previously in connected state
    // - save date to determine if disconnect is fresh
    // - this sometimes occur when switching between different types of wireless signals
    //
    if (self.loginState == kSCStateLoggedIn) {
        DDLogInfo(@"SC-clp: was previously loggedIn - send disconnect notification");
        self.lastConnectedDate = [NSDate date];
        
        // stop keep alive timer
        //
        [self stopKeepTimer];
        
        // inform others that connection was broken
        //
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_SOCKETCENTER_DISCONNECT_LOGIN_NOTIFICATION object:nil];
        });
    }
    
    
    // prevent retry after disconnect
    self.loginState = kSCStateLoggingIn;
    
    // invalidate old wait timers, so they don't disconnect us
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.waitLoginTimer invalidate];
        [self.retryLoginTimer invalidate];
    });
    
    // inform others that we are connecting
    // - chat dialog status needs this
    // - don't inform if network is not available
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isNetworkReachable]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_SOCKETCENTER_CONNECT_TRY_NOTIFICATION object:nil];
        }
    });
    
    
    
    // make sure retry is valid
    if (self.retrySeconds < kMPParamSCRetrySecondStart) {
        [self resetRetrySeconds];
    }
    
    NSString *hostPort = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingDomainClusterName];
    NSArray *parts = [hostPort componentsSeparatedByString:@":"];
    
    // if not connnected, try connecting
    //
    /*if (![self isConnected]) {
        [self disconnect];
        [self connectToHost:[parts objectAtIndex:0] port:[[parts objectAtIndex:1] integerValue]];
    }*/
    

    // always try to reconnect
    if ([parts count] == 2) {
        

        //[asyncSocket setDelegate:nil];
        if ([self isConnected]) {
            DDLogWarn(@"SC-clp: CNT - already connected, kill current connection");
            [self disconnect];
        }
        
        DDLogInfo(@"SC-clp: CNTing to h:%@ p:%@ - isCNT:%@",
                  [parts objectAtIndex:0], 
                  [parts objectAtIndex:1],  
                  [asyncSocket isConnected]?@"YES":@"NO");

        //[asyncSocket setDelegate:self];
        BOOL startConnect = [self connectToHost:[parts objectAtIndex:0] port:[[parts objectAtIndex:1] integerValue]];
        if (!startConnect) {
            DDLogError(@"SC-clp: CNT - quit Login process - connect failed");
            return;
        }
    }
    else {
        DDLogError(@"SC-clp: CNT - quit Login process -  invalid host %@", hostPort);
        self.loginState = kSCStateLoggedOut;
        return;
    }
    
    // if not logged in, login
    // - create login message and send it
    //
    MPMessage *loginMessage = [MPMessage messageLoginIsSuspend:NO];
    
    // save mID to check for wait login timeout
    self.lastLoginMessageID = loginMessage.mID;
    
    DDLogInfo(@"SC-clp: LOGIN-submit");
    [self addDataToWriteQueue:[loginMessage rawNetworkData]];
        
    // start the first read with a timeout
    [self readHeaderUseTimeout:YES];
    
    
    // run a timer in case state left in login wait for too long
    //
    /*
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, delay_in_seconds * NSEC_PER_SEC);
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_after(delay, queue, ^{
        [self timeoutWaitLogin:self.lastLoginMessageID];
    });*/
    
    NSTimeInterval delay_in_seconds = 10.0;// seconds
    
    // make sure timer is valid before state is set
    //
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.waitLoginTimer = [NSTimer scheduledTimerWithTimeInterval:delay_in_seconds target:self selector:@selector(timeoutWaitLogin) userInfo:nil repeats:NO];
    });
    
    self.loginState = kSCStateWaitLogin;
    
    // mark outstanding messages as previous so we can send them out for this session
    //
    [MPChatManager markPreviousOutstandingMPMessages];
}



/*!
 @abstract Setup connection to domain servers
 
 - use internally
 
 - check if connections are available
 ~ if not, connect
 - check if logged in
 ~ if not, login
 
 */
- (void) setupDomainConnectionAndLogin {
    
    dispatch_queue_t netQueue = [AppUtility getQueueNetwork];    
    
    // protect attributes in netQueue
    //
    dispatch_async(netQueue, ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        [self connectAndLoginPrivate];

        [pool drain];
    });
    
}


/*!
 @abstract Public login method
 - activiates retry
 
 */
- (void) loginAndConnect {
    
    [self startupRetry];
    [self setupDomainConnectionAndLogin];
    
}


/*!
 @abstract Logout and disconnect
 */
- (void) logoutAndDisconnect {
    
    DDLogInfo(@"SC: LOGOUT-start");

    dispatch_queue_t netQueue = [AppUtility getQueueNetwork];    
    
    // protect attributes in netQueue
    //
    dispatch_async(netQueue, ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        // - make sure we don't retry to login
        // - if disconnect don't handle failure
        [self shutdownRetry];
        
        // prevents retries during this time
        //
        self.loginState = kSCStateLoggingOut;
        
  
        // reset retry timer, so we can retry quickly next time
        //
        [self resetRetrySeconds];
        
        // only send logout if connected
        //
        if ([self isConnected]) {
            DDLogInfo(@"SC: LOGOUT-submit");

            // create and send logout message
            //
            MPMessage *logoutMessage = [MPMessage messageLogoutIsSuspend:YES];
            [self addDataToWriteQueue:[logoutMessage rawNetworkData]];
        }
        else {
            DDLogWarn(@"SC: LOGOUT-cancelled - not connected now");
        }
        
        [pool drain];
    });
    
}

#pragma mark - Keepalive

/*
 Keep alive parameters should all be protected in main thread
 */

/*!
 @abstract Repeats every 5 sec to check if we are idle and need to send keep alive @ping
 
 */
- (void) startKeepIdleTimer {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // if timer running, don't start it again
        if ([self.keepTimer isValid]) {
            return;
        }
        
        self.keepTimer = [NSTimer scheduledTimerWithTimeInterval:kMPParamSCKeepIdleCheckPeriod target:self selector:@selector(checkForIdleConnection) userInfo:nil repeats:YES];
    });
    
}

/*!
 @abstract Stops keep alive timer
 
 */
- (void) stopKeepTimer {
    
    if (dispatch_get_current_queue() == dispatch_get_main_queue()) {
        [self.keepTimer invalidate];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.keepTimer invalidate];
        });
    }
    
}

/*!
 @abstract Sends ping without disconnect timer
 
 Use:
 - sends a ping to help keep the connection alive
 - send before a large message, this will help reset the idle connection timer when the @ack comes back
 
 */
- (void) sendPing {

    dispatch_queue_t netQ = [AppUtility getQueueNetwork];
    
    if (dispatch_get_current_queue() != netQ) {
        dispatch_async(netQ, ^{
            NSData *ackData = [kMPMessageNetworkPing dataUsingEncoding:NSUTF8StringEncoding];
            [self addDataToWriteQueue:ackData];
        });
    }
    else {
        NSData *ackData = [kMPMessageNetworkPing dataUsingEncoding:NSUTF8StringEncoding];
        [self addDataToWriteQueue:ackData];
    }
}


/*!
 @abstract Sends keepalive
 
 */
- (void) sendKeepAlive {

    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"Must be dispatched on mainQueue");
    
    DDLogInfo(@"SC-ska: send keep alive ping");
    [self stopKeepTimer];

    // start timer to wait for ack response
    // - if fail, then send ping again
    self.keepTimer = [NSTimer scheduledTimerWithTimeInterval:kMPParamSCKeepAckWait target:self selector:@selector(disconnectIdleConnection) userInfo:nil repeats:NO];
    
    dispatch_async([AppUtility getQueueNetwork], ^{
        NSData *ackData = [kMPMessageNetworkPing dataUsingEncoding:NSUTF8StringEncoding];
        [self addDataToWriteQueue:ackData];
    });

}

/*!
 @abstract Sends keepalive - Deprecated
 - 2nd ping check is not needed 
 
 */
- (void) sendKeepAliveAgain {
    
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"Must be dispatched on mainQueue");
    
    DDLogInfo(@"SC-skaa: send keep alive 2nd ping");
    
    [self stopKeepTimer];
    
    // start timer to wait for ack response
    // - if fail then disconnect
    self.keepTimer = [NSTimer scheduledTimerWithTimeInterval:kMPParamSCKeepAckWait target:self selector:@selector(disconnectIdleConnection) userInfo:nil repeats:NO];
    
    dispatch_async([AppUtility getQueueNetwork], ^{
        NSData *ackData = [kMPMessageNetworkPing dataUsingEncoding:NSUTF8StringEncoding];
        [self addDataToWriteQueue:ackData];
    });
}

/*!
 @abstract Disconnect since the connection seems to be idle
 
 Make exception if a read had come in recently.  We don't really care if it was ack.
 ~ A regular read is good evidence that the connection is ok.
 ~ This may be needed if @ping is queued behind a large image message so the ack will take a while to come back
 
 */
- (void) disconnectIdleConnection {
    
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"Must be dispatched on mainQueue");
    
    // check if read came in while we are waiting for @ack
    NSTimeInterval lastTime = [self.keepLastReadDate timeIntervalSinceNow];
    
    // while we are waiting for @ack and add a few seconds to prevent any race conditions
    if (lastTime > -(5.0 + kMPParamSCKeepAckWait) ) {
        
        DDLogInfo(@"SC-dic: found read message - cancel disconnect! - %f", lastTime);

        // stop disconnect timer
        [self stopKeepTimer];
        
        // start regular timer backup
        [self startKeepIdleTimer];
    }
    else {
        DDLogInfo(@"SC-dic: broken connection found - disconnect!");
        
        [self stopKeepTimer];
        [self disconnect];
    }
}


/*!
 @abstract Checks if connection is idle
 
 */
- (void) checkForIdleConnection {

    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"Must be dispatched on mainQueue");

    DDLogInfo(@"SC-cfic: checking idle connection");
    
    NSTimeInterval lastTime = [self.keepLastReadDate timeIntervalSinceNow];
    
    if (lastTime < -kMPParamSCKeepIdleTimeout) {

        DDLogInfo(@"SC-dic: idle timed out - %f", lastTime);

        // stop timer
        [self stopKeepTimer];
        
        // send ping
        [self sendKeepAlive];
    
    }
    // otherwise, do nothing and keep timer will fire again in 5 seconds to check
}


#pragma mark - Write

/*!
 @abstract Check if we should try connecting
 
 @param shouldReset - should reset retry timer
 
 Use:
 - if we got write request and we are logged out, try login immediately
 
 */
- (void) tryLoginAndResetTimer:(BOOL)shouldReset {
    
    // if not connected - then it is ok to retry connection
    // if logging out - then don't connected 
    // 
    if (![self isConnected] && self.loginState != kSCStateLoggingOut) {

        
        // always run in network queue
        //
        dispatch_queue_t netQ = [AppUtility getQueueNetwork];
        if (dispatch_get_current_queue() != netQ) {
            
            // protect attributes in netQueue
            //
            dispatch_async(netQ, ^{
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                
                if (shouldReset) {
                    // reset timer since user is active
                    //
                    [self resetRetrySeconds];
                }
                [self connectAndLoginPrivate];
                
                [pool drain];
            });
            
        }
        else {
            if (shouldReset) {
                // reset timer since user is active
                //
                [self resetRetrySeconds];
            }
            [self connectAndLoginPrivate];
        }
    }
    else {
        DDLogWarn(@"SC: Try login rejected CNT:%@ ST:%@", [self isConnected]?@"Y":@"N", [self connectionStatus]);
    }
}

/*!
 @abstract Add write request with full options
 
 Use:
 - to help get notified when timeout occurs
 - puts suffix of messageID in tag
 
 Note:
 - If no network, post notification
 - try to login
 
 */
- (void) addDataToWriteQueue:(NSData *)newData timeout:(NSTimeInterval)timeout tag:(long)tag {
   
    NSUInteger dataLength = [newData length];
    
    DDLogInfo(@"SC: write data - %d tag:%ld", [newData length], tag);

    
    if (dataLength == 0) {
        DDLogError(@"SC-ERROR: 0byte data");
    }
    else if (dataLength > kMPParamSCKeepLargeWriteMinimum) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.keepDidExtendLastReadDate == NO) {
                DDLogInfo(@"SC: extended keep alive timer with large write");
                // set last read time for keepalive
                self.keepLastReadDate = [NSDate date];
                // we extended the read artificially!
                self.keepDidExtendLastReadDate = YES;
            }
        });
    }
    
    // -1 no time out
    [asyncSocket writeData:newData withTimeout:timeout tag:tag];
}

/*!
 @abstract Add write request to socket queue
 
 If no network, silently fails
 
 */
- (void) addDataToWriteQueue:(NSData *)newData {
    
    DDLogInfo(@"SC: write data - %d", [newData length]);
    
    // only write and try login if network is available
    // 
    if ([self.domainClusterReachable currentReachabilityStatus] != NotReachable) {
        
        if ([newData length] == 0) {
            DDLogError(@"SC-ERROR: 0byte data");
        }
        
        // -1 no time out
        [asyncSocket writeData:newData withTimeout:-1 tag:kMPSCTagNone];
        
        //[self tryLoginAndResetTimer:NO];
        
    }
    else {
        DDLogInfo(@"SC: write ignored - no network");
    }
}


// mostly starts in network queue
#pragma mark - Read Requests 

/* Message Documentation
 
 1. Text message:
 AAAAA@BBBBB?IE1=xxxx&IE2=yyyy&.....&text=zzzz 
 
 AAAAA: integer , fix 5 bytes – indicates the length of the Text Message
 ( from @ to end of message zzzz ) 
 
 @ : Symbol , 1 byte - start of message 
 BBBBB: string , variable length – indicates the type of message . 
 ? : Symbol , 1 byte - start of element IEx: string , variable length – name of the x’ element (not case sensitive) 
 =: Symbol, 1 byte – start of element’s data xxxx: string , variable length – the data or value of element-x 
 & : Symbol , 1 byte - separator of elements
 
 Note : special character : ? , =, & if used in element data , should add ‘\’ before special character . e.g. \? \= \&
 
 2. Text message with Attach-File : AAAAA@BBBBB?IE1=xxxx&attachlength=nnnn&.....&IEn=zzzz........... 
 
 AAAAA: integer , fix 5 bytes – indicates the length of the Text Message
 ( from @ to end of message zzzz , not include attach data ........... ) 
 attachlength: string , fix 12 bytes – the element name to indicate attached data length 
 nnnn: integer, variable length – the length of attached data ...........: string , variable length – attached data
 
 */
 


/*!
 @abstract Reads the 5 byte header for DS messages
 
 */
- (void) readHeaderUseTimeout:(BOOL)useTimeout {
    
    // no timeout
    CGFloat timeout = -1.0;
    
    if (useTimeout) {
        timeout = kMPParamSCDSMessageTimeout;
    }
    
    [asyncSocket readDataToLength:kMPSCHeaderBytes withTimeout:timeout tag:kMPSCTagHeader];

}



/*!
 @abstract Read message body
 
 @param useTimeout should only use for login message, other reads should just keep listening for new data
 
 */
- (void) readBody:(NSInteger)length {
    
    [asyncSocket readDataToLength:length withTimeout:-1.0 tag:kMPSCTagBody];
    
}


/*!
 @abstract Read attachement --- not needed yet, since attachement are not sent from servers
 
 @param useTimeout should only use for login message, other reads should just keep listening for new data
 
 */
- (void) readAttachment:(NSInteger)length {
    
    [asyncSocket readDataToLength:length withTimeout:-1.0 tag:kMPSCTagAttachment];
    
}

// runs in network queue
#pragma mark - Process Read Data


/*!
 @abstract checks if ping message and reply with ack, also reset read counters
 
 */
- (void) processNetworkMessage:(NSString *)networkMessage {
    
    
    if ([networkMessage isEqualToString:kMPMessageNetworkPing]) {
        DDLogInfo(@"SC-pnm: got ping, sending ack");
        NSData *ackData = [kMPMessageNetworkAck dataUsingEncoding:NSUTF8StringEncoding];
        [self addDataToWriteQueue:ackData];
    }
    else if ([networkMessage isEqualToString:kMPMessageNetworkAck]) {
        DDLogInfo(@"SC-pnm: got ack - connection is alive");
        [self stopKeepTimer];
        [self startKeepIdleTimer];
    }
    else {
        DDLogError(@"SC: process non-ping msg - %@", networkMessage);
    }
}


/*!
 @abstract parse header data
 
 @return length of message body to read in, 
  - 0 if no body content to read (ping messages) - so just read another header again
 
 */
- (NSInteger)parseHeaderData:(NSData *)headerData {
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");
    
    NSInteger bodyLength = -1;
    
    NSString *readHeaderString = [[NSString alloc] initWithData:headerData encoding:NSUTF8StringEncoding];
    DDLogInfo(@"SC-phd: Raw data header %@",readHeaderString);
    
    if ([readHeaderString isEqualToString:kMPMessageNetworkPing] ||
        [readHeaderString isEqualToString:kMPMessageNetworkAck]) {
        [self processNetworkMessage:readHeaderString];
        bodyLength = 0;
    }
    // if normal numeric message
    //
    else {
        
        if (kMPParamNetworkEnableDataScrambling) {
            // save encoded header
            self.encodedHeader = headerData;
            
            // decode to get length
            bodyLength = [MPDataScrambler decodeLengthHeader:headerData];
            DDLogInfo(@"SC-phd: scram - Decoded Header Length %d",bodyLength);
        }
        else {
            // ret 0 if invalid integer string
            bodyLength = [readHeaderString integerValue];
        }
        
        // check if length is reasonable
        //
        if (bodyLength > kMPSCBodyMaxLength || bodyLength == 0) {
            DDLogError(@"SC: got INVALID header %@ - Net Error", readHeaderString);
            // reset this connection
            [self disconnect];
            
            /* disable for production 
             NSString *invalidString = [NSString stringWithFormat:@"SC: got INVALID header %@", readHeaderString];
             
             dispatch_async(dispatch_get_main_queue(), ^{
             [Utility showAlertViewWithTitle:@"SC: Error" message:invalidString];            
             }); */
            
            bodyLength = 0;
        }
    }
    [readHeaderString release];
    return bodyLength;
}


/*!
 @abstract parse header data
 
 @return length of message body to read in, 
 - 0 if no body content to read (ping messages) - so just read another header again
 
 */
- (void)parseBodyData:(NSData *)bodyData {
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");
    
    if (kMPParamNetworkEnableDataScrambling && self.encodedHeader) {
        // decode body first
        NSData *decodeMessageBody = [MPDataScrambler decodedMessage:bodyData length:[bodyData length] encodeLength:self.encodedHeader];
        [[MPMessageCenter sharedMPMessageCenter] processInComingMessageData:decodeMessageBody];
        
        // reset header for next message
        self.encodedHeader = nil; 
        DDLogInfo(@"SC-phd: scram - Decoded Body Length %d", [decodeMessageBody length]);
    }
    else {
        // send to message center
        //
        [[MPMessageCenter sharedMPMessageCenter] processInComingMessageData:bodyData];
    }
}



// runs in the network queue
#pragma mark - Socket Delegate


/*!
 @abstract connection established successfully
 
 */
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    DDLogInfo(@"SC: did connect to host:%@ port:%d", host, port);
}

/*!
 @abstract connection failed with error or disconnected on purpose
 
 */
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
    
    DDLogInfo(@"SC: disconnect with error: %@", [error localizedDescription]);
    
    // if connected before, save date to determine if disconnect is fresh
    //
    if (self.loginState == kSCStateLoggedIn) {
        self.lastConnectedDate = [NSDate date];
        
        // inform others that connection was broken
        //
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_SOCKETCENTER_DISCONNECT_LOGIN_NOTIFICATION object:nil];
        });
    }
    
    // disconnected so reset state
    //
    self.loginState = kSCStateLoggedOut;

    // stop keep alive timer
    //
    [self stopKeepTimer];
        
    // raise notification with tag
    // - clear pending messages
    //[[NSNotificationCenter defaultCenter] postNotificationName:MP_SOCKETCENTER_DISCONNECT_NOTIFICATION object:nil];
    
    // always try to reconnect - connection is broken for any reason
    //
    [self handleLoginFailure:kMPCauseTypeSuccess];
    
}

/*!
 @abstract get read data - now process it
 
 */
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    DDLogInfo(@"SC: read data %d tag:%ld", [data length], tag);
    
    if (tag == kMPSCTagHeader)
    {
        int bodyLength = [self parseHeaderData:data];
        
        // if no body, look for the next msg header
        if (bodyLength == 0) {
            [self readHeaderUseTimeout:NO];
        }
        else {
            [self readBody:bodyLength];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // set last read time for keepalive
            self.keepLastReadDate = [NSDate date];
            // reset after each read
            self.keepDidExtendLastReadDate = NO;
        });
        
    }
    else if (tag == kMPSCTagBody)
    {
        // Process the response
        [self parseBodyData:data];
        
        // Start reading the next msg header
        [self readHeaderUseTimeout:NO];
        
    }
    else {
        NSString *badString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        DDLogError(@"SC: unrecognized read data tag! %@", badString);
        [badString release];
    }
}



/*!
 * Called when a socket has written some data, but has not yet completed the entire write.
 * It may be used to for things such as updating progress bars.
 
 Use:
 - update upload progress for images
 
 **/
- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    
    DDLogVerbose(@"SC-dwp: %ld %d", tag, partialLength);
    // only for tagged writes
    //
    if (tag > 100) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSDictionary *userInfoD = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:tag], kMPSCUserInfoKeyTag, [NSNumber numberWithInteger:partialLength], kMPSCUserInfoKeyBytes, nil];
            
            // raise notification with tag
            //
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_SOCKETCENTER_WRITE_PROGRESS_NOTIFICATION   object:nil userInfo:userInfoD];
        });
    }
}

/**
 * Called when a socket has completed writing the requested data. Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    
    DDLogInfo(@"SC: write complete - %ld", tag);
    if (tag != kMPSCTagNone) {
        // inform MC that we finished writing
        //
        [[MPMessageCenter sharedMPMessageCenter] didWriteBufferForMessageID:tag];
        
        // inform that upload is complete
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // -1 length == 100% done
            NSDictionary *userInfoD = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:tag], kMPSCUserInfoKeyTag, [NSNumber numberWithInteger:-1], kMPSCUserInfoKeyBytes, nil];
            
            // raise notification with tag
            //
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_SOCKETCENTER_WRITE_PROGRESS_NOTIFICATION   object:nil userInfo:userInfoD];
        });
    }
}


/*!
 @abstract get read timeout occurred - what to do next?
 
 @discussion usually from waiting for login response
 
 */
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length{
    
    DDLogError(@"SC: read timeout tag:%ld", tag);
    [self disconnect];
    
    // let it timeout
    return 0.0;
}

/*!
 @abstract writing an important message timed out
 
 @discussion usually if connection is not available
 
 */
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length {
    
    // do nothing for now, timeout is done at MC level
    //
    /*dispatch_async(dispatch_get_main_queue(), ^{
    
        // raise notification with tag
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_SOCKETCENTER_WRITE_TIMEOUT_NOTIFICATION object:[NSNumber numberWithLong:tag]];
    });*/
    
    DDLogError(@"SC: write timeout tag:%ld", tag);
    
    // let it timeout
    return 0.0;
}



#pragma mark - Login Logout


/*!
 @abstract authenticate and login
 
 Try to login when app comes into foreground
 - starts on main queue
 
 */
- (void) startLoginTask:(NSNotification *)notification {
    
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"Must be dispatched on mainQueue");

    // in case old retries are running, stop them
    [self.retryLoginTimer invalidate];
    [self.waitLoginTimer invalidate];

    dispatch_queue_t netQueue = [AppUtility getQueueNetwork];    
    dispatch_async(netQueue, ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        [self resetRetrySeconds];
        
        // also reset so early message has a chance to be buffered if connection is slow to establish
        //
        self.lastConnectedDate = [NSDate date];

        [pool drain];
    });

    
    DDLogInfo(@"SC: Got Login Notifcation");
    [[MPHTTPCenter sharedMPHTTPCenter] authenticateAndLogin];
    
}


/*!
 @abstract Logout and disconnect
 
 Starts a background task so that we can logout without being suspended right away
 - starts on main queue
 
 */
- (void) startLogoutTask:(NSNotification *)notification {
    
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"Must be dispatched on mainQueue");
    
    // cancel retries since we are logging out now!
    //
    [self.retryLoginTimer invalidate];
    [self.waitLoginTimer invalidate];
    dispatch_queue_t netQueue = [AppUtility getQueueNetwork];    
    dispatch_async(netQueue, ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        [self resetRetrySeconds];
        
        [pool drain];
    });
    
    
    // reset badge count to correct number
    // ** old unread count
    //[[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[MPChatManager sharedMPChatManager] totalUnreadMessagesUseCache:NO]];
    // ** new alway reset to 0
    // perform instead when launching or entering foreground, since doing it here is not as reliable
    
    if ([self isConnected]) {
        // if multi-tasking, run in background
        if ([Utility isMultitaskSupported]){
            DDLogInfo(@"SC-slt: starting logout task");
            // Register to execute task in background if required
            UIApplication *app = [UIApplication sharedApplication];
            
            self.logoutBGTask= [app beginBackgroundTaskWithExpirationHandler:^{
                [app endBackgroundTask:self.logoutBGTask];
                self.logoutBGTask = UIBackgroundTaskInvalid;
            }];
            
            // send logout to server
            [self logoutAndDisconnect];
            
            
            // just wait for accept from logout, then we should end task there!
            // - keep this time short, in case user tries to come back to app right away
            [NSThread sleepForTimeInterval:0.5];
            
            
            // make sure we are still logging out and user did not re-enter app again
            // - then it is ok to disconnect
            //
            if (self.loginState == kSCStateLoggingOut) {
                DDLogInfo(@"SC-slt: BK Task TimeOUT!!");
                
                if ([self isConnected]) {
                    [self disconnect];
                }
                else {
                    DDLogWarn(@"SC-slt: don't disCNT since not CNT already");
                }
                
                if (self.logoutBGTask != UIBackgroundTaskInvalid) {
                    // tell app that we are done!
                    [app endBackgroundTask:self.logoutBGTask];
                    self.logoutBGTask = UIBackgroundTaskInvalid;
                }
            }
        }
        // if not try do in main 
        else {
            DDLogWarn(@"SC-slt: not multi-task, so logout immediately");
            // send logout to server
            [self logoutAndDisconnect];
        }
    }
    
}



#pragma mark - Message Handling


/*!
 @abstract handles message related to this object
 */
- (void) processMessage:(MPMessage *)newMessage {
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");
    
    // if login was accepted - successful!
    /*
     Example:
     
     @accept?id=2012022100000141000123&cause=0&fromaddr=192.168.1.120&operator=&resourcetime=1329723753000&appversion=1.3.3&command=,deleteM,SMS30&text=您目前還有30封免費簡訊額度…
     
     */
    if ([newMessage.mType isEqualToString:kMPMessageTypeAccept]) {
        
        // from address - get from DS
        NSString *domainIP = [newMessage valueForProperty:kMPMessageKeyFromAddress];
        
        // accept login
        if ([domainIP length] > 0) {
            
            self.loginState = kSCStateLoggedIn;
            // check if we need to run phone sync
            //
            // look for queryM command
            NSString *command = [newMessage valueForProperty:kMPMessageKeyCommand];
            NSArray *commands = [command componentsSeparatedByString:@","];
            // we should start phonebook sync then
            if ([commands containsObject:@"queryM"]) {
                DDLogInfo(@"SC-hm: GOT queryM! - try phone sync");
                [MPContactManager tryStartingPhoneBookSyncForceStart:YES delayed:NO];
            }
            
            // save free SMS number
            for (NSString *iCommand in commands) {
                if ([iCommand hasPrefix:@"SMS"]) {
                    if ([iCommand length] > 3) {
                        NSInteger smsInt = [[iCommand substringFromIndex:3] integerValue];
                        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingFreeSMSLeftNumber settingValue:[NSNumber numberWithInt:smsInt]];
                    }
                }
            }

            
            // for TESTING
            //
            //[[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingGetResourceLastUpateTime settingValue:@"1000"];
            
            // do we need to update resource information?
            //
            NSString *lastUpdateTime = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingGetResourceLastUpateTime];
            
            NSString *resourceTime = [newMessage valueForProperty:@"resourcetime"];
            if ([resourceTime compare:lastUpdateTime] == NSOrderedDescending) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[MPHTTPCenter sharedMPHTTPCenter] getResourceDownloadInfo];
                });
            }
            
            // save latest version
            NSString *latestAppVersion = [newMessage valueForProperty:kMPMessageKeyAppVersion];
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingLatestAppVersion settingValue:latestAppVersion];

            BOOL isUpToDate = [[MPSettingCenter sharedMPSettingCenter] isAppUpToDate];
            if (isUpToDate) {
                [AppUtility setBadgeCount:0 stringCount:nil controllerIndex:kMPTabIndexSetting];
            }
            else {
                // @TEMP - disable update for now
                [AppUtility setBadgeCount:0 stringCount:NSLocalizedString(@"N", "Settings - text: new update is available") controllerIndex:kMPTabIndexSetting];
            }
            
            // save the internal IP of the actual domain server used
            //
            DDLogInfo(@"SC-hm: LOGIN SUCCESS");
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingDomainServerName settingValue:domainIP];
            
            
            // inform others that we have logged in
            // - chat dialog status needs this
            //
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:MP_SOCKETCENTER_CONNECT_SUCCESS_NOTIFICATION object:nil];
                
                // also call helper API if needed
                // - also calls friend suggestion
                //
                [[MPHTTPCenter sharedMPHTTPCenter] sendHelperMessage];
                
                // try to register push notification
                //
                BOOL popOn = [[[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPushPopUpIsOn] boolValue];
                [[AppUtility getAppDelegate] tryRegisterPushNotificationForceStart:NO enableAlertPopup:popOn];
            });
            
            
            // also update the my CDContact
            dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
            
            // update DB stuff in back queue
            //
            dispatch_async(backQueue, ^{
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                
                [CDContact updateMyNickname:nil domainClusterName:nil domainServerName:domainIP statusMessage:nil];
                [[AppUtility getAppDelegate] sharedCacheSetObject:@"" forKey:@"myMplusAddress"];
                
                [pool drain];
            });
            
            // send out outstanding read and delivered messages
            [MPChatManager sendOutstandingMPMessages];
            
            // reset timer to initial state
            //
            [self resetRetrySeconds];
            
            // start checking if connection is idle
            [self startKeepIdleTimer];
            
        }
        // accept logout
        else {
            self.loginState = kSCStateLoggedOut;
            
            DDLogInfo(@"SC-hm: LOGOUT ACCEPTED");
            // stop logout task
            if ([Utility isMultitaskSupported]){
                
                if ([self isConnected]) {
                    [self disconnect];
                }
                else {
                    DDLogInfo(@"SC-hm: already disCNT, don't disCNT");
                }
                if (self.logoutBGTask != UIBackgroundTaskInvalid) {
                    UIApplication *app = [UIApplication sharedApplication];
                    [app endBackgroundTask:self.logoutBGTask];
                    self.logoutBGTask = UIBackgroundTaskInvalid;
                }
            }
        }
    }
    // handle login rejection
    else if ([newMessage.mType isEqualToString:kMPMessageTypeReject]) {
        
        // ignore if already logged in and connected
        // - this must be a reject message from a different session
        // 
        if ([self isLoggedIn]) {
            DDLogWarn(@"SC-hm: Ignore LOGIN REJECT - already loggedin");
            return;
        }
        
        self.loginState = kSCStateLoggedOut;

        DDLogInfo(@"SC-hm: LOGIN REJECTED");
        
        // if cause == 603 (invalid aKey), then
        // - reset aKey
        // - get new akey again (authenticate)
        //
        MPCauseType cause = [[newMessage valueForProperty:kMPMessageKeyCause] intValue];
        if (cause == kMPCauseTypeInvalidAKey) {
            // debug
            DDLogWarn(@"SC-hm: LOGIN-Invalid AKEY");
            [[MPSettingCenter sharedMPSettingCenter] setSecureValueForID:kMPSettingAuthKey settingValue:@""];
        }
        else if (cause == kMPCauseTypeForceUpdate) {
            DDLogInfo(@"SC-hm: LOGIN-force update requested by server");
            NSString* serverText = [newMessage valueForProperty:kMPMessageKeyText];
            dispatch_async(dispatch_get_main_queue(), ^{
                // show force update if needed
                [AppUtility showAppUpdateView:serverText];
            });
        }
        
        // what to do next?? - retry?
        // - do this at the nsstream end event section - 
        [self handleLoginFailure:cause];
    }
}

/*!
 @abstract handles message related to this object
 
 Thread safe, can be called from any thread
 */
- (void) handleMessage:(MPMessage *)newMessage {
    
    //NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");
    
    if (dispatch_get_current_queue() != [AppUtility getQueueNetwork]) {
        
        dispatch_queue_t netQueue = [AppUtility getQueueNetwork];
        
        // protect attributes in netQueue
        //
        dispatch_async(netQueue, ^{
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            [self processMessage:newMessage];
            
            [pool drain];
        });
        
    }
    else {
        [self processMessage:newMessage];
    }
}

@end

