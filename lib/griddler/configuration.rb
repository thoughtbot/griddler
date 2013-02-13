module Griddler
  @@configuration = nil

  def self.configure
    @@configuration = Configuration.new

    if block_given?
      yield configuration
    end

    configuration
  end

  def self.configuration
    @@configuration || configure
  end

  class Configuration
    attr_accessor :processor_class, :reply_delimiter, :to

    def to
      @to ||= :token
    end

    def processor_class
      @processor_class ||= EmailProcessor
    end

    def reply_delimiter
      @reply_delimiter ||= 'Reply ABOVE THIS LINE'
    end

    def email_service
      @email_service_adapter ||= adapter_class[:send_grid]
    end

    def email_service=(foo)
      @email_service_adapter = adapter_class.fetch(foo) { raise }
    end

    config.email_service = :not_an_adapter

    private

    def adapter_class
      {
        send_grid: SendGridAdapter,
        cloud_mailin: CloudMailinAdapter,
      }
    end
  end
end
