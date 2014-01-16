//
//  DestinationDetailViewController.m
//  PebbleRoute
//
//  Created by Remus Lazar on 16.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#import "DestinationDetailViewController.h"

@interface DestinationDetailViewController () <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@property (weak, nonatomic) IBOutlet UILabel *testLabel;

@end

@implementation DestinationDetailViewController

- (void)viewWillAppear:(BOOL)animated
{
	self.title = self.mapItem.placemark.name;
	self.addressLabel.text = self.mapItem.placemark.addressDictionary[@"Street"];
	self.phoneLabel.text = self.mapItem.phoneNumber;
	self.urlLabel.text = [self.mapItem.url description];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// we do have only one alert view, so we know that this one shoud be the alert view for the phone call..
	if (buttonIndex == 1) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:
													[@"tel://" stringByAppendingString: self.mapItem.phoneNumber]]];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.row) {
		case 1:
			// place phone call
			if (self.mapItem.phoneNumber) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Phone Call"
																message:[NSString stringWithFormat:@"Call %@?", self.mapItem.phoneNumber]
															   delegate:self
													  cancelButtonTitle:@"Cancel"
													  otherButtonTitles:@"Call",nil];
				[alert show];
			}
			break;
			
		case 2:
			// call url
			if (self.mapItem.url)
				[[UIApplication sharedApplication] openURL:self.mapItem.url];
			break;
			
		default:
			break;
	}
}

@end
