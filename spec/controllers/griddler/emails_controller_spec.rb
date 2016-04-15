require 'spec_helper'

describe Griddler::EmailsController, :type => :controller do
  before(:each) do
    fake_adapter = double(normalize_params: {})
    Griddler.adapter_registry.register(:one_that_works, fake_adapter)
    Griddler.configuration.email_service = :one_that_works
  end

  describe 'POST create', type: :controller do
    it 'is successful' do
      post :create
      expect(response).to be_successful
    end

    it 'processes an email with griddler' do
      expect(controller).to receive(:process_griddler)
      post :create
    end
  end
end
