//
//  TextEmoticonView.m
//  mp
//
//  Created by Min Tsai on 1/10/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "TextEmoticonView.h"
#import "MPResourceCenter.h"
#import "MPFoundation.h"

//unichar const kTEImageChar = 0xFFFC; // iOS 6.0 will draw this out as a square
unichar const kTEImageChar = 0x0000;


CGFloat const kTEFontThreshold = 15.0;

CGFloat const kTEImageSizeMed = 25.0;
CGFloat const kTEImageSizeSmall = 15.0;

static NSString* const kTEDataDetectorLinkKey = @"kTEDataDetectorLinkKey";
static NSString* const kTEDataDetectorPhoneNumberKey = @"kTEDataDetectorPhoneNumberKey";
static NSString* const kTEDataDetectorDateKey = @"kTEDataDetectorDateKey";
static NSString* const kTEDataDetectorAddressKey = @"kTEDataDetectorAddressKey";
static NSString* const kTELinkAttributeName = @"kTELinkAttributeName";


static inline CTTextAlignment CTTextAlignmentFromUITextAlignment(UITextAlignment alignment) {
	switch (alignment) {
		case UITextAlignmentLeft: return kCTLeftTextAlignment;
		case UITextAlignmentCenter: return kCTCenterTextAlignment;
		case UITextAlignmentRight: return kCTRightTextAlignment;
		default: return kCTNaturalTextAlignment;
	}
}

static inline CTLineBreakMode CTLineBreakModeFromUILineBreakMode(UILineBreakMode lineBreakMode) {
	switch (lineBreakMode) {
		case UILineBreakModeWordWrap: return kCTLineBreakByWordWrapping;
		case UILineBreakModeCharacterWrap: return kCTLineBreakByCharWrapping;
		case UILineBreakModeClip: return kCTLineBreakByClipping;
		case UILineBreakModeHeadTruncation: return kCTLineBreakByTruncatingHead;
		case UILineBreakModeTailTruncation: return kCTLineBreakByTruncatingTail;
		case UILineBreakModeMiddleTruncation: return kCTLineBreakByTruncatingMiddle;
		default: return 0;
	}
}


@interface TextEmoticonView () <UIGestureRecognizerDelegate>

@property (nonatomic, copy) dispatch_block_t tapRecognizedBlock;

@end



@implementation TextEmoticonView

@synthesize tapRecognizedBlock = _tapRecognizedBlock;
@synthesize selectedTextRange = _selectedTextRange;

@synthesize needsFrameSetter;
@synthesize viewString;
@synthesize imageArray;
@synthesize imageIndexes;

@synthesize attributedString;

@synthesize verticalAlignment;
@synthesize textAlignment;
@synthesize numberOfLines;
@synthesize lineBreakMode;
@synthesize font;
@synthesize textColor;
@synthesize highlightedTextColor;

@synthesize tappedDataObject;
//@synthesize removeSelectionTimer;

/*
 */
- (void) dealloc {
    
    // release if it exits
    if (ctFrameSetter != NULL) {
        CFRelease(ctFrameSetter);
        ctFrameSetter = NULL;
    }
    
    if(_graphicsContext != NULL)
    {
        CGContextRelease(_graphicsContext);
        _graphicsContext = NULL;
    }
    
    if(_ctFrame != NULL)
    {
        CFRelease(_ctFrame);
        _ctFrame = NULL;
    }
    
    if(_tapRecognizedBlock != nil) {
        Block_release(_tapRecognizedBlock);
        _tapRecognizedBlock = nil;
    }
    
    
    [font release];
    [textColor release];
    [highlightedTextColor release];
    [attributedString release];
    
    [viewString release];
    [imageArray release];
    [imageIndexes release];
    
    [tappedDataObject release];
    //[removeSelectionTimer release];
    [super dealloc];
}

/*!
 @abstract provides the size that just encloses the available text
 */
/*
 - (CGSize)sizeThatFits:(CGSize)size {
 
 // update this view frame to shrink to fit text
 NSArray *lines = (NSArray *)CTFrameGetLines(ctFrame);
 NSUInteger lineCount = [lines count];
 CGPoint lastLineOrigin = CGPointZero;
 CTFrameGetLineOrigins(ctFrame, CFRangeMake(lineCount-1, 1), &lastLineOrigin);
 //CGFloat lastLineHeight = 0.0;
 
 CGFloat largestWidth = 0.0;
 for (int i=0; i < lineCount; i++) {
 
 CTLineRef thisLine = (CTLineRef)[lines objectAtIndex:i];
 CFRange lineRange = CTLineGetStringRange(thisLine);
 CGFloat charOffset = 0.0;
 CTLineGetOffsetForStringIndex(thisLine, lineRange.location+lineRange.length-1, &charOffset);
 CGFloat lineWidth = charOffset;
 if (lineWidth > largestWidth) {
 largestWidth = lineWidth;
 }
 
 // if last line
 if (i == lineCount - 1) {
 CGFloat ascending = 0.0;
 CGFloat decending = 0.0;
 CTLineGetTypographicBounds(thisLine, &ascending, &decending, NULL);
 lastLineHeight = ascending + decending;
 }
 }
 CGSize newSize = CGSizeMake(largestWidth, self.frame.size.height - lastLineOrigin.y);
 [self setNeedsDisplay];
 return newSize;
 }*/


/* 
 Callbacks 
 
 Sets spacing for emoticons.  If parameters are modified the emoticon images may not show up properly.
 Make sure you test with just emoticon only (without text).  This is a special condition.
 
 */
void deallocationCallback( void* refCon ){
    
}
CGFloat getAscentCallbackMed( void *refCon ){
    return 20.0;
}
CGFloat getDescentCallbackMed( void *refCon ){
    return 5.0;
}
CGFloat getWidthCallbackMed( void* refCon ){
    return 25.0;
}

CGFloat getAscentCallbackSmall( void *refCon ){
    return 14.0; 
}
CGFloat getDescentCallbackSmall( void *refCon ){
    return 3.0;  
}
CGFloat getWidthCallbackSmall( void* refCon ){
    return 17.0; 
}


- (void)setGraphicsContext:(CGContextRef)context
{
    if(context != NULL && context != _graphicsContext)
    {
        if(_graphicsContext != NULL)
        {
            CGContextRelease(_graphicsContext);
        }
        
        _graphicsContext = CGContextRetain(context);
    }
}


/*!
 @abstract inits this view
 @param frame
 - set origin to 0.0, 0.0 to start with, this will help calculate the height of this view!
 - frame width is considered maximum width, however this can be reduced if the text is not that long.
 - height will be reduced to fit the number of lines required. 
 * So after creating this view you will need to set it to the correct origin!
 
 @param textImageArray - array of alternating UIImage and NSStrings
 
 */
