//
//  MainViewController.m
//  Yorient
//
//  Created by P. Mark Anderson on 11/10/09.
//  Copyright Spot Metrix, Inc 2009. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "MainViewController.h"
#import "Constants.h"


#define IDEAL_LOCATION_ACCURACY 40.0


@interface MainViewController ()
{
	SystemSoundID focusSound;
    BOOL sm3darInitialized;
    BOOL acceptableLocationAccuracyAchieved;
    CLLocationAccuracy desiredLocationAccuracy;
    NSInteger desiredLocationAccuracyAttempts;
}

@property (nonatomic, retain) SM3DARMorphingCalloutView *calloutView;
@property (nonatomic, retain) SM3DARPointOfInterest *northStar;

@end



@implementation MainViewController

// Public properties
@synthesize searchQuery = _searchQuery;
@synthesize search = _search;
@synthesize mapView = _mapView;
@synthesize birdseyeView = _birdseyeView;
@synthesize spinner = _spinner;
@synthesize toggleMapButton = _toggleMapButton;

// Private properties
@synthesize calloutView = _calloutView;
@synthesize northStar = _northStar;


- (void)dealloc 
{
	self.searchQuery = nil;
    self.search = nil;
    self.mapView = nil;
    self.hudView = nil;
    self.birdseyeView = nil;
    self.spinner = nil;
    self.toggleMapButton = nil;
    
    self.northStar = nil;
    self.calloutView = nil;
    
    [_refreshButton release];
	[super dealloc];
}

- (void) reduceDesiredLocationAccuracy:(NSTimer*)timer
{
    NSLog(@"Current location accuracy: %.0f", self.mapView.sm3dar.userLocation.horizontalAccuracy);

    if (desiredLocationAccuracyAttempts > 8 || self.mapView.sm3dar.userLocation.horizontalAccuracy <= desiredLocationAccuracy)
    {
        NSLog(@"Acceptable location accuracy achieved.");
        acceptableLocationAccuracyAchieved = YES;
        [timer invalidate];
        timer = nil;
        [self.mapView.sm3dar.locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
        [self loadPoints];
    }
    else
    {
        desiredLocationAccuracy *= 1.5;
        NSLog(@"Setting desired location accuracy to %.0f", desiredLocationAccuracy);
        [self.mapView.sm3dar.locationManager setDesiredAccuracy:desiredLocationAccuracy];
        desiredLocationAccuracyAttempts++;
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) 
    {      
        desiredLocationAccuracy = IDEAL_LOCATION_ACCURACY / 2.0;
    }
    
    return self;
}

- (void) lookBusy
{
    [self.spinner startAnimating];
        
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform"];
    CATransform3D xfm = CATransform3DMakeRotation(M_PI, 0, 0, 1.0);
    
    anim.repeatCount = INT_MAX;
    anim.duration = 5.0;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]; 
    anim.toValue = [NSValue valueWithCATransform3D:xfm];
    anim.cumulative = YES;
    anim.additive = YES;
    anim.fillMode = kCAFillModeForwards;
    anim.removedOnCompletion = NO;
    anim.autoreverses = NO;
    
    [[self.spinner layer] addAnimation:anim forKey:@"flip"];

}

- (void) repositionControls
{
    CGPoint p = self.refreshButton.center;
    p.y = self.mapView.sm3dar.iconLogo.center.y;
    self.refreshButton.center = p;
    
    p = self.toggleMapButton.center;
    p.y = self.mapView.sm3dar.iconLogo.center.y;
    self.toggleMapButton.center = p;
}

- (void) relax
{
    [self.spinner stopAnimating];
    [[self.spinner layer] removeAnimationForKey:@"flip"];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];
    
    self.toggleMapButton.hidden = [((NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"3darMapMode"]) isEqualToString:@"auto"];
    
    [self.mapView.sm3dar startCamera];
    [self make3darFullscreen];
    [self repositionControls];
}

