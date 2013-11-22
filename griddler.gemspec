$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'griddler/version'

Gem::Specification.new do |s|
  s.name        = 'griddler'
  s.version     = Griddler::VERSION
  s.authors     = ['Caleb Thompson', 'Joel Oliveira', 'thoughtbot', 'Swift']
  s.email       = ['cjaysson@gmail.com', 'joel@thoughtbot.com', 'theycallmeswift@gmail.com']
  s.homepage    = 'http://thoughtbot.com'
  s.summary     = 'SendGrid Parse API client Rails Engine'

  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")
  s.files = Dir['{app,config,lib}/**/*'] + ['LICENSE', 'Rakefile', 'README.md']
  s.require_paths = %w{app lib}

  s.post_install_message = <<-MESSAGE
When upgrading from a Griddler version previous to 0.5.0, it is important that
you view https://github.com/thoughtbot/griddler/#upgrading-to-griddler-050 for
upgrade information.
MESSAGE

  s.add_dependency 'rails', '>= 3.2.0'
  s.add_dependency 'htmlentities'
  s.add_dependency 'nokogiri'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'sqlite3'
  # jquery-rails is used by the dummy Rails application
  s.add_development_dependency 'jquery-rails'
end
