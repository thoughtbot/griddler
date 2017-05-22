require 'spec_helper'

describe Griddler::Configuration do
  describe 'no configuration given' do
    before do
      Griddler.configure
    end

    it 'provides defaults' do
      expect(Griddler.configuration.processor_class).to eq(EmailProcessor)
      expect(Griddler.configuration.email_class).to eq(Griddler::Email)
      expect(Griddler.configuration.reply_delimiter).to eq('-- REPLY ABOVE THIS LINE --')
      expect(Griddler.configuration.email_service).to eq(:test_adapter)
      expect(Griddler.configuration.processor_method).to eq(:process)
    end

    it 'raises a helpful error if EmailProcessor is undefined' do
      # temporarily undefine EmailProcessor
      ep = EmailProcessor
      Object.send(:remove_const, :EmailProcessor)
      allow(ActiveSupport::Dependencies).to(
        receive_messages(search_for_file: nil))

      expect { Griddler.configuration.processor_class }.to raise_error(
        NameError, %r{https://github\.com/thoughtbot/griddler#defaults})

      # restore EmailProcessor
      EmailProcessor = ep
    end
  end

  describe 'with config block' do
    after do
      Griddler.configure
    end

    it 'stores a processor_class' do
      class DummyProcessor
      end

      Griddler.configure do |config|
        config.processor_class = DummyProcessor
      end

      expect(Griddler.configuration.processor_class).to eq DummyProcessor
    end

    it 'stores an email_class' do
      class DummyEmail
      end

      Griddler.configure do |config|
        config.email_class = DummyEmail
      end

      expect(Griddler.configuration.email_class).to eq DummyEmail
    end

    it 'stores a processor_method' do
      Griddler.configure do |config|
        config.processor_method = :perform
      end

      expect(Griddler.configuration.processor_method).to eq(:perform)
    end

    it 'stores a reply_delimiter' do
      Griddler.configure do |config|
        config.reply_delimiter = '-----Original Message-----'
      end

      expect(Griddler.configuration.reply_delimiter).to eq(
        '-----Original Message-----')
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
