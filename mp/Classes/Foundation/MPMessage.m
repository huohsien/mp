//
//  MPMessage.m
//  mp
//
//  Created by M Tsai on 11-9-1.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "MPMessage.h"
#import "MPFoundation.h"
#import "MPChatManager.h"
#import "MPDataScrambler.h"


const int kMessageHeaderLength = 1;  // length plus @ - e.g. "XXXXX@"



// define message types
NSString* const kMPMessageTypeLogin = @"login";
NSString* const kMPMessageTypeLogout = @"logout";
NSString* const kMPMessageTypeSent = @"sent";
NSString* const kMPMessageTypeDelivered = @"delivered";
NSString* const kMPMessageTypeRead = @"read";
NSString* const kMPMessageTypeAccept = @"accept";
NSString* const kMPMessageTypeReject = @"reject";
NSString* const kMPMessageTypeInput = @"input";


// message content
NSString* const kMPMessageTypeChat = @"chat";
NSString* const kMPMessageTypeGroupChat = @"gchat";
NSString* const kMPMessageTypeGroupChatLeave = @"leavegchat";
NSString* const kMPMessageTypeImage = @"image";
NSString* const kMPMessageTypeAudio = @"audio";
NSString* const kMPMessageTypeVideo = @"video";
NSString* const kMPMessageTypeFile = @"file";
NSString* const kMPMessageTypeContact = @"contact";
NSString* const kMPMessageTypeCall = @"call";
NSString* const kMPMessageTypeLocation = @"location";

// container message
NSString* const kMPMessageTypeMultimsg = @"multimsg";


NSString* const kMPMessageTypeHeadShot = @"headshot";
NSString* const kMPMessageTypeNickname = @"nickname";
NSString* const kMPMessageTypeFindFriends = @"findfriends";
NSString* const kMPMessageTypePresence = @"presence";

// schedule message
NSString* const kMPMessageTypeSchedule = @"schedule";          // schedule sent confirmation
NSString* const kMPMessageTypeScheduleDelete = @"deleteschedule";    // delete a schedule message

// special network message
NSString* const kMPMessageNetworkPing = @"@ping";
NSString* const kMPMessageNetworkAck = @"@ack?";




// define message keys
NSString* const kMPMessageKeyID = @"id";
NSString* const kMPMessageKeyFrom = @"from";
NSString* const kMPMessageKeyTo = @"to";
NSString* const kMPMessageKeySequence = @"seq";
NSString* const kMPMessageKeyAttachLength = @"attachlength";
NSString* const kMPMessageKeyCause = @"cause";
NSString* const kMPMessageKeyGroupID = @"groupid";
NSString* const kMPMessageKeyText = @"text";

NSString* const kMPMessageKeyFilename = @"filename";
NSString* const kMPMessageKeyDomain = @"domain";
NSString* const kMPMessageKeyFromAddress = @"fromaddr";
NSString* const kMPMessageKeyOperator = @"operator";
NSString* const kMPMessageKeyLanguage = @"language";
NSString* const kMPMessageKeySentTime = @"senttime";
NSString* const kMPMessageKeyIcon = @"icon";
NSString* const kMPMessageKeyCommand = @"command";
NSString* const kMPMessageKeyLetter = @"letter";


// text & group msg params
NSString* const kMPMessageKeySticker = @"sticker";

// group chat params
NSString* const kMPMessageKeyAction = @"action";
NSString* const kMPMessageKeyEnter = @"enter";
NSString* const kMPMessageKeyWithoutPN = @"WithoutPN";
NSString* const kMPMessageKeyWithPN = @"WithPN";
NSString* const kMPMessageKeyWithoutQueue = @"WithoutQueue";



// scheduled message
NSString* const kMPMessageKeySchedule = @"schedule";
NSString* const kMPMessageKeyScheduleTime = @"time";



// login keys
NSString* const kMPMessageKeyAppVersion = @"appversion";
NSString* const kMPMessageKeyDeviceModel = @"devicemodel";

// logout keys
NSString* const kMPMessageKeyBadgeCount = @"BADGECOUNT";


// keys for address components
NSString* const kMPMessageKeyUserID = @"userid";
NSString* const kMPMessageKeyNickName = @"nickname";



@implementation MPMessage

@synthesize mType;
@synthesize mID;
@synthesize groupID;
@synthesize to;
@synthesize from;
@synthesize text;
@synthesize sequence;
@synthesize attachLength;
@synthesize cause;
@synthesize properties;
@synthesize attachmentData;
@synthesize previewImageData;




- (void) dealloc {
    [mType release];
    [mID release];
    [groupID release];
    [to release];
    [from release];
    [text release];
    [sequence release];
    [properties release];
    [attachmentData release];
    [previewImageData release];
    
    [super dealloc];
}

/*!
 */
- (NSString *)description {
    NSString *basicInfo = [NSString stringWithFormat:@"=====\nMessageType: %@\nmID: %@\ngroupID: %@\nto: %@\nfrom: %@\nseq: %@\nattLen: %d\ncause: %d\n properties: %@\ntext: %@\n", self.mType, self.mID, self.groupID, self.to, self.from, self.sequence, self.attachLength, self.cause, self.properties, self.text];
    return  basicInfo;
}

/*!
 getter for dictionary
 */
- (NSMutableDictionary *)properties {
    if (properties){
        return properties;
    }
    
    properties = [[NSMutableDictionary alloc] init];
    return properties;
}

#pragma mark - General Message Processing Methods

/*!
 @abstract initiates a message given parameters
 
 Use
 - to create a message from CDMessage, etc.
 
 */
- (id) initWithID:(NSString *)msgID 
             type:(NSString *)type 
          groupID:(NSString *)aGroupID 
               to:(NSArray *)toArray 
             from:(NSString *)fromString 
             text:(NSString *)textString
         sequence:(NSString *)sequenceString 
       attachData:(NSData *)attachData 
      previewData:(NSData *)preData
         filename:(NSString *)filename {
    
    if ((self = [super init])) {
        self.mID = msgID;
        
        self.mType = type;
        self.groupID = aGroupID;
        self.to = toArray;
        self.from = fromString;
        self.text = textString;
        self.sequence = sequenceString;
        self.cause = NSNotFound;
        // if preview image exists add it
        if (preData) {
            self.previewImageData = preData;
        }
        // add attachment data
        if (attachData) {
            self.attachmentData = attachData;
            self.attachLength = [attachData length];
        }        
        [self.properties setValue:filename forKey:kMPMessageKeyFilename];
        
	}
	return self;
}


/*!
 @abstract generates unique ID for new messages
 
 id:message id (fix 22 bytes) , generated by sender , to identify each message flow .
 yyyymmdd(8) + USERID(8) + serialnumber(6) e.g. 2011082328260333000001
 
 - get counter from setting center
 - use counter and increment
 - update to message center
 
 */