- (void) viewDidLoad 
{
	[super viewDidLoad];
    
    self.calloutView = nil;
    
    [self initSound];
    self.view.backgroundColor = [UIColor blackColor];
    
    if (self.hudView)
    {
        self.mapView.hudView = self.hudView;
        self.hudView.hidden = YES;  // The HUD will appear when the map disappears.
    }


    [self addBirdseyeView];
    
//    [focusView setCalloutDelegate:self.mapView];
//    focusView.focusCalloutView.frame = CGRectMake(0, 180, 300, 66);
//    self.mapView.sm3dar.focusView = focusView;
    self.mapView.sm3dar.focusView = nil;
//    self.hudView = nil;

//    [self lookBusy];
    [self.view bringSubviewToFront:self.hudView];
    [self.view bringSubviewToFront:self.spinner];
    
//    [self.view setFrame:[UIScreen mainScreen].bounds];
}

- (void)runLocalSearch:(NSString*)query 
{
    self.searchQuery = query;
    [self lookBusy];
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    
    BOOL locationAvailable = (self.mapView.sm3dar.locationManager && self.mapView.sm3dar.locationManager.location);

    if (locationAvailable)
    {
        
        self.search.location = self.mapView.sm3dar.userLocation;
        [self.search execute:self.searchQuery];
    }
    else
    {
        // Load a dummy data.
        
        NSMutableArray *points = [NSMutableArray array];
        CLLocationDegrees latitude = self.mapView.sm3dar.userLocation.coordinate.latitude + 0.001;
        CLLocationDegrees longitude = self.mapView.sm3dar.userLocation.coordinate.longitude;

        CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        SM3DARPointOfInterest *poi = [[SM3DARPointOfInterest alloc] initWithLocation:location
                                                                               title:@"Dummy 1"
                                                                            subtitle:@"Location unavailable"
                                                                                 url:nil];
        
        [points addObject:poi];
        
        latitude = self.mapView.sm3dar.userLocation.coordinate.latitude + 0.002;
        longitude = self.mapView.sm3dar.userLocation.coordinate.longitude + 0.0003;
        location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        poi = [[SM3DARPointOfInterest alloc] initWithLocation:location
                                                        title:@"Dummy 2"
                                                     subtitle:@"Location unavailable"
                                                          url:nil];
        
        [points addObject:poi];
        
        [self.mapView addAnnotations:points];
        [self.birdseyeView setLocations:points];
        [self.mapView zoomMapToFit];
        [self relax];
    }

}

- (void)didReceiveMemoryWarning 
{
    NSLog(@"\n\ndidReceiveMemoryWarning\n\n");
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload 
{
    [self setRefreshButton:nil];
    NSLog(@"viewDidUnload");
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

#pragma mark Data loading

- (void) loadPoints
{
//    [self lookBusy];

    self.searchQuery = nil;
    
    [self addNorthStar];
    
    if (!self.search)
    {
        self.search = [[YahooLocalSearch alloc] initAtLocation:self.mapView.sm3dar.userLocation];
        self.search.delegate = self;
    }
    
    [self runLocalSearch:@"restaurant"];

    // TODO: Move this into 3DAR as display3darLogo
    
    CGFloat logoCenterX = self.mapView.sm3dar.view.frame.size.width - 10 - (self.mapView.sm3dar.iconLogo.frame.size.width / 2);
    CGFloat logoCenterY = self.mapView.sm3dar.view.frame.size.height - 10 - (self.mapView.sm3dar.iconLogo.frame.size.height / 2);
    self.mapView.sm3dar.iconLogo.center = CGPointMake(logoCenterX, logoCenterY);
}

- (void) sm3darLoadPoints:(SM3DARController *)sm3dar
{
    // 3DAR initialization is complete,
    // but the first location update may not be very accurate.


    if (self.mapView.sm3dar.userLocation.horizontalAccuracy <= IDEAL_LOCATION_ACCURACY)
    {
        [self loadPoints];
    }
    else
    {
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(reduceDesiredLocationAccuracy:) userInfo:nil repeats:YES];
    }
}

CGFloat _alt = 4;

- (void) sm3dar:(SM3DARController *)sm3dar didChangeFocusToPOI:(SM3DARPoint *)newPOI fromPOI:(SM3DARPoint *)oldPOI
{
	[self playFocusSound];
//    [sm3dar setCameraAltitudeMeters:_alt+=20];
//    NSLog(@"alt: %.0f", _alt);
    

}

- (void) sm3dar:(SM3DARController *)sm3dar didChangeSelectionToPOI:(SM3DARPoint *)newPOI fromPOI:(SM3DARPoint *)oldPOI
{
	NSLog(@"POI was selected: %@", [newPOI title]);
}

- (void) showDetails:(id)sender
{
    id<MKAnnotation> annotation = nil;
    
    if ([sender conformsToProtocol:@protocol(MKAnnotation)])
    {
        annotation = (id<MKAnnotation>)sender;
        NSLog(@"Showing annotation details for '%@'", annotation.title);
    }
    else
    {
        NSLog(@"TODO: pass annotation when callout is tapped.");
    }
}

- (void) mapView:(MKMapView *)theMapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    id<MKAnnotation> annotation = view.annotation;
    NSLog(@"Tapped callout with annotation: %@", annotation);
    [self showDetails:annotation];
}

