//
//  AudioTrimmerViewController.m
//  WeBIRD
//
//  Created by David J Gagnon on 1/20/11.
//  Copyright 2011 University of Wisconsin. All rights reserved.
//

#import "AudioTrimmerViewController.h"
#import "AppModel.h"

@implementation AudioTrimmerViewController

@synthesize soundFileURL;
@synthesize trimmedSoundFileURL;
@synthesize soundPlayer;
@synthesize soundFileAsset;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.

- (id)initWithSoundFileURL:(NSURL*)url {
    self = [super initWithNibName:@"AudioTrimmerViewController" bundle:nil];
    if (self) {
        NSLog(@"AudioTrimmerVC: initWithNib");
		self.title = @"Trimmer";
		self.soundFileURL = url;
		
		//Set up the sound as an asset
		NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
		self.soundFileAsset = [AVURLAsset URLAssetWithURL:self.soundFileURL options:options];

		//Sgtart Calculating the Duration
		NSArray *keys = [NSArray arrayWithObject:@"duration"];
		[self.soundFileAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^(void) {
			NSError *error = nil;
			AVKeyValueStatus durationStatus = [self.soundFileAsset statusOfValueForKey:@"duration" error:&error];
			switch (durationStatus) {
				case AVKeyValueStatusLoaded:
					soundFileDuration = [self.soundFileAsset duration];
					NSLog(@"Duration Loaded: %f Seconds", CMTimeGetSeconds(soundFileDuration));
					break;
				case AVKeyValueStatusFailed:
					NSLog(@"ERROR Loading Asset");
					break;
				case AVKeyValueStatusCancelled:
					// Do whatever is appropriate for cancelation.
				break;
			}
		}];
		 
    }
    return self;
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[AVAudioSession sharedInstance] setDelegate: self];
	
	mode = kAudioTrimmerModeReadyToPlay; 
	[self updateButtonsForCurrentMode];
	
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


- (IBAction) playButtonAction: (id)sender{
	switch (mode) {

		case kAudioTrimmerModePlaying:
			[self.soundPlayer stop];
			mode = kAudioTrimmerModeReadyToPlay;
			[self updateButtonsForCurrentMode];
			break;	
			
		case kAudioTrimmerModeReadyToPlay:
			[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];	
			
			[[AVAudioSession sharedInstance] setActive: YES error: nil];
			
			if (nil == self.soundPlayer) {
				NSError *error;
				AVAudioPlayer *newPlayer =[[AVAudioPlayer alloc] initWithContentsOfURL:self.trimmedSoundFileURL error: &error];
				self.soundPlayer = newPlayer;
				[newPlayer release];
				[self.soundPlayer setDelegate: self];
				mode = kAudioTrimmerModePlaying;
				[self updateButtonsForCurrentMode];
				[self.soundPlayer prepareToPlay];
				[self.soundPlayer play];		
			}
			break;
	}
}

- (IBAction) analyzeButtonAction: (id) sender{
	NSData *audioData = [NSData dataWithContentsOfURL:soundFileURL];
	[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryAmbient error: nil];	
	[[AppModel sharedAppModel] uploadFile:audioData];
}	



- (IBAction) deleteButtonAction: (id) sender{
	soundPlayer = nil;
	mode = kAudioTrimmerModeReadyToPlay;
	[self updateButtonsForCurrentMode];
	
	[self.navigationController popViewControllerAnimated:YES]; 
}


#pragma mark Audio Player Delegate Methods

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
	NSLog(@"audioPlayerDidFinishPlaying");
	
	soundPlayer = nil;
	
	mode = kAudioTrimmerModeReadyToPlay;
	[self updateButtonsForCurrentMode];
	
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
	NSLog(@"AudioRecorder: Playback Error");
}


- (void)calculateTrimmedAudio{

	NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:self.soundFileAsset];
	if ([compatiblePresets containsObject:AVAssetExportPresetAppleM4A]) {
		AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
											   initWithAsset:self.soundFileAsset presetName:AVAssetExportPresetAppleM4A];
		
		
		NSString *soundFilePath = [NSTemporaryDirectory ()
								   stringByAppendingPathComponent: @"exported.m4a"];
		
		
		NSURL *trimmedURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
		exportSession.outputURL = trimmedURL;
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		[fileManager removeItemAtPath:soundFilePath error:NULL];
		
		exportSession.outputFileType = @"com.apple.m4a-audio";

		exportSession.timeRange = [self trimedTimeRange];
		
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
					
					//All Done!
					
					break;
			}
			[exportSession release];
		}];
		
		self.trimmedSoundFileURL = trimmedURL;
		
		
	}
	 
}

