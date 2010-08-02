//
//  AppModel.h
//  WeBIRD
//
//  Created by David J Gagnon on 8/2/10.
//  Copyright 2010 University of Wisconsin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"

@interface AppModel : NSObject {
	NSString* serverURL;
}


@property(assign,readonly) NSString* serverURL;



+ (AppModel *)sharedAppModel;
- (void)uploadFile:(NSData *)fileData;



@end
