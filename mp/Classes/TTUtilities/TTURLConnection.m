//
//  TTURLConnection.m
//  mp
//
//  Created by M Tsai on 11-8-30.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "TTURLConnection.h"
#import "TKLog.h"


const CGFloat kTimeOutInterval = 20.0;


@implementation TTURLConnection

@synthesize delegate;
@synthesize urlRequest;
@synthesize urlConnection;

@synthesize expectedContentLength;
@synthesize receivedData;
@synthesize typeTag;
@synthesize idTag;
@synthesize responseFormat;


- (void) dealloc{
    self.delegate = nil;
    [urlRequest release];
    [urlConnection release];
    [receivedData release];
    [typeTag release];
    [idTag release];
    [super dealloc];
}

/*! 
 @abstract Initialize the TTURLConnection by setting up request
 @discussion Creates a URL Request object with the specified URL string.
 
 @param urlString target URL to connect to
 @param is this a POST request, NO for default (GET)
 
 @param instead urlString, directly use NSURL provided - only GET is available for NSURL
 
 */
- (id) initWithURLString:(NSString *)urlString isPost:(BOOL)isPost nsurl:(NSURL *)nsurl
{
	self = [super init];
	if (self != nil)
	{
        // escape special characters to create a valid URI
        // - DON'T percent encode the entire URI - try encoding only parts that need it (those with reserved chars)
        //
        //NSString *escapedString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];        
        //DDLogVerbose(@"UC-init: escaped url - %@", escapedString);
        
        
        DDLogInfo(@"UC-init: %@ url - %@", isPost?@"POST":@"GET", urlString);
        
        NSURL *requestURL = nil;
        
        if (urlString) {
            requestURL = [NSURL URLWithString:urlString];
        }
        
        if (nsurl) {
            requestURL = nsurl;
        }
        
        
        // use POST method must provide urlString
        if (isPost && urlString) {
            
            NSArray *urlParts = [urlString componentsSeparatedByString:@"?"];
            
            if ([urlParts count] == 2) {
                NSURL *postURL = [NSURL URLWithString:[urlParts objectAtIndex:0]];
                NSMutableURLRequest *postRequest = [NSMutableURLRequest 
                                                    requestWithURL:postURL];
                
                NSString *params = [urlParts objectAtIndex:1];
                [postRequest setHTTPMethod:@"POST"];
                [postRequest setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
                
                self.urlRequest = postRequest;
            }
            else {
                DDLogWarn(@"UC-init: invalid URL (missing '?') %@", urlString);
            }
        }
        // use GET
        else {
            NSURLRequest *getRequest=[NSURLRequest requestWithURL:requestURL
                                                   cachePolicy:NSURLRequestUseProtocolCachePolicy
                                               timeoutInterval:kTimeOutInterval];
            self.urlRequest = getRequest;
        }
        
        // default XML
        self.responseFormat = TTURLResponseFormatXML;
        
        self.expectedContentLength = 0;
	}
	return self;
}

- (id) initWithURLString:(NSString *)urlString isPost:(BOOL)isPost {
    return [self initWithURLString:urlString isPost:isPost nsurl:nil];
}

- (id) initWithURLString:(NSString *)urlString {
    return [self initWithURLString:urlString isPost:NO];
}

/*! 
 @abstract Creates and starts the URL connection
 @discussion Creates the URL connection and allocates data object to receive data
 
 Usage: Call this method when client is ready connect to the URL.
 
 */
- (void) connect {
    
    self.expectedContentLength = 0;
    
    // create the connection with the request
    // and start loading the data
    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:self.urlRequest delegate:self startImmediately:YES];
    self.urlConnection = theConnection;
    [theConnection release];
    
    if (self.urlConnection) {
        // Create the NSMutableData to hold the received data.
        // receivedData is an instance variable declared elsewhere.
        self.receivedData = [NSMutableData data];
        [self.urlConnection start];
    } else {
        // Inform the user that the connection failed.
        DDLogWarn(@"UC-connect: connection failed");
    }
    
}

#pragma mark - Delegate Methods

/*! 
 @abstract Delegate called when a redirect is encountered
 @discussion We can intercept a redirect here.
  
 */
-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)redirectResponse
{
    return request;
}


