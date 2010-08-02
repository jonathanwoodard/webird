//
//  AudioRecorderViewController.m
//  ARIS
//
//  Created by David J Gagnon on 4/6/10.
//  Copyright 2010 University of Wisconsin - Madison. All rights reserved.
//

#import "AudioRecorderViewController.h"
#import "AppModel.h";


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
			
    }
    return self;
}


/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
 }
 */



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	meter = [[AudioMeter alloc]initWithFrame:CGRectMake(0, 0, 320, 420)];
	meter.alpha = 0.0;
	[self.view addSubview:meter];
	[self.view sendSubviewToBack:meter];
	

	NSString *tempDir = NSTemporaryDirectory ();
    NSString *soundFilePath =[tempDir stringByAppendingString: @"sound.caf"];
	
    NSURL *newURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
    self.soundFileURL = newURL;
    [newURL release];
	
	[[AVAudioSession sharedInstance] setDelegate: self];
	
	mode = kAudioRecorderStarting; 
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
	[uploadButton setTitle: @"Upload" forState: UIControlStateNormal];
	[discardButton setTitle: @"Delete" forState: UIControlStateNormal];
	
	switch (mode) {
		case kAudioRecorderStarting:
			[recordStopOrPlayButton setTitle: @"Begin Recording" forState: UIControlStateNormal];
			uploadButton.hidden = YES;
			discardButton.hidden = YES;
			break;
		case kAudioRecorderRecording:
			[recordStopOrPlayButton setTitle: @"Stop Recording" forState: UIControlStateNormal];
			uploadButton.hidden = YES;
			discardButton.hidden = YES;
			break;
		case kAudioRecorderRecordingComplete:
			[recordStopOrPlayButton setTitle: @"Play" forState: UIControlStateNormal];
			uploadButton.hidden = NO;
			discardButton.hidden = NO;
			break;
		case kAudioRecorderPlaying:
			[recordStopOrPlayButton setTitle: @"Stop" forState: UIControlStateNormal];
			uploadButton.hidden = YES;
			discardButton.hidden = YES;
			break;
		default:
			break;
	}
}

- (IBAction) recordStopOrPlayButtonAction: (id) sender{
	
	NSLog(@"AudioRecorder: Record/Play/Stop Button selected");
	
	switch (mode) {
		case kAudioRecorderStarting:
			NSLog(@"AudioRecorder: Record/Play/Stop Button selected");
			
			[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryRecord error: nil];	
			
			NSDictionary *recordSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
											[NSNumber numberWithInt:kAudioFormatAppleIMA4],AVFormatIDKey,
											[NSNumber numberWithInt:16000.0],AVSampleRateKey,
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
			
		case kAudioRecorderPlaying:
			[self.soundPlayer stop];
			mode = kAudioRecorderRecordingComplete;
			[self updateButtonsForCurrentMode];
			break;	
			
		case kAudioRecorderRecordingComplete:
			[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];	
			
			[[AVAudioSession sharedInstance] setActive: YES error: nil];
			
			if (nil == self.soundPlayer) {
				NSError *error;
				AVAudioPlayer *newPlayer =[[AVAudioPlayer alloc] initWithContentsOfURL:self.soundFileURL error: &error];
				self.soundPlayer = newPlayer;
				[newPlayer release];
				[self.soundPlayer prepareToPlay];
				[self.soundPlayer setDelegate: self];
			}	
			
			mode = kAudioRecorderPlaying;
			[self updateButtonsForCurrentMode];
			
			[self.soundPlayer play];
			break;
			
		case kAudioRecorderRecording:
			[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];	
			
			[soundRecorder stop];
			self.soundRecorder = nil;
			mode = kAudioRecorderRecordingComplete;			
			[self updateButtonsForCurrentMode];
			break;	
			
		default:
			break;
	}
	
}


- (IBAction) uploadButtonAction: (id) sender{
	self.audioData = [NSData dataWithContentsOfURL:soundFileURL];
	self.soundRecorder = nil;
	[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryAmbient error: nil];
	
	[[AppModel sharedAppModel] uploadFile:audioData];

}	



- (IBAction) discardButtonAction: (id) sender{
	soundPlayer = nil;
	mode = kAudioRecorderStarting;
	[self updateButtonsForCurrentMode];
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
	
	mode = kAudioRecorderRecordingComplete;
	[self updateButtonsForCurrentMode];
	
	
}

#pragma mark Audio Player Delegate Methods

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
	NSLog(@"audioPlayerDidFinishPlaying");
	
	soundPlayer = nil;
	
	mode = kAudioRecorderRecordingComplete;
	[self updateButtonsForCurrentMode];
	
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
	NSLog(@"AudioRecorder: Playback Error");
}


@end
