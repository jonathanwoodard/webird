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
				
				/*
				 Let's take a minute to play with splicing up the clip
				*/
				NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
				AVURLAsset *asset = [AVURLAsset URLAssetWithURL:self.soundFileURL options:options];
				NSArray *keys = [NSArray arrayWithObject:@"duration"];
				/*
				[asset loadValuesAsynchronouslyForKeys:keys completionHandler:^(void) {
					NSError *error = nil;
					AVKeyValueStatus durationStatus = [asset statusOfValueForKey:@"duration" error:&error];
					switch (durationStatus) {
						case AVKeyValueStatusLoaded:
							NSLog(@"Duration Loaded: %@",[asset valueForKey:@"duration"]);
							break;
						case AVKeyValueStatusFailed:
							NSLog(@"ERROR Loading Asset");
							break;
						case AVKeyValueStatusCancelled:
							// Do whatever is appropriate for cancelation.
							break;
					}
				}];
				 */
				
				//export it to a file
				NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
				if ([compatiblePresets containsObject:AVAssetExportPresetAppleM4A]) {
					AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
														   initWithAsset:asset presetName:AVAssetExportPresetAppleM4A];

									
					NSString *soundFilePath = [NSTemporaryDirectory ()
											stringByAppendingPathComponent: @"exported.m4a"];

					
					NSURL *trimmedURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
					exportSession.outputURL = trimmedURL;
					
					NSFileManager *fileManager = [NSFileManager defaultManager];
					[fileManager removeItemAtPath:soundFilePath error:NULL];
					
					
					
					exportSession.outputFileType = @"com.apple.m4a-audio";
					CMTime start = CMTimeMakeWithSeconds(1.0, 600);
					CMTime duration = CMTimeMakeWithSeconds(1.0, 600);
					CMTimeRange range = CMTimeRangeMake(start, duration);
					exportSession.timeRange = range;
					
					[exportSession exportAsynchronouslyWithCompletionHandler:^{
						NSLog(@"Session Export complete!");
						switch ([exportSession status]) {
							case AVAssetExportSessionStatusFailed:
								NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
								break;
							case AVAssetExportSessionStatusCancelled:
								NSLog(@"Export canceled");
								break;
							default:
								NSLog(@"Export Was Ok");
								
								AVAudioPlayer *newPlayer =[[AVAudioPlayer alloc] initWithContentsOfURL:trimmedURL error: nil];
								self.soundPlayer = newPlayer;
								[newPlayer release];
								[self.soundPlayer setDelegate: self];
								mode = kAudioRecorderPlaying;
								[self updateButtonsForCurrentMode];
								[self.soundPlayer prepareToPlay];
								[self.soundPlayer play];
								break;
						}
						[exportSession release];
					}];
					
					
				}
				

			}	
			

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
	
	//Lets get the trimmer onscreen
	NSLog(@"AudioRecorderViewController: Recording Complete. Display the Trimmer");
	AudioTrimmerViewController *trimmerVC = [[AudioTrimmerViewController alloc] initWithNibName:@"AudioTrimmerViewController" bundle:nil];
	[self.navigationController pushViewController:trimmerVC animated:YES];
	
	
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
