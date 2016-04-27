//
//  CountryCellController.h
//  mp
//
//  Created by M Tsai on 11-10-17.
//  Copyright 2011年 TernTek. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "CellController.h"

@class CountryCellController;

/*!
 Delegate that can be notified to communicate event to parent tableview
 
 */
@protocol CountryCellControllerDelegate <NSObject>

/*!
 @abstract Call when this country cell is selected
 
 The delegate is a table view controller that usually passes this selection back to previous controller
 @param countryCode - 2 letter iso country code
 
 */
- (void)countryCellController:(CountryCellController *)cellController selectedCountryCode:(NSString *)countryCode;

@optional
@end


@class CountryInfo;

@interface CountryCellController : NSObject <CellController> {
    id <CountryCellControllerDelegate> delegate;
    CountryInfo *countryInfo;
}

@property(nonatomic, assign) id <CountryCellControllerDelegate> delegate;
@property(nonatomic, retain) CountryInfo *countryInfo;

- (id)initWithCountryInfo:(CountryInfo *)aCountryInfo;

@end