- (void) generateID {
        
    // set ID
    self.mID = [AppUtility generateMessageID];
    
    // initialize other attributes
    //
    self.attachLength = NSNotFound;
    self.cause = NSNotFound;
    
}


/*!
 @abstract decodes parameters from DS messages
 
 * Slash encoding is used so that DS will not mistake these for it's control chars
 * URL encoding is necessary to communicate between DS & PS - usally for user defined params: nickname, status, etc.
 
 1. Slash decode first
 Replace \? \= \+ \& with ?=+&
 
 2. URL decode second
 
 */
+ (NSString *)decodeDSParameter:(NSString *)rawString {
    
    // slash decode
    NSString *decodedString = [rawString stringByReplacingOccurrencesOfString:@"\\?" withString:@"?"];
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"\\=" withString:@"="];
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"\\+" withString:@"+"];
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"\\&" withString:@"&"];
    
    // URL decode
    decodedString = [decodedString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return decodedString;
    
}

/*!
 @abstract encode parameters to DS messages
 
 1. URL encode

 2. Slash encode
 Replace \? \= \+ \& with ?=+&
 
 
 */
+ (NSString *)encodeDSParameter:(NSString *)rawString {
    
    NSString *encodedString = [Utility stringByAddingPercentEscapeEncoding:rawString];
    
    /*
    // URL encode
    NSString *encodedString = [rawString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    // slash encode
    encodedString = [encodedString stringByReplacingOccurrencesOfString:@"?" withString:@"\\?"];
    encodedString = [encodedString stringByReplacingOccurrencesOfString:@"=" withString:@"\\="];
    encodedString = [encodedString stringByReplacingOccurrencesOfString:@"+" withString:@"\\+"];
    encodedString = [encodedString stringByReplacingOccurrencesOfString:@"&" withString:@"\\&"];
     */
    
    return encodedString;
}


/*!
 @abstract Converts "to string" to an array of separate "to addresses"
 - strips + from nicknames
 */
+ (NSArray *) getToAddressArray:(NSString *)toString {
    
    // if string contains +
    if ([toString rangeOfString:@"+"].location != NSNotFound) {
        
        // make sure [nicknames] don't have + signs!
        // - 0[1]2[3]4, so clean up the even components
        //
        NSCharacterSet *splitChars = [NSCharacterSet characterSetWithCharactersInString:@"[]"];
        NSArray *components = [toString componentsSeparatedByCharactersInSet:splitChars];
        
        NSMutableArray *newComponents = [[NSMutableArray alloc] initWithCapacity:[components count]];
        
        for (int i = 0; i < [components count]; i++) {
            
            NSString *compString = [components objectAtIndex:i];
            // even index are not modified
            //
            if (i%2 == 0) {
                [newComponents addObject:compString];
            }
            // odd components are nicknames
            // - strip possible + signs
            else {
                NSString *newNick = [NSString stringWithFormat:@"[%@]", [compString stringByReplacingOccurrencesOfString:@"+" withString:@""]];
                [newComponents addObject:newNick];
            }
        }
        NSString *newToString = [newComponents componentsJoinedByString:@""];
        [newComponents release];
        return [newToString componentsSeparatedByString:@"+"];
        
    }
    // just a single address
    else {
        return [NSArray arrayWithObject:toString];
    }
    
}


/*!
 @abstract Break up data into components if this is a multi message otherwise just return array with one data object
 
 Note:
 - multimsg itself is returned as the last message (w/ only it's messageID property).
   ~ this is used to send an @sent reply message with
 
 */
+ (NSArray *) subDataComponents:(NSData *)data {
    
    NSInteger dataLength = [data length];
    
    NSMutableArray *datas = [[[NSMutableArray alloc] init] autorelease];
    
    NSString *multiMsg = [NSString stringWithFormat:@"@%@?", kMPMessageTypeMultimsg];
    NSData *multiMsgData = [multiMsg dataUsingEncoding:NSUTF8StringEncoding];

    NSRange mutiRange = [data rangeOfData:multiMsgData options:NSDataSearchAnchored range:NSMakeRange(0, dataLength)];

    if (mutiRange.location != NSNotFound){
        
        NSData *msgData = [@"&msg=" dataUsingEncoding:NSUTF8StringEncoding];
        NSRange msgRange = [data rangeOfData:msgData options:0 range:NSMakeRange(0, dataLength)];
        
        if (msgRange.location != NSNotFound){
            
            // range of multimsg itself
            NSRange multiMessageRange = NSMakeRange(0, msgRange.location);
            
            NSInteger startLocation = msgRange.location + msgRange.length;
            
            while (startLocation != NSNotFound && startLocation < dataLength) {
                
                // read in 5 digit length
                NSRange lenRange = NSMakeRange(startLocation, 5);
                NSData *lenData = [data subdataWithRange:lenRange];
                NSString *lenString = [[NSString alloc] initWithData:lenData encoding:NSUTF8StringEncoding];
                NSInteger length = [lenString integerValue];
                [lenString release];
                
                // read in data
                //
                NSRange iDataRange =  NSMakeRange(startLocation+5, length);
                NSInteger dataEndLocation = iDataRange.location+iDataRange.length;
                
                if (dataEndLocation <= dataLength) {
                    [datas addObject:[data subdataWithRange:iDataRange]];
                    startLocation = dataEndLocation;
                }
                else {
                    startLocation = NSNotFound;
                }
            }
            
            // add multimsg itself last
            NSData *multiMessageData = [data subdataWithRange:multiMessageRange];
            [datas addObject:multiMessageData];
        }
        
    }
    // only single message
    else {
        [datas addObject:data];
    }
    
    DDLogInfo(@"Msg-sdc: got %d messages", [datas count]);
    return datas;
}


/*!
 @abstract Get data string and extract icon attachment from message
 
 @param data            Data to decode and extract icon from
 @param stringEncoding  How to decode this string
 @param mpMessage       New message to attach the image data to
 
 @return dataString     Decoded nsstring of data
 */
+ (NSString *) dataStringFor:(NSData *)data stringEncoding:(NSStringEncoding)stringEncoding mpMessage:(MPMessage *)mpMessage {
    
    NSString *dataString = nil;
    
    NSString *iconKey = [NSString stringWithFormat:@"&%@=", kMPMessageKeyIcon];
    NSData *iconKeyData = [iconKey dataUsingEncoding:stringEncoding];
    NSRange iconRange = [data rangeOfData:iconKeyData options:0 range:NSMakeRange(0, [data length])];
    if (iconRange.location != NSNotFound){
        // skip 6 chars "&icon="
        NSUInteger imageStartLocation = iconRange.location + 6;
        NSRange imageRange = NSMakeRange(imageStartLocation, [data length] - imageStartLocation);
        mpMessage.previewImageData = [data subdataWithRange:imageRange];
        
        // read in just the start
        dataString = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, imageStartLocation)] encoding:NSUTF8StringEncoding] autorelease];
    }
    // read in whole data if preview image does not exists
    else {
        dataString = [[[NSString alloc] initWithData:data encoding:stringEncoding] autorelease];
    }
    return dataString;
}


