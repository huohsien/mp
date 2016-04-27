//
//  MPImageManager.m
//  mp
//
//  Created by M Tsai on 11-12-10.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "MPImageManager.h"
#import "UIImage+TKUtilities.h"
#import "MPImageSource.h"

NSString const *kMPParamImageFileType = @"png";


// if no context, then original large file
//NSString* const kMPImageContextLarge = @"large";    // for large view headshots
NSString* const kMPImageContextList = @"list";      // for list view headshots
NSString* const kMPImageContextDialog = @"dialog";  // for dialog previews




@implementation MPImageManager


@synthesize delegate;
//@synthesize background_queue;
@synthesize fileManager;
@synthesize imageName;
@synthesize version;
@synthesize context;
@synthesize url;



- (void) dealloc {
    
    fileManager.delegate = nil;
    
    delegate = nil;
    /*if (background_queue != NULL) {
        dispatch_release(background_queue);
    }*/
    [fileManager release];
    [imageName release];
    [version release];
    [url release];
    [context release];
    
    [super dealloc];
}

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
        TKFileManager *fileM = [[TKFileManager alloc] init];
        fileM.delegate = self;
        self.fileManager = fileM;
        [fileM release];
	}
	return self;
}


/*!
 @abstract Gets the file name for this image
 
 @param withVersion should version be included? NO is Useful to get older versions
 
 Once a file created or downloaded, it is saved locally.  If this file has a version
 number associated to it, IM will also create a symbolic link without the 
 version number. (to be used as a backup)
 
 Format:
 imageName_context_version.png      regular format
 imageName_version.png              Original large file
 imageName_context.png              Old version file
 imageName.png                      Old version and original large file
 
 imageName:
 - headhost use userID
 - image user messageID
 
 */
- (NSString *)filenameForVersion:(NSString *)newVersion context:(NSString *)newContext{
    
    NSString *contextString = @"";
    if (newContext) {
        contextString = [NSString stringWithFormat:@"_%@", newContext];
    }
    NSString *versionString = @"";
    if (newVersion){
        versionString = [NSString stringWithFormat:@"_%@", newVersion];
    }
    return [NSString stringWithFormat:@"%@%@%@.%@", self.imageName, contextString, versionString, kMPParamImageFileType];
}


/*!
 @abstract create old version sym link of file
 */
- (BOOL) createOldVersionSymLinkForVersion:(NSString *)newVersion context:(NSString *)newContext {
    
    // get filenames for sym and dest files
    //
    
    // old backup file
    NSString *symFilename = [self filenameForVersion:nil context:newContext];
    
    // dest file
    NSString *destFilename = [self filenameForVersion:newVersion context:newContext];
    
    return [self.fileManager createSymbolicLink:symFilename destinationFilename:destFilename];
}

/*!
 @abstract converts the original image to the desired context
 
 - saves the context image and returns it
 
 */
- (UIImage *) convertOriginalImageData:(NSData *)originalData toContext:(NSString *)newContext version:(NSString *)newVersion {
    
    if (!originalData) {
        return nil;
    }
    
    CGSize newSize = CGSizeZero;
    
    if (newContext == kMPImageContextList){
       newSize = CGSizeMake(44.0, 44.0);
    }
    else if (newContext == kMPImageContextDialog){
        newSize = CGSizeMake(100.0, 100.0);
    }
    
    UIImage *originalImage = [UIImage imageWithData:originalData];
    UIImage *newImage = [UIImage imageWithImage:originalImage scaledToSize:newSize maintainScale:YES];
    
    // if convert successful, write to cache
    if (newImage) {
        NSString *newFilename = [self filenameForVersion:newVersion context:newContext];
        NSData *imageData = UIImageJPEGRepresentation(newImage, 0.8);  // UIImagePNGRepresentation(newImage);
        [self.fileManager setFileData:imageData forFilename:newFilename];
    }
    
    // create old version symbolic link
    //
    [self createOldVersionSymLinkForVersion:newVersion context:newContext];
    
    return newImage;
}


- (void) setupWithObject:(id)object context:(NSString *)displayContext ignoreVersion:(BOOL)ignoreVersion {
    
    // get name, version and URL info
    //
    self.imageName = [object imageName];
    self.url = [object imageURLForContext:displayContext ignoreVersion:ignoreVersion];
    self.context = displayContext;
    
    if (ignoreVersion) {
        self.version = nil; 
    }
    else {
        self.version = [object imageVersion];
    }
}


/*!
 @abstract Gets the image that represents this object
 
 @context       Represents the context in which this image will be used - determines size of image
 @ignoreVersion Should version information be ignored (for my own profile headshots)
 
 */
