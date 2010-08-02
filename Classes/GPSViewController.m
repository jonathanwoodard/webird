//
//  GPSViewController.m
//  ARIS
//
//  Created by Ben Longoria on 2/11/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#import "GPSViewController.h"
#import "AppModel.h"
#import "Annotation.h"


static float INITIAL_SPAN = 0.001;

@implementation GPSViewController

@synthesize locations;
@synthesize mapView;
@synthesize tracking;
@synthesize appSetNextRegionChange; 
@synthesize mapTypeButton;
@synthesize playerTrackingButton;

//Override init for passing title and icon to tab bar
- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    self = [super initWithNibName:nibName bundle:nibBundle];
    if (self) {
		tracking = YES;
	}
	
    return self;
}

		
- (IBAction)changeMapType: (id) sender {
	
	switch (mapView.mapType) {
		case MKMapTypeStandard:
			mapView.mapType=MKMapTypeSatellite;
			break;
		case MKMapTypeSatellite:
			mapView.mapType=MKMapTypeHybrid;
			break;
		case MKMapTypeHybrid:
			mapView.mapType=MKMapTypeStandard;
			break;
	}
}

- (IBAction)refreshButtonAction: (id) sender{
	NSLog(@"GPSViewController: Refresh Button Touched");
	
	//resume auto centering
	tracking = YES;
	playerTrackingButton.style = UIBarButtonItemStyleDone;

	//Rerfresh all contents
	[self refresh];

}
		
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	NSLog(@"GPSViewCrontroller: viewDidLoad");

	//Setup the Map
	CGFloat tableViewHeight = 372; //416-44; // todo: get this from const
	CGRect mainViewBounds = self.view.bounds;
	CGRect tableFrame;
	tableFrame = CGRectMake(CGRectGetMinX(mainViewBounds),
							CGRectGetMinY(mainViewBounds),
							CGRectGetWidth(mainViewBounds),
							tableViewHeight);
	
	NSLog(@"GPSViewController: Mapview about to be inited.");
	mapView = [[MKMapView alloc] initWithFrame:tableFrame];
	[mapView setFrame:tableFrame];
	MKCoordinateRegion region = mapView.region;
	region.span.latitudeDelta=0.001;
	region.span.longitudeDelta=0.001;
	[mapView setRegion:region animated:NO];
	[mapView regionThatFits:region];
	mapView.showsUserLocation = YES;
	[mapView setDelegate:self]; //View will request annotation views from us
	[self.view addSubview:mapView];
	NSLog(@"GPSViewController: Mapview inited and added to view");
	
	
	//Setup the buttons
	mapTypeButton.target = self; 
	mapTypeButton.action = @selector(changeMapType:);
	
	playerTrackingButton.target = self; 
	playerTrackingButton.action = @selector(refreshButtonAction:);
	playerTrackingButton.style = UIBarButtonItemStyleDone;

	[self refresh];	
	
	

	NSLog(@"GPSViewController: View Loaded");
}

- (void)viewDidAppear:(BOOL)animated {
	
	[self refresh];		
	
	//remove any existing badge
	self.tabBarItem.badgeValue = nil;
	
	//create a time for automatic map refresh
	NSLog(@"GPSViewController: Starting Refresh Timer");
	if (refreshTimer != nil && [refreshTimer isValid]) [refreshTimer invalidate];
	refreshTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(refresh) userInfo:nil repeats:YES];

	
	NSLog(@"GPSViewController: view did appear");
}

- (void)viewWillDisappear:(BOOL)animated {
	NSLog(@"GPSViewController: Stopping Refresh Timer");
	if (refreshTimer) {
		[refreshTimer invalidate];
		refreshTimer = nil;
	}
}


// Updates the map to current data for player and locations from the server
- (void) refresh {
	if (mapView) {
		NSLog(@"GPSViewController: refresh requested");	
	
		//Zoom and Center
		if (tracking) [self zoomAndCenterMap];

	} else {
		NSLog(@"GPSViewController: refresh requested but ignored, as mapview is nil");	
		
	}
}

-(void) zoomAndCenterMap {
	
	appSetNextRegionChange = YES;
	
	//Center the map on the player
	MKCoordinateRegion region = mapView.region;
	region.center = [AppModel sharedAppModel].currentUserLocation.coordinate;
	region.span = MKCoordinateSpanMake(INITIAL_SPAN, INITIAL_SPAN);

	[mapView setRegion:region animated:YES];
		
}


