//
//  ResourceUpdateController.h
//  mp
//
//  Created by Min Tsai on 1/9/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPResourceCenter.h"


@interface ResourceUpdateController : UIViewController <MPResourceCenterDelegate> {
    
    UIProgressView *progressView;
}

@property (nonatomic, retain) UIProgressView *progressView;

@end
