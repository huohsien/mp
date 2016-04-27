//
//  CenterPinAnnotation.h
//  mp
//
//  Created by Min Tsai on 2/11/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface CenterPinAnnotation: NSObject <MKAnnotation> {
    
    UIImage *image;
    NSNumber *latitude;
    NSNumber *longitude;
    
    CLLocationCoordinate2D coordinate;
    
    MKPlacemark *placemark;
    NSString *addressString;

}

@property (nonatomic, retain) UIImage *image;

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

/*! place that this annotation represents */
@property (nonatomic, retain) MKPlacemark *placemark;

/*! address obtained from reverse geocode */
@property (nonatomic, retain) NSString *addressString;


@end
