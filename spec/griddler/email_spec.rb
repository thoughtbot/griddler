# encoding: utf-8

require 'spec_helper'
require 'support/examples/configurable_email_address'

describe Griddler::Email, '#to and #from' do
  it_should_behave_like 'configurable email address', :to
  it_should_behave_like 'configurable email address', :from
end

describe Griddler::Email, 'body formatting' do

  it 'uses the html field and sanitizes it when text param missing' do
    body = <<-EOF
      <p>Hello.</p><span>Reply ABOVE THIS LINE</span><p>original message</p>
    EOF

    body_from_email(html: body).should eq 'Hello.'
  end

  it 'uses the html field and sanitizes it when text param is empty' do
    body = <<-EOF
      <p>Hello.</p><span>Reply ABOVE THIS LINE</span><p>original message</p>
    EOF

    body_from_email(html: body, text: '').should eq 'Hello.'
  end

  it 'handles invalid utf-8 bytes in html' do
    body_from_email(html: "Hell\xC0.").should eq 'HellÀ.'
  end

  it 'handles invalid utf-8 bytes in text' do
    body_from_email(text: "Hell\xF6.").should eq 'Hellö.'
  end

  it 'handles valid utf-8 bytes in html' do
    body_from_email(html: "Hell\xF1.").should eq 'Hellñ.'
  end

  it 'handles valid utf-8 bytes in text' do
    body_from_email(text: "Hell\xF2.").should eq 'Hellò.'
  end

  it 'handles valid utf-8 char in html' do
    body_from_email(html: 'Hellö.').should eq 'Hellö.'
  end

  it 'handles valid utf-8 char in text' do
    body_from_email(text: 'Hellö.').should eq 'Hellö.'
  end

  it 'does not remove invalid utf-8 bytes if charset is set' do
    charsets = {
      to: 'UTF-8',
      html: 'utf-8',
      subject: 'UTF-8',
      from: 'UTF-8',
      text: 'iso-8859-1'
    }

    body_from_email({ text: 'Helló.' }, charsets).should eq 'Helló.'
  end

  it 'handles everything on one line' do
    body = <<-EOF
      Hello. On 01/12/13, Tristan <email@example.com> wrote: Reply ABOVE THIS LINE or visit your website to respond.
    EOF

    body_from_email(text: body).should eq 'Hello.'
  end

  it 'handles "On [date] [soandso] wrote:" format' do
    body = <<-EOF
      Hello.

      On 2010-01-01 12:00:00 Tristan wrote:
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Tristan
    EOF

    body_from_email(text: body).should eq 'Hello.'
  end

  it 'handles "On [date] [soandso] <email@example.com> wrote:" format' do
    body = <<-EOF
      Hello.

      On 2010-01-01 12:00:00 Tristan <email@example.com> wrote:
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Tristan
    EOF

    body_from_email(text: body).should eq 'Hello.'
  end

  it 'handles "On [date] [soandso]\n<email@example.com> wrote:" format' do
    body = <<-EOF
      Hello.

      On 2010-01-01 12:00:00 Tristan\n <email@example.com> wrote:
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Tristan
    EOF

    body_from_email(text: body).should eq 'Hello.'
  end

  it 'handles "> On [date] [soandso] <email@example.com> wrote:" format' do
    body = <<-EOF.strip_heredoc
      Hello.

      > On 10 janv. 2014, at 18:00, Tristan <email@example.com> wrote:
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Tristan
      >
    EOF

    body_from_email(text: body).should eq 'Hello.'
  end

  it 'handles "From: email@email.com" format' do
    body = <<-EOF
      Hello.

      From: bob@example.com
      Sent: Today
      Subject: Awesome report.

      Check out this report!
    EOF

    body_from_email(text: body).should eq 'Hello.'
  end

  it 'handles "-----Original Message-----" format' do
    body = <<-EOF
      Hello.

      -----Original Message-----
      From: bob@example.com
      Sent: Today
      Subject: Awesome report.

      Check out this report!
    EOF

    body_from_email(text: body).should eq 'Hello.'
  end

  it 'handles "-----Original Message-----" format without a preceding body' do
    body = <<-EOF
      -----Original Message-----
      From: bob@example.com
      Sent: Today
      Subject: Awesome report.

      Check out this report!
    EOF

    body_from_email(text: body).should eq ''
  end

  it 'handles "-----Original message-----" case insensitively' do
    body = <<-EOF
      Hello.

      -----Original message-----
      From: bob@example.com
      Sent: Today
      Subject: Awesome report.

      Check out this report!
    EOF

    body_from_email(text: body).should eq 'Hello.'
  end

  it 'handles "-----Original message-----" case insensitively without a preceding body' do
    body = <<-EOF
      -----Original message-----
      From: bob@example.com
      Sent: Today
      Subject: Awesome report.

      Check out this report!
    EOF

    body_from_email(text: body).should eq ''
  end

  it 'handles "[date] [soandso] <email@example>" format' do
    body = <<-EOF
      2013/12/15 Bob Example <bob@example.com>
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Tristan
    EOF

    body_from_email(text: body).should eq ''
  end

  it 'handles "Reply ABOVE THIS LINE" format' do
    body = <<-EOF
      Hello.

      Reply ABOVE THIS LINE

      Hey!
    EOF

    body_from_email(text: body).should eq 'Hello.'
  end

  it 'removes > in "> Reply ABOVE THIS LINE" ' do
    body = <<-EOF
      Hello.

      > Reply ABOVE THIS LINE
    EOF

    body_from_email(text: body).should eq 'Hello.'
  end

  it 'removes any non-content things above Reply ABOVE THIS LINE' do
    body = <<-EOF
      Hello.

      On 2010-01-01 12:00:00 Tristan wrote:

      > Reply ABOVE THIS LINE

      Hey!
    EOF

    body_from_email(text: body).should eq 'Hello.'
  end

  it 'removes any iphone things above Reply ABOVE THIS LINE' do
    body = <<-EOF
      Hello.

      Sent from my iPhone

      > Reply ABOVE THIS LINE

      Hey!
    EOF

    body_from_email(text: body).should eq 'Hello.'
  end

  it 'should remove any signature above Reply ABOVE THIS LINE' do
    body = <<-EOF
      Hello.

      --
      Mr. Smith
      CEO, company
      t: 6174821300

      > Reply ABOVE THIS LINE

      > Hey!
    EOF

    body_from_email(text: body).should eq 'Hello.'
  end

  it 'should remove any signature without space above Reply ABOVE THIS LINE' do
    body = <<-EOF
      Hello.

      --
      Mr. Smith
      CEO, company
      t: 6174821300

      > Reply ABOVE THIS LINE

      > Hey!
    EOF

    body_from_email(text: body).should eq 'Hello.'
  end

  it 'properly handles a json charsets' do
    body = <<-EOF
      Hello.

      --
      Mr. Smith
      CEO, company
      t: 6174821300

      > Reply ABOVE THIS LINE

      > Hey!
    EOF

    charsets = {
      to: 'UTF-8',
      html: 'utf-8',
      subject: 'UTF-8',
      from: 'UTF-8',
      text: 'utf-8'
    }

    body_from_email({ text: body }, charsets).should eq 'Hello.'
  end

  it 'should preserve empty lines' do
    body = "Hello.\n\nWhat's up?"

    body_from_email(text: body).should eq body
  end

  it 'preserves blockquotes' do
    body = "> Hello.\n\n>another line"

    body_from_email(text: body).should eq body
  end

  it 'handles empty body values' do
    body_from_email(text: '').should eq ''
  end

  it 'handles missing body keys' do
    body_from_email(text: nil).should eq ''
  end

  def body_from_email(raw_body, charsets = {})
    raw_body.each do |format, text|
      text.encode!(charsets[format]) if charsets[format]
    end

    params = {
      to: ['hi@example.com'],
      from: 'bye@example.com',
      charsets: charsets.to_json
    }

    raw_body.select! do |format, text|
      text.force_encoding('utf-8') if text
    end

    params.merge!(raw_body)

    email = Griddler::Email.new(params).process
    email.body
  end
