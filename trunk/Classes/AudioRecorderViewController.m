//
//  AudioRecorderViewController.m
//  ARIS
//
//  Created by David J Gagnon on 4/6/10.
//  Copyright 2010 University of Wisconsin - Madison. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

#import "AudioRecorderViewController.h"
#import "AppModel.h";
#import "AudioTrimmerViewController.h"


@implementation AudioRecorderViewController
@synthesize soundFileURL;
@synthesize soundRecorder;
@synthesize soundPlayer;
@synthesize meter;
@synthesize meterUpdateTimer;
@synthesize audioData;


// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		self.title = @"Recorder";	
    }
    return self;
}


/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
 }
 */


 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	 // Return YES for supported orientations.
	 //return (interfaceOrientation == UIInterfaceOrientationPortrait);
	 return YES;
 }
 


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	meter = [[AudioMeter alloc]initWithFrame:CGRectMake(0, 0, 320, 420)]; //TODO: Make meter resize
	meter.alpha = 0.0;
	[self.view addSubview:meter];
	[self.view sendSubviewToBack:meter];
	
	NSString *tempDir = NSTemporaryDirectory ();
    NSString *soundFilePath =[tempDir stringByAppendingString: @"sound.caf"];
	
    NSURL *newURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
    self.soundFileURL = newURL;
    [newURL release];
	
	[[AVAudioSession sharedInstance] setDelegate: self];
	
	mode = kAudioRecorderReady; 
	[self updateButtonsForCurrentMode];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

- (void)updateButtonsForCurrentMode{
	
	switch (mode) {
		case kAudioRecorderReady:
			[recordStopOrPlayButton setTitle: @"Begin Recording" forState: UIControlStateNormal];
			break;
		case kAudioRecorderRecording:
			[recordStopOrPlayButton setTitle: @"Stop Recording" forState: UIControlStateNormal];
			break;
	}
}

- (IBAction) recordStopOrPlayButtonAction: (id) sender{
	
	NSLog(@"AudioRecorder: Record/Play/Stop Button selected");
	
	switch (mode) {
		case kAudioRecorderReady:
			NSLog(@"AudioRecorder: Record/Play/Stop Button selected");
			
			[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryRecord error: nil];	
			
			NSDictionary *recordSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
											[NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
											[NSNumber numberWithInt:44100.0],AVSampleRateKey,
											[NSNumber numberWithInt: 1],AVNumberOfChannelsKey,
											[NSNumber numberWithInt: AVAudioQualityMin],AVSampleRateConverterAudioQualityKey,
											nil];
			
			AVAudioRecorder *newRecorder = [[AVAudioRecorder alloc] initWithURL: soundFileURL settings: recordSettings error: nil];
			[recordSettings release];
			self.soundRecorder = newRecorder;
			[newRecorder release];
			
			soundRecorder.delegate = self;
			[soundRecorder setMeteringEnabled:YES];
			[soundRecorder prepareToRecord];
			
			
			BOOL audioHWAvailable = [[AVAudioSession sharedInstance] inputIsAvailable];
			if (! audioHWAvailable) {
				UIAlertView *cantRecordAlert =
				[[UIAlertView alloc] initWithTitle: @"Error"
										   message: @"No audio hardware is available on this iOS device"
										  delegate: nil
								 cancelButtonTitle: @"Ok"
								 otherButtonTitles:nil];
				[cantRecordAlert show];
				[cantRecordAlert release]; 
				return;
			}
			
			[soundRecorder record];
			
			self.meter.alpha = 1.0; 
			self.meterUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 
																	 target:self 
																   selector:@selector(updateMeter) 
																   userInfo:nil 
																	repeats:YES];
			NSLog(@"Recording.");
			mode = kAudioRecorderRecording;
			[self updateButtonsForCurrentMode];						
			break;
			
		case kAudioRecorderRecording:
			[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];	
			
			[soundRecorder stop];
			self.soundRecorder = nil;
			mode = kAudioRecorderReady;			
			[self updateButtonsForCurrentMode];
			break;	
			
		default:
			break;
	}
	
}






- (void)updateMeter {
	[self.soundRecorder updateMeters];
	float levelInDb = [self.soundRecorder averagePowerForChannel:0];
	levelInDb = levelInDb + 160;
	
	//Level will always be between 0 and 160 now
	//Usually it will sit around 100 in quiet so we need to correct
	levelInDb = MAX(levelInDb - 100,0);
	float levelInZeroToOne = levelInDb / 60;
	
	NSLog(@"AudioRecorderLevel: %f, level in float:%f",levelInDb,levelInZeroToOne);
	
	[self.meter updateLevel:levelInZeroToOne];
}





#pragma mark Audio Recorder Delegate Metods

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
	NSLog(@"audioRecorderDidFinishRecording");
	[self.meterUpdateTimer invalidate];
	[self.meter updateLevel:0];
	self.meter.alpha = 0.0; 
	
	mode = kAudioRecorderReady;
	[self updateButtonsForCurrentMode];
	
	//Lets get the trimmer onscreen
	NSLog(@"AudioRecorderViewController: Recording Complete. Display the Trimmer");
	AudioTrimmerViewController *trimmerVC = [[AudioTrimmerViewController alloc] initWithSoundFileURL:self.soundFileURL ];
	[self.navigationController pushViewController:trimmerVC animated:YES];
	
	
}



@end