/*!
 @abstract constructs a new message given raw data from the network
 
 @discussion This method will scan through the message looking for special reserved characters
 such as: ?,=,&.  While scanning, the method will store the message types and key value pairs
 that it encounters.  
 
 Note: escaped chracters are ignored since they are considered part of the content.  The content
 will then be \Decoded.  e.g., \& \? \= \+
 
 @return autoreleased MPMessage that represents network message
 
 - ignore message length
 - message type
 - read in key and values
   ~ handle each property: save as attribute or into properties dictionary
 
 example:
 
 00061@login?id=2011082328260333000001&from=20121312&to=1020345
 
 */
+ (MPMessage *)messageWithData:(NSData *)data {

    
    // create a MPMessage object
    //
    MPMessage *mpMessage = [[[MPMessage alloc] init] autorelease];
    
    NSString *dataString = nil;
    
    // search for preview "icon" key
    // - create the icon image
    //
    dataString = [MPMessage dataStringFor:data stringEncoding:NSUTF8StringEncoding mpMessage:mpMessage];
    
    // fail over to ASCII
    if (dataString == nil) {
        DDLogWarn(@"Msg-mwd: UTF8 decoding failed! fall back on ASCII");
        dataString = [MPMessage dataStringFor:data stringEncoding:NSASCIIStringEncoding mpMessage:mpMessage];
    }
    
    // debug
    DDLogInfo(@"Msg-mwd: got message %@", dataString);
    
    // ignore message length section
    // - get rid of extra header bytes
    //
    NSString *newDataString = [dataString substringWithRange:NSMakeRange(kMessageHeaderLength, [dataString length]-kMessageHeaderLength)];

    
    // stores the start of the next interested string value
    // - once a special characters is encountered, these index will the demarkation point
    //   for the string that we want.
    //
    NSInteger startIndex = 0;
    
    // stores the keyString
    // - that is associated with the current value
    //
    NSString *keyString = nil;
    NSString *valueString = nil;
    
    //BOOL foundText = NO;
    
    NSCharacterSet *dsSpecialChars = [NSCharacterSet characterSetWithCharactersInString:@"&+=?"];
    
    // scan through entire string
    //
    for (NSUInteger currentIndex=0; currentIndex < [newDataString length]; currentIndex++) {
        
        unichar currentChar = [newDataString characterAtIndex:currentIndex];

        unichar nextChar;
        
        switch (currentChar) {
                
            // '\' if escape encountered, then ignore then next character!
            case 0x005C:
                
                // what is next char
                nextChar = [newDataString characterAtIndex:(currentIndex+1)];
                // if a ds special char then skip it
                if ([dsSpecialChars characterIsMember:nextChar]) {
                    currentIndex++;
                }
                break;
                
            // if message type encountered
            // - don't overwrite if another ? encountered
            //
            case '?':
                if (!mpMessage.mType) {
                    mpMessage.mType = [newDataString substringWithRange:NSMakeRange(startIndex, currentIndex-startIndex)];
                    // reset the start index
                    startIndex = currentIndex+1;
                }
                break;
                
            // if key encountered
            case '=':
                keyString = [newDataString substringWithRange:NSMakeRange(startIndex, currentIndex-startIndex)];
                // reset the start index
                startIndex = currentIndex+1;
                
                // mark if text string - this should be last element
                /*if ([keyString isEqualToString:kMPMessageKeyText]) {
                    foundText = YES;
                }*/
                break;
                
            // if value encountered, also need \decode it
            case '&':
                valueString = [newDataString substringWithRange:NSMakeRange(startIndex, currentIndex-startIndex)];
                // reset the start index
                startIndex = currentIndex+1;
                
                valueString = [MPMessage decodeDSParameter:valueString];
                
                if ([keyString length] > 0 && [valueString length] > 0) {
                    [mpMessage.properties setValue:valueString forKey:keyString];
                }
                keyString = nil;
                valueString = nil;
                break;
                
            default:
                break;
        }

        // Don't assume "text=" is the always the last parameter!
        //
        //if (foundText || currentIndex == [newDataString length]-1) {
        
        // if LAST character, read until the end and break for loop
        //
        if (currentIndex == [newDataString length]-1) {

            valueString = [newDataString substringWithRange:NSMakeRange(startIndex, [newDataString length]-startIndex)];
            
            valueString = [MPMessage decodeDSParameter:valueString];

            
            if ([keyString length] > 0 && [valueString length] > 0) {
                [mpMessage.properties setValue:valueString forKey:keyString];
            }
            keyString = nil;
            valueString = nil;
            break;  // break for loop
        }
        
    }
    
    // generate special attributes from keyValue pairs
    
    
    // get message id
    //
    valueString = [mpMessage.properties valueForKey:kMPMessageKeyID];
    
    if ([valueString length] > 0) {
        mpMessage.mID = valueString;
    }
    
    // get group id
    //
    valueString = [mpMessage.properties valueForKey:kMPMessageKeyGroupID];
    
    if ([valueString length] > 0) {
        mpMessage.groupID = valueString;
    }
    
    // get from field
    //
    valueString = [mpMessage.properties valueForKey:kMPMessageKeyFrom];
    
    if ([valueString length] > 0) {
        mpMessage.from = valueString;
    }
    
    // get to field
    //
    valueString = [mpMessage.properties valueForKey:kMPMessageKeyTo];
    
    if ([valueString length] > 0) {
        // careful
        // TODO: need to account for + in the wrong place (in nick name)
        /*
         to=00000141[Min%20Y]@192.168.1.120{61.66.229.120:80}+00000136[huiyi+HTC]@192.168.1.120{61.66.229.120}
         */
        
        mpMessage.to = [self getToAddressArray:valueString]; //[valueString componentsSeparatedByString:@"+"];
    }
    
    // get text field
    //
    valueString = [mpMessage.properties valueForKey:kMPMessageKeyText];
    
    if ([valueString length] > 0) {
        mpMessage.text = valueString;
    }
    
    // get seq field
    //
    valueString = [mpMessage.properties valueForKey:kMPMessageKeySequence];
    
    if ([valueString length] > 0) {
        mpMessage.sequence = valueString;
    }
    
    // get attachlength field
    //
    valueString = [mpMessage.properties valueForKey:kMPMessageKeyAttachLength];
    
    if ([valueString length] > 0) {
        mpMessage.attachLength = [valueString integerValue];
    }
    
    // get cause field
    //
    valueString = [mpMessage.properties valueForKey:kMPMessageKeyCause];
    
    if ([valueString length] > 0) {
        mpMessage.cause = [valueString integerValue];
    }
    
    // get preview image data
    //
    /*valueString = [mpMessage.properties valueForKey:kMPMessageKeyIcon];
    if ([valueString length] > 0) {
        mpMessage.previewImageData = [valueString dataUsingEncoding:NSUTF8StringEncoding];
    }*/
    
    return mpMessage;
}


