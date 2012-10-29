require 'spec_helper'

describe Griddler::Configuration do
  describe 'no configuration given' do
    before do
      Griddler.configure
    end

    it 'provides defaults' do
      Griddler.configuration.handler_class.should eq(nil)
      Griddler.configuration.handler_method.should eq(:process)
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

      Griddler.configuration.to.should == :hash
    end

    it 'stores a handler_class' do
      DummyProcessor = Class.new
      Griddler.configure do |config|
        config.handler_class = DummyProcessor
      end

      Griddler.configuration.handler_class.should == ::DummyProcessor
    end
  end
end
