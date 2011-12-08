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


#define SG_CONSUMER_KEY @"cxu7vcXRsfSaBZGm4EZffVGRq662YCNJ"
#define SG_CONSUMER_SECRET @"fTGANz54NXzMVQ6gwgnJcKEua4m2MLSs"
#define IDEAL_LOCATION_ACCURACY 10.0


@interface MainViewController (Private)
- (void) addBirdseyeView;
@end

@implementation MainViewController

@synthesize searchQuery;
@synthesize search;
@synthesize mapView;
@synthesize simplegeo;

- (void)dealloc 
{
	[searchQuery release];
    [search release];
    
    [mapView release];
    mapView = nil;
    
    [hudView release];
    hudView = nil;
    
    [focusView release];
    focusView = nil;
    
    [spinner release];
    spinner = nil;
    
    [simplegeo release];
    [birdseyeView release];
    
    [toggleMapButton release];
    [northStar release];
    
	[super dealloc];
}

- (void) reduceDesiredLocationAccuracy:(NSTimer*)timer
{
    NSLog(@"Current location accuracy: %.0f", mapView.sm3dar.userLocation.horizontalAccuracy);

    if (desiredLocationAccuracyAttempts > 8 || mapView.sm3dar.userLocation.horizontalAccuracy <= desiredLocationAccuracy)
    {
        NSLog(@"Acceptable location accuracy achieved.");
        acceptableLocationAccuracyAchieved = YES;
        [timer invalidate];
        timer = nil;
        [mapView.sm3dar.locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];        
        [self loadPoints];
    }
    else
    {
        desiredLocationAccuracy *= 1.5;
        NSLog(@"Setting desired location accuracy to %.0f", desiredLocationAccuracy);
        [mapView.sm3dar.locationManager setDesiredAccuracy:desiredLocationAccuracy];        
        desiredLocationAccuracyAttempts++;
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) 
    {      
        self.simplegeo = [SimpleGeo clientWithConsumerKey:SG_CONSUMER_KEY
                                            consumerSecret:SG_CONSUMER_SECRET];
        
        desiredLocationAccuracy = IDEAL_LOCATION_ACCURACY / 2.0;        
    }
    
    return self;
}

- (void) lookBusy
{
    [spinner startAnimating];
        
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
    
    [[spinner layer] addAnimation:anim forKey:@"flip"];

}

- (void) relax
{
    [spinner stopAnimating];
    [[spinner layer] removeAnimationForKey:@"flip"];
}

- (void) viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];
    
    toggleMapButton.hidden = [((NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"3darMapMode"]) isEqualToString:@"auto"];
    
    [mapView.sm3dar startCamera];
}

- (void) viewDidLoad 
{
	[super viewDidLoad];
    
    [self initSound];
    self.view.backgroundColor = [UIColor blackColor];
    
    if (hudView)
    {
//        mapView.sm3dar.hudView = hudView;
//        hudView.hidden = YES;
    }    
    
    [self addBirdseyeView];
    
    mapView.sm3dar.focusView = focusView;
    
    [focusView setCalloutDelegate:mapView];

    [self lookBusy];
    [self.view bringSubviewToFront:hudView];
    [self.view bringSubviewToFront:spinner];
    
    [self.view setFrame:[UIScreen mainScreen].bounds];
    [mapView.sm3dar setFrame:self.view.bounds];
}

/*
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.frame = [UIScreen mainScreen].applicationFrame;
    mapView.frame = self.view.frame;
    [mapView.sm3dar setFrame:self.view.frame];
//    [mapView.sm3dar.view addSubview:mapView.sm3dar.iconLogo];
    
    self.view.backgroundColor = [UIColor blueColor];
}
*/

- (void)runLocalSearch:(NSString*)query 
{
    [self lookBusy];

    [mapView removeAnnotations:mapView.annotations];
    
	self.searchQuery = query;
    search.location = mapView.sm3dar.userLocation;
    [search execute:searchQuery];    
}

