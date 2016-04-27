//
//  AddFriendAlertView.m
//  mp
//
//  Created by Min Tsai on 2/24/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "AddFriendAlertView.h"
#import "MPFoundation.h"
#import "CDContact.h"
#import "MPContactManager.h"
#import "MPFoundation.h"

/*! 
 inform object that contact was added or blocked
 Notification used since there could be several headshots showing 1-M notification needed
 */
NSString* const MP_ADDFRIENDALERT_CONTACT_CHANGED_NOTIFICATION = @"MP_ADDFRIENDALERT_CONTACT_CHANGED_NOTIFICATION";


@implementation AddFriendAlertView

@synthesize contact;

#define ADD_BTN_TAG     13001
#define BLOCK_BTN_TAG   13002
#define ALERT_VIEW_TAG  13003

#define kAlertWidth        240.0
#define kAlertHeight       200.0

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [contact release];
    [super dealloc];
    
}

- (id)initWithFrame:(CGRect)frame contact:(CDContact *)newContact 
{
    self.contact = newContact;
    //CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        // hide view so it can fade in
        self.alpha = 0.0;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
        self.userInteractionEnabled = YES;
        
        // Add Letter background
        // - hide keypad when tapped
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(pressClose:)];
        tapRecognizer.numberOfTapsRequired = 1;
        tapRecognizer.delegate = self;
        [self addGestureRecognizer:tapRecognizer];
        [tapRecognizer release];
        
        
        // add alert view
        // - center of the view
        //
        CGRect alertRect = CGRectMake((self.frame.size.width-kAlertWidth)/2.0, (self.frame.size.height-kAlertHeight)/2.0, kAlertWidth, kAlertHeight);
        UIImageView *alertView = [[UIImageView alloc] initWithFrame:alertRect];
        alertView.userInteractionEnabled = YES;
        alertView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |  UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        alertView.image = [UIImage imageNamed:@"std_icon_bk_popup.png"];
        alertView.tag = ALERT_VIEW_TAG;
        [self addSubview:alertView];
    
        
        // add close button
        //
        // - dismisses view    
        UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(kAlertWidth-40.0, 0.0, 40.0, 40.0)];
        closeButton.contentMode = UIViewContentModeCenter;
        [closeButton setImage:[UIImage imageNamed:@"std_icon_delete2_nor.png"] forState:UIControlStateNormal];
        [closeButton setImage:[UIImage imageNamed:@"std_icon_delete2_prs.png"] forState:UIControlStateHighlighted];
        closeButton.backgroundColor = [UIColor clearColor];
        [closeButton addTarget:self action:@selector(pressClose:) forControlEvents:UIControlEventTouchUpInside];
        [alertView addSubview:closeButton];
        [closeButton release];
        
        // default photo button
        //
        UIImageView *frameView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"friend_icon_popup_frame.png"]];
        frameView.frame = CGRectMake((kAlertWidth-105.0)/2.0, 10.0, 105.0, 105.0);
        [alertView addSubview:frameView];
        
        // photo image view
        //
        UIImageView *headShotView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"friend_icon_popup_bear.png"]];
        headShotView.frame = CGRectMake(11.0, 11.0, 85.0, 85.0);
        [frameView addSubview:headShotView];
        
        
        // photo view
        //
        /*UIImageView *headShotView = [[UIImageView alloc] initWithFrame:CGRectMake(50.0, 15.0, 98.0, 98.0)];
        headShotView.userInteractionEnabled = YES;
        headShotView.image = [UIImage imageNamed:@"profile_headshot_bear3.png"];
        [alertView addSubview:headShotView];
        
        // actual image
        //
        UIButton *photoView = [[UIButton alloc] initWithFrame:CGRectMake(6.5, 5.5, 85.0, 85.0)];
        photoView.imageView.contentMode = UIViewContentModeScaleAspectFill;
        photoView.backgroundColor = [UIColor clearColor];
        photoView.userInteractionEnabled = NO;
        //photoView.alpha = 0.5;
        //[photoView addTarget:self action:@selector(pressHeadShot:) forControlEvents:UIControlEventTouchUpInside];
        [headShotView addSubview:photoView];
        */
        
        MPImageManager *imageM = [[MPImageManager alloc] init];
        UIImage *gotImage = [imageM getImageForObject:self.contact context:kMPImageContextList];
        if (gotImage) {
            headShotView.image = gotImage;
        }
        else {
            headShotView.image = [UIImage imageNamed:@"friend_icon_popup_bear.png"];
        }
        [imageM release];
        
        //[photoView release];
        [frameView release];
        [headShotView release];
        
        
        // message label
        //
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 118.0, kAlertWidth-40.0, 20.0)];
        [AppUtility configLabel:messageLabel context:kAULabelTypeBlackSmall];
        messageLabel.backgroundColor = [UIColor clearColor];
        messageLabel.textAlignment = UITextAlignmentCenter;
        //messageLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Add %@ as your friend?", @"AddFriendAlertAlert - text: Add or block a contact"),[self.contact displayName]];
        messageLabel.text = [self.contact displayName];
        [alertView addSubview:messageLabel];
        [messageLabel release];
        
        // Block button
        //
        UIButton *blockButton = [[UIButton alloc] initWithFrame:CGRectMake(35.0, kAlertHeight-55.0, 75.0, 35.0)];
        [AppUtility configButton:blockButton context:kAUButtonTypeRed3];
        blockButton.backgroundColor = [UIColor clearColor];
        [blockButton addTarget:self action:@selector(pressBlock:) forControlEvents:UIControlEventTouchUpInside];
        [blockButton setTitle:NSLocalizedString(@"Block", @"AddFriendAlert - button: block a contact") forState:UIControlStateNormal];
        blockButton.tag = BLOCK_BTN_TAG;
        [alertView addSubview:blockButton];
        [blockButton release];
        
        // Add button
        //
        UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(130.0, kAlertHeight-55.0, 75.0, 35.0)];
        [AppUtility configButton:addButton context:kAUButtonTypeGreen3];
        addButton.backgroundColor = [UIColor clearColor];
        [addButton addTarget:self action:@selector(pressAdd:) forControlEvents:UIControlEventTouchUpInside];
        [addButton setTitle:NSLocalizedString(@"Add", @"AddFriendAlert - button: add a new friend") forState:UIControlStateNormal];
        addButton.tag = ADD_BTN_TAG;
        [alertView addSubview:addButton];
        [addButton release];
        
        [alertView release];
        
    }
    return self;
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
 @abstract Show letter animated
 
 Use:
 - call adding letter as an overlay to fade in
 */