- (id)initWithFrame:(CGRect)frame
{
    
    self = [super initWithFrame:frame];
    if (self) {
        
        // default values
        
        // also determines if we provide data detection!
        self.userInteractionEnabled = NO;
        
        self.verticalAlignment = TETextVerticalAlignmentCenter;
        self.textAlignment = UITextAlignmentLeft;
        self.numberOfLines = 0;
        self.lineBreakMode = UILineBreakModeWordWrap;
        self.textColor = [UIColor blackColor];
        
        self.font = [UIFont systemFontOfSize:15.0];
        
        [self setBackgroundColor:[UIColor clearColor]];
        
        
        // Build string and image arrays
        NSMutableString *newString = [[NSMutableString alloc] init];
        self.viewString = newString;
        [newString release];
        
        NSMutableArray *newArray = [[NSMutableArray alloc] init];
        self.imageArray = newArray;
        [newArray release];
        
        NSMutableArray *rangeArray = [[NSMutableArray alloc] init];
        self.imageIndexes = rangeArray;
        [rangeArray release];
        
        // add tap recognizer
        //
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(receivedTap:)];
        tap.delegate = self;
        [self addGestureRecognizer:tap];
        [tap release];
        
    }
    return self;
}


/*!
 @abstract Getter that creates a frame setter
 */
- (CTFramesetterRef)ctFrameSetter {
    if (self.needsFrameSetter) {
        @synchronized(self) {
            
            if (ctFrameSetter != NULL) {
                CFRelease(ctFrameSetter);
            }
            
            ctFrameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.attributedString);
            
            self.needsFrameSetter = NO;
        }
    }
    
    return ctFrameSetter;
}



#pragma mark - Set Text



/*!
 @abstract Creates and caches a shared data detector
 
 - one is created for each thread
 - cached since it is very expensive to init
 
 */
+ (NSDataDetector *)dataDetector
{
    NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
    NSDataDetector *detector = [dictionary objectForKey:@"TextEmoticonViewDataDetector"];
    
    if (!detector)
    {
        NSError* error = NULL;
        detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink|NSTextCheckingTypePhoneNumber
                                                   error:&error];
        NSAssert(error == nil, @"Problem creating the link detector: %@", [error localizedDescription]);
        
        [dictionary setObject:detector forKey:@"TextEmoticonViewDataDetector"];
    }
    return detector;
}



/*!
 @abstract Adds attributes for data types found
 
 */
- (void)dataDetectorPassInRange:(NSRange)range withAttributedString:(NSMutableAttributedString *)thisAttributedString
{
    if (!self.userInteractionEnabled) {
        return;
    }
    
	NSDataDetector* detector = [TextEmoticonView dataDetector];
    
	NSString* string = [thisAttributedString string];
    
	[detector enumerateMatchesInString:string options:0 
                                 range:range 
                            usingBlock:^(NSTextCheckingResult* match, NSMatchingFlags flags, BOOL* stop) 
     {
         NSRange matchRange = [match range];
         
         // No way to call into Calendar, so don't detect dates
         if([match resultType] != NSTextCheckingTypeDate)
         {
             //UIColor *linkColor = (_linkColor != nil) ? _linkColor : [UIColor blueColor];
             UIColor *linkColor = [UIColor blueColor];
             
             //This sentinel attribute will tell us that this is a link.
             [thisAttributedString addAttribute:kTELinkAttributeName
                                          value:[NSNull null]
                                          range:matchRange];
             
             [thisAttributedString addAttribute:(NSString*)kCTForegroundColorAttributeName 
                                          value:(id)linkColor.CGColor
                                          range:matchRange];
             
             //if(_shouldUnderlineLinks) {
             if (YES) {
                 [thisAttributedString addAttribute:(NSString*)kCTUnderlineStyleAttributeName 
                                              value:[NSNumber numberWithInt:kCTUnderlineStyleSingle] 
                                              range:matchRange];
             }
         }
         switch([match resultType])
         {
             case NSTextCheckingTypeLink:
             {
                 NSURL* url = [match URL];
                 [thisAttributedString addAttribute:kTEDataDetectorLinkKey value:url range:matchRange];
                 break;
             }
             case NSTextCheckingTypePhoneNumber:
             {
                 NSString* phoneNumber = [match phoneNumber];
                 [thisAttributedString addAttribute:kTEDataDetectorPhoneNumberKey value:phoneNumber range:matchRange];
                 break;
             }
             case NSTextCheckingTypeAddress:
             {
                 NSDictionary* addressComponents = [match addressComponents];
                 [thisAttributedString addAttribute:kTEDataDetectorAddressKey value:addressComponents range:matchRange];
                 break;
             }
             case NSTextCheckingTypeDate:
             {
                 //NSDate* date = [match date];
                 //[self.attributedText addAttribute:kJTextViewDataDetectorDateKey value:date range:matchRange];
                 break;
             }
         }
     }];
}






/*!
 @abstract Sets the text string for the view
 
 @param enableDataDetection should we parse text to find phone, web, and email links
 
 */
