#import "ViewController.h"
#import <CoreRing/CoreRing.h>
#import <RobotKit/RobotKit.h>
#import <RobotUIKit/RobotUIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
@import SafariServices;

@interface ViewController () <CRApplicationDelegate,RKResponseObserver>{
    float heading;
    BOOL gestureMode;
    BOOL didReceivePoint;
    BOOL quatStartFlg;
    NSTimer *timer;
    BOOL _ringIsConnected;
    UIButton *circleBtn;
    BOOL _imageSet;
    int spheroAngle;

}
@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self startConnectionTimer];
    if (!_robot.isConnected) {
        [self handleConnecting];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    [self startAnimating];
    [self rotateUIImage:(_controlSpeed)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    [self.view.layer removeAllAnimations];
    [self stopConnectionTimer];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;
    
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    //  iphone4,4S -> width = 320, height = 480
    //  iphone5,5S -> width = 320, height = 568
    //  iphone6,6S -> width = 375, height = 667
    //  iphone6+,6S+ -> width = 414, height = 736
    //  iPad2,3,4,Air,iPad Mini,Mini2 -> width = 768, height = 1024
    //  iPad Pro -> width = 1024, height = 1366
    
    circleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if (screenHeight == 736) { // iPhone6,6S Plus
        circleBtn.frame = CGRectMake(width/1.7868679246, height/1.3806098563, 50, 50);
        [self.view addSubview:circleBtn];
    } else if (screenHeight == 667) { // iPhone6,6S
        circleBtn.frame = CGRectMake(width/1.7688679246, height/1.3696098563, 50, 50);
        [self.view addSubview:circleBtn];
    } else if (screenHeight == 568) { // iPhone5,5S
        circleBtn.frame = CGRectMake(width/1.7297297297, height/1.3996098563, 50, 50);
        [self.view addSubview:circleBtn];
    } else if (screenHeight == 480) { // iPhone4,4S, iPads
        circleBtn.frame = CGRectMake(width/1.7297297297, height/1.3831686461, 50, 50);
        [self.view addSubview:circleBtn];
    } else { // other
        circleBtn.frame = CGRectMake(width/1.7297297297, height/1.3131686461, 50, 50);
        [self.view addSubview:circleBtn];
        [self.myView removeFromSuperview];
    }

    self.calibrateHandler = [[RUICalibrateButtonGestureHandler alloc] initWithView:self.view button:circleBtn];

    if (screenHeight == 480 || screenHeight == 568) {
        self.calibrateHandler.calibrationRadius = 200;
    } else {
        self.calibrateHandler.calibrationRadius = 250;
    }
    self.calibrateHandler.calibrationCircleLocation = RUICalibrationCircleLocationAbove;

    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(willEnterForeground) name:@"applicationWillEnterForeground" object:nil];
    
    //  initialize
    heading = 0;
    gestureMode = YES;
    quatStartFlg = NO;
    
    // current time
    NSDate* date = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:@"date"];
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:@"tapDate"];
    
    [_controlSpeed addTarget:self action:@selector(slidervaluechanged:) forControlEvents:UIControlEventValueChanged];

    
    //  Ring----------------------------------------------------------------------
    self.ringApp = [[CRApplication alloc] initWithDelegate:self background:NO];
    
    //  Register gestures
    if (![[self.ringApp installedGestureIdentifiers] count]) {
        NSDictionary *gestures = @{ @"circle" : CR_POINTS_CIRCLE, @"left" : CR_POINTS_LEFT , @"right" : CR_POINTS_RIGHT, @"up" : CR_POINTS_UP, @"down" : CR_POINTS_DOWN, @"triangle" : CR_POINTS_TRIANGLE, @"heart" : CR_POINTS_HEART};
        NSError *error;
        
        if (![self.ringApp installGestures:gestures error:&error]) {
            //NSLog(@"%@", error);
            return;
        }
    }

    [self.ringApp setActiveGestureIdentifiers:@[@"circle", @"left", @"right", @"up", @"down", @"triangle", @"heart"]];
    [self.ringApp start];
    
    
    //  Sphero----------------------------------------------------------------------
    
    // Hook up for robot state changes
    [[RKRobotDiscoveryAgent sharedAgent] addNotificationObserver:self selector:@selector(handleRobotStateChangeNotification:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)appDidBecomeActive:(NSNotification*)notification {
    [RKRobotDiscoveryAgent startDiscovery];
    NSLog(@"appDidBecomeActive");
}


- (void)appWillResignActive:(NSNotification*)notification {
    [RKRobotDiscoveryAgent stopDiscovery];
    [RKRobotDiscoveryAgent disconnectAll];
    [_robot macroAbort];
    NSLog(@"appWillResignActive");
}


- (void)willEnterForeground {
    [self startAnimating];
    if (!_robot.isConnected) {
        [self handleConnecting];
        NSLog(@"willEnterForeground");
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UIEvent
- (IBAction)freeControlModePushed:(id)sender {
    [self freeControlMode];
}

- (IBAction)gestureControlModePushed:(id)sender {
    [self gestureControlMode];
}
- (IBAction)emergencyStopBtnPushed:(id)sender {
    [self emergencyStopMode];
}


- (void)freeControlMode {
    // Notify user this button tapped
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    // Animate this button
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.1 animations:^{
            self.freeControlModeButton.transform = CGAffineTransformMakeScale(1.1, 1.1);
        }completion:^(BOOL finished){
            self.freeControlModeButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
        }];
    });

    // Set CRRingModePoint & Change button images
    if (gestureMode == YES) {
        [self.ringApp setRingMode:CRRingModePoint];
        gestureMode = NO;
        _imageSet = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.gestureControlButton setImage:[UIImage imageNamed:@"mode_gesture.png"] forState:UIControlStateNormal];
            [self.freeControlModeButton setImage:[UIImage imageNamed:@"mode_free_touched.png"] forState:UIControlStateNormal];
        });
    } else if (gestureMode == NO) {
        [self.ringApp setRingMode:CRRingModeGesture];
        gestureMode = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.gestureControlButton setImage:[UIImage imageNamed:@"mode_gesture.png"] forState:UIControlStateNormal];
            [self.freeControlModeButton setImage:[UIImage imageNamed:@"mode_free.png"] forState:UIControlStateNormal];
        });
    }
}

