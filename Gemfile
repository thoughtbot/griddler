source "http://rubygems.org"

gemspec

version = ENV["RAILS_VERSION"] || "4.0"

rails = case version
when "master"
  {:github => "rails/rails"}
else
  "~> #{version}.0"
end

gem "rails", rails
gem "griddler-sendgrid", github: "thoughtbot/griddler-sendgrid", branch: "gbw-make-it-work"
