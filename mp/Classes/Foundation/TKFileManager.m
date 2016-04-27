//
//  TKFileCenter.m
//  mp
//
//  Created by M Tsai on 11-10-4.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "TKFileManager.h"
#import "ZipArchive.h" 
#import "AppUtility.h"
#import "TKLog.h"




NSString* const kFileDirectory=@"filecenter";
NSString* const kTKQueueBackgroundFileManager = @"com.terntek.mp.background_filemanager";


@interface TKFileManager (PrivateMethods)
- (void) initFileDirectory;
@end

/*!
 
 This class provides basic file access and download functionality:
 - downloads a file if not available, then saves a local copy
 
 */
@implementation TKFileManager

@synthesize delegate;
@synthesize urlConnection;
@synthesize tempFilename;

@synthesize baseDirectory;
@synthesize specifiedDirectory;
@synthesize state;
@synthesize downloadQueue;

- (void) dealloc {
    
    urlConnection.delegate = nil;
    
    if (background_queue != NULL) {
        dispatch_release(background_queue);
    }
    
    urlConnection.delegate = nil;
    [urlConnection release];
    [tempFilename release];
    [specifiedDirectory release];
    [downloadQueue release];
    
    [super dealloc];
}



/*!
 @abstract init and specify the directory to save or get files from
 
 @param directoryName specify a different subdirectory to store file.
        - if defined, we assume these are support files that don't need to be backedup
        - so we use the caches directory instead of the backuped documents directory
 */
- (id)initWithDirectory:(NSString *)directoryName
{
	self = [super init];
	if (self != nil)
	{
        self.state = kTKFMStateIdle;
        
        if (directoryName) {
            self.baseDirectory = NSCachesDirectory;
        }
        else {
            self.baseDirectory = NSDocumentDirectory;
        }
        
        self.specifiedDirectory = directoryName;
        [self initFileDirectory];
        
        NSMutableArray *newArray = [[NSMutableArray alloc] init];
        self.downloadQueue = newArray;
        [newArray release];
        
	}
	return self;
}

/*!
 @abstract initialized cell controller with related CDMessage
 
 if CDMessage is not available, then this is an blank message where user 
 can write a new message.
 
 */
- (id)init
{
	return [self initWithDirectory:nil];
}





#pragma mark - Utility Methods


/*!
 @abstract getter for background MOC queue
 
 @discussion only execute background CD task here on this thread
 
 */
- (dispatch_queue_t) background_queue {
    
    // if does not exists
    // - create it
    if (background_queue == NULL){
        background_queue = dispatch_queue_create([kTKQueueBackgroundFileManager UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_retain(background_queue);
    }
    return background_queue;
}




/*!
 @abstract provides dictory that we should use for this FM
 - use specified directory if available
 
 */
- (NSString *) getDirectory {
    
    NSString *directory = nil;
    if ([self.specifiedDirectory length] > 0) {
        directory = self.specifiedDirectory;
    }
    else {
        directory = kFileDirectory;
    }
    return directory;
}

/*!
 @abstract Obtains and caches the directory path
 
 */
- (NSString *) getDirectoryPath
{
    NSString *directory = [self getDirectory];
    
    NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
    NSString *dPath = [dictionary objectForKey:directory];
    
    if (!dPath)
    {
        /* create path to cache directory inside the application's Documents directory */
        NSArray *paths = NSSearchPathForDirectoriesInDomains(self.baseDirectory, NSUserDomainMask, YES);
        dPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:directory];
        [dictionary setObject:dPath forKey:directory];
    }
    
    return dPath;
}


- (void) initFileDirectory
{
    NSNumber *directoryExists = [[AppUtility getAppDelegate] sharedCacheObjectForKey:[self getDirectory]];
    if ([directoryExists boolValue] == YES) {
        return;
    }
    
    NSString *dataPath = [self getDirectoryPath];
    
    /* check for existence of cache directory */
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        [[AppUtility getAppDelegate] sharedCacheSetObject:[NSNumber numberWithBool:YES] forKey:[self getDirectory]];
        return;
    }
    
    NSError *error;
    
    /* create a new cache directory */
    if (![[NSFileManager defaultManager] createDirectoryAtPath:dataPath
                                   withIntermediateDirectories:NO
                                                    attributes:nil
                                                         error:&error]) {
        //URLCacheAlertWithError(error);
        return;
    }
}


