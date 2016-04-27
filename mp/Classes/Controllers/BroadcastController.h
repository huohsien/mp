//
//  BroadcastController.h
//  mp
//
//  Created by M Tsai on 11-10-31.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BroadcastController;


@protocol BroadcastControllerDelegate <NSObject>

// notify parent that broadcast is complete - to dismiss this view and previous views that were show modally
//
- (void)broadcastController:(BroadcastController *)broadcastController;

@end


@interface BroadcastController : UIViewController {
    id <BroadcastControllerDelegate> delegate;
    NSArray *contacts;
    
}

@property (nonatomic, assign) id <BroadcastControllerDelegate> delegate;
@property (nonatomic, retain) NSArray *contacts;

- (id)initWithContacts:(NSArray *)selectedContacts;


@end


