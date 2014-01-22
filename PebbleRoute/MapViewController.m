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
#import <PebbleKit/PebbleKit.h>

// rl_route app uuid here
#define PEBBLE_APP_UUID @"cf59151f-4dff-4221-a109-7dde3377545c"

// treshold for location change delta to update UI stuff in m
#define SIGNIFICANT_DISTANCE_FOR_UPDATE_UI 25

@interface MapViewController () <MKMapViewDelegate, DirectionsViewControllerDelegate, UIGestureRecognizerDelegate,
									CLLocationManagerDelegate, UIActionSheetDelegate, PBPebbleCentralDelegate>

@property (nonatomic) MKCoordinateRegion region; // current region reflecting the current user location
@property (nonatomic, strong) MKPlacemark *destination; // selected destination
@property (nonatomic, strong) NSMutableArray *destinationHistory; // of MKMapItem
@property (nonatomic, strong) MKDistanceFormatter *distanceFormatter;
@property (nonatomic, strong) MKRoute *route; // current route (or nil when no route active)
@property (nonatomic, weak) MKRouteStep *currentStep; // on our route

// map annotations for the final destination and the current (next) route step
@property (nonatomic, strong) MKPointAnnotation *destinationAnnotation;
@property (nonatomic, strong) MKPointAnnotation *routeStepAnnotation;

@property (nonatomic, strong) PebbleRoute *pebbleRoute; // our model
@property (nonatomic, weak) DirectionsViewController *directionsVC; // embedded mvc, we dont need a strong pointer

// outlets
@property (weak, nonatomic) IBOutlet UIView *directionsContainerView; // where the embedded directions mvc resides
@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (weak, nonatomic) IBOutlet UILabel *RouteDistanceLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) PBWatch *pebbleWatch;
@property (nonatomic) BOOL pebbleWatchStateNormal;
@property (nonatomic, strong) UIBarButtonItem *pebbleWatchButtonItem;

@end

@implementation MapViewController

#pragma mark - UI actions

// recalculate route button (refresh icon in the top toolbar)
- (IBAction)recalculateRoute:(id)sender {
    [self calculateRoute];
}

#pragma mark - lazy instantiation of properties

- (UIBarButtonItem *)pebbleWatchButtonItem
{
    if (!_pebbleWatchButtonItem) {
        _pebbleWatchButtonItem =
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Pebble Watch Bar Icon.png"]
                                         style:UIBarButtonItemStylePlain target:nil action:NULL];
        _pebbleWatchButtonItem.enabled = NO;
    }
    return _pebbleWatchButtonItem;
}

- (CLLocationManager *)locationManager
{
	if (!_locationManager) {
		_locationManager = [[CLLocationManager alloc] init];
		_locationManager.delegate = self;

		/*
		 CLActivityTypeFitness
		 The location manager is being used to track any pedestrian-related activity. This activity might cause location updates
		 to be paused only when the user does not move a significant distance over a period of time.
		 Available in iOS 6.0 and later.
		 */

		_locationManager.activityType = CLActivityTypeFitness;
	}
	return _locationManager;
}

@synthesize destinationAnnotation = _destinationAnnotation;
- (MKPointAnnotation *)destinationAnnotation
{
	if (!_destinationAnnotation) _destinationAnnotation = [[MKPointAnnotation alloc] init];
	[self.map addAnnotation:_destinationAnnotation];
	return _destinationAnnotation;
}
- (void)setDestinationAnnotation:(MKPointAnnotation *)destinationAnnotation
{
	[self.map removeAnnotation:_destinationAnnotation];
	_destinationAnnotation = destinationAnnotation;
}

@synthesize routeStepAnnotation = _routeStepAnnotation; // we implement both setter and getter
- (void)setRouteStepAnnotation:(MKPointAnnotation *)routeStepAnnotation
{
	[self.map removeAnnotation:_routeStepAnnotation];
	_routeStepAnnotation = routeStepAnnotation;
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

#pragma mark - Properties

- (void)setRoute:(MKRoute *)route
{
	_route = route;
	self.pebbleRoute.route = route;
	[self showRoute];

	if (route) {
		self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
		[self.locationManager startUpdatingLocation];
        if (self.pebbleWatch) [self pebbleSendRouteStep:0];
	} else {
		[self.locationManager stopUpdatingLocation];
		self.locationManager = nil;
		[self updateLocationOnMap];
	}
}

#pragma mark - Public API

- (void)setDestination:(MKPlacemark *)destination
{
	_destination = destination;
	self.destinationAnnotation.coordinate = destination.coordinate;
	self.destinationAnnotation.title = destination.name;
    self.title = destination.name;
	self.directionsContainerView.hidden = YES;
    [self calculateRoute];
}

#pragma mark - Internal methods

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
			self.route = nil;
		} else {
			MKRoute *route = [response.routes firstObject];
			self.route = route;
		}
		self.refreshButton.enabled = YES;
    }];
}