- (void) showAnimated:(BOOL)animated {
    
    if (animated) {
        [UIView animateWithDuration:kMPParamAnimationStdDuration 
                         animations:^{
                             self.alpha = 1.0;
                         }];
    }
    else {
        self.alpha = 1.0;
    }
}



/*!
 @abstract Called after view added as subview
 */
- (void)didAddSubview:(UIView *)subview {
    [self showAnimated:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processGetUserInfo:) name:MP_HTTPCENTER_GETUSERINFO_NOTIFICATION object:nil];
    
    // observe block events
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(handleBlock:) name:MP_HTTPCENTER_BLOCK_NOTIFICATION object:nil];
    
}




#pragma mark - Button


/*!
 @abstract pressed add - add this found user as a friend!
 
 Submit presence query server first
 
 */
- (void)pressAdd:(id) sender {
    
    [AppUtility startActivityIndicator];
    
    // userID to tag this request
    // - so we can identify if response is for us
    [[MPHTTPCenter sharedMPHTTPCenter] getUserInformation:[NSArray arrayWithObject:self.contact.userID] action:kMPHCQueryTagAdd idTag:self.contact.userID itemType:kMPHCItemTypeUserID];
    
}

/*!
 @abstract block friend
 */
- (void)pressBlock:(id)sender {

    [AppUtility startActivityIndicator];
    [[MPHTTPCenter sharedMPHTTPCenter] blockUser:self.contact.userID];
    
}



