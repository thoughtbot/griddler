source "http://rubygems.org"

gemspec

if ENV["RAILS_BRANCH"]
  gem "rails", github: "rails/rails", branch: ENV["RAILS_BRANCH"]
else
  gem "rails", "~> 4.0.0"
end

gem "griddler-sendgrid", github: "thoughtbot/griddler-sendgrid"
gem "griddler-mandrill", github: "wingrunr21/griddler-mandrill"
gem "griddler-mailgun", github: "bradpauly/griddler-mailgun"