+ (NSArray *)messagesWithData:(NSData *)data {
    
    // Check if multimessage and create array of data objects
    NSArray *datas = [MPMessage subDataComponents:data];
    
    NSMutableArray *messages = [[[NSMutableArray alloc] initWithCapacity:[datas count]] autorelease];
    
    for (NSData *iData in datas) {
        
        MPMessage *iMessage = [MPMessage messageWithData:iData];
        if (iMessage) {
            [messages addObject:iMessage];
        }
    }
    return messages;
}


/*!
 @abstract Generate message to address string "<to+to>"
 
 @return nil if failed
 
 */
- (NSString *) toAddressString {
    
    if ([self.to count] > 0) {
        
        NSMutableArray *toArray = [[NSMutableArray alloc] initWithCapacity:[self.to count]];
        for (NSString *iString in self.to){
            [toArray addObject:iString];
        }
        NSString *toString = [toArray componentsJoinedByString:@"+"];
        [toArray release];
        
        return toString;
    }
    return nil;
}

/*!
 @abstract create raw data from this message
 
 @discussion Create a the NSData object from this message object.  This used to send
 messages over the network.
 
 @return NSData representation suitable for net transmission
 
 - construct the string using object properties
 - prepend message length to the start of the message
 - convert to NSData
 
 example:
 00061@login?id=2011082328260333000001&from=20121312&to=1020345
 
 addresses:
 10021233[Beer]@61.66.229.110
 

 */
