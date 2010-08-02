//
//  WeBIRDAppDelegate.h
//  WeBIRD
//
//  Created by David J Gagnon on 8/2/10.
//  Copyright University of Wisconsin 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLLocationManagerDelegate.h>
#import "WaitingIndicatorViewController.h"

@interface WeBIRDAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, CLLocationManagerDelegate > {
    UIWindow *window;
    UITabBarController *tabBarController;
	CLLocationManager *locationManager;
	CLLocation *currentUserLocation;
	WaitingIndicatorViewController *waitingIndicator;

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *currentUserLocation;
@property (nonatomic, retain) WaitingIndicatorViewController *waitingIndicator;


- (void) showWaitingIndicator:(NSString *)message displayProgressBar:(BOOL)yesOrNo;
- (void) removeWaitingIndicator;
 

@end
