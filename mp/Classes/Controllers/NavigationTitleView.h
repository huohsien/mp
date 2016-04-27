//
//  NavigationTitleView.h
//  mp
//
//  Created by Min Tsai on 2/25/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

/*!
 @header NavigationTitleView
 
 Navigation title view for Chat Dialogs which requires a sublabel under the title
 
 Format:
 - title            Title is on the top
 - status           Status is below title
 
 Usage:
 
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <UIKit/UIKit.h>


/*!
 @abstract Current connection status 
 */
typedef enum {
    kNTStateConnecting,
    kNTStateNoNetwork,
    kNTStateTyping
} NTState;


@interface NavigationTitleView : UIView 


- (id)initWithTitle:(NSString *)title status:(NSString *)status;

/*!
 @abstract Update title label text
 */
- (void) setTitleText:(NSString *)newTitleText;

/*!
 @abstract Update status label text
 */
- (void) setStatusText:(NSString *)newStatusText;

+ (NSString *)descriptionForState:(NTState)state;

@end
