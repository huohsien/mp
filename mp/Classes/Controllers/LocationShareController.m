//
//  LocationShareController.m
//  mp
//
//  Created by Min Tsai on 2/10/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "LocationShareController.h"
#import "MPFoundation.h"
#import "CenterPinAnnotation.h"
#import "PlaceAnnotation.h"
#import <CoreLocation/CoreLocation.h>
#import "PreviewAnnotation.h"


#define POI_BTN_TAG         18001
#define POI_ACTIVITY_TAG    18002


CLLocationDistance const kMPParamMapSpanMinimum = 1000.0;
CLLocationDistance const kMPParamMapPreviewDistanceMinimum = 1000.0;
CLLocationDistance const kMPParamMapPOIDistance = 1000.0;



NSString* const kLSAnnotationIDPlace = @"placeAnnotationID";
NSString* const kLSAnnotationIDCenter = @"centerPinAnnotationID";
NSString* const kLSAnnotationIDShared = @"sharedAnnotationID";



@interface LocationShareController (Private)

- (void)setupSearch;
- (void)setupButtons;
- (void)setupMap;
- (void) requestReverseGeocoding:(CLLocationCoordinate2D)coordinate;
- (void) requestCenterPinAddress;
- (void) deselectPOIButton;

@end


@implementation LocationShareController

@synthesize delegate;
@synthesize locationMode;

@synthesize searchBar;
@synthesize mainMapView;
@synthesize mapAnnotations;

@synthesize centerPinView;
@synthesize centerPinAnnotation;

@synthesize reverseTimer;
@synthesize requestTagReverseGeocode;
@synthesize requestTagForwardGeocode;
@synthesize reverseCoder;

@synthesize requestTagPlaceSearch;
@synthesize requestTagPlaceSearchPOI;

@synthesize sharedLocationAnnotation;
@synthesize sharePressed;
@synthesize shareImageTimer;
@synthesize shareCoordinate;
@synthesize isMapTileLoading;
@synthesize shareImageDelay;

@synthesize foundUser;

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    mainMapView.delegate = nil;
    
    //[imageMapView release];
    
    [shareImageTimer release];
    [requestTagPlaceSearchPOI release];
    [requestTagPlaceSearch release];
    [reverseTimer release];
    [requestTagReverseGeocode release];
    [requestTagForwardGeocode release];
    [reverseCoder release];
    [centerPinView release];
    [centerPinAnnotation release];
    [searchBar release];
    [mainMapView release];
    [mapAnnotations release];
    
    [super dealloc];
    
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    self.sharePressed = NO;
    self.isMapTileLoading = NO;
    self.foundUser = NO;
    
    self.title = NSLocalizedString(@"Location", @"Location - Title: view title");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    
    UIView *backView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    backView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = backView;
    [backView release];
    
    
    // search only for share mode
    if (self.locationMode == kLSModeShare) {
        [self setupSearch];
    }
 
    // add map view
    //
    [self setupMap];
    
    // add btns
    //
    [self setupButtons];
    
    
    // listen for results
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReverseGeocode:) name:MP_HTTPCENTER_REVERSE_GEOCODE_NOTIFICATION object:nil];
    
    // listen for results
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleForwardGeocode:) name:MP_HTTPCENTER_FORWARD_GEOCODE_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlaceSearch:) name:MP_HTTPCENTER_PLACE_SEARCH_NOTIFICATION object:nil];
    
    // if connection fails - reset POI button if POI requested
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processConnectFailure:) name:MP_HTTPCENTER_CONNECT_FAILED_NOTIFICATION object:nil];
    
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void) viewWillAppear:(BOOL)animated {
    
    DDLogInfo(@"LSC-vwa");
    
    [super viewWillAppear:animated];
    
    // position center view
    //
    CGSize mapSize = self.mainMapView.frame.size;
    CGRect newRect = self.centerPinView.frame;
    self.centerPinView.frame = CGRectMake(mapSize.width/2.0-10.5, mapSize.height/2.0-36.0, newRect.size.width, newRect.size.height);
    
    self.mainMapView.showsUserLocation = YES;
    
}

#pragma mark - MapView




/*!
 @abstract Sets up mapview
 */
- (void)setupMap {

    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];

    CGRect mapRect = CGRectZero;
    
    if (self.searchBar) {
        mapRect = CGRectMake(0.0, self.searchBar.frame.size.height, appFrame.size.width, appFrame.size.height - self.searchBar.frame.size.height);
    }
    else {
        mapRect = CGRectMake(0.0, 0.0, appFrame.size.width, appFrame.size.height);
    }
    
    MKMapView *newMap = [[MKMapView alloc] initWithFrame:mapRect];
    newMap.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    //newMap.showsUserLocation = YES;
    newMap.delegate = self;
    self.mainMapView = newMap;
    [newMap release];
    
    self.mainMapView.mapType = MKMapTypeStandard;
    
    // show center pin for share mode
    if (self.locationMode == kLSModeShare) {
        
        /*// add center pin
        //
        if (!self.centerPinAnnotation) {
            CenterPinAnnotation *newCenter = [[CenterPinAnnotation alloc] init];
            self.centerPinAnnotation = newCenter;
            [newCenter release];
        }
        [self.mainMapView addAnnotation:self.centerPinAnnotation];
        */
        
        // add center pin view
        // - position it before appearing - not accurate now
        if (!self.centerPinView) {
            UIImageView *pinView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loc_icon_pin.png"]];
            self.centerPinView = pinView;
            [pinView release];
            
            [self.mainMapView addSubview:self.centerPinView];
        }
    }
    // show share coordinate for view mode
    else if (self.locationMode == kLSModeView) {
        // add single red pin for location
        PreviewAnnotation *locationAnnotation = [[PreviewAnnotation alloc] init];
        locationAnnotation.coordinate = self.shareCoordinate;
        locationAnnotation.name = NSLocalizedString(@"Location", @"Location - Title: Call title for shared location");
        self.sharedLocationAnnotation = locationAnnotation;
        [self.mainMapView addAnnotation:locationAnnotation];
        [locationAnnotation release];
        
        // move map to desired region area
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.shareCoordinate, kMPParamMapPreviewDistanceMinimum, kMPParamMapPreviewDistanceMinimum);
        [self.mainMapView setRegion:viewRegion animated:YES];
        
        [self.mainMapView selectAnnotation:self.sharedLocationAnnotation animated:NO];
        
        // create new geocode request
        // for shared location
        //
        self.requestTagReverseGeocode = [NSString stringWithFormat:@"%f%f", self.shareCoordinate.latitude, self.shareCoordinate.longitude];
        [[MPHTTPCenter sharedMPHTTPCenter] mapReverseGeocode:self.shareCoordinate idTag:self.requestTagReverseGeocode];
    }

    
    [self.view addSubview:self.mainMapView];
    
    
    // add hidden mapview for image preview image generation
    // - update this map whenever an annotation is selected
    //
    /*CGRect imageMapRect = CGRectMake(0.0, -kLocationPreviewSize, kLocationPreviewSize, kLocationPreviewSize);
    
    MKMapView *imageMap = [[MKMapView alloc] initWithFrame:imageMapRect];
    imageMap.mapType = MKMapTypeStandard;
    self.imageMapView = imageMap;
    [imageMap release];
    [self.view addSubview:self.imageMapView];*/
    
}
    








