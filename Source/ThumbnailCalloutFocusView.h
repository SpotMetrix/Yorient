//
//  ThumbnailCalloutFocusView.h
//  Yorient
//
//  Created by P. Mark Anderson on 8/16/11.
//  Copyright 2011 Spot Metrix, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SM3DAR.h"

@interface ThumbnailCalloutFocusView : SM3DARFocusView
{
    IBOutlet UIImageView *focusThumbView;
    IBOutlet SM3DARDetailCalloutView *focusCalloutView;
}

- (void) setCalloutDelegate:(id<SM3DARCalloutViewDelegate>)calloutDelegate;

@end