-(void)setText:(NSString *)text enableDataDetection:(BOOL)enableDataDetection
{
    // DDLogVerbose(@"TE: setting new Text:%@", text);
    // parse text into resource elements
    //
    NSArray *msgElements = [[MPResourceCenter sharedMPResourceCenter] parseText:text];
    
    // clear out values
    [self.viewString setString:@""];
    [self.imageArray removeAllObjects];
    [self.imageIndexes removeAllObjects];
    
    // Insert special char to mark location of emoticons
    // - get image object
    // - add marker to string
    // - store index of the marker in the string
    for (id arrayItem in msgElements) {
        if ([arrayItem isKindOfClass:[NSString class]]) {
            [self.viewString appendString:(NSString *)arrayItem];
        }
        else if ([arrayItem isKindOfClass:[UIImage class]]) {
            [self.imageArray addObject:arrayItem];
            [self.viewString appendFormat:@"%C", kTEImageChar];
            [self.imageIndexes addObject:[NSNumber numberWithInt:[self.viewString length]-1]];
        }
    }
    
    // setup Font
    CTFontRef bubbleFont = NULL;
    bubbleFont = CTFontCreateUIFontForLanguage(kCTFontSystemFontType, [self.font pointSize], NULL);
    
    /*
     iOS 5.0 & 5.1 has a bug in CoreText and uses bold text instead of normal font.
     - Set the correct font manually here
     - Note this is only fixed if local language is set to TW or CN
     
     NSString *langCode = [AppUtility devicePreferredLanguageCode];
     if ([langCode isEqualToString:@"zh"]) {
     bubbleFont = CTFontCreateWithName(CFSTR("STHeitiTC-Light"), [self.font pointSize], NULL);
     }
     else if ([langCode isEqualToString:@"cn"]) {
     bubbleFont = CTFontCreateWithName(CFSTR("STHeitiSC-Light"), [self.font pointSize], NULL);
     }
     else {
     bubbleFont = CTFontCreateUIFontForLanguage(kCTFontSystemFontType, [self.font pointSize], NULL);
     }
     
     Design team likes the bold font better even though this is an apple bug
     */
    
    // setup paragraph style
    CTTextAlignment newAlignment = CTTextAlignmentFromUITextAlignment(self.textAlignment);
    
    // use word wrap if multiple lines
    // - take care of last line later
    //
    CTLineBreakMode newLineBreakMode;
    newLineBreakMode = CTLineBreakModeFromUILineBreakMode(UILineBreakModeWordWrap);
    
    /* 
     Don't set truncate for single lines here.  This results in blank lines for some Zh text!
     - However truncating in drawRect: works fine for the same Zh text.
     
     if (self.numberOfLines != 1) {
     newLineBreakMode = CTLineBreakModeFromUILineBreakMode(UILineBreakModeWordWrap);
     }
     else {
     newLineBreakMode = CTLineBreakModeFromUILineBreakMode(self.lineBreakMode);
     }*/
    
    CTParagraphStyleSetting settings[2] = {
        {.spec = kCTParagraphStyleSpecifierAlignment, .valueSize = sizeof(CTTextAlignment), .value = (const void *)&newAlignment},
		{.spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(CTLineBreakMode), .value = (const void *)&newLineBreakMode},
    };
    
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, 2);
    
    /* Example of other params
     CTLineBreakMode lineBreakMode = CTLineBreakModeFromUILineBreakMode(label.lineBreakMode);
     CGFloat lineSpacing = label.leading;
     CGFloat lineHeightMultiple = label.lineHeightMultiple;
     CGFloat topMargin = label.textInsets.top;
     CGFloat bottomMargin = label.textInsets.bottom;
     CGFloat leftMargin = label.textInsets.left;
     CGFloat rightMargin = label.textInsets.right;
     CGFloat firstLineIndent = label.firstLineIndent + leftMargin;
     CTParagraphStyleSetting paragraphStyles[9] = {
     {.spec = kCTParagraphStyleSpecifierAlignment, .valueSize = sizeof(CTTextAlignment), .value = (const void *)&alignment},
     {.spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(CTLineBreakMode), .value = (const void *)&lineBreakMode},
     {.spec = kCTParagraphStyleSpecifierLineSpacing, .valueSize = sizeof(CGFloat), .value = (const void *)&lineSpacing},
     {.spec = kCTParagraphStyleSpecifierLineHeightMultiple, .valueSize = sizeof(CGFloat), .value = (const void *)&lineHeightMultiple},
     {.spec = kCTParagraphStyleSpecifierFirstLineHeadIndent, .valueSize = sizeof(CGFloat), .value = (const void *)&firstLineIndent},
     {.spec = kCTParagraphStyleSpecifierParagraphSpacingBefore, .valueSize = sizeof(CGFloat), .value = (const void *)&topMargin},
     {.spec = kCTParagraphStyleSpecifierParagraphSpacing, .valueSize = sizeof(CGFloat), .value = (const void *)&bottomMargin},
     {.spec = kCTParagraphStyleSpecifierHeadIndent, .valueSize = sizeof(CGFloat), .value = (const void *)&leftMargin},
     {.spec = kCTParagraphStyleSpecifierTailIndent, .valueSize = sizeof(CGFloat), .value = (const void *)&rightMargin},
     };
     CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphStyles, 9);
     [mutableAttributes setObject:(id)paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];
     CFRelease(paragraphStyle);
     */
    
    
    // pack it into attributes dictionary
    NSDictionary *attributesDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    (id)bubbleFont, (id)kCTFontAttributeName, 
                                    [self.textColor CGColor], kCTForegroundColorAttributeName,
                                    (id)paragraphStyle, (id)kCTParagraphStyleAttributeName, nil];
    if(paragraphStyle != NULL)
    {
        CFRelease(paragraphStyle);
    }
    if(bubbleFont != NULL)
    {
        CFRelease(bubbleFont);
    }
    
    // make the attributed string
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:self.viewString
                                                                                   attributes:attributesDict];
    self.attributedString = attrString;
    [attrString release];
    
    // create the delegate
    CTRunDelegateCallbacks callbacks;
    callbacks.version = kCTRunDelegateCurrentVersion;
    callbacks.dealloc = deallocationCallback;
    if ([self.font pointSize] < kTEFontThreshold) {
        callbacks.getAscent = getAscentCallbackSmall;
        callbacks.getDescent = getDescentCallbackSmall;
        callbacks.getWidth = getWidthCallbackSmall;
    }
    else {
        callbacks.getAscent = getAscentCallbackMed;
        callbacks.getDescent = getDescentCallbackMed;
        callbacks.getWidth = getWidthCallbackMed;
    }
    
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, NULL);
    
    // add delegate for each location of image
    for (NSNumber *iIndex in self.imageIndexes) {
        // set the delegate as an attribute
        CFAttributedStringSetAttribute((CFMutableAttributedStringRef)self.attributedString,
                                       CFRangeMake([iIndex intValue], 1), kCTRunDelegateAttributeName, delegate);
    }
    if(delegate != NULL)
    {
        CFRelease(delegate);
    }
    
    // Detect email, web, phone links
    // - add link attributes
    //
    if (enableDataDetection) {
        [self dataDetectorPassInRange:NSMakeRange(0, [self.attributedString.string length]) withAttributedString:self.attributedString];
    }
    
    
    self.needsFrameSetter = YES;
    
    // reformat text
    [self ctFrameSetter];
    
    // ask to be redrawn
    [self setNeedsDisplay];
}

-(void)setText:(NSString *)text {
    [self setText:text enableDataDetection:NO];
}



#pragma mark - Basic



// selectedTextRange property accessor overrides 

- (NSRange)selectedTextRange
{
    return _selectedTextRange;
}

- (void)setSelectedTextRange:(NSRange)range
{
    _selectedTextRange = range;
    
    // ask for update 
    [self setNeedsDisplay];
}

/*!
 @abstract deselect text selection
 */
- (void) removeTextSelection {
    
    self.selectedTextRange = NSMakeRange(NSNotFound, 0);
    
}


#pragma mark - UIView

/*!
 @abstract provides size that fits this message
 - called with [UIView sizeToFit] is called
 */
