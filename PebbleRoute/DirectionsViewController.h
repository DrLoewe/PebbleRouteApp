//
//  DirectionsViewController.h
//  PebbleRoute
//
//  Created by Remus Lazar on 14.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "DirectionsViewControllerDelegate.h"

@interface DirectionsViewController : UITableViewController
@property (strong, nonatomic) MKRoute *route;
@property (nonatomic, weak) MKRouteStep *currentStep;
@property (nonatomic, weak) id <DirectionsViewControllerDelegate> delegate;
@end
