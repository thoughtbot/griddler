require 'spec_helper'

describe Griddler::Configuration do
  describe 'no configuration given' do
    before do
      Griddler.configure
    end

    it 'provides defaults' do
      Griddler.configuration.processor_class.should eq(EmailProcessor)
      Griddler.configuration.to.should eq(:token)
      Griddler.configuration.raw_body.should eq(false)
      Griddler.configuration.reply_delimiter.should eq('Reply ABOVE THIS LINE')
    end
  end

  describe 'with config block' do
    it 'stores config' do
      Griddler.configure do |config|
        config.to = :hash
      end

      Griddler.configuration.to.should eq :hash
    end

    it 'stores a processor_class' do
      class DummyProcessor
        def self.process(email)
          true
        end
      end

      Griddler.configure do |config|
        config.processor_class = DummyProcessor
      end

      Griddler.configuration.processor_class.should eq ::DummyProcessor
    end
  end
end
