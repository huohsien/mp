//
//  ResourceScrollView.m
//  mp
//
//  Created by Min Tsai on 1/9/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "ResourceScrollView.h"
#import "MPResourceCenter.h"
#import "CDResource.h"
#import "ResourceButton.h"
#import "MPFoundation.h"

@interface ResourceScrollView (Private)

- (void) configurePage:(NSInteger)pageNumber;
- (void) addRecentButtonViews;
- (void) addAllButtonViews;

- (void) configureScrollView;
- (void) layoutRecentButtonViews;
- (void) layoutAllButtonViews;

@end


@implementation ResourceScrollView

@synthesize resourceDelegate;

@synthesize setID;
@synthesize resourceType;
@synthesize numberOfPages;
@synthesize currentPage;
@synthesize recentResources;
@synthesize allResources;
@synthesize resourcesPerPage;
@synthesize resourcesPerRow;
@synthesize pageControlUsed;

@synthesize recentButtons;
@synthesize allButtons;

@synthesize startX;
@synthesize startY;
@synthesize shiftX;
@synthesize shiftY;
@synthesize resourceWidth;
@synthesize resourceHeight;

@synthesize lastLayoutWidth;

int const kRSVStickersPerPage = 8;
int const kRSVStickersPerRow = 4;

#define kStickerWidth 70.0
#define kStickerHeight 70.0

#define kStickerStartX 12.5
#define kStickerStartY 5.0
#define kStickerShiftX 75.0
#define kStickerShiftY 75.0

int const kRSVEmoticonPerPage = 20;
int const kRSVEmoticonPerRow = 7;

#define kEmoticonWidth 40.0
#define kEmoticonHeight 40.0

#define kEmoticonStartX 15.0
#define kEmoticonStartY 14.0
#define kEmoticonShiftX 42.0
#define kEmoticonShiftY 45.0


int const kRSVPetPhrasePerPage = 5;
int const kRSVPetPhrasePerRow = 1;

#define kPetPhraseWidth 300.0
#define kPetPhraseHeight 28.0

#define kPetPhraseStartX 10.0
#define kPetPhraseStartY 8.0
#define kPetPhraseShiftX 300.0
#define kPetPhraseShiftY 33.0

#define kPetPhraseWidthLandscape 460.0
#define kPetPhraseShiftXLandscape 460.0


- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [recentResources release];
    [allResources release];
    [recentButtons release];
    [allButtons release];
    
    [super dealloc];
}


- (id)initWithFrame:(CGRect)frame type:(RCType)newType setID:(int)newSetID 
{
    
    // must call initWithFrame!
    self = [super initWithFrame:frame];
    if (self) {
        
        self.lastLayoutWidth = 0.0;
        self.delegate = self;
        self.pageControlUsed = NO;
        self.pagingEnabled = YES;
        self.showsHorizontalScrollIndicator = YES;
        self.backgroundColor = [AppUtility colorForContext:kAUColorTypeKeypad];
        
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.setID = newSetID;
        self.resourceType = newType;

        //self.recentResources = [CDResource resourcesForType:self.resourceType setID:self.setID onlyRecent:YES];
        self.allResources = [CDResource resourcesForType:self.resourceType setID:self.setID onlyRecent:NO];
        
        // if not petphrases, insert defaults ones
        if ([self.allResources count] == 0 && self.resourceType == kRCTypePetPhrase) {
            self.allResources = [[MPResourceCenter sharedMPResourceCenter] loadDefaultPetPhrases];
        }
        
        // debug
        //
        for (CDResource *iResource in self.allResources) {
            DDLogVerbose(@"r: %@", iResource);
        }
        
        DDLogVerbose(@"RSV: got recent:%d all:%d", [self.recentResources count], [self.allResources count]);

        NSMutableArray *recentArray = [[NSMutableArray alloc] init];
        self.recentButtons = recentArray;
        [recentArray release];
        
        NSMutableArray *allArray = [[NSMutableArray alloc] init];
        self.allButtons = allArray;
        [allArray release];
        
        
        // Configure basic measurements
        //
        if (self.resourceType == kRCTypeSticker) {
            self.startX = kStickerStartX;
            self.startY = kStickerStartY;
            self.shiftX = kStickerShiftX;
            self.shiftY = kStickerShiftY;
            self.resourceWidth = kStickerWidth;
            self.resourceHeight = kStickerHeight;
        }
        else if (self.resourceType == kRCTypeEmoticon) {
            self.startX = kEmoticonStartX;
            self.startY = kEmoticonStartY;
            self.shiftX = kEmoticonShiftX;
            self.shiftY = kEmoticonShiftY;
            self.resourceWidth = kEmoticonWidth;
            self.resourceHeight = kEmoticonHeight;
        }
        else if (self.resourceType == kRCTypePetPhrase) {
            self.startX = kPetPhraseStartX;
            self.startY = kPetPhraseStartY;
            self.shiftX = kPetPhraseShiftX;
            self.shiftY = kPetPhraseShiftY;
            self.resourceWidth = kPetPhraseWidth;
            self.resourceHeight = kPetPhraseHeight;
            
            // no need for paging here
            self.pagingEnabled = NO;
        }
        
        //[self addRecentButtonViews];
        [self addAllButtonViews];
        
        // configure basic scroll view 
        // - so page numbers can be fed to page controller
        [self configureScrollView];
        
        
        // download resources if needed
        //
        //[self checkAndStartDownload]; // check if download is incomplete

        
        // layout buttons
        //[self layoutRecentButtonViews];
        //[self layoutAllButtonViews];
    
        
        // configure each page
        /*for (int i=0; i < pages; i++) {
            [self configurePage:i];
        }*/
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidDownload:) name:MP_RESOURCECENTER_DID_DOWNLOAD_RESOURCE_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleButtonSetPreviewImage:) name:MP_RESOURCEBUTTON_DID_SET_PREVIEW_IMAGE_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification object:nil];
        
    }
    return self;
}

