//
//  EmoticonKeypad.h
//  mp
//
//  Created by Min Tsai on 1/5/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TKTabButton.h"
#import "ResourceScrollView.h"
#import "TKPageControl.h"


/*!
 @abstract display mode for keypad
 
 Default                Show all tabs
 HideSticker            Don't show any sticker tabs
 HideEmoticonPetPhrase  Don't show emoticon and petphrase tabs
 
 */
typedef enum {
	kEKModeDefault = 0,
    kEKModeHideSticker = 1,
	kEKModeHideEmoticonPetPhrase = 2,
    kEKModeEmoticonOnly = 3
} EKMode;


@class CDResource;
@class EmoticonKeypad;
@class TKPageControl;

/*!
 Delegate that handles input from this view's controls
 */
@protocol EmoticonKeypadDelegate <NSObject>
/*!
 @abstract User pressed this resource
 
 */
- (void)EmoticonKeypad:(EmoticonKeypad *)emoticonKeypad resource:(CDResource *)resource;

/*!
 @abstract User pressed delete key
 */
- (void)EmoticonKeypad:(EmoticonKeypad *)emoticonKeypad pressDelete:(id)sender;

@end


@interface EmoticonKeypad : UIView <TKTabButtonDelegate, ResourceScrollViewDelegate, TKPageControlDelegate> {
    
    id <EmoticonKeypadDelegate> delegate;
    NSArray *tabButtons;
    
    TKPageControl *pageController;
    
    ResourceScrollView *currentScrollView;
    ResourceScrollView *emoticonScrollView;
    ResourceScrollView *petPhraseScrollView;
    
    NSMutableDictionary *stickerScrollViewD;
    
    
}

@property (nonatomic, assign) id <EmoticonKeypadDelegate> delegate;

/*! keep track of tab buttons */
@property (nonatomic, retain) NSArray *tabButtons;

/*! Shows page indicator for scrollviews */
@property (nonatomic, retain) TKPageControl *pageController;

/*! keep track of current scroll view */
@property (nonatomic, retain) ResourceScrollView *currentScrollView;

/*! keypad view for emoticons */
@property (nonatomic, retain) ResourceScrollView *emoticonScrollView;

/*! keypad view for petphrases */
@property (nonatomic, retain) ResourceScrollView *petPhraseScrollView;

/*! Caches created sticker scroll views: key (setID NSNumber) - value (scrollview) */
@property (nonatomic, retain) NSMutableDictionary *stickerScrollViewD;


/*!
 @abstract creates singleton object
 */
//+ (EmoticonKeypad *)sharedEmoticonKeypad;

- (id)initWithFrame:(CGRect)frame displayMode:(EKMode)displayMode;
- (void) setFrameOrigin:(CGPoint)frameOrigin;
- (void) setMode:(EKMode)displayMode;
- (void) setKeypadForIndex:(NSInteger)keypadIndex;

@end
