//
//  PebbleRoute.m
//  PebbleRoute
//
//  Created by Remus Lazar on 16.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#import "PebbleRoute.h"

@interface PebbleRoute()
@property (nonatomic, weak, readwrite) MKRouteStep *currentStep;
@property (nonatomic, readwrite) NSUInteger distance;
@end

@implementation PebbleRoute

- (MKPolyline *)currentRoutePath
{
	return self.currentStep.polyline;
}

- (void)setRoute:(MKRoute *)route
{
	_route = route;
	self.currentStep = [self.route.steps firstObject];
	[self calculateDistance];
    [self calculateCurrentStep];
}

// get the distance (in m) from a specified location to self.location
- (NSUInteger)distanceFrom: (CLLocationCoordinate2D)from {
	CLLocation *toLocation = [[CLLocation alloc] initWithLatitude:from.latitude
													  longitude:from.longitude];
	return [self.location distanceFromLocation:toLocation];
}

// calculate the total distance to the final destination using the current location of the user
- (void)calculateDistance
{
	NSUInteger indexOfCurrentStep = [self.route.steps indexOfObject:self.currentStep];
	if (indexOfCurrentStep != NSNotFound) {
		if (self.route.steps.count > (indexOfCurrentStep+1)) {
			
			int totalDistance = 0; // total distance to destination
			
			MKRouteStep *nextStep = self.route.steps[indexOfCurrentStep+1];
			NSUInteger distanceToNextStep = [self distanceFrom:nextStep.polyline.coordinate];
			totalDistance += distanceToNextStep;
			
			for (int i=indexOfCurrentStep+2; i<self.route.steps.count; i++) {
				MKRouteStep *step = self.route.steps[i];
				totalDistance += step.distance;
			}
			if (totalDistance) self.distance = totalDistance;
			//			NSLog(@"total distance: %.1dm",totalDistance);
		}
	}
}

- (void)setLocation:(CLLocation *)location
{
	_location = location;
    [self calculateCurrentStep];
	[self calculateDistance];
}

// calculate the minimum distance from the current location to a given routeStep
- (void)calculateCurrentStep
{
    MKMapPoint origin = MKMapPointForCoordinate(self.location.coordinate);
    float minDistance = MAXFLOAT;
    MKMapPoint pointOnPath;
    MKRouteStep *currentStep;

    for (MKRouteStep *routeStep in self.route.steps) {
        for (NSUInteger i=0; i<routeStep.polyline.pointCount; i++) {
            MKMapPoint point = routeStep.polyline.points[i];
            float dx = point.x - origin.x;
            float dy = point.y - origin.y;
            float distance = dx * dx + dy * dy;
            if (distance <= minDistance) {
                minDistance = distance;
                pointOnPath = point;
                currentStep = routeStep;
            }
        }
    }

//    CLLocationCoordinate2D coordOnRoute = MKCoordinateForMapPoint(pointOnPath);
//    float distance = [self.location distanceFromLocation:[[CLLocation alloc] initWithLatitude:coordOnRoute.latitude longitude:coordOnRoute.longitude]];
//    NSLog(@"distance to route: %.1fm", distance);
    self.currentStep = currentStep;
}

@end