#define RECENT_BTN_TAG  16000
#define DELETE_BTN_TAG  16001
#define ACTIVITY_TAG    16002

/*!
 @abstract add subviews for each page
 
 */
/*- (void) configurePage:(NSInteger)pageNumber {
    
    
    CGPoint leftCorner = CGPointMake(self.frame.size.width*pageNumber, 0.0);
    
    NSInteger startIndex = 0;
    NSInteger endIndex = 0;
    
    NSArray *resources = nil;
    
    BOOL isRecentPage = NO;
    
    // recent page
    if (pageNumber == 0) {
        resources = self.recentResources;
        isRecentPage = YES;
        if (self.resourceType == kRCTypePetPhrase) {
            resources = self.allResources;
            isRecentPage = NO;
        }
        startIndex = 0;
        endIndex = self.resourcesPerPage;
    }
    else {
        resources = self.allResources;
        startIndex = (pageNumber - 1)*self.resourcesPerPage;
        endIndex = startIndex + self.resourcesPerPage;
    }
    // cap endIndex to last item
    if (endIndex > [resources count]) {
        endIndex = [resources count];
    }
    
    // loop through resources and add them to this page
    //
    CGFloat startX = 0.0;
    CGFloat startY = 0.0;
    CGFloat shiftX = 0.0;
    CGFloat shiftY = 0.0;
    CGFloat resourceWidth = 0.0;
    CGFloat resourceHeight = 0.0;
    int itemsPerRow = 1;
    if (self.resourceType == kRCTypeSticker) {
        startX = kStickerStartX;
        startY = kStickerStartY;
        shiftX = kStickerShiftX;
        shiftY = kStickerShiftY;
        resourceWidth = kStickerWidth;
        resourceHeight = kStickerHeight;
    
        itemsPerRow = kRSVStickersPerRow;
    }
    else if (self.resourceType == kRCTypeEmoticon) {
        startX = kEmoticonStartX;
        startY = kEmoticonStartY;
        shiftX = kEmoticonShiftX;
        shiftY = kEmoticonShiftY;
        resourceWidth = kEmoticonWidth;
        resourceHeight = kEmoticonHeight;
        
        itemsPerRow = kRSVEmoticonPerRow;
    }
    else if (self.resourceType == kRCTypePetPhrase) {
        startX = kPetPhraseStartX;
        startY = kPetPhraseStartY;
        shiftX = kPetPhraseShiftX;
        shiftY = kPetPhraseShiftY;
        resourceWidth = kPetPhraseWidth;
        resourceHeight = kPetPhraseHeight;
        
        itemsPerRow = kRSVPetPhrasePerRow;
    }
    
    int j = 0; // number of resource for this page
    for (int i=startIndex; i < endIndex; i++) {
        
        CGFloat originX = j%itemsPerRow*shiftX + leftCorner.x + startX;
        CGFloat originY = j/itemsPerRow*shiftY + leftCorner.y + startY;
        CGRect resourceRect = CGRectMake(originX, originY, resourceWidth, resourceHeight);
        
        CDResource *iResource = [resources objectAtIndex:i];
        ResourceButton *resourceButton = [[ResourceButton alloc] initWithFrame:resourceRect resource:iResource];
        [resourceButton addTarget:self action:@selector(pressResource:) forControlEvents:UIControlEventTouchUpInside];
        if (isRecentPage) {
            resourceButton.tag = RECENT_BTN_TAG;    // tag so we can clear and reload this page
        }
        
        [self addSubview:resourceButton];
        [resourceButton release];

        j++;
    }
    // add back button for emoticon keypad
    //
    if (self.resourceType == kRCTypeEmoticon) {
        CGFloat originX = kRSVEmoticonPerPage%itemsPerRow*shiftX + leftCorner.x + startX;
        CGFloat originY = kRSVEmoticonPerPage/itemsPerRow*shiftY + leftCorner.y + startY;
        CGRect backRect = CGRectMake(originX, originY, resourceWidth, resourceHeight);
        
        UIButton *backButton = [[UIButton alloc] initWithFrame:backRect];
        [backButton setImage:[UIImage imageNamed:@"chat_attach_icon_back.png"] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(pressBackKey:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:backButton];
        [backButton release];
    }
    
}*/

