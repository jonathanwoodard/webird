//
//  AudioTrimmerViewController.h
//  WeBIRD
//
//  Created by David J Gagnon on 1/20/11.
//  Copyright 2011 University of Wisconsin. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AudioTrimmerViewController : UIViewController {
	IBOutlet UIView*	trimInBar;
	IBOutlet UIView*	trimOutBar;
	IBOutlet UIButton*	deleteButton;
	IBOutlet UIButton*	playButton;
	IBOutlet UIButton*	analyzeButton;
}

- (IBAction) deleteButtonAction: (id) sender;
- (IBAction) playButtonAction: (id) sender;
- (IBAction) analyzeButtonAction: (id) sender;

@end
