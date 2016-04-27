//
//  Utility.m
//
//  Created by M Tsai on 11/29/09.
//  Copyright 2012 TernTek. All rights reserved.
//

#import "Utility.h"
#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "TKLog.h"





#pragma mark -
#pragma mark C Functions



CGMutablePathRef createRoundedRectForRect(CGRect rect, CGFloat radius) {
	
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPathAddArcToPoint(path, NULL, CGRectGetMaxX(rect), CGRectGetMinY(rect), 
						CGRectGetMaxX(rect), CGRectGetMaxY(rect), radius);
    CGPathAddArcToPoint(path, NULL, CGRectGetMaxX(rect), CGRectGetMaxY(rect), 
						CGRectGetMinX(rect), CGRectGetMaxY(rect), radius);
    CGPathAddArcToPoint(path, NULL, CGRectGetMinX(rect), CGRectGetMaxY(rect), 
						CGRectGetMinX(rect), CGRectGetMinY(rect), radius);
    CGPathAddArcToPoint(path, NULL, CGRectGetMinX(rect), CGRectGetMinY(rect), 
						CGRectGetMaxX(rect), CGRectGetMinY(rect), radius);
    CGPathCloseSubpath(path);
	
    return path;        
}


@implementation Utility


#pragma mark - System & Device Queries


/*!
 @checks if app support background
 */
+ (BOOL) isMultitaskSupported {
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) {
        return [[UIDevice currentDevice] isMultitaskingSupported];
    }
    return NO;
}


/*!
 @checks get app frame
 
 - accounts for status bar
 - also checks for orientation
 */
+ (CGRect) appFrame {
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        return appFrame;
    }
    else {
        return CGRectMake(0.0, 20.0, appFrame.size.height, appFrame.size.width);
    }
}



#pragma mark - Basic


/*!
 @abstract allows you to switch a method of an existing class - like hijacking it
 
 see: http://www.cocoadev.com/index.pl?MethodSwizzling
 
 Use:
 - to insert custom nav bar for iOS4.0 and below
 
 */
+ (void)swizzleSelector:(SEL)orig ofClass:(Class)c withSelector:(SEL)new;
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    
    if (class_addMethod(c, orig, method_getImplementation(newMethod),
                        method_getTypeEncoding(newMethod)))
    {
        class_replaceMethod(c, new, method_getImplementation(origMethod),
                            method_getTypeEncoding(origMethod));
    }
    else
    {
        method_exchangeImplementations(origMethod, newMethod);
    }
}



#pragma mark - Collection Methods
/**
 Sorts a unordered set of objects according to key of attribute specified
 */
+ (id) arrayByOrderingSet:(NSSet *)set byKey:(NSString *)key ascending:(BOOL)ascending {
	NSMutableArray *ret = [NSMutableArray arrayWithCapacity:[set count]];
	for (id oneObject in set) {
		[ret addObject:oneObject];
	}
	
	NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:ascending];
	[ret sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
	[descriptor release];
	return ret;
}


/**
 Checks if a indexPath is within an array of index paths
 */
+ (BOOL) isIndexPath:(NSIndexPath *)indexPath inIndexPaths:(NSArray *)indexPathArray {
	
	for (NSIndexPath *iPath in indexPathArray){
		if ([indexPath compare:iPath] == NSOrderedSame) {
			//DDLogVerbose(@"ipath:%@ ip:%@", iPath, indexPath);
			return YES;
		}
	}
	return NO;
}

#pragma mark - NSData

+ (NSString *)stringWithHexFromData:(NSData *)data
{
    NSString *result = [[data description] stringByReplacingOccurrencesOfString:@" " withString:@""];
    result = [result substringWithRange:NSMakeRange(1, [result length] - 2)];
    return result;
}


#pragma mark - NSDate Time Methods

/*!
 @abstract Creates and caches date formatter
 
 - expensive to create and allocate
 
 */
+ (NSDateFormatter *)dateFormatter
{
    NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *formatter = [dictionary objectForKey:@"UtilityDateFormatter"];
    if (!formatter)
    {
        formatter = [[[NSDateFormatter alloc] init] autorelease];
        
        [dictionary setObject:formatter forKey:@"UtilityDateFormatter"];
    }
    
    // reset formatter - but this is slightly expensive too
    // - so use methods below if possible
    [formatter setDateFormat:@""];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterNoStyle];
    
    return formatter;
}


/*!
 @abstract Creates and caches date formatter with short time format
 
 - expensive to create and allocate
 
 */
+ (NSDateFormatter *)dateFormatterTimeShort
{
    NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *formatter = [dictionary objectForKey:@"UtilityDateFormatterTimeShort"];
    if (!formatter)
    {
        formatter = [[[NSDateFormatter alloc] init] autorelease];
        [formatter setTimeStyle:NSDateFormatterShortStyle];

        [dictionary setObject:formatter forKey:@"UtilityDateFormatterTimeShort"];
    }
    
    return formatter;
}


/*!
 @abstract Creates and caches date formatter with short date format
 
 - expensive to create and allocate
 
 */
+ (NSDateFormatter *)dateFormatterDateShort
{
    NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *formatter = [dictionary objectForKey:@"UtilityDateFormatterDateShort"];
    if (!formatter)
    {
        formatter = [[[NSDateFormatter alloc] init] autorelease];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        
        [dictionary setObject:formatter forKey:@"UtilityDateFormatterDateShort"];
    }
    
    return formatter;
}

/*!
 @abstract Gets only the date with the seconds chopped off
 
 Use:
 - if you don't want seconds accuracy
 
 */
+ (NSDate *) stripSecondsFromDate:(NSDate *)newDate {
    if (newDate) {        
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *dayComponents = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit) fromDate:newDate];
        
        NSDate *dateNoSecs = [cal dateFromComponents:dayComponents];
        
        return dateNoSecs;
    }
    return nil;
}


