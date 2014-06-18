require 'spec_helper'

describe Griddler::EmailsController do
  before(:each) do
    fake_adapter = double(normalize_params: normalized_params)
    Griddler.adapter_registry.register(:one_that_works, fake_adapter)
    Griddler.configuration.email_service = :one_that_works
  end

  describe 'POST create', type: :controller do
    it 'is successful' do
      post :create, email_params

      response.should be_success
    end

    it 'creates a new Griddler::Email with the given params' do
      email = double
      Griddler::Email.should_receive(:new).
        with(hash_including(to: ['tb@example.com'])).
        and_return(email)

      post :create, { to: 'tb@example.com' }
    end

    it 'calls process on the custom processor class' do
      my_handler = double
      my_handler.should_receive(:process)
      Griddler.configuration.stub(processor_class: my_handler)

      post :create, email_params
    end

    it 'calls the custom processor method on the processor class' do
      Griddler.configuration.stub(processor_method: :perform)
      griddler_email = double
      Griddler::Email.should_receive(:new).and_return(griddler_email)

      EmailProcessor.should_receive(:perform).with(griddler_email)

      post :create, to: 'tb@example.com'
    end
  end

  def email_params
    {
      headers: 'Received: by 127.0.0.1 with SMTP...',
      to: 'thoughtbot <tb@example.com>',
      cc: 'CC <cc@example.com>',
      from: 'John Doe <someone@example.com>',
      subject: 'hello there',
      text: 'this is an email message',
      html: '<p>this is an email message</p>',
      charsets: '{"to":"UTF-8","html":"ISO-8859-1","subject":"UTF-8","from":"UTF-8","text":"ISO-8859-1"}',
      SPF: "pass"
    }
  end

  def normalized_params
    {
      to: ['tb@example.com'],
      from: 'tb@example.com',
      cc: [],
    }
  end
end
