Gem::Specification.new do |s|
  s.name        = 'docker_registry_cli'
  s.version     = '0.0.3'
  s.date        = '2016-07-03'
  s.summary     = 'Docker Registry Cli - Search your docker registry from the cli'
  s.description = 'This cli-tool lets you query your private docker registry for different things. For now, there is no tool provided by docker to do so'
  s.authors     = ['Eugen Mayer']
  s.executables = %w[docker_registry_cli]
  s.email       = 'eugen.mayer@kontextwork.de'
  s.files       = Dir['auth/**/*.rb','commands/**/*.rb','requests/**/*.rb','bin/*']
  s.license     = 'GPL'
  s.homepage    = 'https://github.com/EugenMayer/docker_registry_cli'
  s.add_runtime_dependency 'colorize', '~> 0'
  s.add_runtime_dependency 'httparty', '~> 0'
end
