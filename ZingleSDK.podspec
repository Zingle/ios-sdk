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
  
  s.ios.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  s.requires_arc = true
  
  s.default_subspec = 'Core'
  
  s.subspec 'Core' do |core|
  
	  # Cross-platform source files (non-UI)
	  s.source_files = [
		  'Pod/Classes/*.{h,m}',
		  'Pod/Classes/Clients/**/*.{h,m}',		
		  'Pod/Classes/Logging/**/*.{h,m}',
		  'Pod/Classes/Models/**/*.{h,m}',
		  'Pod/Classes/NetworkDiagnostics/**/*.{h,m}',
		  'Pod/Classes/UI/ViewModels/**/*.{h,m}',
		  'Pod/Classes/ValueTransformers/**/*.{h,m}'
	  ]

	  # iOS-specific source and resource files (all source/resource files not added above)
	  s.ios.source_files = 'Pod/Classes/**/*.{h,m}'
	  s.ios.resources = ['Pod/Assets/**/*', 'Pod/Classes/UI/**/*.{xib,storyboard}']

	  # Cross-platform dependencies
	  s.dependency 'AFNetworking/NSURLSession'
	  s.dependency 'Mantle'
	  s.dependency 'Socket.IO-Client-Swift', '~> 13.0'
  
	  # iOS-specific dependencies
	  s.ios.dependency 'JVFloatLabeledTextField'  
	  s.ios.dependency 'SBObjectiveCWrapper'
	  s.ios.dependency 'JSQMessagesViewController'
	  s.ios.dependency 'Analytics', '~> 3.0'
	  s.ios.dependency 'MGSwipeTableCell'
	  s.ios.dependency 'SDWebImage/GIF'
	  s.ios.dependency 'Shimmer'
  end
  
# Extension subspec, including everything in 'Core' plus a compile flag
  s.subspec 'Extension' do |extension|
     extension.dependency 'ZingleSDK/Core'
  end

end