#pragma mark - UI Setup


/*!
 @abstract Add recent buttons to this view
 
 @discussion views are all stacked on top of each other.  A separate method will lay them out.
 
 */
- (void) addRecentButtonViews {
    
    CGRect resourceRect = CGRectMake(0.0, 0.0, self.resourceWidth, self.resourceHeight);
    
    // clear out old buttons
    [self.recentButtons removeAllObjects];
    
    int i = 0;
    for (CDResource *iResource in self.recentResources) {
        
        // don't go over the one page limit
        if (i >= self.resourcesPerPage) {
            break;
        }
        
        ResourceButton *resourceButton = [[ResourceButton alloc] initWithFrame:resourceRect resource:iResource];
        [resourceButton addTarget:self action:@selector(pressResource:) forControlEvents:UIControlEventTouchUpInside];
        resourceButton.tag = RECENT_BTN_TAG;    // tag so we can clear and reload this page
        
        [self addSubview:resourceButton];
        [self.recentButtons addObject:resourceButton];
        [resourceButton release];
        i++;
    }
}

/*!
 @abstract Add all resource buttons to this view
 
 @discussion views are all stacked on top of each other.  A separate method will lay them out.
 
 */
- (void) addAllButtonViews {
    
    CGRect resourceRect = CGRectMake(0.0, 0.0, self.resourceWidth, self.resourceHeight);
    
    // clear out old buttons
    [self.allButtons removeAllObjects];
    
    BOOL didEncounterMissingImage = NO;
    
    
    
    int i=1;
    for (CDResource *iResource in self.allResources) {
        
        ResourceButton *resourceButton = [[ResourceButton alloc] initWithFrame:resourceRect resource:iResource];
        [resourceButton addTarget:self action:@selector(pressResource:) forControlEvents:UIControlEventTouchUpInside]; 
        
        
        // no image for petphase
        // - check if image is missing
        if (self.resourceType != kRCTypePetPhrase) {
            if (didEncounterMissingImage == NO) {
                UIImage *image = [resourceButton imageForState:UIControlStateNormal];
                if (!image) {
                    didEncounterMissingImage = YES;
                }
            }
            
            // hide remaining buttons
            if (didEncounterMissingImage) {
                //resourceButton.backgroundColor = [UIColor blueColor];
                resourceButton.alpha = 0.0;
            }
        }

        [self addSubview:resourceButton];
        [self.allButtons addObject:resourceButton];
        [resourceButton release];
        i++;
    }
    
    // add activity indicator
    if (didEncounterMissingImage) {
        
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        //activityIndicator.backgroundColor = [UIColor blackColor];
        activityIndicator.frame = CGRectMake(0.0, 0.0,
                                         activityIndicator.frame.size.width, 
                                         activityIndicator.frame.size.height);
        activityIndicator.hidesWhenStopped = YES;
        activityIndicator.tag = ACTIVITY_TAG;
        [self addSubview:activityIndicator];
        [activityIndicator release];
    }
}

