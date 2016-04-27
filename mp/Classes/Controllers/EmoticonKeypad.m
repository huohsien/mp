//
//  EmoticonKeypad.m
//  mp
//
//  Created by Min Tsai on 1/5/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "EmoticonKeypad.h"
#import "TextEmoticonView.h"
#import "TKPageControl.h"
#import "AppUtility.h"
#import "CDResource.h"
#import "MPFoundation.h"



CGFloat const kKeypadHeight = 216.0;
CGFloat const kMainViewHeight = 176.0;

CGFloat const kEKTabWidth = 64.0;
CGFloat const kEKTabHeight = 40.0;

CGFloat const kEKPageControlHeight = 10.0;
CGFloat const kEKPageControlWidth = 300.0;
CGFloat const kEKPageControlMargin = 10.0;

@interface EmoticonKeypad (Private)
- (void)setKeypadForIndex:(NSInteger)keypadIndex;
@end

@implementation EmoticonKeypad

@synthesize delegate;
@synthesize tabButtons;

@synthesize pageController;
@synthesize currentScrollView;
@synthesize petPhraseScrollView;
@synthesize emoticonScrollView;
@synthesize stickerScrollViewD;

#define kStickerTabsNum 5

#define TAB_SCROLL_TAG          13000
#define EMOTICON_TAG            13001
#define PETPHRASE_TAG           13002

#define KEYBACK_VIEW_TAG        14001
#define STICKER_BASE_TAG        15001   // 15xxx reserved for stickers! don't use these


//SYNTHESIZE_SINGLETON_FOR_CLASS(EmoticonKeypad);


