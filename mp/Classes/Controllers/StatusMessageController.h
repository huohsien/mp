//
//  StatusMessageController.h
//  mp
//
//  Created by M Tsai on 11-11-25.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

/*!
 @header StatusMessageController
 
 Allow users to select from a predefined list of status messages.  
 
 The list of predefined messages are loaded from plist files:
    status_message_<language>.plist
  - language is normally the 2 letter iso code
  - zh uses zh_TW and zh_CN
 
 @copyright TernTek
 @updated 2011-11-25
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */



#import <UIKit/UIKit.h>
#import "SelectCellController.h"
#import "GenericTableViewController.h"
#import "ComposerController.h"


@interface StatusMessageController : GenericTableViewController <SelectCellControllerDelegate, ComposerControllerDelegate> {

    NSArray *predefinedStatusMessages;
    NSString *tempStatus;

}

/*! list of predefined status to display to user */
@property (nonatomic, retain) NSArray *predefinedStatusMessages;

/*! save pending status update value here */
@property (nonatomic, retain) NSString *tempStatus;

@end
