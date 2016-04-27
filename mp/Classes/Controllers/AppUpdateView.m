//
//  AppUpdateView.m
//  mp
//
//  Created by Min Tsai on 4/12/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "AppUpdateView.h"
#import "MPFoundation.h"

#define kUpdateButtonSize 152.0

@implementation AppUpdateView

- (id)initWithFrame:(CGRect)frame
{
    
    CGRect appFrame = [Utility appFrame];
    //frame = CGRectMake(0.0, 0.0, appFrame.size.width, appFrame.size.height);
    
    self = [super initWithFrame:appFrame];
    if (self) {
        // Initialization code
                
        
        // hide view so it can fade in
        self.alpha = 0.0;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:1.0];
        self.userInteractionEnabled = YES;
        
        
        // update message label
        //
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 80.0, appFrame.size.width, 40.0)];
        messageLabel.backgroundColor = [UIColor clearColor];
        messageLabel.numberOfLines = 2;
        messageLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
        messageLabel.textColor = [UIColor whiteColor];
        messageLabel.textAlignment = UITextAlignmentCenter;
        messageLabel.text = NSLocalizedString(@"<app force update messasge>", @"AppUpdate - text: Message to encourage users to update to the new version.");
        [self addSubview:messageLabel];
        [messageLabel release];
        
        
        // update button
        //
        UIButton *updateButton = [[UIButton alloc] initWithFrame:CGRectMake((appFrame.size.width - kUpdateButtonSize)/2.0, 130.0, kUpdateButtonSize, kUpdateButtonSize)];
        [updateButton setBackgroundImage:[UIImage imageNamed:@"app_icon_force_update_nor.png"] forState:UIControlStateNormal];
        [updateButton setContentEdgeInsets:UIEdgeInsetsMake(120.0, 0.0, 0.0, 0.0)];
        [updateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        updateButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
        [updateButton setTitle:NSLocalizedString(@"Update Now", @"AppUpdate - button: tap to update app now") forState:UIControlStateNormal];
        [updateButton addTarget:self action:@selector(pressUpdate:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:updateButton];
        [updateButton release];
        
        
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
 @abstract Show view animated - fades in
 
 Use:
 - called when view is added as subview
 */
- (void) showAnimated:(BOOL)animated {
    
    DDLogInfo(@"AUV: show animated");
    
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
}

#pragma mark - Button


/*!
 @abstract open update app page
 */
- (void) pressUpdate:(id)sender {
    
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:kMPParamAppURLUpdate]];
}


@end