#define kPetPhrasePageHeight 176.0

/*!
 @abstract configure scroll view
 
 - resource per row
 - resource per page
 - number of pages
 - set content size and current position
 
 */
- (void)configureScrollView {
    CGFloat pageWidth = self.bounds.size.width;
    CGFloat pageHeight = self.bounds.size.height;
    
    if (self.resourceType == kRCTypePetPhrase) {
        pageHeight = kPetPhrasePageHeight;
    }
    
    self.resourcesPerRow = floor(pageWidth/self.shiftX);
    NSUInteger rows = floor(pageHeight/self.shiftY);
    self.resourcesPerPage = self.resourcesPerRow * rows;
    
    // center the buttons horizontally
    //
    self.startX = (pageWidth - self.resourcesPerRow*self.shiftX)/2.0;
    
    // center vertically
    //
    CGFloat yBottomPadding = 20.0;
    if (self.resourceType == kRCTypePetPhrase) {
        yBottomPadding = 0.0;   // petphrase does not use page control
    }
    self.startY = (pageHeight - yBottomPadding - (rows-1)*self.shiftY - self.resourceHeight)/2.0;
    
    // emoticons has one back button
    if (self.resourceType == kRCTypeEmoticon) {
        self.resourcesPerPage--;
    }
    
    NSUInteger pages = 0;
    
    // only one page for pet phrase
    if (self.resourceType == kRCTypePetPhrase) {
        pages = 1.0;
        self.currentPage = 0;
    }
    else {
        pages = ceil([self.allResources count]/(CGFloat)self.resourcesPerPage) + 1;
        // start at page index 1 - (2nd page)
        //
        [self setContentOffset:CGPointMake(self.frame.size.width, 0.0)];
        self.currentPage = 1;
    }
    self.numberOfPages = pages;
    self.contentSize = CGSizeMake(pageWidth*pages, pageHeight);
    
    //self.contentSize = CGSizeMake(self.frame.size.width*pages, self.frame.size.height);
}


/*!
 @abstract Rect for resource Button
 
 @param isRecent Is this an recent resouce - put on first page, otherwise start on page 1
 @param isLastPosition Get the rect for the last position on this page
 
 */
- (CGRect)rectForButtonAtIndex:(NSUInteger)index isLastPosition:(BOOL)isLastPosition {
    
    CGFloat thisPage =  floor(index/(CGFloat)self.resourcesPerPage);
    CGPoint leftCorner = CGPointMake(self.frame.size.width*thisPage, 0.0);

    NSUInteger pageIndex = index%self.resourcesPerPage;
    if (isLastPosition) {
        pageIndex = self.resourcesPerPage;
    }    

    CGFloat originX = pageIndex%self.resourcesPerRow*shiftX + leftCorner.x + self.startX;
    CGFloat originY = (pageIndex/self.resourcesPerRow)*shiftY + leftCorner.y + startY;
    CGRect resourceRect = CGRectMake(originX, originY, self.resourceWidth, self.resourceHeight);
    
    return resourceRect;    
}


/*!
 @abstract Layout all resource buttons
 
 */
- (void) layoutRecentButtonViews {
    int i = 0;
    for (UIButton *iButton in self.recentButtons) {
      
        iButton.frame = [self rectForButtonAtIndex:i isLastPosition:NO];

        i++;
    }    
}


/*!
 @abstract Layout all resource buttons
 
 */
- (void) layoutAllButtonViews {
    
    int i = 0;
    BOOL didFindMissingImageButton = NO;
    
    for (ResourceButton *iButton in self.allButtons) {
        
        // pet phrase starts on page 0
        if (self.resourceType == kRCTypePetPhrase) {
            iButton.frame = [self rectForButtonAtIndex:i isLastPosition:NO];
            
            // redraw text otherwise it will look stretched out in landscape mode
            [iButton redrawTextView];
        }
        // others start on page 1
        else {
            iButton.frame = [self rectForButtonAtIndex:i+self.resourcesPerPage isLastPosition:NO];
            
            // missing image
            if (didFindMissingImageButton == NO && iButton.alpha == 0.0) {
                didFindMissingImageButton = YES;
                UIActivityIndicatorView *actView = (UIActivityIndicatorView *)[self viewWithTag:ACTIVITY_TAG];
                actView.center = iButton.center;
                [actView startAnimating];
            }
        }
        i++;
    }    
}