/*!
 @abstract Remove existing place annotation
 */
- (void)removeCurrentPlaceAnnotations {
    
    NSMutableArray *removeAnnotations = [[NSMutableArray alloc] init];
    
    for (id iAnnotation in self.mainMapView.annotations) {
        if ([iAnnotation isKindOfClass:[PlaceAnnotation class]]) {
            [removeAnnotations addObject:iAnnotation];
        }
    }
    
    [self.mainMapView removeAnnotations:removeAnnotations];
    [removeAnnotations release];
}

/*!
 @abstract Hide center pin
 */
- (void)hideCenterPin {
    
    // hide call out
    [self.mainMapView deselectAnnotation:self.centerPinAnnotation animated:NO];
    
    // hide center view
    self.centerPinView.hidden = YES;

}  

/*!
 @abstract Show center pin
 */
- (void)showCenterPin {
    
    // hide center view
    self.centerPinView.hidden = NO;
    
}


/*!
 @abstract this simply adds a single pin and zooms in on it nicely 
 */
- (void) zoomToAnnotation:(id)annotation {
    /*MKCoordinateSpan span = {0.027, 0.027};
    MKCoordinateRegion region = {[annotation coordinate], span};
    */

    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([annotation coordinate], kMPParamMapSpanMinimum, kMPParamMapSpanMinimum);
    [self.mainMapView setRegion:region animated:YES];
}

/*!
 @abstract This returns a rectangle bounding all of the pins within the supplied
 array 
 */
- (MKMapRect) getMapRectUsingAnnotations:(NSArray*)theAnnotations {
    MKMapPoint points[[theAnnotations count]];
    
    for (int i = 0; i < [theAnnotations count]; i++) {
        id annotation = [theAnnotations objectAtIndex:i];
        points[i] = MKMapPointForCoordinate([annotation coordinate]);
    }
    
    MKPolygon *poly = [MKPolygon polygonWithPoints:points count:[theAnnotations count]];
    
    return [poly boundingMapRect];
}

/*!
 @abstract Zooms to show all annotations
 */
- (void) zoomToAnnotations:(NSArray *)zoomAnnotations {
    if ([zoomAnnotations count] == 1) {
        // If there is only one annotation then zoom into it.
        [self zoomToAnnotation:[zoomAnnotations objectAtIndex:0]];
    } else {
        // If there are several, then the default behaviour is to show all of them
        //
        MKMapRect mapRect = [self getMapRectUsingAnnotations:zoomAnnotations];
        MKCoordinateRegion region = MKCoordinateRegionForMapRect(mapRect);
        
        // get MP/meter
        double mpPerMeter = MKMapPointsPerMeterAtLatitude(region.center.latitude);
        CGFloat minMapPoint = mpPerMeter * kMPParamMapSpanMinimum;
        
        CGFloat mapWidth = mapRect.size.width;
        CGFloat mapHeight = mapRect.size.height;
        
        if (mapWidth < minMapPoint) {
            mapWidth = minMapPoint;
        }
        if (mapHeight < minMapPoint) {
            mapHeight = minMapPoint;
        }
        
        MKMapRect newRect = MKMapRectMake(MKMapRectGetMidX(mapRect)-mapWidth/2.0,
                                          MKMapRectGetMidY(mapRect)-mapHeight/2.0, mapWidth, mapHeight);
        [self.mainMapView setVisibleMapRect:newRect animated:YES];
        
        /*
        if (region.span.latitudeDelta < 0.027) {
            region.span.latitudeDelta = 0.027;
        }
        
        if (region.span.longitudeDelta < 0.027) {
            region.span.longitudeDelta = 0.027;
        }
        [self.mainMapView setRegion:region animated:YES];
         */
    }
}



/*!
 @abstract Shows the current user location without chaning maprect size
 */
- (void)panToUserLocationAnimated:(BOOL)animated {
    
    // get current maprect
    MKMapRect newRect = self.mainMapView.visibleMapRect;
    MKMapPoint userPoint = MKMapPointForCoordinate(self.mainMapView.userLocation.coordinate);
    
    newRect.origin.x = userPoint.x - newRect.size.width/2.0;
    newRect.origin.y = userPoint.y - newRect.size.height/2.0;
    
    [self.mainMapView setVisibleMapRect:newRect animated:animated];
    
}


/*!
 @abstract Shows the current user location and zoom in
 */
- (void)zoomToUserLocation {
    
    MKUserLocation *meAnnotation = nil;
    
    for (id iAnnotation in self.mainMapView.annotations) {
        
        // if it's the user location, just return nil. - use standard view
        if ([iAnnotation isKindOfClass:[MKUserLocation class]])
            meAnnotation = iAnnotation;
    }
    
    if (meAnnotation) {
        [self.mainMapView selectAnnotation:meAnnotation animated:YES];
        [self zoomToAnnotation:meAnnotation];
    }
    // no user location, try to find it
    else {
        self.mainMapView.showsUserLocation = NO;
        self.mainMapView.showsUserLocation = YES;
    }
}




#define kLocationPreviewSize 160.0
#define kLocationPreviewWidth 170.0


/*!
 @abstract Capture an image from the map view and send to delegate
 */
- (void) getPreviewImageAndShare {
    
    // if share not pressed skip it
    // - maybe extra timer fired
    if (self.sharePressed == NO) {
        return;
    }
    
    // prevent another timer firing and sending another image
    self.sharePressed = NO;
    [self.shareImageTimer invalidate];
    
    [AppUtility stopActivityIndicator];
    
    UIImage *fullImage = [UIImage sharpImageWithView:self.mainMapView];
    //return fullImage;
    
    CGSize fullSize = [fullImage size];
    CGRect cropRect = CGRectMake((fullSize.width - kLocationPreviewWidth)/2.0, (fullSize.height - kLocationPreviewSize)/2.0, kLocationPreviewWidth, kLocationPreviewSize);
    
    UIImage *cropImage = [fullImage crop:cropRect];
    
    DDLogVerbose(@"LS: pre image size w:%f h:%f", [cropImage size].width, [cropImage size].height);
    
    // debug
    UIImageView *preView = [[UIImageView alloc] initWithImage:cropImage];
    [self.mainMapView addSubview:preView];
    [preView release];
    
    if ([self.delegate respondsToSelector:@selector(LocationShareController:shareCoordinate:previewImage:)]) {
        [self.delegate LocationShareController:self shareCoordinate:self.shareCoordinate previewImage:cropImage];
    }
}




#pragma mark - MapView Delegates


