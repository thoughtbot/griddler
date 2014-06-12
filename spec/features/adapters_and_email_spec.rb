require 'spec_helper'
require 'griddler/testing'

def params_for
  @params_for ||= {
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
          from_email: 'there@example.com',
          from_name: 'There',
          to: [['hi@example.com', 'Hello World']],
          cc: [['emily@example.com', 'Emily']],
        }
      }])
    },
    mailgun: {
      To: 'Hello World <hi@example.com>',
      From: 'There <there@example.com>',
      Cc: 'emily@example.com',
      'body-plain' => 'hi',
    }
  }
end

describe 'Adapters act the same' do
  [:sendgrid, :postmark, :cloudmailin, :mandrill, :mailgun].each do |adapter|
    it_should_behave_like 'Griddler adapter', adapter, params_for[adapter]
  end
end