#pragma mark Sound
- (void) initSound 
{
	CFBundleRef mainBundle = CFBundleGetMainBundle();
	CFURLRef soundFileURLRef = CFBundleCopyResourceURL(mainBundle, CFSTR ("focus2"), CFSTR ("aif"), NULL) ;
	AudioServicesCreateSystemSoundID(soundFileURLRef, &focusSound);
}

- (void) playFocusSound 
{
	AudioServicesPlaySystemSound(focusSound);
} 

#pragma mark -

- (void) locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation 
{
    if (!acceptableLocationAccuracyAchieved)
    {
        [self.mapView zoomMapToFit];
    }

    self.birdseyeView.centerLocation = newLocation;
    
    
    // When moving quickly along a path
    // in or on a vehicle like a bus, automobile or bike
    // I want yorient to auto-refresh upcoming places
    // several seconds ahead of my current position 
    // in small batches of 7 or so
    // working backwards towards me from my vector
    // d = rt, so 50 km/h * 10 sec = 500 km*sec/h = 0.14 km
    // 140 meters in 10 seconds at 50 km/h on a Broadway bus
    // bearing 270° (west)
    // use Vincenty to find lat/lng of point 140m away at 270°
    // 
    // Once I see places popping up around me 
    // as I move through and among them
    // I'll prefer that my location updates happen smoothly
    // so that place markers cruise by me with rest of the scene
    // without jerking.
    // 
}

#pragma mark -

/*
- (SM3DARFixture*) addFixtureWithView:(SM3DARPointView*)pointView
{
    SM3DARFixture *point = [[SM3DARFixture alloc] init];
    
    point.view = pointView;  
    
    pointView.point = point;
    
    return [point autorelease];
}

- (SM3DARFixture*) addLabelFixture:(NSString*)title subtitle:(NSString*)subtitle coord:(Coord3D)coord
{
    RoundedLabelMarkerView *v = [[RoundedLabelMarkerView alloc] initWithTitle:title subtitle:subtitle];

    SM3DARFixture *fixture = [self addFixtureWithView:v];
    [v release];    
    
    fixture.worldPoint = coord;
    
    [SM3DAR addPoint:fixture];

    return fixture;
}

- (void) addDirectionBillboardsWithFixtures
{
    Coord3D origin = {
        0, 0, DIRECTION_BILLBOARD_ALTITUDE_METERS
    };    
    
    Coord3D north, south, east, west;
    
    north = south = east = west = origin;
    
    CGFloat range = 5000.0;    
    
    north.y += range;
    south.y -= range;
    east.x += range;
    west.x -= range;
    
    [self addLabelFixture:@"N" subtitle:@"" coord:north];
    [self addLabelFixture:@"S" subtitle:@"" coord:south];
    [self addLabelFixture:@"E" subtitle:@"" coord:east];
    [self addLabelFixture:@"W" subtitle:@"" coord:west];
}
*/

- (void) searchDidFinishWithEmptyResults
{
    NSLog(@"No search results for '%@'", self.searchQuery);
    [self relax];
}

