//
//  ResourceScrollView.h
//  mp
//
//  Created by Min Tsai on 1/9/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPResourceCenter.h"

@class CDResource;
@class ResourceScrollView;

/*!
 Delegate that handles input from this view's controls
 */
@protocol ResourceScrollViewDelegate <NSObject>
/*!
 @abstract User pressed this resource
 */
- (void)ResourceScrollView:(ResourceScrollView *)resourceScrollView resource:(CDResource *)resource;

@optional

/*!
 @abstract User pressed delete key - for emoticon
 */
- (void)ResourceScrollView:(ResourceScrollView *)resourceScrollView pressDelete:(id)sender;

/*!
 @abstract User scrolled this view to a new page
 */
- (void)ResourceScrollView:(ResourceScrollView *)resourceScrollView changePage:(NSUInteger)page;
@end


@interface ResourceScrollView : UIScrollView <UIScrollViewDelegate> {
    
    id <ResourceScrollViewDelegate> resourceDelegate;
    RCType resourceType;
    NSArray *recentResources;
    NSArray *allResources;
    
    NSMutableArray *recentButtons;
    NSMutableArray *allButtons;
    
    NSInteger setID;
    NSInteger numberOfPages;
    NSInteger currentPage;
    BOOL pageControlUsed;
    
    CGFloat startX;
    CGFloat startY;
    CGFloat shiftX;
    CGFloat shiftY;
    CGFloat resourceWidth;
    CGFloat resourceHeight;
    
    NSInteger resourcesPerPage;
    NSInteger resourcesPerRow;
    
    CGFloat lastLayoutWidth;
}


@property (nonatomic, assign) id <ResourceScrollViewDelegate> resourceDelegate;

@property (nonatomic, assign) RCType resourceType;
@property (nonatomic, assign) NSInteger setID;
@property (nonatomic, assign) NSInteger numberOfPages;
@property (nonatomic, assign) NSInteger currentPage;

@property (nonatomic, assign) NSInteger resourcesPerPage;
@property (nonatomic, assign) NSInteger resourcesPerRow;

@property (nonatomic, assign) CGFloat startX;
@property (nonatomic, assign) CGFloat startY;
@property (nonatomic, assign) CGFloat shiftX;
@property (nonatomic, assign) CGFloat shiftY;
@property (nonatomic, assign) CGFloat resourceWidth;
@property (nonatomic, assign) CGFloat resourceHeight;

/*! keeps track of last width, so we know when to layout views again */
@property (nonatomic, assign) CGFloat lastLayoutWidth;



/*! Resources that have been recently used */
@property (nonatomic, retain) NSArray *recentResources;

/*! All resources for this type and set */
@property (nonatomic, retain) NSArray *allResources;

/*! Store buttons so we can move them when orientation changes */
@property (nonatomic, retain) NSMutableArray *recentButtons;
@property (nonatomic, retain) NSMutableArray *allButtons;

/*! Prevent feedback loop from page control */
@property (nonatomic, assign) BOOL pageControlUsed;

- (id) initWithFrame:(CGRect)frame type:(RCType)type setID:(int)setID;
- (void) setPage:(NSInteger)pageNumber animated:(BOOL)animated;
- (void) checkAndStartDownload;
- (void) refreshMissingButtons;

@end
