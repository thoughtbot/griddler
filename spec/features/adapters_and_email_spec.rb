require 'spec_helper'

describe 'Adapters act the same' do
  [:sendgrid, :postmark, :cloudmailin, :mandrill, :mailgun].each do |adapter|
    context adapter do
      it "wraps recipients in an array and passes them to Email by #{adapter}" do
        Griddler.configuration.email_service = adapter

        normalized_params = Griddler.configuration.email_service.normalize_params(params_for[adapter])

        Array.wrap(normalized_params).each do |params|
          email = Griddler::Email.new(params)

          email.to.should eq([{
            token: 'hi',
            host: 'example.com',
            full: 'Hello World <hi@example.com>',
            email: 'hi@example.com',
            name: 'Hello World',
          }])
          email.cc.should eq ['emily@example.com']
        end

      end
    end
  end
end

def params_for
  {
    cloudmailin: {
      envelope: {
        to: 'Hello World <hi@example.com>',
        from: 'There <there@example.com>',
      },
      plain: 'hi',
      headers: { Cc: 'emily@example.com' },
    },
    postmark: {
      FromFull: {
        Email: 'there@example.com',
        Name: 'There',
      },
      ToFull: [{
        Email: 'hi@example.com',
        Name: 'Hello World',
      }],
      CcFull: [{
        Email: 'emily@example.com',
        Name: '',
      }],
      TextBody: 'hi',
    },
    sendgrid: {
      text: 'hi',
      to: 'Hello World <hi@example.com>',
      cc: 'emily@example.com',
      from: 'There <there@example.com>',
    },
    mandrill: {
      mandrill_events: ActiveSupport::JSON.encode([{
        msg: {
          text: 'hi',
          from_email: "there@example.com",
          from_name: "There",
          to: [["hi@example.com", "Hello World"]],
          headers: [['Cc', 'emily@example.com']]
        }
      }])
    },
    mailgun: {
      recipient: 'Hello World <hi@example.com>',
      from: 'There <there@example.com>',
      Cc: 'emily@example.com',
      'body-plain' => 'hi',
    }
  }
end
