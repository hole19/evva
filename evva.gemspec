require_relative 'lib/evva/version'

Gem::Specification.new do |s|
  s.name        = 'evva'
  s.version     = Evva::VERSION
  s.date        = Evva::VERSION_UPDATED_AT
  s.summary     = 'An event generating service'
  s.description = 'Evva generates all the analytics event tracking functions for you'
  s.authors     = ['RicardoTrindade']
  s.email       = 'ricardo.trindade743@gmail.com'
  s.license     = 'MIT'
  s.homepage    = 'https://github.com/hole19/'

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ['lib']

  s.executables << 'evva'

  s.add_runtime_dependency 'safe_yaml',  '~> 1.0'
  s.add_runtime_dependency 'colorize',   '~> 0.7'
  s.add_runtime_dependency 'xml-simple', '~> 1.1'

  s.add_development_dependency 'webmock', '~> 1.20'
end
