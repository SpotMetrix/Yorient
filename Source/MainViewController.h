//
//  MainViewController.h
//  Yorient
//
//  Created by P. Mark Anderson on 11/10/09.
//  Copyright Spot Metrix, Inc 2009. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "SM3DAR.h" 
#import "AudioToolbox/AudioServices.h"
#import "ILGeoNamesSearchController.h"
#import <MapKit/MapKit.h>
#import "BirdseyeView.h"
#import "ThumbnailCalloutFocusView.h"

@interface MainViewController : UIViewController <MKMapViewDelegate, SM3DARDelegate, CLLocationManagerDelegate, SM3DARCalloutViewDelegate, ILGeoNamesLookupDelegate>
{}

@property (nonatomic, retain) NSString *searchQuery;
@property (nonatomic, retain) ILGeoNamesLookup *search;
@property (nonatomic, retain) IBOutlet SM3DARMapView *mapView;
@property (nonatomic, retain) IBOutlet UIView *hudView;
@property (nonatomic, retain) BirdseyeView *birdseyeView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, retain) IBOutlet UIButton *toggleMapButton;
@property (nonatomic, retain) IBOutlet UIButton *refreshButton;

- (void)initSound;
- (void)playFocusSound;
//- (void)addDirectionBillboardsWithFixtures;
- (IBAction)refreshButtonTapped;
- (IBAction)toggleMapButtonTapped:(UIButton *)sender;
- (void)addNorthStar;
- (void)loadPoints;

@end