- (void) dealloc {
    
    for (TKTabButton *iButton in self.tabButtons){
        iButton.delegate = nil;
    }
    
    [pageController release];
    [currentScrollView release];
    [emoticonScrollView release];
    [petPhraseScrollView release];
    [stickerScrollViewD release];
    
    [tabButtons release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame displayMode:(EKMode)displayMode
{
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    // only use the origin, the size is ignored
    frame.size.width = appFrame.size.width;
    frame.size.height = kKeypadHeight;
    
    self = [super initWithFrame:frame];
    if (self) {
        
        // test reset
        //[CDResource deleteAllResources];
        
        // Initialization code
        self.autoresizesSubviews = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth ;
        self.backgroundColor = [UIColor blackColor];
        
        // add keypad view - background
        UIView *keypadView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, appFrame.size.width, kMainViewHeight)];
        keypadView.backgroundColor = [AppUtility colorForContext:kAUColorTypeKeypad];
        keypadView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight ;
        keypadView.tag = KEYBACK_VIEW_TAG;
        [self addSubview:keypadView];
        [keypadView release];
        
        // add page control
        //
        TKPageControl *newPageController = [[TKPageControl alloc] initWithFrame:CGRectMake((self.frame.size.width-kEKPageControlWidth)/2.0, kMainViewHeight-kEKPageControlHeight-kEKPageControlMargin, kEKPageControlWidth, kEKPageControlHeight)];
        newPageController.backgroundColor = [AppUtility colorForContext:kAUColorTypeKeypad];
        newPageController.currentPageImageFile =  @"chat_attach_icon_nowpage.png";
        newPageController.otherPageImageFile = @"chat_attach_icon_pages.png";
        newPageController.specialCurrentPageImageFile = @"chat_attach_icon_recent_prs.png";
        newPageController.specialOtherPageImageFile = @"chat_attach_icon_recent.png";
        newPageController.specialPageIndex = 0;
        newPageController.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
        newPageController.delegate = self;
        [self addSubview:newPageController];
        self.pageController = newPageController;
        [newPageController release];
        
        
        // add buttons
        //CGRect initFrame = CGRectMake(0.0, kMainViewHeight, kEKTabWidth, kEKTabHeight);
        CGRect initFrame = CGRectMake(0.0, 0.0, kEKTabWidth, kEKTabHeight);
        
        
        // add a blank underneath if some tabs are not showing
        //
        UIImage *blankImage = [Utility resizableImage:[UIImage imageNamed:@"chat_attach_tab_nor.png"] leftCapWidth:kEKTabWidth/2.0-1.0 topCapHeight:kEKTabHeight/2.0-1.0];
        UIImageView *blankView = [[UIImageView alloc] initWithImage:blankImage];
        blankView.frame = CGRectMake(0.0, kMainViewHeight, self.bounds.size.width, kEKTabHeight);
        blankView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:blankView];
        [blankView release];

        
        // add button scrollview
        //
        UIScrollView *tabScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, kMainViewHeight, self.bounds.size.width, kEKTabHeight)];
        
        tabScrollView.scrollEnabled = NO;
        /*
         @CONFIG Enable to allow scrolling of tab bars - change scrollEnabled above to YES
         
        tabScrollView.pagingEnabled = YES;
        tabScrollView.showsHorizontalScrollIndicator = YES;
        tabScrollView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
         */
        tabScrollView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        tabScrollView.contentSize = CGSizeMake(self.bounds.size.width*2.0, kEKTabHeight);
        tabScrollView.backgroundColor = [UIColor clearColor];
        tabScrollView.tag = TAB_SCROLL_TAG;
        [self addSubview:tabScrollView];
        
        
        // array to hold enabled tabs
        //
        NSMutableArray *tabs = [[NSMutableArray alloc] init];
        
        //if (displayMode != kEKModeHideEmoticonPetPhrase) {
            TKTabButton *emoticonButton = [[TKTabButton alloc] initWithFrame:initFrame normalImageFilename:@"chat_attach_tab_emoti_nor.png" selectedImageFilename:@"chat_attach_tab_emoti_prs.png" normalBackgroundImageFilename:@"chat_attach_tab_nor.png" selectedBackgroundImageFilename:@"chat_attach_tab_prs.png"];
            emoticonButton.delegate = self;
            emoticonButton.tag = EMOTICON_TAG;
            emoticonButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
            [tabScrollView addSubview:emoticonButton];
            [tabs addObject:emoticonButton];
            [emoticonButton release];
            
            TKTabButton *petButton = [[TKTabButton alloc] initWithFrame:initFrame normalImageFilename:@"chat_attach_tab_phrase_nor.png" selectedImageFilename:@"chat_attach_tab_phrase_prs.png" normalBackgroundImageFilename:@"chat_attach_tab_nor.png" selectedBackgroundImageFilename:@"chat_attach_tab_prs.png"];
            petButton.delegate = self;
            petButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
            petButton.tag = PETPHRASE_TAG;
            [tabScrollView addSubview:petButton];
            [tabs addObject:petButton];
            [petButton release];
        //}
        
        /*
         @CONFIG
         To add future sticker sets, just add the sticker image name prefix here
         */
        NSArray *stickerImagePrefixes = [NSArray arrayWithObjects: 
                                         @"chat_attach_tab_baby_",
                                         @"chat_attach_tab_bo2-emoti_",
                                         @"chat_attach_tab_cute_",
                                         nil];

        
        //if (displayMode != kEKModeHideSticker) {

            NSInteger sIndex = 0;
            for (NSString *iStickerImagePrefix in stickerImagePrefixes) {
                
                NSString *norFile = [NSString stringWithFormat:@"%@nor.png", iStickerImagePrefix];
                NSString *prsFile = [NSString stringWithFormat:@"%@prs.png", iStickerImagePrefix];
                
                TKTabButton *iStickerButton = [[TKTabButton alloc] 
                                               initWithFrame:initFrame 
                                               normalImageFilename:norFile 
                                               selectedImageFilename:prsFile 
                                               normalBackgroundImageFilename:@"chat_attach_tab_nor.png"
                                               selectedBackgroundImageFilename:@"chat_attach_tab_prs.png"];
                iStickerButton.delegate = self;
                iStickerButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
                iStickerButton.tag = STICKER_BASE_TAG+sIndex;
                [tabScrollView addSubview:iStickerButton];
                [tabs addObject:iStickerButton];
                [iStickerButton release];
                sIndex++;
            }
        
        //}
        [tabScrollView release];
        
        self.tabButtons = [NSArray arrayWithArray:tabs];
        [tabs release];
        
        // set frames
        int i = 0;
        for (UIButton *iTab in self.tabButtons) {
            iTab.frame = CGRectMake(kEKTabWidth*i, 0.0, kEKTabWidth, kEKTabHeight);
            i++;
        }

        // set emoticon first
        [self setKeypadForIndex:0];

        // add page controller
        
        
        // test emotion view
        /*NSArray *itemArray = [NSArray arrayWithObjects:@"test sdlkfdsjf sdlfdsjkf  sdfljtest", [UIImage imageNamed:@"Em_001.png"], 
                              @"ttt tt  sldjfsdf sdflkjsdf sdljfs tt tt tt ", [UIImage imageNamed:@"Em_017.png"], @"end end sdjfjakdlsf  asdfljdsl fj sdlfjdsfl",[UIImage imageNamed:@"Em_015.png"], [UIImage imageNamed:@"Em_017.png"],@"  sdlfjsdfkl  sdlfjsdjf k sdlfjsdj f sdlfj sdlfjsdf weiursffl seoru .", nil];
        //TextEmoticonView *testV = [[TextEmoticonView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 100.0) textImageArray:itemArray];
        //[testV sizeToFit];
        //testV.backgroundColor = [UIColor greenColor];
        [self addSubview:testV];
        [testV release];*/
        
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame displayMode:kEKModeDefault];
}

