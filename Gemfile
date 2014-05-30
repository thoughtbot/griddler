source "http://rubygems.org"

gemspec

if ENV["RAILS_VERSION"]
  gem "rails", github: "rails/rails", branch: ENV["RAILS_VERSION"]
else
  gem "rails", "~> 4.0.0"
end

gem "griddler-sendgrid", github: "thoughtbot/griddler-sendgrid"