end

describe Griddler::Email, 'multipart emails' do
  it 'allows raw access to text and html bodies' do
    email = email_with_params(
      html: '<b>hello there</b>',
      text: 'hello there'
    )
    email.raw_html.should eq '<b>hello there</b>'
    email.raw_text.should eq 'hello there'
  end

  it 'uses text as raw_body if both text and html are present' do
    email = email_with_params(
      html: '<b>hello there</b>',
      text: 'hello there'
    )
    email.raw_body.should eq 'hello there'
  end

  it 'uses text as raw_body' do
    email = email_with_params(
      text: 'hello there'
    )
    email.raw_body.should eq 'hello there'
  end

  it 'uses html as raw_body if text is not present' do
    email = email_with_params(
      html: '<b>hello there</b>'
    )
    email.raw_body.should eq '<b>hello there</b>'
  end

  it 'uses html as raw_body if text is empty' do
    email = email_with_params(
      html: '<b>hello there</b>',
      text: ''
    )
    email.raw_body.should eq '<b>hello there</b>'
  end

  def email_with_params(params)
    params = {
      to: ['hi@example.com'],
      from: 'bye@example.com'
    }.merge(params)

    Griddler::Email.new(params).process
  end
end

describe Griddler::Email, 'extracting email headers' do
  it 'extracts header names and values as a hash' do
    header_name = 'Arbitrary-Header'
    header_value = 'Arbitrary-Value'
    header = "#{header_name}: #{header_value}"

    headers = header_from_email(header)
    headers[header_name].should eq header_value
  end

  it 'handles no matched headers' do
    headers = header_from_email('')
    headers.should eq({})
  end

  it 'handles nil headers' do
    headers = header_from_email(nil)
    headers.should eq({})
  end

  def header_from_email(header)
    params = {
      headers: header,
      to: ['hi@example.com'],
      from: 'bye@example.com',
      text: ''
    }

    email = Griddler::Email.new(params).process
    email.headers
  end