- (void) searchDidFinishWithResults:(NSArray*)results;
{
    [self.mapView.sm3dar setCameraAltitudeMeters:80];

    NSMutableArray *points = [NSMutableArray arrayWithCapacity:[results count]];
    
    for (NSDictionary *data in results)
    {
		SM3DARPointOfInterest *poi = [[SM3DARPointOfInterest alloc] initWithLocation:[data objectForKey:@"location"]
                                                                                 title:[data objectForKey:@"title"] 
                                                                              subtitle:[data objectForKey:@"subtitle"] 
                                                                                   url:nil];
        
//        [self.mapView addAnnotation:poi];
        [points addObject:poi];
        [poi release];
    }
    
    [self.mapView addAnnotations:points];
    [self.birdseyeView setLocations:points];
    [self.mapView zoomMapToFit];
    [self relax];
}

- (void) sm3darDidShowMap:(SM3DARController *)sm3dar
{
    self.hudView.hidden = YES;
    [self.mapView addSubview:self.refreshButton];
    [self.mapView addSubview:self.toggleMapButton];
}


- (void) sm3darDidHideMap:(SM3DARController *)sm3dar
{
    [self.hudView addSubview:self.mapView.sm3dar.iconLogo];
    [self.hudView addSubview:self.refreshButton];
    [self.hudView addSubview:self.toggleMapButton];
    self.hudView.hidden = NO;
}

#pragma mark -

- (void) add3dObjectNortheastOfUserLocation 
{
    SM3DARTexturedGeometryView *modelView = [[[SM3DARTexturedGeometryView alloc] initWithOBJ:@"star.obj" textureNamed:nil] autorelease];
    
    CLLocationDegrees latitude = self.mapView.sm3dar.userLocation.coordinate.latitude + 0.0001;
    CLLocationDegrees longitude = self.mapView.sm3dar.userLocation.coordinate.longitude + 0.0001;

    
    // Add a point with a 3D 
    
    SM3DARPoint *poi = [[self.mapView.sm3dar addPointAtLatitude:latitude
                                                 longitude:longitude
                                                  altitude:0 
                                                     title:nil 
                                                      view:modelView] autorelease];
    
    [self.mapView addAnnotation:(SM3DARPointOfInterest*)poi];
}

- (void) addNorthStar
{
    UIImageView *star = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"polaris.png"]] autorelease];
    
    CLLocationDegrees latitude = self.mapView.sm3dar.userLocation.coordinate.latitude + 0.1;
    CLLocationDegrees longitude = self.mapView.sm3dar.userLocation.coordinate.longitude;
    
    
    // NOTE: poi is autoreleased
    
    self.northStar = (SM3DARPointOfInterest*)[[self.mapView.sm3dar addPointAtLatitude:latitude
                              longitude:longitude
                               altitude:3000.0 
                                  title:@"Polaris" 
                                   view:star] retain];
    
    self.northStar.canReceiveFocus = NO;
    
    // 3DAR bug: addPointAtLatitude:longitude:altitude:title:view should add the point, not just init it.  Doh!
    [self.mapView.sm3dar addPoint:self.northStar];
}


- (IBAction) refreshButtonTapped
{
    NSLog(@"Refresh button was tapped");
    [self runLocalSearch:self.searchQuery];
}

- (void) addBirdseyeView
{
    CGFloat birdseyeViewRadius = 70.0;

    self.birdseyeView = [[BirdseyeView alloc] initWithLocations:nil
                                                    around:self.mapView.sm3dar.userLocation
                                            radiusInPixels:birdseyeViewRadius];
    
    self.birdseyeView.center = CGPointMake(self.view.frame.size.width - (birdseyeViewRadius) - 10,
                                      10 + (birdseyeViewRadius));
    
    [self.view addSubview:self.birdseyeView];
    
    self.mapView.sm3dar.compassView = self.birdseyeView;
}

- (IBAction) toggleMapButtonTapped:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    if (sender.selected)
    {
        [self.mapView.sm3dar hideMap];
    }
    else
    {
        [self.mapView.sm3dar showMap];
    }
}

