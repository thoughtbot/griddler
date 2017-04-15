require 'spec_helper'

describe ReplyingMailer, '#response' do
  it 'builds an RFC 5322 compliant reply' do
    email = Griddler::Email.new(
      headers: [
        'Message-ID: <3@example.com>',
        'In-Reply-To: <2@example.com>',
        'References: <1@example.com> <2@example.com>',
        'Reply-To: me@example.com'
      ].join("\r\n"),
      to: ['recipient@example.com'],
      from: 'sender@example.com',
      subject: 'Hello world',
      text: 'This is just a test email'
    )

    reply = ReplyingMailer.response(email)

    reply.to.should eq ['me@example.com']
    reply.from.should eq ['info@myapp.example.com']
    reply.subject.should eq 'Re: Hello world'
    reply.header['In-Reply-To'].value.should eq '<3@example.com>'
    reply.header['References'].value.should eq '<1@example.com> <2@example.com> <3@example.com>'
    reply.html_part.body.should match %r(<p>The HTML version of the email!</p>)
    reply.text_part.body.should match %r(The text version of the email!)
  end
end
