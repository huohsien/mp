//
//  DialogInfoCellController.h
//  mp
//
//  Created by Min Tsai on 3/6/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellController.h"

/*!
 @header DialogInfoCellController
 
 Cell controller that represents basic information text required in the chat dialog
 
 @copyright TernTek
 @updated 2011-08-30
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */


/**
 Defines how messsage should be displayed in dialog
 */
typedef enum {
    kDInfoTypeDate,
    kDInfoTypeJoin,
    kDInfoTypeLeave
} DInfoType;


@interface DialogInfoCellController : NSObject <CellController> {
    
    DInfoType infoType;
    NSString *infoString;

}

/*! Determine to display message */
@property (nonatomic, assign) DInfoType infoType;

/*! Message string to show */
@property (nonatomic, retain) NSString *infoString;

- (id)initWithInfo:(NSString *)info messageType:(DInfoType)type;

@end
