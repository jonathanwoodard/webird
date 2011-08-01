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
#import "CorePlot-CocoaTouch.h"

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

@interface AudioTrimmerViewController : UIViewController <AVAudioPlayerDelegate, CPTPlotDataSource> {
	IBOutlet UIView*	trimInBar;
	IBOutlet UIView*	trimOutBar;
	IBOutlet UIButton*	deleteButton;
	IBOutlet UIButton*	playButton;
	IBOutlet UIButton*	analyzeButton;
	IBOutlet CPTGraphHostingView*	graphView;
	IBOutlet UIView*	playhead;
	
	CPTXYGraph *graph;
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

@property(nonatomic, retain) NSURL *soundFileURL;
@property(nonatomic, retain) NSURL *trimmedSoundFileURL;
@property(nonatomic, retain) AVURLAsset *soundFileAsset;
@property(nonatomic, retain) AVAudioPlayer *soundPlayer;


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
