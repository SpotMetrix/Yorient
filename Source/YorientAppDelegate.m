//
//  YorientAppDelegate.m
//  Yorient
//
//  Created by P. Mark Anderson on 11/10/09.
//  Copyright Spot Metrix, Inc 2009. All rights reserved.
//

#import "YorientAppDelegate.h"
#import "MainViewController.h"

@implementation YorientAppDelegate


@synthesize window;
@synthesize mainViewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application 
{
	[application setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    [application setStatusBarHidden:YES animated:NO];
	
    [SM3DARMapView class];
    
	MainViewController *aController = [[MainViewController alloc] initWithNibName:@"MainView" bundle:nil];
	self.mainViewController = aController;
	[aController release];
	
	mainViewController.view.frame = [UIScreen mainScreen].applicationFrame;
	[window addSubview:[mainViewController view]];
	[window makeKeyAndVisible];
}


- (void)dealloc {
	[mainViewController release];
	[window release];
	[super dealloc];
}

@end
