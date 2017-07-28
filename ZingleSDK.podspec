#
# Be sure to run `pod lib lint ZingleSDK.podspec' to ensure this is a
# valid spec before submitting.

Pod::Spec.new do |s|
  s.name             = "ZingleSDK"
  s.version          = "1.1.0"
  s.summary          = "Zingle iOS SDK"

  s.description      = <<-DESC
    Zingle is a multi-channel communications platform that allows the sending, receiving and automating of conversations between a Business and a Customer. Zingle is typically interacted with by Businesses via a web browser to manage these conversations with their customers. The Zingle API provides functionality to developers to act on behalf of either the Business or the Customer. The Zingle iOS SDK provides mobile application developers an easy-to-use layer on top of the Zingle API.

    To view the latest API documentation, please refer to: https://github.com/Zingle/rest-api/
  DESC

  s.homepage         = "https://github.com/Zingle/ios-sdk"
  s.screenshots      = "https://raw.githubusercontent.com/Zingle/ios-sdk/master/Assets/message_layout.png"
  s.license          = 'MIT'
  s.author           = { "Jason Neel" => "jneel@zingleme.com" }
  s.source           = { :git => "https://github.com/Zingle/ios-sdk.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/zingleme'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*.{h,m}'
  s.resources = ['Pod/Assets/**/*', 'Pod/Classes/UI/**/*.{xib,storyboard}']

  s.dependency 'AFNetworking'
  s.dependency 'JVFloatLabeledTextField'  
  s.dependency 'Mantle'
  s.dependency 'CocoaLumberjack', '2.3'
  s.dependency 'JSQMessagesViewController'
  s.dependency 'Analytics', '~> 3.0'
  s.dependency 'MGSwipeTableCell'
  s.dependency 'SDWebImage/GIF'
  s.dependency 'Socket.IO-Client-Swift'
  s.dependency 'Shimmer'
end
