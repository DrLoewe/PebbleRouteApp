//
//  MapViewController.m
//  TestApp
//
//  Created by Remus Lazar on 12.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#import "MapViewController.h"
#import "FindDestinationTableViewController.h"

@interface MapViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *map;
@end

@implementation MapViewController

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
	// calculate route for destination
	MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
	
	MKMapItem *source = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:self.region.center addressDictionary:nil]];
	request.source = source;
	request.destination = [[MKMapItem alloc] initWithPlacemark:self.destination];
	request.transportType = MKDirectionsTransportTypeWalking;

	MKDirections *route = [[MKDirections alloc] initWithRequest:request];
	[route calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
		for (MKRoute *route in response.routes) {
			NSLog(@"route: %@", route);
			for (MKRouteStep *routeStep in route.steps) {
				NSLog(@"%.1fm: %@", routeStep.distance, routeStep.instructions);
			}
		}
	}];
	
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		NSLog(@"initWithNibName");
    }
    return self;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
	NSLog(@"didUpdateUserLocation to lat=%f&lon=%f",userLocation.coordinate.latitude, userLocation.coordinate.longitude);

	MKCoordinateRegion region;
	region.center = userLocation.coordinate;
	region.span.latitudeDelta = 1;
	region.span.longitudeDelta = 1;
	
	self.region = region;
	[self.map setRegion:self.region animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.destinationViewController isKindOfClass:[FindDestinationTableViewController class]]) {
		FindDestinationTableViewController *dvc = segue.destinationViewController;
		dvc.history = self.destinationHistory;
		dvc.region = self.region;
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	NSLog(@"viewDidLoad()");
	// Do any additional setup after loading the view.
	self.map.showsUserLocation = YES;
	self.map.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)selectDestination:(UIStoryboardSegue *)segue {
	self.destination = [[segue sourceViewController] selectedDestination];
	NSLog(@"selected destination: %@",self.destination);
}

@end
