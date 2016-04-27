//
//  MPImageManager.h
//  mp
//
//  Created by M Tsai on 11-12-10.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//



//
//  TKFileCenter.h
//  mp
//
//  Created by M Tsai on 11-10-4.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKFileManager.h"

extern NSString* const kMPImageContextList;      // for list view headshots
extern NSString* const kMPImageContextDialog;    // for dialog previews

/*!
 @header MPImageManager
 
 Helps MP access & download images 
 
 Usage:
 Create one ImageManager for each image you need to download.
 
 IM will take care of caching, version control and tagging of images
 
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
@class MPImageManager;


/*!
 Delegate that can be notified when TTURLConnection is finished or has
 encountered an error.
 
 */
@protocol MPImageManagerDelegate <NSObject>

/*!
 @abstract Called when data has completed loading and is ready to use.
 
 */
- (void)MPImageManager:(MPImageManager *)imageManager finishLoadingImage:(UIImage *)image;

@optional

/*!
 @abstract Inform delegate that we started downloading image
 
 */
- (void)MPImageManager:(MPImageManager *)imageManager didStartImageDownload:(NSString *)url;

/*!
 @abstract Called regularly when data is regularly downloaded
 
 */
- (void)MPImageManager:(MPImageManager *)imageManager bytesDownloaded:(NSUInteger)bytes expectedContentLength:(NSUInteger)expectedContentLengthBytes;

/*! 
 @abstract Delegate called when error has occurred
 @discussion Handles connection error.  No further delegate calls will be made 
 for this connection. So reset connection and received data.
 */
- (void)MPImageManager:(MPImageManager *)imageManager didFailWithError:(NSError *)error;

@end



@interface MPImageManager : NSObject <TKFileManagerDelegate> {
    
    id <MPImageManagerDelegate> delegate;
    //dispatch_queue_t background_queue;
    TKFileManager *fileManager;
    
    NSString *imageName;
    NSString *version;
    NSString *context;
    NSString *url;
    
}

/*! delegate that gets called when content finishes loading */
@property (nonatomic, assign) id <MPImageManagerDelegate> delegate;
//@property (readonly, assign) dispatch_queue_t background_queue;
@property (nonatomic, retain) TKFileManager *fileManager;
@property (nonatomic, retain) NSString *imageName;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSString *context;
@property (nonatomic, retain) NSString *url;

- (UIImage *) getImageForObject:(id)object context:(NSString *)displayContext ignoreVersion:(BOOL)ignoreVersion;
- (UIImage *) getImageForObject:(id)object context:(NSString *)displayContext;

- (UIImage *) getImageForFilename:(NSString *)filename context:(NSString *)displayContext;

- (void) setImage:(UIImage *)image forFilename:(NSString *)filename context:(NSString *)displayContext version:(NSString *)newVersion;
- (void) setImage:(UIImage *)image forFilename:(NSString *)filename context:(NSString *)displayContext;

//- (BOOL) doesDataExistforFilename:(NSString *)filename;



//- (BOOL) setPreviewData:(NSData *)previewData forFilename:(NSString *)filename;
//- (UIImage *) getPreviewImageForFilename:(NSString *)filename;
@end
