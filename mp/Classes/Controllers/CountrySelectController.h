//
//  CountrySelectController.h
//  mp
//
//  Created by M Tsai on 11-10-17.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CountryCellController.h"

@class CountrySelectController;

/*!
 Delegate that can be notified when results are obtained
 
 */
@protocol CountrySelectControllerDelegate <NSObject>

/*!
 @abstract Call when a country is selected
 
 The delegate will receive the results of the selection
 
 @param countryCode - 2 letter iso country code
 
 */
- (void)countrySelectController:(CountrySelectController *)cellController selectedCountryIsoCode:(NSString *)isoCode;

@optional
@end


@class TTCollationWrapper;

@interface CountrySelectController : UITableViewController <CountryCellControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate> {
    
    id <CountrySelectControllerDelegate> delegate;
    NSMutableDictionary *isoCodeToCountryD;
    TTCollationWrapper *collation;
    NSMutableArray *filteredObjects;

    
    NSMutableDictionary *cellControllerD;
    
    UISearchBar	*searchBar;
	UISearchDisplayController *searchController;
    
}

@property (nonatomic, assign) id <CountrySelectControllerDelegate> delegate;

/*! array used to create data model */
@property (nonatomic, retain) NSMutableDictionary *isoCodeToCountryD;

/*! collation object to organize contacts for table views */
@property (nonatomic, retain) TTCollationWrapper *collation;

/*! access cell controllers */
@property (nonatomic, retain) NSMutableDictionary *cellControllerD;

/*! @abstract search results data model */
@property (nonatomic, retain) NSMutableArray *filteredObjects;


@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) UISearchDisplayController *searchController;

- (void)setSearch;

@end
