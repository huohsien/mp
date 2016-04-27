//
//  TextEmoticonView.h
//  mp
//
//  Created by Min Tsai on 1/10/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

/*!
 @header TextEmoticonView
 
 View the can combine text and images together
 
 
 Example1
  * set text properties first
  * then set text - so the attributed string will include these properties
  * size to fit to find the actual size
 
 TextEmoticonView *textView = [[TextEmoticonView alloc] initWithFrame:maxRect];
 textView.font = bubbleFont;
 [textView setText:self.thisMessage.text];
 [textView sizeToFit];
 
 Example2
  * limits to only 1 line of text
 
 TextEmoticonView *textView = [[TextEmoticonView alloc] initWithFrame:CGRectMake(12.0, 1.5, 253.0, 25.0)];
 textView.font = [AppUtility fontPreferenceWithContext:kAUFontSystemSmall];
 textView.lineBreakMode = UILineBreakModeTailTruncation;
 textView.numberOfLines = 1;
 [textView setText:self.resource.text];
 
 // to enable data detection and highlighting
 // - also allows for tap action
 //
 textView.userInteractionEnabled = YES;
 
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */


#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import <MessageUI/MFMailComposeViewController.h>


typedef enum {
    TETextVerticalAlignmentCenter  = 0,
    TETextVerticalAlignmentTop     = 1,
    TETextVerticalAlignmentBottom  = 2
} TETextVerticalAlignment;


extern unichar const kTEImageChar;
extern CGFloat const kTEImageWidth;
extern CGFloat const kTEImageHeight;


@interface TextEmoticonView : UIView <UIActionSheetDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate> {
    
    NSMutableString *viewString;
    NSMutableArray *imageArray;
    NSMutableArray *imageIndexes;
    
    NSMutableAttributedString * attributedString;
    CTFramesetterRef ctFrameSetter;             // frame setter for core text
    BOOL needsFrameSetter;
    
    TETextVerticalAlignment verticalAlignment;
    UITextAlignment textAlignment;
    NSUInteger numberOfLines;
    UILineBreakMode lineBreakMode;
    UIFont *font;
    UIColor *textColor;
    UIColor *highlightedTextColor;
    
    id tappedDataObject;
    
    //NSTimer *removeSelectionTimer;
    
    @private
    
    CGContextRef    _graphicsContext;
    CTFrameRef      _ctFrame;
    NSRange         _selectedTextRange; // Selected text range
    
}



/*! marks frameSetter as dirty and needs to be refreshed */
@property (nonatomic, assign) BOOL needsFrameSetter;


/*! string that will be displayed for this view */
@property (nonatomic, retain) NSMutableString *viewString;

/*! array of images to add inline with string */
@property (nonatomic, retain) NSMutableArray *imageArray;

/*! range where we added object chars to insert images */
@property (nonatomic, retain) NSMutableArray *imageIndexes;

@property (nonatomic, retain) NSMutableAttributedString * attributedString;

/*! number of lines to limit text.  0 is no limit */
@property (nonatomic, assign) NSUInteger numberOfLines;

@property (nonatomic, assign) TETextVerticalAlignment verticalAlignment;
@property (nonatomic, assign) UITextAlignment textAlignment;

@property (nonatomic, assign) UILineBreakMode lineBreakMode;
@property (nonatomic, retain) UIFont *font;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) UIColor *highlightedTextColor;

/*! object related to tapped data: link, email or phone number (NSURL or NSString) */
@property (nonatomic, retain) id tappedDataObject;

@property (nonatomic, assign) NSRange selectedTextRange;


/*! automatically deselect if touch is not properly received */
//@property (nonatomic, retain) NSTimer *removeSelectionTimer;


-(void)setText:(NSString *)text;
-(void)setText:(NSString *)text enableDataDetection:(BOOL)enableDataDetection;


@end
