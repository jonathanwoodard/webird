//
//  Annotation.m
//  ARIS
//
//  Created by Brian Deith on 7/21/09.
//  Copyright 2009 Brian Deith. All rights reserved.
//

#import "Annotation.h"


@implementation Annotation

@synthesize coordinate;
@synthesize title;
@synthesize subtitle;


-(id)initWithCoordinate:(CLLocationCoordinate2D) c{
	if (self == [super init]) {
		coordinate=c;
	}
	NSLog(@"Annotation: Annotation created");
	return self;
}


@end
