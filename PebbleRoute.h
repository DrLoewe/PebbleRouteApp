//
//  PebbleRoute.h
//  PebbleRoute
//
//  Created by Remus Lazar on 16.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface PebbleRoute : NSObject
@property (nonatomic, strong) MKRoute *route;
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, weak, readonly) MKRouteStep *currentStep;
- (MKPolyline *)currentRoutePath; // get the current remaining route(path) as Polyline
@end
