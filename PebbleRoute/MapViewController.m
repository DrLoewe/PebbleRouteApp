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

@interface MapViewController () <MKMapViewDelegate, DirectionsViewControllerDelegate, UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (nonatomic, weak) DirectionsViewController *directionsVC;
@property (weak, nonatomic) IBOutlet UILabel *RouteDistanceLabel;
@property (nonatomic, strong) MKDistanceFormatter *distanceFormatter;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) PebbleRoute *pebbleRoute; // our model
@property (nonatomic, weak) MKRouteStep *currentStep; // on our route
@end

@implementation MapViewController

- (IBAction)tap:(id)sender {
	self.toolbar.hidden = NO;
	[sender setCancelsTouchesInView:NO];
}

#pragma mark - Outlets

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
	self.toolbar.hidden = YES;
}

- (IBAction)recalculateRoute:(id)sender {
    [self calculateRoute];
}

#pragma mark - lazy instantiation of properties

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

- (void)setDestination:(MKPlacemark *)destination
{
	_destination = destination;
	MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
	[annotation setCoordinate:destination.coordinate];
	[self.map addAnnotation:annotation];
    self.title = destination.name;
    [self calculateRoute];
}

#pragma mark - route functions

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
		renderer.strokeColor = [UIColor blueColor];
	} else {
		renderer.strokeColor = [UIColor redColor];
	}

    renderer.lineWidth = 5.0;
    return renderer;
}

-(void)showRoute:(MKRoute *)route
{
	if (self.directionsVC.route) {
		MKRoute *oldRoute = self.directionsVC.route;
		// clean up references to the old route
		[self.map removeOverlay:oldRoute.polyline];
	}
    self.directionsVC.route = route;
	self.RouteDistanceLabel.text = [NSString stringWithFormat:@"Total distance: %@",
									[self.distanceFormatter stringFromDistance:route.distance]];
	self.RouteDistanceLabel.hidden = NO;
	[self.map addOverlay:route.polyline level:MKOverlayLevelAboveRoads];
	self.currentStep = nil;
	[self updateLocationOnMap];
}

- (void)updateLocationOnMap
{
	static MKPolyline *currentRoutePath = nil;

	if (!self.pebbleRoute.route) return;
	
	if (self.currentStep != self.pebbleRoute.currentStep) {
		NSLog(@"currentStep changed");
		self.currentStep = self.pebbleRoute.currentStep;
		if (currentRoutePath)
			[self.map removeOverlay:currentRoutePath];
		currentRoutePath = [self.pebbleRoute currentRoutePath];
		NSLog(@"current route path: %@", currentRoutePath);
		[self.map addOverlay:currentRoutePath];
	}
}

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
	self.pebbleRoute.location = userLocation.location;
	[self updateLocationOnMap];
}

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
							 trackingButton] animated:YES
	 ];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)selectDestination:(UIStoryboardSegue *)segue {
	self.destination = [[segue sourceViewController] selectedDestination];
}

#pragma mark - DirectionsViewControllerDelegate

- (void)didSelectLocation:(CLLocationCoordinate2D)location
{
	MKCoordinateRegion region;
	region.center = location;
	region.span.latitudeDelta = .02;
	region.span.longitudeDelta = .02;
	[self.map setRegion:region animated:YES];
	
	static MKPointAnnotation *annotation = nil;
	[self.map removeAnnotation:annotation];

	annotation = [[MKPointAnnotation alloc] init];
	[annotation setCoordinate:location];
	[self.map addAnnotation:annotation];
}

@end
