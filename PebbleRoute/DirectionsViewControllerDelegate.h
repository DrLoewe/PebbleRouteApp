//
//  DirectionsViewControllerDelegate.h
//  PebbleRoute
//
//  Created by Remus Lazar on 14.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DirectionsViewControllerDelegate <NSObject>
@optional
- (void)didSelectLocation:(CLLocationCoordinate2D)location;
@end
