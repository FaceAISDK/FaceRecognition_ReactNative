# FaceAISDK React Native —— CocoaPods post_install 修复脚本
#
# 背景：
#   FaceAISDK_Core 是用 Swift 5.9.x 工具链预编译的 xcframework（开启了 library
#   evolution，随包提供 .swiftinterface）。当宿主 App 使用更新的工具链
#   （例如 Xcode 16 / Swift 6.1.x）时，编译器无法直接加载旧版本的二进制
#   .swiftmodule，会转而用 .swiftinterface 重新编译。该重新编译过程需要能解析
#   `import TensorFlowLite`，否则会报：
#
#     failed to build module 'FaceAISDK_Core'; this SDK is not supported by the
#     compiler (built with Apple Swift 5.9.2, compiler is Apple Swift 6.1.2)
#     cannot load underlying module for 'TensorFlowLite'
#
#   要让重新编译成功，需要满足两点（这两点都作用在「别的 Pod / 聚合 target」上，
#   无法只靠 react-native-face-sdk.podspec 配置自身 target 来完成，因此必须由宿主
#   工程在 Podfile 的 post_install 中调用本脚本）：
#
#     1. 让 TensorFlowLiteSwift 也以「发行模式」编译（BUILD_LIBRARY_FOR_DISTRIBUTION
#        = YES），从而产出可被 FaceAISDK_Core.swiftinterface 安全 import 的模块；
#     2. 把 Pods/Headers/Public 暴露给 SWIFT_INCLUDE_PATHS，并为 TensorFlowLite
#        建立 module.modulemap，使其 Clang 模块在 swiftinterface 重编译时可被发现。
#
# 用法（在宿主 App 的 ios/Podfile 中）：
#
#   require_relative '../node_modules/@faceaisdk/react-native-face-sdk/scripts/faceaisdk_post_install.rb'
#
#   post_install do |installer|
#     react_native_post_install(installer, config[:reactNativePath], :mac_catalyst_enabled => false)
#     faceaisdk_post_install(installer)   # <-- 加这一行
#   end

def faceaisdk_post_install(installer)
  headers_public = "#{installer.sandbox.root}/Headers/Public"

  installer.pods_project.targets.each do |target|
    # 1) 让 FaceAISDK_Core 依赖的 Swift 模块以发行模式编译，并跳过接口校验，
    #    避免不同工具链之间 .swiftinterface 校验失败。
    if ['TensorFlowLiteSwift', 'RCTSwiftUI', 'RCTSwiftUIWrapper'].include?(target.name)
      target.build_configurations.each do |bc|
        existing = bc.build_settings['OTHER_SWIFT_FLAGS'] || '$(inherited)'
        unless existing.include?('-no-verify-emitted-module-interface')
          bc.build_settings['OTHER_SWIFT_FLAGS'] = "#{existing} -no-verify-emitted-module-interface"
        end
      end
    end

    if target.name == 'TensorFlowLiteSwift'
      target.build_configurations.each do |bc|
        bc.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      end
    end

    # 2) 任何消费 FaceAISDK_Core 的 target 在重新编译其 .swiftinterface 时，都需要
    #    能找到 TensorFlowLite 的 Clang modulemap，因此把 Pods/Headers/Public 加入
    #    Swift 的 include 搜索路径（-Xcc 的 module-map 标志在此上下文不会被传播）。
    target.build_configurations.each do |bc|
      existing = bc.build_settings['SWIFT_INCLUDE_PATHS'] || '$(inherited)'
      unless existing.to_s.include?(headers_public)
        bc.build_settings['SWIFT_INCLUDE_PATHS'] = "#{existing} \"#{headers_public}\""
      end
    end
  end

  # 3) 为 TensorFlowLite 建立 module.modulemap 软链，使其 Clang 模块在
  #    FaceAISDK_Core.swiftinterface 处理阶段可被发现。
  tfl_dir = File.join(headers_public, 'TensorFlowLite')
  if Dir.exist?(tfl_dir)
    modulemap_link = File.join(tfl_dir, 'module.modulemap')
    source_modulemap = File.join(tfl_dir, 'TensorFlowLiteSwift.modulemap')
    if File.exist?(source_modulemap) && !File.exist?(modulemap_link)
      File.symlink('TensorFlowLiteSwift.modulemap', modulemap_link)
    end
  end

  # 4) 把同样的 SWIFT_INCLUDE_PATHS 写进聚合 target 的 xcconfig，确保宿主工程本体
  #    在链接 / 编译时也能发现上述模块。
  installer.aggregate_targets.each do |aggregate_target|
    aggregate_target.xcconfigs.each do |config_name, xcconfig|
      existing = xcconfig.attributes['SWIFT_INCLUDE_PATHS'] || '$(inherited)'
      unless existing.include?(headers_public)
        xcconfig.attributes['SWIFT_INCLUDE_PATHS'] = "#{existing} \"#{headers_public}\""
        xcconfig_path = aggregate_target.xcconfig_path(config_name)
        xcconfig.save_as(xcconfig_path)
      end
    end
  end
end