- (UIImage *) getImageForObject:(id)object context:(NSString *)displayContext ignoreVersion:(BOOL)ignoreVersion{
    
    // only for objects that conform!
    if (![object conformsToProtocol:@protocol(MPImageSource)]) {
        return nil;
    }
    
    // get name, version and URL info
    //
    [self setupWithObject:object context:displayContext ignoreVersion:ignoreVersion];
    
    
    // see if file exists return it immediately
    //
    NSData *fileData = [self.fileManager getFileDataForFilename:[self filenameForVersion:self.version context:self.context] url:nil];
    
    // make sure data is returning something useful
    // - otherwise download again
    if ([fileData length] > 0) {
        return [UIImage imageWithData:fileData];
    }
    
    
    // if large version exists convert in background to the right context and call back
    //
    NSData *originalData = [self.fileManager getFileDataForFilename:[self filenameForVersion:self.version context:nil] url:nil];
    UIImage *convertedImage = [self convertOriginalImageData:originalData toContext:self.context version:self.version];
    if (convertedImage) {
        return convertedImage;
    }

    // if url exits and version number is greater than 0, then try downloading it
    //
    if ([self.url length] > 5) {
        [self.fileManager getFileDataForFilename:[self filenameForVersion:self.version context:self.context] url:self.url];
        
        // inform delegate that we started download
        if ([self.delegate respondsToSelector:@selector(MPImageManager:didStartImageDownload:)]) {
            [self.delegate MPImageManager:self didStartImageDownload:self.url];
        }
    }
    
    // ** don't try to download large size 
    // otherwise download original in background
    // - after downloading, 
    //[self.fileManager getFileDataForFilename:[self filenameForVersion:self.version context:nil] url:self.url];
    
    
    // if older version exists return it for now, but continue to download the newest one
    //
    NSString *oldName = [self filenameForVersion:nil context:self.context];
    NSData *oldData = [self.fileManager getFileDataForFilename:oldName url:nil];
    if (oldData) {
        return [UIImage imageWithData:oldData];
    }
    return nil;
}

- (UIImage *) getImageForObject:(id)object context:(NSString *)displayContext {
    
    return [self getImageForObject:object context:displayContext ignoreVersion:NO];

}


/*!
 @abstract gets a local cached file without downloading
 
 @param context which context do we want?
 
 Use:
 - to get a picture of myself or when we don't want to request a download
 
 */
- (UIImage *) getImageForFilename:(NSString *)filename context:(NSString *)displayContext{
    
    if ([filename length] > 0) {
        
        NSString *contextString = @"";
        if (displayContext) {
            contextString = [NSString stringWithFormat:@"_%@", displayContext];
        }
        
        NSString *fileN = [NSString stringWithFormat:@"%@%@.%@", filename, contextString, kMPParamImageFileType];
        
        NSData *oldData = [self.fileManager getFileDataForFilename:fileN url:nil];
        if (oldData) {
            return [UIImage imageWithData:oldData];
        }
    }
    return nil;
}

/*!
 @abstract caches a file locally
 
 @param which context is this image for
 @param filename full file name including file type
        - can use filenameForVersion:context: to obtain
 @param version of the file to get
 
 Use:
 - cache images of myself for future use
 
 */
- (void) setImage:(UIImage *)image forFilename:(NSString *)filename context:(NSString *)displayContext version:(NSString *)newVersion {
    
    if (image && [filename length] > 0) {
        
        NSString *contextString = @"";
        if (displayContext) {
            contextString = [NSString stringWithFormat:@"_%@", displayContext];
        }
        NSString *versionString = @"";
        if (newVersion){
            versionString = [NSString stringWithFormat:@"_%@", newVersion];
        }
        NSString *fileN = [NSString stringWithFormat:@"%@%@%@.%@", filename, contextString, versionString, kMPParamImageFileType];
        NSString *fileNoVersion = [NSString stringWithFormat:@"%@%@.%@", filename, contextString, kMPParamImageFileType];

        NSData *imageData = UIImageJPEGRepresentation(image, 0.8); // UIImagePNGRepresentation(image);
        [self.fileManager setFileData:imageData forFilename:fileN];
        
        // Create no version symlink of this file just set
        //
        NSString *symFilename = fileNoVersion;
        NSString *destFilename = fileN;
        [self.fileManager createSymbolicLink:symFilename destinationFilename:destFilename];
    }
}

- (void) setImage:(UIImage *)image forFilename:(NSString *)filename context:(NSString *)displayContext {
    [self setImage:image forFilename:filename context:displayContext version:nil];
}

#pragma mark - TKFileManager Delegate


/*!
 @abstract Called when data has completed loading and is ready to use.
 
 - just finished download original file
 - create a sym link for it
 
 */
- (void)TKFileManager:(TKFileManager *)fileManager finishLoadingWithData:(NSData *)data{
    
    // finished downloading original file
    //
    [self createOldVersionSymLinkForVersion:self.version context:self.context];

    // call delegate and send it the new image
    //
    UIImage *newImage = [UIImage imageWithData:data];
    
    if (newImage && [self.delegate respondsToSelector:@selector(MPImageManager:finishLoadingImage:)]){
        [self.delegate MPImageManager:self finishLoadingImage:newImage];
    }
}

/*!
 @abstract Called regularly when data is regularly downloaded
 
 */
- (void)TKFileManager:(TKFileManager *)fileManager bytesDownloaded:(NSUInteger)bytes expectedContentLength:(NSUInteger)expectedContentLengthBytes{
    
    if ([self.delegate respondsToSelector:@selector(MPImageManager:bytesDownloaded:expectedContentLength:)]){
        [self.delegate MPImageManager:self bytesDownloaded:bytes expectedContentLength:expectedContentLengthBytes];
    }
}

/*! 
 @abstract Delegate called when error has occurred
 @discussion Handles connection error.  No further delegate calls will be made 
 for this connection. So reset connection and received data.
 */
- (void)TKFileManager:(TKFileManager *)fileManager didFailWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(MPImageManager:didFailWithError:)]){
        [self.delegate MPImageManager:self didFailWithError:error];
    }
}


@end
