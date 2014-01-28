//
//  DestinationDetailViewController.m
//  PebbleRoute
//
//  Created by Remus Lazar on 16.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#import "DestinationDetailViewController.h"
#import <MapKit/MapKit.h>

@interface DestinationDetailViewController () <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@property (weak, nonatomic) IBOutlet UILabel *testLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@end

@implementation DestinationDetailViewController

- (void)viewWillAppear:(BOOL)animated
{
	self.title = self.mapItem.placemark.name;
	self.addressLabel.text = self.mapItem.placemark.addressDictionary[@"Street"];
	self.phoneLabel.text = self.mapItem.phoneNumber;

	if (self.mapItem.url) {
		// strip the scheme (http, https) and "://" from the url description
		self.urlLabel.text = [[self.mapItem.url description] stringByReplacingCharactersInRange:
							  NSMakeRange(0, self.mapItem.url.scheme.length+3) withString:@""];
	}
	
	// lazy instantiate this guy
	static MKPointAnnotation *destinationAnnotation = nil;
	if (!destinationAnnotation) destinationAnnotation = [[MKPointAnnotation alloc] init];

	destinationAnnotation.title = self.title;
	destinationAnnotation.coordinate = self.mapItem.placemark.coordinate;
	[self.mapView addAnnotation:destinationAnnotation];

	MKCoordinateRegion region;
	region.center = self.mapItem.placemark.coordinate;
	region.span.latitudeDelta = .02;
	region.span.longitudeDelta = .02;
	
	[self.mapView setRegion:region animated:NO];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// we do have only one alert view, so we know that this one shoud be the alert view for the phone call..
	if (buttonIndex == 1) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:
													[@"tel://" stringByAppendingString: self.mapItem.phoneNumber]]];
	}
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.row) {
		case 1:
			// place phone call
			if (!self.mapItem.phoneNumber) {
				cell.accessoryType = UITableViewCellAccessoryNone;
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
			break;
			
		case 2:
			// call url
			if (!self.mapItem.url) {
				cell.accessoryType = UITableViewCellAccessoryNone;
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
			break;
			
		default:
			break;
	}
	
}

#define ALERT_PHONE_CALL_TITLE NSLocalizedStringFromTable(@"ALERT_PHONE_CALL_TITLE", @"DestinationDetailViewController", @"Title of the AlertView to confirm a phone call")

#define ALERT_CANCEL_BUTTON_TITLE NSLocalizedStringFromTable(@"ALERT_CANCEL_BUTTON_TITLE", @"DestinationDetailViewController", @"Cancel button text")

#define ALERT_CALL_BUTTON_TITLE NSLocalizedStringFromTable(@"ALERT_CALL_BUTTON_TITLE", @"DestinationDetailViewController", @"Title of the Button to actually perform the phone call")

#define ALERT_CALL_MESSAGE_TEXT NSLocalizedStringFromTable(@"ALERT_CALL_MESSAGE_TEXT", @"DestinationDetailViewController", @"The Message on the above AlertView as a formatted string, the phone number has to be included in the message using %@")

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.row) {
		case 1:
			// place phone call
			if (self.mapItem.phoneNumber) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ALERT_PHONE_CALL_TITLE
																message:[NSString stringWithFormat:ALERT_CALL_MESSAGE_TEXT, self.mapItem.phoneNumber]
															   delegate:self
													  cancelButtonTitle:ALERT_CANCEL_BUTTON_TITLE
													  otherButtonTitles:ALERT_CALL_BUTTON_TITLE, nil];
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
