#import "DjiPlugin.h"
#if __has_include(<dji/dji-Swift.h>)
#import <dji/dji-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "dji-Swift.h"
#endif

@implementation DjiPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftDjiPlugin registerWithRegistrar:registrar];
}
@end