- (CGSize)sizeThatFits:(CGSize)size {
    if (!self.attributedString) {
        return [super sizeThatFits:size];
    }
    
    CFRange rangeToSize = CFRangeMake(0, [self.attributedString length]);
    CGSize constraints = CGSizeMake(size.width, 15000.0);
    
    // only show one line
    //
    /* if (self.numberOfLines == 0) {
     // If there is one line, the size that fits is the full width of the line
     constraints = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
     } 
     
     else */
    
    // retrict to only the number of line specified
    //
    if (self.numberOfLines > 0) {
        // If the line count of the label more than 1, limit the range to size to the number of lines that have been set
        CGPathRef path = CGPathCreateWithRect(CGRectMake(0.0f, 0.0f, self.bounds.size.width, CGFLOAT_MAX), NULL);
        CTFrameRef frame = CTFramesetterCreateFrame([self ctFrameSetter], CFRangeMake(0, 0), path, NULL);
        CFArrayRef lines = CTFrameGetLines(frame);
        
        if (CFArrayGetCount(lines) > 0) {
            NSInteger lastVisibleLineIndex = MIN(self.numberOfLines, CFArrayGetCount(lines)) - 1;
            CTLineRef lastVisibleLine = CFArrayGetValueAtIndex(lines, lastVisibleLineIndex);
            
            CFRange rangeToLayout = CTLineGetStringRange(lastVisibleLine);
            rangeToSize = CFRangeMake(0, rangeToLayout.location + rangeToLayout.length);
        }
        if(frame != NULL)
        {
            CFRelease(frame);
        }
        if(path != NULL)
        {
            CFRelease(path);
        }
        
    }
    
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints([self ctFrameSetter], rangeToSize, NULL, constraints, NULL);
    
    // don't go beyond the contraints
    // - CTFramesetterSuggestFrameSizeWithConstraints is buggy and gives sizes that are too large at times
    //
    if (suggestedSize.width > constraints.width) {
        //DDLogInfo(@"TE-stf: width to large sug:%f max:%f", suggestedSize.width, constraints.width);
        suggestedSize.width = constraints.width;
    }
    
    return CGSizeMake(ceilf(suggestedSize.width), ceilf(suggestedSize.height));
    //return CGSizeMake(ceilf(constraints.width), ceilf(suggestedSize.height));
    
}




#pragma mark - Draw Methods


/*!
 @abstract checks if this line's range has images
 */
- (BOOL)lineRangeHasImage:(CFRange)range {
    
    BOOL hasImage = NO;
    // highest index that is in this line
    NSMutableIndexSet *iSet = [[NSMutableIndexSet alloc] init];
    for (int i=0; i < [self.imageIndexes count]; i++) {
        int imageIndex = [[self.imageIndexes objectAtIndex:i] intValue];
        if (imageIndex >= range.location && imageIndex < range.location+range.length) {
            [iSet addIndex:i];
        }
        // if not in line, get out
        /* else {
         break;
         }*/
    }
    // has image
    // - remove indexes - to make things faster, but this does not work since we should not clear this info
    if ([iSet count] > 0) {
        //[self.imageIndexes removeObjectsAtIndexes:iSet];
        hasImage = YES;
    }
    [iSet release];
    return hasImage;
}

/*!
 @abstract Class method that returns current selection color (note that in this sample,
 the color cannot be changed)
 */
+ (UIColor *)selectionColor
{
    static UIColor *color = nil;
    if (color == nil) {
        //color = [[UIColor alloc] initWithRed:0.25 green:0.50 blue:1.0 alpha:0.50];
        color = [[UIColor alloc] initWithWhite:0.0 alpha:0.3];  
    }    
    return color;
}

/*!
 @abstract Helper method for obtaining the intersection of two ranges (for handling
 selection range across multiple line ranges in drawRangeAsSelection below)
 */
- (NSRange)RangeIntersection:(NSRange)first withSecond:(NSRange)second
{
    NSRange result = NSMakeRange(NSNotFound, 0);
    
    // Ensure first range does not start after second range
    if (first.location > second.location) {
        NSRange tmp = first;
        first = second;
        second = tmp;
    }
    
    // Find the overlap intersection range between first and second
    if (second.location < first.location + first.length) {
        result.location = second.location;
        NSUInteger end = MIN(first.location + first.length, second.location + second.length);
        result.length = end - result.location;
    }
    
    return result;    
}

#define kSelectionPadding 3.0

/*!
 @abstract Helper method for drawing the current selection range (as a simple filled rect)
 */
- (void)drawRangeAsSelection:(NSRange)selectionRange
{
    
    // If selection range empty, do not draw
    if (selectionRange.length == 0 || selectionRange.location == NSNotFound)
        return;
    
    // set the fill color to the selection color
    [[TextEmoticonView selectionColor] setFill];
    
    // Iterate over the lines in our CTFrame, looking for lines that intersect
    // with the given selection range, and draw a selection rect for each intersection
    //
    NSArray* tempLines = (NSArray*)CTFrameGetLines(_ctFrame);
	CFIndex lineCount = [tempLines count];
	NSMutableArray* lines = [NSMutableArray arrayWithCapacity:lineCount];
	for(id elem in [tempLines reverseObjectEnumerator])
		[lines addObject:elem];
    
    CGPoint lineOrigins[lineCount];
	CTFrameGetLineOrigins(_ctFrame, CFRangeMake(0, 0), lineOrigins);
    
    for (int i = 0; i < [lines count]; i++) {
        CTLineRef line = (CTLineRef) [lines objectAtIndex:i];
        CFRange lineRange = CTLineGetStringRange(line);
        NSRange range = NSMakeRange(lineRange.location, lineRange.length);
        NSRange intersection = [self RangeIntersection:range withSecond:selectionRange];
        if (intersection.location != NSNotFound && intersection.length > 0) {
            // The text range for this line intersects our selection range
            CGFloat xStart = CTLineGetOffsetForStringIndex(line, intersection.location, NULL);
            CGFloat xEnd = CTLineGetOffsetForStringIndex(line, intersection.location + intersection.length, NULL);
            //CGPoint origin;
            
            CGFloat ascent, descent;
            CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            // Create a rect for the intersection and draw it with selection color
            CGPoint thisOrigin = lineOrigins[i];
            // add padding to left, right & bottom
            // - top already has enough
            CGRect selectionRect = CGRectMake(xStart-kSelectionPadding, thisOrigin.y - descent, xEnd - xStart+kSelectionPadding*2.0, ascent + descent+kSelectionPadding*2.0);
            UIRectFill(selectionRect);
        }
    }    
}


/*!
 @abstract Draw emoticons for given line
 
 @param iLine           Line that we want to draw emoticons for
 @param baselineOrigin  Starting point of the line
 @param context         CG Context to draw on
 @param imageIndex      Keeps track of which emoticons should draw next
 @param isLastLine      Is this the last line - should we truncate
 
 @return the new imageIndex value.  Changes if emoticons where drawn
 
 */