- (void)gestureControlMode {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.1 animations:^{
            self.gestureControlButton.transform = CGAffineTransformMakeScale(1.1, 1.1);
        }completion:^(BOOL finished){
            self.gestureControlButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
        }];
    });

    [self.ringApp setRingMode:CRRingModeGesture];
    gestureMode = YES;
    
    if (_imageSet == NO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.gestureControlButton setImage:[UIImage imageNamed:@"mode_gesture_touched.png"] forState:UIControlStateNormal];
            [self.freeControlModeButton setImage:[UIImage imageNamed:@"mode_free.png"] forState:UIControlStateNormal];
            _imageSet = YES;
        });
    } else if (_imageSet == YES) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.gestureControlButton setImage:[UIImage imageNamed:@"mode_gesture.png"] forState:UIControlStateNormal];
            [self.freeControlModeButton setImage:[UIImage imageNamed:@"mode_free.png"] forState:UIControlStateNormal];
            _imageSet = NO;
        });
    }
}

- (void)emergencyStopMode {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.1 animations:^{
            self.emergencyStopButton.transform = CGAffineTransformMakeScale(1.1, 1.1);
            [self.emergencyStopButton setImage:[UIImage imageNamed:@"mode_stop_touched.png"] forState:UIControlStateNormal];
        }completion:^(BOOL finished){
            self.emergencyStopButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
            [self.emergencyStopButton setImage:[UIImage imageNamed:@"mode_stop.png"] forState:UIControlStateNormal];
        }];
    });

    [_robot enableCollisions:NO]; // Disable collision detention to avoid vibrating and flashing during aiming.
    
    _imageSet = NO;
    gestureMode = YES;
    [_robot stop];
    [self setHeading];
    [self.ringApp setRingMode:CRRingModeGesture];
    [self.freeControlModeButton setImage:[UIImage imageNamed:@"mode_free.png"] forState:UIControlStateNormal];
    [self.gestureControlButton setImage:[UIImage imageNamed:@"mode_gesture.png"] forState:UIControlStateNormal];
}


