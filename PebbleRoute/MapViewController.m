//
//  MapViewController.m
//  TestApp
//
//  Created by Remus Lazar on 12.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#import "MapViewController.h"
#import "FindDestinationTableViewController.h"
#import "DirectionsViewController.h"
#import "DirectionsViewControllerDelegate.h"
#import "PebbleRoute.h"
#import "DateTimeFormatter.h"

@interface MapViewController () <MKMapViewDelegate, DirectionsViewControllerDelegate, UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (nonatomic, weak) DirectionsViewController *directionsVC;
@property (weak, nonatomic) IBOutlet UILabel *RouteDistanceLabel;
@property (nonatomic, strong) MKDistanceFormatter *distanceFormatter;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) PebbleRoute *pebbleRoute; // our model
@property (nonatomic, weak) MKRouteStep *currentStep; // on our route
@property (nonatomic, strong) MKPointAnnotation *destinationAnnotation;
@property (nonatomic, strong) MKPointAnnotation *routeStepAnnotation;
@end

@implementation MapViewController

#pragma mark - Outlets

// recalculate route button (refresh icon in the top toolbar)
- (IBAction)recalculateRoute:(id)sender {
    [self calculateRoute];
}

#pragma mark - lazy instantiation of properties

- (MKPointAnnotation *)destinationAnnotation
{
	if (!_destinationAnnotation) _destinationAnnotation = [[MKPointAnnotation alloc] init];
	[self.map addAnnotation:_destinationAnnotation];
	return _destinationAnnotation;
}

- (MKPointAnnotation *)routeStepAnnotation
{
	if (!_routeStepAnnotation) _routeStepAnnotation = [[MKPointAnnotation alloc] init];
	[self.map addAnnotation:_routeStepAnnotation];
	return _routeStepAnnotation;
}

- (PebbleRoute *)pebbleRoute
{
	if (!_pebbleRoute) _pebbleRoute = [[PebbleRoute alloc] init];
	return _pebbleRoute;
}

- (MKDistanceFormatter *)distanceFormatter
{
	if (!_distanceFormatter) _distanceFormatter = [[MKDistanceFormatter alloc] init];
	return _distanceFormatter;
}

- (NSArray *)destinationHistory
{
	if (!_destinationHistory) _destinationHistory = [[NSMutableArray alloc] init];
	return _destinationHistory;
}

#pragma mark - public API

- (void)setDestination:(MKPlacemark *)destination
{
	_destination = destination;
	self.destinationAnnotation.coordinate = destination.coordinate;

	[self.destinationAnnotation setCoordinate:destination.coordinate];
	self.destinationAnnotation.title = destination.name;
    self.title = destination.name;
    [self calculateRoute];
}

#pragma mark - internal methods

- (void)calculateRoute
{
    self.refreshButton.enabled = NO;
    // calculate route for destination
	MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
	
	MKMapItem *source = [[MKMapItem alloc] initWithPlacemark:
						 [[MKPlacemark alloc] initWithCoordinate:self.region.center addressDictionary:nil]];
	request.source = source;
	request.destination = [[MKMapItem alloc] initWithPlacemark:self.destination];
	request.transportType = MKDirectionsTransportTypeWalking;
	MKDirections *route = [[MKDirections alloc] initWithRequest:request];
	[route calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
		if (error) {
			[[[UIAlertView alloc] initWithTitle:@"Route failure"
									   message:error.localizedDescription
									  delegate:nil
							 cancelButtonTitle:nil
							 otherButtonTitles:@"OK", nil] show];
		} else {
			MKRoute *route = [response.routes firstObject];
			self.pebbleRoute.route = route;
			[self showRoute:route];
		}
		self.refreshButton.enabled = YES;
    }];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];

	// draw to full route in light gray, the current remaining route path in blue
	if (overlay == self.pebbleRoute.route.polyline) {
		renderer.strokeColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:.4];
	} else {
		renderer.strokeColor = [UIColor colorWithRed:.5 green:0 blue:.5 alpha:.4];
	}

    renderer.lineWidth = 5.0;
    return renderer;
}



