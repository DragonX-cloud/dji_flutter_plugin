#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint dji.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'dji'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for DJI SDK.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://dragonx.cloud/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'info@dragonx.cloud' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'DJI-SDK-iOS', '~> 4.14'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 or arm64 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64 i386' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64 i386' }
  s.swift_version = '5.0'
end
