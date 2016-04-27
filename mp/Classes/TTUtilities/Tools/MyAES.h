//
//  MyAES.h
//


#import <CommonCrypto/CommonCryptor.h>
#import "Base64.h"

@interface MyAES : NSObject

+ (NSString *)AES256EncryptWithValue:(NSString *)value;
+ (NSString *)AES256DecryptWithValue:(NSString *)value;

+ (NSString *)AES128EncryptWithValue:(NSString *)value;
+ (NSString *)AES128DecryptWithValue:(NSString *)value;

@end
