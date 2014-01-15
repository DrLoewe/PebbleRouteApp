//
//  FindDestinationTableViewController.m
//  TestApp
//
//  Created by Remus Lazar on 12.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#import "FindDestinationTableViewController.h"

@interface FindDestinationTableViewController () <UISearchBarDelegate, UITableViewDelegate>
@property (strong, nonatomic) MKLocalSearch *localSearch;
@property (strong, nonatomic) MKLocalSearchResponse *searchResponse;
@end

@implementation FindDestinationTableViewController

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
	
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.history.count) {
        // no items in our history, auto select the search field
        [self.searchDisplayController.searchBar becomeFirstResponder];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setSearchResponse:(MKLocalSearchResponse *)searchResponse
{
	_searchResponse = searchResponse;
	[self.searchDisplayController.searchResultsTableView reloadData];
}

- (void)searchDestination:(NSString *)text
{
	NSLog(@"searching for'%@'",text);
	
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
	NSString *street = mark.addressDictionary[@"Street"];
	cell.textLabel.text = item.name;
	CLLocation *origin = [[CLLocation alloc] initWithLatitude:self.region.center.latitude
													longitude:self.region.center.longitude];
	int dist = [item.placemark.location distanceFromLocation:origin];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"[%.1fkm] %@",
								 dist/1000.0,
								 street];
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// we do implement only one segue, so we dont do any checking for now
	UITableViewCell *cell = sender;
	NSIndexPath *indexPath = [[segue.sourceViewController tableView] indexPathForCell:cell];
	MKMapItem *mapItem = nil;
	
	if (indexPath) {
		mapItem = self.history[indexPath.row];
	} else {
		indexPath = [[[segue.sourceViewController searchDisplayController] searchResultsTableView] indexPathForCell:cell];
		if (indexPath)
			mapItem = self.searchResponse.mapItems[indexPath.row];
	}
	
	if (mapItem) {
		self.selectedDestination = mapItem.placemark;
		if ([self.history indexOfObject:mapItem] == NSNotFound)
			[self.history addObject:mapItem];
	}
	
}

@end
