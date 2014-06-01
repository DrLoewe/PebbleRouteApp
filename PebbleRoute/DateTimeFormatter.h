//
//  DateTimeFormatter.h
//  PebbleRoute
//
//  Created by Remus Lazar on 18.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateTimeFormatter : NSObject

// returns a string representation of the given time interval in a
// human readable way with the appropriate precision
- (NSString *)shortStringForTimeInterval:(NSTimeInterval)timeInterval;

@end
