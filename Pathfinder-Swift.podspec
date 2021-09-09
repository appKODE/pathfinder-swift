Pod::Spec.new do |s|
  s.name             = 'Pathfinder-Swift'
  s.version          = '0.1.2'
  s.summary          = 'Pathfinder is a simple URL resolver that allow you to add any environment parameters to URLs via UI'

  s.description      = <<-DESC
Pathfinder is a URL resolver. It allows you to retrieve correct URL string depending on chosen server, path and query parameters. You just need to configure module in the beginning of you app's lifecycle and call buildUrl() whenever you need to make network request.
                       DESC

  s.homepage         = 'https://github.com/appKODE/pathfinder-swift.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'KODE' => 'slurm@kode.ru' }
  s.source           = { :git => 'https://github.com/appKODE/pathfinder-swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'Pathfinder-Swift/Classes/**/*.swift'
  s.swift_version = '4.0'
end
