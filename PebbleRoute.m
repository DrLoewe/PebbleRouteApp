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
@property (nonatomic, readwrite) float distance;
@property (nonatomic, readwrite) float remainingDistanceInCurrentStep;
@end

@implementation PebbleRoute

#pragma mark - properties

- (void)setRoute:(MKRoute *)route
{
	_route = route;
    [self calculateCurrentStep];
	[self calculateDistance];
}

- (void)setCurrentUserLocation:(CLLocation *)location
{
	_currentUserLocation = location;
    [self calculateCurrentStep];
	[self calculateDistance];
}

#pragma mark - public API

- (MKPolyline *)currentRoutePath
{
	return self.currentStep.polyline;
}

#pragma mark - internal methods

// calculate the total distance to the final destination using the current location of the user
- (void)calculateDistance
{
	NSUInteger indexOfCurrentStep = [self.route.steps indexOfObject:self.currentStep];
	if (indexOfCurrentStep != NSNotFound) {
		float totalDistance = self.remainingDistanceInCurrentStep;
		for (NSUInteger i=indexOfCurrentStep+1; i<self.route.steps.count; i++) {
			MKRouteStep *step = self.route.steps[i];
			totalDistance += step.distance;
		}
		self.distance = totalDistance;
	}
}

// determine which is the current step in the current route and set the properties
// currentStep and remaining distance accordingly
- (void)calculateCurrentStep
{
    MKMapPoint origin = MKMapPointForCoordinate(self.currentUserLocation.coordinate);
    float minDistance = MAXFLOAT;
//    MKMapPoint pointOnPath;
    MKRouteStep *currentStep;
//	NSUInteger pointIndex;

    for (MKRouteStep *routeStep in self.route.steps) {
        for (NSUInteger i=0; i<routeStep.polyline.pointCount; i++) {
            MKMapPoint point = routeStep.polyline.points[i];
            float dx = point.x - origin.x;
            float dy = point.y - origin.y;
            float distance = dx * dx + dy * dy;

            // by using < we get only the first point having a minimum distance to
            // the user location
            if (distance < minDistance) {
//				pointIndex = i;
                minDistance = distance;
//                pointOnPath = point;
                currentStep = routeStep;
            }
        }
    }

    self.currentStep = currentStep;
	
	if (self.currentStep.polyline.pointCount < 2) {
		self.remainingDistanceInCurrentStep = 0;
	} else {
		float totalDistance = 0;
		float distanceFromPointToEnd = 0;
		for (NSUInteger i=0; i<self.currentStep.polyline.pointCount-1; i++) {
			float distance = [PebbleRoute distanceFrom:self.currentStep.polyline.points[i]
													to:self.currentStep.polyline.points[i+1]];
			totalDistance += distance;
//			if (i >= pointIndex) {
//				distanceFromPointToEnd += distance;
//			}
		}
		self.remainingDistanceInCurrentStep = distanceFromPointToEnd / totalDistance * self.currentStep.distance;
		//		NSLog(@"remaining distance in current step: %.1f", self.remainingDistanceInCurrentStep);
	}
}

+ (float)distanceFrom:(MKMapPoint)from to:(MKMapPoint)to
{
	float dx = from.x - to.x;
	float dy = from.y - to.y;
	return sqrtf(dx * dx + dy * dy);
}

@end