- (NSUInteger)drawEmoticonsForLine:(CTLineRef)iLine 
                    baselineOrigin:(CGPoint)baselineOrigin 
                           context:(CGContextRef)context 
                        imageIndex:(NSUInteger)imageIndex 
                        isLastLine:(BOOL)isLastLine {
    
    CGFloat imageSize = ([self.font pointSize] < kTEFontThreshold)?kTEImageSizeSmall:kTEImageSizeMed;
    
    BOOL truncateLastLine = (self.lineBreakMode == UILineBreakModeHeadTruncation || 
                             self.lineBreakMode == UILineBreakModeMiddleTruncation || 
                             self.lineBreakMode == UILineBreakModeTailTruncation);
    
    BOOL isLastRun = NO;
    
    // does line have the special char
    CFRange lineRange = CTLineGetStringRange(iLine);
    BOOL hasImage = [self lineRangeHasImage:lineRange];
    
    // if no image then do nothing
    if (!hasImage) {
        return imageIndex;
    }
    
    // loop through each run for this line and search for emoticons
    //
    NSArray *runs = (NSArray *)CTLineGetGlyphRuns(iLine);
    NSInteger numberOfRuns = [runs count];
    for (int j=0; j < numberOfRuns; j++) {
        
        if (j == numberOfRuns - 1) {
            isLastRun = YES;
        }
        
        CTRunRef iRun = (CTRunRef)[runs objectAtIndex:j];
        
        // range of string that is in this run
        CFRange runRange = CTRunGetStringRange(iRun);
        
        NSInteger glyphCount = CTRunGetGlyphCount(iRun);
        
        if (runRange.length >= 1) {
            
            for (int iGlyph=0; iGlyph < glyphCount; iGlyph++) {
                
                //NSInteger glyphLocation = runRange.location+iGlyph;
                
                NSString *testChar = [self.viewString substringWithRange:NSMakeRange(runRange.location+iGlyph, 1)];
                
                // if special image char
                if ([testChar isEqualToString:[NSString stringWithFormat:@"%C",kTEImageChar]]) {
                    
                    CGFloat decent = 0.0;
                    CGFloat ascent = 0.0;
                    CTRunGetTypographicBounds(iRun, CFRangeMake(iGlyph, 1), &ascent, &decent, NULL); // ascent, decent, leading
                    
                    // find the x offset
                    CGFloat charOffset = 0.0;
                    CTLineGetOffsetForStringIndex(iLine, runRange.location+iGlyph, &charOffset);
                    CGPoint charPoint = CGPointMake(baselineOrigin.x + charOffset, baselineOrigin.y-decent);
                    
                    // if X is at 0 but not the first run in this line, then this image should not be shown
                    if (charOffset == 0 & j != 0 || (ascent == 0.0 && decent == 0.0) ) {
                        // this is a truncated image that should not show up!!
                    }
                    // draw the image!!
                    else {
                        CGRect imageRect = CGRectMake(charPoint.x, charPoint.y, imageSize, imageSize);
                        
                        // if
                        // - at last line to be drawn
                        // - truncate is required
                        // - there are parts of string not drawn out yet, we need to truncate this line
                        // -> draw ellipse instead of image
                        //
                        if (isLastLine &&
                            truncateLastLine &&
                            [self.attributedString.string length] > runRange.location+iGlyph + 1
                            )
                        {
                            
                            
                            
                            // if at last run for this line
                            // - truncate the emoticon
                            //
                            //if (glyphLocation == lineRange.location+lineRange.length-1) {
                            
                            // if at last glyph of last run and line is truncated
                            // then this is the ellipse
                            // don't draw the last emoticon over ellipse
                            if (isLastRun && iGlyph == glyphCount - 1) {
                                // draw ellipses
                                //
                                NSDictionary *tokenAttributes = [self.attributedString attributesAtIndex:(runRange.location) effectiveRange:NULL];
                                NSAttributedString *tokenString = [[NSAttributedString alloc] initWithString:@"\u2026" attributes:tokenAttributes]; // \u2026 is the Unicode horizontal ellipsis character code
                                CTFramesetterRef tokenFrameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)tokenString);
                                
                                CGMutablePathRef tokPath = CGPathCreateMutable();
                                // provide enough space, otherwise ellipses does not show up!
                                imageRect.size.width = ascent + decent;
                                imageRect.size.height = ascent + decent+1.0;  // 1.0 is needed!
                                CGPathAddRect(tokPath, NULL, imageRect);
                                CTFrameRef tokCTFrame = CTFramesetterCreateFrame(tokenFrameSetter, CFRangeMake(0, tokenString.length), tokPath, NULL);
                                CTFrameDraw(tokCTFrame, context);
                                [tokenString release];
                                if(tokPath != NULL)
                                {
                                    CFRelease(tokPath);
                                }
                                if(tokenFrameSetter != NULL)
                                {
                                    CFRelease(tokenFrameSetter);
                                }
                                if(tokCTFrame != NULL)
                                {
                                    CFRelease(tokCTFrame);
                                }
                            }
                            // if second to last char
                            // - and last emoticon in this line
                            /*else if (runRange.location == lineRange.location+lineRange.length-2 &&
                             imageIndex == [self.imageArray count] -1) {
                             
                             // do nothing, don't draw this image since it will cover ellipse generated by text below
                             }*/
                            else if (imageIndex < [self.imageArray count]) {
                                UIImage *imageToDraw = [self.imageArray objectAtIndex:imageIndex];
                                CGContextDrawImage(context, imageRect, imageToDraw.CGImage);
                                DDLogInfo(@"te: runloc:%d lineLoc:%d lLen:%d", runRange.location, lineRange.location, lineRange.length);
                                
                            }
                            
                        } // end last line
                        // not last line
                        else {
                            if (imageIndex < [self.imageArray count]) {
                                UIImage *imageToDraw = [self.imageArray objectAtIndex:imageIndex];
                                CGContextDrawImage(context, imageRect, imageToDraw.CGImage);
                                //DDLogInfo(@"te: runloc:%d lineLoc:%d lLen:%d", runRange.location, lineRange.location, lineRange.length);
                                
                            }
                            else {
                                DDLogVerbose(@"TE-ERROR: trying to access non existing emoticon image!");
                            } 
                        }
                    }
                    //[imageToDraw drawAtPoint:charPoint];
                    
                    imageIndex++;
                    
                }
                
                
            }
            
        }
        
    }
    return imageIndex;
}


