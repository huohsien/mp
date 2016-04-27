//
//  LocationShareController.h
//  mp
//
//  Created by Min Tsai on 2/10/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

/*!
 @header LocationShareController
 
 Locate and Share location
 - locate user and zooms into location
 - allow users to pan to fine tune location
 - search and show POI
 - edit address and search again
 - recenter my location
 
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */


#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "TextEditController.h"

/*!
 @abstract Edit mode that affects the UI interface for edit view
 
 kLSModeShare   Select location to share
 kLSModeView    View locatione shared
 
 */
typedef enum {
    kLSModeShare = 0,
    kLSModeView = 1
} LSMode;


@class CenterPinAnnotation;
@class LocationShareController;
@class PreviewAnnotation;



@protocol LocationShareControllerDelegate <NSObject>

/*!
 @abstract Call when user has selected a location to share 
 */
- (void)LocationShareController:(LocationShareController *)controller shareCoordinate:(CLLocationCoordinate2D)coordinate previewImage:(UIImage *)previewImage;

@end



@interface LocationShareController : UIViewController <UISearchBarDelegate, MKMapViewDelegate, MKReverseGeocoderDelegate, UIActionSheetDelegate, TextEditControllerDelegate, UIAlertViewDelegate>{
    
    id <LocationShareControllerDelegate> delegate;
    LSMode locationMode;
    
    UISearchBar *searchBar;
    
    MKMapView *mainMapView;
    NSMutableArray *mapAnnotations;
        
    UIImageView *centerPinView;
    CenterPinAnnotation *centerPinAnnotation;
    BOOL foundUser;
    
    NSTimer *reverseTimer;
    NSString *requestTagReverseGeocode;
    NSString *requestTagForwardGeocode;
    MKReverseGeocoder *reverseCoder;
    NSString *requestTagPlaceSearch;
    NSString *requestTagPlaceSearchPOI;
    
    
    PreviewAnnotation *sharedLocationAnnotation;
    BOOL sharePressed;
    NSTimer *shareImageTimer;
    CLLocationCoordinate2D shareCoordinate;
    BOOL isMapTileLoading;
    CGFloat shareImageDelay;
}


/*! Delegate */
@property (nonatomic, assign) id <LocationShareControllerDelegate> delegate;

/*! Mode to present controller */
@property (nonatomic, assign) LSMode locationMode;


/*! Search Bar */
@property (nonatomic, retain) UISearchBar *searchBar;

/*! Main map view */
@property (nonatomic, retain) MKMapView *mainMapView;

/*! Keep track of annotations */
@property (nonatomic, retain) NSMutableArray *mapAnnotations;

/*! Image that represents center pin */
@property (nonatomic, retain) UIImageView *centerPinView;

/*! actual invisible center pin - used to display call out info */
@property (nonatomic, retain) CenterPinAnnotation *centerPinAnnotation;

/*! did we find user location yet? */
@property (nonatomic, assign) BOOL foundUser;



/*! timer to request reverse geocode */
@property (nonatomic, retain) NSTimer *reverseTimer;

/*! used to convert coord to address */
@property (nonatomic, retain) MKReverseGeocoder *reverseCoder;

/*! save latest request id */
@property (nonatomic, retain) NSString *requestTagReverseGeocode;

/*! save latest request id */
@property (nonatomic, retain) NSString *requestTagForwardGeocode;

/*! save latest place search id */
@property (nonatomic, retain) NSString *requestTagPlaceSearch;

/*! save latest place POI search id */
@property (nonatomic, retain) NSString *requestTagPlaceSearchPOI;



/*! annotation representing location shared */
@property (nonatomic, retain) PreviewAnnotation *sharedLocationAnnotation;

/*! was share button pressed */
@property (nonatomic, assign) BOOL sharePressed;

/*! timer to capture preview image to share */
@property (nonatomic, retain) NSTimer *shareImageTimer;

/*! coordinate to share */
@property (nonatomic, assign) CLLocationCoordinate2D shareCoordinate;

/*! is map tiles loading - don't get image if tiles are still loading */
@property (nonatomic, assign) BOOL isMapTileLoading;

/*! how long should we wait for map to load and take image */
@property (nonatomic, assign) CGFloat shareImageDelay;

+ (NSString *)locationMessageTextForCoordinate:(CLLocationCoordinate2D)coordinate;

@end
