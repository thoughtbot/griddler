require 'spec_helper'

describe Griddler::EmailsController do
  describe 'POST create' do
    it 'is successfull' do
        post :create, email_params
        response.should be_success
    end

    it 'creates a new Griddler::Email' do
        controller.stub(:params).and_return({})
        Griddler::Email.stub(:new).and_return('something')
        Griddler::Email.should_receive(:new).with({})

        post :create
    end
  end
end

private

def email_params
  {
    to: 'someone@example.com',
    from: 'someone@example.com'
  }
end