- (void)updateButtonsForCurrentMode{
	
	switch (mode) {
		case kAudioTrimmerModeReadyToPlay:
			[playButton setTitle: @"Play" forState: UIControlStateNormal];
			break;
		case kAudioTrimmerModePlaying:
			[playButton setTitle: @"Stop" forState: UIControlStateNormal];
			break;
		default:
			break;
	}
}



#pragma mark Managing Touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject]; //should be just one
	CGPoint touchPoint = [touch locationInView:self.view];
	
	//Was the touch within a trim bar? If so, which one?
	UIView *hitView = [self.view hitTest:touchPoint withEvent:event];
	
	if (hitView == trimInBar) selectedTrimmer = kAudioTrimmerIn;
	else if (hitView == trimOutBar) selectedTrimmer = kAudioTrimmerOut;

}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event { 
	UITouch *touch = [touches anyObject]; //should be just one
	CGPoint touchPoint = [touch locationInView:self.view];
	
	NSLog(@"AudioTrimmer: Touch recieved in one of the trim bars. xPos = %f",touchPoint.x);


	if (selectedTrimmer == kAudioTrimmerIn && 
		touchPoint.x  + trimInBar.frame.size.width > spectrogramView.frame.origin.x && 
		touchPoint.x + trimInBar.frame.size.width < trimOutBar.frame.origin.x) {
		CGRect newFrame = CGRectMake(touchPoint.x, trimInBar.frame.origin.y, trimInBar.frame.size.width , trimInBar.frame.size.height);
		trimInBar.frame = newFrame;
	}
	else if (selectedTrimmer == kAudioTrimmerOut && 
			 touchPoint.x < spectrogramView.frame.origin.x + spectrogramView.frame.size.width  && 
			 touchPoint.x > trimInBar.frame.origin.x + trimInBar.frame.size.width) {
		CGRect newFrame = CGRectMake(touchPoint.x, trimOutBar.frame.origin.y, trimOutBar.frame.size.width , trimOutBar.frame.size.height);
		trimOutBar.frame = newFrame;
	}
	
	[self secondsForXPosition:touchPoint.x];

}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	CMTimeRange range = [self trimedTimeRange];

	NSLog(@"AudioTrimmerVC: Touches ended. Trim region starts at %f and is %f in duration",
		  CMTimeGetSeconds(range.start),
		  CMTimeGetSeconds(range.duration) );
	
	[self calculateTrimmedAudio];
	
}

-(CMTimeRange)trimedTimeRange {
	Float64 startTimeInSeconds = [self secondsForXPosition: trimInBar.frame.origin.x + trimInBar.frame.size.width];
	Float64 endTimeInSeconds = [self secondsForXPosition:trimOutBar.frame.origin.x];
	Float64 durationInSeconds = endTimeInSeconds - startTimeInSeconds;
	
	CMTime start = CMTimeMakeWithSeconds(startTimeInSeconds, 600);
	CMTime duration = CMTimeMakeWithSeconds(durationInSeconds, 600);
	return CMTimeRangeMake(start, duration);
	
}

-(Float64)secondsForXPosition: (CGFloat)xPos {
	Float64 timePerPixel = CMTimeGetSeconds(soundFileDuration)/spectrogramView.frame.size.width;
	NSLog(@"AudioTrimmerVC: timeForPosition: timePerPixel is %f",timePerPixel);
	
	//how many pixels into the spectrogram?
	CGFloat pixelsIn = xPos - spectrogramView.frame.origin.x; 
	NSLog(@"AudioTrimmerVC: timeForPosition: This is %f pixels into the spectrogram", pixelsIn);
	
	//time within sound
	Float64 timeIn = timePerPixel * pixelsIn;
	NSLog(@"AudioTrimmerVC: timeForPosition: This is %f seconds into the spectrogram", timeIn);
	
	return timeIn;
}


@end