/*!
 @abstract Remove and add new delete buttons for Emoticon view
 - call after configuring scrollview
 
 Use:
 - run when laying subviews since delete buttons number and postion may have changed
 
 */
- (void)reloadDeleteButtons
{
    // only reload for these types
    if (self.resourceType == kRCTypeEmoticon) {
        
        // remove old recents
        [Utility removeSubviewsForView:self tag:DELETE_BTN_TAG];
        
        // add a delete button for each page
        for (int i=0; i < self.numberOfPages; i++) {
            
            // get first item index for each page
            NSUInteger index = i*self.resourcesPerPage;
            CGRect buttonRect = [self rectForButtonAtIndex:index isLastPosition:YES];
            // add a back button to the end
            UIButton *backButton = [[UIButton alloc] initWithFrame:buttonRect];
            [backButton setImage:[UIImage imageNamed:@"chat_attach_icon_back.png"] forState:UIControlStateNormal];
            [backButton addTarget:self action:@selector(pressBackKey:) forControlEvents:UIControlEventTouchUpInside];
            backButton.tag = DELETE_BTN_TAG;
            [self addSubview:backButton];
            [self.allButtons addObject:backButton];
            [backButton release];
        }
    }
}


/*!
 @abstract Changes to the desired page
 
 Use:
 - page control change the page of scroll view
 
 */
- (void)setPage:(NSInteger)pageNumber animated:(BOOL)animated
{
    	
    self.pageControlUsed = YES;
    CGPoint newPoint = CGPointMake(pageNumber*self.frame.size.width, 0.0);    
    [self setContentOffset:newPoint animated:animated];
}

/*!
 @abstract Reload recently used page
 
 Use:
 - call when ever a button is pressed
 
 */
- (void)reloadRecentPage
{
    // only reload for these types
    if (self.resourceType == kRCTypeEmoticon || self.resourceType == kRCTypeSticker) {
        
        // remove old recents
        [Utility removeSubviewsForView:self tag:RECENT_BTN_TAG];
        
        // get new recents
        self.recentResources = [CDResource resourcesForType:self.resourceType setID:self.setID onlyRecent:YES];
        
        // configure recent page again
        [self addRecentButtonViews];
        [self layoutRecentButtonViews];
    }
}


/*!
 @abstract Refresh missing buttons
 
 Use:
 - call when tab is selected to make sure all sticker buttons are showing
 
 */
- (void)refreshMissingButtons {
    
    if (self.resourceType == kRCTypePetPhrase) {
        return;
    }
    
    for (ResourceButton *iButton in self.allButtons) {
        
        // missing image        
        if (iButton.alpha == 0.0) {
            DDLogInfo(@"RSV: hidden button %@", iButton.resource.text);
            [iButton setPreviewImage];
        }
    }  
}

#pragma mark - UIView 

/*!
 @abstract Provide precise layout of views
 
 The default implementation of this method does nothing.
 
 Subclasses can override this method as needed to perform more precise layout of their subviews. You should override this method only if the autoresizing behaviors of the subviews do not offer the behavior you want. You can use your implementation to set the frame rectangles of your subviews directly.
 
 You should not call this method directly. If you want to force a layout update, call the setNeedsLayout method instead to do so prior to the next drawing update. If you want to update the layout of your views immediately, call the layoutIfNeeded method.
 */
- (void)layoutSubviews {
    
    //CGRect testFrame = self.frame;

    // only layout if orientation has changed
    // - otherwise this seems like a waste and will cause scrolling to freeze!
    //
    if (self.lastLayoutWidth != self.frame.size.width) {
        
        // modify parameters for petphrase
        //
        if (self.resourceType == kRCTypePetPhrase) {
            self.shiftX = self.frame.size.width - 20.0;
            self.resourceWidth = self.shiftX;
        }
        
        
        // configure basic scroll view
        [self configureScrollView];
        
        // layout buttons
        [self layoutAllButtonViews];
        [self reloadRecentPage];
        
        // layout delete buttons
        [self reloadDeleteButtons];
        self.lastLayoutWidth = self.frame.size.width;
    }
}


    