/*!
 @abstract Gets only the day components without time
 
 Use:
 - useful to compare if two days are the same
 
 */
+ (NSDate *) stripTimeFromDate:(NSDate *)newDate {
    if (newDate) {        
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *dayComponents = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:newDate];
        
        NSDate *dateNoTime = [cal dateFromComponents:dayComponents];
        
        return dateNoTime;
    }
    return nil;
}


/*!
 @abstract Gets date string for using current local given date components
 
 - for date components see : http://unicode.org/reports/tr35/#Date_Format_Patterns
 
 */
+ (NSString *) stringForDate:(NSDate *)newDate  componentString:(NSString *)componentString {
    if (newDate) {        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
                
        NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:componentString options:0 locale:[NSLocale currentLocale]];
        [df setDateFormat:dateFormat];
        NSString *sString = [df stringFromDate:newDate];
        [df release];
        return sString;
    }
    return nil;
}

/*!
 @abstract Gets short format for time and date
 
 */
+ (NSString *) shortStyleTimeDate:(NSDate *)date {
    
    if (date) {
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        NSString *dateString = [NSString stringWithFormat:@"%@", [formatter stringFromDate:date]];
        [formatter release];
        return dateString;
    }
    return nil;
}

/*!
 @abstract Gets the time if today or date if not today

 @discussion This methods returns a date string that provides minimun info needed by the user
 
 @return nil if date is not valid
 
 e.g.
 today:     9:10 AM
 yesterday: yesterday
 not today: 10/11/10
 
 */
+ (NSString *) terseDateString:(NSDate *)date {
    
    if (date) {
        
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *todayComponents = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
        NSDateComponents *yesterdayComponents = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate dateWithTimeIntervalSinceNow:-86400.0]];
        
        NSDate *today = [cal dateFromComponents:todayComponents];
        NSDate *yesterday = [cal dateFromComponents:yesterdayComponents];
        
        NSDateComponents *components = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:date];
        NSDate *dateNoTime = [cal dateFromComponents:components];
        
        NSString *dateString = nil;
        
        // if today, time only
        if([today isEqualToDate:dateNoTime]) {
            
            // use cached copy
            NSDateFormatter* formatterTime = [Utility dateFormatterTimeShort];
            dateString = [NSString stringWithFormat:@"%@", [formatterTime stringFromDate:date]];
                                              
        }
        // if yesterday
        else if([yesterday isEqualToDate:dateNoTime]) {
            dateString = NSLocalizedString(@"yesterday", @"Utility - date: identify date as yesterday");
        }
        // older date, date only
        else {
            // use cached copy
            NSDateFormatter* formatterDate = [Utility dateFormatterDateShort];
            dateString = [NSString stringWithFormat:@"%@", [formatterDate stringFromDate:date]];
        }              
        return dateString;
    }
    return nil;
}


#pragma mark - File Management Methods

/**
 Returns the path to the application's Documents directory.
 */
