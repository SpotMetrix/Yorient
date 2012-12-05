//
//  ThumbnailCalloutFocusView.m
//  Yorient
//
//  Created by P. Mark Anderson on 8/16/11.
//  Copyright 2011 Spot Metrix, Inc. All rights reserved.
//

#import "ThumbnailCalloutFocusView.h"


@implementation ThumbnailCalloutFocusView

@synthesize focusCalloutView = _focusCalloutView;
@synthesize focusThumbView = _focusThumbView;

- (void) dealloc
{
    [focusThumbView release];
    focusThumbView = nil;
    
    [focusCalloutView release];
    focusCalloutView = nil;

    [super dealloc];
}

- (void) pointDidGainFocus:(SM3DARPoint *)point
{
    [self.focusCalloutView pointDidGainFocus:point];  // IMPORTANT
}

- (void) pointDidLoseFocus:(SM3DARPoint *)point
{
    [self.focusCalloutView pointDidLoseFocus:point];  // IMPORTANT

    self.focusCalloutView.titleLabel.text = nil;
    self.focusCalloutView.subtitleLabel.text = nil;
    self.focusCalloutView.distanceLabel.text = nil;
    [self.focusThumbView setImage:nil];
}

- (void) setCalloutDelegate:(id<SM3DARCalloutViewDelegate>)calloutDelegate
{
    self.focusCalloutView.delegate = calloutDelegate;
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
    NSLog(@"Focus view touched");
    [self.nextResponder touchesBegan:touches withEvent:event];
}


@end