- (NSData *)rawNetworkData {
    
    NSMutableString *workingString = [[NSMutableString alloc] init];
    
    // append type to message - "@type?"
    //
    [workingString appendFormat:@"@%@?", self.mType];
    
    // append id - "id=mid"
    // - block delivered message don't have mID defined
    //
    if ([self.mID length] > 0) {
        [workingString appendFormat:@"%@=%@",kMPMessageKeyID, self.mID];
    }
    
    // append timestamp
    //
    [workingString appendFormat:@"&timestamp=%@", [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] ] ];
    
    
    // append from - "&from=<from>"
    // - to & from are not encoded since it is already done by before hand
    if ([self.from length] > 0) {
        [workingString appendFormat:@"&%@=%@", kMPMessageKeyFrom, self.from];
    }
    
    NSString *toString = [self toAddressString];
    if (toString) {
        [workingString appendFormat:@"&%@=%@", kMPMessageKeyTo, toString];
    }
    
    // append groupid - "&groupid=<groupid>"
    if ([self.groupID length] > 0) {
        [workingString appendFormat:@"&%@=%@", kMPMessageKeyGroupID, self.groupID];
    }
    
    
    // append seq
    //
    if ([self.sequence length] > 0){
        [workingString appendFormat:@"&%@=%@", kMPMessageKeySequence, self.sequence];
    }
    
    // append attachlength
    //
    if (self.attachLength != NSNotFound && self.attachLength != 0){
        [workingString appendFormat:@"&%@=%d", kMPMessageKeyAttachLength, self.attachLength];
    }
    
    // append cause
    //
    if (self.cause != NSNotFound){
        [workingString appendFormat:@"&%@=%d", kMPMessageKeyCause, self.cause];
    }
    
    // append dictionary values
    //
    NSArray *keys = [self.properties allKeys];
    NSString *valueString = nil;
    for (NSString *iKey in keys){
        valueString = [self.properties valueForKey:iKey];
        if ([iKey length] > 0 && [valueString length] > 0) {
            
            // don't encode icon preview for headshots - otherwise crash
            if ([iKey isEqualToString:kMPMessageKeyIcon]) {
                [workingString appendFormat:@"&%@=%@", iKey, valueString];
            }
            // don't encode enter addresses
            else if ([iKey isEqualToString:kMPMessageKeyEnter]) {
                [workingString appendFormat:@"&%@=%@", iKey, valueString];
            }
            else {
                [workingString appendFormat:@"&%@=%@", iKey, [MPMessage encodeDSParameter:valueString]];

            }
        }
    }
    
    
    // append text - "&text=<text>"
    // - must go at the end! since it is allowed to include reserved characters
    //
    if ([self.text length] > 0) {
        [workingString appendFormat:@"&%@=%@", kMPMessageKeyText, [MPMessage encodeDSParameter:self.text]];
    }
    // Andriod needs us to sent this parameter otherwise it can't parse this message
    else if ([self.text isEqualToString:@""]) {
        [workingString appendFormat:@"&%@=", kMPMessageKeyText];
    }
    
    // append icon data
    // - could this contain special characeters??
    // - add this last since we also need to append data to the end
    //
    if (self.previewImageData){
        [workingString appendFormat:@"&%@=", kMPMessageKeyIcon];
    }

    // merge msg and preview data
    //
    NSMutableData *workingData = [[NSMutableData alloc] initWithData:[workingString dataUsingEncoding:NSUTF8StringEncoding]];
    if (self.previewImageData) {
        [workingData appendData:self.previewImageData];
    }

    NSUInteger workingLength = [workingData length];
    
    // if working length is greater than 40000 log this
    if (workingLength > 40000) {
        DDLogError(@"Msg-rnd: over max length! %d", workingLength);
    }
    
    NSData *lengthData = nil;
    
    NSString *lenghString = [NSString stringWithFormat:@"%05d", workingLength];
    DDLogInfo(@"Msg-rnd: Sending MSG: %@%@", lenghString, workingString);
    [workingString release];
    
    if (kMPParamNetworkEnableDataScrambling) {
        DDLogInfo(@"Msg-rnd: scram - Encode Msg Length %d",workingLength);

        lengthData = [MPDataScrambler encodeLengthHeader:workingLength];
        [workingData setData:[MPDataScrambler encodeMessage:workingData length:workingLength encodeLength:lengthData]];
    }
    else {
        lengthData = [lenghString dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    NSMutableData *messageData = [[[NSMutableData alloc] initWithData:lengthData] autorelease];
    [messageData appendData:workingData];
    [workingData release];
    
    // if attachment exists also append to the end
    //
    if (self.attachLength > 0 && [self.attachmentData length] > 0) {
        [messageData appendData:self.attachmentData];
    }
    
    return messageData;
}



/*!
 @abstract encodes a M+ address string
 */
- (NSString *)encodeAddressString:(NSString *)addressString {
    
    NSCharacterSet *splitChars = [NSCharacterSet characterSetWithCharactersInString:@"[]"];
    NSArray *addressArray = [addressString componentsSeparatedByCharactersInSet:splitChars];
    
    if ([addressArray count] == 3) {
        
        NSString *encodeString = [NSString stringWithFormat:@"%@[%@]%@", 
                                  [addressArray objectAtIndex:0],
                                  [MPMessage encodeDSParameter:[addressArray objectAtIndex:1]],
                                  [addressArray objectAtIndex:2]];
        
        return encodeString;
    }
    // if other than 3 parts - we don't know what to do, so just return the same string back w/o encoding
    // - normally should only be userID@domain, so encoding is not needed
    else {
        return addressString;
    }
}

/*!
 @abstract takes M+ address string and parses it into a dictionary
 
 @return success - dictionary, nil - invalid address string
 
 e.g. 00000071[beer]@192.168.1.110{61.66.229.110}
 
 - nickname is optional []
 - domain server is optional {}
 
 */
- (NSDictionary *) getAddressDictionary:(NSString *)addressString {
    
    NSMutableDictionary *toDictionary = [[[NSMutableDictionary alloc] initWithCapacity:4] autorelease];
    
    
    NSString *newUserID = nil;
    NSString *newNickname = nil;
    NSString *newFrom = nil;
    NSString *newDomain = nil;
    
    NSInteger startBraketIndex = [addressString rangeOfString:@"["].location;
    NSInteger endBraketIndex = [addressString rangeOfString:@"]" options:NSBackwardsSearch].location;
    NSInteger mouseIndex = [addressString rangeOfString:@"@" options:NSBackwardsSearch].location;
    NSInteger startCurlyIndex = [addressString rangeOfString:@"{" options:NSBackwardsSearch].location;
    NSInteger endCurlytIndex = [addressString rangeOfString:@"}" options:NSBackwardsSearch].location;

    // if brackets exists then save nickname and userID
    //
    if (startBraketIndex != NSNotFound && endBraketIndex != NSNotFound) {
        newUserID = [addressString substringToIndex:startBraketIndex];
        
        // strip away special characters, just in case
        NSString *rawNick = [addressString substringWithRange:NSMakeRange(startBraketIndex+1, endBraketIndex - startBraketIndex-1)];
        //DDLogInfo(@"rn:**%@**", rawNick);
        newNickname = [AppUtility stripNickName:rawNick];
    }
    else if (mouseIndex != NSNotFound) {
        newUserID = [addressString substringToIndex:mouseIndex];
    }
    
    // save from and domain addresses
    if (startCurlyIndex != NSNotFound && endCurlytIndex != NSNotFound) {
        newFrom = [addressString substringWithRange:NSMakeRange(mouseIndex+1, startCurlyIndex - mouseIndex-1)];
        newDomain = [addressString substringWithRange:NSMakeRange(startCurlyIndex+1, endCurlytIndex - startCurlyIndex-1)];
    }
    else if (mouseIndex != NSNotFound) {
        newFrom = [addressString substringFromIndex:mouseIndex+1];
    }

    if (newUserID) {
        [toDictionary setObject:newUserID forKey:kMPMessageKeyUserID];
    }
    if (newNickname) {
        [toDictionary setObject:newNickname forKey:kMPMessageKeyNickName];
    }
    if (newFrom) {
        [toDictionary setObject:newFrom forKey:kMPMessageKeyFromAddress];
    }
    if (newDomain) {
        [toDictionary setObject:newDomain forKey:kMPMessageKeyDomain];
    }
    
    
    
    if ([toDictionary count] == 0) {
        DDLogError(@"Msg-gad: empty dictionary add:%@", addressString);
        return nil;
    }
    
    
    if (![AppUtility isUserIDValid:[toDictionary valueForKey:kMPMessageKeyUserID]]) {
        DDLogError(@"Msg-gad: invalid userid add:%@", addressString);
        return nil;
    }
    
    // checks addresss
    // - assumes: 61.66.229.120 or abc.abc.com
    NSArray *fromArray = [[toDictionary valueForKey:kMPMessageKeyFromAddress] componentsSeparatedByString:@"."];
    NSArray *domainArray = [[toDictionary valueForKey:kMPMessageKeyDomain] componentsSeparatedByString:@"."];

    // both addresses must fail
    if ([fromArray count] < 3 && [domainArray count] < 3) {
        DDLogError(@"Msg-gad: invalid fromAddress add:%@", addressString);
        return nil;
    }
    return toDictionary;
}

/*!
 @abstract extract ToContacts information
 
 @return array of contact dictionaries - keys are kMPMessageKeys, 
 nil if invalid address found - you should also cancel what you were doing since this is corrupt address
 
 NSString   kMPMessageKeyUserID
 NSString   kMPMessageKeyNickName
 NSString   kMPMessageKeyDomain
 NSString   kMPMessageKeyFromAddress
 
 Use
 - used to find which contacts this message is for
 
 Example:
 userID[nickname]@server  - for chat text
 userID[nickname]@cluster - for attachments
 
 */
- (NSArray *)toContactsDictionaries {
    
    NSMutableArray *contacts = [[[NSMutableArray alloc] init] autorelease];
    
    for (NSString *iTo in self.to){
        
        NSDictionary *toDictionary = [self getAddressDictionary:iTo];
        if (toDictionary != nil) {
            [contacts addObject:toDictionary];
        }
        // bad to addressses are just ignored
        
    }
    return contacts;
}



/*!
 @abstract extract FromContact information
 
 @return a contact dictionaries - keys are kMPMessageKeys
 nil if invalid address found - you should also cancel what you were doing since this is corrupt address
 
 NSNumber   kMPMessageKeyUserID
 NSString   kMPMessageKeyNickName
 NSString   kMPMessageKeyDomain
 NSString   kMPMessageKeyFromAddress
 
 Use
 - used to find which contacts this message is from
 
 Example:
 userID[nickname]@server  - for chat text
 userID[nickname]@cluster - for attachments
 
 */
- (NSDictionary *)fromContactsDictionary {
    
    NSDictionary *fromDictionary = [self getAddressDictionary:self.from];
    
    return fromDictionary;
}





/*!
 @abstract generate a delivered reply message from this message
 
 @param messageType this determine message type.  Should be kMPMessageTypeDelivered or Read
 
 e.g.
 @<message type>?id=x&from=B&to=A
 - use same message ID
 - from self to all participants
 
 */
- (MPMessage *)generateReplyWithMessageType:(NSString *)messageType {
    
    NSString *myUserID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    
    // configure addresses
    //
    NSMutableArray *toArray = [[NSMutableArray alloc] init];
    NSString *fromString = nil;
    NSString *groupIDString = nil;
    NSString *sequenceString = nil;
    
    // Don't need all these parameters for 
    // - sent replies
    // - gchat delivered messages
    //
    if (![messageType isEqualToString:kMPMessageTypeSent] &&
        !([self.mType isEqualToString:kMPMessageTypeGroupChat] && [messageType isEqualToString:kMPMessageTypeDelivered]) 
        ) 
    {
        
        groupIDString = self.groupID;
        sequenceString = self.sequence;
        
        // only need to send to the source user
        [toArray addObject:[self encodeAddressString:self.from]];
        
        for (NSString *iAddress in self.to){
            // if self - add to from address
            //
            if ([iAddress hasPrefix:myUserID]) {
                fromString = [self encodeAddressString:iAddress];
            }
            // add rest of contacts to string
            /*else {
             [toArray addObject:iAddress];
             }*/
        }
    }
    
    
    
    
    MPMessage *replyMessage = [[[MPMessage alloc] initWithID:self.mID type:messageType groupID:groupIDString to:toArray from:fromString text:nil sequence:sequenceString attachData:nil previewData:nil filename:nil] autorelease];
    [toArray release];
    
    return replyMessage;
}





#pragma mark - Query Methods


/*!
 @abstract get value for non-core properties stored in the properties dictionary
 */
- (NSString *)valueForProperty:(NSString *)messageKey {
    
    return [self.properties valueForKey:messageKey];
    
}

/*!
 @abstract gets the domain cluster name using the "from" key info

 usage:
 - used to get domain cluster to form download string
 
 Example:
 10021233[Beer]@61.66.229.110

 */
- (NSString *)senderDomainClusterName {
    
    NSArray *toks = [self.from componentsSeparatedByString:@"@"];
    if ([toks count] > 1) {
        return [toks objectAtIndex:1];
    }
    return nil;
}


/*!
 @abstract Gets userID of the sender
 
 Use:
 - check from sender to see if this leave message is related to the groupID specified
 */
- (NSString *) senderUserID {
    
    NSDictionary *fromD = [self fromContactsDictionary];
    return [fromD valueForKey:kMPMessageKeyUserID];

}

/*!
 @abstract gets downloadURL for this message
 
 downloadURL
 
 http://xx.xx.xx.xx/downloadxxxxx?from=A&to=B&filename=xxxx.xx(&offset=xxxx) xx.xx.xx.xx :	the (virtual) domain address of sender’s Domain Server downloadxxxx : download type : e,g, downloadimage , downloadaudio, downloadvideo , downloadcontact
 downloadheadshot .... from :	receiver’s USERID
 to :	sender’s(file owner) USERID filename :	the filename (from sender) to be downloaded offset : (optional : default=0) is the start download position (in bytes) of the download file .
 
 */
- (NSString *)downloadURL {
    /*
    // only create for certain types
    //
    NSString *filename = [self.properties valueForKey:kMPMessageKeyFilename];
    
    NSString *downloadURL = nil;
    
    if (filename) {
        downloadURL = [NSString stringWithFormat:@"http://%@/download%@?from=%@to%@&filename=%@", 
                       [self senderDomainClusterName], self.mType, self.from, self.to, filename];
    }
    return downloadURL;
     */
    return nil;  // invalid
}


/*!
 @abstract Is this message from myself
 
 @discussion This means that this message was created locally
 
 Check if "from" starts with my user ID
 
 */
- (BOOL) isFromSelf {
    
    NSString *userID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    if ([self.from hasPrefix:userID]) {
        return YES;
    }
    return NO;

}

/*!
 @abstract gets the NSDate when message was sent
 
 @return date if successful, nil if no date
 
 */
- (NSDate *)sentDate {
    
    NSDate *sentDate = nil;
    
    NSInteger sentTime = [[self.properties valueForKey:kMPMessageKeySentTime] integerValue];
    //DDLogVerbose(@"in senttime: %d", sentTime);
    if (sentTime) {
        sentDate = [NSDate dateWithTimeIntervalSince1970:sentTime];
    }
    // try looking at scheduled senttime param: "time=xx"
    else {
        sentTime = [[self.properties valueForKey:kMPMessageKeyScheduleTime] integerValue];
        //DDLogVerbose(@"in senttime: %d", sentTime);
        if (sentTime) {
            sentDate = [NSDate dateWithTimeIntervalSince1970:sentTime];
        }
    }
    return sentDate;
}

/*!
 @abstract get sequence number
 */
- (NSNumber *)sequenceNumber {
    
    // default 1
    NSNumber *seqNum = [NSNumber numberWithInt:1];
    
    NSArray *sequenceToks = [self.sequence componentsSeparatedByString:@"/"];
    if ([sequenceToks count] == 2 ) {
        NSInteger sequenceNumber = [[sequenceToks objectAtIndex:0] integerValue];
        
        if (sequenceNumber) {
            seqNum = [NSNumber numberWithInt:sequenceNumber];
        }
    }
    return seqNum;
}

/*!
 @abstract get the total number of messages in this sequence
 */
- (NSNumber *)sequenceTotal {
    
    // default of 1 - so no sequence
    NSNumber *seqTotal = [NSNumber numberWithInt:1];
    
    NSArray *sequenceToks = [self.sequence componentsSeparatedByString:@"/"];
    if ([sequenceToks count] == 2 ) {
        NSInteger sequenceNumber = [[sequenceToks objectAtIndex:1] integerValue];
        
        if (sequenceNumber) {
            seqTotal = [NSNumber numberWithInt:sequenceNumber];
        }
    }
    return seqTotal;
}


/*!
 @abstract is message type is related to chat content?
 
 Use:
 - determine how to route and handle this message
 
 */
- (BOOL) isChatContentType {
    
    NSArray *contentTypes = [NSArray arrayWithObjects:kMPMessageTypeChat, kMPMessageTypeGroupChat, kMPMessageTypeImage, kMPMessageTypeAudio, kMPMessageTypeVideo, kMPMessageTypeContact, kMPMessageTypeLocation, nil];

    NSInteger foundIndex = [contentTypes indexOfObject:self.mType];
    if (foundIndex != NSNotFound) {
        return YES;
    }
    return NO;
    
    /*
    if ([self.mType isEqualToString:kMPMessageTypeChat] || 
        [self.mType isEqualToString:kMPMessageTypeGroupChat] ||
        [self.mType isEqualToString:kMPMessageTypeImage] || 
        [self.mType isEqualToString:kMPMessageTypeAudio] || 
        [self.mType isEqualToString:kMPMessageTypeVideo] || 
        [self.mType isEqualToString:kMPMessageTypeContact]) {
        return YES;
    }
    return NO;*/
}


/*!
 @abstract is message type a chat message state update
 
 Use:
 - determine how to route and handle this message
 
 */
- (BOOL) isChatStateUpdate {
    
    NSArray *contentTypes = [NSArray arrayWithObjects:kMPMessageTypeSent, kMPMessageTypeDelivered, kMPMessageTypeRead, kMPMessageTypeSchedule, kMPMessageTypeMultimsg, nil];
    
    NSInteger foundIndex = [contentTypes indexOfObject:self.mType];
    if (foundIndex != NSNotFound) {
        return YES;
    }
    return NO;
}

/*!
 @abstract is message type affects the chat dialog state: @input msges
 
 Use:
 - determine how to route and handle this message
 - for typing now messages
 
 */
- (BOOL) isChatDialogUpdate {
    
    NSArray *contentTypes = [NSArray arrayWithObjects:kMPMessageTypeInput, nil];
    
    NSInteger foundIndex = [contentTypes indexOfObject:self.mType];
    if (foundIndex != NSNotFound) {
        return YES;
    }
    return NO;
}


#pragma mark - Message Factory Methods


/*!
 @abstract Generates a login message

 @return login MPMessage including userID and authentication key
 
 example:

 xxxxx@login?id=x&from=y&to=z&appversion=xx.xx&devicemodel=www-xxx-yyy-zzz&cause=1
 
 @login? : login Domain Server 
  xxxxx: indicate the length of @login message ( from @ to z )
  id : message id – generated by sender , total 22 bytes , rule : 
  from : USERID 
  to: akey : from http response <akey>1020345</akey>
  appversion: version of app.
  devicemodel: model of device : www-xxx-yyy-zzz
  www : OS : android or ios 
  xxx : OS version 
  yyy : hardware manufacture : eg. htc , 
  zzz : hardware model 
  cause: reason of login : 1=normal login   3=resume of previous suspend logout
 
 e.g.: 00091@login?id=2011082328260333000001&from=20121312&to=1020345&appversion=1.01
        &devicemodel=android-2.2-htc-hero&cause=1
 

 */
+ (MPMessage *)messageLoginIsSuspend:(BOOL)isSuspend {
    
    MPMessage *mpMessage = [[[MPMessage alloc] init] autorelease];
    [mpMessage generateID];
    
    mpMessage.mType = kMPMessageTypeLogin;
    mpMessage.from = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    
    NSString *authKey = [[MPSettingCenter sharedMPSettingCenter] secureValueForID:kMPSettingAuthKey];
    if (authKey) {
        mpMessage.to = [NSArray arrayWithObject:authKey];
    }
    else {
        DDLogVerbose(@"Msg-login: missing authkey!");
    }
    
    // 1 is normal login
    // 3 is resume from suspend
    //
    if (isSuspend) {
        mpMessage.cause = 3;
    }
    else{
        mpMessage.cause = 1;
    }
    
    NSString *deviceModel = [AppUtility getDeviceModel];
    NSString *language = [AppUtility devicePreferredLanguageCode];

    [mpMessage.properties setValue:[AppUtility getAppVersion] forKey:kMPMessageKeyAppVersion];
    [mpMessage.properties setValue:deviceModel forKey:kMPMessageKeyDeviceModel];
    [mpMessage.properties setValue:language forKey:@"LANGUAGE"];
    
    return mpMessage;
}


/*!
 @abstract Generates a logout message
 
 @return login MPMessage including userID and authentication key
 
 e.g.: 
 - send:    @logout?id=x&cause=0
 - recv:    @sent?id=x
 - recv:    @accept?id=x
 
 cause: reason of logout :	1=normal logout, 2= suspend logout
 
 Note: 
 - for now we always send cause = 2, since it is hard to predict when a normal logout will really occur
   Ideally, when user power offs(?), app terminates(possible), etc. 
 
 */
+ (MPMessage *)messageLogoutIsSuspend:(BOOL)isSuspend {
    
    MPMessage *mpMessage = [[[MPMessage alloc] init] autorelease];
    [mpMessage generateID];
    
    mpMessage.mType = kMPMessageTypeLogout;
    
    if (isSuspend) {
        mpMessage.cause = 2;
    }
    else{
        mpMessage.cause = 1;
    }
    
    // send logout message with the proper unread message count
    // - so notification server will have the right number
    // - used cache since we just called it to set the local badge count
    // ** This is old total unread method
    //NSUInteger unreadCount = [[MPChatManager sharedMPChatManager] totalUnreadMessagesUseCache:YES];
    //[mpMessage.properties setValue:[NSString stringWithFormat:@"%d", unreadCount] forKey:kMPMessageKeyBadgeCount];
    
    // ** Use new method - always set to zero after leaving app
    //
    [mpMessage.properties setValue:@"0" forKey:kMPMessageKeyBadgeCount];

    
    return mpMessage;
}


/*!
 @abstract Creates the users's headshot message
 
 Example:
 @headshot?id=x&attachlength=98304&filename=myhead.jpg&icon=small_data......attach_large_data.......
 
 */
+ (MPMessage *)messageHeadshotSmallImage:(UIImage *)smallImage largeImage:(UIImage *)largeImage{
    
    MPMessage *mpMessage = [[[MPMessage alloc] init] autorelease];
    [mpMessage generateID];
    
    mpMessage.mType = kMPMessageTypeHeadShot;
    
    NSString *userID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    NSString *fileName = [AppUtility headShotFilenameForUserID:userID];
    
    // Use small jpeg instead of PNG
    mpMessage.previewImageData = UIImageJPEGRepresentation(smallImage, 0.8);
    NSData *largeData = UIImageJPEGRepresentation(largeImage, 0.8);
    
    //mpMessage.previewImageData = UIImagePNGRepresentation(smallImage);
    //NSData *largeData = UIImagePNGRepresentation(largeImage);
    
    mpMessage.attachmentData = largeData;
    mpMessage.attachLength = [mpMessage.attachmentData length];
    [mpMessage.properties setValue:fileName forKey:kMPMessageKeyFilename];
    
    DDLogInfo(@"Msg: s:%d l:%d", [mpMessage.previewImageData length], [largeData length]);
    return mpMessage;
}




/*!
 @abstract Creates a delete schedule message request
 
 2. Delete a scheduled message :
 
 2.1 Client send to DS :
 @deleteschedule?id=2012011700000035395846
 
 2.2 DS reply client :
 @accept?id=2012011700000035395846  (or) @reject?id=2012011700000035395846  //while not found ! 

 
 */
+ (MPMessage *)deleteScheduleMessage:(NSString *)messageID {
    
    MPMessage *mpMessage = [[[MPMessage alloc] init] autorelease];

    mpMessage.mID = messageID;
    mpMessage.mType = kMPMessageTypeScheduleDelete;
    
    return mpMessage;
}



/*!
 @abstract Create dummy delivered feedback for blocked messages
 
 - format: @delivered?
 - DS needs this so it knows we got the message ok and that it does not need to queue this message.
 
 */
+ (MPMessage *)deliveredMessageForBlocked {
    
    MPMessage *mpMessage = [[[MPMessage alloc] init] autorelease];
    mpMessage.mType = kMPMessageTypeDelivered;
    mpMessage.cause = NSNotFound;
    return mpMessage;
}

/*!
 @abstract Create dummy delivered feedback for schedule message
 
 - format: @delivered?id=xxxx
 - DS needs this so it knows we got the message ok and that it does not need to queue this message.
 
 */
+ (MPMessage *)deliveredMessageDummyWithID:(NSString *)aMessageID {
    
    MPMessage *mpMessage = [[[MPMessage alloc] init] autorelease];
    mpMessage.mID = aMessageID;
    mpMessage.mType = kMPMessageTypeDelivered;
    mpMessage.cause = NSNotFound;
    return mpMessage;
}



#pragma mark - Test Methods


/*!
 @abstract Generates an outgoing text chat message and multicast chat 
 
 @return text chat MPMessage
 
 example:
 @chat?id=xxxx&to=xxx&from=10021233[Beer]@61.66.229.110&text=xxxx
 
 multicast example:
 @chat?id=xxxx&to=xxx+yyy+zzz&from=10021233[Beer]@61.66.229.110&text=xxxx
 
 */
+ (MPMessage *)messageChatTo:(NSString *)toString textMessage:(NSString *)messageString {
    
    MPMessage *mpMessage = [[[MPMessage alloc] init] autorelease];
    [mpMessage generateID];
    
    mpMessage.mType = kMPMessageTypeChat;
    
    NSString *userID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    NSString *nickname = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingNickName];
    NSString *domainIP = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingDomainServerName];
    
    mpMessage.from = [NSString stringWithFormat:@"%@[%@]@%@", userID, [MPMessage encodeDSParameter:nickname], domainIP];
    mpMessage.to = [toString componentsSeparatedByString:@"+"];
    mpMessage.text = messageString;
    
    return mpMessage;
}

