//
//  AudioTrimmerViewController.m
//  WeBIRD
//
//  Created by David J Gagnon on 1/20/11.
//  Copyright 2011 University of Wisconsin. All rights reserved.
//

#import "AudioTrimmerViewController.h"
#import "AppModel.h"
#import "CorePlot-CocoaTouch.h"


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
					[self moveTrimBarsToTimeRange: CMTimeRangeMake(CMTimeMakeWithSeconds(0.0f, 600),soundFileDuration)];
					[self calculateTrimmedAudio];
					break;
				case AVKeyValueStatusFailed:
					NSLog(@"ERROR Loading Asset");
					break;
				case AVKeyValueStatusCancelled:
					// Do whatever is appropriate for cancelation.
				break;
			}
		}];
		 
		audioAsArray = [[NSMutableArray alloc]initWithCapacity:10];
    }
    return self;
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[AVAudioSession sharedInstance] setDelegate: self];
	
	[self calculateVisualization];
	playhead.alpha = 0.0;

	
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
				
				updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 
																		 target:self 
																	   selector:@selector(updatePlayhead) 
																	   userInfo:nil 
																		repeats:YES];
				
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
	
	[updateTimer invalidate];
	playhead.alpha = 0.0;
    
	mode = kAudioTrimmerModeReady;
	[self updateButtonsForCurrentMode];
	
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
	NSLog(@"AudioRecorder: Playback Error");
}




#pragma mark Core Plot Delegate
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot{
	return graphView.frame.size.width;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
	if (fieldEnum == CPTScatterPlotFieldX ) return [NSNumber numberWithUnsignedInteger:index];
	
	Float32 samplesPerPixel = [audioAsArray count] / graphView.frame.size.width;
	NSUInteger scaledIndex = floor(samplesPerPixel * index);
	return [audioAsArray objectAtIndex:scaledIndex];
}




#pragma mark Managing Touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	UITouch *touch = [touches anyObject]; //should be just one
	CGPoint touchPoint = [touch locationInView:self.view];
	
	//Was the touch within a trim bar? If so, which one?
	UIView *hitView = [self.view hitTest:touchPoint withEvent:event];
	
	if (hitView == trimInBar) {
		selectedTrimmer = kAudioTrimmerIn;
		NSLog(@"AudioTrimmerVC: Touches Began on the in bar");
	}
	else if (hitView == trimOutBar) {
		selectedTrimmer = kAudioTrimmerOut;
		NSLog(@"AudioTrimmerVC: Touches Began on the out bar");
	}
	else {
		selectedTrimmer = kAudioTrimmerNone;
		NSLog(@"AudioTrimmerVC: Touches Began, but not on a trim bar");
	}


}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event { 
	UITouch *touch = [touches anyObject]; //should be just one
	CGPoint touchPoint = [touch locationInView:self.view];

	if (selectedTrimmer == kAudioTrimmerIn && 
		touchPoint.x  + trimInBar.frame.size.width > graphView.frame.origin.x && 
		touchPoint.x + trimInBar.frame.size.width < trimOutBar.frame.origin.x) {
		CGRect newFrame = CGRectMake(touchPoint.x, trimInBar.frame.origin.y, trimInBar.frame.size.width , trimInBar.frame.size.height);
		trimInBar.frame = newFrame;
	}
	else if (selectedTrimmer == kAudioTrimmerOut && 
			 touchPoint.x < graphView.frame.origin.x + graphView.frame.size.width  && 
			 touchPoint.x > trimInBar.frame.origin.x + trimInBar.frame.size.width) {
		CGRect newFrame = CGRectMake(touchPoint.x, trimOutBar.frame.origin.y, trimOutBar.frame.size.width , trimOutBar.frame.size.height);
		trimOutBar.frame = newFrame;
	}
	
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if (selectedTrimmer == kAudioTrimmerNone) return;
	
	CMTimeRange range = [self trimmedTimeRange];

	NSLog(@"AudioTrimmerVC: Touches ended. Trim region starts at %f and is %f in duration",
		  CMTimeGetSeconds(range.start),
		  CMTimeGetSeconds(range.duration) );
	
	[self calculateTrimmedAudio];
	
}


#pragma mark Utilities