/*!
 @abstract gets document directory path to save files in
 
 Note:
 - if available saves to specifiedDirectory
 - otherwise use default kFileDirectory
 
 */
- (NSString *)documentFilePath:(NSString *)fileName {
    
    return [[self getDirectoryPath] stringByAppendingFormat:@"/%@", fileName];
    
	// mht: stringByAppendingPathComponent .. didn't work well on device for me.. may get fixed later
	//      use above for now since it is reliable
}

/*!
 @abstract creates the file path used by file center
 */
- (NSString *)pathForFilename:(NSString *)filename isPreview:(BOOL)isPreview {

    NSString *newFilename = nil;
    if (isPreview) {
        newFilename = [NSString stringWithFormat:@"pre_%@", filename];
    }
    else {
        newFilename = filename;
    }
    NSString *filePath = [self documentFilePath:newFilename];
    return filePath;
}


/*!
 @abstract Deletes file with given file name
 */
- (void) deleteFilename:(NSString *)filename deletePreivew:(BOOL)deletePreview {
	NSError *error = nil;
    NSString *path = [self pathForFilename:filename isPreview:NO];
	[[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    
    if (deletePreview) {
        NSString *path = [self pathForFilename:filename isPreview:YES];
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    }
}



#pragma mark - Query

/*!
 @abstract Is FM downloading a file now?
 
 Use:
 - lets us know if this FM is downloading - can be used to throttle connections
 
 */
- (BOOL) isDownloading {
    
    if (self.state == kTKFMStateDownloading) {
        return YES;
    }
    
    return NO;
}

#pragma mark - File Access Methods

/*!
 @abstract creates sym link for files managed by FM
 
 Use:
 - to create files that are not tagged, which are used as backups while the newest or desired
   files are being downloaded.
 */
- (BOOL) createSymbolicLink:(NSString *)newSymFilename destinationFilename:(NSString *)destinationFilename {
    
    NSString *symPath = [self pathForFilename:newSymFilename isPreview:NO];
    NSString *destPath = [self pathForFilename:destinationFilename isPreview:NO];
    
    // deletes old link or file!
    [[NSFileManager defaultManager] removeItemAtPath:symPath error:nil];
    
    // creates the link
    BOOL didSucceed = [[NSFileManager defaultManager] createSymbolicLinkAtPath:symPath withDestinationPath:destPath error:nil];
    
    return didSucceed;
}



/*!
 @abstract check if this file exists
 
 In case we just want to see if a file is available and don't want to download it
 
 @return YES if file is available
 */
- (BOOL) doesDataExistforFilename:(NSString *)filename {
    
    NSString *filePath = [self pathForFilename:filename isPreview:NO];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}


/*!
 @abstract saves file to FC
 
 @discussion 
 - The caller needs to make sure that filenames are unique otherwise they will be overwritten!
 - zip files will be automatically extracted and the zip will be deleted
 
 @return YES if operation succeeds, otherwise NO
 */
- (BOOL) setFileData:(NSData *)fileData forFilename:(NSString *)filename {
    
    NSString *filePath = [self pathForFilename:filename isPreview:NO];
    BOOL didSucceed = [fileData writeToFile:filePath atomically:YES];
    
    // unzip zip files
    //
    if ([filename hasSuffix:@".zip"]){
        ZipArchive* za = [[ZipArchive alloc] init];
        if( [za UnzipOpenFile:filePath] )
        {
            BOOL ret = [za UnzipFileTo:[self pathForFilename:@"" isPreview:NO] overWrite:YES];
            if( NO==ret )
            {
                // error handler here
                DDLogError(@"FM: unzip failed %@", filename);
                
                didSucceed = NO;
            }
            else {
                //NSString *debug = [NSString stringWithFormat:@"UNZIP Success %@", filename];
            }
            [za UnzipCloseFile];
        }
        else {
            DDLogWarn(@"FM: could not unzip %@", filename);
            didSucceed = NO;
        }
        [za release];
        
        // deletes zip file
        [self deleteFilename:filename deletePreivew:NO];
    }
    return didSucceed;
}


/*!
 @abstract downloads a file given URL
 
 @param filname what this file is called
 @param urlString where can we download it from if it does not exists, provide nil if don't want to download!
 @param isPost should use POST method - CDResources should use GET and others should use POST
 Use:
 - used to refresh and update a file even if it already exists
 
 */
- (void) downloadFilename:(NSString *)filename url:(NSString *)urlString isPost:(BOOL)isPost{
    
    // otherwise we need to start downloading this file in background
    //
    if ([urlString length] > 4) {
        //dispatch_async(self.background_queue, ^{
        
        // add request to queue if we are alread downloading
        if (self.state == kTKFMStateDownloading) {
            DDLogVerbose(@"FM: queueing down %@", filename);
            [self.downloadQueue addObject:[NSArray arrayWithObjects:
                                           filename,
                                           urlString,
                                           [NSNumber numberWithBool:isPost],
                                           nil]];
        }
        else {
            DDLogInfo(@"FM: start down %@", filename);
            self.state = kTKFMStateDownloading;
            self.tempFilename = filename;
            TTURLConnection *newConnection = [[TTURLConnection alloc] initWithURLString:urlString isPost:isPost];
            newConnection.delegate = self;
            [newConnection connect];
            self.urlConnection = newConnection;
            [newConnection release];
        }
        //});
    }
}


/*!
 @abstract Checks download queue and start download if a download is present

 
 Use:
 - run after finishing a download or encountering an error
 
 */
- (void) drainDownloadQueue {
    
    if ([self.downloadQueue count] > 0) {
        NSArray *downloadParams = [self.downloadQueue objectAtIndex:0];
        [downloadParams retain];
        // pop off download since it has started
        [self.downloadQueue removeObjectAtIndex:0];
        
        if ([downloadParams count] == 3 ) {
            [self downloadFilename:[downloadParams objectAtIndex:0]
                               url:[downloadParams objectAtIndex:1]
                            isPost:[(NSNumber *)[downloadParams objectAtIndex:2] boolValue]];
        }
        [downloadParams release];
    }
}

/*!
 @abstract Clear out download queue
 
 Use:
 - don't leave downloads pending between sessions, otherwise we will probably queue up too many!
 
 */
- (void) clearDownloadQueue {
    
    if ([self.downloadQueue count] > 0) {
        
        [self.downloadQueue removeAllObjects];
    }
}

/*!
 @abstract gets file given file name
 
 @discussion if local file exists, the file data is returned.  If no file, then start downloading.  Keep sending progress notification while downloading.  Requester should get file again once file download is complete. (100%) if negative progress, then download failed.
 
 @param filname what this file is called
 @param urlString where can we download it from if it does not exists, provide nil if don't want to download!
 
 @return nil if no local file available and needs download
 
 */
- (NSData *) getFileDataForFilename:(NSString *)filename url:(NSString *)urlString {
    
    NSString *filePath = [self pathForFilename:filename isPreview:NO];
    
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    
    // return if data is valid
    if ([fileData length] > 0){
        return fileData;
    }
    
    // otherwise we need to start downloading this file in background
    //
    if ([urlString length] > 4) {
        [self downloadFilename:filename url:urlString isPost:YES];
    }
    return nil;
}


/*!
 @abstract Gets UIImage for a given file name
 
 - only to read from cache, no downloading
 - also loads directly to UIImage to save mem and automatically get @2x images
   ~ pre iOS4.1 may have problem detecting @2x properly
 
 */
- (UIImage *) getImageForFilename:(NSString *)filename {
    /*NSData *fileData = [self getFileDataForFilename:filename url:nil];
    UIImage *newImage = [UIImage imageWithData:fileData];*/
    
    NSString *filePath = [self pathForFilename:filename isPreview:NO];
    UIImage *newImage = [UIImage imageWithContentsOfFile:filePath];
    return newImage;
}



#pragma mark - Preview Image


/*!
 @abstract set Preview data for file name
 
 @discussion save and access preview file for display in chat dialog view.
 
 Preview file prepends "pre_" to the file name
 
 @return YES if operation succeeds, otherwise NO
 */
- (BOOL) setPreviewData:(NSData *)previewData forFilename:(NSString *)filename {
        
    NSString *filePath = [self pathForFilename:filename isPreview:YES];
    
    BOOL didSucceed = [previewData writeToFile:filePath atomically:YES];
    return didSucceed;
    
}

/*!
 @abstract get preview image for file name
 
 @return nil if no preview file available
 */
- (UIImage *) getPreviewImageForFilename:(NSString *)filename {
    
    NSString *filePath = [self pathForFilename:filename isPreview:YES];
    
    NSData *previewData = [NSData dataWithContentsOfFile:filePath];
    UIImage *previewImage = [UIImage imageWithData:previewData];
    
    return previewImage;
}


#pragma mark - URL Conneciton Delegate


/*!
 @abstract Called when data has completed loading and is ready to use.
 
 */
- (void)TTURLConnection:(TTURLConnection *)newUrlConnection finishLoadingWithData:(NSData *)data {
    
    BOOL didSave = NO;
    
    // save cache first, otherwise tempFilename will be overwritten
    // 
    if (self.tempFilename && [data length] > 0) {
        didSave = [self setFileData:data forFilename:self.tempFilename];
    }

    // file saved ok
    if (didSave) {
        // make sure we call it in main thread - since delegate may be a UIView
        //
        if ([self.delegate respondsToSelector:@selector(TKFileManager:finishLoadingWithData:filename:)]) {
            //dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate TKFileManager:self finishLoadingWithData:data filename:self.tempFilename];
            //});
        }
        else if ([self.delegate respondsToSelector:@selector(TKFileManager:finishLoadingWithData:)]) {
            //dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate TKFileManager:self finishLoadingWithData:data];
            //});
        }
    }
    // did not save, so inform of error
    else {
        [self TTURLConnection:newUrlConnection didFailWithError:nil];
    }
    
    // start next download
    // - above must fin first, otherwise tempFilename is overwritten by drain
    self.state = kTKFMStateIdle;
    [self drainDownloadQueue];
}

/*!
 @abstract Called regularly when data is regularly downloaded
 
 */
- (void)TTURLConnection:(TTURLConnection *)urlConnection bytesDownloaded:(NSUInteger)bytes expectedContentLength:(NSUInteger)expectedContentLengthBytes {
    
    // make sure we call it in main thread - since delegate may be a UIView
    //
    if ([self.delegate respondsToSelector:@selector(TKFileManager:bytesDownloaded:expectedContentLength:)]) {
        
        //dispatch_sync(dispatch_get_main_queue(), ^{
        [self.delegate TKFileManager:self bytesDownloaded:bytes expectedContentLength:expectedContentLengthBytes];
        //});
    }
}

/*! 
 @abstract Delegate called when error has occurred
 @discussion Handles connection error.  No further delegate calls will be made 
 for this connection. So reset connection and received data.
 
 */
- (void)TTURLConnection:(TTURLConnection *)connection didFailWithError:(NSError *)error {
    
    
    self.state = kTKFMStateIdle;
    [self drainDownloadQueue];

    if ([self.delegate respondsToSelector:@selector(TKFileManager:didFailWithError:filename:)]) {
        [self.delegate TKFileManager:self didFailWithError:error filename:self.tempFilename];
    }
    else if ([self.delegate respondsToSelector:@selector(TKFileManager:didFailWithError:)]) {
        [self.delegate TKFileManager:self didFailWithError:error];
    }
}



@end
