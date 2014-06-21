require 'action_dispatch'

module Griddler::Testing
  def upload_1
    @upload_1 ||= UploadedImage.new('photo1.jpg').file
  end

  def upload_2
    @upload_2 ||= UploadedImage.new('photo2.jpg').file
  end

  def normalize_params(params)
    Griddler::Sendgrid::Adapter.normalize_params(params)
  end

  class UploadedImage
    def initialize(name)
      @name = name
    end

    def file
      ActionDispatch::Http::UploadedFile.new({
        filename: @name,
        type: 'image/jpeg',
        tempfile: fixture_file
      })
    end

    private

    def fixture_file
      cwd = File.expand_path File.dirname(__FILE__)
      File.new(File.join(cwd, '..', '..', 'spec', 'fixtures', @name))
    end
  end
end

shared_examples_for 'Griddler adapter' do |adapter, service_params|
  it 'adapts params to expected values' do
    Griddler.configuration.email_service = adapter

    normalized_params = Griddler.configuration.email_service.normalize_params(service_params)

    Array.wrap(normalized_params).each do |params|
      email = Griddler::Email.new(params)

      expect(email.to).to eq([{
        token: 'hi',
        host: 'example.com',
        full: 'Hello World <hi@example.com>',
        email: 'hi@example.com',
        name: 'Hello World',
      }])
      expect(email.cc).to eq [{
        token: 'emily',
        host: 'example.com',
        email: 'emily@example.com',
        full: 'emily@example.com',
        name: nil
      }]
    end
  end
end

RSpec::Matchers.define :be_normalized_to do |expected|
  failure_message do |actual|
    message = ""
    expected.each do |k, v|
      if actual[k] != expected[k]
        message << "expected :#{k} to be normalized to #{expected[k].inspect}, "\
          "but received #{actual[k].inspect}\n"
      end
    end
    message
  end

  description do
    "be normalized to #{expected}"
  end

  match do |actual|
    expected.each do |k, v|
      case v
      when Regexp then expect(actual[k]).to =~ v
      else expect(actual[k]).to === v
      end
    end
  end
end