/*!
 @abstract got user location update
 */
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    
    CLLocationAccuracy hAccuracy = userLocation.location.horizontalAccuracy;
    CLLocationAccuracy vAccuracy = userLocation.location.verticalAccuracy;
    
    DDLogInfo(@"LS: updating user location %f,%f - %f,%f",hAccuracy, vAccuracy, 
              userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude);

    // if == 0 then no location provided
    //
    if (vAccuracy != 0 && hAccuracy != 0) {
        if (self.locationMode == kLSModeShare) {
            
            // only zoom in on first update
            if (self.foundUser == NO) {
                
                // add center pin
                //
                if (!self.centerPinAnnotation) {
                    DDLogInfo(@"LS-duul: create center pin annotation");
                    CenterPinAnnotation *newCenter = [[CenterPinAnnotation alloc] init];
                    self.centerPinAnnotation = newCenter;
                    [newCenter release];
                    
                    [self.mainMapView addAnnotation:self.centerPinAnnotation];
                }
                
                // create new rect to zoom to
                //
                CLLocationDistance spanMeters = MAX(userLocation.location.verticalAccuracy, kMPParamMapSpanMinimum);
                
                MKCoordinateRegion userRegion = MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate, spanMeters, spanMeters);
                
                [self.mainMapView setRegion:userRegion animated:YES];
                self.foundUser = YES;
            }
        }
        else if (self.locationMode == kLSModeView) {
            self.foundUser = YES;
        }
    }
    
}

#define ENABLE_LOCATION_TAG 13001
/*!
 @abstract getting user location failed
 
 */
- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
    
    // only fail for sharing location since location is critical
    // - viewing is not that critical
    //
    // show alert for both view and share location
    if (error) {
        if (error.code == 0) {
            
            NSString *title = nil;
            if (self.locationMode == kLSModeShare) {
                title = NSLocalizedString(@"Share Location", @"LocationShare: enable location to share location");
            }
            else {
                title = NSLocalizedString(@"View Location", @"LocationShare: enable location to view location");
            }
            NSString *message = NSLocalizedString(@"Turn on Location Service in Settings to allow M+ to determine your location." , @"LocationShare: Enable location to access photots");

            //NSString *message = [error localizedRecoverySuggestion]; - standard suggestion is less complete than above
            [Utility showAlertViewWithTitle:title message:message delegate:self tag:ENABLE_LOCATION_TAG];
        }
    }
}



/*!
 @abstract Before map is moved
 */
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    
    // hide call out when moving map
    [self.mainMapView deselectAnnotation:self.centerPinAnnotation animated:YES];
    
    // if user is moving the pin
    // - yes means that programmatically being moved
    if (animated == NO) {
        // make sure center pin is shown
        [self showCenterPin];
    }
}



/*!
 @abstract Get updates when map view changes
 */
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    
    // if share pressed, don't modify anything
    if (self.sharePressed == NO && self.locationMode == kLSModeShare) {
        // recenter the main pin
        [self.centerPinAnnotation setCoordinate:mapView.region.center];
        
        // clear old placemark
        self.centerPinAnnotation.placemark = nil;
        
        // create new geocode request
        // - provide id so we can match request to results
        
        [self.reverseTimer invalidate];
        
        // only show if the center view is showing
        // - hidden if search started
        if (self.centerPinView.hidden == NO) {
            [self requestCenterPinAddress];
        }
    }
    
}

/*!
 @abstract Called when map moved and needs new map tiles
 */
- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView {
    
    // if sharing started
    // - stop image capture, since it will happen after loading
    if (self.sharePressed) {
        DDLogInfo(@"LS: start load");
        self.isMapTileLoading = YES;
        [self.shareImageTimer invalidate];
    }
}

/*!
 @abstract Called when map is loaded at each zoom level
 */
- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {

    // if sharing started
    // - want to capture image only after map finishes loading
    // - so restart timer every time this is called, since it is possible that several zoom levels encountered
    if (self.sharePressed) {
        DDLogInfo(@"LS: finished load");
        self.isMapTileLoading = NO;
        [self.shareImageTimer invalidate];
        self.shareImageTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(getPreviewImageAndShare) userInfo:nil repeats:NO];
    }
}

/*!
 @abstract Called when loading failed - however pending loads may be in progress
 */
- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error {
    // if sharing started
    // - want to capture image only after map finishes loading
    // - so restart timer every time this is called, since it is possible that several zoom levels encountered
    if (self.sharePressed) {
        DDLogInfo(@"LS: error load");
        self.isMapTileLoading = NO;
        [self.shareImageTimer invalidate];
        self.shareImageTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(getPreviewImageAndShare) userInfo:nil repeats:NO];
    }
}


/*!
 @abstract After an annotation view was added
 */
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    
    // Start final map image capture process
    // - detect when selected annotation is added
    // - start timers to capture map image
    // 
    if (self.sharePressed && self.isMapTileLoading == NO) {
        DDLogInfo(@"LS: add annotation after press");
        [self.shareImageTimer invalidate];
        // delay is longer since start load usually take 1-4 seconds to start
        // - wait for start load in case zoom scale changed
        self.shareImageTimer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(getPreviewImageAndShare) userInfo:nil repeats:NO];
    }
}


/*!
 @abstract Annotation was deselected
 */
- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    
    if (self.locationMode == kLSModeShare) {
        // only share if a location is seleted
        if ([self.mainMapView.selectedAnnotations count] > 0) {
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
        else {
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
    }
    
}

/*!
 @abstract Annotation was selected
 */
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    
    // if a place annotation selected, hide the center pin
    if ([view.reuseIdentifier isEqualToString:kLSAnnotationIDPlace]) {
        [self hideCenterPin];
    }
    
    // only share if a location is seleted
    if ([self.mainMapView.selectedAnnotations count] > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    // update the hidden map
    /*[self.imageMapView removeAnnotations:self.imageMapView.annotations];
    [self.imageMapView addAnnotation:view.annotation];
    
    // center annotation in map
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(view.annotation.coordinate, kMPParamMapSpanMinimum, kMPParamMapSpanMinimum);
    [self.imageMapView setRegion:viewRegion animated:NO];*/
    
}




- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // if it's the user location, just return nil. - use standard view
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    // handle Center Pin
    //
    if (annotation == self.centerPinAnnotation)
    {
        // try to dequeue an existing pin view first
        MKPinAnnotationView* pinView = (MKPinAnnotationView *)
        [theMapView dequeueReusableAnnotationViewWithIdentifier:kLSAnnotationIDCenter];
        if (!pinView)
        {
            // if an existing pin view was not available, create one
            MKPinAnnotationView* customPinView = [[[MKPinAnnotationView alloc]
                                                   initWithAnnotation:annotation reuseIdentifier:kLSAnnotationIDCenter] autorelease];
            //customPinView.pinColor = MKPinAnnotationColorPurple;
            customPinView.image = [UIImage imageNamed:@"std_clear.png"];
            customPinView.centerOffset = CGPointZero;
            customPinView.calloutOffset = CGPointMake(0.0, -32.0);
            customPinView.animatesDrop = NO;
            customPinView.canShowCallout = YES;
            
            // add a detail disclosure button to the callout which will open a new view controller page
            //
            // note: you can assign a specific call out accessory view, or as MKMapViewDelegate you can implement:
            //  - (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;
            //
            CGRect editFrame = CGRectMake(0.0, 0.0, 27.0, 27.0);
            UIButton *editButton = [[UIButton alloc] initWithFrame:editFrame];
            [editButton setImage:[UIImage imageNamed:@"chat_attach_phrase_edit_nor.png"] forState:UIControlStateNormal];
            [editButton setImage:[UIImage imageNamed:@"chat_attach_phrase_edit_prs.png"] forState:UIControlStateNormal];
            [editButton addTarget:self action:@selector(pressEdit:) forControlEvents:UIControlEventTouchUpInside];
            customPinView.rightCalloutAccessoryView = editButton;
            [editButton release];
            
            return customPinView;
        }
        else
        {
            pinView.annotation = annotation;
        }
        return pinView;
    }
    // Shared location Annotation
    //
    if (annotation == self.sharedLocationAnnotation)
    {
        // try to dequeue an existing pin view first
        MKPinAnnotationView* pinView = (MKPinAnnotationView *)
        [theMapView dequeueReusableAnnotationViewWithIdentifier:kLSAnnotationIDShared];
        if (!pinView)
        {
            // if an existing pin view was not available, create one
            MKPinAnnotationView* customPinView = [[[MKPinAnnotationView alloc]
                                                   initWithAnnotation:annotation reuseIdentifier:kLSAnnotationIDShared] autorelease];
            //customPinView.pinColor = MKPinAnnotationColorPurple;
            //customPinView.centerOffset = CGPointZero;
            //customPinView.calloutOffset = CGPointMake(0.0, -32.0);
            customPinView.animatesDrop = NO;
            customPinView.canShowCallout = YES;
            
            return customPinView;
        }
        else
        {
            pinView.annotation = annotation;
        }
        return pinView;
    }
    // POI annotations
    else if ([annotation isKindOfClass:[PlaceAnnotation class]])  
    {
        //return nil;
        MKAnnotationView* placePinView = (MKAnnotationView *)[self.mainMapView dequeueReusableAnnotationViewWithIdentifier:kLSAnnotationIDPlace];
        if (!placePinView)
        {
            // if an existing pin view was not available, create one
            placePinView = [[[MKAnnotationView alloc] initWithAnnotation:annotation 
                                                         reuseIdentifier:kLSAnnotationIDPlace] autorelease];
            //customPinView.pinColor = MKPinAnnotationColorGreen;
            placePinView.image = [UIImage imageNamed:@"loc_icon_poi.png"];
            //CGSize pinSize = [placePinView.image size];
            placePinView.centerOffset = CGPointMake(5.0, -15.0);
            placePinView.calloutOffset = CGPointMake(-5.0, 3.0);
            //pinView.animatesDrop = NO;
            placePinView.canShowCallout = YES;
        }
        else {
            placePinView.annotation = annotation;
        }
        return placePinView;
    }
    
    return nil;
}


#pragma mark - UIAlertView

/*!
 @abstract Dismiss if error encountered
 */
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == ENABLE_LOCATION_TAG) {
        if (self.locationMode == kLSModeShare) {
            [self pressCancel:nil];
        }
    }
}



#pragma mark - Goolge API 


/*!
 @abstract Request reverse geocoding
 */
- (void) requestReverseGeocoding {
    
    // create new geocode request
    // - provide id so we can match request to results
    CLLocationCoordinate2D coordinate = self.mainMapView.centerCoordinate;
    
    self.requestTagReverseGeocode = [NSString stringWithFormat:@"%f%f", coordinate.latitude, coordinate.longitude];
    DDLogVerbose(@"LOC: requesting reverse geocode: %@", self.requestTagReverseGeocode);

    [[MPHTTPCenter sharedMPHTTPCenter] mapReverseGeocode:coordinate idTag:self.requestTagReverseGeocode];
    
}


/*!
 @abstract Get address for centerPin
 */
- (void) requestCenterPinAddress {
    
    [self showCenterPin];

    self.reverseTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(requestReverseGeocoding) userInfo:nil repeats:NO];
    
    /*
     Make sure center exists before selecting
     - iOS 4.2 requires this otherwise crash will occur with this error:
        CoreAnimation: ignoring exception: (null) must implement title when canShowCallout is YES on correspoding view
        ~ so title is implemented in CenterPinAnnotation Class, but iOS 4.2 can't handle a nil annotation.
     
     */
    if (!self.centerPinAnnotation) {
        DDLogInfo(@"LS-rcpa: create center pin annotation");
        CenterPinAnnotation *newCenter = [[CenterPinAnnotation alloc] init];
        self.centerPinAnnotation = newCenter;
        [newCenter release];
        
        [self.mainMapView addAnnotation:self.centerPinAnnotation];
    }
    
    // clear old address and show new call out
    self.centerPinAnnotation.addressString = nil;    
    [self.mainMapView selectAnnotation:self.centerPinAnnotation animated:NO];
    
}





/*!
 @abstract Handle results from reverse geocode requets

 Doc:
  - http://code.google.com/apis/maps/documentation/geocoding/#ReverseGeocoding
 
 Code:
  - check if this was my request
  - is result status OK?
  - get first result element in results array - most fine grain result
  - get formatted address string from this element
  - set to annotation
 
 */
- (void) handleReverseGeocode:(NSNotification *)notification {
    
    // if share started, don't show callout
    if (self.sharePressed) {
        return;
    }
    
    NSDictionary *resultD = [notification object];
 
    // if result for latest request
    if ([self.requestTagReverseGeocode isEqualToString:[resultD valueForKey:kTTXMLIDTag]]) {
        
        NSDictionary *jsonD = [resultD valueForKey:kMPHCJsonKeyJsonObject];
        
        NSString *status = [jsonD valueForKey:kMPHCJsonKeyStatus];
        
        // if successfull
        if ([status isEqualToString:@"OK"]) {
            
            NSArray *addressResults = [jsonD valueForKey:kMPHCJsonKeyResults];
            if ([addressResults count] > 0) {
                NSString *formattedAddress = [[addressResults objectAtIndex:0] valueForKey:kMPHCJsonKeyFormattedAddress];
                
                id selectedAnnotation = nil;
                NSArray *annotations = self.mainMapView.selectedAnnotations;
                if ([annotations count] > 0) {
                    selectedAnnotation = [annotations objectAtIndex:0];
                }
                
                if (self.locationMode == kLSModeShare) {
                    self.centerPinAnnotation.addressString = formattedAddress;
                    
                    // refresh annotation - if selected
                    if (selectedAnnotation == self.centerPinAnnotation) {
                        [self.mainMapView deselectAnnotation:self.centerPinAnnotation animated:NO];
                        [self.mainMapView selectAnnotation:self.centerPinAnnotation animated:NO];
                    }

                }
                else if (self.locationMode == kLSModeView) {
                    self.sharedLocationAnnotation.address = formattedAddress;
                    
                    // refresh annotation - if selected
                    if (selectedAnnotation == self.sharedLocationAnnotation) {
                        [self.mainMapView deselectAnnotation:self.sharedLocationAnnotation animated:NO];
                        [self.mainMapView selectAnnotation:self.sharedLocationAnnotation animated:NO];
                    }
                }
            }
        }
        // did not succeed
        else {
            
            // stop activity indicator
        
        }
    }
    // else we ignore it
}




