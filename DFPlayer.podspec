Pod::Spec.new do |s|
  
  s.name         = "DFPlayer"
  s.version      = "1.0.0"
  s.summary      = "A simple and flexible iOS audio playback module."
  s.homepage     = "https://github.com/ihoudf/DFPlayer"
  s.license      = "MIT"
  s.author       = { "ihoudf" => "188816190@qq.com" }
  s.platform     = :ios
  s.ios.deployment_target = "7.0"
  s.source       = { :git => "https://github.com/ihoudf/DFPlayer.git", :tag => s.version }
  s.source_files = 'DFPlayer/**/*.{h,m}'
  s.resource     = 'DFPlayer/DFPlayer.bundle'
  s.requires_arc = true
  s.frameworks = 'UIKit','AVFoundation'
end

