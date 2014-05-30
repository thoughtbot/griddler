require 'spec_helper'

describe Griddler::AdapterRegistry do
  it 'it is exposed by Griddler' do
    Griddler.adapter_registry.should be_a Griddler::AdapterRegistry
  end

  it 'can register adapters' do
    adapter_registry = Griddler::AdapterRegistry.new

    adapter_registry.register(:foo, adapter)

    adapter_registry[:foo].should eq(adapter)
  end

  it 'can fetch like a hash' do
    adapter_registry = Griddler::AdapterRegistry.new

    result = adapter_registry.fetch(:non_existent) { 'exists' }

    result.should eq 'exists'
  end

  it 'maps :default to :sendgrid' do
    adapter_registry = Griddler::AdapterRegistry.new

    adapter_registry.register(:sendgrid, adapter)

    adapter_registry[:default].should eq(adapter)
  end

  def adapter
    @adapter ||= Class.new
  end
end
