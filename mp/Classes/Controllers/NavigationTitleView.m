//
//  NavigationTitleView.m
//  mp
//
//  Created by Min Tsai on 2/25/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "NavigationTitleView.h"
#import "MPFoundation.h"

#define TITLE_TAG   15001
#define STATUS_TAG  15002






@implementation NavigationTitleView

// getting these programmatically does not work in iOS4.x
//
#define kTitleWidth     170.0
#define kTitleHeight    26.0
#define kStatusHeight   16.0


/*!
 
 Possible states:
 - No network
 - Connecting...
 - Connected
 - Online
 - 2011/02/14
 - 15:30 AM
 
 */
- (id)initWithTitle:(NSString *)title status:(NSString *)status 
{
    UIFont *titleFont = [AppUtility fontPreferenceWithContext:kAUFontBoldHugePlus];
    UIFont *statusFont = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];

    //CGSize titleSize = [title sizeWithFont:titleFont];
    
    // max width should be "connecting", but in case check the status being set
    //
    //CGSize statusSize = [[NavigationTitleView descriptionForState:kNTStateConnecting] sizeWithFont:statusFont];
    //CGSize curStatusSize = [status sizeWithFont:statusFont];
    //CGFloat maxStatusWidth = 150.0; // - this does not work right.. MAX(statusSize.width+5.0, curStatusSize.width+5.0);
    
    //CGRect newFrame = CGRectMake(0.0, 0.0, MAX(titleSize.width, maxStatusWidth), kTitleHeight+kStatusHeight);
    CGRect newFrame = CGRectMake(0.0, 0.0, kTitleWidth, kTitleHeight+kStatusHeight);
    self = [super initWithFrame:newFrame];
    if (self) {
        // Initialization code
        
        self.backgroundColor = [UIColor clearColor];
        
        UILabel *titleLabel = [[UILabel alloc] init];
        //titleLabel.frame = CGRectMake((newFrame.size.width-titleSize.width)/2.0, 0.0, titleSize.width, kTitleHeight);
        titleLabel.frame = CGRectMake(0.0, 0.0, kTitleWidth, kTitleHeight);
        [AppUtility configLabel:titleLabel context:kAULabelTypeNavTitle];
        titleLabel.font = titleFont;
        titleLabel.text = title;
        titleLabel.tag = TITLE_TAG;
        [self addSubview:titleLabel];
        [titleLabel release];
        
        UILabel *statusLabel = [[UILabel alloc] init];
        //statusLabel.frame = CGRectMake((newFrame.size.width-maxStatusWidth)/2.0, kTitleHeight-2.0, maxStatusWidth, kStatusHeight);
        statusLabel.frame = CGRectMake(0.0, kTitleHeight-2.0, kTitleWidth, kStatusHeight);

        statusLabel.textAlignment = UITextAlignmentCenter;
        statusLabel.font = statusFont;
        //statusLabel.adjustsFontSizeToFitWidth = YES;
        //statusLabel.minimumFontSize = 10.0;
        statusLabel.textColor = [UIColor whiteColor];
        statusLabel.backgroundColor = [UIColor clearColor];
        //debug - statusLabel.backgroundColor = [UIColor blueColor];

        statusLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.43];
        //statusLabel.shadowColor = [UIColor darkGrayColor];
        statusLabel.shadowOffset = CGSizeMake(0, 1);
        statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        statusLabel.text = status;
        statusLabel.tag = STATUS_TAG;
        [self addSubview:statusLabel];
        [statusLabel release];
    }
    return self;
}

/*!
 @abstract Update title label text
 */
- (void) setTitleText:(NSString *)newTitleText {
    
    UILabel *titleLabel = (UILabel *)[self viewWithTag:TITLE_TAG];
    titleLabel.text = newTitleText;
}


/*!
 @abstract Update status label text
 */
- (void) setStatusText:(NSString *)newStatusText {
    
    UILabel *statusLabel = (UILabel *)[self viewWithTag:STATUS_TAG];
    statusLabel.text = newStatusText;
}


/*!
 @abstract gets the state string
 */
+ (NSString *)descriptionForState:(NTState)state {
    
    switch (state) {
        case kNTStateConnecting:
            return  NSLocalizedString(@"connecting...", @"NavTitle: Currently connecting to servers");
            break;
            
        case kNTStateNoNetwork:
            return NSLocalizedString(@"no network", @"NavTitle: No network available, cant' connect to servers");
            break;
            
        case kNTStateTyping:
            return NSLocalizedString(@"typing...", @"NavTitle: Other party is typing a message");
            break;
            
        default:
            break;
    }
    return nil;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
