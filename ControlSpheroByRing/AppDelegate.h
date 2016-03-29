#import <UIKit/UIKit.h>
#import <RobotKit/RobotKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) id<RKRobotBase> robot;


@end

