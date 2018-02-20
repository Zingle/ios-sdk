//
//  ZNGGooglyEye.m
//  ZingleSDK
//
//  Created by Jason Neel on 2/19/18.
//

#import "ZNGGooglyEye.h"
#import "ZNGGooglyEyePupil.h"
#import "ZNGLogging.h"

static const int zngLogLevel = ZNGLogLevelInfo;

@import CoreMotion;

@implementation ZNGGooglyEye
{
    ZNGGooglyEyePupil * pupil;
    
    UIDynamicAnimator * animator;
    UIGravityBehavior * gravity;
    UIPushBehavior * userForce;
    UICollisionBehavior * collision;
    
    CMMotionManager * motionManager;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self != nil) {
        self.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self != nil) {
        self.backgroundColor = [UIColor whiteColor];
    }

    return self;
}

- (UIDynamicItemCollisionBoundsType) collisionBoundsType
{
    return UIDynamicItemCollisionBoundsTypeEllipse;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    [self setupMask];
}

- (void) setupMask
{
    CAShapeLayer * mask = [[CAShapeLayer alloc] init];
    UIBezierPath * maskPath = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    mask.path = [maskPath CGPath];
    self.layer.mask = mask;
}

- (void) removeFromSuperview
{
    [motionManager stopDeviceMotionUpdates];
    animator = nil;
    [super removeFromSuperview];
}

- (void) didMoveToSuperview
{
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
    
    [pupil removeFromSuperview];
    CGFloat pupilDiameter = MIN(self.bounds.size.height, self.bounds.size.width) * 0.4;
    pupil = [[ZNGGooglyEyePupil alloc] initWithFrame:CGRectMake(0.0, 0.0, pupilDiameter, pupilDiameter)];
    pupil.backgroundColor = [UIColor blackColor];
    pupil.center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height - (pupilDiameter * 0.5));
    [self addSubview:pupil];
    
    collision = [[UICollisionBehavior alloc] initWithItems:@[pupil]];
    UIBezierPath * boundaryPath = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(self.bounds, -2.5, -2.5)]; // Allow slight overflow of pupils outside whites
    [collision addBoundaryWithIdentifier:@"circleBoundary" forPath:boundaryPath];
    
    gravity = [[UIGravityBehavior alloc] initWithItems:@[pupil]];
    userForce = [[UIPushBehavior alloc] initWithItems:@[pupil] mode:UIPushBehaviorModeContinuous];
    
    // Add some random friction to vary the movement of this eye vs. other eyes
    UIDynamicItemBehavior * friction = [[UIDynamicItemBehavior alloc] initWithItems:@[pupil]];
    friction.resistance = (CGFloat)(arc4random() % 33) * 0.01;
    
    [animator addBehavior:friction];
    [animator addBehavior:collision];
    [animator addBehavior:gravity];
    [animator addBehavior:userForce];
    
    motionManager = [[CMMotionManager alloc] init];
    
    if (motionManager.deviceMotionAvailable) {
        motionManager.deviceMotionUpdateInterval = 0.1;
        __weak ZNGGooglyEye * weakSelf = self;
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            [weakSelf handleMotionData:motion];
        }];
    } else {
        ZNGLogDebug(@"Device motion is not available.  Physics will not apply to eyeballs :(");
    }
}

- (CGVector) orientationRelativeAccelerationFromDeviceRelativeAcceleration:(CMAcceleration)acceleration
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return CGVectorMake(acceleration.x, -acceleration.y);
        case UIInterfaceOrientationPortraitUpsideDown:
            return CGVectorMake(-acceleration.x, acceleration.y);
        case UIInterfaceOrientationLandscapeLeft:
            return CGVectorMake(acceleration.y, acceleration.x);
        case UIInterfaceOrientationLandscapeRight:
            return CGVectorMake(-acceleration.y, -acceleration.x);
        default:
            return CGVectorMake(0.0, 0.0);
    }
}

- (void) handleMotionData:(CMDeviceMotion *)data
{
    if (data == nil) {
        return;
    }
    
    CGVector gravityAcceleration = [self orientationRelativeAccelerationFromDeviceRelativeAcceleration:data.gravity];
    ZNGLogVerbose(@"Gravity is (%.2f, %.2f)", (float)gravityAcceleration.dx, (float)gravityAcceleration.dy);
    gravity.gravityDirection = gravityAcceleration;
    
    CGVector pushDirection = [self orientationRelativeAccelerationFromDeviceRelativeAcceleration:data.userAcceleration];
    CGFloat magnitude = sqrt(pow(data.userAcceleration.x, 2) + pow(data.userAcceleration.y, 2));
    ZNGLogVerbose(@"User acceleration is %.2f in the direction (%.2f, %.2f)", (float)magnitude, (float)pushDirection.dx, (float)pushDirection.dy);
    userForce.pushDirection = pushDirection;
    userForce.magnitude = magnitude * 0.25;  // Reduce magnitude a tiny bit from the raw value
}

@end