/*!
 @abstract Generates a nickname update
 
 @return text nickname MPMessage
 
 example:
 @nickname?id=x&text=Beer
 
 */
+ (MPMessage *)messageNickname {
    
    MPMessage *mpMessage = [[[MPMessage alloc] init] autorelease];
    [mpMessage generateID];
    
    mpMessage.mType = kMPMessageTypeNickname;
    NSString *nickname = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingNickName];
    mpMessage.text = nickname;
    
    return mpMessage;
}


/*!
 @abstract Queries for friends

 @discussion Includes logic to append country code if needed. International number are ones that start with '+'.
 The rest are considered local numbers... is this a universal rule? exceptions?
 
 @param phoneNumbers array of phone numbers (assume all non functional chars are stripped except '+')
 @return MPMessage

 
 example:
 
 id : message id
 text : concatenation of phone numbers or USERID : p1+p2+....+pN 
 
 e.g. : @findfriends? id=2011082328260333000001&text=88691122334455+886988776655+......+1935638040
 
 */
+ (MPMessage *)messageFindFriends:(NSArray *)phoneNumbers {
    
    NSString *countryCode = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPhoneCountryCode];
    NSUInteger ccLength = [countryCode length];
    
    NSMutableArray *findPhones = [[NSMutableArray alloc] init];
    
    for (NSString *iNumber in phoneNumbers){
        
        // if international, strip out + sign and add
        //
        if ([iNumber hasPrefix:@"+"]) {
            [findPhones addObject:[iNumber stringByReplacingOccurrencesOfString:@"+" withString:@""]];
        }
        // if phone is not international, prepend my country code
        //
        else {
            // number should be max 15 digits
            if ([iNumber length] + ccLength < 16 ) {
                NSString *noZeroNumber = [AppUtility stripZeroPrefixForString:iNumber];
                [findPhones addObject:[NSString stringWithFormat:@"%@%@", countryCode, noZeroNumber]];
            }
            // for long numbers, maybe already include cc
            else {
                DDLogVerbose(@"MPM-mff: WARN - number not added for find friends! %@", iNumber);
            }
        }
    }
    
    
    MPMessage *mpMessage = [[[MPMessage alloc] init] autorelease];
    [mpMessage generateID];
    
    //NSArray *friendNumbers = [NSArray arrayWithObjects:@"886928260333", @"886981693193", @"886911222333", @"886922333444", nil];
    
    mpMessage.mType = kMPMessageTypeFindFriends;
    mpMessage.text = [findPhones componentsJoinedByString:@"+"];  //[friendNumbers componentsJoinedByString:@"+"];
    [findPhones release];
    
    return mpMessage;
}

