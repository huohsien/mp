//
//  MyAES.m
//

#import "MyAES.h"

static NSString *_key = @"1N3A5T7U9R1A3L56";

@implementation MyAES

+ (NSString *)AES256EncryptWithValue:(NSString *)value
{ 
    NSData *m_data = [value dataUsingEncoding:NSUTF8StringEncoding];
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise 
    char keyPtr[kCCKeySizeAES256 + 1]; // room for terminator (unused) 
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding) 
    
    // fetch key data 
    [_key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding]; 
    
    //NSUInteger dataLength = [self length]; 
    
    NSUInteger dataLength = [m_data length]; 
    
    //See the doc: For block ciphers, the output size will always be less than or 
    //equal to the input size plus the size of one block. 
    //That's why we need to add the size of one block here 
    size_t bufferSize           = dataLength + kCCBlockSizeAES128;
    void* buffer                = malloc(bufferSize); 
    
    size_t numBytesEncrypted    = 0; 
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode | kCCOptionPKCS7Padding, keyPtr, kCCKeySizeAES256, NULL /* initialization vector (optional) */, [m_data bytes], dataLength, /* input */ buffer, bufferSize, /* output */ &numBytesEncrypted); //[self bytes]
    
    if (cryptStatus == kCCSuccess) 
    { 
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        
        NSString *return_string = [Base64 encode:[NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted]];
        
        return return_string;//[NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted]; 
    } 
    else
    {
        if (cryptStatus == kCCParamError) NSLog(@"A-enc: PARAM ERROR");
        else if (cryptStatus == kCCBufferTooSmall) NSLog(@"A-enc: BUFFER TOO SMALL");
        else if (cryptStatus == kCCMemoryFailure) NSLog(@"A-enc: MEMORY FAILURE");
        else if (cryptStatus == kCCAlignmentError) NSLog(@"A-enc: ALIGNMENT");
        else if (cryptStatus == kCCDecodeError) NSLog(@"A-enc: DECODE ERROR");
        else if (cryptStatus == kCCUnimplemented) NSLog(@"A-enc: UNIMPLEMENTED");
    }
    
    
    free(buffer); //free the buffer; 
    return nil; 
} 


+ (NSString *)AES256DecryptWithValue:(NSString *)value
{ 
    [Base64 initialize];
        
    NSData *m_data = [Base64 decode:value];

    // 'key' should be 32 bytes for AES256, will be null-padded otherwise 
    char keyPtr[kCCKeySizeAES256 + 1]; // room for terminator (unused) 
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding) 
    
    // fetch key data 
    [_key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding]; 
        
    NSUInteger dataLength = [m_data length]; 
    
    //See the doc: For block ciphers, the output size will always be less than or 
    //equal to the input size plus the size of one block. 
    //That's why we need to add the size of one block here 
    size_t bufferSize           = dataLength + kCCBlockSizeAES128; 
    void* buffer                = malloc(bufferSize); 
    
    size_t numBytesDecrypted    = 0; 
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionECBMode | kCCOptionPKCS7Padding, keyPtr, kCCKeySizeAES256, NULL /* initialization vector (optional) */, [m_data bytes], dataLength, /* input */ buffer, bufferSize, /* output */ &numBytesDecrypted); //[self bytes]
    
    if (cryptStatus == kCCSuccess) 
    { 
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        
        NSString *return_string = [[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted] encoding:NSUTF8StringEncoding];
        
        return [return_string autorelease];
    } 
    else
    {
        if (cryptStatus == kCCParamError) NSLog(@"A-dec: PARAM ERROR");
        else if (cryptStatus == kCCBufferTooSmall) NSLog(@"A-dec: BUFFER TOO SMALL");
        else if (cryptStatus == kCCMemoryFailure) NSLog(@"A-dec: MEMORY FAILURE");
        else if (cryptStatus == kCCAlignmentError) NSLog(@"A-dec: ALIGNMENT");
        else if (cryptStatus == kCCDecodeError) NSLog(@"A-dec: DECODE ERROR");
        else if (cryptStatus == kCCUnimplemented) NSLog(@"A-dec: UNIMPLEMENTED");
    }
    
    free(buffer); //free the buffer; 
    return nil; 
} 

