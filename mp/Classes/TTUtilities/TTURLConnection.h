//
//  TTURLConnection.h
//  mp
//
//  Created by M Tsai on 11-8-30.
//  Copyright 2011年 TernTek. All rights reserved.
//


/*!
 @header TTURLConnection
 
 TTURLConnection takes a URL and downloads the content to memory as NSData.
 
 This is essentially a wrapper for NSURLRequest and NSURLConnection.  This
 wrapper just helps make it simpler to download content for typical URL requests
 by reducing settings and delegates methods needed.
 
 For more connections that require more customization, use NSURLRequest and
 NSURLConnection directly.
 
 Note:
 Don't call this in any background threads.  This is already async and should not block.
 - If you do want to call this in background thread, then you need to run NRURLConnection synchronously
 NSError *error;
 NSURLResponse *response;
 NSData *connectionData = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&response error:&error];
 - But we don't do this, so don't run in background thread!!
 
 Example:
 
 
 // create connection
 TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString];
 newConnection.delegate = self;
 newConnection.responseFormat = TTURLResponseFormatJSON;  // specify how to parse the response
 
 // start request
 [newConnection connect];           

 // then create write delegates to handle returned message

 
 
 @copyright TernTek
 @updated 2011-08-30
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <Foundation/Foundation.h>


/*!
 @abstract Response format coming back from URL request
 
 - Default should be XML
 
 */
typedef enum {
    TTURLResponseFormatXML = 0,
	TTURLResponseFormatJSON = 1
} TTURLResponseFormat;



@class TTURLConnection;

/*!
 Delegate that can be notified when TTURLConnection is finished or has
 encountered an error.
 
 */
@protocol TTURLConnectionDelegate <NSObject>

/*!
 @abstract Called when data has completed loading and is ready to use.
 
 */
- (void)TTURLConnection:(TTURLConnection *)urlConnection finishLoadingWithData:(NSData *)data;

@optional

/*! 
 @abstract Delegate called when error has occurred
 @discussion Handles connection error.  No further delegate calls will be made 
 for this connection. So reset connection and received data.
 
 */
- (void)TTURLConnection:(TTURLConnection *)connection didFailWithError:(NSError *)error;

/*!
 @abstract Called regularly when data is regularly downloaded
 
 */
- (void)TTURLConnection:(TTURLConnection *)urlConnection bytesDownloaded:(NSUInteger)bytes expectedContentLength:(NSUInteger)expectedContentLengthBytes;

@end

/*!
 
 */
@interface TTURLConnection : NSObject {
    
    id <TTURLConnectionDelegate> delegate;
    
    NSURLRequest *urlRequest;
    NSURLConnection *urlConnection;

    NSUInteger expectedContentLength;
    NSMutableData *receivedData;
    
    NSString *typeTag;
    NSString *idTag;

    TTURLResponseFormat responseFormat;
}

/*! delegate that gets called when content finishes loading */
@property (nonatomic, assign) id <TTURLConnectionDelegate> delegate;

/*! reference to NSURLRequest */
@property (nonatomic, retain) NSURLRequest *urlRequest;
/*! reference to NRURLConnection */
@property (nonatomic, retain) NSURLConnection *urlConnection;

/*! The expected length of the response received - to help update download progress */
@property (nonatomic, assign) NSUInteger expectedContentLength;

/*! memory storage to append data as it is read in */
@property (nonatomic, retain) NSMutableData *receivedData;

/*! tag to identify what type of query this is & how we should handle the results */
@property (nonatomic, retain) NSString *typeTag;

/*! tag to identify who requested and who should handle this query */
@property (nonatomic, retain) NSString *idTag;

/*! expected response format - determine how to parse response */
@property (nonatomic, assign) TTURLResponseFormat responseFormat;


/*! 
 @abstract Initialize the TTURLConnection by setting up request
 @discussion Creates a URL Request object with the specified URL string.
 
 @param urlString target URL to connect to
 */
- (id) initWithURLString:(NSString *)urlString;
- (id) initWithURLString:(NSString *)urlString isPost:(BOOL)isPost;
- (id) initWithURLString:(NSString *)urlString isPost:(BOOL)isPost nsurl:(NSURL *)nsurl;

/*! 
 @abstract Creates and starts the URL connection
 @discussion Creates the URL connection and allocates data object to receive data
 
 Usage: Call this method when client is ready connect to the URL.
 
 */
- (void) connect;


@end



