module Griddler
  mattr_accessor :configuration

  def self.configure
    self.configuration = Configuration.new
    yield configuration
  end

  class Configuration
    attr_accessor :handler_class, :handler_method, :raw_body, :reply_delimiter, :to

    def to
      @to ||= :token
    end

    def handler_method
      @handler_method ||= :process
    end

    def raw_body
      @raw_body ||= false
    end

    def reply_delimiter
      @raw_body ||= 'REPLY ABOVE THIS LINE'
    end
  end
end
