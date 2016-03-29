#import <UIKit/UIKit.h>
#import <CoreRing/CoreRing.h>
#import <RobotKit/RobotKit.h>
#import <RobotUIKit/RobotUIKit.h>

@interface ViewController : UIViewController <RKResponseObserver>

@property (nonatomic, strong) CRApplication *ringApp;
@property (strong, nonatomic) RKConvenienceRobot* robot;
@property (strong, nonatomic) RUICalibrateButtonGestureHandler *calibrateHandler;
@property (strong, nonatomic) RUICalibrationView *calibrationView;
@property (strong, nonatomic) RUICalibrateOneTouchOverlayView *overLayView;
@property (weak, nonatomic) IBOutlet UIView *statusBar;
@property (weak, nonatomic) IBOutlet UIImageView *leftImage;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIImageView *myView;
@property (weak, nonatomic) IBOutlet UIButton *freeControlModeButton;
@property (weak, nonatomic) IBOutlet UIButton *gestureControlButton;
@property (weak, nonatomic) IBOutlet UIButton *emergencyStopButton;
@property (weak, nonatomic) IBOutlet UIImageView *spheroSpeedImageView;
@property (weak, nonatomic) IBOutlet UIButton *openUrlBtn;
@property (weak, nonatomic) IBOutlet UISlider *controlSpeed;

@end