+ (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

/*!
 @abstract Provide the absolute path to the file in the document directory
 */
+ (NSString *)documentFilePath:(NSString *)fileName {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return [documentsDirectory stringByAppendingFormat:@"/%@",fileName];
	// mht: stringByAppendingPathComponent .. didn't work well on device for me.. may get fixe later
	//      use above for now since it is reliable
}


//
// Checks if file exists in document directory, provided the filename
//
+ (BOOL)fileExistsAtDocumentFilePath:(NSString *)fileName {
	return [[NSFileManager defaultManager] fileExistsAtPath:[Utility documentFilePath:fileName]];
}

/**
 Deletes file for a given path
 */
+ (void) deleteFileAtPath:(NSString *)filePath {
	NSError *error = nil;
	[[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
}


/**
 Check if file has been modified between now and the date given
  * this checks if the file is still fresh

 Return:
  * YES: if modified
  * NO: if not modified or the file does not exits
  * sinceNow: specifies how many seconds ago do you still consider this file still fresh
    - NSTimeInterval is a double e.g. 53432.3f
    - positive number is future, negative number is the past
*/
+ (BOOL)hasFileBeenModified:(NSString *)fileName sinceNow:(NSTimeInterval)secsToBeSubtractedFromNow {
	NSDictionary *fileAttributesDictionary = [[NSFileManager defaultManager] 
											  attributesOfItemAtPath:[Utility documentFilePath:fileName]
															   error:nil];
	NSDate *fileModificationDate = [fileAttributesDictionary fileModificationDate];
	
	NSDate *checkDate = [[NSDate alloc] initWithTimeIntervalSinceNow:secsToBeSubtractedFromNow*(-1.0f)]; // neg to go into past
	BOOL answer = NO;
	if ([fileModificationDate compare:checkDate] == NSOrderedDescending) {
		answer = YES;
	}
	[checkDate release];
	return answer;
}

#pragma mark - NSString

/*!
 @abstract Removes white space from start and end of strings

 Use:
 - if you don't want white spaces at the ends of strings
 
 E.g.
 " spaces in front and at the end " ---> "spaces in front and at the end"
 
 */
+ (NSString *)trimWhiteSpace:(NSString *)string {
    
    NSString *trimmedString = [string stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmedString;
}



#pragma mark - URL

/*!
 @abstract Add percent escape encoding to given string
 
 @return returns string with +1 retain!  so release when done.
 
 Note
 - [nickname stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
   * The method above does not encode special URL chars such as &, =, etc..
   * However, this method will do this encoding!... this is perferred.
 
 Legal Chars Encoded:
 This methods adds additional chars to encode: " ! * ' ( ) ; : @ & = + $ , / ? % # [ ] "
 
 Encoding: UTF8

 
 */
+ (NSString *)stringByAddingPercentEscapeEncoding:(NSString *)string {

    NSString *retString  =  (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                (CFStringRef) string,
                                                NULL,
                                                (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                                kCFStringEncodingUTF8);
    return [retString autorelease];
}

/*!
 @abstract Reverses the above
 
 @return returns string with +1 retain!  so release when done.
 
 Note
 - [nickname stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
 * The method above does not encode special URL chars such as &, =, etc..
 * However, this method will do this encoding!... this is perferred.
 
 Legal Chars Encoded:
 This methods adds additional chars to encode: " ! * ' ( ) ; : @ & = + $ , / ? % # [ ] "
 
 Encoding: UTF8
 
 
 */
/*+ (NSString *)createStringByReplacingPercentEscape:(NSString *)string {
    
    NSString *retString  =  (NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                    (CFStringRef) string,
                                                                                    CFSTR(""),
                                                                                    kCFStringEncodingUTF8);
    return retString;
}*/




#pragma mark - Telephony & Formatting 

/*!
 @abstract Is TW LandLine
 - is given number a fixed line number (or non-mobile)
 
 01xxxxxxx, 02xxxxxx , 03xxxxxx, 04xxxxxx ................. 08xxxxxxx
 +8861xxxxx  ~ +8868xxxx
 0028861xxxx~0028868xxxx
 0128861xxxx~0128868xxxx
 0058861xxxx~0058868xxxx
 0158861xxxx~0158868xxxx
 0068861xxxx~0068868xxxx
 0168861xxxx~0168868xxxx
 0078861xxxx~0078868xxxx
 0098861xxxx~0098868xxxx
 0198861xxxx~0198868xxxx
 
 */
+ (BOOL) isTWFixedLinePhoneNumber:(NSString *)phoneNumber {
    
    NSSet *basePrefixes = [NSSet setWithObjects:
                             @"0",
                             @"+886", 
                             @"002886",
                             @"005886",
                             @"006886",
                             @"007886",
                             @"009886",
                             @"012886",
                             @"015886",
                             @"016886",
                             @"019886",
                             nil];
    NSSet *subPrefixes = [NSSet setWithObjects:@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", nil];
    
    // create all prefix combinations
    //
    NSMutableSet *allPrefixes = [[NSMutableSet alloc] initWithCapacity:[basePrefixes count]*[subPrefixes count]];
    for (NSString *iBase in basePrefixes) {
        for (NSString *iSub in subPrefixes) {
            [allPrefixes addObject:[iBase stringByAppendingString:iSub]];
        }
    }
    BOOL isLandLine = NO;
    // if match any prefix, then it is landline
    for (NSString *iPrefix in allPrefixes) {
        if ([phoneNumber hasPrefix:iPrefix]) {
            isLandLine = YES;
            break;
        }
    }
    [allPrefixes release];
    return isLandLine;
}


/*!
 @abstract formats phone numbers into a readable string
 
 @param phoneNumber phone number to format
 @param countryCode helps determin how to format
 @param showCountryCode should returned string include country code?

 
 Note
 - 
 - all param should only have digits!
 - mainly for cell phones!
 
 */
+ (NSString *)formatPhoneNumber:(NSString *)phoneNumber countryCode:(NSString *)countryCode showCountryCode:(BOOL)showCountryCode {
    
    // strip all non digits
    NSCharacterSet *nonDecimalSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSString *strippedCountry = [[countryCode componentsSeparatedByCharactersInSet:nonDecimalSet] componentsJoinedByString:@""];
    
    if ([phoneNumber hasPrefix:@"+"]) {
        
        // force cc to show since it was already included in phone number
        showCountryCode = YES;
        
        // if phone starts with country code
        if ([phoneNumber hasPrefix:@"+886"] && [phoneNumber length] > 4) {
            strippedCountry = @"886";
            phoneNumber = [phoneNumber substringFromIndex:4];
        }
        else if ([phoneNumber hasPrefix:@"+81"] && [phoneNumber length] > 3) {
            strippedCountry = @"81";
            phoneNumber = [phoneNumber substringFromIndex:3];
        }
        else if ([phoneNumber hasPrefix:@"+86"] && [phoneNumber length] > 3) {
            strippedCountry = @"86";
            phoneNumber = [phoneNumber substringFromIndex:3];
        }
        else if ([phoneNumber hasPrefix:@"+1"] && [phoneNumber length] > 2) {
            strippedCountry = @"1";
            phoneNumber = [phoneNumber substringFromIndex:2];
        }
        // unknown country to return original phone number back
        else {
            return phoneNumber;
        }
    }
    
    
    
    // What if phone has *, # chars? - leave it for now


    NSString *strippedPhone = [[phoneNumber componentsSeparatedByCharactersInSet:nonDecimalSet] componentsJoinedByString:@""];
    NSUInteger phoneLength = [strippedPhone length];

    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterNoStyle];
    //[formatter setLenient:YES];
    
    NSString *phoneString = nil;
    
    // for Taiwan ###-###-###
    //
    if ([strippedCountry isEqualToString:@"886"]) {
        
        if (phoneLength == 9) {
            phoneString = [NSString stringWithFormat:@"%@-%@-%@", 
                           [strippedPhone substringWithRange:NSMakeRange(0,3)],
                           [strippedPhone substringWithRange:NSMakeRange(3,3)],
                           [strippedPhone substringWithRange:NSMakeRange(6,3)]];
        }
        else if (phoneLength == 10) {
            
            // mobile numbers
            if ([strippedPhone hasPrefix:@"09"]) {
                phoneString = [NSString stringWithFormat:@"%@-%@-%@", 
                               [strippedPhone substringWithRange:NSMakeRange(0,4)],
                               [strippedPhone substringWithRange:NSMakeRange(4,3)],
                               [strippedPhone substringWithRange:NSMakeRange(7,3)]];
            }
            // land lines
            else {
                phoneString = [NSString stringWithFormat:@"%@-%@-%@", 
                               [strippedPhone substringWithRange:NSMakeRange(0,2)],
                               [strippedPhone substringWithRange:NSMakeRange(2,4)],
                               [strippedPhone substringWithRange:NSMakeRange(6,4)]];
            }
        }
        else if (phoneLength > 5) {
            phoneString = [NSString stringWithFormat:@"%@-%@-%@", 
                           [strippedPhone substringWithRange:NSMakeRange(0,2)],
                           [strippedPhone substringWithRange:NSMakeRange(2,3)],
                           [strippedPhone substringFromIndex:5]];
        }
        else {
            phoneString = strippedPhone;
        }
    }
    // for Japan ## #### ####
    else if ([strippedCountry isEqualToString:@"81"] && phoneLength == 10){
        
        phoneString = [NSString stringWithFormat:@"%@ %@ %@", 
                       [strippedPhone substringWithRange:NSMakeRange(0,2)],
                       [strippedPhone substringWithRange:NSMakeRange(1,4)],
                       [strippedPhone substringWithRange:NSMakeRange(5,4)]];
    }
    // for China ###-####-####
    else if ([strippedCountry isEqualToString:@"86"] && phoneLength == 11){
        
        phoneString = [NSString stringWithFormat:@"%@-%@-%@", 
                       [strippedPhone substringWithRange:NSMakeRange(0,3)],
                       [strippedPhone substringWithRange:NSMakeRange(3,4)],
                       [strippedPhone substringWithRange:NSMakeRange(7,4)]];
    }
    // for NorthA (###) ###-####
    else if ([strippedCountry isEqualToString:@"1"] && phoneLength == 10){
        
        phoneString = [NSString stringWithFormat:@"(%@) %@-%@", 
                       [strippedPhone substringWithRange:NSMakeRange(0,3)],
                       [strippedPhone substringWithRange:NSMakeRange(3,3)],
                       [strippedPhone substringWithRange:NSMakeRange(6,4)]];
    }
    // reset just bunch them together
    else {
        phoneString = strippedPhone;
    }
    [formatter release];
    
    if (!strippedCountry) {
        strippedCountry = @"";
    }
    
    NSString *fullNumber = nil;
    
    if (showCountryCode && [strippedCountry length] > 0) {
        fullNumber = [NSString stringWithFormat:@"+%@ %@", strippedCountry, phoneString];
    }
    else {
        fullNumber = phoneString;
    }
    
    return fullNumber;
    
}







/*!
 @abstract Call phone number
 
 */
+ (void) callPhoneNumber:(NSString *)phoneNumber {
    
    // perform action!!!
	NSString *escapedString = phoneNumber;
	
    if (!escapedString) {
        return;
    }
	
	// check for special characters
	// - if in middle of string notify users that 3rd party apps can't dial # or *
	// - if at end of string strip character and tell users to dial it manually
    // strip string of special characters
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"*" withString:@""];
	
	// prepare string for URL calling out
	escapedString = [escapedString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	// can be call, callHome, callWork, etc.
    
    NSString *urlString = [NSString stringWithFormat:@"tel:%@", escapedString];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlString]]) {
        DDLogVerbose(@"UTL: calling phone");
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }
    else {
        DDLogVerbose(@"UTL: telephony not supported %@", escapedString);
        
        // alert users that mail is not setup yet
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Call Failure", @"Call - alert: inform of failure")
                                                         message:NSLocalizedString(@"Device does not support Telephony.", @"Call - alert: device does not support calls") 
                                                        delegate:nil
                                               cancelButtonTitle:@"OK" 
                                               otherButtonTitles:nil] autorelease];
        [alert show];
    }
}