/*! 
 @abstract Delegate called when response is received
 @discussion Called when client has enough information to create URL Response.
 This can occur for redirects and less frequently for multipart
 MIME messages.
 
 The client should reset all progress indication and discard all previously received data.

 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // This method is called when the server has determined that it
    // has enough information to create the NSURLResponse.
    
    // It can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
    
    // receivedData is an instance variable declared elsewhere.
    [self.receivedData setLength:0];
    
    self.expectedContentLength = response.expectedContentLength;
}


/*! 
 @abstract Delegate called when data is received
 @discussion Called when client has received some data.
 
 Append new data to the receivedData attribute.
  
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    
    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
    [self.receivedData appendData:data];

    // call TTURLConnectionDelegate to update progress
    //
	if ([self.delegate respondsToSelector:@selector(TTURLConnection:bytesDownloaded:expectedContentLength:)]) {
		[self.delegate TTURLConnection:self bytesDownloaded:[self.receivedData length] expectedContentLength:self.expectedContentLength];
	}
    
}

/*! 
 @abstract Delegate called when error has occurred
 @discussion Handles connection error.  No further delegate calls will be made 
 for this connection. So reset connection and received data.
  
 */
- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    self.urlConnection = nil;
    // receivedData is declared as a method instance elsewhere
    self.receivedData = nil;
    
    // inform the user
    DDLogError(@"NSURL Connection failed! %@ Error - %@ %@", connection,
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);

    
    // call delegate method to inform of error
    //
    if ([self.delegate respondsToSelector:@selector(TTURLConnection:didFailWithError:)]) {
        [self.delegate TTURLConnection:self didFailWithError:error];
    }
}

/*! 
 @abstract Delegate called when loading completes
 @discussion Handles the complete data after loading completes.  No further
 messages will be sent to the delegates, so reset the connection and receivedData.
  
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    DDLogInfo(@"UC-cdfl: Succeeded! Received %d bytes of data",[receivedData length]);
    
    // call TTURLConnectionDelegate to inform that the content was retrieved
    //
	if ([self.delegate respondsToSelector:@selector(TTURLConnection:finishLoadingWithData:)]) {
		[self.delegate TTURLConnection:self finishLoadingWithData:self.receivedData];
	}
    
    // release the connection, and the data object
    self.delegate = nil;
    self.urlConnection = nil;
    self.receivedData = nil;
    
}

/*
 @abstract Are we able to authenticate against the security requirements of this server?
 */
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return [protectionSpace.authenticationMethod
			isEqualToString:NSURLAuthenticationMethodServerTrust];
}


/*!
 @abstract respond to authentication challenges
 */

-(void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge previousFailureCount] == 0) {
        
        OSStatus                err;
        SecCertificateRef       mpCert;
        
        NSString *certPath = [[NSBundle mainBundle]
                              pathForResource:@"mplus" ofType:@"der"];
        NSData *derData = [[NSData alloc] initWithContentsOfFile:certPath];
        mpCert = SecCertificateCreateWithData(NULL, (CFDataRef) derData);
        if (derData != NULL) {
            CFRelease(derData);
        }
        
        NSURLCredential *credential = nil;
        NSURLProtectionSpace *protectionSpace;
        SecTrustRef trust;
        //int err;
        
        // Setup
        protectionSpace = [challenge protectionSpace];
        trust = [protectionSpace serverTrust];
        credential = [NSURLCredential credentialForTrust:trust];
        
        // Set up the array of certs we will authenticate against and create cred 
        //
        NSArray * certs = [[NSArray alloc] initWithObjects:(id)mpCert,nil];
        // seems like duplicate -- credential = [NSURLCredential credentialForTrust:trust];
        if (mpCert != NULL) {
            CFRelease(mpCert);
        }
        
        // Build up the trust anchor using our root cert 
        //
        err = SecTrustSetAnchorCertificates(trust, (CFArrayRef) certs);
        SecTrustResultType trustResult = 0;
        if (err == noErr) {
            err = SecTrustEvaluate(trust, &trustResult);
        }
        
        [certs release];
        
        
        BOOL trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified));
        
        
        // Return based on whether we decided to trust or not
        // @TEMP disable for now
        // - Add back when the new certificate with the correct extensions are added
        //
        if (YES /*trusted*/)
            [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        else {
            NSLog(@"Trust evaluation failed for service root certificate");
            
            [[challenge sender] cancelAuthenticationChallenge:challenge];
        }
        
        
        //NSURLCredential *proposed = [challenge proposedCredential];
        
        /*NSURLProtectionSpace *space = [challenge protectionSpace];
        NSURLCredential *storedCredential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:space];
        
        [[challenge sender] useCredential:storedCredential forAuthenticationChallenge:challenge];
         */
    } 
    else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        // inform the user that the user name and password
        // in the preferences are incorrect
        //[self showPreferencesCredentialsAreIncorrectPanel:self];
    }
}


@end
