//
//  GPSViewController.h
//  ARIS
//
//  Created by Ben Longoria on 2/11/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Annotation.h"



@interface GPSViewController : UIViewController <MKMapViewDelegate> {
	MKMapView *mapView;
	NSArray *locations;
	BOOL tracking;
	BOOL appSetNextRegionChange;
	IBOutlet UIBarButtonItem *mapTypeButton;
	IBOutlet UIBarButtonItem *playerTrackingButton;
	BOOL silenceNextServerUpdate;
	NSTimer *refreshTimer;

}

-(void) refresh;
-(void) zoomAndCenterMap;


@property (nonatomic, retain) MKMapView *mapView;
@property (nonatomic, retain) NSArray *locations;

@property BOOL tracking;
@property BOOL appSetNextRegionChange;


@property (nonatomic, retain) IBOutlet UIBarButtonItem *mapTypeButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *playerTrackingButton;

@end
