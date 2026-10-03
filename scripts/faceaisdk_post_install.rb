# FaceAISDK_Core 的公开 Swift interface 引用了 TensorFlowLite。
# 静态库集成时，Swift 重新编译该 interface 需要标准的 module.modulemap 名称。
# podspec 提供插件自身的 Swift 搜索路径，本文件仅补齐 modulemap。
module FaceAISDK
  module CocoaPodsIntegration
    module PostInstall
      def post_install!(installer)
        executed = super
        if installer.pod_targets.any? { |target| target.pod_name == 'react-native-face-sdk' }
          FaceAISDK::CocoaPodsIntegration.apply(installer)
        end
        executed
      end
    end

    def self.register!
      Pod::Podfile.prepend(PostInstall) unless Pod::Podfile.ancestors.include?(PostInstall)
    end

    def self.apply(installer)
      return unless installer.pods_project

      tfl_dir = File.join(installer.sandbox.root, 'Headers', 'Public', 'TensorFlowLite')
      source = File.join(tfl_dir, 'TensorFlowLiteSwift.modulemap')
      link = File.join(tfl_dir, 'module.modulemap')
      if File.exist?(source) && !File.exist?(link) && !File.symlink?(link)
        File.symlink('TensorFlowLiteSwift.modulemap', link)
      end
    end
  end
end

# 兼容旧版 Podfile 的手动调用；podspec 已自动注册，接入方可以移除旧调用。
def faceaisdk_post_install(installer)
  FaceAISDK::CocoaPodsIntegration.apply(installer)
end
