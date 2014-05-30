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
      envelope: { to: ['hi@example.com'], from: 'there@example.com' }.to_json,
      SPF: 'pass',
      dkim: '{@gmail.com : pass}',
      spam_score: '0.012',
      spam_report: 'OMG This might be spam!',
      charsets: { to: "UTF-8", cc: "UTF-8", subject: "UTF-8", from: "UTF-8", html: "UTF-8", text: "iso-8859-1" }.to_json
    },
    mandrill: {
      mandrill_events: ActiveSupport::JSON.encode([{
        msg: {
          text: 'hi',
          from_email: 'there@example.com',
          from_name: 'There',
          to: [['hi@example.com', 'Hello World']],
          cc: [['emily@example.com', 'Emily']],
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
