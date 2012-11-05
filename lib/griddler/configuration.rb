module Griddler
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration = Configuration.new

    if block_given?
      yield configuration
    end

    self.configuration
  end

  def self.configuration
    @configuration || self.configure
  end

  class Configuration
    attr_accessor :handler_class, :handler_method, :raw_body, :reply_delimiter, :to

    def to
      @to ||= :token
    end

    def handler_class
      @handler_class ||= EmailProcessor
    end

    def handler_method
      @handler_method ||= :process
    end

    def raw_body
      @raw_body ||= false
    end

    def reply_delimiter
      @reply_delimiter ||= 'Reply ABOVE THIS LINE'
    end
  end
end
