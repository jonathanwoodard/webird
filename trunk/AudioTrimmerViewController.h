//
//  AudioTrimmerViewController.h
//  WeBIRD
//
//  Created by David J Gagnon on 1/20/11.
//  Copyright 2011 University of Wisconsin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <CorePlot/CorePlot.h>


typedef enum {
	kAudioTrimmerIn,
	kAudioTrimmerOut,
	kAudioTrimmerNone,
} AudioTrimmerInOrOut;

typedef enum {
	kAudioTrimmerModeTrimming,
	kAudioTrimmerModeReady,
	kAudioTrimmerModePlaying,
} AudioTrimmerMode;

@interface AudioTrimmerViewController : UIViewController <AVAudioPlayerDelegate, CPPlotDataSource> {
	IBOutlet UIView*	trimInBar;
	IBOutlet UIView*	trimOutBar;
	IBOutlet UIButton*	deleteButton;
	IBOutlet UIButton*	playButton;
	IBOutlet UIButton*	analyzeButton;
	IBOutlet CPGraphHostingView*	graphView;
	IBOutlet UIView*	playhead;
	
	CPXYGraph *graph;
	NSMutableArray *audioAsArray;
	AudioTrimmerInOrOut selectedTrimmer;
	AudioTrimmerMode mode;
	NSURL *soundFileURL;
	NSURL *trimmedSoundFileURL;
	AVURLAsset *soundFileAsset;
	CMTime soundFileDuration;
	AVAudioPlayer *soundPlayer;
	NSTimer *updateTimer;

}

@property(readwrite, retain) NSURL *soundFileURL;
@property(readwrite, retain) NSURL *trimmedSoundFileURL;
@property(readwrite, retain) AVURLAsset *soundFileAsset;
@property(readwrite, retain) AVAudioPlayer *soundPlayer;


- (id)initWithSoundFileURL:(NSURL*)url;
- (void) updateButtonsForCurrentMode;
- (Float64)secondsForXPosition: (CGFloat)xPos;
- (CGFloat)xPositionForSeconds: (Float64)seconds;      
- (CMTimeRange)trimmedTimeRange;
- (void)moveTrimBarsToTimeRange: (CMTimeRange)range;
- (void)calculateTrimmedAudio;

- (IBAction) deleteButtonAction: (id) sender;
- (IBAction) playButtonAction: (id) sender;
- (IBAction) analyzeButtonAction: (id) sender;

@end