/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 */
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    // draw text and emoticons
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self setGraphicsContext:context];
    
    // draw highlight first
    [self drawRangeAsSelection:_selectedTextRange];
    
    
    // prepare and resets text matrix
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    
    CGFloat startX = 0.0;
    CGFloat startY = 0.0;
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    
    // adjust starting point for if centered alignment
    if (self.verticalAlignment == TETextVerticalAlignmentCenter) {
        CGSize textSize = [self sizeThatFits:rect.size];
        CGFloat verticleDiff = rect.size.height - textSize.height;
        if (verticleDiff > 0) {
            startY = ceilf(verticleDiff/2.0);
            height = textSize.height;
        }
    }
    CGContextSetTextPosition(context, startX, startY);
    // extra height 1 pt for iOS 4.x
    // - otherwise text like "預約訊息２(wink)" will show a blank text label
    //
    CGRect textRect = CGRectMake(startX, startY, width, height+1.0);
    
    if(_ctFrame != NULL) 
    {
        CFRelease(_ctFrame);
    }
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, textRect);
    _ctFrame = CTFramesetterCreateFrame(self.ctFrameSetter, CFRangeMake(0, self.attributedString.length), path, NULL);
    if(path != NULL)
    {
        CFRelease(path);
    }    
    
    // insert images
    //
    // go through each line and get position of images
    //
    //CGFloat imageSize = ([self.font pointSize] < kTEFontThreshold)?kTEImageSizeSmall:kTEImageSizeMed;
    NSUInteger imageIndex = 0;
    
    NSArray *lines = (NSArray *)CTFrameGetLines(_ctFrame);
    
    NSUInteger thisNmberOfLines = MIN(self.numberOfLines, [lines count]);
    BOOL truncateLastLine = (self.lineBreakMode == UILineBreakModeHeadTruncation || 
                             self.lineBreakMode == UILineBreakModeMiddleTruncation || 
                             self.lineBreakMode == UILineBreakModeTailTruncation);
    
    
    
    // draw all lines at one time
    //
    if (self.numberOfLines == 0) {
        
        CTFrameDraw(_ctFrame, context); 
        
        NSUInteger linesCount = [lines count];
        // draw emoticons for each line
        CGPoint lineOrigins[linesCount];
        CTFrameGetLineOrigins(_ctFrame, CFRangeMake(0, linesCount), lineOrigins);
        
        for (NSUInteger lineIndex = 0; lineIndex < linesCount; lineIndex++) {
            
            CGRect frameBounds = textRect;
            CGPoint baselineOriginOffset = lineOrigins[lineIndex];
            CGPoint baselineOrigin = CGPointMake(frameBounds.origin.x + baselineOriginOffset.x, frameBounds.origin.y + baselineOriginOffset.y);
            CGContextSetTextPosition(context, baselineOrigin.x, baselineOrigin.y);
            
            CTLineRef line = (CTLineRef)[lines objectAtIndex:lineIndex];  // CFArrayGetValueAtIndex(lines, lineIndex);
            imageIndex = [self drawEmoticonsForLine:line baselineOrigin:baselineOrigin context:context imageIndex:imageIndex isLastLine:NO];
        }
        
    } 
    // only draw lines that are needed
    // - and adds truncation
    //
    else {
        
        CGPoint lineOrigins[thisNmberOfLines];
        CTFrameGetLineOrigins(_ctFrame, CFRangeMake(0, thisNmberOfLines), lineOrigins);
        
        CFRange textRange = CFRangeMake(0, self.attributedString.length);
        
        for (NSUInteger lineIndex = 0; lineIndex < thisNmberOfLines; lineIndex++) {
            
            CGRect frameBounds = textRect;
            CGPoint baselineOriginOffset = lineOrigins[lineIndex];
            CGPoint baselineOrigin = CGPointMake(frameBounds.origin.x + baselineOriginOffset.x, frameBounds.origin.y + baselineOriginOffset.y);
            CGContextSetTextPosition(context, baselineOrigin.x, baselineOrigin.y);
            
            CTLineRef line = (CTLineRef)[lines objectAtIndex:lineIndex];  // CFArrayGetValueAtIndex(lines, lineIndex);
            
            
            // Draw the last line
            //
            if (lineIndex == thisNmberOfLines - 1 && truncateLastLine) {
                // Check if the range of text in the last line reaches the end of the full attributed string
                CFRange lastLineRange = CTLineGetStringRange(line);
                
                // check if line ends with emoticon
                BOOL endWithEmoticons = NO;
                NSString *lastChar = [self.viewString substringWithRange:NSMakeRange(lastLineRange.location+lastLineRange.length-1, 1)];
                if ([lastChar isEqualToString:[NSString stringWithFormat:@"%C",kTEImageChar]]) {
                    endWithEmoticons = YES;
                }
                else if ([lastChar isEqualToString:@"\n"] &&
                         lastLineRange.length > 1) {
                    NSString *secondLastChar = [self.viewString substringWithRange:NSMakeRange(lastLineRange.location+lastLineRange.length-2, 1)];
                    if ([secondLastChar isEqualToString:[NSString stringWithFormat:@"%C",kTEImageChar]]) {
                        endWithEmoticons = YES;
                    }
                }
                
                // only truncate if last line does not show the entire string && does not end with emoticon
                //
                if (lastLineRange.location + lastLineRange.length < textRange.location + textRange.length &&
                    !endWithEmoticons) {
                    
                    // Get correct truncationType and attribute position
                    CTLineTruncationType truncationType;
                    NSUInteger truncationAttributePosition = lastLineRange.location;
                    
                    // Multiple lines, only use UILineBreakModeTailTruncation
                    if (numberOfLines != 1) {
                        self.lineBreakMode = UILineBreakModeTailTruncation;
                    }
                    
                    switch (self.lineBreakMode) {
                        case UILineBreakModeHeadTruncation:
                            truncationType = kCTLineTruncationStart;
                            break;
                        case UILineBreakModeMiddleTruncation:
                            truncationType = kCTLineTruncationMiddle;
                            truncationAttributePosition += (lastLineRange.length / 2);
                            break;
                        case UILineBreakModeTailTruncation:
                        default:
                            truncationType = kCTLineTruncationEnd;
                            truncationAttributePosition += (lastLineRange.length - 1);
                            break;
                    }
                    
                    // Get the attributes and use them to create the truncation token string
                    NSDictionary *tokenAttributes = [self.attributedString attributesAtIndex:truncationAttributePosition effectiveRange:NULL];
                    // \u2026 is the Unicode horizontal ellipsis character code
                    NSAttributedString *tokenString = [[[NSAttributedString alloc] initWithString:@"\u2026" attributes:tokenAttributes] autorelease];
                    CTLineRef truncationToken = CTLineCreateWithAttributedString((CFAttributedStringRef)tokenString);
                    
                    // Append rest of the text to this line and than truncate it
                    // - just taking the last line does not work properly, since it is already truncated to fit the rect
                    // - this allows for proper truncation
                    //
                    lastLineRange.length = CFAttributedStringGetLength((CFAttributedStringRef)self.attributedString) - lastLineRange.location;
                    CFAttributedStringRef truncationString = CFAttributedStringCreateWithSubstring(kCFAllocatorDefault, (CFAttributedStringRef)self.attributedString, lastLineRange);
                    CTLineRef truncationLine = CTLineCreateWithAttributedString(truncationString);
                    
                    // Truncate the line in case it is too long.
                    CTLineRef truncatedLine = CTLineCreateTruncatedLine(truncationLine, rect.size.width, truncationType, truncationToken);
                    if (!truncatedLine) {
                        // If the line is not as wide as the truncationToken, truncatedLine is NULL
                        truncatedLine = CFRetain(truncationToken);
                    }
                    
                    CTLineDraw(truncatedLine, context);
                    
                    imageIndex = [self drawEmoticonsForLine:truncatedLine baselineOrigin:baselineOrigin context:context imageIndex:imageIndex isLastLine:YES];
                    
                    if(truncatedLine != NULL)
                    {
                        CFRelease(truncatedLine);
                    }
                    if(truncationLine != NULL)
                    {
                        CFRelease(truncationLine);
                    }
                    if(truncationString != NULL)
                    {
                        CFRelease(truncationString);
                    }
                    if(truncationToken != NULL)
                    {
                        CFRelease(truncationToken);
                    }
                    
                    
                }
                else {
                    CTLineDraw(line, context);
                    imageIndex = [self drawEmoticonsForLine:line baselineOrigin:baselineOrigin context:context imageIndex:imageIndex isLastLine:YES];
                }
            }
            // draw lines before last line
            else {
                CTLineDraw(line, context);
                imageIndex = [self drawEmoticonsForLine:line baselineOrigin:baselineOrigin context:context imageIndex:imageIndex isLastLine:NO];
            }
            
        }
    }
    
    /*
     if (ctFrame) {
     CFRelease(ctFrame);
     }*/
    
}





