//
//  TKFileCenter.h
//  mp
//
//  Created by M Tsai on 11-10-4.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTURLConnection.h"


/*!
 State of the URL connection
 
 Idle           no network activity
 Downloading    connected and downloading
 
 */
typedef enum {
    kTKFMStateIdle,
    kTKFMStateDownloading
} TKFMState;



/*!
 @header TKFileManager
 
 Helps app download and cache file locally
 
 Usage:
 Create one FileManager each time you need to download a file.
 
 FileManager will download the file in a background thread.
 
 To get information about the download progress set the delegate to the object that
 is interested in this information.  This is typically a view controller that is 
 responsible for displaying the download progress or displaying the file contents.
 
 Filename Format:
 
 <messageID>.png        Attachment use messageID as their names with file type as the suffix
 pre_<filename>         Preview file names are prefixed with "pre_" string
 <userID>_headshot.png  Headshot for userID
 
 
 @copyright TernTek
 @updated 2011-10-04
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */
@class TKFileManager;




/*!
 Delegate that can be notified when TTURLConnection is finished or has
 encountered an error.
 
 */
@protocol TKFileManagerDelegate <NSObject>

@optional

/*!
 @abstract Called when data has completed loading and is ready to use.
 */
- (void)TKFileManager:(TKFileManager *)fileManager finishLoadingWithData:(NSData *)data;


/*!
 @abstract Called regularly when data is regularly downloaded
 
 */
- (void)TKFileManager:(TKFileManager *)fileManager bytesDownloaded:(NSUInteger)bytes expectedContentLength:(NSUInteger)expectedContentLengthBytes;

/*! 
 @abstract Delegate called when error has occurred
 @discussion Handles connection error.  No further delegate calls will be made 
 for this connection. So reset connection and received data.
 */
- (void)TKFileManager:(TKFileManager *)fileManager didFailWithError:(NSError *)error;


/*!
 @abstract Passes download data and filename as an ID tag
 */
- (void)TKFileManager:(TKFileManager *)fileManager finishLoadingWithData:(NSData *)data filename:(NSString *)filename;

/*! 
 @abstract Got error and passes filename as an ID tag
 */
- (void)TKFileManager:(TKFileManager *)fileManager didFailWithError:(NSError *)error filename:(NSString *)filename;

@end





@interface TKFileManager : NSObject <TTURLConnectionDelegate> {
    
    id <TKFileManagerDelegate> delegate;
    dispatch_queue_t background_queue;
    TTURLConnection *urlConnection;
    NSString *tempFilename;
    
    NSSearchPathDirectory baseDirectory;
    NSString *specifiedDirectory;
    TKFMState state;
    
    NSMutableArray *downloadQueue;

}

/*! delegate that gets called when content finishes loading */
@property (nonatomic, assign) id <TKFileManagerDelegate> delegate;

@property (readonly, assign) dispatch_queue_t background_queue;
@property (nonatomic, retain) TTURLConnection *urlConnection;

/*! the path we should save to for the cache once download is complete */
@property (nonatomic, retain) NSString *tempFilename;

/*! base parent directory - depends on backup policy for files */
@property (nonatomic, assign) NSSearchPathDirectory baseDirectory;

/*! optional directory to save files in, otherwise use default */
@property (nonatomic, retain) NSString *specifiedDirectory;

/*! is downloading data now? */
@property (nonatomic, assign) TKFMState state;

/*! queues download requests */
@property (nonatomic, retain) NSMutableArray *downloadQueue;



- (id)initWithDirectory:(NSString *)directoryName;

- (BOOL) isDownloading;
- (void) clearDownloadQueue;

- (BOOL) createSymbolicLink:(NSString *)newSymFilename destinationFilename:(NSString *)destinationFilename;
- (BOOL) doesDataExistforFilename:(NSString *)filename;
- (BOOL) setFileData:(NSData *)fileData forFilename:(NSString *)filename;
- (void) deleteFilename:(NSString *)filename deletePreivew:(BOOL)deletePreview;

- (void) downloadFilename:(NSString *)filename url:(NSString *)urlString isPost:(BOOL)isPost;
- (NSData *) getFileDataForFilename:(NSString *)filename url:(NSString *)urlString;
- (UIImage *) getImageForFilename:(NSString *)filename;

- (BOOL) setPreviewData:(NSData *)previewData forFilename:(NSString *)filename;
- (UIImage *) getPreviewImageForFilename:(NSString *)filename;

@end