- (void)updatePlayhead {
	playhead.alpha = 1.0;
	
	//Float64 startTimeInSeconds = [self secondsForXPosition: trimInBar.frame.origin.x + trimInBar.frame.size.width];
	NSTimeInterval currentTimeInTrimRegion = soundPlayer.currentTime;

	CGFloat playheadX = [self xPositionForSeconds: currentTimeInTrimRegion] + trimInBar.frame.origin.x  - graphView.frame.origin.x;
	
	CGRect frame = CGRectMake(playheadX, playhead.frame.origin.y, playhead.frame.size.width, playhead.frame.size.height);
	playhead.frame = frame;
}

- (void)moveTrimBarsToTimeRange: (CMTimeRange)range{
	
	CGFloat inBarX = [self xPositionForSeconds: CMTimeGetSeconds(range.start)];
	CGFloat outBarX = [self xPositionForSeconds: CMTimeGetSeconds(range.duration) - CMTimeGetSeconds(range.start)];
	
	NSLog(@"AudioTrimmerVC: moveTrimBarsToTimeRange: inBarX:%f outBarX:%f",inBarX,outBarX);
	
	CGRect inFrame = CGRectMake(inBarX - trimInBar.frame.size.width, graphView.frame.origin.y, trimInBar.frame.size.width , graphView.frame.size.height);
	trimInBar.frame = inFrame;
	
	CGRect outFrame = CGRectMake(outBarX, graphView.frame.origin.y, trimOutBar.frame.size.width , graphView.frame.size.height);
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

- (void)calculateVisualization {
	NSLog(@"AudioTrimmerVC: calculateVisualization");
	AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:soundFileAsset error:nil];
	
	AVAssetReaderAudioMixOutput *output = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:soundFileAsset.tracks 
																								  audioSettings:[AppModel sharedAppModel].recordSettings];
	[reader addOutput:output];
	[reader startReading];
	
	CMSampleBufferRef ref;

	while ((ref = [output copyNextSampleBuffer])) {
		AudioBufferList audioBufferList;
		CMBlockBufferRef blockBuffer;
		CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(ref, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
		for( int y=0; y<audioBufferList.mNumberBuffers; y++ ){ //loop through the buffers that make up the sound
			AudioBuffer audioBuffer = audioBufferList.mBuffers[y]; //get a copy to the audio buffer
			int bitDepth = [[(NSDictionary*)([AppModel sharedAppModel].recordSettings) objectForKey: AVLinearPCMBitDepthKey] intValue];
			UInt32 frameCount = audioBuffer.mDataByteSize / bitDepth;  
			Float32 *frame = (Float32*)audioBuffer.mData;
			for(UInt32 i=0; i<frameCount; i++ ) {
				Float32 currentSample = frame[i];
				[audioAsArray addObject:[NSNumber numberWithFloat:currentSample]];
			}
		}
	}
				 
	NSLog(@"Adding Plot Now");

	graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    CPTTheme *theme = [CPTTheme themeNamed:kCPTSlateTheme];
    [graph applyTheme:theme];
    graphView.collapsesLayers = NO; // Setting to YES reduces GPU memory usage, but can slow drawing/scrolling
    graphView.hostedGraph = graph;

	graph.paddingLeft = 0.0;
	graph.paddingTop = 0.0;
	graph.paddingRight = 0.0;
	graph.paddingBottom = 0.0;
	
	CPTScatterPlot *plot = [[[CPTScatterPlot alloc] 
									initWithFrame:graphView.bounds] autorelease];
	plot.identifier = @"plot";
	plot.dataSource = self;
	plot.cachePrecision = CPTPlotCachePrecisionDouble;
	[graph addPlot:plot];	
	
	
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
	[plotSpace scaleToFitPlots:[[NSArray alloc] initWithObjects:plot,nil]];
 
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
								   stringByAppendingPathComponent: @"audio.m4a"];
		
		
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
	Float64 timePerPixel = CMTimeGetSeconds(soundFileDuration)/graphView.frame.size.width;
	CGFloat pixelsIn = xPos - graphView.frame.origin.x; 
	Float64 timeIn = timePerPixel * pixelsIn;
	
	return timeIn;
}

 -(CGFloat)xPositionForSeconds: (Float64)seconds {
	 Float64 timePerPixel = CMTimeGetSeconds(soundFileDuration)/graphView.frame.size.width;
	 CGFloat xPos =  seconds / timePerPixel + graphView.frame.origin.x; 
	 
	 return xPos;
 }		 
		 

@end