//
// This was added on 9/10/2011 for Stéphane.
// https://gist.github.com/1207231
//
- (SM3DARPointOfInterest *) movePOI:(SM3DARPointOfInterest *)poi toLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude altitude:(CLLocationDistance)altitude
{    
    
    CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    
    SM3DARPointOfInterest *newPOI = [[SM3DARPointOfInterest alloc] initWithLocation:newLocation 
                                                                              title:poi.title 
                                                                           subtitle:poi.subtitle 
                                                                                url:poi.dataURL 
                                                                         properties:poi.properties];
    
    newPOI.view = poi.view;
    newPOI.delegate = poi.delegate;
    newPOI.annotationViewClass = poi.annotationViewClass;
    newPOI.canReceiveFocus = poi.canReceiveFocus;
    newPOI.hasFocus = poi.hasFocus;
    newPOI.identifier = poi.identifier;
    newPOI.gearPosition = poi.gearPosition;
    

    id oldAnnotation = [self.mapView annotationForPoint:poi];
    
    if (oldAnnotation)
    {
        [self.mapView removeAnnotation:oldAnnotation];
        [self.mapView addAnnotation:newPOI];
    }
    else
    {
        [self.mapView.sm3dar removePointOfInterest:poi];
        [self.mapView.sm3dar addPointOfInterest:newPOI];
    }
    
    [newLocation release];
    [newPOI release];
    
    return newPOI;
}
/*
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
    NSLog(@"Main view touched");
    [self.nextResponder touchesBegan:touches withEvent:event];
}
*/

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKAnnotationView *annotationView = nil;
    
    // if it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    if ([annotation isKindOfClass:[SM3DARPointOfInterest class]])
    {
        // try to dequeue an existing pin view first
        static NSString *ReusableAnnotationIdentifier = @"reusableAnnotationIdentifier";
        
        MKPinAnnotationView *pinView = (MKPinAnnotationView *)[theMapView dequeueReusableAnnotationViewWithIdentifier:ReusableAnnotationIdentifier];
        
        if (!pinView)
        {
            // if an existing pin view was not available, create one
            MKPinAnnotationView *customPinView = [[[MKPinAnnotationView alloc]
                                                   initWithAnnotation:annotation reuseIdentifier:ReusableAnnotationIdentifier] autorelease];
            
            customPinView.pinColor = MKPinAnnotationColorPurple;
            customPinView.animatesDrop = YES;
            customPinView.canShowCallout = YES;
            
            // add a detail disclosure button to the callout which will open a new view controller page
            //
            // note: you can assign a specific call out accessory view, or as MKMapViewDelegate you can implement:
            //  - (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;
            //
            UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [rightButton addTarget:self
                            action:@selector(showDetails:)
                  forControlEvents:UIControlEventTouchUpInside];
            
            customPinView.rightCalloutAccessoryView = rightButton;
            
            return customPinView;
        }
        else
        {
            pinView.annotation = annotation;
        }
        
        annotationView = pinView;
    }
    
    return annotationView;
}

// Return nil from sm3dar:calloutViewForPoint: to disable the given point's callout.
- (SM3DARCalloutView*) sm3dar:(SM3DARController*)sm3dar calloutViewForPoint:(SM3DARPoint*)point
{
    if (self.calloutView == nil)
    {
        // A blue disclosure button will be visible if the callout view has an SM3DARCalloutViewDelegate.
        // Set the delegate to nil to hide the disclosure button.
        
        self.calloutView = [[[SM3DARMorphingCalloutView alloc] initWithDelegate:self] autorelease];
        self.calloutView.centerOffset = CGPointMake(0, 50);

        NSLog(@"Initialized new callout view of type '%@'", [self.calloutView class]);
    }
 
    return (SM3DARCalloutView*)self.calloutView;
}

- (void) calloutViewWasTappedForPoint:(SM3DARPoint*)point
{
    NSLog(@"Callout view tapped: %@", point.title);
}

#define IS_WIDESCREEN ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

//
// Call this after starting the camera, which must happen after at or after viewDidAppear.
//
- (void)make3darFullscreen
{
    [self.mapView.sm3dar setFrame:[UIScreen mainScreen].bounds];
    [self.mapView.sm3dar.glView setFrame:[UIScreen mainScreen].bounds];
  
    if (IS_WIDESCREEN)
    {
        CGFloat scale = 1.41;
        self.mapView.sm3dar.camera.cameraViewTransform = CGAffineTransformMakeScale(scale, scale);
    }
}

@end

