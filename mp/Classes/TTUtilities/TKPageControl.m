//
//  TKPageControl.m
//  mp
//
//  Created by Min Tsai on 1/11/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "TKPageControl.h"


// Tweak these or make them dynamic.
#define kDotDiameter 10.0
#define kDotSpacer 6.7

@implementation TKPageControl

@synthesize dotColorCurrentPage;
@synthesize dotColorOtherPage;
@synthesize delegate;

@synthesize currentPageImageFile;
@synthesize otherPageImageFile;

@synthesize specialCurrentPageImageFile;
@synthesize specialOtherPageImageFile;
@synthesize specialPageIndex;


- (void)dealloc 
{
    [dotColorCurrentPage release];
    [dotColorOtherPage release];
    
    [currentPageImageFile release];
    [otherPageImageFile release];
    [specialCurrentPageImageFile release];
    [specialOtherPageImageFile release];
    
    [super dealloc];
}


- (NSInteger)currentPage
{
    return _currentPage;
}

- (void)setCurrentPage:(NSInteger)page
{
    _currentPage = MIN(MAX(0, page), _numberOfPages-1);
    [self setNeedsDisplay];
}

- (NSInteger)numberOfPages
{
    return _numberOfPages;
}

- (void)setNumberOfPages:(NSInteger)pages
{
    _numberOfPages = MAX(0, pages);
    _currentPage = MIN(MAX(0, _currentPage), _numberOfPages-1);
    
    // hides if only one page
    if (_numberOfPages == 1) {
        [self setHidden:YES];
    }
    else {
        [self setHidden:NO];
    }
    [self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
    {
        // Default colors.
        self.backgroundColor = [UIColor clearColor];
        self.dotColorCurrentPage = [UIColor blackColor];
        self.dotColorOtherPage = [UIColor lightGrayColor];
        
        self.specialPageIndex = -1;
    }
    return self;
}

- (void)drawRect:(CGRect)rect 
{
    CGContextRef context = UIGraphicsGetCurrentContext(); 
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextSetAllowsAntialiasing(context, true);
    
    CGRect currentBounds = self.bounds;
    CGFloat dotsWidth = self.numberOfPages*kDotDiameter + MAX(0, self.numberOfPages-1)*kDotSpacer;
    CGFloat x = CGRectGetMidX(currentBounds)-dotsWidth/2;
    CGFloat y = CGRectGetMidY(currentBounds)-kDotDiameter/2;
    
    UIImage *currentPageI = [UIImage imageNamed:self.currentPageImageFile];
    UIImage *otherPageI = [UIImage imageNamed:self.otherPageImageFile];
    UIImage *specialCurrentPageI = [UIImage imageNamed:self.specialCurrentPageImageFile];
    UIImage *specialOtherPageI = [UIImage imageNamed:self.specialOtherPageImageFile];
    
    for (int i=0; i<_numberOfPages; i++)
    {
        CGRect circleRect = CGRectMake(x, y, kDotDiameter, kDotDiameter);
        // current page
        if (i == _currentPage)
        {
            // if special
            if (i == self.specialPageIndex && specialCurrentPageI) {
                CGContextDrawImage(context, circleRect, specialCurrentPageI.CGImage);
            }
            // if regular image
            else if (currentPageI) {
                CGContextDrawImage(context, circleRect, currentPageI.CGImage);
            }
            else {
                CGContextSetFillColorWithColor(context, self.dotColorCurrentPage.CGColor);
                CGContextFillEllipseInRect(context, circleRect);
            }
        }
        // other pages
        else
        {
            // if special
            if (i == self.specialPageIndex  && specialOtherPageI) {
                CGContextDrawImage(context, circleRect, specialOtherPageI.CGImage);
            }
            // if regular image
            else if (otherPageI) {
                CGContextDrawImage(context, circleRect, otherPageI.CGImage);
            }
            else {
                CGContextSetFillColorWithColor(context, self.dotColorOtherPage.CGColor);
                CGContextFillEllipseInRect(context, circleRect);
            }
        }
        x += kDotDiameter + kDotSpacer;
    }
}



- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // do nothing if no delegate
    if ([self.delegate respondsToSelector:@selector(TKPageControl:currentPageChanged:)]) {
    
        CGPoint touchPoint = [[[event touchesForView:self] anyObject] locationInView:self];
        
        CGRect currentBounds = self.bounds;
        CGFloat x = touchPoint.x - CGRectGetMidX(currentBounds);
        
        if(x<0 && self.currentPage>=0){
            self.currentPage--;
            [self.delegate TKPageControl:self currentPageChanged:self.currentPage]; 
        }
        else if(x>0 && self.currentPage<self.numberOfPages-1){
            self.currentPage++;
            [self.delegate TKPageControl:self currentPageChanged:self.currentPage]; 
        }  
    }
}

@end
