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

		
		//Start Calculating the Duration
		NSArray *keys = [NSArray arrayWithObject:@"duration"];
		[self.soundFileAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^(void) {
			NSError *error = nil;
			AVKeyValueStatus durationStatus = [self.soundFileAsset statusOfValueForKey:@"duration" error:&error];
			switch (durationStatus) {
				case AVKeyValueStatusLoaded:
					soundFileDuration = [self.soundFileAsset duration];
					NSLog(@"Duration Loaded: %f Seconds", CMTimeGetSeconds(soundFileDuration));
					[self calculateTrimmedAudio];
					[self moveTrimBarsToTimeRange: CMTimeRangeMake(CMTimeMakeWithSeconds(0.0f, 600),soundFileDuration)];
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
	
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return YES;
}

- (void)willAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
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


#pragma mark Button Actions


- (IBAction) playButtonAction: (id)sender{
	switch (mode) {

		case kAudioTrimmerModePlaying:
			[self.soundPlayer stop];
			mode = kAudioTrimmerModeReady;
			[self updateButtonsForCurrentMode];
			break;	
			
		case kAudioTrimmerModeReady:
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
	NSData *audioData = [NSData dataWithContentsOfURL:trimmedSoundFileURL];
	[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryAmbient error: nil];	
	[[AppModel sharedAppModel] uploadFile:audioData];
}	

- (IBAction) deleteButtonAction: (id) sender{
	
	[self.navigationController popViewControllerAnimated:YES]; 
}


#pragma mark AVAudioPlayer Delegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
	NSLog(@"audioPlayerDidFinishPlaying");
	
	soundPlayer = nil;
	
	mode = kAudioTrimmerModeReady;
	[self updateButtonsForCurrentMode];
	
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
	NSLog(@"AudioRecorder: Playback Error");
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
	CMTimeRange range = [self trimmedTimeRange];

	NSLog(@"AudioTrimmerVC: Touches ended. Trim region starts at %f and is %f in duration",
		  CMTimeGetSeconds(range.start),
		  CMTimeGetSeconds(range.duration) );
	
	[self calculateTrimmedAudio];
	
}


#pragma mark Utilities

- (void)moveTrimBarsToTimeRange: (CMTimeRange)range{
	
	CGFloat inBarX = [self xPositionForSeconds: CMTimeGetSeconds(range.start)];
	CGFloat outBarX = [self xPositionForSeconds: CMTimeGetSeconds(range.duration) - CMTimeGetSeconds(range.start)];
	
	NSLog(@"AudioTrimmerVC: moveTrimBarsToTimeRange: inBarX:%f outBarX:%f",inBarX,outBarX);
	
	CGRect inFrame = CGRectMake(inBarX - trimInBar.frame.size.width, spectrogramView.frame.origin.y, trimInBar.frame.size.width , spectrogramView.frame.size.height);
	trimInBar.frame = inFrame;
	
	CGRect outFrame = CGRectMake(outBarX, spectrogramView.frame.origin.y, trimOutBar.frame.size.width , spectrogramView.frame.size.height);
	trimOutBar.frame = outFrame;
	
}
- (void)updateButtonsForCurrentMode{
	
	switch (mode) {
		case kAudioTrimmerModeReady:
			NSLog(@"Setting title to play");
			playButton.enabled = YES;
			analyzeButton.enabled = YES;
			playButton.alpha = 1.0f;
			analyzeButton.alpha = 1.0f;
			[playButton setTitle: @"Play" forState: UIControlStateNormal];
			break;
		case kAudioTrimmerModePlaying:
			playButton.enabled = YES;
			analyzeButton.enabled = YES;
			playButton.alpha = 0.8f;
			analyzeButton.alpha = 0.8f;
			[playButton setTitle: @"Stop" forState: UIControlStateNormal];
			break;
		case kAudioTrimmerModeTrimming:
			NSLog(@"Setting title to preparing");
			playButton.enabled = NO;
			analyzeButton.enabled = NO;
			playButton.alpha = 0.8f;
			analyzeButton.alpha = 0.8f;
			[playButton setTitle: @"Preparing" forState: UIControlStateNormal];
			break;	
		default:
			break;
	}
	
	[playButton setNeedsDisplay];
}

- (void)calculateTrimmedAudio{
	
	NSLog(@"AudioTrimmerVC: calculateTrimmedAudio");
	mode = kAudioTrimmerModeTrimming;
	[self updateButtonsForCurrentMode];
	
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
		
		exportSession.timeRange = [self trimmedTimeRange];
		
		[exportSession exportAsynchronouslyWithCompletionHandler:^{
			switch ([exportSession status]) {
				case AVAssetExportSessionStatusFailed:
					NSLog(@"AudioTrimmerVC: Calculating Trim Failed: %@", [[exportSession error] localizedDescription]);
					break;
				case AVAssetExportSessionStatusCancelled:
					NSLog(@"AudioTrimmerVC: Calculating Trim Canceled");
					break;
				default:
					NSLog(@"AudioTrimmerVC: Calculating Trim Complete");
					mode = kAudioTrimmerModeReady;
					[self updateButtonsForCurrentMode];
					break;
			}
			[exportSession release];
		}];
		
		self.trimmedSoundFileURL = trimmedURL;
	}
	
}


-(CMTimeRange)trimmedTimeRange {
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

 -(CGFloat)xPositionForSeconds: (Float64)seconds {
	 Float64 timePerPixel = CMTimeGetSeconds(soundFileDuration)/spectrogramView.frame.size.width;
	 NSLog(@"AudioTrimmerVC: xPositionForSeconds: timePerPixel is %f",timePerPixel);
	 
	 //how many pixels into the spectrogram + spectrogram origin?
	 CGFloat xPos =  seconds / timePerPixel + spectrogramView.frame.origin.x; 
	 NSLog(@"AudioTrimmerVC: PositionForSeconds: This is %f pixels into the view", xPos);
	 
	 return xPos;
 }		 
		 

@end
