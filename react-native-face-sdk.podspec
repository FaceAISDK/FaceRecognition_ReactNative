require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = 'react-native-face-sdk'
  s.version      = package['version']
  s.summary      = package['description']
  s.license      = package['license']
  s.homepage     = 'https://github.com/FaceAISDK/FaceRecognition_ReactNative'
  s.authors      = { 'FaceAISDK' => 'support@faceaisdk.example' }
  s.platforms    = { :ios => '15.5' }
  s.source       = { :git => 'https://github.com/FaceAISDK/FaceRecognition_ReactNative.git', :tag => s.version.to_s }
  s.source_files = 'ios/**/*.{h,m,mm,swift}'
  s.exclude_files = [
    'ios/Pods/**/*',
    'ios/build/**/*'
  ]
  s.resources    = [
    'ios/Resources/*.lproj'
  ]
  s.requires_arc = true
  s.swift_version = '5.9'
  s.module_name  = 'FaceAISDKReactNative'

  # 本插件自身（消费 FaceAISDK_Core 的 target）在更高版本工具链上编译时，需要重新
  # 编译 FaceAISDK_Core 的 .swiftinterface，而该过程必须能发现 TensorFlowLite 的
  # Clang modulemap。这里把 Pods/Headers/Public 暴露给本 target 的 Swift include
  # 搜索路径。注意：对 TensorFlowLiteSwift / 聚合 target 的修复无法在 podspec 内完成，
  # 宿主工程仍需在 Podfile 的 post_install 中调用 scripts/faceaisdk_post_install.rb。
  s.pod_target_xcconfig = {
    'SWIFT_INCLUDE_PATHS' => '$(inherited) "${PODS_ROOT}/Headers/Public"',
    'OTHER_SWIFT_FLAGS'   => '$(inherited) -no-verify-emitted-module-interface'
  }

  s.dependency 'React-Core'
  s.dependency 'FaceAISDK_Core', '2026.07.22'
end