/*!
 @abstract SMS registered phone
 */
+ (void) smsPhoneNumber:(NSString *)phoneNumber presentWithViewController:(UIViewController *)baseController delegate:(id)delegate {
	
    if (!phoneNumber) {
        return;
    }
    
    // check if sms is available
    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *composer = [[MFMessageComposeViewController alloc] init];
        composer.messageComposeDelegate = delegate;
        composer.recipients = [NSArray arrayWithObject:phoneNumber];
        
        // present with root container to allow rotation
        //
        [baseController presentModalViewController:composer animated:YES];
        [composer release]; // autorelease?
    }
    else {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Compose SMS Failure", @"SMS - alert: inform of failure")
                                                         message:NSLocalizedString(@"Device does not support SMS.", @"SMS - alert: device does not support SMS")
                                                        delegate:nil
                                               cancelButtonTitle:@"OK" 
                                               otherButtonTitles:nil] autorelease];
        [alert show];
    }
}




/*!
 @abstract SMS registered phone
 */
+ (void) componseEmailToAddresses:(NSArray *)addresses presentWithViewController:(UIViewController *)baseController delegate:(id)delegate {
    // check if can send email first
    if ([MFMailComposeViewController canSendMail]) {

        MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
        composer.mailComposeDelegate = delegate;
        [composer setToRecipients:addresses];
                
        // present with root container to allow rotation
        //
        [baseController presentModalViewController:composer animated:YES];
        [composer release];
    }
    else {
        // alert users that mail is not setup yet
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Compose Email Failure", @"Email - alert: inform of failure") 
                                                         message:NSLocalizedString(@"Email account setup is incomplete.", @"Email - alert: email account is not setup.")
                                                        delegate:nil
                                               cancelButtonTitle:@"OK" 
                                               otherButtonTitles:nil] autorelease];
        [alert show];
    }
}


