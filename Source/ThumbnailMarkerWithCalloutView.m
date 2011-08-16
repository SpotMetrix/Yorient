//
//  ThumbnailMarkerWithCalloutView.m
//

#import "ThumbnailMarkerWithCalloutView.h"

@implementation ThumbnailMarkerWithCalloutView

- (id)initWithPointOfInterest:(SM3DARPointOfInterest*)pointOfInterest imageName:(NSString *)imageName
{    
	if (self = [super initWithPointOfInterest:pointOfInterest imageName:imageName]) 
    {
        SM3DARDetailCalloutView *calloutView = [[SM3DARDetailCalloutView alloc] initWithFrame:CGRectZero];
        calloutView.titleLabel.text = pointOfInterest.title;
        calloutView.subtitleLabel.text = pointOfInterest.subtitle;
        
        [self addSubview:calloutView]; 
	}
    
	return self;
}



@end
