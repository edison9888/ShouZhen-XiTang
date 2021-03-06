//
//  SGMapViewController.m
//  SouZhen
//
//  Created by chenwang on 13-8-21.
//  Copyright (c) 2013年 songguo. All rights reserved.
//

#import "SGMapViewController.h"
#import <MapKit/MapKit.h>
#import "CalloutMapAnnotation.h"
#import "CalloutMapAnnotationView.h"
#import "SGPinContentView.h"
#import "SGSceneryDetailViewController.h"
#import "SGAppDelegate.h"
#import "SGFakeDataHelper.h"
#import <AddressBook/AddressBook.h>
#import "SGHotelHouseTypeViewController.h"
#import "SGHotelDetailViewController.h"

@interface SGMapViewController () <MKMapViewDelegate, SGPinContentViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (nonatomic, retain) CalloutMapAnnotation *calloutAnnotation;
@property (nonatomic, retain) MKAnnotationView *selectedAnnotationView;


@end

@implementation SGMapViewController
{
    NSMutableArray *_annotations;
    SGPinContentView *_pinContentView;
}

- (id)init
{
    self = [super init];
    if (self) {
        _annotations = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationBarHidden = YES;
    self.title = @"地图";
    self.mapView.delegate = self;
    
    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"SGPinContentView" owner:nil options:nil];
    _pinContentView = [views objectAtIndex:0];
    _pinContentView.delegate = self;

    [self refreshMap];
}

- (void)refreshMap
{
    CLLocationCoordinate2D leftUpLocation = CLLocationCoordinate2DMake(0, 180);
    CLLocationCoordinate2D rightDownLocation = CLLocationCoordinate2DMake(90, 0);
    for (SGAnnotation *data in _annotations) {
        if (data.coordinate.latitude == 0 || data.coordinate.longitude == 0) {
            continue;
        }
        leftUpLocation.latitude = MAX(ABS(leftUpLocation.latitude),ABS(data.coordinate.latitude));
        leftUpLocation.longitude = MIN(leftUpLocation.longitude, data.coordinate.longitude);
        
        rightDownLocation.latitude = MIN(ABS(rightDownLocation.latitude),ABS(data.coordinate.latitude));
        rightDownLocation.longitude = MAX(rightDownLocation.longitude, data.coordinate.longitude);
    }
    MKCoordinateSpan span = MKCoordinateSpanMake(2*ABS(rightDownLocation.latitude - leftUpLocation.latitude),
                                                 2*ABS(rightDownLocation.longitude - leftUpLocation.longitude));
    if (span.latitudeDelta == 0 || span.longitudeDelta == 0) {
        span.latitudeDelta = 0.01f;
        span.longitudeDelta = 0.01f;
    }
    CLLocationCoordinate2D center;
    center.latitude = (rightDownLocation.latitude + leftUpLocation.latitude) / 2;
    center.longitude = (rightDownLocation.longitude + leftUpLocation.longitude) / 2;
    
    MKCoordinateRegion displayRegion = MKCoordinateRegionMake(center,span);
    [self.mapView setRegion:displayRegion animated:NO];
    [self.mapView removeAnnotations:_annotations];
    [self.mapView addAnnotations:_annotations];
}

- (void)setAnnotations:(NSArray *)annotations
{
    [_annotations removeAllObjects];
    [_annotations addObjectsFromArray:annotations];
    
    [self refreshMap];
}

- (void)addAnnotation:(SGAnnotation *)annotation
{
    [_annotations addObject:annotation];
    [self.mapView addAnnotation:annotation];
}

- (void)removeAnnotationWithId:(NSString *)annotationId
{
    for (SGAnnotation *annotation in _annotations) {
        if ([annotationId isEqualToString:annotation.uid]) {
            [_annotations removeObject:annotation];
            [self refreshMap];
            break;
        }
    }
}


- (IBAction)showRouteAction:(id)sender {
    UIAlertView *alerView = [[UIAlertView alloc] initWithTitle:nil message:@"即将打开苹果内置地图显示路线，确认吗？" delegate:self cancelButtonTitle:@"暂不" otherButtonTitles:@"好", nil];
    [alerView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        SGAnnotation *anno = _pinContentView.annotation;
        Class itemClass = [MKMapItem class];
        if (IPHONE_OS_6() && itemClass && [itemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)]) {
                //kABPersonAddressStreetKey : @"Street"
            NSDictionary *addressDict = [NSDictionary dictionaryWithObject:anno.address
                                                                    forKey:(NSString *)kABPersonAddressStreetKey];
            
            MKPlacemark *tPlacement = [[MKPlacemark alloc] initWithCoordinate:anno.coordinate
                                                            addressDictionary:addressDict];
            
            MKMapItem *tMapItem = [[MKMapItem alloc] initWithPlacemark:tPlacement];
            
            [MKMapItem openMapsWithItems:[NSArray arrayWithObject:tMapItem]
                               launchOptions:nil];
        } else {
                // show pin directly
            NSString *str = [NSString stringWithFormat:@"http://maps.google.com/maps?q=%f,%f(%@)",
                             anno.coordinate.latitude, anno.coordinate.longitude,
                             [anno.address stringByAddingPercentEscapesUsingEncodingExt:NSUTF8StringEncoding]];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
        }

    }
}