#pragma mark - NSLocal Methods

/*! 
 @abstract gets country local information
 @discussion 
 
 @return two letter ISO country code.
 */
+ (NSString *)currentLocalCountryCode {
    
    NSLocale *currentLocale = [NSLocale currentLocale];
	NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    return countryCode;
}





#pragma mark - UIView Methods


/*!
 @abstract Gets image from the UIView
 */
+ (UIImage *) imageFromUIView:(UIView *)view {
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}


/**
 Remove subviews of UIView
 
 Arg:
 @param tag	integer tag of views to strip, if NSNotFound then remove all subviews
 
 Used:
 - when you want to make sure all subviews are removed
 
 */
+ (void) removeSubviewsForView:(UIView *)view tag:(NSInteger)tag {

	for (UIView *iView in view.subviews){
		if (tag != NSNotFound) {
			if (iView.tag == tag) {
				[iView removeFromSuperview];
			}
		}
		else {
			[iView removeFromSuperview];
		}
	}
}

/**
 Change highlight for subviews
 - only changes for child and grand children views and no later
 
 Arg:
 state		specify the desired highlight state: YES or NO
 
 Used:
 - help turn highlight of subviews on or off
 
 */
+ (void) setHighlightOfSubViewForView:(UIView *)view state:(BOOL)state {
	
	for (UIView *iView in [view subviews]){
		// if UIImageView, set highlighted
		if ([iView respondsToSelector:@selector(setHighlighted:)]) {
			[(UIImageView *)iView setHighlighted:state];
			// check one more layer down
			for (UIView *jView in [iView subviews]){
				// if UIImageView, set highlighted
				if ([jView respondsToSelector:@selector(setHighlighted:)]) {
					[(UIImageView *)jView setHighlighted:state];
				}
			}
		}
	}	
}

/**
 Adds UILabels to a base UIView.
 
 Useful to combine labels of different fonts and colors into a single line
 - if combined label lengths exceed the baseView then the last label added will get cut short!
 
 Usage:
 - used to show highlighted search text in phone nubmers for t9 keypad
 
 Parameters:
 @param	baseView		The view labels will be added to
 @param labelArray		NSArray of UILabels to be added
 @param textAlignment	UITextAlignmentRight or Left to push labels flush to either side of baseView
 */
+ (void) addLabelsToView:(UIView *)baseView labelArray:(NSArray *)newLabelArray textAlignment:(UITextAlignment)textAlignment {
	
	CGFloat baseHeight = baseView.frame.size.height;
	CGFloat baseWidth = baseView.frame.size.width;
	
	// start at 0.0 since no labels added
	//
	CGFloat currentWidth = 0.0;
	BOOL breakOut = NO;
	
	for (UILabel *iLabel in newLabelArray){
	
		CGFloat labelWidth = [iLabel.text sizeWithFont:iLabel.font].width;
		
		// if exceed length
		//
		if (currentWidth + labelWidth > baseWidth){
			labelWidth = baseWidth - currentWidth;
			breakOut = YES;
		}
		iLabel.frame = CGRectMake(currentWidth, 0.0, labelWidth, baseHeight);
		[baseView addSubview:iLabel];
	
		currentWidth = currentWidth + labelWidth;
		
		if (breakOut){
			break;
		}
	}
	
	// if did not break out and alight right, then push labels to the right
	//
	if (!breakOut && textAlignment == UITextAlignmentRight){
	
		CGFloat rightMargin = baseWidth - currentWidth;
		for (UILabel *iLabel in newLabelArray){
			iLabel.frame = CGRectOffset(iLabel.frame, rightMargin, 0.0);
		}
	}
}


/*!
 @abstract gets stretchableImage

 checks if ios5.0 method is available, since stretchableImageWithLeftCapWidth is deprecated in 5.0
 - 5.0 will use all cap settings
 - 4.0 will only use left and top cap settings
 
 */
+ (UIImage *)resizableImage:(UIImage *)image leftCapWidth:(CGFloat)leftCap rightCapWidth:(CGFloat)rightCap topCapHeight:(CGFloat)topCap bottomCapHeight:(CGFloat)bottomCap {

    if ([image respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
        return [image resizableImageWithCapInsets:UIEdgeInsetsMake(topCap, leftCap, bottomCap, rightCap)];
    }
    
    return [image stretchableImageWithLeftCapWidth:leftCap topCapHeight:topCap];
}

/*!
 @abstract gets stretchableImage
 
 Use this if image is symmetric, so only need to specify left and top caps
 
 */
+ (UIImage *)resizableImage:(UIImage *)image leftCapWidth:(CGFloat)leftCap topCapHeight:(CGFloat)topCap {
    return [self resizableImage:image leftCapWidth:leftCap rightCapWidth:leftCap topCapHeight:topCap bottomCapHeight:topCap];
}

#pragma mark - UIAlertView


/*!
 @abstract show a simple alert view with only an "OK" option
 
 Use:
 - for debugging and notifying users
 
 */
+ (UIAlertView *) showAlertViewWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate tag:(NSInteger)tag {
    
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:delegate
                                           cancelButtonTitle:NSLocalizedString(@"OK", @"Alert: OK button for alerts") 
                                           otherButtonTitles:nil] autorelease];
    if (tag) {
        alert.tag = tag;
    }
    [alert show];
    return alert;
}

/*!
 @abstract show a simple alert view with only an "OK" option
 
 Use:
 - for debugging and notifying users
 
 */
+ (void) showAlertViewWithTitle:(NSString *)title message:(NSString *)message {
    [Utility showAlertViewWithTitle:title message:message delegate:nil tag:0];
}

/*!
 @abstract Check if an alert with a specific tag is being shown
 
 Use:
 - to prevent the same alert from showing multiple times
 
 */
