//
//  LetterController.h
//  mp
//
//  Created by Min Tsai on 2/6/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

/*!
 @header LetterController
 
 Creates and composes a letter.
 - select letter paper
 - enter to, from and body text
 - preview letter to be sent
 
 Usage:
 - allocate
 - set .letterMode attribute - control if top right button't title is send or next
 - set .toName - name of recipient
 - use delegate to get informed when next or send is tapped
 
 
 Example:
 
 // take snapshot of background image to use for letter view
 //
 UIImage *dialogBackView = [Utility imageFromUIView:self.view];
 
 LetterController *nextController = [[LetterController alloc] init];
 nextController.letterMode = kLCModeSend;
 nextController.toName = toName;
 nextController.backImage = dialogBackView;
 nextController.delegate = self;
 
 // Create nav controller to present modally
 UINavigationController *navigationController = [[UINavigationController alloc]
 initWithRootViewController:nextController];            
 [AppUtility customizeNavigationController:navigationController];
 
 [self presentModalViewController:navigationController animated:YES];
 [navigationController release];
 [nextController release];
 
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */


#import <UIKit/UIKit.h>
#import "EmoticonKeypad.h"

/*!
 @abstract Edit mode that affects the UI interface for edit view
 
 kLCModeCreate  Only create letter, but will be followed by next step
 kLCModeSend    Create and sends letter out directly
 
 */
typedef enum {
    kLCModeCreate = 0,
    kLCModeSend = 1
} LCMode;


@class LetterController;
@class TextEmoticonView;

@protocol LetterControllerDelegate <NSObject>

/*!
 @abstract Call when letter creation is complete and ready to send
 */
- (void)LetterController:(LetterController *)view letterImage:(UIImage *)letterImage letterID:(NSString *)letterID;

@end




@interface LetterController : UIViewController <UITextViewDelegate, UITextFieldDelegate, EmoticonKeypadDelegate, UIAlertViewDelegate>{
    
    id <LetterControllerDelegate> delegate;
    LCMode letterMode;
    NSString *toName;
    
    UIImage *backImage;
    
    NSArray *letterResources;
    UIImageView *letterView;
    NSString *letterID;
    
    // base elements
    UIScrollView *baseScrollView;
    UIPageControl *selectPageControl;
    BOOL pageControlUsed;
    UIButton *keyboardButton;
    EmoticonKeypad *emoticonKeypad;
    UILabel *charCountLabel;
    
    // text elements
    UITextField *toField;
    UITextField *fromField;
    UITextView *bodyTextView;
    TextEmoticonView *bodyTEView;
    
    // background images
    UIImageView *toBackView;
    UIImageView *fromBackView;
    UIImageView *bodyBackView;
    
    // select letter view
    UIScrollView *selectionView;
    NSMutableArray *selectLetterButtons;
    
}

/*! Delegate that handle letter after creation */
@property (nonatomic, assign) id <LetterControllerDelegate> delegate;

/*! Indicates how we are using this VC */
@property (nonatomic, assign) LCMode letterMode;

/*! store all possible letter types here */
@property (nonatomic, retain) NSArray *letterResources;


/*! Suggested name for to field */
@property (nonatomic, retain) NSString *toName;

/*! Optional background image */
@property (nonatomic, retain) UIImage *backImage;


/*! Letter background image view */
@property (nonatomic, retain) UIImageView *letterView;

/*! ID of the selected letter resource */
@property (nonatomic, retain) NSString *letterID;


/*! shows and switch between keyboards */
@property (nonatomic, retain) UIButton *keyboardButton;

/*! counts and limits body text */
@property (nonatomic, retain) UILabel *charCountLabel;


/*! emoticon keypad view */
@property (nonatomic, retain) EmoticonKeypad *emoticonKeypad;


/*! vertical scroll view */
@property (nonatomic, retain) UIScrollView *baseScrollView;

/*! page control used for letter selection */
@property (nonatomic, retain) UIPageControl *selectPageControl;

/*! Indicate if scrolling was initiated by pagecontrol - prevent feedback loop */
@property (nonatomic, assign) BOOL pageControlUsed;





// UI elements
/*! top to field */
@property (nonatomic, retain) UITextField *toField;

/*! from signature field */
@property (nonatomic, retain) UITextField *fromField;

/*! body of the letter */
@property (nonatomic, retain) UITextView *bodyTextView;

/*! actual body of letter */
@property (nonatomic, retain) TextEmoticonView *bodyTEView;


/*! Edit background views */
@property (nonatomic, retain) UIImageView *toBackView;
@property (nonatomic, retain) UIImageView *fromBackView;
@property (nonatomic, retain) UIImageView *bodyBackView;

/*! horizontal scroll view for letter selection */
@property (nonatomic, retain) UIScrollView *selectionView;

/*! letter selection button */
@property (nonatomic, retain) NSMutableArray *selectLetterButtons;

@end
