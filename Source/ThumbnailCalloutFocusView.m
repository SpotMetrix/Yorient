//
//  ThumbnailCalloutFocusView.m
//  Yorient
//
//  Created by P. Mark Anderson on 8/16/11.
//  Copyright 2011 Spot Metrix, Inc. All rights reserved.
//

#import "ThumbnailCalloutFocusView.h"


@implementation ThumbnailCalloutFocusView


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
    [focusCalloutView pointDidGainFocus:point];  // IMPORTANT
}

- (void) pointDidLoseFocus:(SM3DARPoint *)point
{
    [focusCalloutView pointDidLoseFocus:point];  // IMPORTANT

    focusCalloutView.titleLabel.text = nil;
    focusCalloutView.subtitleLabel.text = nil;
    focusCalloutView.distanceLabel.text = nil;
    [focusThumbView setImage:nil];
}

- (void) setCalloutDelegate:(id<SM3DARCalloutViewDelegate>)calloutDelegate
{
    focusCalloutView.delegate = calloutDelegate;
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
    NSLog(@"Focus view touched");
    [self.nextResponder touchesBegan:touches withEvent:event];
}


@end