+ (BOOL) doesAlertViewExistWithTag:(NSUInteger)alertTag {
    for (UIWindow* window in [UIApplication sharedApplication].windows) {
        for (UIView* view in window.subviews) {
            BOOL alert = [view isKindOfClass:[UIAlertView class]];
            if (alert && view.tag == alertTag) {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark -
#pragma mark UILabel Methods

/**
 Resize the frame so that it fits the string used for this label
 
 Usage:
 
 Make sure you configure the label before using this method
 - frame size: the height will be adjusted, width will remain the same
 - font
 - lineBreakMode
 */
 
+ (void)setRightHeightForLabel:(UILabel *)label {
	
	CGSize maximumSize = CGSizeMake(label.frame.size.width, 9999.0f);
	CGSize labelSize = [label.text sizeWithFont:label.font 
												 constrainedToSize:maximumSize 
													 lineBreakMode:label.lineBreakMode];
	label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y, label.frame.size.width, labelSize.height);

}	   



#pragma mark -
#pragma mark TableView Methods

/**
 Helps you find the differences in the data model and tells you which rows need to be inserted or deleted
 
 Attribute:
 - compareSelector		selector that defines what should be compared
 - section				section number that this data belongs to
 - newDataArray			the new data model
 - oldDataArray			old data model
 - insertArray			paths to insert
 - deleteArray			paths to delete
 
 Usage:
 - used to help you figure out which rows to animate and how after changes are done
 
 */
+ (void) findTableDataModelChangesWithCompareSelector:(SEL)compareSelector section:(NSInteger)section newDataArray:(NSArray *)newDataArray oldDataArray:(NSArray *)oldDataArray insertArray:(NSMutableArray *)insertArray deleteArray:(NSMutableArray *)deleteArray {
	
	
	// Add row animation for any favorite changes
	// find difference between last data model and current model, then reload
	// * for every row in original and not in new array - add to delete array
	// * for every row in new and not in original - add to insert array
	//  + once we find a match, previous rows in new array are not considered
	//  + so if original row, finds a match in new but behind a previous new array match location, -- it does not count as a match
	// .. complex ... ^^
	
	
	//DDLogVerbose(@"%@", origArray);
	//DDLogVerbose(@"%@", newArray);
	
	NSInteger lastDestinationIndex = -1;
	
	// loop through old data
	for (NSUInteger o=0; o < [oldDataArray count]; o++) {
		BOOL found = NO;
		NSInteger foundIndex = 0;
		
		// loop though new data
		for (NSUInteger n=0; n < [newDataArray count]; n++) {
			
			// compare the two objects
			if ([[oldDataArray objectAtIndex:o] respondsToSelector:compareSelector] &&
				[[newDataArray objectAtIndex:n] respondsToSelector:compareSelector] ) {
				if ( [[[oldDataArray objectAtIndex:o] performSelector:compareSelector] isEqual:[[newDataArray objectAtIndex:n] performSelector:compareSelector]] ) {
					found = YES;
					foundIndex = n;
					break;
				}
			}
		}
		
		// if a match was found and is further down the list
		if (found == YES && foundIndex > lastDestinationIndex) {
			// add destination rows "not found in original rows" to insert array
			for (NSInteger i = lastDestinationIndex+1; i < foundIndex ; i++) {
				[insertArray addObject:[NSIndexPath indexPathForRow:i inSection:section]];
			}
			lastDestinationIndex = foundIndex;
		}
		// if no match found, add index to delete
		else {
			
			[deleteArray addObject:[NSIndexPath indexPathForRow:o inSection:section]];
		}
	}
	// add remaining destination array indexes to insert array
	for (NSInteger i = lastDestinationIndex+1; i < [newDataArray count]; i++) {
		[insertArray addObject:[NSIndexPath indexPathForRow:i inSection:section]];
	}
	
}


#pragma mark -
#pragma mark NSCopying Related Methods

// arrays need deep copy of each element
/*+ (NSMutableArray *)deepCopyOfArray:(NSArray *)oldArray
						   withZone:(NSZone *)zone {
	
	unsigned int count, max;
	id newChild;
	
	NSMutableArray *newArray = [[NSMutableArray alloc] init];
	
	max = [oldArray count];
	for (count = 0; count < max; count++)
    {
		newChild = [[oldArray objectAtIndex:count] copyWithZone: zone];
		[newArray addObject: newChild];
		[newChild release];
    }
	return newArray;
}*/


#pragma mark -
#pragma mark Sound and Vibration Methods

/*!
 @abstract Play short audio file

 @param filename of audio file e.g. "sent.caf"
 
 Note:
 - This can only accept caf, wav, aif files
 
 */
+ (void) asPlaySystemSoundFilename:(NSString *)filename {
    
    NSArray *fileParts = [filename componentsSeparatedByString:@"."];
    
    if ([fileParts count] == 2) {
        // Get the main bundle for the app
        CFBundleRef mainBundle = CFBundleGetMainBundle ();
        
        // Get the URL to the sound file to play. The file in this case
        // is "tap.aif"
        CFURLRef soundFileURLRef  = CFBundleCopyResourceURL (
                                                             mainBundle,
                                                             (CFStringRef) [fileParts objectAtIndex:0],
                                                             (CFStringRef) [fileParts objectAtIndex:1],
                                                             NULL
                                                             );
        SystemSoundID soundFileObject;
        
        // Create a system sound object representing the sound file
        AudioServicesCreateSystemSoundID (
                                          soundFileURLRef,
                                          &soundFileObject
                                          );
        
        AudioServicesPlaySystemSound (soundFileObject);

        if (soundFileURLRef != NULL) {
            CFRelease(soundFileURLRef);
        }
    }
}


/*!
 @abstract Play short audio file
 
 @param filename of audio file e.g. "sent.caf"
 @playbackMode YES if background music should be turned off
 
 Note:
 - This can only accept caf, wav, aif files
 
 */
+ (void) asPlaySystemSoundFilename:(NSString *)filename playbackMode:(BOOL)playbackMode {
    
    // setup audio
    NSError *audioError = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:&audioError];
    // set active
    //[session setActive:YES error:&audioError];
    
    [self asPlaySystemSoundFilename:filename];
    
    [session setCategory:AVAudioSessionCategoryAmbient error:&audioError];
    
}



// These don't work, need to play right away and you can't release right away
// so mem leak...
//
+ (AVAudioPlayer *)getAVAudioPlayerWithMp3Name:(NSString *)soundFileName {
	return [self getAVAudioPlayerWithMp3Name:soundFileName fileType:@"mp3" volume:1.0];
}


+ (AVAudioPlayer *)getAVAudioPlayerWithMp3Name:(NSString *)soundFileName fileType:(NSString *)fileType volume:(float)volume {
	
	NSError *avError = nil;
	
	NSString *audioFile = [NSString stringWithFormat:@"%@/%@.%@", [[NSBundle mainBundle] resourcePath], soundFileName, fileType];
	NSData *audioData = [NSData dataWithContentsOfMappedFile:audioFile];
	AVAudioPlayer *player = [[[AVAudioPlayer alloc] initWithData:audioData error:&avError] autorelease];
	
	/*
	NSString *path = [[NSBundle mainBundle] pathForResource:soundFileName ofType:fileType];
	AVAudioPlayer *player = [[[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&avError] autorelease];
	*/
	player.volume = volume;
	
	//DDLogVerbose(@"path:%@", path);

	if (avError) {
		DDLogVerbose(@"ERROR: AV-%@", avError);
	}
	
	return player;
	
	/* only wav files
	 SystemSoundID soundID;
	AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:path], &soundID);
	AudioServicesPlaySystemSound(soundID);*/
}

+ (AVAudioPlayer *)createAVAudioPlayerWithMp3Name:(NSString *)soundFileName fileType:(NSString *)fileType volume:(float)volume {
	
	NSError *avError = nil;
	
	NSString *audioFile = [NSString stringWithFormat:@"%@/%@.%@", [[NSBundle mainBundle] resourcePath], soundFileName, fileType];
	NSData *audioData = [NSData dataWithContentsOfMappedFile:audioFile];
	AVAudioPlayer *player = [[[AVAudioPlayer alloc] initWithData:audioData error:&avError] autorelease];
	
	/*
	 NSString *path = [[NSBundle mainBundle] pathForResource:soundFileName ofType:fileType];
	 AVAudioPlayer *player = [[[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&avError] autorelease];
	 */
	player.volume = volume;
	
	//DDLogVerbose(@"path:%@", path);
	
	if (avError) {
		DDLogVerbose(@"ERROR: AV-%@", avError);
	}
	
	return player;
	
	/* only wav files
	 SystemSoundID soundID;
	 AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:path], &soundID);
	 AudioServicesPlaySystemSound(soundID);*/
}

+ (void)vibratePhone {
	//only wav files
	 AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}


//
// Vibrate phone "vibrateCount" times and sleep "sleepSeconds" seconds in between
//
+ (void)vibratePhoneWithArguments:(NSDictionary *)argumentsD {

	NSUInteger vibrateCount = [[argumentsD objectForKey:@"vibrateCount"] intValue];
	float sleepSeconds = [[argumentsD objectForKey:@"sleepSeconds"] floatValue];
	BOOL continuous = [[argumentsD objectForKey:@"continuous"] boolValue];
	
	// continuous does not work... also may get your app rejected
	if (continuous){
		// sleep is used to specify how long to vibrate
		/*NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.05 
														  target:self
														selector:@selector(vibratePhone) 
														userInfo:nil 
														 repeats:YES];
		[NSThread sleepForTimeInterval:sleepSeconds];
		[timer invalidate];*/
	}
	else {
		for (int i = 0; i < vibrateCount; i++) {
			[Utility vibratePhone];
			[NSThread sleepForTimeInterval:sleepSeconds];
		}
	}
}


#pragma mark -
#pragma mark Graphics Methods

/**
 Gets color ref
 */
/*+ (CGColorRef) TTCopyDeviceRGBColorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a
{
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGFloat comps[] = {r, g, b, a};
    CGColorRef color = CGColorCreate(rgb, comps);
    CGColorSpaceRelease(rgb);
    return color;
}*/


/**
 Gets a bitmap context
 */
/*+ (CGContextRef)TTCopyBitmapContextWidth:(NSInteger)pixelsWide height:(NSInteger)pixelsHigh
{
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
	
    bitmapBytesPerRow   = (pixelsWide * 4);// 1
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
	
	colorSpace = CGColorSpaceCreateDeviceRGB();
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL)
    {
		DDLogVerbose(@"UT-CBCW: Memory not allocated!");
        //fprintf (stderr, "Memory not allocated!");
		CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    context = CGBitmapContextCreate (bitmapData,
									 pixelsWide,
									 pixelsHigh,
									 8,      // bits per component
									 bitmapBytesPerRow,
									 colorSpace,
									 kCGImageAlphaPremultipliedLast);
    if (context== NULL)
    {
        free (bitmapData);
		DDLogVerbose(@"UT-CBCW: Context not created!");
        //fprintf (stderr, "Context not created!");
		CGColorSpaceRelease(colorSpace);
        return NULL;
    }
	CGColorSpaceRelease(colorSpace);
    return context;
}*/



//
// NewPathWithRoundRect
//
// Creates a CGPathRect with a round rect of the given radius.
//
/*+ (CGPathRef)NewPathWithRect:(CGRect)rect
{
	//
	// Create the boundary path
	//
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, rect);

	return path;
}*/

//
// NewPathWithRoundRect
//
// Creates a CGPathRect with a round rect of the given radius.
//
/*+ (CGPathRef)NewPathWithRoundRect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius
{
	//
	// Create the boundary path
	//
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL,
					  rect.origin.x,
					  rect.origin.y + rect.size.height - cornerRadius);
	
	// Top left corner
	CGPathAddArcToPoint(path, NULL,
						rect.origin.x,
						rect.origin.y,
						rect.origin.x + rect.size.width,
						rect.origin.y,
						cornerRadius);
	
	// Top right corner
	CGPathAddArcToPoint(path, NULL,
						rect.origin.x + rect.size.width,
						rect.origin.y,
						rect.origin.x + rect.size.width,
						rect.origin.y + rect.size.height,
						cornerRadius);
	
	// Bottom right corner
	CGPathAddArcToPoint(path, NULL,
						rect.origin.x + rect.size.width,
						rect.origin.y + rect.size.height,
						rect.origin.x,
						rect.origin.y + rect.size.height,
						cornerRadius);
	
	// Bottom left corner
	CGPathAddArcToPoint(path, NULL,
						rect.origin.x,
						rect.origin.y + rect.size.height,
						rect.origin.x,
						rect.origin.y,
						cornerRadius);
	
	// Close the path at the rounded rect
	CGPathCloseSubpath(path);
	
	return path;
}*/

/**
 Return a rounded rectangle image
 
 mht: does not work quite right - corners look funny
 
 */
+ (UIImage *) roundedRectangleImage:(CGRect)rect strokeColor:(UIColor *)strokeColor rectColor:(UIColor *)rectColor 
				   strokeWidth:(CGFloat)strokeWidth cornerRadius:(CGFloat)cornerRadius {
    
	UIGraphicsBeginImageContext(rect.size);
	
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, strokeWidth);
    CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
    CGContextSetFillColorWithColor(context, rectColor.CGColor);
    
    CGRect rrect = rect;
    
    CGFloat radius = cornerRadius;
    CGFloat width = CGRectGetWidth(rrect);
    CGFloat height = CGRectGetHeight(rrect);
    
    // Make sure corner radius isn't larger than half the shorter side
    if (radius > width/2.0)
        radius = width/2.0;
    if (radius > height/2.0)
        radius = height/2.0;    
    
    CGFloat minx = CGRectGetMinX(rrect);
    CGFloat midx = CGRectGetMidX(rrect);
    CGFloat maxx = CGRectGetMaxX(rrect);
    CGFloat miny = CGRectGetMinY(rrect);
    CGFloat midy = CGRectGetMidY(rrect);
    CGFloat maxy = CGRectGetMaxY(rrect);
    CGContextMoveToPoint(context, minx, midy);
    CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
	
	UIImage *rrectViewImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return rrectViewImage;
}

/**
 Return a rectangle image
 */
+ (UIImage *) rectangleImage:(CGRect)rect 
				 strokeColor:(UIColor *)strokeColor 
				   rectColor:(UIColor *)rectColor 
				 strokeWidth:(CGFloat)strokeWidth {
	
	
	UIGraphicsBeginImageContext(rect.size);
	
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, strokeWidth);
    CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
    CGContextSetFillColorWithColor(context, rectColor.CGColor);
    
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    
	CGContextFillRect(context, CGRectMake(0.0, 0.0, width, height));
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}