- (void)didReceiveMemoryWarning 
{
    NSLog(@"\n\ndidReceiveMemoryWarning\n\n");
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload 
{
    NSLog(@"viewDidUnload");
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

#pragma mark Data loading

- (void) loadPoints
{
    [self lookBusy];

    self.searchQuery = nil;
    
    [self addNorthStar];
    [self fetchSimpleGeoPlaces:nil];
    
    // TODO: Move this into 3DAR as display3darLogo
    
    CGFloat logoCenterX = mapView.sm3dar.view.frame.size.width - 10 - (mapView.sm3dar.iconLogo.frame.size.width / 2);
    CGFloat logoCenterY = mapView.sm3dar.view.frame.size.height - 10 - (mapView.sm3dar.iconLogo.frame.size.height / 2);                           
    mapView.sm3dar.iconLogo.center = CGPointMake(logoCenterX, logoCenterY);    
}

- (void) sm3darLoadPoints:(SM3DARController *)sm3dar
{
    // 3DAR initialization is complete, 
    // but the first location update may not be very accurate.

    if (mapView.sm3dar.userLocation.horizontalAccuracy <= IDEAL_LOCATION_ACCURACY)
    {
        [self loadPoints];
    }
    else
    {
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(reduceDesiredLocationAccuracy:) userInfo:nil repeats:YES];
    }
}

- (void) sm3dar:(SM3DARController *)sm3dar didChangeFocusToPOI:(SM3DARPoint *)newPOI fromPOI:(SM3DARPoint *)oldPOI
{
	[self playFocusSound];
}

- (void) sm3dar:(SM3DARController *)sm3dar didChangeSelectionToPOI:(SM3DARPoint *)newPOI fromPOI:(SM3DARPoint *)oldPOI
{
	NSLog(@"POI was selected: %@", [newPOI title]);
}

- (void) mapView:(MKMapView *)theMapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    id<MKAnnotation> annotation = view.annotation;
    NSLog(@"Tapped callout with annotation: %@", annotation);
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
        [mapView zoomMapToFit];
    }

    birdseyeView.centerLocation = newLocation;
    
    
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
    [self relax];
}

- (void) searchDidFinishWithResults:(NSArray*)results;
{    
    NSMutableArray *points = [NSMutableArray arrayWithCapacity:[results count]];
    
    for (NSDictionary *data in results)
    {
		SM3DARPointOfInterest *poi = [[SM3DARPointOfInterest alloc] initWithLocation:[data objectForKey:@"location"]
                                                                                 title:[data objectForKey:@"title"] 
                                                                              subtitle:[data objectForKey:@"subtitle"] 
                                                                                   url:nil];
        
        //[mapView addAnnotation:poi];
        [points addObject:poi];
        [poi release];
    }
    
    [mapView addAnnotations:points];

//    [mapView performSelectorOnMainThread:@selector(zoomMapToFit) withObject:nil waitUntilDone:YES];
//    [mapView addBackground];
    [mapView zoomMapToFit];
    [self relax];
}

- (void) sm3darDidShowMap:(SM3DARController *)sm3dar
{
//    hudView.hidden = YES;
}

- (void) sm3darDidHideMap:(SM3DARController *)sm3dar
{
//    hudView.hidden = NO;
//    [hudView addSubview:mapView.sm3dar.iconLogo];

}

#pragma mark SimpleGeo