#pragma mark - Button


/*!
 @abstract Inform delegate that this resource was pressed
 
 */
- (void) pressBackKey:(id)sender {
        
    if ([self.resourceDelegate respondsToSelector:@selector(ResourceScrollView:pressDelete:)]) {
        [self.resourceDelegate ResourceScrollView:self pressDelete:nil];
    }
}

/*!
 @abstract Inform delegate that this resource was pressed
 
 */
- (void) pressResource:(id)sender {
    
    ResourceButton *resourceButton = (ResourceButton *)sender;

    if (self.resourceType != kRCTypePetPhrase) {
        [self reloadRecentPage];
    }
    
    if ([self.resourceDelegate respondsToSelector:@selector(ResourceScrollView:resource:)]) {
        [self.resourceDelegate ResourceScrollView:self resource:resourceButton.resource];
    }
}

#pragma mark - Scroll Methods


- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
    // which a scroll event generated from the user hitting the page control triggers updates from
    // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
    if (self.pageControlUsed)
    {
        // do nothing - the scroll was initiated from the page control, not the user dragging
        self.pageControlUsed = NO;
        return;
    }
    
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.frame.size.width;
    int page = floor((self.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.currentPage = page;
    
    if ([self.resourceDelegate respondsToSelector:@selector(ResourceScrollView:changePage:)]) {
        [self.resourceDelegate ResourceScrollView:self changePage:page];
    }
    
    
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    /*[self loadScrollViewWithPage:page - 1];
	 [self loadScrollViewWithPage:page];
	 [self loadScrollViewWithPage:page + 1];
	 */
    // A possible optimization would be to unload the views+controllers which are no longer visible
}

// At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.pageControlUsed = NO;
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.pageControlUsed = NO;
}

#pragma mark - Download

/*!
 @abstract start downloading resources that are still outstanding
 
 Runs only when initialized
 
 */
- (void) checkAndStartDownload {
    
    // only download emoticon and sticker
    //
    if (self.resourceType == kRCTypeSticker || 
        self.resourceType == kRCTypeEmoticon ) {
        
        // check and start download 
        //
        for (ResourceButton *iButton in self.allButtons) {
            
            if (iButton.alpha == 0.0) {
                [[MPResourceCenter sharedMPResourceCenter] downloadResource:iButton.resource force:NO isRetry:NO addPending:YES];
            }
        } 
    }
}

/*!
 @abstract check if the download resource is ours and udpate view appropriately
 */
- (void) handleDidDownload:(NSNotification *)notification {
    
    NSManagedObjectID *resourceID = [notification object];
    
    ResourceButton *foundButton = nil;
    
    // check if hidden views have images now
    //
    for (ResourceButton *iButton in self.allButtons) {
        
        // if hidden
        //
        if (iButton.alpha == 0.0) {
        
            // for downloaded resource set it's image
            if ([resourceID isEqual:[iButton.resource objectID]]) {
                [iButton setPreviewImage];
                foundButton = iButton;
                break;
            }
        }
    }
    
    // if emoticon then refresh all button images since all of them should be available
    if ([foundButton.resource rcType] == kRCTypeEmoticon) {
        for (ResourceButton *iButton in self.allButtons) {
            // if hidden
            //
            if (iButton.alpha == 0.0) {
                [iButton setPreviewImage];
            }
        }
    }
}


/*!
 @abstract Check if we need to move the activity indicator and stop it
 */
- (void) handleButtonSetPreviewImage:(NSNotification *)notification {
        
    BOOL stillDownloading = NO;
    UIActivityIndicatorView *actView = (UIActivityIndicatorView *)[self viewWithTag:ACTIVITY_TAG];
    
    // check if hidden views have images now
    //
    for (ResourceButton *iButton in self.allButtons) {
        
        // for first hidden button encountered, then set indicator location here
        //
        if (iButton.alpha == 0.0) {
            
            actView.center = iButton.center;
            stillDownloading = YES;
            break;

        }
    }
    
    // if no more buttons are downloading, then stop indicator
    if (!stillDownloading) {
        [actView stopAnimating];
    }
}

/*!
 @abstract If app becomes active and scroll view is showing, then refresh scrollview
 */
- (void) handleBecomeActive:(NSNotification *)notification {
    if (!self.isHidden) {
        [self refreshMissingButtons];
    }
}

@end
