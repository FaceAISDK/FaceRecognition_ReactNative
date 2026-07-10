Pod::Spec.new do |s|
  s.name             = 'TensorFlowLiteSwift'
  s.version          = '2.17.0'
  s.authors          = 'Google Inc.'
  s.license          = { :type => 'Apache' }
  s.homepage         = 'https://github.com/tensorflow/tensorflow'
  s.source           = { :http => 'https://github.com/nicklama/tensorflow/archive/refs/tags/v2.17.0.tar.gz' }
  s.summary          = 'TensorFlow Lite for Swift'
  s.description      = 'TensorFlow Lite is TensorFlow\'s lightweight solution for Swift developers.'
  s.cocoapods_version = '>= 1.9.0'
  s.ios.deployment_target = '12.0'
  s.swift_version    = '5.0'
  s.module_name      = 'TensorFlowLite'
  s.static_framework = true

  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  s.default_subspecs = 'Core'

  s.subspec 'Privacy' do |ss|
    ss.resource_bundles = {
      'TensorFlowLite' => 'tensorflow/lite/swift/PrivacyInfo.xcprivacy'
    }
  end

  s.subspec 'Core' do |ss|
    ss.dependency 'TensorFlowLiteC', '2.17.0'
    ss.dependency 'TensorFlowLiteSwift/Privacy', '2.17.0'
    ss.source_files = 'tensorflow/lite/swift/Sources/*.swift'
    ss.exclude_files = 'tensorflow/lite/swift/Sources/{CoreML,Metal}Delegate.swift'
  end
end
