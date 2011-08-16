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
    focusCalloutView.titleLabel.text = point.title;
    
    if ([point respondsToSelector:@selector(subtitle)])
    {
        focusCalloutView.subtitleLabel.text = [point performSelector:@selector(subtitle)];
    }
    
    if ([point isKindOfClass:[SM3DARPointOfInterest class]])
    {
        SM3DARPointOfInterest *poi = (SM3DARPointOfInterest *)point;        
        focusCalloutView.distanceLabel.text = [poi formattedDistanceFromCurrentLocationWithUnits];
        
                
        // Use the point properties to determine thumbnail image.
        
        //NSLog(@"----- %@", poi.properties);
        //[focusThumbView setImage:nil];
    }
    
}

- (void) pointDidLoseFocus:(SM3DARPoint *)point
{
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
}


@end
