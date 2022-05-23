// Autogenerated from Pigeon (v1.0.19), do not edit directly.
// See also: https://pub.dev/packages/pigeon
#import <Foundation/Foundation.h>
@protocol FlutterBinaryMessenger;
@protocol FlutterMessageCodec;
@class FlutterError;
@class FlutterStandardTypedData;

NS_ASSUME_NONNULL_BEGIN

@class FLTVersion;
@class FLTBattery;
@class FLTDrone;
@class FLTMedia;
@class FLTStream;

@interface FLTVersion : NSObject
+ (instancetype)makeWithString:(nullable NSString *)string;
@property(nonatomic, copy, nullable) NSString * string;
@end

@interface FLTBattery : NSObject
+ (instancetype)makeWithLevel:(nullable NSNumber *)level;
@property(nonatomic, strong, nullable) NSNumber * level;
@end

@interface FLTDrone : NSObject
+ (instancetype)makeWithStatus:(nullable NSString *)status
    batteryPercent:(nullable NSNumber *)batteryPercent
    altitude:(nullable NSNumber *)altitude
    latitude:(nullable NSNumber *)latitude
    longitude:(nullable NSNumber *)longitude
    speed:(nullable NSNumber *)speed
    roll:(nullable NSNumber *)roll
    pitch:(nullable NSNumber *)pitch
    yaw:(nullable NSNumber *)yaw;
@property(nonatomic, copy, nullable) NSString * status;
@property(nonatomic, strong, nullable) NSNumber * batteryPercent;
@property(nonatomic, strong, nullable) NSNumber * altitude;
@property(nonatomic, strong, nullable) NSNumber * latitude;
@property(nonatomic, strong, nullable) NSNumber * longitude;
@property(nonatomic, strong, nullable) NSNumber * speed;
@property(nonatomic, strong, nullable) NSNumber * roll;
@property(nonatomic, strong, nullable) NSNumber * pitch;
@property(nonatomic, strong, nullable) NSNumber * yaw;
@end

@interface FLTMedia : NSObject
+ (instancetype)makeWithFileName:(nullable NSString *)fileName
    fileUrl:(nullable NSString *)fileUrl
    fileIndex:(nullable NSNumber *)fileIndex;
@property(nonatomic, copy, nullable) NSString * fileName;
@property(nonatomic, copy, nullable) NSString * fileUrl;
@property(nonatomic, strong, nullable) NSNumber * fileIndex;
@end

@interface FLTStream : NSObject
+ (instancetype)makeWithData:(nullable FlutterStandardTypedData *)data;
@property(nonatomic, strong, nullable) FlutterStandardTypedData * data;
@end

/// The codec used by FLTDjiHostApi.
NSObject<FlutterMessageCodec> *FLTDjiHostApiGetCodec(void);

@protocol FLTDjiHostApi
/// @return `nil` only when `error != nil`.
- (nullable FLTVersion *)getPlatformVersionWithError:(FlutterError *_Nullable *_Nonnull)error;
/// @return `nil` only when `error != nil`.
- (nullable FLTBattery *)getBatteryLevelWithError:(FlutterError *_Nullable *_Nonnull)error;
/// @return `nil` only when `error != nil`.
- (void)registerAppWithError:(FlutterError *_Nullable *_Nonnull)error;
/// @return `nil` only when `error != nil`.
- (void)connectDroneWithError:(FlutterError *_Nullable *_Nonnull)error;
/// @return `nil` only when `error != nil`.
- (void)disconnectDroneWithError:(FlutterError *_Nullable *_Nonnull)error;
/// @return `nil` only when `error != nil`.
- (void)delegateDroneWithError:(FlutterError *_Nullable *_Nonnull)error;
/// @return `nil` only when `error != nil`.
- (void)takeOffWithError:(FlutterError *_Nullable *_Nonnull)error;
/// @return `nil` only when `error != nil`.
- (void)landWithError:(FlutterError *_Nullable *_Nonnull)error;
/// @return `nil` only when `error != nil`.
- (void)startFlightJson:(NSString *)flightJson error:(FlutterError *_Nullable *_Nonnull)error;
/// @return `nil` only when `error != nil`.
- (nullable NSArray<FLTMedia *> *)getMediaListWithError:(FlutterError *_Nullable *_Nonnull)error;
/// @return `nil` only when `error != nil`.
- (nullable NSString *)downloadMediaFileIndex:(NSNumber *)fileIndex error:(FlutterError *_Nullable *_Nonnull)error;
/// @return `nil` only when `error != nil`.
- (nullable NSNumber *)deleteMediaFileIndex:(NSNumber *)fileIndex error:(FlutterError *_Nullable *_Nonnull)error;
/// @return `nil` only when `error != nil`.
- (nullable NSString *)videoFeedStartWithError:(FlutterError *_Nullable *_Nonnull)error;
/// @return `nil` only when `error != nil`.
- (nullable NSString *)videoFeedStopWithError:(FlutterError *_Nullable *_Nonnull)error;
@end

extern void FLTDjiHostApiSetup(id<FlutterBinaryMessenger> binaryMessenger, NSObject<FLTDjiHostApi> *_Nullable api);

/// The codec used by FLTDjiFlutterApi.
NSObject<FlutterMessageCodec> *FLTDjiFlutterApiGetCodec(void);

@interface FLTDjiFlutterApi : NSObject
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger;
- (void)setStatusDrone:(FLTDrone *)drone completion:(void(^)(NSError *_Nullable))completion;
- (void)sendVideoStream:(FLTStream *)stream completion:(void(^)(NSError *_Nullable))completion;
@end
NS_ASSUME_NONNULL_END
