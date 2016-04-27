//
//  TKBadgeView.m
//  mp
//
//  Created by Min Tsai on 1/17/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "TKImageLabel.h"

@implementation TKImageLabel

@synthesize text;
@synthesize font;
@synthesize textColor;
@synthesize backgroundImage;
@synthesize maxWidth;
@synthesize textEdgeInsets;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.font = [UIFont systemFontOfSize:15.0];
        self.textColor = [UIColor darkTextColor];
        self.textEdgeInsets = UIEdgeInsetsMake(5.0, 10.0, 5.0, 10.0);
        self.hidden = YES;
    }
    return self;
}

- (void) dealloc {
    
    [text release];
    [font release];
    [textColor release];
    [backgroundImage release];
    [super dealloc];
}

/*!
 @abstract sets the text to display
 - call this last so that view is redrawn and layout correctly
 */
- (void) setText:(NSString *)newText{
    [newText retain];
    [text release];
    text = newText;
    
    // hide if no text
    if ([text length] > 0) {
        self.hidden = NO;
    }
    else {
        self.hidden = YES;
    }
    
    CGRect oldFrame = self.frame;
    
    [self sizeToFit];

    // if left margin if flexible, then push frame to the left after resizing
    if (self.autoresizingMask & UIViewAutoresizingFlexibleLeftMargin) {
        CGRect newFrame = self.frame;
        newFrame.origin.x = newFrame.origin.x + oldFrame.size.width - newFrame.size.width;
        self.frame = newFrame;
    }

    [self setNeedsDisplay];
}

- (void) setFont:(UIFont *)newFont {
    [newFont retain];
    [font release];
    font = newFont;
}


- (void) setTextColor:(UIColor *)newTextColor {
    [newTextColor retain];
    [textColor release];
    textColor = newTextColor;
    [self setNeedsDisplay];
}


- (void) setBackgroundImage:(UIImage *)newBackgroundImage {
    [newBackgroundImage retain];
    [backgroundImage release];
    backgroundImage = newBackgroundImage;
}

/*!
 @abstract view should not grow beyond this width
 */
- (void) setMaxWidth:(CGFloat)newMaxWidth {
    maxWidth = newMaxWidth;
}

/*!
 @abstract inset padding between text and image
 
 @param textEdgeInsets Define amount of padding for the text.  
 - only top and left really used.
 - define 0.0 if you want text to be centered on that axis
 - UIEdgeInsetsZero if centered on both axis
 
 */
- (void) setTextEdgeInsets:(UIEdgeInsets)newTextEdgeInsets {
    textEdgeInsets = newTextEdgeInsets; 
}


#pragma mark - UIView

/*!
 @abstract provides size that fits this message
 - called with [UIView sizeToFit] is called
 */
- (CGSize)sizeThatFits:(CGSize)size {
    
    // only resize if insets are defined
    //
    if (!self.textEdgeInsets.left) {
        return [super sizeThatFits:size];
    }
    
    CGSize textSize = [self.text sizeWithFont:self.font];
    
    // get standard text size
    CGSize imageSize = [self.backgroundImage size];
    
    CGFloat desiredWidth = textSize.width + self.textEdgeInsets.left + self.textEdgeInsets.right;
    
    // if text is larger than image size and insets
    // - then resize
    //
    if ( desiredWidth > imageSize.width ) {
        return CGSizeMake(desiredWidth, imageSize.height);
    }
    
    // if text is smaller than image and insets
    // - then just use image size
    //
    return imageSize;

}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
	
	CGRect contentRect = self.bounds;
		
    CGFloat boundsX = contentRect.origin.x;
    CGPoint point;
		
    // draw background Image to fill rect
    //
    [self.backgroundImage drawInRect:contentRect];
    
    
    // draw text
    [self.textColor set];
    CGSize textSize = [self.text sizeWithFont:self.font];
    
    CGFloat startX = self.textEdgeInsets.left; // 
    CGFloat startY = self.textEdgeInsets.top;  // 
    
    // if insets are 0.0, then center the view
    if (startX == 0.0) {
        startX = MAX((contentRect.size.width - textSize.width)/2.0, 0.0);
    }
    if (startY == 0.0) {
        startY = MAX((contentRect.size.height - textSize.height)/2.0, 0.0);
    }
    
    // Draw first string
    point = CGPointMake(boundsX + startX, startY);
    [self.text drawAtPoint:point forWidth:textSize.width withFont:self.font minFontSize:[self.font pointSize] actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
    
}


@end