- (id)init {
    return [self initWithFrame:CGRectMake(0.0, 0.0, 1.0, 1.0) displayMode:kEKModeDefault];
}

/*!
 @abstract Sets frame origin
 */
- (void) setFrameOrigin:(CGPoint)frameOrigin {
    
    CGRect newFrame = self.frame;
    newFrame.origin = frameOrigin;
    self.frame = newFrame;
    
}


/*!
 @abstract Enable and disable tabs depending the on the diplay mode desired
 */
- (void) setMode:(EKMode)displayMode {
    
    BOOL enableEmoticon = YES;
    BOOL enablePetPhrase = YES;
    BOOL enableStickers = YES;
    
    switch (displayMode) {
        case kEKModeHideEmoticonPetPhrase:
            enableEmoticon = NO;
            enablePetPhrase = NO;
            break;
            
        case kEKModeHideSticker:
            enableStickers = NO;
            break;
            
        case kEKModeEmoticonOnly:
            enablePetPhrase = NO;
            enableStickers = NO;
            
        default:
            break;
    }

    
    int i = 0;
    for (TKTabButton *iTab in self.tabButtons) {
        if (iTab.tag == EMOTICON_TAG) {
            iTab.enabled = enableEmoticon;
        }
        else if (iTab.tag == PETPHRASE_TAG) {
            iTab.enabled = enablePetPhrase;
        }
        else {
            iTab.enabled = enableStickers;
        }
        
        if (iTab.enabled == YES) {
            iTab.hidden = NO;
            iTab.frame = CGRectMake(kEKTabWidth*i, 0.0, kEKTabWidth, kEKTabHeight);
            i++;
        }
        else {
            iTab.hidden = YES;
        }
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/



#pragma mark - UIView


/*!
 @abstract Highlist the scroll indicator after being added as a subview
 */
//- (void)didAddSubview:(UIView *)subview {
- (void) didMoveToSuperview {
    UIScrollView *tabSV = (UIScrollView *)[self viewWithTag:TAB_SCROLL_TAG];
    [tabSV flashScrollIndicators];
}



#pragma mark - TKTabButton

/*!
 @abstract Show the proper keypad view and lazy load views
 */
- (void)setKeypadForIndex:(NSInteger)keypadIndex {
    
    UIView *keypadView = [self viewWithTag:KEYBACK_VIEW_TAG];
    CGRect keypadRect =  keypadView.frame; //CGRectMake(0.0, 0.0, self.bounds.size.width, kMainViewHeight);
    
    TKTabButton *buttonPressed = (TKTabButton *)[self.tabButtons objectAtIndex:keypadIndex];
    
    int buttonTag = buttonPressed.tag;

    // set image
    for (TKTabButton *iButton in self.tabButtons){
        if (iButton == buttonPressed) {
            [iButton setImagePressed:YES];
        }
        else {
            [iButton setImagePressed:NO];
        }
    }

    
    // emoticon
    if (buttonTag == EMOTICON_TAG) {
        if (!self.emoticonScrollView) {
            ResourceScrollView *newView = [[ResourceScrollView alloc] initWithFrame:keypadRect type:kRCTypeEmoticon setID:0];
            newView.resourceDelegate = self;
            [self insertSubview:newView atIndex:1];
            self.emoticonScrollView = newView;
            [newView release];
        }
        // set pages and current page
        //
        self.currentScrollView = self.emoticonScrollView;
    }
    else {
        [self.emoticonScrollView setHidden:YES];
    }
    
    // pet phrase
    if (buttonTag == PETPHRASE_TAG) {
        if (!self.petPhraseScrollView) {
            ResourceScrollView *newView = [[ResourceScrollView alloc] initWithFrame:keypadRect type:kRCTypePetPhrase setID:0];
            newView.resourceDelegate = self;
            [self insertSubview:newView atIndex:1];
            self.petPhraseScrollView = newView;
            [newView release];
        }
        // set pages and current page
        //
        self.currentScrollView = self.petPhraseScrollView;
    }
    else {
        [self.petPhraseScrollView setHidden:YES];
    }
    
    // hide all sticker buttons
    // - only the selected one will be shown
    //
    NSArray *stickerViews = [self.stickerScrollViewD allValues];
    for (ResourceScrollView *iView in stickerViews) {
        iView.hidden = YES;
    }
    
    // sticker 1 to N
    if (buttonTag >= STICKER_BASE_TAG && buttonTag < STICKER_BASE_TAG+20) {
        
        NSInteger stickerSetID = buttonTag - STICKER_BASE_TAG;

        // lazy create stickerD
        //
        if (!self.stickerScrollViewD) {
            NSMutableDictionary *sDict = [[NSMutableDictionary alloc] initWithCapacity:20];
            self.stickerScrollViewD = sDict;
            [sDict release];
        }
        
        ResourceScrollView *stickerScrollView = [self.stickerScrollViewD objectForKey:[NSNumber numberWithInt:stickerSetID]];
        
        if (!stickerScrollView) {
            
            stickerScrollView = [[[ResourceScrollView alloc] initWithFrame:keypadRect type:kRCTypeSticker setID:stickerSetID] autorelease];
            
            stickerScrollView.resourceDelegate = self;
            [self insertSubview:stickerScrollView atIndex:1];
            
            [self.stickerScrollViewD setObject:stickerScrollView forKey:[NSNumber numberWithInt:stickerSetID]];
        }
        // refresh missing stickers in case we need to start download again
        else {
            [stickerScrollView refreshMissingButtons];
        }
        
        self.currentScrollView = stickerScrollView;
    
    }
    
    // set environment for new current scroll view
    //
    [self.currentScrollView setHidden:NO];
    
    self.pageController.numberOfPages = self.currentScrollView.numberOfPages;
    self.pageController.currentPage = self.currentScrollView.currentPage;
    [self bringSubviewToFront:self.pageController];
}


/*!
 @abstract Tab Button got a control event - delegate should control how tabs images changes
 */
- (void)TKTabButton:(TKTabButton *)tabButton gotControlEvent:(UIControlEvents)controlEvent {
    
    // if tap down
    // - set that button as selected and clear the rest
    //
    if (controlEvent == UIControlEventTouchDown) {
        
        int buttonIndex = [self.tabButtons indexOfObject:tabButton];
        
        if (buttonIndex != NSNotFound) {
            [self setKeypadForIndex:buttonIndex];
        }
        
    }
    // optionally - if double tap, go to first page of this set
    //
    
}

#pragma mark - ResourceScrollView Delegate

/*!
 @abstract Did press a resource on a scroll view keypad
 */
- (void)ResourceScrollView:(ResourceScrollView *)resourceScrollView resource:(CDResource *)resource {
    
    NSString *soundFile = @"tap.caf";
    [Utility asPlaySystemSoundFilename:soundFile];
    
    if ([self.delegate respondsToSelector:@selector(EmoticonKeypad:resource:)]) {
        [self.delegate EmoticonKeypad:self resource:resource];
    }    
}

/*!
 @abstract User pressed delete key - for emoticon
 */
- (void)ResourceScrollView:(ResourceScrollView *)resourceScrollView pressDelete:(id)sender {
    
    NSString *soundFile = @"tap.caf";
    [Utility asPlaySystemSoundFilename:soundFile];
    
    if ([self.delegate respondsToSelector:@selector(EmoticonKeypad:pressDelete:)]) {
        [self.delegate EmoticonKeypad:self pressDelete:sender];
    }  
}

/*!
 @abstract User scrolled this view to a new page
 */
- (void)ResourceScrollView:(ResourceScrollView *)resourceScrollView changePage:(NSUInteger)page{
    self.pageController.currentPage = page;
}


#pragma mark - TKPageControl Delegate 

/*!
 @abstract Informs delegate that the current page should change
 
 */
- (void)TKPageControl:(TKPageControl *)pageControl currentPageChanged:(NSInteger)currentPage{
    
    [self.currentScrollView setPage:currentPage animated:YES];
    
}



@end
