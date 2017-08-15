source "http://rubygems.org"

gemspec

if ENV["RAILS_BRANCH"]
  gem "rails", github: "rails/rails", branch: ENV["RAILS_BRANCH"]
else
  gem "rails", "~> 4.2.0"
end
