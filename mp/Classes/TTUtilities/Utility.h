//
//  Utility.h
//
//  Created by M Tsai on 11/29/09.
//  Copyright 2012 TernTek. All rights reserved.
//
#import <objc/runtime.h> 
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import <OpenAL/al.h>  // for ALuint

#import "UIDevice+IdentifierAddition.h"
#import "UIImage+TKUtilities.h"
#import "UIView+TKUtilities.h"



@interface Utility : NSObject {

}

// Device
+ (BOOL) isMultitaskSupported;
+ (CGRect) appFrame;


// Basic
+ (void)swizzleSelector:(SEL)orig ofClass:(Class)c withSelector:(SEL)new;


// Collections
+ (id) arrayByOrderingSet:(NSSet *)set byKey:(NSString *)key ascending:(BOOL)ascending;
+ (BOOL) isIndexPath:(NSIndexPath *)indexPath inIndexPaths:(NSArray *)indexPathArray;

// TableViews
+ (void) findTableDataModelChangesWithCompareSelector:(SEL)compareSelector section:(NSInteger)section newDataArray:(NSArray *)newDataArray oldDataArray:(NSArray *)oldDataArray insertArray:(NSMutableArray *)insertArray deleteArray:(NSMutableArray *)deleteArray;

// Data
+ (NSString *)stringWithHexFromData:(NSData *)data;

// Date Management
+ (NSDate *) stripSecondsFromDate:(NSDate *)newDate;
+ (NSDate *) stripTimeFromDate:(NSDate *)newDate;
+ (NSString *) stringForDate:(NSDate *)newDate  componentString:(NSString *)componentString;
+ (NSString *) shortStyleTimeDate:(NSDate *)date;
+ (NSString *) terseDateString:(NSDate *)date;

// File Management
+ (NSString *)applicationDocumentsDirectory;
+ (NSString *)documentFilePath:(NSString *)fileName;
+ (BOOL)fileExistsAtDocumentFilePath:(NSString *)fileName;
+ (BOOL)hasFileBeenModified:(NSString *)fileName sinceNow:(NSTimeInterval)secsToBeSubtractedFromNow;
+ (void) deleteFileAtPath:(NSString *)filePath;

// NSString
+ (NSString *)trimWhiteSpace:(NSString *)string;

// URL
+ (NSString *)stringByAddingPercentEscapeEncoding:(NSString *)string;
//+ (NSString *)createStringByReplacingPercentEscape:(NSString *)string;


// telephony
+ (BOOL) isTWFixedLinePhoneNumber:(NSString *)phoneNumber;
+ (NSString *)formatPhoneNumber:(NSString *)phoneNumber countryCode:(NSString *)countryCode showCountryCode:(BOOL)showCountryCode;
+ (void) callPhoneNumber:(NSString *)phoneNumber;
+ (void) smsPhoneNumber:(NSString *)phoneNumber presentWithViewController:(UIViewController *)baseController delegate:(id)delegate;
+ (void) componseEmailToAddresses:(NSArray *)addresses presentWithViewController:(UIViewController *)baseController delegate:(id)delegate;


// NSLocale
+ (NSString *)currentLocalCountryCode;

// UIView
+ (UIImage *) imageFromUIView:(UIView *)view;
+ (void) removeSubviewsForView:(UIView *)view tag:(NSInteger)tag;
+ (void) setHighlightOfSubViewForView:(UIView *)view state:(BOOL)state;
+ (void) addLabelsToView:(UIView *)baseView labelArray:(NSArray *)newLabelArray textAlignment:(UITextAlignment)textAlignment;

// UIImage
+ (UIImage *)resizableImage:(UIImage *)image leftCapWidth:(CGFloat)leftCap rightCapWidth:(CGFloat)rightCap topCapHeight:(CGFloat)topCap bottomCapHeight:(CGFloat)bottomCap;
+ (UIImage *)resizableImage:(UIImage *)image leftCapWidth:(CGFloat)leftCap topCapHeight:(CGFloat)topCap;

// UIAlertView
+ (UIAlertView *) showAlertViewWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate tag:(NSInteger)tag;
+ (void) showAlertViewWithTitle:(NSString *)title message:(NSString *)message;
+ (BOOL) doesAlertViewExistWithTag:(NSUInteger)alertTag;

// UILabel
+ (void)setRightHeightForLabel:(UILabel *)label;


//+ (NSMutableArray *) deepCopyOfArray:(NSArray *)oldArray withZone:(NSZone *)zone;


// Audio
+ (void)asPlaySystemSoundFilename:(NSString *)filename;
+ (void) asPlaySystemSoundFilename:(NSString *)filename playbackMode:(BOOL)playbackMode;
+ (AVAudioPlayer *)getAVAudioPlayerWithMp3Name:(NSString *)soundFileName;
+ (AVAudioPlayer *)getAVAudioPlayerWithMp3Name:(NSString *)soundFileName fileType:(NSString *)fileType volume:(float)volume;
+ (AVAudioPlayer *)createAVAudioPlayerWithMp3Name:(NSString *)soundFileName fileType:(NSString *)fileType volume:(float)volume;
+ (void)vibratePhone;


// graphics
//+ (CGColorRef) TTCopyDeviceRGBColorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a;
//+ (CGContextRef) TTCopyBitmapContextWidth:(NSInteger)pixelsWide height:(NSInteger)pixelsHigh;
//+ (CGPathRef) NewPathWithRoundRect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius;
//+ (CGPathRef) NewPathWithRect:(CGRect)rect;
+ (UIImage *) roundedRectangleImage:(CGRect)rect strokeColor:(UIColor *)strokeColor rectColor:(UIColor *)rectColor 
						strokeWidth:(CGFloat)strokeWidth cornerRadius:(CGFloat)cornerRadius;

+ (UIImage *) rectangleImage:(CGRect)rect 
				 strokeColor:(UIColor *)strokeColor 
				   rectColor:(UIColor *)rectColor 
				 strokeWidth:(CGFloat)strokeWidth;

+ (UIImage *) rectangleImage:(CGRect)rect 
				 strokeColor:(UIColor *)strokeColor 
				   rectColor:(UIColor *)rectColor 
				 strokeWidth:(CGFloat)strokeWidth 
				   isEllipse:(BOOL)isEllipse;
//+ (UIImage *) roundedRectangleImage:(CGRect)rect cornerRadius:(CGFloat)cornerRadius fillColor:(UIColor *)fillColor;



@end
