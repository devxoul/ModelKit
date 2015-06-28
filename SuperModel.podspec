Pod::Spec.new do |s|
  s.name         = "SuperModel"
  s.version      = "0.0.3"
  s.summary      = "Model framework for Swift"
  s.homepage     = "http://github.com/devxoul/SuperModel"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "devxoul" => "devxoul@gmail.com" }
  s.source       = { :git => "https://github.com/devxoul/SuperModel.git",
                     :tag => "#{s.version}" }
  s.platform     = :ios, '8.0'
  s.source_files = 'SuperModel/*.{swift,h}'
  s.frameworks   = 'Foundation'
  s.requires_arc = true
end
