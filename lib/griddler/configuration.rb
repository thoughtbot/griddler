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
    attr_accessor :processor_class, :reply_delimiter

    def to
      @to ||= :hash
    end

    def to=(type)
      if type == :token
        Kernel.warn <<-WARN.strip_heredoc
          [Deprecation] the :token option is deprecated and will be removed in v0.6.
          For tokens use :hash and retrieve the token from email.to[:token] or choose any of [:email, :full, :hash]
        WARN
      end

      @to = type
    end

    def processor_class
      @processor_class ||= EmailProcessor
    end

    def reply_delimiter
      @reply_delimiter ||= 'Reply ABOVE THIS LINE'
    end

    def email_service
      @email_service_adapter ||= adapter_class[:sendgrid]
    end

    def email_service=(new_email_service)
      @email_service_adapter = adapter_class.fetch(new_email_service) { raise Griddler::Errors::EmailServiceAdapterNotFound }
    end

    private

    def adapter_class
      {
        sendgrid: Griddler::Adapters::SendgridAdapter,
        cloudmailin: Griddler::Adapters::CloudmailinAdapter,
        postmark: Griddler::Adapters::PostmarkAdapter,
        mandrill: Griddler::Adapters::MandrillAdapter,
      }
    end
  end
end
