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

typedef enum {
	kAudioTrimmerIn,
	kAudioTrimmerOut
} AudioTrimmerInOrOut;

typedef enum {
	kAudioTrimmerModeReadyToPlay,
	kAudioTrimmerModePlaying,
} AudioTrimmerMode;

@interface AudioTrimmerViewController : UIViewController {
	IBOutlet UIView*	trimInBar;
	IBOutlet UIView*	trimOutBar;
	IBOutlet UIButton*	deleteButton;
	IBOutlet UIButton*	playButton;
	IBOutlet UIButton*	analyzeButton;
	IBOutlet UIView*	spectrogramView;
	
	AudioTrimmerInOrOut selectedTrimmer;
	AudioTrimmerMode mode;
	
	NSURL *soundFileURL;
	AVURLAsset *soundFileAsset;
	CMTime soundFileDuration;


	NSURL *trimmedSoundFileURL;
	
	AVAudioPlayer *soundPlayer;
}

@property(readwrite, retain) NSURL *soundFileURL;
@property(readwrite, retain) NSURL *trimmedSoundFileURL;
@property(readwrite, retain) AVURLAsset *soundFileAsset;
@property(readwrite, retain) AVAudioPlayer *soundPlayer;


- (id)initWithSoundFileURL:(NSURL*)url;
- (void) updateButtonsForCurrentMode;
- (Float64)secondsForXPosition: (CGFloat)xPos;
- (CMTimeRange)trimedTimeRange;


- (IBAction) deleteButtonAction: (id) sender;
- (IBAction) playButtonAction: (id) sender;
- (IBAction) analyzeButtonAction: (id) sender;

@end