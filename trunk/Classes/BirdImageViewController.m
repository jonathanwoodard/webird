//
//  BirdImageViewController.m
//  WeBIRD
//
//  Created by David J Gagnon on 8/1/11.
//  Copyright 2011 University of Wisconsin. All rights reserved.
//

#import "BirdImageViewController.h"


@implementation BirdImageViewController

@synthesize bird;


- (id)initWithBird:(Bird *)b {
	if ((self = [super initWithNibName:@"BirdImageViewController" bundle:nil])) {
		// Custom initialization
		self.bird = b;
	}
	return self;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    imageView.image = bird.image;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.title = bird.commonName;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