#pragma mark - Sphero
- (void)handleRobotStateChangeNotification:(RKRobotChangedStateNotification*)n {
    switch(n.type) {
        case RKRobotConnecting:{
            [self handleConnecting];
            //NSLog(@"RKRobotConnecting!!!!!!!!!!!!!!!!!!!!");
            break;
        }
        case RKRobotOnline: {
            // Do not allow the robot to connect if the application is not running
            RKConvenienceRobot *convenience = [RKConvenienceRobot convenienceWithRobot:n.robot];
            if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
                [convenience disconnect];
                return;
            }
            self.robot = convenience;
            _robot = [RKConvenienceRobot convenienceWithRobot:n.robot];
            [self handleConnected];
            
            //  These values are adjusted for small hits so that the Sphero won't keep moving to a wall.
            [_robot sendCommand:[[RKConfigureCollisionDetectionCommand alloc] initForMethod:RKCollisionDetectionMethod1 xThreshold:20 xSpeedThreshold:30 yThreshold:20 ySpeedThreshold:30 postTimeDeadZone:10]];

            [_robot enableCollisions:NO];
            //NSLog(@"RKRobotOnline!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            
            break;
        }
        case RKRobotDisconnected:
            [self handleDisconnected];
            self.robot = nil;
            [RKRobotDiscoveryAgent startDiscovery];
            //NSLog(@"RKrobotDisconnected!!!!!!!!!!!!!!!!!!!!!!");
            break;
        default:
            break;
    }
}

- (void)handleConnecting {
    // Handle when a robot is connecting here
}

- (void)handleConnected {
    [_calibrateHandler setRobot:_robot.robot];
    [_robot enableStablilization:YES];
    [_robot setBackLEDBrightness:1];
    [_robot addResponseObserver:self];
    [self sendSetDataStreamingCommand];
}

- (void)handleDisconnected {
    [_calibrateHandler setRobot:nil];
}

-(void)setHeading{
    // rotate the robot
    [_robot sendCommand:[RKRollCommand commandWithHeading:0 andVelocity:0.0]];
    
    // when user is done aiming - set the heading
    [_robot sendCommand:[RKSetHeadingCommand command]];
}

- (void)startConnectionTimer {
    NSTimer *t = timer;
    if (t == timer){
        [t invalidate];
        timer = nil;
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(checkConnection) userInfo:nil repeats:true];
    NSLog(@"startTimer");
}

- (void)stopConnectionTimer {
    NSTimer *t = timer;
    if (t == timer) {
        [t invalidate];
        timer = nil;
    }
    NSLog(@"stopTimer");
}

- (void)checkConnection {
    if (RKRobotConnecting) {
        self.statusBar.backgroundColor = [UIColor colorWithWhite:0.4 alpha:1.0];
        self.statusLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:30];
        self.statusLabel.text = @"DISCOVERING...";
        self.leftImage.image = [UIImage imageNamed:@"icon_discover"];
        //NSLog(@"DISCOVERING...");
    }
    
    if (_robot.isConnected) {
        self.statusBar.backgroundColor = [UIColor colorWithRed: 19.0/255.0 green: 158.0/255.0 blue: 254.0/255.0 alpha: 1.0];
        self.statusLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:30];
        self.statusLabel.text = @"CONNECTED";
        self.leftImage.image = [UIImage imageNamed:@"icon_sphero.png"];
        [self.openUrlBtn setEnabled:NO];
        //NSLog(@"CONNECTED");
    }
    
    if (!_robot.isConnected) {
        self.statusBar.backgroundColor = [UIColor colorWithRed: 225.0/255.0 green: 111.0/255.0 blue: 117.0/255.0 alpha: 1.0];
        self.statusLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:30];
        self.statusLabel.text = @"DISCONNECTED";
        self.leftImage.image = [UIImage imageNamed:@"icon_disconnected.png"];
        [self.openUrlBtn setEnabled:YES];
        
        UIViewAnimationOptions myOptions = UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAutoreverse;
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:myOptions
                         animations:^{
                             //[UIView setAnimationRepeatCount: 2.0];
                             _openUrlBtn.alpha = 0.2;
                         } completion: ^(BOOL finished){
                             _openUrlBtn.alpha = 1.0;
                         }];
        //NSLog(@"DISCONNECTED");
    }
}

