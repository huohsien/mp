/*!
 @header HiddenChatView
 
 Hidden Chat view to manage PIN.
 - lock/unlock HC
 - Set/Change PIN
 
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <UIKit/UIKit.h>

/*!
 
 kHCViewStatusClose                 HC view is closed and reset to initial state
 kHCViewStatusOpen,                 
 kHCViewStatusEnable,               HC view is asking is users would like to enable HC
 kHCViewStatusUnlockPIN,            Unlock HC mode
 kHCViewStatusChangePIN,            Start change PIN process
 kHCViewStatusChangePINConfirm,     Confirm new PIN
 kHCViewStatusChangePINUnlockFirst, Always enter new PIN once
 kHCViewStatusChangePINEnter        Enter new PIN for first time
 
 
 */
typedef enum {
    kHCViewStatusClose,
    kHCViewStatusOpen,
    kHCViewStatusEnable,
    kHCViewStatusUnlockPIN,
    kHCViewStatusChangePIN,
    kHCViewStatusChangePINConfirm,
    kHCViewStatusChangePINUnlockFirst,
    kHCViewStatusChangePINEnter,
    
	kTableStatusNormal,
	kTableStatusPullToReload,
	kTableStatusReleaseToReload,
	kTableStatusLoading
} HCViewStatus;


@class HiddenChatView;

@protocol HiddenChatViewDelegate <NSObject>

/*!
 @abstract Call when header view wants to close itself
 */
- (void)HiddenChatView:(HiddenChatView *)view closeWithAnimation:(BOOL)animated;

@optional;

/*!
 @abstract Call when PIN display should be shown
 */
- (void)HiddenChatView:(HiddenChatView *)view showPINDisplayWithHeight:(CGFloat)height;

/*!
 @abstract Call when pin animation is completed
 @discussion Used to show cancel button in integrated view's navbar
 */
- (void)HiddenChatView:(HiddenChatView *)view showPINDisplayAnimationDidComplete:(BOOL)didComplete;

/*!
 @abstract Notifiy Delegate that unlock was successful
 */
- (void)HiddenChatView:(HiddenChatView *)view unlockDidSucceed:(BOOL)didSucceed;

/*!
 @abstract Notifiy Delegate that lock was successful
 */
- (void)HiddenChatView:(HiddenChatView *)view lockDidSucceed:(BOOL)didSucceed animated:(BOOL)animated;

@end


/*!
 
 tableStatus					status of this table - pull to reload, release to reload, or loading
 

 
 */
@interface HiddenChatView : UIView <UITextFieldDelegate>{
	
    id <HiddenChatViewDelegate> delegate;
    
    BOOL isAlignedToTop;
    
	HCViewStatus viewStatus;
    
    UIView *containerView;
    UIButton *frameButton;
    
    NSString *tempNewPIN;
    BOOL allowEnterPIN;
    
    UILabel *eLabel;
    UILabel *fLabel;
    UILabel *gLabel;
    UILabel *hLabel;
    
    UITextField *hiddenTextField;
    
    NSTimer *performTimer;
    
	BOOL isFlipped;
}

@property (nonatomic, assign) id <HiddenChatViewDelegate> delegate;

@property (nonatomic, assign) HCViewStatus viewStatus;
@property BOOL isFlipped;


/*! view is aligned to top of parent view - otherwise aligned with bottom */
@property (nonatomic, assign) BOOL isAlignedToTop;

/*! container view that wraps wall and code view together */
@property (nonatomic, retain) UIView *containerView;

/*! frame reference so we can easily access it */
@property (nonatomic, retain) UIButton *frameButton;

/*! store newPIN to confirm later */
@property (nonatomic, retain) NSString *tempNewPIN;

/*! Should user be allowed to enter pin at this time */
@property (nonatomic, assign) BOOL allowEnterPIN;

/*! labels to show PIN number */
@property (nonatomic, retain) UILabel *eLabel;
@property (nonatomic, retain) UILabel *fLabel;
@property (nonatomic, retain) UILabel *gLabel;
@property (nonatomic, retain) UILabel *hLabel;


/*! hidden text field to store user's PIN entry */
@property (nonatomic, retain) UITextField *hiddenTextField;

/*! Use to perform delayed method calls */
@property (nonatomic, retain) NSTimer *performTimer;

- (id)initWithFrame:(CGRect)frame isAlignedToTop:(BOOL)alignedToTop;

- (void)setStatus:(HCViewStatus)newStatus;

- (CGFloat) openViewThreshold;
- (CGFloat) openViewHeight;
- (void) updateHiddenChatBadge;


- (void) flipImageAnimated:(BOOL)animated;
- (void) moveImage:(CGFloat)position animated:(BOOL)animated;
- (void) toggleActivityView:(BOOL)isON;

- (void) pressLockNowNoAnimation:(id)sender;

@end