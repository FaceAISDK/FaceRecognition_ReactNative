# FaceAISDK_Core 的公开 Swift interface 引用了 TensorFlowLite。
# 静态库集成时，Swift 重新编译该 interface 需要标准的 module.modulemap 名称。
# Core 的预编译代码使用 TensorFlowLite 的 library evolution ABI；消费端也必须
# 以同样模式编译 TensorFlowLiteSwift，否则 Interpreter.Options 会按错误布局传参，
# 在 Interpreter 初始化时触发 Swift runtime trap。宿主 App 和其他 Pods 不受影响。
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

      projects = [installer.pods_project]
      if installer.respond_to?(:pod_target_subprojects)
        projects.concat(installer.pod_target_subprojects || [])
      end
      flag = '-no-verify-emitted-module-interface'
      projects.uniq.each do |project|
        project.targets.each do |target|
          next unless target.name == 'TensorFlowLiteSwift' ||
                      target.name.start_with?('TensorFlowLiteSwift-')

          target.build_configurations.each do |configuration|
            configuration.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
            existing = configuration.build_settings['OTHER_SWIFT_FLAGS'] || '$(inherited)'
            if existing.is_a?(Array)
              unless existing.include?(flag)
                configuration.build_settings['OTHER_SWIFT_FLAGS'] = existing + [flag]
              end
            elsif !existing.split.include?(flag)
              configuration.build_settings['OTHER_SWIFT_FLAGS'] = "#{existing} #{flag}"
            end
          end
        end
      end

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
