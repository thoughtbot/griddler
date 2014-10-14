require 'spec_helper'

describe Griddler::AdapterRegistry do
  it 'it is exposed by Griddler' do
    expect(Griddler.adapter_registry).to be_a Griddler::AdapterRegistry
  end

  it 'can register adapters' do
    adapter_registry = Griddler::AdapterRegistry.new

    adapter_registry.register(:foo, adapter)

    expect(adapter_registry[:foo]).to eq(adapter)
  end

  it 'can fetch like a hash' do
    adapter_registry = Griddler::AdapterRegistry.new

    result = adapter_registry.fetch(:non_existent) { 'exists' }

    expect(result).to eq 'exists'
  end

  it 'maps :default to :sendgrid' do
    adapter_registry = Griddler::AdapterRegistry.new

    adapter_registry.register(:sendgrid, adapter)

    expect(adapter_registry[:default]).to eq(adapter)
  end

  def adapter
    @adapter ||= Class.new
  end
end
