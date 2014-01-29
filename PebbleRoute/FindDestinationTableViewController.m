//
//  FindDestinationTableViewController.m
//  TestApp
//
//  Created by Remus Lazar on 12.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#import "FindDestinationTableViewController.h"
#import "DestinationDetailViewController.h"
#import <AddressBookUI/AddressBookUI.h>

@interface FindDestinationTableViewController () <UISearchBarDelegate, UITableViewDelegate, ABPeoplePickerNavigationControllerDelegate>
@property (strong, nonatomic) MKLocalSearch *localSearch;
@property (strong, nonatomic) MKLocalSearchResponse *searchResponse;
@property (nonatomic) BOOL firstCall;
@property (nonatomic, strong) MKDistanceFormatter *distanceFormatter;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@end

static NSInteger lastSelectedRow = -1;

@implementation FindDestinationTableViewController


- (MKDistanceFormatter *)distanceFormatter
{
	if (!_distanceFormatter) _distanceFormatter = [[MKDistanceFormatter alloc] init];
	return _distanceFormatter;
}

- (NSMutableArray *)history
{
	if (!_history) _history = [[NSMutableArray alloc] init];
	return _history;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.firstCall = YES;
	
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	// workarround for a bug in the current sdk, so that the UISearchBar.placeholder strings arent getting
	// localized
	self.searchBar.placeholder = NSLocalizedStringWithDefaultValue(@"UgI-xV-4k6.placeholder",
																   @"Main",
																   [NSBundle mainBundle],
																   self.searchBar.placeholder, nil);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.history.count && self.firstCall) {
        // no items in our history, auto select the search field
		//        [self.searchDisplayController.searchBar becomeFirstResponder];
		self.firstCall = NO;
    }
}

- (void)setSearchResponse:(MKLocalSearchResponse *)searchResponse
{
	_searchResponse = searchResponse;
	[self.searchDisplayController.searchResultsTableView reloadData];
}

- (void)searchDestination:(NSString *)text
{
	//	NSLog(@"searching for'%@'",text);
	
	[self.localSearch cancel];
	self.localSearch = nil;
	
	MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
	request.naturalLanguageQuery = text;
	request.region = self.region;
	
	self.localSearch = [[MKLocalSearch alloc] initWithRequest:request];
	[self.localSearch startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
		if (error) {
			NSLog(@"search error: %@",error.description);
		}
		self.searchResponse = error ? nil : response;
	}];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self searchDestination:searchBar.text];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	//	[self searchDestination:searchText];
}

#pragma mark - AddressBook picker and delegate methods

- (IBAction)selectAddressFromLocalAB:(id)sender {
	ABPeoplePickerNavigationController *picker =
	[[ABPeoplePickerNavigationController alloc] init];
	picker.peoplePickerDelegate = self;
	[self presentViewController:picker animated:YES completion:NULL];
}

- (void)peoplePickerNavigationControllerDidCancel:
(ABPeoplePickerNavigationController *)peoplePicker
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person
								property:(ABPropertyID)property
							  identifier:(ABMultiValueIdentifier)identifier
{
	if (property == kABPersonAddressProperty) {
		NSString *name = (__bridge_transfer NSString*)ABRecordCopyCompositeName(person);
		//		NSLog(@"selected person: %@",name);

		ABMultiValueRef addresses = ABRecordCopyValue(person, property);
		CFIndex index = ABMultiValueGetIndexForIdentifier(addresses, identifier);
		CFTypeRef cf_address = ABMultiValueCopyValueAtIndex(addresses, index);

		NSDictionary *address = (__bridge_transfer NSDictionary*)cf_address;
		//		CFRelease(cf_address); // no release because we transfered this ressource to ARC
		CFRelease(addresses);
		//		NSLog(@"selected %@ with address %@",name, address);

		CLGeocoder *geocoder = [[CLGeocoder alloc] init];
		[geocoder geocodeAddressDictionary:address completionHandler:^(NSArray *placemarks, NSError *error) {
			CLPlacemark *abPlacemark = [placemarks firstObject];
			if (error) {
				NSLog(@"geocode error: %@", [error localizedDescription]);
			} else if (abPlacemark) {
				//				NSLog(@"placemark: %@", abPlacemark);
				MKMapItem *abMapItem;
				if ([abPlacemark.region isKindOfClass:[CLCircularRegion class]]) {
					CLCircularRegion *region = (CLCircularRegion *)abPlacemark.region;
					abMapItem =
					[[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc]
														  initWithCoordinate:region.center
														  addressDictionary: address]];
					abMapItem.name = name;
					[self.history addObject:abMapItem];
					[self.tableView reloadData];
					[self performSegueWithIdentifier:@"unwind segue" sender:abMapItem];
				}
			}
		}];
		
		[self dismissViewControllerAnimated:YES completion:NULL];
	} else {
		// @todo show an alert to inform the user to select an address record
	}
	return NO;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
	if (tableView == self.tableView) {
		return self.history.count;
	} else {
		return self.searchResponse ? self.searchResponse.mapItems.count : 0;
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MapItem Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
	MKMapItem *item = nil;
	
    // Configure the cell...
	if (tableView == self.tableView) {
		item = self.history[indexPath.row];
	} else {
		item = self.searchResponse.mapItems[indexPath.row];
	}
	MKPlacemark *mark = item.placemark;
	NSString *street = mark.addressDictionary[(NSString *)kABPersonAddressStreetKey];
	cell.textLabel.text = item.name;
	CLLocation *origin = [[CLLocation alloc] initWithLatitude:self.region.center.latitude
													longitude:self.region.center.longitude];
	int dist = [item.placemark.location distanceFromLocation:origin];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"[%@] %@",
								 [self.distanceFormatter stringFromDistance:dist],
								 street];
	if (lastSelectedRow == indexPath.row) {
		cell.tintColor = [UIColor blackColor];
	}
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

	if ([sender isKindOfClass:[MKMapItem class]]) {
		// it has to be the unwind segue
		MKMapItem *mapItem = sender;
		self.selectedDestination = mapItem.placemark;
	} else if ([sender isKindOfClass:[UITableViewCell class]]) {
		UITableViewCell *cell = sender;
		NSIndexPath *indexPath = [[segue.sourceViewController tableView] indexPathForCell:cell];
		MKMapItem *mapItem = nil;
		
		if (indexPath) {
			mapItem = self.history[indexPath.row];
		} else {
			indexPath = [[[segue.sourceViewController searchDisplayController] searchResultsTableView] indexPathForCell:cell];
			if (indexPath) {
				mapItem = self.searchResponse.mapItems[indexPath.row];
				//			NSLog(@"lastSelectedRow set now to %d",indexPath.row);
				lastSelectedRow = indexPath.row;
				[self.searchDisplayController.searchResultsTableView reloadData];
			}
		}
		
		if ([segue.destinationViewController isKindOfClass:[DestinationDetailViewController class]]) {
			DestinationDetailViewController *dvc = segue.destinationViewController;
			dvc.mapItem = mapItem;
		} else { // it has to be the unwind segue
			if (mapItem) {
				self.selectedDestination = mapItem.placemark;
				if ([self.history indexOfObject:mapItem] == NSNotFound)
					[self.history addObject:mapItem];
			}
		}
	}
}

@end
