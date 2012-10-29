require 'spec_helper'

describe Griddler::Configuration do
  describe 'no configuration given' do
    before do
      Griddler.configure do
      end
    end

    it 'provides defaults' do
      Griddler.configuration.handler_class.should == nil
      Griddler.configuration.handler_method.should == :process
      Griddler.configuration.to.should == :token
      Griddler.configuration.raw_body.should == false
      Griddler.configuration.reply_delimiter == 'Reply ABOVE THIS LINE'
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
