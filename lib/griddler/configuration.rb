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
    attr_accessor :controller_class, :processor_class, :processor_method, :reply_delimiter, :cc, :from

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

    def cc
      @cc ||= :email
    end

    def from
      @from ||= :email
    end

    def controller_class
      @controller_class ||= EmailsController
    end

    def processor_class
      @processor_class ||=
        begin
          if Kernel.const_defined?(:EmailProcessor)
            EmailProcessor
          else
            raise NameError.new(<<-ERROR.strip_heredoc, 'EmailProcessor')
              To use Griddler, you must either define `EmailProcessor` or configure a
              different processor. See https://github.com/thoughtbot/griddler#defaults for
              more information.
            ERROR
          end
        end
    end

    def processor_method
      @processor_method ||= :process
    end

    def reply_delimiter
      @reply_delimiter ||= 'Reply ABOVE THIS LINE'
    end

    def email_service
      @email_service_adapter ||= adapter_class[:sendgrid]
    end

    def email_service=(new_email_service)
      if new_email_service == :default
        new_email_service = :sendgrid
      end

      @email_service_adapter = adapter_class.fetch(new_email_service) { raise Griddler::Errors::EmailServiceAdapterNotFound }
    end

    private

    def adapter_class
      {
        sendgrid: Griddler::Adapters::SendgridAdapter,
        cloudmailin: Griddler::Adapters::CloudmailinAdapter,
        postmark: Griddler::Adapters::PostmarkAdapter,
        mandrill: Griddler::Adapters::MandrillAdapter,
        mailgun: Griddler::Adapters::MailgunAdapter
      }
    end
  end
end