/*!
 @abstract Handle results from reverse geocode requets
 
 Doc:
 - http://code.google.com/apis/maps/documentation/geocoding/
 
 Code:
 - check if this was my request
 - is result status OK?
 - get first result element in results array - most fine grain result
 - get geometry to get coordinate data
 - move map to new coordinate
 
 */
- (void) handleForwardGeocode:(NSNotification *)notification {
    
    // if share started, don't show callout
    if (self.sharePressed) {
        return;
    }
    
    NSDictionary *resultD = [notification object];
    
    // if result for latest request
    if ([self.requestTagForwardGeocode isEqualToString:[resultD valueForKey:kTTXMLIDTag]]) {
        
        NSDictionary *jsonD = [resultD valueForKey:kMPHCJsonKeyJsonObject];
        
        NSString *status = [jsonD valueForKey:kMPHCJsonKeyStatus];
        
        // if successfull
        if ([status isEqualToString:@"OK"]) {
            
            NSArray *addressResults = [jsonD valueForKey:kMPHCJsonKeyResults];
            if ([addressResults count] > 0) {
                NSDictionary *firstResult = [addressResults objectAtIndex:0];
                
                NSDictionary *geometry = [firstResult valueForKey:kMPHCJsonKeyGeometry];
                NSDictionary *location = [geometry valueForKey:kMPHCJsonKeyLocation];
                CGFloat lat = [[location valueForKey:kMPHCJsonKeyLatitude] doubleValue];
                CGFloat lng = [[location valueForKey:kMPHCJsonKeyLongitude] doubleValue];
                
                CLLocationCoordinate2D newCoordinate = CLLocationCoordinate2DMake(lat, lng);
                
                self.centerPinAnnotation.coordinate = newCoordinate;
                [self zoomToAnnotation:self.centerPinAnnotation];
                
            }
        }
        // did not succeed
        // did not succeed
        else if ([status isEqualToString:@"ZERO_RESULTS"]) {
            
            [Utility showAlertViewWithTitle:NSLocalizedString(@"No matches found for address", @"Location - alert: No search matches for address entered") message:nil];
        }
    }
    // else we ignore it
}



/*!
 @abstract Handle results from place search request
 
 Doc:
 http://code.google.com/apis/maps/documentation/places/#PlaceSearches
 
 Code:
 - check if this was my request
 - is result status OK?
 - get first 8 result element and create annotations for each
 - clear old annotations
 - add new annotations
 - hide center PIN
 
 "results" : [
 {
 "geometry" : {
 "location" : {
 "lat" : -33.8719830,
 "lng" : 151.1990860
 }
 },
 "icon" : "http://maps.gstatic.com/mapfiles/place_api/icons/restaurant-71.png",
 "id" : "677679492a58049a7eae079e0890897eb953d79b",
 "name" : "Zaaffran Restaurant - BBQ and GRILL, Darling Harbour",
 "rating" : 3.90,
 "reference" : "CpQBjAAAAHDHuimUQATR6gfoWNmZlk5dKUKq_n46BpSzPQCjk1m9glTKkiAHH_Gs4xGttdOSj35WJJDAV90dAPnNnZK2OaxMgogdeHKQhIedh6UduFrW53wtwXigUfpAzsCgIzYNI0UQtCj38cr_DE56RH4Wi9d2bWbbIuRyDX6tx2Fmk2EQzO_lVJ-oq4ZY5uI6I75RnxIQJ6smWUVVIHup9Jvc517DKhoUidfNPyQZZIgGiXS_SwGQ1wg0gtc",
 "types" : [ "restaurant", "food", "establishment" ],
 "vicinity" : "Harbourside Centre 10 Darling Drive, Darling Harbour, Sydney"
 },
 }
 
 */      
- (void) handlePlaceSearch:(NSNotification *)notification {
    
    UIActivityIndicatorView *poiIndicator = (UIActivityIndicatorView *)[self.view viewWithTag:POI_ACTIVITY_TAG];
    [poiIndicator stopAnimating];
    
    NSDictionary *resultD = [notification object];
    
    NSString *requestID = [resultD valueForKey:kTTXMLIDTag];
    
    // if result for latest request
    if ([self.requestTagPlaceSearch isEqualToString:requestID] ||
        [self.requestTagPlaceSearchPOI isEqualToString:requestID] ) {
        
        NSDictionary *jsonD = [resultD valueForKey:kMPHCJsonKeyJsonObject];
        
        NSString *status = [jsonD valueForKey:kMPHCJsonKeyStatus];
        
        //DDLogInfo(@"LS: place res %@", jsonD);
        
        // if successfull
        if ([status isEqualToString:@"OK"]) {
            
            NSArray *results = [jsonD valueForKey:kMPHCJsonKeyResults];
            if ([results count] > 0) {
                
                NSMutableArray *resAnnoations = [[NSMutableArray alloc] initWithCapacity:8];
                
                int i = 0;
                for (NSDictionary *iResult in results) {
                    
                    NSDictionary *geometry = [iResult valueForKey:kMPHCJsonKeyGeometry];
                    NSDictionary *location = [geometry valueForKey:kMPHCJsonKeyLocation];
                    CGFloat lat = [[location valueForKey:kMPHCJsonKeyLatitude] doubleValue];
                    CGFloat lng = [[location valueForKey:kMPHCJsonKeyLongitude] doubleValue];
                    
                    // if location exists
                    if (lat != 0.0 && lng != 0.0) {
                        NSString *name = [iResult valueForKey:kMPHCJsonKeyName];
                        NSString *vicinity = [iResult valueForKey:kMPHCJsonKeyVicinity];
                        
                        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat, lng);
                        
                        PlaceAnnotation *newAnnotation = [[PlaceAnnotation alloc] init];
                        newAnnotation.coordinate = coordinate;
                        newAnnotation.name = name;
                        newAnnotation.address = vicinity;
                        [resAnnoations addObject:newAnnotation];
                        [newAnnotation release];
                    }
                    i++;
                    if (i==8)
                        break;
                }
                
                // hide center PIN annotation
                [self hideCenterPin];
                
                // remove old annotations
                [self removeCurrentPlaceAnnotations];
                
                // add new annotations and zoom
                [self.mainMapView addAnnotations:resAnnoations];
                [self zoomToAnnotations:resAnnoations];
                [resAnnoations release];
            }
        }
        // did not succeed
        else if ([status isEqualToString:@"ZERO_RESULTS"]) {

            // make sure POI is cleared
            [self deselectPOIButton];
            
            [Utility showAlertViewWithTitle:NSLocalizedString(@"No matches found nearby", @"Location - alert: No search matches or POI found nearby") message:nil];
        }
        
    }
    // else we ignore it
    
}


