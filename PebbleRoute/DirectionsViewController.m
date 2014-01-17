//
//  DirectionsViewController.m
//  PebbleRoute
//
//  Created by Remus Lazar on 14.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#import "DirectionsViewController.h"

@interface DirectionsViewController ()
@property (nonatomic, strong) MKDistanceFormatter *distanceFormatter;
@end

@implementation DirectionsViewController

- (void)setCurrentStep:(MKRouteStep *)currentStep
{
	_currentStep = currentStep;
    NSUInteger index = [self.route.steps indexOfObject:self.currentStep];
    if (index != NSNotFound) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]
                              atScrollPosition:UITableViewScrollPositionMiddle
                                      animated:YES];
    }
	[self.tableView reloadData];
}

- (MKDistanceFormatter *)distanceFormatter
{
	if (!_distanceFormatter) _distanceFormatter = [[MKDistanceFormatter alloc] init];
	return _distanceFormatter;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.route ? self.route.steps.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Route Direction Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    MKRouteStep *step = self.route.steps[indexPath.row];

	NSDictionary *attributes = nil;
	if (step == self.currentStep)
		attributes = @{NSForegroundColorAttributeName: [UIColor blueColor] };
	
	NSString *instructionsString = step.distance ? [NSString stringWithFormat:@"%@, %@",
													[[self.distanceFormatter stringFromDistance: step.distance] stringByReplacingOccurrencesOfString:@" " withString:@""],
													step.instructions] : step.instructions;

    cell.textLabel.attributedText = attributes ?
	[[NSAttributedString alloc] initWithString:instructionsString attributes:attributes] :
	[[NSAttributedString alloc] initWithString:instructionsString];
    return cell;
}

- (void)updateUI
{
    [self.view setHidden:self.route == nil];
    [self.tableView reloadData];
}

- (void)setRoute:(MKRoute *)route
{
    _route = route;
    [self updateUI];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self updateUI];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	MKRouteStep *step = self.route.steps[indexPath.row];
	CLLocationCoordinate2D coords = step.polyline.coordinate;
	[self.delegate didSelectLocation:coords];
}

@end
