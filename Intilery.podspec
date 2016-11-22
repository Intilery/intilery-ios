Pod::Spec.new do |s|
  s.name         = 'Intilery'
  s.version      = '0.0.6'
  s.summary      = 'iPhone tracking library for Intilery Analytics'
  s.homepage     = 'https://intilery.com'
  s.license      = 'Apache License, Version 2.0'
  s.author       = { 'Intilery.com Ltd' => 'support@intilery.com' }
  s.source       = { :git => 'https://github.com/intilery/intilery-ios.git', :tag => "v#{s.version}" }
  s.requires_arc = true
  s.default_subspec = 'Intilery'
  s.platforms = { :ios => '7.0' }

  s.subspec 'Intilery' do |ss|
    ss.source_files  = 'Intilery/**/*.{m,h}', 'Intilery/**/*.swift'
    ss.resources 	 = []
    ss.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration'
    ss.libraries = 'icucore'
    ss.platform = :ios
  end
end
