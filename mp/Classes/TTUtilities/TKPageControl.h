//
//  TKPageControl.h
//  mp
//
//  Created by Min Tsai on 1/11/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//
#import <UIKit/UIKit.h>

@class TKPageControl;

@protocol TKPageControlDelegate <NSObject>
@optional
/*!
 @abstract Informs delegate that the current page should change
 
 */
- (void)TKPageControl:(TKPageControl *)pageControl currentPageChanged:(NSInteger)currentPage;
@end



@interface TKPageControl : UIView 
{
    id <TKPageControlDelegate> delegate;

    NSInteger _currentPage;
    NSInteger _numberOfPages;
    UIColor *dotColorCurrentPage;
    UIColor *dotColorOtherPage;
    
    NSString *currentPageImageFile;
    NSString *otherPageImageFile;
    
    NSString *specialCurrentPageImageFile;
    NSString *specialOtherPageImageFile;
    
    NSInteger specialPageIndex;
}

// Optional delegate for callbacks when user taps a page dot.
@property (nonatomic, assign) id <TKPageControlDelegate> delegate;

// Set these to control the PageControl.
@property (nonatomic) NSInteger currentPage;
@property (nonatomic) NSInteger numberOfPages;

// Customize these as well as the backgroundColor property.
@property (nonatomic, retain) UIColor *dotColorCurrentPage;
@property (nonatomic, retain) UIColor *dotColorOtherPage;


/*! image for current page */
@property (nonatomic, retain) NSString *currentPageImageFile;

/*! image for other pages */
@property (nonatomic, retain) NSString *otherPageImageFile;

/*! special image can also be specified for a certain page index */
@property (nonatomic, retain) NSString *specialCurrentPageImageFile;
@property (nonatomic, retain) NSString *specialOtherPageImageFile;
@property (nonatomic, assign) NSInteger specialPageIndex;


@end