/*!
 @abstract Dismiss this view
 */
- (void) pressClose:(id)sender {
    [UIView animateWithDuration:kMPParamAnimationStdDuration 
                     animations:^{
                         self.alpha = 0.0;
                     } 
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self removeFromSuperview];
                         }
                     }
     ];
}


#pragma mark - Handlers

- (void) showFailureAlert {
    
    NSString *title = NSLocalizedString(@"Add Friend", @"AddFriendAlert - alert title:");
    NSString *detMessage = NSLocalizedString(@"Add friend failed. Try again later.", @"AddFriendAlert - alert: Inform of failure");
    
    [Utility showAlertViewWithTitle:title message:detMessage];
    
}

/*!
 @abstract Did add friend process succeed for the M+ ID friend?
 
 If successful, then add this person as a friend in the DB, update new friend badge
 
 // notification object
 //
 NSMutableDictionary *newD = [[NSMutableDictionary alloc] initWithDictionary:responseDictionary];
 [newD setValue:presenceArray forKey:@"array"];
 
 */
- (void) processGetUserInfo:(NSNotification *)notification {
    
    [AppUtility stopActivityIndicator];
    
    BOOL didAdd = [MPContactManager processAddFriendNotification:notification contactToAdd:self.contact];
    if (didAdd) {

        // dismiss view
        //
        [self pressClose:nil];
        
        // inform message view that so it can update headshot view
        // - remove + icon
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_ADDFRIENDALERT_CONTACT_CHANGED_NOTIFICATION object:self.contact];
    }
}

/*!
 @abstract process block response
 
 Successful case
 <Block>
 <cause>0</cause>
 </Block>
 
 Exception case
 <Block>
 <cause>602</cause>
 <text>invalid USERID!</text>
 </Block>
 
 */
- (void) handleBlock:(NSNotification *)notification {
    //[AppUtility stopActivityIndicator:self.navigationController];
    
    NSDictionary *responseD = [notification object];
    
    // go ahead and block user
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        NSManagedObjectID *blockUserObjectID = [self.contact objectID];
        
        // block user
        //
        dispatch_async([AppUtility getBackgroundMOCQueue], ^{
            
            CDContact *blockContact = (CDContact *)[[AppUtility cdGetManagedObjectContext] objectWithID:blockUserObjectID];
            
            [blockContact blockUser];
            [AppUtility cdSaveWithIDString:@"AFAV: blocked users" quitOnFail:NO];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self pressClose:nil];
                
                // inform message view that so it can update headshot view
                // - remove + icon
                [[NSNotificationCenter defaultCenter] postNotificationName:MP_ADDFRIENDALERT_CONTACT_CHANGED_NOTIFICATION object:self.contact];
                
            });
        });
        
    }
    // ask to confirm
    else {
        
        NSString *alertTitle = NSLocalizedString(@"Block Friend", @"FriendInfo - alert title:");
        NSString *alertMessage = NSLocalizedString(@"Block failed. Try again later.", @"FriendInfo - alert: Inform of failure");
        [Utility showAlertViewWithTitle:alertTitle message:alertMessage];
    }
}

#pragma mark - UIGestureRecognizer

/*!
 @abstract Determine is touch should be received
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    // don't accept touch over alert view
    // - so alert view taps will not dismiss this view itself
    //
    
    CGPoint pointInView = [touch locationInView:gestureRecognizer.view];
    
    if ( [gestureRecognizer isMemberOfClass:[UITapGestureRecognizer class]] ) {
        
        UIView *alertView = [self viewWithTag:ALERT_VIEW_TAG];
        if (CGRectContainsPoint(alertView.frame, pointInView))
            return NO;
    } 
    return YES;
}


@end