/*!
 @abstract handle connection failure and reset switch back to original values
 
 */
- (void) processConnectFailure:(NSNotification *)notification {
    
    //[AppUtility stopActivityIndicator];
    NSDictionary *responseD = [notification object];
    
    NSString *queryType = [responseD valueForKey:kTTXMLTypeTag];
    
    // if search setting failed
    if ([queryType isEqualToString:kMPHCRequestTypeMapPlaceSearch]) {
        
        UIActivityIndicatorView *poiIndicator = (UIActivityIndicatorView *)[self.view viewWithTag:POI_ACTIVITY_TAG];
        [poiIndicator stopAnimating];
        
        [self deselectPOIButton];
    }
}


#pragma mark - MKReverseGeocoder

// Delegate methods
- (void)reverseGeocoder:(MKReverseGeocoder*)geocoder didFindPlacemark:(MKPlacemark*)place
{

    // Associate the placemark with the annotation.
    self.centerPinAnnotation.placemark = place;
    

    
}

- (void)reverseGeocoder:(MKReverseGeocoder*)geocoder didFailWithError:(NSError*)error
{
    DDLogVerbose(@"Could not retrieve the specified place information.\n");
}



#pragma mark - Buttons

#define kBTNSize            55.0
#define kBTNWidth           60.0
#define kBTNMarginSmall     5.0
#define kBTNMarginLarge     10.0




/*!
 @abstract Sets up all elements related to search function
 */
