#
# Be sure to run `pod lib lint SwiftCamScanner.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = 'SwiftCamScanner'
s.version          = '0.2.0'
s.summary          = 'A document scanner that uses OpenCV, in Swift'
s.description      = 'Creates scanner apps that can detect rectangles, crop and transformation selected regions'
s.homepage         = 'https://github.com/Srinija/SwiftCamScanner'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = 'Srinija Ammapalli'
s.source           = { :git => 'https://github.com/Srinija/SwiftCamScanner.git', :tag => s.version.to_s }
s.ios.deployment_target = '8.0'
s.source_files = 'SwiftCamScanner/Classes/**/*'
# s.public_header_files = 'Pod/Classes/**/*.h'
s.dependency 'OpenCV'
s.frameworks = 'UIKit'
end