/*!
 @abstract group chat message
 */
+ (MPMessage *)messageGroupChat {
    
    MPMessage *mpMessage = [[[MPMessage alloc] init] autorelease];
    [mpMessage generateID];
    
    mpMessage.mType = kMPMessageTypeGroupChat;
    
    NSString *userID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    NSString *nickname = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingNickName];
    NSString *server = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingDomainServerName];
    
    mpMessage.groupID = mpMessage.mID;
    mpMessage.from = [NSString stringWithFormat:@"%@[%@]@%@", userID, [MPMessage encodeDSParameter:nickname], server];
    mpMessage.to = [NSArray arrayWithObjects:@"10000001@61.66.229.110", @"10000002@61.66.229.110", nil];
    mpMessage.text = @"test group chat from iPhone";
    
    return mpMessage;
}


/*!
 @abstract sends a image attachement
 
 example:
 @image?id=x&to=B&from=A&...&filename=yy.jpg&attachlength=201336....
 
 */
+ (MPMessage *)messageImage:(UIImage *)image {
    
    MPMessage *mpMessage = [[[MPMessage alloc] init] autorelease];
    [mpMessage generateID];
    
    mpMessage.mType = kMPMessageTypeImage;
    
    NSString *userID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    NSString *nickname = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingNickName];
    NSString *cluster = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingDomainClusterName];
    
    mpMessage.groupID = mpMessage.mID;
    mpMessage.from = [NSString stringWithFormat:@"%@[%@]@%@", userID, [MPMessage encodeDSParameter:nickname], cluster];
    mpMessage.to = [NSArray arrayWithObjects:@"10000001@61.66.229.110", @"10000002@61.66.229.110", nil];
    mpMessage.text = @"test group chat text";
    
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    mpMessage.attachmentData = imageData;
    mpMessage.attachLength = [mpMessage.attachmentData length];
    [mpMessage.properties setValue:[NSString stringWithFormat:@"%@.jpg",mpMessage.mID] forKey:kMPMessageKeyFilename];
    
    return mpMessage;
    
}

/*!
 message for testing
 */
+ (MPMessage *)messageTest {
    
    MPMessage *mpMessage = [[[MPMessage alloc] init] autorelease];
    [mpMessage generateID];
    
    mpMessage.mType = @"test";
    //NSString *nickname = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingNickName];
    mpMessage.text = @"test text";
    
    return mpMessage;
}

@end
