ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../dummy/config/environment", __FILE__)
require 'rspec/rails'
require 'helpers/fixtures_helper'

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.order = "random"

  config.expect_with :rspec do |c|
    c.syntax = [:expect, :should]
  end

  config.mock_with :rspec do |c|
    c.syntax = :should
  end

  config.before :each do
    Griddler.configuration.email_service = :default
  end
end

RSpec::Matchers.define :be_normalized_to do |expected|
  failure_message do |actual|
    message = ""
    expected.each do |k, v|
      message << "expected :#{k} to be normalized to #{expected[k].inspect}, "\
      "but received #{actual[k].inspect}\n" unless actual[k] == expected[k]
    end
    message
  end

  description do
    "be normalized to #{expected}"
  end

  match do |actual|
    expected.each do |k, v|
      case v
      when Regexp then actual[k].should =~ v
      else actual[k].should === v
      end
    end
  end
end
