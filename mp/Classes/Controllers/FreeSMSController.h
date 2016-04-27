//
//  FreeSMSController.h
//  mp
//
//  Created by Min Tsai on 3/5/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FreeSMSController : UIViewController {
    
    NSArray *contactProperties;
    
}

/*! contacts to send free message to */
@property(nonatomic, retain) NSArray *contactProperties;

@end
