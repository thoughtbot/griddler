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
    attr_accessor :processor_class, :reply_delimiter, :to, :mail_service

    def to
      @to ||= :token
    end

    def processor_class
      @processor_class ||= EmailProcessor
    end

    def reply_delimiter
      @reply_delimiter ||= 'Reply ABOVE THIS LINE'
    end
    
    def mail_service
      @mail_service ||= :send_grid
    end

  end
end
