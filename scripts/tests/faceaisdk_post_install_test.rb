require 'minitest/autorun'
require 'cocoapods'
require 'tmpdir'
require 'fileutils'
require 'ostruct'

# Read the real podspec: the host must not require the integration script itself.
SDK_ROOT = File.expand_path('../..', __dir__)
Pod::Specification.from_file(File.join(SDK_ROOT, 'react-native-face-sdk.podspec'))

class FaceAISDKPostInstallTest < Minitest::Test
  Integration = FaceAISDK::CocoaPodsIntegration
  Installer = Struct.new(:pod_targets, :pods_project, :pod_target_subprojects, :sandbox, :aggregate_targets)
  Aggregate = Struct.new(:xcconfigs, :root) do
    def xcconfig_path(name)
      Pathname.new(File.join(root, "#{name}.xcconfig"))
    end
  end

  def setup
    @root = Dir.mktmpdir('faceaisdk-pods-')
    @project = Xcodeproj::Project.new(File.join(@root, 'Pods.xcodeproj'))
    @tfl = @project.new_target(:static_library, 'TensorFlowLiteSwift', :ios, '15.5')
    @react = @project.new_target(:static_library, 'RCTSwiftUI', :ios, '15.5')
    @xcconfig = Xcodeproj::Config.new('SWIFT_INCLUDE_PATHS' => '$(inherited) "custom/path"')
    @installer = Installer.new(
      [OpenStruct.new(:pod_name => 'react-native-face-sdk')], @project, [],
      OpenStruct.new(:root => Pathname.new(@root)), [Aggregate.new({ 'Debug' => @xcconfig }, @root)]
    )
    @tfl_headers = File.join(@root, 'Headers', 'Public', 'TensorFlowLite')
    FileUtils.mkdir_p(@tfl_headers)
    File.write(File.join(@tfl_headers, 'TensorFlowLiteSwift.modulemap'), 'module TensorFlowLite {}')
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_podspec_registers_once
    2.times { Pod::Specification.from_file(File.join(SDK_ROOT, 'react-native-face-sdk.podspec')) }
    assert_equal 1, Pod::Podfile.ancestors.count(Integration::PostInstall)
  end

  def test_host_callback_runs_before_sdk_configuration_and_settings_are_preserved
    tfl = @tfl
    called = false
    podfile = Pod::Podfile.new do
      post_install do |_installer|
        called = true
        tfl.build_configurations.each do |config|
          config.build_settings['OTHER_SWIFT_FLAGS'] = ['$(inherited)', '-DHOST_FLAG']
          config.build_settings['SWIFT_INCLUDE_PATHS'] = ['$(inherited)', 'custom/path']
        end
      end
    end

    assert podfile.post_install!(@installer)
    assert called
    @tfl.build_configurations.each do |config|
      assert_equal ['$(inherited)', '-DHOST_FLAG', '-no-verify-emitted-module-interface'],
                   config.build_settings['OTHER_SWIFT_FLAGS']
      assert_equal ['$(inherited)', 'custom/path'], config.build_settings['SWIFT_INCLUDE_PATHS']
      assert_equal 'YES', config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION']
    end
    @react.build_configurations.each do |config|
      assert_nil config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION']
      assert_nil config.build_settings['OTHER_SWIFT_FLAGS']
      assert_nil config.build_settings['SWIFT_INCLUDE_PATHS']
    end
    assert_equal 'TensorFlowLiteSwift.modulemap', File.readlink(File.join(@tfl_headers, 'module.modulemap'))
    assert_equal '$(inherited) "custom/path"', @xcconfig.attributes['SWIFT_INCLUDE_PATHS']
    refute File.exist?(File.join(@root, 'Debug.xcconfig'))
  end

  def test_modulemap_fix_works_without_host_callback
    refute Pod::Podfile.new.post_install!(@installer)
    assert File.exist?(File.join(@tfl_headers, 'module.modulemap'))
  end

  def test_legacy_and_automatic_calls_are_idempotent
    podfile = Pod::Podfile.new do
      post_install { |installer| faceaisdk_post_install(installer) }
    end
    2.times { podfile.post_install!(@installer) }
    assert_equal 'TensorFlowLiteSwift.modulemap', File.readlink(File.join(@tfl_headers, 'module.modulemap'))
    assert_nil @tfl.build_configurations.first.build_settings['SWIFT_INCLUDE_PATHS']
    @tfl.build_configurations.each do |config|
      assert_equal 'YES', config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION']
      assert_equal '$(inherited) -no-verify-emitted-module-interface',
                   config.build_settings['OTHER_SWIFT_FLAGS']
    end
    assert_equal '$(inherited) "custom/path"', @xcconfig.attributes['SWIFT_INCLUDE_PATHS']
  end

  def test_projects_without_sdk_are_untouched
    @installer.pod_targets = [OpenStruct.new(:pod_name => 'OtherPod')]
    settings = @tfl.build_configurations.first.build_settings.dup
    refute Pod::Podfile.new.post_install!(@installer)
    assert_equal settings, @tfl.build_configurations.first.build_settings
    refute File.exist?(File.join(@tfl_headers, 'module.modulemap'))
    refute File.exist?(File.join(@root, 'Debug.xcconfig'))
  end

  def test_multiple_pod_projects_and_variant_targets
    subproject = Xcodeproj::Project.new(File.join(@root, 'TensorFlowLiteSwift.xcodeproj'))
    target = subproject.new_target(:static_library, 'TensorFlowLiteSwift-variant', :ios, '15.5')
    @installer.pod_target_subprojects = [subproject]
    Pod::Podfile.new.post_install!(@installer)
    settings = target.build_configurations.first.build_settings
    assert_equal 'YES', settings['BUILD_LIBRARY_FOR_DISTRIBUTION']
    assert_equal '$(inherited) -no-verify-emitted-module-interface', settings['OTHER_SWIFT_FLAGS']
    assert_nil settings['SWIFT_INCLUDE_PATHS']
    assert File.exist?(File.join(@tfl_headers, 'module.modulemap'))
  end

  def test_skipping_project_generation_and_missing_modulemap
    @installer.pods_project = nil
    refute Pod::Podfile.new.post_install!(@installer)
    refute File.exist?(File.join(@tfl_headers, 'module.modulemap'))
    @installer.pods_project = @project
    File.delete(File.join(@tfl_headers, 'TensorFlowLiteSwift.modulemap'))
    Pod::Podfile.new.post_install!(@installer)
    refute File.exist?(File.join(@tfl_headers, 'module.modulemap'))
  end

  def test_existing_modulemap_is_preserved
    path = File.join(@tfl_headers, 'module.modulemap')
    File.write(path, 'custom modulemap')
    Pod::Podfile.new.post_install!(@installer)
    assert_equal 'custom modulemap', File.read(path)
    File.delete(path)
    File.symlink('missing.modulemap', path)
    Pod::Podfile.new.post_install!(@installer)
    assert_equal 'missing.modulemap', File.readlink(path)
  end

  def test_host_callback_errors_are_propagated
    podfile = Pod::Podfile.new do
      post_install { |_installer| raise 'Host callback failed' }
    end
    error = assert_raises(RuntimeError) { podfile.post_install!(@installer) }
    assert_equal 'Host callback failed', error.message
    refute File.exist?(File.join(@tfl_headers, 'module.modulemap'))
  end

  def test_real_local_install_creates_modulemap_without_changing_other_targets
    # Use local dependency stubs to exercise CocoaPods generation without downloads.
    config = Pod::Config.instance
    previous_root = config.installation_root
    previous_silent = config.silent
    config.installation_root = Pathname.new(@root)
    config.silent = true
    {
      'React-Core' => ['0.84.0', nil],
      'FaceAISDK_Core' => ['2026.09.22', "s.dependency 'TensorFlowLiteSwift', '2.17.0'"],
      'TensorFlowLiteSwift' => ['2.17.0', "s.module_name = 'TensorFlowLite'"]
    }.each do |name, (version, extra)|
      path = File.join(@root, name)
      FileUtils.mkdir_p(path)
      File.write(File.join(path, 'Stub.swift'), 'public struct Stub {}')
      File.write(File.join(path, "#{name}.podspec"), <<~RUBY)
        Pod::Spec.new do |s|
          s.name = '#{name}'
          s.version = '#{version}'
          s.summary = 'Local installation fixture'
          s.homepage = 'https://example.com'
          s.license = 'MIT'
          s.author = 'Fixture'
          s.source = { :git => 'https://example.com/fixture.git' }
          s.platform = :ios, '15.5'
          s.swift_version = '5.9'
          s.source_files = '*.swift'
          #{extra}
        end
      RUBY
    end
    # There is deliberately no require_relative or faceaisdk_post_install call.
    File.write(File.join(@root, 'Podfile'), <<~RUBY)
      install! 'cocoapods', :integrate_targets => false
      platform :ios, '15.5'
      target 'Fixture' do
        pod 'react-native-face-sdk', :path => #{SDK_ROOT.inspect}
        pod 'React-Core', :path => './React-Core'
        pod 'FaceAISDK_Core', :path => './FaceAISDK_Core'
        pod 'TensorFlowLiteSwift', :path => './TensorFlowLiteSwift'
      end
      post_install do |installer|
        installer.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
            config.build_settings['OTHER_SWIFT_FLAGS'] = '$(inherited) -DHOST_FLAG'
          end
        end
      end
    RUBY
    sandbox = Pod::Sandbox.new(File.join(@root, 'Pods'))
    podfile = Pod::Podfile.from_file(File.join(@root, 'Podfile'))
    installer = Pod::Installer.new(sandbox, podfile)
    installer.install!

    saved = Xcodeproj::Project.open(File.join(@root, 'Pods', 'Pods.xcodeproj'))
    tfl = saved.targets.find { |target| target.name == 'TensorFlowLiteSwift' }
    refute_nil tfl
    tfl.build_configurations.each do |build_config|
      assert_equal 'YES', build_config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION']
      assert_equal '$(inherited) -DHOST_FLAG -no-verify-emitted-module-interface',
                   build_config.build_settings['OTHER_SWIFT_FLAGS']
      assert_nil build_config.build_settings['SWIFT_INCLUDE_PATHS']
    end
    saved.targets.reject { |target| target == tfl }.each do |target|
      target.build_configurations.each do |build_config|
        assert_equal '$(inherited) -DHOST_FLAG', build_config.build_settings['OTHER_SWIFT_FLAGS']
        assert_nil build_config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION']
      end
    end
    assert File.exist?(File.join(sandbox.root, 'Headers', 'Public', 'TensorFlowLite', 'module.modulemap'))
    sdk_config = File.join(sandbox.root, 'Target Support Files', 'react-native-face-sdk', 'react-native-face-sdk.debug.xcconfig')
    assert_includes File.read(sdk_config), '${PODS_ROOT}/Headers/Public'
    aggregate_config = File.join(sandbox.root, 'Target Support Files', 'Pods-Fixture', 'Pods-Fixture.debug.xcconfig')
    swift_paths = File.readlines(aggregate_config).find { |line| line.start_with?('SWIFT_INCLUDE_PATHS =') }
    refute_nil swift_paths
    refute_includes swift_paths, '${PODS_ROOT}/Headers/Public'
  ensure
    config.installation_root = previous_root
    config.silent = previous_silent
  end
end