// show the route after the route was changed. This method is called only once while a route is created
-(void)showRoute
{
	if (self.directionsVC.route) {
		MKRoute *oldRoute = self.directionsVC.route;
		// clean up references to the old route
		[self.map removeOverlay:oldRoute.polyline];
	}
	// setup the new route in the directions view controller
    self.directionsVC.route = self.route;
	if (self.route) {
		self.RouteDistanceLabel.text = [NSString stringWithFormat:@"∑ %@ (%@)",
										[self.distanceFormatter stringFromDistance:self.route.distance],
										[DateTimeFormatter shortStringForTimeInterval:self.route.expectedTravelTime]
										];
		self.RouteDistanceLabel.hidden = NO;
		[self.map addOverlay:self.route.polyline level:MKOverlayLevelAboveRoads];
		self.currentStep = nil;
		self.directionsContainerView.hidden = NO; // it will be set to hidden in setDestination
        [self.map showAnnotations:self.map.annotations animated:YES];
	} else {
		self.RouteDistanceLabel.hidden = YES;
		self.directionsContainerView.hidden = YES;
		self.routeStepAnnotation = nil;
		self.destinationAnnotation = nil;
		self.title = @"No active route";
        [self.map setRegion:self.region animated:YES];
	}
	[self updateLocationOnMap];
}

// update the map to reflect the current routing state. This method is called periodically while the user location
// is updated
- (void)updateLocationOnMap
{
	static MKPolyline *currentRoutePath = nil;

	if (self.route) {
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
	} else {
		// no current route
		if (currentRoutePath) {
			[self.map removeOverlay:currentRoutePath];
			currentRoutePath = nil;
		}
	}
}

#define MIN_STEP_DISTANCE_FOR_ALERT 80

- (void)updateLocationInBackground
{
	static __weak MKRouteStep *oldRouteStep = nil;
	
//	NSLog(@"distance in current step: %f, total distance of current step: %f",
//		  self.pebbleRoute.remainingDistanceInCurrentStep,
//		  self.pebbleRoute.currentStep.distance);

	if (self.pebbleRoute.lastStep.distance >= MIN_STEP_DISTANCE_FOR_ALERT &&
		self.pebbleRoute.currentStep != self.pebbleRoute.lastStep &&
		self.pebbleRoute.lastStep != oldRouteStep) {
		oldRouteStep = self.pebbleRoute.lastStep;
		UILocalNotification *notification = [[UILocalNotification alloc] init];
		notification.alertBody = self.pebbleRoute.lastStep.instructions;
		notification.soundName = UILocalNotificationDefaultSoundName;
		notification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
		[[UIApplication sharedApplication] presentLocalNotificationNow:notification];
	} else if (self.pebbleRoute.currentStep == [self.route.steps lastObject] &&
			   self.pebbleRoute.remainingDistanceInCurrentStep == 0) {
		UILocalNotification *notification = [[UILocalNotification alloc] init];
		notification.alertBody = [NSString stringWithFormat:@"🏁 %@, %@",self.destination.name,
								  self.pebbleRoute.currentStep.instructions];
		notification.soundName = UILocalNotificationDefaultSoundName;
		notification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
		[[UIApplication sharedApplication] presentLocalNotificationNow:notification];

		// clear the current route now, we reached destination
		self.route = nil;
	}
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
	//	NSLog(@"MKMapView: current location %@", userLocation.location);
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

	if (!self.locationManager) { // no location manager available
		[self processUpdatedUserLocation:userLocation.location];
	}
}

#pragma mark - CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	CLLocation *currentLocation = [locations lastObject];
	//	NSLog(@"CLLocationManager: current location %@", currentLocation);
	[self processUpdatedUserLocation:currentLocation];
}

- (void)processUpdatedUserLocation:(CLLocation *)location
{
	// perform further updates only if the user location has changed significantly
	static CLLocation *lastLocation = nil;
	if (!lastLocation || [location distanceFromLocation:lastLocation] > SIGNIFICANT_DISTANCE_FOR_UPDATE_UI) {
		lastLocation = location;
		//		NSLog(@"location updated");
		// update the current user location in our model
		self.pebbleRoute.currentUserLocation = location;

		if (self.pebbleWatch) {
			[self pebbleUpdateLocation];
		}

		if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
			[self updateLocationOnMap];
		} else {
			// running in background
			if (!self.pebbleWatch || !self.pebbleWatchStateNormal)
				[self updateLocationInBackground];
		}
	}
}

#pragma mark - Segues
#pragma mark Outgoing

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

#pragma mark Unwind Segues

