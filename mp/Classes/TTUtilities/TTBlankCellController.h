//
//  TTBlankCellController.h
//  ContactBook
//
//  Created by M Tsai on 11-2-14.
//  Copyright 2011 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellController.h"

/**
 Serves as a generic blank row
 */
@interface TTBlankCellController : NSObject <CellController> {
	UIColor *backgroundColor;
}

@property (nonatomic, retain) UIColor *backgroundColor;


- (id)initWithColor:(UIColor *)backColor;

@end
