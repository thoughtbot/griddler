require 'yajl'

class Griddler::Event
  attr_reader :attributes

  def self.process(body)
    parser = Yajl::Parser.new
    parser.on_parse_complete = proc do |event_attributes|
      config.event_processor_class.process Event.new(event_attributes)
    end
    parser.parse(body)
  end

  def initialize(attributes)
    @attributes = attributes
  end

  def event
    @attributes[:event]
  end

  def email
    @attributes[:email]
  end

  def timestamp
    @timestamp ||= Time.at (@attribute[:timestamp] || Time.now).to_i
  end

  def [](key)
    @attributes[key]
  end

  class << self
    private

    def config
      Griddler.configuration
    end
  end
end