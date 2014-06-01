//
//  DateTimeFormatter.m
//  PebbleRoute
//
//  Created by Remus Lazar on 18.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#import "DateTimeFormatter.h"
@interface DateTimeFormatter()
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@end

@implementation DateTimeFormatter

#pragma mark - properties

- (NSDateFormatter *)dateFormatter
{
	if (!_dateFormatter) _dateFormatter = [[NSDateFormatter alloc] init];
	NSLog(@"format: %@", [NSDateFormatter dateFormatFromTemplate:@"HHmm" options:0 locale:[NSLocale currentLocale]]);
	[_dateFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"HHmm" options:0 locale:[NSLocale currentLocale]]];
	return _dateFormatter;
}

#pragma mark - Public API

- (NSString *)shortStringForTimeInterval:(NSTimeInterval)timeInterval
{
	return [self.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timeInterval]];
	
//	if (timeInterval < 60) {
//		return @"< 1 min";
//	} else if (timeInterval < 3600) {
//		return [NSString stringWithFormat:@"%.0f min",timeInterval/60];
//	} else {
//		return [NSString stringWithFormat:@"%.1f h",timeInterval/3600];
//	}
}

@end
