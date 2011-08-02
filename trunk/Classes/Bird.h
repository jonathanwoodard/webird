//
//  Bird.h
//  WeBIRD
//
//  Created by David J Gagnon on 8/1/11.
//  Copyright 2011 University of Wisconsin. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Bird : NSObject {
    NSNumber*   uid;
    NSString*   scientificName;
    NSString*   commonName;
    UIImage*    image;
}

@property(nonatomic, retain) NSNumber*	uid;
@property(nonatomic, retain) NSString*	scientificName;
@property(nonatomic, retain) NSString*	commonName;
@property(nonatomic, retain) UIImage*   image;

@end
