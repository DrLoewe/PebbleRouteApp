//
//  DestinationDetailViewController.h
//  PebbleRoute
//
//  Created by Remus Lazar on 16.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface DestinationDetailViewController : UITableViewController
@property (nonatomic, strong) MKMapItem *mapItem;
@end