end

describe Griddler::Email, 'extracting email addresses' do
  before do
    @hash = {
      full: 'Bob <bob@example.com>',
      email: 'bob@example.com',
      token: 'bob',
      host: 'example.com',
      name: 'Bob',
    }
    @address = @hash[:full]
  end

  it 'extracts the name' do
    email = Griddler::Email.new(to: [@address], from: @address).process
    email.to.should eq [@hash.merge(name: 'Bob')]
  end

  it 'handles normal e-mail address' do
    email = Griddler::Email.new(text: 'hi', to: [@hash[:email]], from: @address).process
    email.to.should eq [@hash.merge(full: @hash[:email], name: nil)]
    email.from.should eq @hash[:email]
  end

  it 'handles new lines' do
    email = Griddler::Email.new(text: 'hi', to: ["#{@address}\n"],
      from: "#{@address}\n").process
    email.to.should eq [@hash.merge(full: "#{@address}\n")]
    email.from.should eq @hash[:email]
  end

  it 'handles angle brackets around address' do
    email = Griddler::Email.new(text: 'hi', to: ["<#{@hash[:email]}>"],
      from: "<#{@hash[:email]}>").process
    email.to.should eq [@hash.merge(full: "<#{@hash[:email]}>", name: nil)]
    email.from.should eq @hash[:email]
  end

  it 'handles name and angle brackets around address' do
    email = Griddler::Email.new(text: 'hi', to: [@address],
      from: @address).process
    email.to.should eq [@hash]
    email.from.should eq @hash[:email]
  end

  it 'handles multiple e-mails, with priority to the bracketed' do
    email = Griddler::Email.new(
      text: 'hi',
      to: ["fake@example.com <#{@hash[:email]}>"],
      from: "fake@example.com <#{@hash[:email]}>"
    ).process
    email.to.should eq [@hash.merge(full: "fake@example.com <#{@hash[:email]}>", name: 'fake@example.com')]
    email.from.should eq @hash[:email]
  end
end

