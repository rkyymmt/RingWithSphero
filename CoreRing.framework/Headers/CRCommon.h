#import <UIKit/UIKit.h>


// Ring

typedef NS_ENUM(int, CRRingEvent) {
  CRRingEventTap,
  CRRingEventLongPress
};

typedef NS_ENUM(int, CRRingMode) {
  CRRingModeGesture,
  CRRingModeQuaternion,
  CRRingModePoint,
  CRRingModeEvent
};

typedef struct {
  float w;
  float x;
  float y;
  float z;
} CRQuaternion;


// Error

#define CR_ERROR_DOMAIN @"jp.logbar.corering"

typedef NS_ENUM(int, CRErrorCode) {
  CRErrorCodeUnknown = -1,
  CRErrorCodeSuccess,
  CRErrorCodeInvalidPoints,
  CRErrorCodeSQLiteError
};


// Gesture

#define CR_POINTS_LEFT     @"60005bff58ff55ff51ff4cff48ff42ff3cff35ff2eff28ff20ff18ff0fff07fffffff6ffed00e800e300da00d000c700be00b600af01aa01a601a301a202a102"
#define CR_POINTS_RIGHT    @"a703ab02af02b402bc02c402ce02d402da02e002e702ed02f402000206020d02190225022f023801400147014c005100540056005800590059005a005aff5afe"
#define CR_POINTS_UP       @"00ab00b000b400b900bd00c200c800ce00d400db00e200ea00ee00f300fc0004000d0016001f0027002f0035003c00410046004d005200550056005600550154"
#define CR_POINTS_DOWN     @"01570150024a0244023f023a0235022e0228022002190210020702ff02f701f001ea01e101d800d200cd00c800c300be00b900b300ae00ac00ab00aaffaaffab"
#define CR_POINTS_CIRCLE   @"d7a5cba7bcb2b0c3a7d8a3e5a1f3a222a62fac3bb347bc51d260df65f96b1b6b2668395d4851533f5c2b601960fc5ff05bd557c94cb744ae32a1279b1b97f89a"
#define CR_POINTS_HEART    @"ebd5e6d9e1e0dce7d7efd2f8cc04c80fc519c525c530c53ace48d34ede54e854f04af838fe1cff1c0531215135523d403d2b3c1c310319e20ed6f7c3d8afd2ad"
#define CR_POINTS_TRIANGLE @"e611e20ddc06d4fac9ebc0dcb9d1a5b5a3b0a1aea0adb5adbcadc8addaad09b036b253b25fb361b460b45db759bb52c349cf3de12ff81f110d28fe3cf050ee54"
#define CR_POINTS_PIGTAIL  @"abe4a9d6aec2b4b8c3accfaadaaae6b1f2befccd0ef6140c16201731174f0c57fd57f454e745e338e314e403ebe5f0d700c009b915b521b432b540bf4dcb57f5"
#define CR_POINTS_ONE      @"f72cf730f730f733f838fb3dfd430047024b054f0650075007500750074f074f084c0847093c092b091f091209f909e109cc09be09b509b109af09af0aaf0aaf"
#define CR_POINTS_TWO      @"daf3d2f6cff8cdfcc804c709c719c924ce2fd439d940e047e84bf24dfd4d064c163f1f2f200d1b0013f2fed7dbbac7b2cab2ccb2e4b7f5b926bd2fbe39be3abe"
#define CR_POINTS_THREE    @"d516d01cd025d02cd536db40e448ee4ef851045210511a4b243b1d1b0b0cef020e0623fc2fef31d72ec825bd18b308aefaadeeade4b0dcb7d6c1d3c8d1cdd0d4"
#define CR_POINTS_FOUR     @"25591f551f5513490138ef25cc02c1f7b9f1b6edb4ecc6eeedf017f037f142f348f44cf54df64df74df845fe4001360d2c1725172417231722ef1fbb1fa61fa7"


// Helper

@interface CRCommon : NSObject

+ (UIImage *)imageWithPoints:(NSString *)points
                       width:(CGFloat)width
                   lineColor:(UIColor *)lineColor
                  pointColor:(UIColor *)pointColor;

@end
