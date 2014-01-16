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
@end

@implementation PebbleRoute

- (MKPolyline *)currentRoutePath
{
	NSUInteger indexOfCurrentStep = [self.route.steps indexOfObject:self.currentStep];
	if (indexOfCurrentStep != NSNotFound) {
		if (self.route.steps.count > (indexOfCurrentStep+1)) {
			MKRouteStep *step = self.route.steps[indexOfCurrentStep+1];
			if (step) return step.polyline;
		}
	}
	return self.currentStep.polyline;
}

- (void)setRoute:(MKRoute *)route
{
	_route = route;
	NSLog(@"PebbleRoute: new route setup: %@", self.route);
	MKPolyline *polyline = self.route.polyline;
	NSLog(@"polyline has %d points", polyline.pointCount);
	self.currentStep = [self.route.steps firstObject];
}

// get the distance (in m) from a specified location to self.location
- (NSUInteger)distanceFrom: (CLLocationCoordinate2D)from {
	CLLocation *toLocation = [[CLLocation alloc] initWithLatitude:from.latitude
													  longitude:from.longitude];
	return [self.location distanceFromLocation:toLocation];
}

- (void)setLocation:(CLLocation *)location
{
	_location = location;
	
	NSUInteger currentDistance = [self distanceFrom:self.currentStep.polyline.coordinate];
	
	for (MKRouteStep *step in self.route.steps) {
		int distance = [self distanceFrom:step.polyline.coordinate];
		if (distance < currentDistance) {
			self.currentStep = step;
		}
	}
	
	NSUInteger indexOfCurrentStep = [self.route.steps indexOfObject:self.currentStep];
	if (indexOfCurrentStep != NSNotFound) {
		if (self.route.steps.count > (indexOfCurrentStep+1)) {
			
			int totalDistance = 0; // total distance to destination
			
			MKRouteStep *nextStep = self.route.steps[indexOfCurrentStep+1];
			int distanceToNextStep = [self distanceFrom:nextStep.polyline.coordinate];
			totalDistance += distanceToNextStep;
			
			for (int i=indexOfCurrentStep+2; i<self.route.steps.count; i++) {
				MKRouteStep *step = self.route.steps[i];
				totalDistance += step.distance;
			}
			
			//			NSLog(@"total distance: %.1dm",totalDistance);
		}
	}
}

@end
