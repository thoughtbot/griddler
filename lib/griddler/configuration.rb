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
    attr_accessor :processor_class, :processor_method, :reply_delimiter

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
      @email_service_adapter ||= Griddler.adapter_registry[:default]
    end

    def email_service=(new_email_service)
      @email_service_adapter = Griddler.adapter_registry.fetch(new_email_service) { raise Griddler::Errors::EmailServiceAdapterNotFound }
    end
  end
end