/*
- (void)refreshViewFromModel {
	if (mapView) {
		//only refresh if there's a mapview
		NSLog(@"GPSViewController: Refreshing view from model");
	
	
		//Add a badge if this is NOT the first time data has been loaded
		if (silenceNextServerUpdate == NO) {
			self.tabBarItem.badgeValue = @"!";
			
			//ARISAppDelegate* appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
			//[appDelegate playAudioAlert:@"mapChange" shouldVibrate:YES]; //this is a little annoying becasue it happens even when players move
			
		}
		else silenceNextServerUpdate = NO;
	
		//Blow away the old markers except for the player marker
		NSEnumerator *existingAnnotationsEnumerator = [[[mapView annotations] copy] objectEnumerator];
		NSObject <MKAnnotation> *annotation;
		while (annotation = [existingAnnotationsEnumerator nextObject]) {
			if (annotation != mapView.userLocation) [mapView removeAnnotation:annotation];
		}
	
		locations = appModel.locationList;
	
		//Add the freshly loaded locations from the notification
		for ( Location* location in locations ) {
			NSLog(@"GPSViewController: Adding location annotation for:%@ id:%d", location.name, location.locationId);
			if (location.hidden == YES) 
			{
				NSLog(@"No I'm not, because this location is hidden.");
				continue;
			}
			CLLocationCoordinate2D locationLatLong = location.location.coordinate;
			
			Annotation *annotation = [[Annotation alloc]initWithCoordinate:locationLatLong];
			
			annotation.title = location.name;
			if (location.kind == NearbyObjectItem && location.qty > 1) annotation.subtitle = [NSString stringWithFormat:@"Quantity: %d",location.qty];
			NSLog(@"GPSViewController: Annotation title is %@; subtitle is %@.", annotation.title, annotation.subtitle);
			
			annotation.iconMediaId = location.iconMediaId; //if we have a custom icon
			annotation.kind = location.kind; //if we want a default icon

			[mapView addAnnotation:annotation];
			if (!mapView) {
				NSLog(@"GPSViewController: Just added an annotation to a null mapview!");
			}
			
			[annotation release];
		}
		
		//Add the freshly loaded players from the notification
		for ( Player *player in appModel.playerList ) {
			if (player.hidden == YES) continue;
			CLLocationCoordinate2D locationLatLong = player.location.coordinate;

			Annotation *aPlayer = [[Annotation alloc]initWithCoordinate:locationLatLong];
			aPlayer.title = player.name;
			[mapView addAnnotation:aPlayer];
			[aPlayer release];
		} 
	} else {
		NSLog(@"GPSViewController: Refresh requested but ignored, as mapview is nil.");
	}
}
*/


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
	[mapView release];
    [super dealloc];
}

-(UIImage *)addTitle:(NSString *)imageTitle quantity:(int)quantity toImage:(UIImage *)img {
	
	NSString *calloutString;
	if (quantity > 1) {
		calloutString = [NSString stringWithFormat:@"%@:%d",imageTitle, quantity];
	} else {
		calloutString = imageTitle;
	}
 	UIFont *myFont = [UIFont fontWithName:@"Arial" size:12];
	CGSize textSize = [calloutString sizeWithFont:myFont];
	CGRect textRect = CGRectMake(0, 0, textSize.width + 10, textSize.height);
	
	//callout path
	CGMutablePathRef calloutPath = CGPathCreateMutable();
	CGPoint pointerPoint = CGPointMake(textRect.origin.x + 0.6 * textRect.size.width,  textRect.origin.y + textRect.size.height + 5);
	CGPathMoveToPoint(calloutPath, NULL, textRect.origin.x, textRect.origin.y);
	CGPathAddLineToPoint(calloutPath, NULL, textRect.origin.x, textRect.origin.y + textRect.size.height);
	CGPathAddLineToPoint(calloutPath, NULL, pointerPoint.x - 5.0, textRect.origin.y + textRect.size.height);
	CGPathAddLineToPoint(calloutPath, NULL, pointerPoint.x, pointerPoint.y);
	CGPathAddLineToPoint(calloutPath, NULL, pointerPoint.x + 5.0, textRect.origin.y+ textRect.size.height);
	CGPathAddLineToPoint(calloutPath, NULL, textRect.origin.x + textRect.size.width, textRect.origin.y + textRect.size.height);
	CGPathAddLineToPoint(calloutPath, NULL, textRect.origin.x + textRect.size.width, textRect.origin.y);
	CGPathAddLineToPoint(calloutPath, NULL, textRect.origin.x, textRect.origin.y);
	
	
	
	CGRect imageRect = CGRectMake(0, textSize.height + 10.0, img.size.width, img.size.height);
	CGRect backgroundRect = CGRectUnion(textRect, imageRect);
	if (backgroundRect.size.width > img.size.width) {
		imageRect.origin.x = (backgroundRect.size.width - img.size.width) / 2.0;
	}
	
	CGSize contextSize = backgroundRect.size;
	UIGraphicsBeginImageContext(contextSize);
	CGContextAddPath(UIGraphicsGetCurrentContext(), calloutPath);
	[[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.6] set];
	CGContextFillPath(UIGraphicsGetCurrentContext());
	[[UIColor blackColor] set];
	CGContextAddPath(UIGraphicsGetCurrentContext(), calloutPath);
	CGContextStrokePath(UIGraphicsGetCurrentContext());
	[img drawAtPoint:imageRect.origin];
	[calloutString drawInRect:textRect withFont:myFont lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
	UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
	CGPathRelease(calloutPath);
	UIGraphicsEndImageContext();
	
	return returnImage;
}


#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
	//User must have moved the map. Turn off Tracking
	NSLog(@"GPSVC: regionDidChange delegate metohd fired");

	if (!appSetNextRegionChange) {
		NSLog(@"GPSViewController: regionDidChange without appSetNextRegionChange, it must have been the user");
		tracking = NO;
		playerTrackingButton.style = UIBarButtonItemStyleBordered;
	}
	
	appSetNextRegionChange = NO;


}


- (MKAnnotationView *)mapView:(MKMapView *)myMapView viewForAnnotation:(id <MKAnnotation>)annotation{
	NSLog(@"GPSViewController: In viewForAnnotation");

	
	//Player
	if (annotation == mapView.userLocation)
	{
		NSLog(@"GPSViewController: Getting the annotation view for the user's location");
		 return nil; //Let it do it's own thing
	}
	
	MKAnnotationView *annotationView=[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"marker"];
	annotationView.image = [UIImage imageNamed:@"item.png"];
	annotationView.canShowCallout = YES;
	return annotationView;
}


@end
