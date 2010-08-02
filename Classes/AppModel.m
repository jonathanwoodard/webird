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

@implementation AppModel
@synthesize serverURL;


SYNTHESIZE_SINGLETON_FOR_CLASS(AppModel);


-(id)init {
    if (self = [super init]) {
		serverURL = @"http://atsosxdev.doit.wisc.edu/WeBIRD";
	}
	
    return self;
}


- (void)uploadFile:(NSData *)fileData{
	NSString *fileName = @"audio.caf";
	
	
	// setting up the request object now
	NSString *urlString = [NSString stringWithFormat:@"%@/birdMatcher.php", self.serverURL];
	NSURL *url = [NSURL URLWithString:urlString];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	
	[request setPostValue:fileName forKey:@"fileName"];
	[request setData:fileData forKey:@"file"];
	[request setDidFinishSelector:@selector(uploadItemRequestFinished:)];
	[request setDidFailSelector:@selector(uploadItemRequestFailed:)];
	[request setDelegate:self];
	
	NSLog(@"Model: Uploading File. fileName:%@", fileName);
	
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
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Response from Server" 
													message: response 
												   delegate: self 
										  cancelButtonTitle: @"Ok" 
										  otherButtonTitles: nil];
	[alert show];
	[alert release];	
		
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