// show the route after the route was calculated
-(void)showRoute:(MKRoute *)route
{
	if (self.directionsVC.route) {
		MKRoute *oldRoute = self.directionsVC.route;
		// clean up references to the old route
		[self.map removeOverlay:oldRoute.polyline];
	}
    self.directionsVC.route = route;
	self.RouteDistanceLabel.text = [NSString stringWithFormat:@"∑ %@ (%@)",
									[self.distanceFormatter stringFromDistance:route.distance],
									[DateTimeFormatter shortStringForTimeInterval:route.expectedTravelTime]
									];
	self.RouteDistanceLabel.hidden = NO;
	[self.map addOverlay:route.polyline level:MKOverlayLevelAboveRoads];
	self.currentStep = nil;
	[self updateLocationOnMap];
	[self.map setRegion:self.region animated:YES];
	
}

- (void)updateLocationOnMap
{
	static MKPolyline *currentRoutePath = nil;

	if (!self.pebbleRoute.route) return;
	
	if (self.currentStep != self.pebbleRoute.currentStep) {
		// currentStep changed
		self.currentStep = self.pebbleRoute.currentStep;
		if (currentRoutePath)
			[self.map removeOverlay:currentRoutePath];
		currentRoutePath = [self.pebbleRoute currentRoutePath];
		[self.map addOverlay:currentRoutePath];
		[self.routeStepAnnotation setCoordinate:self.pebbleRoute.currentStep.polyline.coordinate];
	}
	[self.directionsVC setCurrentStep:self.pebbleRoute.currentStep distance:self.pebbleRoute.remainingDistanceInCurrentStep];
	self.title = [NSString stringWithFormat:@"%@ ⇢ %@",
				  [self.distanceFormatter stringFromDistance:self.pebbleRoute.distance],
				  self.destination.name
				  ];
}

#pragma mark - MKMapViewDelegate protocoll

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
	static NSString *pinViewIdentifier = @"pinView";
	
	if (annotation == self.map.userLocation) return nil;
	
	MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:pinViewIdentifier];
	if (!pinView) {
		pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
												  reuseIdentifier:pinViewIdentifier];
	}

	pinView.pinColor =
	annotation == self.destinationAnnotation ? MKPinAnnotationColorGreen :
	annotation == self.routeStepAnnotation ? MKPinAnnotationColorPurple :
	MKPinAnnotationColorRed;
	
	pinView.canShowCallout = YES;

	return pinView;
}

// user moved and his position got updated
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
	//	NSLog(@"didUpdateUserLocation to lat=%f&lon=%f",userLocation.coordinate.latitude, userLocation.coordinate.longitude);

	MKCoordinateRegion region;
	region.center = userLocation.coordinate;
	region.span.latitudeDelta = .1;
	region.span.longitudeDelta = .1;

	if (!CLLocationCoordinate2DIsValid(self.region.center) ||
		(self.region.center.longitude == 0.0 &&
		self.region.center.latitude == 0.0)) {
		[self.map setRegion:region animated:YES];
	}
	
	self.region = region;
	// update the current user location in our model
	self.pebbleRoute.currentUserLocation = userLocation.location;
	[self updateLocationOnMap];
}

#pragma mark - segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.destinationViewController isKindOfClass:[FindDestinationTableViewController class]]) {
		FindDestinationTableViewController *dvc = segue.destinationViewController;
		dvc.history = self.destinationHistory;
		dvc.region = self.region;
	} else if ([segue.identifier isEqualToString:@"Show Directions"]) {
        DirectionsViewController *dvc = segue.destinationViewController;
		dvc.delegate = self;
        self.directionsVC = dvc;
    }
}

#pragma mark - MVC Livecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	self.map.showsUserLocation = YES;
	self.map.delegate = self;
	MKUserTrackingBarButtonItem *trackingButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.map];
	[self.toolbar setItems:@[
							 [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																		   target:nil
																		   action:nil],
							 trackingButton] animated:YES
	 ];
}

#pragma unwind segue actions

// FindDestinationViewController will call this action on unwind
- (IBAction)selectDestination:(UIStoryboardSegue *)segue {
	self.destination = [[segue sourceViewController] selectedDestination];
}

#pragma mark - DirectionsViewControllerDelegate protocoll

// user clicked on a table row in the directions table mvc
- (void)didSelectLocation:(CLLocationCoordinate2D)location
{
	MKCoordinateRegion region;
	region.center = location;
	region.span.latitudeDelta = .02;
	region.span.longitudeDelta = .02;
	[self.map setRegion:region animated:YES];
	[self.routeStepAnnotation setCoordinate:location];
}

@end
