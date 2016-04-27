//
//  ChatCellController.h
//  mp
//
//  Created by M Tsai on 11-9-26.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CellController.h"
#import "MPImageManager.h"

@class CDChat;
@class ChatCellController;

@protocol ChatCellControllerDelegate <NSObject>

/*!
 @abstract Called when contact cell needs to be refreshed.
 
 We need to tell the table to refresh the cell if something changed like the headshot.
 The table will then:
 - figure out if this controller is visible
 - if visible then refresh it
 
 */
- (void)ChatCellController:(ChatCellController *)controller refreshChat:(CDChat *)chat;


/*!
 @abstract Inform delegate that cell was selected
 
 */
- (void)ChatCellController:(ChatCellController *)controller didSelectChat:(CDChat *)chat;

@end


@interface ChatCellController : NSObject <CellController, MPImageManagerDelegate> {
    id <ChatCellControllerDelegate> delegate;
    CDChat *cdChat;
    MPImageManager *imageManager;
    
}




@property (nonatomic, assign) id <ChatCellControllerDelegate> delegate;

/*! chat room that we are in right now */
@property (nonatomic, retain) CDChat *cdChat;


/*! helps access headshots for friends */
@property(nonatomic, retain) MPImageManager *imageManager;





- (id)initWithCDChat:(CDChat *)newCDChat;



@end
