//
//  AppModel.m
//  WeBIRD
//
//  Created by David J Gagnon on 8/2/10.
//  Copyright 2010 University of Wisconsin. All rights reserved.
//

#import "AppModel.h"
#import "ASIFormDataRequest.h"
#import "WeBIRDAppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "SBJSON.h"
#import "WeBIRDAppDelegate.h"
#import "Bird.h"
#import "BirdImageViewController.h"


@implementation AppModel
@synthesize serverURL;
@synthesize recordSettings;
@synthesize currentUserLocation;



SYNTHESIZE_SINGLETON_FOR_CLASS(AppModel);


-(id)init {
    if (self = [super init]) {
		serverURL = @"http://ornithology.wisc.edu/webird";
        //serverURL = @"http://davembp.local";
		recordSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
										[NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
										[NSNumber numberWithInt:44100.0],AVSampleRateKey,
										[NSNumber numberWithInt: 1],AVNumberOfChannelsKey,
										[NSNumber numberWithInt: 32], AVLinearPCMBitDepthKey,
										[NSNumber numberWithBool: NO],AVLinearPCMIsBigEndianKey,
										[NSNumber numberWithBool: YES],AVLinearPCMIsFloatKey,
										nil];
		
	}
	
    return self;
}


- (void)identifyBirdFromAudio:(NSData *)fileData{
	NSString *fileName = @"audio.m4a";
	
	
	// setting up the request object now
	NSString *urlString = [NSString stringWithFormat:@"%@/birdMatcherTest.php", self.serverURL];
	NSURL *url = [NSURL URLWithString:urlString];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	
	[request setPostValue:fileName forKey:@"fileName"];
	[request setData:fileData forKey:@"file"];
	[request setDidFinishSelector:@selector(uploadItemRequestFinished:)];
	[request setDidFailSelector:@selector(uploadItemRequestFailed:)];
	[request setDelegate:self];
	
	NSLog(@"Model: Uploading %@ to %@", fileName, urlString);
	
	WeBIRDAppDelegate* appDelegate = (WeBIRDAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate showWaitingIndicator:@"Uploading" displayProgressBar:YES];
	[request setUploadProgressDelegate:appDelegate.waitingIndicator.progressView];
	[request startAsynchronous];
}

- (void)uploadItemRequestFinished:(ASIFormDataRequest *)request
{
	WeBIRDAppDelegate* appDelegate = (WeBIRDAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate removeWaitingIndicator];
	
	NSString *response = [request responseString];
	
	NSLog(@"Model: Upload Media Request Finished. Response: %@", response);
	
    
    //Parse It
	SBJsonParser *parser = [[SBJsonParser alloc] init];
    NSDictionary *resultDictionary = [parser objectWithString:response]; 
    
    
    int birdId;
    NSString *birdIDString = [resultDictionary objectForKey:@"birdId"];
    if ((NSNull *)birdIDString != [NSNull null]) birdId = [birdIDString intValue];
    
    float reliability;
    NSString *reliabilityString = [resultDictionary objectForKey:@"reliability"];
    if ((NSNull *)reliabilityString != [NSNull null]) reliability = [reliabilityString intValue];

    
    
    //Load the image and Name if we have it
    
    Bird *b = [[Bird alloc]init];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Bird Not In Database" 
                                                    message: [NSString stringWithFormat:@"Result from server: \nId = %d \n R = %f", birdId, reliability]
                                                   delegate: self 
                                          cancelButtonTitle: @"Ok" 
                                          otherButtonTitles: nil];
    switch (birdId) {
        case 1652:
            b.commonName = @"Cerulean Warbler";
            break;
        case 1530:
            b.commonName = @"Wood Thrush";
            break;
        case 1307:
            b.commonName = @"Warbling Vireo";
            break;
        case 1399:
            b.commonName = @"Tufted Titmouse";
            break;
        case 1439:
            b.commonName = @"House Wren";
            break;
        case 1811:
            b.commonName = @"Eastern Towhee";
            break;
        case 1669:
            b.commonName = @"Common Yellowthroat";
            break;
        case 1833:
            b.commonName = @"Chipping Sparrow";
            break;
        case 1340:
            b.commonName = @"Blue Jay";
            break;
        case 1390:
            b.commonName = @"Black-capped Chickadee";
            break;
        default:
            [alert show];
            [alert release];
            return;
            break;
    }
    
    b.uid = [NSNumber numberWithInt: birdId];
    b.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",b.uid]];

    
    BirdImageViewController *bivc = [[BirdImageViewController alloc]initWithBird:b];
    [b release];
    
    [appDelegate.navController pushViewController:bivc animated:YES];
    [bivc release];
    
		
}

- (void)uploadItemRequestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	NSLog(@"Model: upload failed: %@",[error localizedDescription]);

	WeBIRDAppDelegate* appDelegate = (WeBIRDAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate removeWaitingIndicator];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Upload Failed" 
													message: @"An network error occured while uploading the file" 
												   delegate: self 
										  cancelButtonTitle: @"Ok" 
										  otherButtonTitles: nil];
	[alert show];
	[alert release];
}



@end
