//
//  BirdImageViewController.h
//  WeBIRD
//
//  Created by David J Gagnon on 8/1/11.
//  Copyright 2011 University of Wisconsin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Bird.h"

@interface BirdImageViewController : UIViewController {
    Bird *bird;
    IBOutlet UIImageView *imageView;
}

@property (nonatomic,retain) Bird *bird;

- (id)initWithBird:(Bird *)b;

@end
