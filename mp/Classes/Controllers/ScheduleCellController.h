//
//  ScheduleCellController.h
//  mp
//
//  Created by Min Tsai on 1/20/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CellController.h"
#import "MPImageManager.h"

@class CDMessage;
@class ScheduleCellController;


@protocol ScheduleCellControllerDelegate <NSObject>

/*!
 @abstract Inform delegate that scheduled message was tapped
 
 */
- (void)ScheduleCellController:(ScheduleCellController *)controller tappedMessage:(CDMessage *)message ;

@end


@interface ScheduleCellController : NSObject <CellController, MPImageManagerDelegate> {
    id <ScheduleCellControllerDelegate> delegate;
    CDMessage *cdMessage;
    UIViewController *parentController;
    MPImageManager *imageManager;
    
}

@property (nonatomic, assign) id <ScheduleCellControllerDelegate> delegate;

/*! chat room that we are in right now */
@property (nonatomic, retain) CDMessage *cdMessage;

/*! helps access headshots for friends */
@property(nonatomic, retain) MPImageManager *imageManager;

- (id)initWithCDMessage:(CDMessage *)newCDMessage;



@end