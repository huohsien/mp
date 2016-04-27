//
//  MPSocketCenter.h
//  mp
//
//  Created by M Tsai on 11-12-18.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

/*!
 @header MPSocketCenter
 
 MPSocketCenter provides access and control over TCP networking.
 
 
 @copyright TernTek
 @updated 2011-08-30
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <Foundation/Foundation.h>
#import "TKLog.h"



/*!
 @abstract Identifies login state
 
 kSCStateLoggingIn      1. Setting up login tasks - 
 kSCStateWaitLogin      2. Waiting for login response - sent login request and waiting
 kSCStateLoggedIn       3. Successfully logged in - got accept from DS
 
 kSCStateLoggingOut     1. Setting up logout tasks - preparing to log out
 kSCStateLoggedOut      2. Successfully logged out - got accept from DS, also initial state at launch
 
 */
typedef enum {
    kSCStateLoggingIn,
    kSCStateWaitLogin,
    kSCStateLoggedIn,
    kSCStateLoggingOut,
    kSCStateLoggedOut
} SCLoginState;


/*! write timed out - notif object is tag used to ID write operation */
extern NSString* const MP_SOCKETCENTER_WRITE_TIMEOUT_NOTIFICATION;

/*! when write progress is received - userInfo kMPSCUserInfoKeyTag and kMPSCUserInfoKeyBytes keys */
extern NSString* const MP_SOCKETCENTER_WRITE_PROGRESS_NOTIFICATION;

/*! just lost network */
extern NSString* const MP_SOCKETCENTER_NETWORK_NOTREACHABLE_NOTIFICATION;

/*! trying to connect now */
extern NSString* const MP_SOCKETCENTER_CONNECT_TRY_NOTIFICATION;

/*! connected successfully */
extern NSString* const MP_SOCKETCENTER_CONNECT_SUCCESS_NOTIFICATION;


/*
 @abstract When disconnect encountered
 - Should stop and clear all registered messages, since disconnect encountered
 - Pending timeouts should be cancelled as well
 */
NSString* const MP_SOCKETCENTER_DISCONNECT_LOGIN_NOTIFICATION;

/* regular disconnect but not may not have been logged in previously */
NSString* const MP_SOCKETCENTER_DISCONNECT_NOTIFICATION;


extern NSString* const kMPSCUserInfoKeyTag;
extern NSString* const kMPSCUserInfoKeyBytes;


@class GCDAsyncSocket;
@class MPMessage;
@class Reachability;

@interface MPSocketCenter : NSObject <NSStreamDelegate> {
    
    
    GCDAsyncSocket *asyncSocket; // socket object used for communication 
    
    Reachability* domainClusterReachable;
    BOOL isDomainClusterActive;
    CGFloat retrySeconds;
    NSTimer *retryLoginTimer;
    BOOL disableRetry;
    NSTimer *waitLoginTimer;

    // keepalive
    NSTimer *keepTimer;
    NSDate *keepLastReadDate;
    BOOL keepDidExtendLastReadDate;
    
    // login
    SCLoginState loginState;
    NSString *lastLoginMessageID;
    UIBackgroundTaskIdentifier logoutBGTask;
    
    // data scrambling
    NSData *encodedHeader;
    
    // disconnect
    NSDate *lastConnectedDate;
    
}

/*! @abstract helps track if network is reachable */
@property (nonatomic, retain) Reachability* domainClusterReachable;

/*! @abstract indicates if internet is currently available */
@property (assign) BOOL isDomainClusterActive;

/*! 
 @abstract retry seconds - when should we try reconnecting again
 @discussion this increases by 2x after each retry.
 - should reset whenever a successful connection occurs or when app becomes active
 */
@property (assign) CGFloat retrySeconds;

/*! @abstract timer to try login again */
@property (nonatomic, retain) NSTimer *retryLoginTimer;

/*! 
 @abstract Set to YES to prevent retry from occuring
 
 */
@property (assign) BOOL disableRetry;


/*! @abstract timeout for waiting for login to finish */
@property (nonatomic, retain) NSTimer *waitLoginTimer;


/*! @abstract are we trying to logout now - don't retry login then */
@property (assign) SCLoginState loginState;

/*! @abstract mID of the last login message - double check if timeout belongs to this login */
@property (nonatomic, retain) NSString *lastLoginMessageID;

/*! @abstract logout bgTask ID */
@property (assign) UIBackgroundTaskIdentifier logoutBGTask;


/*! @abstract timer used for keep alive - test for idle timeout */
@property (nonatomic, retain) NSTimer *keepTimer;

/*! @abstract last date which we read some thing - determine idle timeout */
@property (nonatomic, retain) NSDate *keepLastReadDate;

/*! 
 @abstract allow large writes to extend the last read date once 
 - since that write will block pings&acks and cause false positives 
 */
@property (nonatomic, assign) BOOL keepDidExtendLastReadDate;

// data scrambling

/*! 
 @abstract Save header to help decode message body later 
 */
@property (nonatomic, retain) NSData *encodedHeader;

/*! @abstract time that we last were logged and connected - when disconnect occured or app enter foreground */
@property (nonatomic, retain) NSDate *lastConnectedDate;


// query
- (BOOL) isConnected;
- (BOOL) isLoggedIn;
- (NSString *) connectionStatus; // testing
- (BOOL) isNetworkReachable;
- (BOOL) isDisconnectFresh;

// action
- (void) disconnect; // public for testing
- (void) setDomainClusterName:(NSString *)hostname;   // when cluster name changes


/*!
 @abstract Setup connection to domain servers
 
 - check if connections are available
 ~ if not connect
 - check if logged in
 ~ if not login
 
 */
- (void) setupDomainConnectionAndLogin;

- (void) loginAndConnect;

/*!
 @abstract Logout and disconnect
 */
- (void) logoutAndDisconnect;
- (void) shutdownRetry;
- (void) startupRetry;
- (void) resetRetry;

/*!
 @abstract add data to write queue to send over the domain server connection
 */
- (void) addDataToWriteQueue:(NSData *)newData;
- (void) addDataToWriteQueue:(NSData *)newData timeout:(NSTimeInterval)timeout tag:(long)tag;


/*!
 @abstract handles message related to this object
 */
- (void) handleMessage:(MPMessage *)newMessage;


- (void) sendPing;

@end
