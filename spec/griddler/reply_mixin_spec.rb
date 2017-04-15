# encoding: utf-8

require 'spec_helper'
require 'griddler/reply_mixin'

class DummyMailer
  include Griddler::ReplyMixin
end

describe Griddler::ReplyMixin, '#reply' do
  let(:mailer) do
    DummyMailer.new.tap { |mailer| mailer.stub(:mail) }
  end

  describe 'setting the subject (RFC 5322 § 3.6.5)' do
    it 'prefixes the original subject with Re:' do
      email = build_email(subject: 'Hello')

      mailer.should_receive(:mail).with(hash_including(subject: 'Re: Hello'))
      mailer.reply(email)
    end

    it 'does not create a duplicate prefix' do
      email = build_email(subject: 'Re: Important')

      mailer.should_receive(:mail).with(hash_including(subject: 'Re: Important'))
      mailer.reply(email)
    end
  end

  describe 'setting the recipient (RFC 5322 § 3.6.2)' do
    it 'prefers to use the Reply-To header' do
      email = build_email(
        from: '"Jane Doe" <jane@example.com>',
        headers: %Q(Reply-To: "John Doe" <john@example.com>\r\n)
      )

      mailer.should_receive(:mail).with(hash_including(to: '"John Doe" <john@example.com>'))
      mailer.reply(email)
    end

    it 'uses the From header when Reply-To is not set' do
      email = build_email(from: '"Jane Doe" <jane@example.com>')

      mailer.should_receive(:mail).with(hash_including(to: 'jane@example.com'))
      mailer.reply(email)
    end
  end

  describe 'setting the reply headers (RFC 5322 § 3.6.4)' do
    describe 'from a parent with no identifying headers' do
      it 'does not set any headers' do
        email = build_email(headers: '')

        mailer.should_receive(:mail) do |headers|
          headers.should_not have_key('In-Reply-To')
          headers.should_not have_key('References')
        end
        mailer.reply(email)
      end
    end

    describe 'from a parent with only a Message-ID' do
      it 'sets In-Reply-To and References' do
        email = build_email(headers: 'Message-ID: <1@example.com>')

        mailer.should_receive(:mail).with(hash_including(
          'In-Reply-To' => '<1@example.com>',
          'References' => '<1@example.com>'
        ))
        mailer.reply(email)
      end
    end

    describe 'from a parent with Message-ID, In-Reply-To & References' do
      it 'sets In-Reply-To and References' do
        email = build_email(headers: [
          'Message-ID: <3@example.com>',
          'In-Reply-To: <2@example.com>',
          'References: <1@example.com> <2@example.com>'
        ].join("\r\n"))

        mailer.should_receive(:mail).with(hash_including(
          'In-Reply-To' => '<3@example.com>',
          'References' => '<1@example.com> <2@example.com> <3@example.com>'
        ))
        mailer.reply(email)
      end
    end

    describe 'from a parent with a Message-ID and a single In-Reply-To' do
      it 'sets In-Reply-To and References' do
        email = build_email(headers: [
          'Message-ID: <2@example.com>',
          'In-Reply-To: <1@example.com>'
        ].join("\r\n"))

        mailer.should_receive(:mail).with(hash_including(
          'In-Reply-To' => '<2@example.com>',
          'References' => '<1@example.com> <2@example.com>'
        ))
        mailer.reply(email)
      end
    end

    describe 'from a parent with a Message-ID and a multiple In-Reply-To' do
      it 'sets In-Reply-To and References' do
        email = build_email(headers: [
          'Message-ID: <3@example.com>',
          'In-Reply-To: <1@example.com> <2@example.com>'
        ].join("\r\n"))

        mailer.should_receive(:mail).with(hash_including(
          'In-Reply-To' => '<3@example.com>',
          'References' => '<3@example.com>'
        ))
        mailer.reply(email)
      end
    end
  end

  describe 'accepting custom arguments' do
    it 'passes them on to `mail`' do
      email = build_email(subject: 'Hello world', from: 'you@example.com')

      mailer.should_receive(:mail).with(hash_including(
        to: 'you@example.com',
        from: 'me@example.com',
        subject: 'Goodbye world'
      ))
      mailer.reply(email, subject: 'Goodbye world', from: 'me@example.com')
    end

    it 'passes the given block on to `mail`' do
      format = double.tap { |f| f.stub(:html) }
      mailer.stub(:mail).and_yield(format)

      format.should_receive(:html).with(text: '<p>Hello!</p>')
      mailer.reply(build_email) { |format| format.html text: '<p>Hello!</p>' }
    end
  end

  def build_email(params={})
    Griddler::Email.new({
      headers: '',
      to: ['recipient@example.com'],
      from: 'sender@example.com',
      subject: 'Hello',
      text: 'Hello there!'
    }.merge(params))
  end
end