describe Griddler::Email, 'extracting email addresses from CC field' do
  before do
    @address = 'bob@example.com'
    @cc = 'Charles Conway <charles+123@example.com>'
  end

  it 'uses the cc from the adapter' do
    email = Griddler::Email.new(to: [@address], from: @address, cc: [@cc], headers: @headers).process
    email.cc.should eq ['charles+123@example.com']
  end

  it 'returns an empty array when no CC address is added' do
    email = Griddler::Email.new(to: [@address], from: @address).process
    email.cc.should be_empty
  end
end

describe Griddler::Email, 'extracting envelope' do
  before { Griddler.configuration.stub(from: :token, to: :token) }

  let!(:email) do
    Griddler::Email.new(
      from: 'there@example.com',
      envelope: { to: ['hi@example.com'], from: 'there@example.com' }
    )
  end

  it 'extracts address of To' do
    email.envelope[:to].should eq ['hi']
  end

  it 'extracts address of From' do
    email.envelope[:from].should eq 'there'
  end
end

%i[dkim spf spam_score spam_report].each do |param|
  describe Griddler::Email, "extracting #{param}" do
    it "copies #{param} into an attribute" do
      Griddler::Email.any_instance.stub(:extract_address)

      email = Griddler::Email.new(param => 'example')
      email.send(param).should eq 'example'
    end
  end
end

describe Griddler::Email, 'with custom configuration' do
  let(:params) do
    {
      to: ['Some Identifier <some-identifier@example.com>'],
      from: 'Joe User <joeuser@example.com>',
      subject: 'Re: [ThisApp] That thing',
      text: <<-EOS.strip_heredoc.strip
        lololololo hi

        Reply ABOVE THIS LINE

        hey sup
      EOS
    }
  end

  before do
    Griddler.configure
  end

  describe 'accepts and works with a string reply delimiter' do
    it 'does not split on Reply ABOVE THIS LINE' do
      Griddler.configuration.stub(reply_delimiter: 'Stuff and things')
      email = Griddler::Email.new(params).process

      email.body.should eq params[:text]
    end

    it 'splits at custom delimeter' do
      params[:text] = <<-EOS.strip_heredoc.strip
        trolololo

        -- reply above --

        wut
      EOS

      Griddler.configuration.stub(reply_delimiter: '-- reply above --')
      email = Griddler::Email.new(params).process
      email.body.should eq 'trolololo'
    end
  end

  describe 'accepts and works with an array of reply delimiters' do
    before do
      Griddler.configuration.stub(reply_delimiter: ['-- old reply above --', '-- new reply above --'])
    end

    it 'splits with old delimiter' do
      params[:text] = <<-EOS.strip_heredoc.strip
        Hey, split me with the old one!

        -- old reply above --

        wut
      EOS

      email = Griddler::Email.new(params).process
      email.body.should eq 'Hey, split me with the old one!'
    end

    it 'splits with the new delimiter' do
      params[:text] = <<-EOS.strip_heredoc.strip
        Hey, split me with the new one!

        -- new reply above --

        wut
      EOS

      email = Griddler::Email.new(params).process
      email.body.should eq 'Hey, split me with the new one!'
    end
  end

  describe 'processor_class' do
    it 'calls process on the custom processor class' do
      my_handler = double
      my_handler.should_receive(:process)
      Griddler.configuration.stub(processor_class: my_handler)

      Griddler::Email.new(params).process
    end
  end

  describe 'processor_method' do
    it 'calls the custom processor method on the processor class' do
      Griddler.configuration.stub(processor_method: :perform)
      griddler_email = Griddler::Email.new(params)

      EmailProcessor.should_receive(:perform).with(griddler_email)

      griddler_email.process
    end
  end

  context 'with multiple recipients in to field' do
    it 'includes all of the emails' do
      recipients = ['caleb@example.com', '<joel@example.com>', 'Swift <swift@example.com>']
      params = { to: recipients, from: 'ralph@example.com', text: 'hi guys' }
      Griddler.configuration.stub(to: :full)

      email = Griddler::Email.new(params).process

      email.to.should eq recipients
    end
  end
end
