//
//  MapViewController.h
//  TestApp
//
//  Created by Remus Lazar on 12.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MapViewController : UIViewController
@property (nonatomic) MKCoordinateRegion region;
@property (nonatomic, strong) MKPlacemark *destination;
@property (nonatomic, strong) NSMutableArray *destinationHistory; // of MKMapItem
@end
