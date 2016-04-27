//
//  ProgressOverlayView.h
//  mp
//
//  Created by Min Tsai on 5/1/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProgressOverlayView : UIView {
    NSString *messageID;
    UIProgressView *progressView;
    NSUInteger currentBytes;
    NSUInteger totalBytes;
}

/*! message we are tracking progress for */
@property (nonatomic, retain) NSString *messageID;

@property (nonatomic, retain) UIProgressView *progressView;

/*! keeps track of current progress levels */
@property (nonatomic, assign) NSUInteger currentBytes;

/*! total size of content */
@property (nonatomic, assign) NSUInteger totalBytes;

- (id)initWithFrame:(CGRect)frame messageID:(NSString *)msgID totalSize:(NSUInteger)totalSize;

@end
