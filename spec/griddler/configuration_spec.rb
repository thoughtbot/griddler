require 'spec_helper'

describe Griddler::Configuration do
  describe 'no configuration given' do
    before do
      Griddler.configure
    end

    it 'provides defaults' do
      Griddler.configuration.processor_class.should eq(EmailProcessor)
      Griddler.configuration.to.should eq(:hash)
      Griddler.configuration.reply_delimiter.should eq('Reply ABOVE THIS LINE')
      Griddler.configuration.email_service.should eq(Griddler::Adapters::SendgridAdapter)
    end
  end

  describe 'with config block' do
    after do
      Griddler.configure
    end

    it 'stores config' do
      Griddler.configure do |config|
        config.to = :full
      end

      Griddler.configuration.to.should eq :full
    end

    it 'warns when setting token' do
      Kernel.should_receive(:warn)

      Griddler.configure do |config|
        config.to = :token
      end
    end

    it 'stores a processor_class' do
      dummy_processor = Class.new

      Griddler.configure do |config|
        config.processor_class = dummy_processor
      end

      Griddler.configuration.processor_class.should eq dummy_processor
    end

     it 'sets and stores an email_service' do

        Griddler.configure do |config|
          config.email_service = :cloudmailin
        end

        Griddler.configuration.email_service.should eq(Griddler::Adapters::CloudmailinAdapter)
      end

    it 'raises an error when setting a non-existent email service adapter' do
      config = lambda do
        Griddler.configure do |c|
          c.email_service = :non_existent
        end
      end

      config.should raise_error(Griddler::Errors::EmailServiceAdapterNotFound)
    end

    it "accepts all valid email service adapter settings" do
      [:sendgrid, :cloudmailin, :postmark, :mandrill].each do |adapter|
        config = lambda do
          Griddler.configure do |c|
            c.email_service = adapter
          end
        end

        config.should_not raise_error
      end
    end
  end
end