- (void)setupButtons {
    
    if (self.locationMode == kLSModeShare) {
        
        // if not root, then there is a next step
        // - for broadcast
        NSString *shareTitle = nil; 
        if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
            shareTitle = NSLocalizedString(@"Share", @"Location - button: shares this location");
        }
        else {
            shareTitle = NSLocalizedString(@"Next", @"Location - button: shares location - go to next step in braodcast");
        }
        
        
        // Nav buttons
        // - next step is required before sending
        //
        UIBarButtonItem *shareButton = [AppUtility barButtonWithTitle:shareTitle
                                                           buttonType:kAUButtonTypeBarHighlight 
                                                               target:self action:@selector(pressShare:)];
        shareButton.enabled = NO;
        self.navigationItem.rightBarButtonItem = shareButton;
        
        UIBarButtonItem *cancelButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Cancel", @"Location - button: cancel status edit") 
                                                            buttonType:kAUButtonTypeBarNormal 
                                                                target:self action:@selector(pressCancel:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
    else if (self.locationMode == kLSModeView ) {
        
        // Nav buttons
        // - next step is required before sending
        //
        UIBarButtonItem *closeButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Close", @"Location - button: close location view") 
                                                           buttonType:kAUButtonTypeBarNormal 
                                                               target:self action:@selector(pressCancel:)];
        closeButton.enabled = YES;
        self.navigationItem.rightBarButtonItem = closeButton;
    }
    

    
    
    // Map Buttons
    CGSize mapSize = self.view.bounds.size;
    
    CGRect moreRect = CGRectMake(kBTNMarginLarge, 
                                 mapSize.height - (kBTNSize + kBTNMarginSmall), kBTNSize, kBTNSize);
    
    CGRect meRect = CGRectMake(kBTNMarginLarge + kBTNSize + kBTNMarginSmall, 
                                 mapSize.height - (kBTNSize + kBTNMarginSmall), kBTNWidth, kBTNSize);
    
    CGRect locRect = CGRectMake(kBTNMarginLarge + kBTNSize + kBTNMarginSmall + kBTNWidth, 
                                 mapSize.height - (kBTNSize + kBTNMarginSmall), kBTNWidth, kBTNSize);
    
    CGRect bothRect = CGRectMake(kBTNMarginLarge + kBTNSize + kBTNMarginSmall + kBTNWidth*2.0, 
                                 mapSize.height - (kBTNSize + kBTNMarginSmall), kBTNWidth, kBTNSize);
    
    CGRect nextLastRect = CGRectMake(mapSize.width - (kBTNSize*2.0+kBTNMarginSmall+kBTNMarginLarge), 
                                 mapSize.height - (kBTNSize + kBTNMarginSmall), kBTNSize, kBTNSize);
    
    CGRect lastRect = CGRectMake(mapSize.width - (kBTNSize+kBTNMarginLarge), 
                                 mapSize.height - (kBTNSize + kBTNMarginSmall), kBTNSize, kBTNSize);
    
    CGRect poiRect = CGRectZero;
    
    // More btn
    //
    if (self.locationMode == kLSModeView ) {
        
        poiRect = lastRect;
        
        UIButton *moreButton = [[UIButton alloc] initWithFrame:moreRect];
        moreButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
        [moreButton setBackgroundImage:[UIImage imageNamed:@"loc_btn_more_nor.png"] forState:UIControlStateNormal];
        [moreButton setBackgroundImage:[UIImage imageNamed:@"loc_btn_more_prs.png"] forState:UIControlStateHighlighted];
        [moreButton addTarget:self action:@selector(pressMore:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:moreButton];
        [moreButton release];


        // Me btn
        //
        UIButton *meButton = [[UIButton alloc] initWithFrame:meRect];
        meButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
        [meButton setBackgroundImage:[UIImage imageNamed:@"loc_btn_me_nor.png"] forState:UIControlStateNormal];
        [meButton setBackgroundImage:[UIImage imageNamed:@"loc_btn_me_prs.png"] forState:UIControlStateHighlighted];
        [meButton setTitle:NSLocalizedString(@"Me", @"Location - button: Show my location") forState:UIControlStateNormal];
        meButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
        [meButton addTarget:self action:@selector(pressMe:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:meButton];
        [meButton release];
        
        // Location btn
        //
        UIButton *locButton = [[UIButton alloc] initWithFrame:locRect];
        locButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
        [locButton setBackgroundImage:[UIImage imageNamed:@"loc_btn_loc_nor.png"] forState:UIControlStateNormal];
        [locButton setBackgroundImage:[UIImage imageNamed:@"loc_btn_loc_prs.png"] forState:UIControlStateHighlighted];
        [locButton setTitle:NSLocalizedString(@"<Location button>", @"Location - button: Show shared location") forState:UIControlStateNormal];
        locButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
        [locButton addTarget:self action:@selector(pressLocation:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:locButton];
        [locButton release];
        
        // Both btn
        //
        UIButton *bothButton = [[UIButton alloc] initWithFrame:bothRect];
        bothButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
        [bothButton setBackgroundImage:[UIImage imageNamed:@"loc_btn_both_nor.png"] forState:UIControlStateNormal];
        [bothButton setBackgroundImage:[UIImage imageNamed:@"loc_btn_both_prs.png"] forState:UIControlStateHighlighted];
        [bothButton setTitle:NSLocalizedString(@"Both", @"Location - button: Show both locations (me & shared location)") forState:UIControlStateNormal];
        bothButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
        [bothButton addTarget:self action:@selector(pressBoth:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:bothButton];
        [bothButton release];
    
    }
    else {
        poiRect = nextLastRect;
        
        // Position btn
        //
        UIButton *positionButton = [[UIButton alloc] initWithFrame:lastRect];
        positionButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
        [positionButton setImage:[UIImage imageNamed:@"loc_btn_position_nor.png"] forState:UIControlStateNormal];
        [positionButton setImage:[UIImage imageNamed:@"loc_btn_position_prs.png"] forState:UIControlStateHighlighted];
        [positionButton addTarget:self action:@selector(pressPosition:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:positionButton];
        [positionButton release];
    }
    
    // POI btn
    //
    UIButton *poiButton = [[UIButton alloc] initWithFrame:poiRect];
    poiButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [poiButton setImage:[UIImage imageNamed:@"loc_btn_poi_nor.png"] forState:UIControlStateNormal];
    //[poiButton setImage:[UIImage imageNamed:@"loc_btn_poi_prs.png"] forState:UIControlStateHighlighted];
    [poiButton setImage:[UIImage imageNamed:@"loc_btn_poi_prs.png"] forState:UIControlStateSelected];
    [poiButton addTarget:self action:@selector(pressPOI:) forControlEvents:UIControlEventTouchUpInside];
    poiButton.tag = POI_BTN_TAG;
    [self.view addSubview:poiButton];
    
    UIActivityIndicatorView *poiIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    // place indicator on POI button
    poiIndicator.frame = CGRectMake( (poiRect.size.width-poiIndicator.frame.size.width)/2.0, 
                                     (poiRect.size.height-poiIndicator.frame.size.height)/2.0,
                                     poiIndicator.frame.size.width, 
                                     poiIndicator.frame.size.height);
    poiIndicator.hidesWhenStopped = YES;
    poiIndicator.tag = POI_ACTIVITY_TAG;
    [poiButton addSubview:poiIndicator];
    [poiIndicator release];
    
    [poiButton release];
    
}

/*!
 @abstract Finds and deselect POI button
 
 Use:
 - called if no POI results
 - if we start regular place search
 
 */
- (void) deselectPOIButton {
    
    UIButton *poiButton = (UIButton *)[self.view viewWithTag:POI_BTN_TAG];
    poiButton.selected = NO;
    
}


/*!
 @abstract Show user location
 */
- (void) pressPosition:(id)sender {
    
    [self zoomToUserLocation];
}

/*!
 @abstract Show points of interest near the center of the mapView
 
 - if not selected: Turn on
  ~ start new search
 
 - if selected: Turn off
  ~ clear old place annotations
  ~ show center pin
 
 */
- (void) pressPOI:(UIButton *)sender {
    
    DDLogInfo(@"LS: press POI");
    
    // clear any existing places
    [self removeCurrentPlaceAnnotations];
    
    UIActivityIndicatorView *poiIndicator = (UIActivityIndicatorView *)[sender viewWithTag:POI_ACTIVITY_TAG];
    
    // turn off
    if (sender.selected) {
        sender.selected = NO;
        [poiIndicator stopAnimating];
        
        if (self.locationMode == kLSModeShare) {
            [self requestCenterPinAddress];
        }
        else {
            [self.mainMapView selectAnnotation:self.sharedLocationAnnotation animated:YES];
        }
    }
    // turn on
    // - start search
    else {
        sender.selected = YES;
        [poiIndicator startAnimating];
        
        CLLocationCoordinate2D center = self.mainMapView.centerCoordinate;
        
        self.requestTagPlaceSearchPOI = [NSString stringWithFormat:@"%f%f", center.latitude, center.longitude];
        
        NSString *types = @"convenience_store|restaurant|cafe|point_of_interest|bar|hotel";

        [[MPHTTPCenter sharedMPHTTPCenter] mapPlaceSearch:center radiusMeters:1000.0 keyword:nil type:types idTag:self.requestTagPlaceSearchPOI];
        
    }
}


/*!
 @abstract Shares selected location
 */
- (void) pressShare:(id)sender {
    
    NSArray *selected = self.mainMapView.selectedAnnotations;
    
    if ([selected count] > 0) {
        
        [AppUtility startActivityIndicator];
        
        self.shareImageDelay = 1.6;
        /* try to test if zoom is need and adjust delay
           - may not be that reliable, so just set a fixed number
        CGFloat mapWidth = self.mainMapView.visibleMapRect.size.width;
        CGFloat mapMeters = mapWidth * MKMetersPerMapPointAtLatitude(self.centerPinAnnotation.coordinate.latitude);
        CGFloat percentDifference = (mapMeters - kMPParamMapPreviewDistanceMinimum)/kMPParamMapPreviewDistanceMinimum;
        DDLogVerbose(@"LS: share zoom diff %f", percentDifference);
        if (percentDifference > 0.2) {
            self.shareImageDelay = 1.6;
        }
        else {
            self.shareImageDelay = 0.8;
        }*/
        
        id selectedAnnotation = [selected objectAtIndex:0];
        self.shareCoordinate = [selectedAnnotation coordinate];
        
        // disable user interaction so users can't move map accidentally
        self.mainMapView.userInteractionEnabled = NO;
        self.mainMapView.zoomEnabled = NO;
        self.mainMapView.scrollEnabled = NO;
        
        // hide user location
        self.mainMapView.showsUserLocation = NO;
        
        // hide center pin view
        [self hideCenterPin];
        
        // clear all annotations
        [self.mainMapView removeAnnotations:self.mainMapView.annotations];
        
        // add single red pin for location
        PreviewAnnotation *locationAnnotation = [[PreviewAnnotation alloc] init];
        locationAnnotation.coordinate = self.shareCoordinate;
        
        // tell controller we want an image when the map has done loading the map and added the annotation
        self.sharePressed = YES;
        
        [self.mainMapView addAnnotation:locationAnnotation];
        [locationAnnotation release];
        

        // move map to desired region area for image capture
        // - no zoom, just pan
        // - less map loading needed
        //
        MKMapRect newRect = self.mainMapView.visibleMapRect;
        MKMapPoint centerPoint = MKMapPointForCoordinate(self.shareCoordinate);
        newRect.origin.x = centerPoint.x - newRect.size.width/2.0;
        newRect.origin.y = centerPoint.y - newRect.size.height/2.0;
        [self.mainMapView setVisibleMapRect:newRect animated:YES];
        
        /*
         // zoom to default level
         // - looks good but requires map loading!, so map may have gray grid background if loading does not finish
         // 
         MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.shareCoordinate, kMPParamMapPreviewDistanceMinimum, kMPParamMapPreviewDistanceMinimum);
        [self.mainMapView setRegion:viewRegion animated:YES];
         */
    }
}


/*!
 @abstract Zoom to my location
 */
- (void) pressMe:(id)sender {
    
    DDLogInfo(@"LS: press ME");

    [self zoomToUserLocation];
}

/*!
 @abstract Zoom to location shared
 */
- (void) pressLocation:(id)sender {
    
    PreviewAnnotation *locAnnotation = nil;
    
    for (id iAnnotation in self.mainMapView.annotations) {
        
        // if it's the user location, just return nil. - use standard view
        if ([iAnnotation isKindOfClass:[PreviewAnnotation class]])
            locAnnotation = iAnnotation;
    }
    
    if (locAnnotation) {
        [self.mainMapView selectAnnotation:locAnnotation animated:YES];
        [self zoomToAnnotation:locAnnotation];
    }
}


/*!
 @abstract Zoom to both locations
 */
- (void) pressBoth:(id)sender {
    
    [self zoomToAnnotations:self.mainMapView.annotations];
    
}

/*!
 @abstract Show more action sheet
 */
- (void) pressMore:(id)sender {
    
    UIActionSheet *aSheet;
    
    aSheet	= [[UIActionSheet alloc]
               initWithTitle:nil 
               delegate:self
               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel contact group action")
               destructiveButtonTitle:nil
               otherButtonTitles:NSLocalizedString(@"Directions", @"Location - Button: Directions to location"),
               NSLocalizedString(@"Copy", @"Location - Button: Copy location addresss"), nil];
    
    aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    [aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
    [aSheet release];
    
}


/*!
 @abstract Show more action sheet
 */
- (void) pressEdit:(id)sender {
    
    TextEditController *nextController = [[TextEditController alloc] init];
    nextController.doneButtonTitle = NSLocalizedString(@"Search", @"Location - button: search address button");
    nextController.originalText = self.centerPinAnnotation.addressString;
    nextController.title = NSLocalizedString(@"Location Address", @"Location - Title: edit address and search");
    nextController.delegate = self;
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
    
}

/*!
 @abstract Cancel location sharing
 */
- (void) pressCancel:(id)sender {
    
    [self dismissModalViewControllerAnimated:YES];
    
}


#pragma mark - Action Sheet Methods

/*!
 @abstract respond to actionsheet selection
 */
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // if not cancel
    if (buttonIndex != [actionSheet cancelButtonIndex]) {
        
		NSString *actionButtonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
		if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Directions",nil)]) {
            
            // only show directions if user loc is available
            // 
            if (self.foundUser) {
                NSString *urlString = [NSString stringWithFormat:@"http://maps.google.com/maps?daddr=%f,%f&saddr=%f,%f", 
                                       self.sharedLocationAnnotation.coordinate.latitude,
                                       self.sharedLocationAnnotation.coordinate.longitude,
                                       self.mainMapView.userLocation.coordinate.latitude, 
                                       self.mainMapView.userLocation.coordinate.longitude
                                       ];
                
                NSURL *url =  [NSURL URLWithString:urlString];
                [[UIApplication sharedApplication] openURL:url];
            }
            // if no location available
            // - alert users and get it
            //
            else {
                
                NSString *title = NSLocalizedString(@"Directions", @"LocationShare: get directions to location");
                NSString *message = NSLocalizedString(@"Your location is not available. Please try again later." , @"LocationShare: without location we can't get the directions");
                [Utility showAlertViewWithTitle:title message:message];
                
                self.mainMapView.showsUserLocation = NO;
                self.mainMapView.showsUserLocation = YES;
            }
		}
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Copy",nil)]) {
         
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = self.sharedLocationAnnotation.address;
            
		}
    }
}


#pragma mark - Search

/*!
 @abstract Sets up all elements related to search function
 */
- (void)setupSearch {
	
	// if search exists then do nothing
	if (searchBar) {
		DDLogVerbose(@"LS-SS: search already exists, do nothing");
		return;
	}
	DDLogVerbose(@"LS-SS: setting up search");
	
	// add search bar to top	
	UISearchBar *sBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    [sBar sizeToFit];
	self.searchBar = sBar;
	[sBar release];
    if ([self.searchBar respondsToSelector:@selector(setImage:forSearchBarIcon:state:)]) {
        [self.searchBar setImage:[UIImage imageNamed:@"loc_icon_search.png"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    }
	self.searchBar.placeholder = NSLocalizedString(@"Search Other Locations", @"Search Placeholder: prompts user to enter search string");
	//self.searchBar.showsCancelButton = YES;
	self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.searchBar.delegate = self;    

    UIColor *searchBarColor = [AppUtility colorForContext:kAUColorTypeSearchBar];
    self.searchBar.tintColor = searchBarColor; // [AppUtility colorForContext:kAUColorTypeSearchBar];
    
    [self.view addSubview:self.searchBar];
    
}

/*!
 @abstract Delegate called when search field tapped
 */
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.searchBar setShowsCancelButton:YES animated:YES];
}

/*!
 @abstract Delegate called when cancel clicked
 */
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.searchBar resignFirstResponder];
}


/*!
 @abstract Delegate called when search clicked
 
 - request place search
 
 */
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    // make sure POI is cleared
    [self deselectPOIButton];
    
    // clear any existing places
    [self removeCurrentPlaceAnnotations];
    
    self.requestTagPlaceSearch = self.searchBar.text;
    
    [[MPHTTPCenter sharedMPHTTPCenter] mapPlaceSearch:self.mainMapView.centerCoordinate radiusMeters:5000.0 keyword:self.searchBar.text type:nil idTag:self.requestTagPlaceSearch];
    [self.searchBar resignFirstResponder];
    
    // clear cancel button
    [self.searchBar setShowsCancelButton:NO animated:YES];
}


#pragma mark - TextEdit 

/*!
 @abstract User pressed saved with new text string
 
 Code:
 - submit forward geocode request to get coordinates
 
 
 */
- (void)TextEditController:(TextEditController *)controller didEditText:(NSString *)newText {
    
    [self showCenterPin];
    
    // clear old address
    self.centerPinAnnotation.addressString = nil;
    
    // show call out
    [self.mainMapView selectAnnotation:self.centerPinAnnotation animated:NO];
    
    self.requestTagForwardGeocode = newText;
    [[MPHTTPCenter sharedMPHTTPCenter] mapForwardGeocodeAddress:newText idTag:self.requestTagForwardGeocode];
    
    [self.navigationController popViewControllerAnimated:YES];
    
}

#pragma mark - Class Tools

/*!
 @abstract Get text representation for coordinate information
 */
+ (NSString *)locationMessageTextForCoordinate:(CLLocationCoordinate2D)coordinate {
    
    NSString *textString = [NSString stringWithFormat:@"%f,%f,0,0,0,0,0", coordinate.latitude, coordinate.longitude];
    return textString;
}

@end
