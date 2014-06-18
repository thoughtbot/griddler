require 'spec_helper'

describe Griddler::Configuration do
  describe 'no configuration given' do
    before do
      Griddler.configure
    end

    it 'provides defaults' do
      Griddler.configuration.processor_class.should eq(EmailProcessor)
      Griddler.configuration.reply_delimiter.should eq('Reply ABOVE THIS LINE')
      Griddler.configuration.email_service.should eq(:test_adapter)
      Griddler.configuration.processor_method.should eq(:process)
    end

    it 'raises a helpful error if EmailProcessor is undefined' do
      Kernel.stub(const_defined?: false)

      expect { Griddler.configuration.processor_class }.to raise_error(NameError, %r{https://github\.com/thoughtbot/griddler#defaults})
    end
  end

  describe 'with config block' do
    after do
      Griddler.configure
    end

    it 'stores a processor_class' do
      dummy_processor = Class.new

      Griddler.configure do |config|
        config.processor_class = dummy_processor
      end

      Griddler.configuration.processor_class.should eq dummy_processor
    end

    it 'stores a processor_method' do
      Griddler.configure do |config|
        config.processor_method = :perform
      end

      Griddler.configuration.processor_method.should eq(:perform)
    end

    it 'sets and stores an email_service' do
      Griddler.should_receive(:adapter_registry).and_return(double(fetch: :configured_adapter))
      Griddler.configure do |config|
        config.email_service = :another_adapter
      end

      Griddler.configuration.email_service.should eq(:configured_adapter)
    end

    it 'accepts a :default symbol and uses sendgrid' do
      Griddler.configure do |c|
        c.email_service = :default
      end

      Griddler.configuration.email_service.should eq(:test_adapter)
    end

    it 'raises an error when setting a non-existent email service adapter' do
      config = lambda do
        Griddler.configure do |c|
          c.email_service = :non_existent
        end
      end

      config.should raise_error(Griddler::Errors::EmailServiceAdapterNotFound)
    end
  end
end
