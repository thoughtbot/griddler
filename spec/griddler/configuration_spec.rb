require 'spec_helper'

describe Griddler::Configuration do
  describe 'no configuration given' do
    before do
      Griddler.configure
    end

    it 'provides defaults' do
      expect(Griddler.configuration.processor_class).to eq(EmailProcessor)
      expect(Griddler.configuration.reply_delimiter).to eq('Reply ABOVE THIS LINE')
      expect(Griddler.configuration.email_service).to eq(:test_adapter)
      expect(Griddler.configuration.processor_method).to eq(:process)
    end

    it 'raises a helpful error if EmailProcessor is undefined' do
      allow(Kernel).to receive_messages(const_defined?: false)

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

      expect(Griddler.configuration.processor_class).to eq dummy_processor
    end

    it 'stores a processor_method' do
      Griddler.configure do |config|
        config.processor_method = :perform
      end

      expect(Griddler.configuration.processor_method).to eq(:perform)
    end

    it 'sets and stores an email_service' do
      expect(Griddler).to receive(:adapter_registry).and_return(double(fetch: :configured_adapter))
      Griddler.configure do |config|
        config.email_service = :another_adapter
      end

      expect(Griddler.configuration.email_service).to eq(:configured_adapter)
    end

    it 'accepts a :default symbol and uses sendgrid' do
      Griddler.configure do |c|
        c.email_service = :default
      end

      expect(Griddler.configuration.email_service).to eq(:test_adapter)
    end

    it 'raises an error when setting a non-existent email service adapter' do
      config = lambda do
        Griddler.configure do |c|
          c.email_service = :non_existent
        end
      end

      expect(config).to raise_error(Griddler::Errors::EmailServiceAdapterNotFound)
    end
  end
end