#pragma mark - RingApp
- (void)deviceDidDisconnect {
    // Ring is disconnected
}

- (void)deviceDidInitialize {
    //  Ring is initialized
    _ringIsConnected = YES;
}

- (void)didReceiveEvent:(CRRingEvent)event {
    // Touch sensor is touched
    NSDate *now = [NSDate date];
    NSDate *past = [[NSUserDefaults standardUserDefaults] objectForKey:@"tapDate"];
    float elapsedTime = [now timeIntervalSinceDate:past];
    
    if (elapsedTime < 0.5) {
        if (gestureMode == YES) {
            [self freeControlMode];
        } else {
            [self gestureControlMode];
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:now forKey:@"tapDate"];
}

- (void)didReceiveGesture:(NSString *)identifier {
    [_robot enableCollisions:YES];  // Enable collision detection
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([@"left" isEqualToString:identifier]) {
            [_robot driveWithHeading:270.0 andVelocity:self.controlSpeed.value/10];
        
        }else if ([@"right" isEqualToString:identifier]) {
            [_robot driveWithHeading:90 andVelocity:self.controlSpeed.value/10];
        
        }else if ([@"up" isEqualToString:identifier]) {
            [_robot driveWithHeading:0.0 andVelocity:self.controlSpeed.value/10];
            
        }else if ([@"down" isEqualToString:identifier]) {
            [_robot driveWithHeading:180 andVelocity:self.controlSpeed.value/10];
            
        }else if ([@"circle" isEqualToString:identifier]) {
            
            NSString *file = [[NSBundle mainBundle] pathForResource:@"rainbow" ofType:@"sphero"];
            NSData *data = [NSData dataWithContentsOfFile:file];
            
            //saves a temporary macro (255) command thats includes the data packet
            [_robot macroSaveTemporary:data];
            [_robot macroRunAtId:255];
        
        }else if([@"heart" isEqualToString:identifier]){
            
            NSString *file = [[NSBundle mainBundle] pathForResource:@"rainbowSpin" ofType:@"sphero"];
            NSData *data = [NSData dataWithContentsOfFile:file];
            
            //saves a temporary macro (255) command thats includes the data packet
            [_robot macroSaveTemporary:data];
            [_robot macroRunAtId:255];
        } else {
            NSLog(@"this gesture is not found.");
        }
    });
}

- (void)didReceivePoint:(CGPoint)point {
    NSLog(@"start controlling");
    
    didReceivePoint = YES;
    [_robot enableCollisions:YES];

    //  Ring continues points(x, y) during this method
    NSLog(@"x = %f, y = %f", point.x, point.y);

    double x = point.x;
    double y = point.y;
    
    int ringAngle = (atan2(y, x)) * 180 / M_PI;
    //NSLog(@"ringAngle = %d", ringAngle);
    int orgSpheroAngle = (atan2(x, y)) * 180 / M_PI;
    spheroAngle = 0;
    
    //  Transform coordinate of Ring to that of Sphero
    if ((0 <= ringAngle && ringAngle < 90) || (-90 < ringAngle && ringAngle < 0)) {
        spheroAngle = orgSpheroAngle;
        //NSLog(@"spheroAngle14 = %d°", spheroAngle);
    }
    if ((90 <= ringAngle && ringAngle <= 180) || (-180 <= ringAngle && ringAngle <= -90)){
        spheroAngle = 360 - abs(orgSpheroAngle);
        //NSLog(@"spheroAngle23 = %d°", spheroAngle);
    }

    //  Set drive angle and speed
    [_robot driveWithHeading:spheroAngle andVelocity:self.controlSpeed.value/10];
    //NSLog(@"velocity = %f", self.controlSpeed.value/10);
}

- (void)didReceiveQuaternion:(CRQuaternion)quaternion {
    //  Quaternion mode
}

