require 'spec_helper'

describe Griddler::EmailsController do
  describe 'POST create' do
    it 'is successful' do
      post :create, email_params

      response.should be_success
    end

    it 'creates a new Griddler::Email with the given params' do
      email = double(process: 'something')
      Griddler::Email.should_receive(:new).
        with(hash_including('to' => ['tb@example.com'])).
        and_return(email)
      email.should_receive(:process)

      post :create, { to: 'tb@example.com' }
    end
  end

  def email_params
    {
      headers: 'Received: by 127.0.0.1 with SMTP...',
      to: 'thoughtbot <tb@example.com>',
      from: 'John Doe <someone@example.com>',
      subject: 'hello there',
      text: 'this is an email message',
      html: '<p>this is an email message</p>',
      charsets: '{"to":"UTF-8","html":"ISO-8859-1","subject":"UTF-8","from":"UTF-8","text":"ISO-8859-1"}',
      SPF: "pass"
    }
  end
end