- (void) plotSimpleGeoPlaces:(NSArray*)fetchedPlaces
{
    NSMutableArray *annotations = [NSMutableArray arrayWithCapacity:[fetchedPlaces count]];
    
    for (SGPlace *place in fetchedPlaces) 
    {
        SGPoint *point = place.point;
        NSString *name = place.name;
        NSString *category = @"";


        if (place.classifiers)
        {
            NSDictionary *classifiers = [place.classifiers objectAtIndex:0];
            
            category = [classifiers classifierCategory];
            
            NSString *subcategory = [classifiers classifierSubcategory];
            
            if (subcategory && ! ([subcategory isEqual:@""] ||
                                  [subcategory isEqual:[NSNull null]])) 
            {
                category = [NSString stringWithFormat:@"%@ : %@", category, subcategory];
            }
        }
        
#if 0
        
        // Use standard marker view.
        
        MKPointAnnotation *annotation = [[[MKPointAnnotation alloc] init] autorelease];
        annotation.coordinate = point.coordinate;
        annotation.title = name;
        annotation.subtitle = category;
        
#else
        
        // Use custom marker view.
        
        CLLocation *location = [[[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude] autorelease];
        
        SM3DARPointOfInterest *annotation = [[[SM3DARPointOfInterest alloc] initWithLocation:location properties:[place properties]] autorelease];
        annotation.title = name;
        annotation.subtitle = category;
        
#endif
        
        [annotations addObject:annotation];
    }
    
    NSLog(@"Adding annotations");
    [birdseyeView setLocations:annotations];
    [mapView addAnnotations:annotations];
    
    
    // Temporary workaround:
    // Hide the simple callout view
    // because yorient uses its own focusView.
    for (SM3DARPointOfInterest *poi in [mapView.sm3dar pointsOfInterest])
    {
        if ([poi.view isKindOfClass:[SM3DARIconMarkerView class]])
        {
            ((SM3DARIconMarkerView *)poi.view).callout = nil;
        }
    }
    
    [mapView zoomMapToFit];
    [self relax];
    
}

- (void) fetchSimpleGeoPlaces:(NSString*)searchString
{
    SGPoint *here = [SGPoint pointWithLat:mapView.sm3dar.userLocation.coordinate.latitude
                                      lon:mapView.sm3dar.userLocation.coordinate.longitude];
    
    SGPlacesQuery *query = [SGPlacesQuery queryWithPoint:here];
    
    [query setSearchString:searchString];
    
    [simplegeo getPlacesForQuery:query
                        callback:[SGCallback callbackWithSuccessBlock:
                                  ^(id response) {
                                      
                                      NSArray *places = [NSArray arrayWithSGCollection:response type:SGCollectionTypePlaces];
                                      [self plotSimpleGeoPlaces:places];
                                      
                                  } 
                                                         failureBlock:^(NSError *error) {
                                                             // handle failures
                                                         }]];
}

#pragma mark -

- (void) add3dObjectNortheastOfUserLocation 
{
    SM3DARTexturedGeometryView *modelView = [[[SM3DARTexturedGeometryView alloc] initWithOBJ:@"star.obj" textureNamed:nil] autorelease];
    
    CLLocationDegrees latitude = mapView.sm3dar.userLocation.coordinate.latitude + 0.0001;
    CLLocationDegrees longitude = mapView.sm3dar.userLocation.coordinate.longitude + 0.0001;

    
    // Add a point with a 3D 
    
    SM3DARPoint *poi = [[mapView.sm3dar addPointAtLatitude:latitude
                                                 longitude:longitude
                                                  altitude:0 
                                                     title:nil 
                                                      view:modelView] autorelease];
    
    [mapView addAnnotation:(SM3DARPointOfInterest*)poi]; 
}

- (void) addNorthStar
{
    UIImageView *star = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"polaris.png"]] autorelease];
    
    CLLocationDegrees latitude = mapView.sm3dar.userLocation.coordinate.latitude + 0.1;
    CLLocationDegrees longitude = mapView.sm3dar.userLocation.coordinate.longitude;
    
    
    // NOTE: poi is autoreleased
    
    northStar = (SM3DARPointOfInterest*)[[mapView.sm3dar addPointAtLatitude:latitude
                              longitude:longitude
                               altitude:3000.0 
                                  title:@"Polaris" 
                                   view:star] retain];
    
    northStar.canReceiveFocus = NO;
    
    // 3DAR bug: addPointAtLatitude:longitude:altitude:title:view should add the point, not just init it.  Doh!
    [mapView.sm3dar addPoint:northStar];
}


- (IBAction) refreshButtonTapped
{
    [self lookBusy];
    
    [birdseyeView setLocations:nil];
    [self.mapView removeAllAnnotations];

    [self addNorthStar];

//    [self add3dObjectNortheastOfUserLocation];
    [self fetchSimpleGeoPlaces:@"pizza"];    
}

- (void) addBirdseyeView
{
    CGFloat birdseyeViewRadius = 70.0;

    birdseyeView = [[BirdseyeView alloc] initWithLocations:nil
                                                    around:mapView.sm3dar.userLocation 
                                            radiusInPixels:birdseyeViewRadius];
    
    birdseyeView.center = CGPointMake(self.view.frame.size.width - (birdseyeViewRadius) - 10, 
                                      10 + (birdseyeViewRadius));
    
    [self.view addSubview:birdseyeView];
    
    mapView.sm3dar.compassView = birdseyeView;    
}

- (IBAction) toggleMapButtonTapped:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    if (sender.selected)
    {
        [mapView.sm3dar hideMap];
    }
    else
    {
        [mapView.sm3dar showMap];
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
    

    id oldAnnotation = [mapView annotationForPoint:poi];
    
    if (oldAnnotation)
    {
        [mapView removeAnnotation:oldAnnotation];
        [mapView addAnnotation:newPOI];
    }
    else
    {
        [mapView.sm3dar removePointOfInterest:poi];
        [mapView.sm3dar addPointOfInterest:newPOI];
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

@end