// FindDestinationViewController will call this action on unwind
- (IBAction)selectDestination:(UIStoryboardSegue *)segue {
	self.destination = [[segue sourceViewController] selectedDestination];
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
							 trackingButton,
							 [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																		   target:nil
																		   action:nil],
                             self.pebbleWatchButtonItem,
							 [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																		   target:nil
																		   action:@selector(toolbarAction)],
							 ] animated:YES
	 ];

    // init the connected pebble watch now
    [self initPebbleWatch];
}

- (void)toolbarAction
{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
															 delegate:self
													cancelButtonTitle:@"Cancel"
											   destructiveButtonTitle:@"Stop navigation"
													otherButtonTitles:@"Recalculate Route",
								  nil];
	[actionSheet showFromToolbar:self.toolbar];
}

#pragma mark - action sheet actions

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
		case 0:
			self.route = nil;
			[self showRoute];
			break;

		case 1:
			[self calculateRoute];
			break;
			
		default:
			break;
	}
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

#pragma mark - MKOverlay renderer

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

#pragma mark - Pebble Watch, AppMessage and Delegate Methods

- (void)setPebbleWatch:(PBWatch *)pebbleWatch
{
    _pebbleWatch = pebbleWatch;
    if (pebbleWatch) {
//        NSLog(@"pebble available, register the receiving handler");
        [pebbleWatch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update) {
            NSLog(@"Received message: %@", update);
//            [self pebbleSendRouteStep:0];
            return YES;
        }];
        self.pebbleWatchButtonItem.enabled = YES;
		self.pebbleWatchStateNormal = YES;
    } else {
        self.pebbleWatchButtonItem.enabled = NO;
    }
}

- (void)initPebbleWatch
{
    uuid_t myAppUUIDbytes;
    NSUUID *myAppUUID = [[NSUUID alloc] initWithUUIDString:PEBBLE_APP_UUID];
    [myAppUUID getUUIDBytes:myAppUUIDbytes];
    [[PBPebbleCentral defaultCentral] setAppUUID:[NSData dataWithBytes:myAppUUIDbytes length:16]];

    self.pebbleWatch = [[PBPebbleCentral defaultCentral] lastConnectedWatch];
    [[PBPebbleCentral defaultCentral] setDelegate:self];
    NSLog(@"Last connected watch: %@", self.pebbleWatch);

    if (self.pebbleWatch) {
        [self pebbleLaunchApp];
    }
}

-(void)pebbleLaunchApp
{
    [self.pebbleWatch appMessagesLaunch:^(PBWatch *watch, NSError *error) {
        if (!error) {
            NSLog(@"Successfully launched app.");
        }
        else {
            NSLog(@"Error launching app - Error: %@", error);
        }
    }];
}

- (void)pebbleCentral:(PBPebbleCentral *)central watchDidConnect:(PBWatch *)watch isNew:(BOOL)isNew
{
    NSLog(@"Pebble connected: %@", [watch name]);
    self.pebbleWatch = watch;
    [self pebbleLaunchApp];
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidDisconnect:(PBWatch*)watch
{
    NSLog(@"Pebble disconnected: %@", [watch name]);
    
    if (self.pebbleWatch == watch || [watch isEqual:self.pebbleWatch]) {
        self.pebbleWatch = nil;
    }
}

- (void)pebbleUpdateLocation {
	NSUInteger index = [self.route.steps indexOfObject:self.pebbleRoute.currentStep];
    NSDictionary *appMessage = @{
                                 @(3): [NSNumber numberWithInt8:index],
                                 @(4): [self.distanceFormatter stringFromDistance:self.pebbleRoute.distance],
                                 };
    
    [self.pebbleWatch appMessagesPushUpdate:appMessage onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
        if (!error) {
			NSLog(@"Successfully sent message %@", appMessage);
			
        }
        else {
            NSLog(@"Error sending message: %@", error);
        }
		self.pebbleWatchStateNormal = !error;
    }];
	
}

- (void)pebbleSendRouteStep:(NSUInteger)routeStepIndex
{
    if (!self.route) return; // no route, stop here
    if (routeStepIndex >= self.route.steps.count) return; // no more steps, break
    MKRouteStep *routeStep = self.route.steps[routeStepIndex];
    
    NSDictionary *appMessage = @{
                                 @(0): [NSNumber numberWithInt8:routeStepIndex],
                                 @(1): [self.distanceFormatter stringFromDistance:routeStep.distance],
                                 @(2): routeStep.instructions
                                 };
    
    [self.pebbleWatch appMessagesPushUpdate:appMessage onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
        if (!error) {
			//            NSLog(@"Successfully sent message.");
            [self pebbleSendRouteStep:routeStepIndex+1];
        }
        else {
            NSLog(@"Error sending message: %@", error);
			self.pebbleWatchStateNormal = !error;
        }
    }];
}

@end
