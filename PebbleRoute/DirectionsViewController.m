//
//  DirectionsViewController.m
//  PebbleRoute
//
//  Created by Remus Lazar on 14.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#import "DirectionsViewController.h"

@interface DirectionsViewController ()

@end

@implementation DirectionsViewController


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.route ? self.route.steps.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Route Direction Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    MKRouteStep *step = self.route.steps[indexPath.row];
    cell.textLabel.text = step.distance ? [NSString stringWithFormat:@"in %.1fkm %@",
                                           step.distance/1000,
                                           step.instructions] :
    step.instructions;
    return cell;
}

- (void)updateUI
{
    NSLog(@"updateUI called");
    [self.view setHidden:self.route == nil];
    [self.tableView reloadData];

    NSLog(@"route: %@", self.route);
    for (MKRouteStep *routeStep in self.route.steps) {
        NSLog(@"%.1fm: %@", routeStep.distance, routeStep.instructions);
    }
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

@end
