//
//  AppModel.h
//  WeBIRD
//
//  Created by David J Gagnon on 8/2/10.
//  Copyright 2010 University of Wisconsin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "SynthesizeSingleton.h"

@interface AppModel : NSObject {
	NSString* serverURL;
	NSDictionary* recordSettings;
	CLLocation *currentUserLocation;

}


@property (assign,readonly) NSString* serverURL;
@property (assign,readonly) NSDictionary* recordSettings;
@property (nonatomic, retain) CLLocation *currentUserLocation;



+ (AppModel *)sharedAppModel;
- (void)identifyBirdFromAudio:(NSData *)fileData;



@end
