$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'griddler/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'griddler'
  s.version     = Griddler::VERSION
  s.authors     = ['Caleb Thompson', 'Joel Oliveira', 'thoughtbot']
  s.email       = ['cjaysson@gmail.com', 'joel@thoughtbot.com']
  s.homepage    = 'http://thoughtbot.com'
  s.summary     = 'SendGrid Parse API client Rails Engine'

  s.files = Dir['{app,config,lib}/**/*'] + ['MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'rails', '~> 3.2.8'
  s.require_paths = %w{app lib}

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'pry'
end