#pragma mark - ActionSheets

#define URL_AS_TAG      12001
#define EMAIL_AS_TAG    12002
#define PHONE_AS_TAG    12003

/*!
 @abstract detect touch and extract data if pressed
 
 
 */
- (void)pressLink {
    
    NSString *urlString = [self.tappedDataObject absoluteString];
    
    NSString *openButtonTitle = NSLocalizedString(@"Open", @"TextEmoticon - button: open a url link");
    if ([urlString hasPrefix:@"mailto:"]) {
        
        // strip out mailto:
        if ([urlString length] > 7) {
            urlString = [urlString substringFromIndex:7];
        }
        
        openButtonTitle = NSLocalizedString(@"Compose Email", @"TextEmoticon - button: compose a new email message");
    }
    
    UIActionSheet *aSheet;
	
	aSheet	= [[UIActionSheet alloc]
               initWithTitle:urlString
               delegate:self
               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel delete all chats")
               destructiveButtonTitle:nil
               otherButtonTitles:
               openButtonTitle,
               NSLocalizedString(@"Copy", @"TextEmoticon - button: sms a highlighted phone number"),
               nil
               ];
	
	aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    aSheet.tag = URL_AS_TAG;
	
    [aSheet showInView:[[UIApplication sharedApplication] keyWindow]];
	[aSheet release];
}

/*!
 @abstract detect touch and extract data if pressed
 */
- (void)pressPhonenumber {
    
    NSString *cc = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPhoneCountryCode];
    NSString *formattedNumber = [Utility formatPhoneNumber:self.tappedDataObject countryCode:cc showCountryCode:NO];
    
    UIActionSheet *aSheet;
	
	aSheet	= [[UIActionSheet alloc]
               initWithTitle:formattedNumber
               delegate:self
               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel delete all chats")
               destructiveButtonTitle:nil
               otherButtonTitles:
               NSLocalizedString(@"Call", @"TextEmoticon - button: call a highlighted phone number"),
               NSLocalizedString(@"SMS", @"TextEmoticon - button: sms a highlighted phone number"),
               NSLocalizedString(@"Copy", @"TextEmoticon - button: sms a highlighted phone number"),
               nil
               ];
	
	aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    aSheet.tag = PHONE_AS_TAG;
	
    [aSheet showInView:[[UIApplication sharedApplication] keyWindow]];
	[aSheet release];
}





/*!
 @abstract respond to actionsheet selection
 */
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    // clears out selection
    self.selectedTextRange = NSMakeRange(NSNotFound, 0);
    
    // if not cancel
    if (actionSheet.tag == URL_AS_TAG && buttonIndex != [actionSheet cancelButtonIndex]) {
        
		NSString *actionButtonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Open", nil)]) {
            [[UIApplication sharedApplication] openURL:self.tappedDataObject];
        }
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Compose Email", nil)]) {
            
            NSString *address = [self.tappedDataObject absoluteString];
            if ([address hasPrefix:@"mailto:"] && [address length] > 7) {
                address = [address substringFromIndex:7];
            }
            
            [Utility componseEmailToAddresses:[NSArray arrayWithObject:address] presentWithViewController:[AppUtility getAppDelegate].containerController delegate:self];
        }
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Copy", nil)]) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            
            // remove mailto for copy
            NSString *copyString = [self.tappedDataObject absoluteString];
            if ([copyString hasPrefix:@"mailto:"] && [copyString length] > 7) {
                copyString = [copyString substringFromIndex:7];
            }
            
            pasteboard.string = copyString;
        }
    }
    // Broadcast options
    //
    else if (actionSheet.tag == PHONE_AS_TAG && buttonIndex != [actionSheet cancelButtonIndex]) {
        
        NSString *actionButtonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Call", nil)]) {
            [Utility callPhoneNumber:self.tappedDataObject];
        }
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"SMS", nil)]) {
            // resign first responder before presenting SMS composer
            // - otherwise dialog tool bar will shift up for a keyboard that does not exists
            //
            [AppUtility findAndResignFirstResponder];
            [Utility smsPhoneNumber:self.tappedDataObject presentWithViewController:[AppUtility getAppDelegate].containerController delegate:self];
        }
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Copy", nil)]) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = self.tappedDataObject;
        }
    }
    else {
        DDLogVerbose(@"Actionsheet Cancelled");
    }
    
}






#pragma mark - GuestureRecognizer


/*!
 @abstract Finds CTRun at touch point
 */
- (CTRunRef) runAtTouch:(UITouch *)touch  {
    
    CGPoint point = [touch locationInView:self];
    
    // reverse line order
    // - otherwise they are in opposite order
    //
	NSArray* tempLines = (NSArray*)CTFrameGetLines(_ctFrame);
	CFIndex lineCount = [tempLines count];//CFArrayGetCount(lines);
	NSMutableArray* lines = [NSMutableArray arrayWithCapacity:lineCount];
	for(id elem in [tempLines reverseObjectEnumerator])
		[lines addObject:elem];
    
	CGPoint lineOrigins[lineCount];
	CTFrameGetLineOrigins(_ctFrame, CFRangeMake(0, 0), lineOrigins);
    
    // find line containing point
    NSUInteger lineIndex;
    for (lineIndex = 0; lineIndex < lineCount-1; lineIndex++) {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        if (lineOrigin.y < point.y) {
            break;
        }
    }
    
    // get string index of point tapped
    //
    CGPoint lineOrigin = lineOrigins[lineIndex];
    CTLineRef line = CFArrayGetValueAtIndex((CFArrayRef)lines, lineIndex);
    // Convert CT coordinates to line-relative coordinates
    CGPoint relativePoint = CGPointMake(point.x - lineOrigin.x, point.y - lineOrigin.y);
    CFIndex idx = CTLineGetStringIndexForPosition(line, relativePoint);
    
    
    // find run with that index
    NSArray *runs = (NSArray *)CTLineGetGlyphRuns(line);
    NSUInteger runCount = [runs count];
    
    for(CFIndex j = 0; j < runCount; j++)
    {
        CTRunRef run = CFArrayGetValueAtIndex((CFArrayRef)runs, j);
        CFRange runRange = CTRunGetStringRange(run);
        
        if (idx >= runRange.location && idx < runRange.location+runRange.length) {
            return run;
        }
    }
    
    return NULL;
}

