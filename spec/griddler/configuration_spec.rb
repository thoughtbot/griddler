require 'spec_helper'

describe Griddler::Configuration do
  describe 'no configuration given' do
    before do
      Griddler.configure
    end

    it 'provides defaults' do
      Griddler.configuration.processor_class.should eq(EmailProcessor)
      Griddler.configuration.to.should eq(:token)
      Griddler.configuration.reply_delimiter.should eq('Reply ABOVE THIS LINE')
    end
  end

  describe 'with config block' do
    after do
      Griddler.configure
    end

    it 'stores config' do
      Griddler.configure do |config|
        config.to = :hash
      end

      Griddler.configuration.to.should eq :hash
    end

    it 'stores a processor_class' do
      dummy_processor = Class.new

      Griddler.configure do |config|
        config.processor_class = dummy_processor
      end

      Griddler.configuration.processor_class.should eq dummy_processor
    end

    it 'defaults the email service to SendGrid' do
      Griddler.configuration.email_service.should eq(Griddler::Adapters::SendGridAdapter)
    end

    it 'raises an error when setting a non-existent email service adapter' do
      config = -> {
        Griddler.configure do |config|
          config.email_service = :non_existent
        end
      }

      config.should raise_error(Griddler::Errors::EmailServiceAdapterNotFound)
    end
  end
end
