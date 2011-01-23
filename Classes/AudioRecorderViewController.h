//
//  AudioRecorderViewController.h
//  ARIS
//
//  Created by David J Gagnon on 4/6/10.
//  Copyright 2010 University of Wisconsin - Madison. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

#import "AudioMeter.h"

typedef enum {
	kAudioRecorderReady,
	kAudioRecorderRecording,
} AudioRecorderModeType;


@interface AudioRecorderViewController : UIViewController <AVAudioSessionDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate> {
	
	AudioMeter *meter;
	AVAudioRecorder *soundRecorder;
	AVAudioPlayer *soundPlayer;
	NSURL *soundFileURL;
	NSData *audioData;
	IBOutlet UIButton *recordStopOrPlayButton;
	IBOutlet UIButton *uploadButton;
	IBOutlet UIButton *discardButton;
	AudioRecorderModeType mode;
	BOOL recording;
	BOOL playing;
	NSTimer *meterUpdateTimer;
	
}

@property(readwrite, retain) AudioMeter *meter;
@property(readwrite, retain) NSURL *soundFileURL;
@property(readwrite, retain) NSData *audioData;
@property(readwrite, retain) AVAudioRecorder *soundRecorder;
@property(readwrite, retain) AVAudioPlayer *soundPlayer;
@property(readwrite, retain) NSTimer *meterUpdateTimer;


- (IBAction) recordStopOrPlayButtonAction: (id) sender;
- (IBAction) uploadButtonAction: (id) sender;
- (IBAction) discardButtonAction: (id) sender;
- (void) updateButtonsForCurrentMode;



@end