/**
 Create rectangle or ellipse
 */
+ (UIImage *) rectangleImage:(CGRect)rect 
				 strokeColor:(UIColor *)strokeColor 
				   rectColor:(UIColor *)rectColor 
				 strokeWidth:(CGFloat)strokeWidth 
				   isEllipse:(BOOL)isEllipse {
	
	
	UIGraphicsBeginImageContext(rect.size);
	
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, strokeWidth);
    CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
    CGContextSetFillColorWithColor(context, rectColor.CGColor);
    
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
	CGRect drawRect = CGRectMake(0.0, 0.0, width, height);
    if (isEllipse) {
		CGContextFillEllipseInRect(context, drawRect);
	}
	else {
		CGContextFillRect(context, drawRect);
	}
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}

/**
 Creates a rounded rectangle image
 
 
 */
/*+ (UIImage *) roundedRectangleImage:(CGRect)rect cornerRadius:(CGFloat)cornerRadius fillColor:(UIColor *)fillColor {
	
	UIGraphicsBeginImageContext(rect.size);

	//CGRect buttonRect = CGRectMake(0.0, 0.0, 100.0, 50.0);
	
	// Replace the contents of drawRect with the following:
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, rect);
	
	//CGColorRef outerTop = [UIColor clearColor].CGColor;
	//UIColor *buttonColor = [UIColor colorWithRed:0.22 green:0.208 blue:0.212 alpha:1.0];
	
	//CGColorRef shadowColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.5].CGColor;
	
	CGFloat outerMargin = 0.0f;
	CGRect outerRect = CGRectInset(rect, outerMargin, outerMargin);
	CGMutablePathRef outerPath = createRoundedRectForRect(outerRect, cornerRadius);
	
	CGContextSaveGState(context);
	//CGContextSetFillColorWithColor(context, outerTop);
	//CGContextSetShadowWithColor(context, CGSizeMake(0, 2), 3.0, shadowColor);
	//CGContextAddPath(context, outerPath);
	//CGContextFillPath(context);
	[fillColor setFill];
	CGContextAddPath(context, outerPath);
	CGContextFillPath(context);
	CGContextRestoreGState(context);
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}*/



@end
