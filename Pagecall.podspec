#
# Be sure to run `pod lib lint Pagecall.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Pagecall'
  s.version          = '0.0.30' # Update `version` field of PagecallWebView as you change this
  s.summary          = 'Pagecall WebView: Enhanced Voice Communication via Custom WebView based on WKWebView'

  s.description      = 'Pagecall-ios-sdk provides PagecallWebView, a custom WebView based on WKWebView that extends its functionality by adding a proprietary JavaScript Bridge to improve voice communication features. This enables customers to offer an enhanced voice communication experience. By utilizing PagecallWebView, powerful voice communication features can be easily integrated in place of the existing WKWebView.'

  s.homepage         = 'https://github.com/pagecall/pagecall-ios-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'author' => 'support@pagecall.com' }
  s.source           = { :git => 'https://github.com/pagecall/pagecall-ios-sdk.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.swift_version = '5.0'
  s.vendored_frameworks =  [
    'Binaries/Mediasoup.xcframework',
    'Binaries/WebRTC.xcframework'
  ]
  s.source_files = 'Sources/PagecallSDK/**/*.{swift,h,m}'
  s.resource = 'Sources/PagecallSDK/PagecallNative.js'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'

  s.default_subspec = :none

  s.subspec 'Log' do |subspec|
    subspec.dependency 'Sentry', '~> 8.46.0'
  end
end
