module Griddler
  class AdapterRegistry
    DEFAULT_ADAPTER = :sendgrid

    def initialize
      @registry = {}
    end

    def register(adapter_name, adapter_class)
      if adapter_name == DEFAULT_ADAPTER
        @registry[:default] = adapter_class
      end
      @registry[adapter_name] = adapter_class
    end

    def [](adapter_name)
      @registry[adapter_name]
    end

    def fetch(key, &block)
      @registry.fetch(key, &block)
    end
  end

  def self.adapter_registry
    @adapter_registry ||= AdapterRegistry.new
  end
end
