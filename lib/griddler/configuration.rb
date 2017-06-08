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
    attr_accessor :processor_method, :reply_delimiter, :prefer_html
    attr_writer :email_class

    def processor_class
      @processor_class ||=
        begin
          EmailProcessor.to_s
        rescue NameError
          raise NameError.new(<<-ERROR.strip_heredoc, 'EmailProcessor')
            To use Griddler, you must either define `EmailProcessor` or configure a
            different processor. See https://github.com/thoughtbot/griddler#defaults for
            more information.
          ERROR
        end
      @processor_class.constantize
    end

    def processor_class=(klass)
      @processor_class = klass.to_s
    end

    def email_class
      @email_class ||= Griddler::Email
    end

    def processor_method
      @processor_method ||= :process
    end

    def reply_delimiter
      @reply_delimiter ||= '-- REPLY ABOVE THIS LINE --'
    end

    def email_service
      @email_service_adapter ||=
        Griddler.adapter_registry[:default] ||
          raise(Griddler::Errors::EmailServiceAdapterNotFound)
    end

    def email_service=(new_email_service)
      @email_service_adapter = Griddler.adapter_registry.fetch(new_email_service) { raise Griddler::Errors::EmailServiceAdapterNotFound }
    end
  end
end