- (IBAction)resetAction:(id)sender {
    [self refreshMap];
}

- (IBAction)backAction:(id)sender {
    if ([self.navigationController.childViewControllers count] > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        if ([[SGAppDelegate instance].drawerController openSide] == MMDrawerSideNone) {
            [[SGAppDelegate instance].drawerController openDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
        } else {
            [[SGAppDelegate instance].drawerController closeDrawerAnimated:YES completion:nil];
        }
    }
}

#pragma mark - MapViewDelegate
- (MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[SGAnnotation class]]) {
        MKAnnotationView *pin = (MKAnnotationView *)[map dequeueReusableAnnotationViewWithIdentifier:@"annotationsView"];
        if(pin == nil) {
            pin = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"annotationsView"];
            pin.exclusiveTouch = YES;
            pin.draggable = NO;
//            pin.canShowCallout = YES;
        } else {
            pin.annotation = annotation;
        }
        SGAnnotation *routeAnno = annotation;
//        if (routeAnno.leftImage.length > 0) {
//            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:routeAnno.leftImage]];
//            imageView.frame = CGRectMake(0, 0, 32, 32);
//            pin.leftCalloutAccessoryView = imageView;
//        } else {
//            pin.leftCalloutAccessoryView = nil;
//        }
        
        UIImage *backgroundImage = nil;
        if (routeAnno.type == AnnotationTypeScenery) {
            backgroundImage = [UIImage imageNamed:@"icon_dbjd"];
        } else if (routeAnno.type == AnnotationTypeHotel) {
            backgroundImage = [UIImage imageNamed:@"icon_dbkz"];
        } else {
            backgroundImage = [UIImage imageNamed:@"icon_dbyl"];
        }
        pin.image = backgroundImage;
        
        return pin;
    } else if ([annotation isKindOfClass:[CalloutMapAnnotation class]]) {
        CalloutMapAnnotationView *calloutMapAnnotationView = (CalloutMapAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"CalloutAnnotation"];
		if (!calloutMapAnnotationView) {
			calloutMapAnnotationView = [[CalloutMapAnnotationView alloc] initWithAnnotation:annotation
																			 reuseIdentifier:@"CalloutAnnotation"];
			calloutMapAnnotationView.contentHeight = _pinContentView.frame.size.height;
            calloutMapAnnotationView.contentWidth = _pinContentView.frame.size.width;
			[calloutMapAnnotationView.contentView addSubview:_pinContentView];
		}
        calloutMapAnnotationView.enabled = NO;
		calloutMapAnnotationView.parentAnnotationView = self.selectedAnnotationView;
		calloutMapAnnotationView.mapView = self.mapView;
		return calloutMapAnnotationView;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    self.selectedAnnotationView = view;
	if ([view.annotation isKindOfClass:[SGAnnotation class]]) {
		if (self.calloutAnnotation == nil) {
			self.calloutAnnotation = [[CalloutMapAnnotation alloc] initWithLatitude:view.annotation.coordinate.latitude
                                                                        andLongitude:view.annotation.coordinate.longitude];
		} else {
			self.calloutAnnotation.latitude = view.annotation.coordinate.latitude;
			self.calloutAnnotation.longitude = view.annotation.coordinate.longitude;
		}
        [_pinContentView showAnnotation:view.annotation];
		[self.mapView addAnnotation:self.calloutAnnotation];
	}
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
	if (self.calloutAnnotation && ([view.annotation isKindOfClass:[SGAnnotation class]])) {
		[self.mapView removeAnnotation: self.calloutAnnotation];
	}
}

- (void)pinContentView:(SGPinContentView *)pinContentView didSelectAtAnnotation:(SGAnnotation *)annotation
{
    SGViewController *viewController;
    if (annotation.type == AnnotationTypeScenery) {
        viewController = [[SGSceneryDetailViewController alloc] init];
        SGSceneryData *data = [[SGFakeDataHelper instance] getSceneryByID:annotation.uid];
        ((SGSceneryDetailViewController *)viewController).sceneryData = data;
    } else if (annotation.type == AnnotationTypeHotel) {
        SGHotelData *hotel = [[SGFakeDataHelper instance] getHotelByID:annotation.uid];
        if (hotel.houseList.count > 0) {
            SGHotelHouseTypeViewController *viewController = [[SGHotelHouseTypeViewController alloc] init];
            viewController.title = hotel.name;
            viewController.houseTypeList = hotel.houseList;
            viewController.hotelData = hotel;
            [self.navigationController pushViewController:viewController animated:YES];
        } else {
            SGHotelDetailViewController *viewController = [[SGHotelDetailViewController alloc] init];
            viewController.title = hotel.name;
            viewController.hotelData = hotel;
            [self.navigationController pushViewController:viewController animated:YES];
        }
    }
    if (viewController) {
        if (self.navigationController == nil) {
            [self.parentViewController.navigationController pushViewController:viewController animated:YES];
        } else {
            [self.navigationController pushViewController:viewController animated:YES];
        }        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setMapView:nil];
    [super viewDidUnload];
}
@end