#pragma mark - Private
- (void)startAnimating {
    UIViewAnimationOptions leftImageOptions = UIViewAnimationOptionCurveLinear | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse;
    [UIView animateWithDuration:1.0
                          delay:0.0
                        options:leftImageOptions
                     animations:^{
                         _leftImage.transform = CGAffineTransformMakeScale(0.8, 0.8);
                         _leftImage.alpha = 0.5;
                     } completion: ^(BOOL finished){
                         _leftImage.transform = CGAffineTransformIdentity;
                         _leftImage.alpha = 1.0;
                     }];
    
    UIViewAnimationOptions circleBtnOptions = UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAutoreverse;
    [UIView animateWithDuration:0.4
                          delay:0.2
                        options:circleBtnOptions
                     animations:^{
                         [UIView setAnimationRepeatCount: 2.0];
                         circleBtn.alpha = 0.2;
                     } completion: ^(BOOL finished){
                         circleBtn.alpha = 1.0;
                     }];
}

- (void)slidervaluechanged:(id)sender{
    [self rotateUIImage:(_controlSpeed)];
}

- (void)rotateUIImage:(UISlider*)speed {
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    animation.toValue = [NSNumber numberWithFloat:M_PI * speed.value];
    animation.duration = 0.2;
    animation.repeatCount = MAXFLOAT;
    animation.cumulative = YES;
    [_spheroSpeedImageView.layer addAnimation:animation forKey:@"ImageViewRotation"];
}


- (void)sendSetDataStreamingCommand {
    // Requesting the Accelerometer X, Y, and Z filtered (in Gs)
    //            the IMU Angles roll, pitch, and yaw (in degrees)
    //            the Quaternion data q0, q1, q2, and q3 (in 1/10000) of a Q
    RKDataStreamingMask mask =  RKDataStreamingMaskAccelerometerFilteredAll |
    RKDataStreamingMaskIMUAnglesFilteredAll   |
    RKDataStreamingMaskQuaternionAll;
    [_robot enableSensors:mask atStreamingRate:10];
}


// Listens for the collisions, provided the class is registered for responses
- (void)handleAsyncMessage:(RKAsyncMessage *)message forRobot:(id<RKRobotBase>)robot {
    if( [message isKindOfClass:[RKCollisionDetectedAsyncData class]]) {
        RKCollisionDetectedAsyncData *collisionAsyncData = (RKCollisionDetectedAsyncData *) message;

/*
        float impactAccelX = [collisionAsyncData impactAcceleration].x;
        float impactAccelY = [collisionAsyncData impactAcceleration].y;
        float impactAccelZ = [collisionAsyncData impactAcceleration].z;
        float impactAxisX = [collisionAsyncData impactAxis].x;
        float impactAxisY = [collisionAsyncData impactAxis].y;
        float impactPowerX = [collisionAsyncData impactPower].x;
        float impactPowerY = [collisionAsyncData impactPower].y;
*/
        float impactSpeed = [collisionAsyncData impactSpeed];
 
        
/*
        //NSLog(@"impactAccelX = %f", impactAccelX);
        //NSLog(@"impactAccelY = %f", impactAccelY);
        //NSLog(@"impactAccelZ = %f", impactAccelZ);
        //NSLog(@"impactAxisX = %f", impactAxisX);
        //NSLog(@"impactAxisY = %f", impactAxisY);
        //NSLog(@"impactPowerX = %f", impactPowerX);
        //NSLog(@"impactPowerY = %f", impactPowerY);
*/
        NSLog(@"impactSpeed = %f", impactSpeed);
        
        //NSLog(@"Collision detected!");

        [_robot stop];

        [UIView animateWithDuration:0.2 animations:^{
            self.view.backgroundColor = [UIColor grayColor];
        }completion:^(BOOL finished){
            self.view.backgroundColor = [UIColor blackColor];
        }];
    }
}

- (IBAction)questionBtnPushed:(id)sender {
    SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"https://app.logbar.jp/public/ios/ring/sphero/help.html"]];
    [self presentViewController:safariVC animated:YES completion:nil];
}

- (IBAction)bluetoothBtnPushed:(id)sender {
    NSURL *url1 = [NSURL URLWithString:@"prefs:root=Bluetooth"];
    if ([[UIApplication sharedApplication] canOpenURL:url1]) {
        [[UIApplication sharedApplication] openURL:url1];
    }
}



@end