+ (NSString *)AES128EncryptWithValue:(NSString *)value
{
    NSData *m_data = [value dataUsingEncoding:NSUTF8StringEncoding];
    // 'key' should be 16 bytes for AES128, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES128 + 1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [_key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    //NSUInteger dataLength = [self length];
    
    NSUInteger dataLength = [m_data length];
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize           = dataLength + kCCBlockSizeAES128;
    void* buffer                = malloc(bufferSize);
    
    size_t numBytesEncrypted    = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode | kCCOptionPKCS7Padding, keyPtr, kCCKeySizeAES128, NULL, [m_data bytes], dataLength, /* input */ buffer, bufferSize, /* output */ &numBytesEncrypted);


    if (cryptStatus == kCCSuccess)
    {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        
//        NSString *return_string = [self toHexStringFromNSData:[NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted]];
        NSString *return_string = [Base64 encode:[NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted]];
        
        return return_string;
    }
    else
    {
        if (cryptStatus == kCCParamError) NSLog(@"A-enc: PARAM ERROR");
        else if (cryptStatus == kCCBufferTooSmall) NSLog(@"A-enc: BUFFER TOO SMALL");
        else if (cryptStatus == kCCMemoryFailure) NSLog(@"A-enc: MEMORY FAILURE");
        else if (cryptStatus == kCCAlignmentError) NSLog(@"A-enc: ALIGNMENT");
        else if (cryptStatus == kCCDecodeError) NSLog(@"A-enc: DECODE ERROR");
        else if (cryptStatus == kCCUnimplemented) NSLog(@"A-enc: UNIMPLEMENTED");
    }
    
    
    free(buffer); //free the buffer;
    return nil;
}


+ (NSString *)AES128DecryptWithValue:(NSString *)value {
            
//    NSData *m_data = [self toBinaryDataFromHexString:value];
    
    [Base64 initialize];
    NSData *m_data = [Base64 decode:value];
    
    // 'key' should be 16 bytes for AES128, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES128 + 1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [_key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    //NSUInteger dataLength = [self length];
    
    NSUInteger dataLength = [m_data length];
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize           = dataLength + kCCBlockSizeAES128;
    void* buffer                = malloc(bufferSize);
    
    size_t numBytesDecrypted    = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionECBMode | kCCOptionPKCS7Padding, keyPtr, kCCKeySizeAES128, NULL, [m_data bytes], dataLength, /* input */ buffer, bufferSize, /* output */ &numBytesDecrypted);
    
    if (cryptStatus == kCCSuccess)
    {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        
        NSString *return_string = [[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted] encoding:NSUTF8StringEncoding];
        
        return [return_string autorelease];
    }
    else
    {
        if (cryptStatus == kCCParamError) NSLog(@"A-dec: PARAM ERROR");
        else if (cryptStatus == kCCBufferTooSmall) NSLog(@"A-dec: BUFFER TOO SMALL");
        else if (cryptStatus == kCCMemoryFailure) NSLog(@"A-dec: MEMORY FAILURE");
        else if (cryptStatus == kCCAlignmentError) NSLog(@"A-dec: ALIGNMENT");
        else if (cryptStatus == kCCDecodeError) NSLog(@"A-dec: DECODE ERROR");
        else if (cryptStatus == kCCUnimplemented) NSLog(@"A-dec: UNIMPLEMENTED");
    }
    
    free(buffer); //free the buffer;
    return nil;
} 

+ (NSString *)toHexStringFromNSData:(NSData *)data {
    
    NSString *returnString = @"";
    
    int length = [data length];
    void *buffer = malloc(length);
    [data getBytes:buffer length:length];
    
    for (int i = 0; i < length; i++) {
        
        uint8_t dataByte = ((uint8_t *)buffer)[i];
        returnString = [NSString stringWithFormat:@"%@%02X", returnString, dataByte];
        NSLog(@"%d %@", i, returnString);
    }
    free(buffer);
    return returnString;
}

+ (NSData *)toBinaryDataFromHexString:(NSString *)dataString {
        
    int length = [dataString length] / 2;
    void *buffer = malloc(length);
    
    for (int i = 0; i < length; i++) {
        NSRange range = NSMakeRange(i * 2, 2);

        NSString *subString = [dataString substringWithRange:range];
        unsigned int outVal;
        NSScanner* scanner = [NSScanner scannerWithString:subString];
        [scanner scanHexInt:&outVal];
        ((uint8_t *)buffer)[i] = (uint8_t)(outVal & 0xff);
    }
    NSData *returnData = [NSData dataWithBytes:buffer length:length];
    free(buffer);

    return returnData;
}

@end
