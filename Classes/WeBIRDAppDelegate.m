//
//  WeBIRDAppDelegate.m
//  WeBIRD
//
//  Created by David J Gagnon on 8/2/10.
//  Copyright University of Wisconsin 2010. All rights reserved.
//

#import "WeBIRDAppDelegate.h"
#import "AppModel.h"
#import "AudioRecorderViewController.h"


@implementation WeBIRDAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize navController;
@synthesize locationManager;
@synthesize waitingIndicator;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
	//Register for location updates
	NSLog(@"WeBIRDAppDelegate: Init, Configure and Start Location Manager");
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self; // Tells the location manager to send updates to this object
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	locationManager.distanceFilter = 5; //Minimum change of 5 meters for update
	[locationManager startUpdatingLocation];
	
	
	
    // Add the tab bar controller's view to the window and display.
	NSLog(@"WeBIRDAppDelegate: Configure UI");
    //[window addSubview:tabBarController.view];
	AudioRecorderViewController *audioRecorderVC = [[AudioRecorderViewController alloc] initWithNibName:@"AudioRecorderViewController" bundle:nil];
	self.navController = [[UINavigationController alloc]initWithRootViewController:audioRecorderVC];
	[window addSubview:self.navController.view];
	
    [window makeKeyAndVisible];

    return YES;
}


- (void) showWaitingIndicator:(NSString *)message displayProgressBar:(BOOL)displayProgressBar {
	NSLog (@"AppDelegate: Showing Waiting Indicator");
	if (!self.waitingIndicator) {
		self.waitingIndicator = [[WaitingIndicatorViewController alloc] initWithNibName:@"WaitingIndicator" bundle:nil];
	}
	self.waitingIndicator.message = message;
	self.waitingIndicator.progressView.hidden = !displayProgressBar;
	
	//by adding a subview to window, we make sure it is put on top
	[self.window addSubview:self.waitingIndicator.view]; 
	
}

- (void) removeWaitingIndicator {
	NSLog (@"AppDelegate: Removing Waiting Indicator");
	if (self.waitingIndicator != nil) [self.waitingIndicator.view removeFromSuperview ];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark UITabBarControllerDelegate methods

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
}
*/


#pragma mark -
#pragma mark CLLocationManager Delegate methods
// Called when the location is updated
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	
	NSLog(@"WeBIRDAppDelegate: Read %lf, %lf from CLLocationManager with Accuracy of %gm,%gm", newLocation.coordinate.latitude,
		  newLocation.coordinate.longitude,  newLocation.horizontalAccuracy, newLocation.verticalAccuracy );
	
	//Update the Model
	[AppModel sharedAppModel].currentUserLocation = newLocation;
	
}

// Called when there is an error getting the location
- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	NSMutableString *errorString = [[[NSMutableString alloc] init] autorelease];
	
	if ([error domain] == kCLErrorDomain) {
		
		// We handle CoreLocation-related errors here
		
		switch ([error code]) {
				// This error code is usually returned whenever user taps "Don't Allow" in response to
				// being told your app wants to access the current location. Once this happens, you cannot
				// attempt to get the location again until the app has quit and relaunched.
				//
				// "Don't Allow" on two successive app launches is the same as saying "never allow". The user
				// can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
				//
			case kCLErrorDenied:
				[errorString appendFormat:@"%@\n", NSLocalizedString(@"LocationDenied", nil)];
				break;
				
				// This error code is usually returned whenever the device has no data or WiFi connectivity,
				// or when the location cannot be determined for some other reason.
				//
				// CoreLocation will keep trying, so you can keep waiting, or prompt the user.
				//
			case kCLErrorLocationUnknown:
				[errorString appendFormat:@"%@\n", NSLocalizedString(@"LocationUnknown", nil)];
				break;
				
				// We shouldn't ever get an unknown error code, but just in case...
				//
			default:
				[errorString appendFormat:@"%@ %d\n", NSLocalizedString(@"GenericLocationError", nil), [error code]];
				break;
		}
	} else {
		// We handle all non-CoreLocation errors here
		// (we depend on localizedDescription for localization)
		[errorString appendFormat:@"Error domain: \"%@\"  Error code: %d\n", [error domain], [error code]];
		[errorString appendFormat:@"Description: \"%@\"\n", [error localizedDescription]];
	}
	
	//Send the update somewhere?
}



#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [tabBarController release];
    [window release];
    [super dealloc];
}

@end