/*!
 @abstract Means that two recognizer are detected - Should we also recognize this one?
 
 - Usually should be NO - default behavior
 
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    // Since we don't recognize the selection, cancel it
    // - otherwise if scroll view is deaccelerating and we tap this TE view
    // - the tap will highlight the text, but remain highlighted, but recognizer will not fire
    // - so text will remain highlighted indefintely :(
    //
    [self removeTextSelection];
    
    // never let two recognizer run together
    return NO;
}

/*!
 @abstract detect touch and extract data if pressed
 - only respond if data tapped, otherwise should pass touch to button below for long press option
 
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    if (!self.userInteractionEnabled) {
        return NO;
    }
    
    self.tapRecognizedBlock = nil;
    
    
    CTRunRef foundRun = [self runAtTouch:touch];
    
    if (foundRun != NULL) {
        NSDictionary* attributes = (NSDictionary*)CTRunGetAttributes(foundRun);
        
        NSURL* url = [attributes objectForKey:kTEDataDetectorLinkKey];
        NSString* phoneNumber = [attributes objectForKey:kTEDataDetectorPhoneNumberKey];
        //NSDictionary* addressComponents = [attributes objectForKey:kTEDataDetectorAddressKey];
        
        //BOOL result = NO;
        //NSDate* date = [attributes objectForKey:kJTextViewDataDetectorDateKey];
        
        if(url)
        {
            self.tappedDataObject = url;
            
            self.tapRecognizedBlock = ^{
                [self pressLink];
            };
            
            CFRange runRange = CTRunGetStringRange(foundRun);
            self.selectedTextRange = NSMakeRange(runRange.location, runRange.length);
            
            // call timer incase we tapped but nothing touch was not passed on properly
            // - so deselect the text
            //self.removeSelectionTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(removeTextSelection) userInfo:nil repeats:NO];
            
            return YES;
        }
        else if(phoneNumber)
        {
            NSCharacterSet *phoneSet = [NSCharacterSet characterSetWithCharactersInString:@"+01234567890"];
            
            NSUInteger startIndex = 0;
            
            // find where we consider this to be a phone number
            // - data detector sometimes adds non numbers such as 公司電話:0929-257618
            //
            for (NSUInteger i = 0; i < [phoneNumber length]; i++) {
                unichar iChar = [phoneNumber characterAtIndex:i];
                
                if ([phoneSet characterIsMember:iChar]) {
                    startIndex = i;
                    break;
                }
            }
            
            if (startIndex > 0) {
                phoneNumber = [phoneNumber substringFromIndex:startIndex];
            }
            
            // The following code may be switched to if we absolutely need to remove everything but the numbers.
            //NSMutableString* strippedPhoneNumber = [NSMutableString stringWithCapacity:[phoneNumber length]]; // Can't be longer than that
            //for(NSUInteger i = 0; i < [phoneNumber length]; i++)
            //{
            //	if(isdigit([phoneNumber characterAtIndex:i]))
            //		[strippedPhoneNumber appendFormat:@"%c", [phoneNumber characterAtIndex:i]];
            //}
            //DDLogVerbose(@"*** phoneNumber = %@; strippedPhoneNumber = %@", phoneNumber, strippedPhoneNumber);
            
            
            self.tappedDataObject = phoneNumber; // no need to encode here, do it when actuallying calling out
            
            self.tapRecognizedBlock = ^{
                [self pressPhonenumber];
            };
            
            CFRange runRange = CTRunGetStringRange(foundRun);
            self.selectedTextRange = NSMakeRange(runRange.location, runRange.length);
            //self.removeSelectionTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(removeTextSelection) userInfo:nil repeats:NO];
            
            return YES;
        }
        /*else if(addressComponents)
         {
         self.tapRecognizedBlock = ^{
         NSMutableString* address = [NSMutableString string];
         NSString* temp = nil;
         if((temp = [addressComponents objectForKey:NSTextCheckingStreetKey]))
         [address appendString:temp];
         if((temp = [addressComponents objectForKey:NSTextCheckingCityKey]))
         [address appendString:[NSString stringWithFormat:@"%@%@", ([address length] > 0) ? @", " : @"", temp]];
         if((temp = [addressComponents objectForKey:NSTextCheckingStateKey]))
         [address appendString:[NSString stringWithFormat:@"%@%@", ([address length] > 0) ? @", " : @"", temp]];
         if((temp = [addressComponents objectForKey:NSTextCheckingZIPKey]))
         [address appendString:[NSString stringWithFormat:@" %@", temp]];
         if((temp = [addressComponents objectForKey:NSTextCheckingCountryKey]))
         [address appendString:[NSString stringWithFormat:@"%@%@", ([address length] > 0) ? @", " : @"", temp]];
         NSString* urlString = [NSString stringWithFormat:@"http://maps.google.com/maps?q=%@", [address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
         
         };
         
         return YES;
         }*/
        //else if((NSDate* date = [attributes objectForKey:kJTextViewDataDetectorDateKey]))
        //{
        //	DDLogVerbose(@"Unable to handle date: %@", date);
        //	result = NO;
        //	return;
        //}
        
    }
    
    return NO;
}


#pragma mark Touch handling


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {    
    if(!self.tapRecognizedBlock) {
        [self.nextResponder touchesBegan:touches withEvent:event];
    }
}

/*- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
 if(!self.tapRecognizedBlock) {
 [self.nextResponder touchesMoved:touches withEvent:event];
 }
 }*/

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    // clears out selection
    [self removeTextSelection];
    
    if(!self.tapRecognizedBlock) {
        [self.nextResponder touchesCancelled:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    // clears out selection
    [self removeTextSelection];
    
    if(!self.tapRecognizedBlock) {
        [self.nextResponder touchesEnded:touches withEvent:event];
    }
}

- (void)receivedTap:(UITapGestureRecognizer*)recognizer
{
	/*if(self.editable)
     {
     [self becomeFirstResponder];
     return;
     }*/
    
    // reset tap block
    //
    if(_tapRecognizedBlock) {
        _tapRecognizedBlock();
        
        self.tapRecognizedBlock = nil;
        
        
        // stops timer, since we got tap ok
        //
        //[self.removeSelectionTimer invalidate];
        // clears out selection
        //self.selectedTextRange = NSMakeRange(NSNotFound, 0);
    }
}



#pragma mark - Mail Methods

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{   
	if (result == MFMailComposeResultFailed) {
		DDLogVerbose(@"MFMail: mail failed");
        
        NSString *title = NSLocalizedString(@"Compose Email Failure", @"Email - alert title");
        NSString *detMessage = [NSString stringWithFormat:@"%@", [error localizedDescription]];
        
        [Utility showAlertViewWithTitle:title message:detMessage];
        
	}
    [[[AppUtility getAppDelegate] containerController] dismissModalViewControllerAnimated:YES];
}


#pragma mark - SMS Methods

// Dismisses the message composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result 
{   
	if (result == MessageComposeResultFailed) {
        
        [AppUtility showAlert:kAUAlertTypeNoTelephonySMS];
        
	}
    [[[AppUtility getAppDelegate] containerController] dismissModalViewControllerAnimated:YES];
	
}




@end
