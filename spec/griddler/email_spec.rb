# encoding: utf-8

require 'spec_helper'

describe Griddler::Email, 'body formatting' do

  it 'uses the html field and sanitizes it when text param missing' do
    body = <<-EOF
      <p>Hello.</p><span>Reply ABOVE THIS LINE</span><p>original message</p>
    EOF

    expect(body_from_email(html: body)).to eq 'Hello.'
  end

  it 'uses the html field and sanitizes it when text param is empty' do
    body = <<-EOF
      <p>Hello.</p><span>Reply ABOVE THIS LINE</span><p>original message</p>
    EOF

    expect(body_from_email(html: body, text: '')).to eq 'Hello.'
  end

  it 'handles invalid utf-8 bytes in html' do
    expect(body_from_email(html: "Hell\xC0.")).to eq 'HellÀ.'
  end

  it 'handles invalid utf-8 bytes in text' do
    expect(body_from_email(text: "Hell\xF6.")).to eq 'Hellö.'
  end

  it 'handles valid utf-8 bytes in html' do
    expect(body_from_email(html: "Hell\xF1.")).to eq 'Hellñ.'
  end

  it 'handles valid utf-8 bytes in text' do
    expect(body_from_email(text: "Hell\xF2.")).to eq 'Hellò.'
  end

  it 'handles valid utf-8 char in html' do
    expect(body_from_email(html: 'Hellö.')).to eq 'Hellö.'
  end

  it 'handles valid utf-8 char in text' do
    expect(body_from_email(text: 'Hellö.')).to eq 'Hellö.'
  end

  it 'does not remove invalid utf-8 bytes if charset is set' do
    charsets = {
      to: 'UTF-8',
      html: 'utf-8',
      subject: 'UTF-8',
      from: 'UTF-8',
      text: 'iso-8859-1'
    }

    expect(body_from_email({ text: 'Helló.' }, charsets)).to eq 'Helló.'
  end

  it 'handles everything on one line' do
    body = <<-EOF
      Hello. On 01/12/13, Tristan <email@example.com> wrote: Reply ABOVE THIS LINE or visit your website to respond.
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
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

    expect(body_from_email(text: body)).to eq 'Hello.'
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

    expect(body_from_email(text: body)).to eq 'Hello.'
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

    expect(body_from_email(text: body)).to eq 'Hello.'
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

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'handles "From: email@email.com" format' do
    body = <<-EOF
      Hello.

      From: bob@example.com
      Sent: Today
      Subject: Awesome report.

      Check out this report!
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
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

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'handles "-----Original Message-----" format without a preceding body' do
    body = <<-EOF
      -----Original Message-----
      From: bob@example.com
      Sent: Today
      Subject: Awesome report.

      Check out this report!
    EOF

    expect(body_from_email(text: body)).to eq ''
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

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'handles "-----Original message-----" case insensitively without a preceding body' do
    body = <<-EOF
      -----Original message-----
      From: bob@example.com
      Sent: Today
      Subject: Awesome report.

      Check out this report!
    EOF

    expect(body_from_email(text: body)).to eq ''
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

    expect(body_from_email(text: body)).to eq ''
  end

  it 'handles "Reply ABOVE THIS LINE" format' do
    body = <<-EOF
      Hello.

      Reply ABOVE THIS LINE

      Hey!
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'removes > in "> Reply ABOVE THIS LINE" ' do
    body = <<-EOF
      Hello.

      > Reply ABOVE THIS LINE
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'removes any non-content things above Reply ABOVE THIS LINE' do
    body = <<-EOF
      Hello.

      On 2010-01-01 12:00:00 Tristan wrote:

      > Reply ABOVE THIS LINE

      Hey!
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'removes any iphone things above Reply ABOVE THIS LINE' do
    body = <<-EOF
      Hello.

      Sent from my iPhone

      > Reply ABOVE THIS LINE

      Hey!
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
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

    expect(body_from_email(text: body)).to eq 'Hello.'
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

    expect(body_from_email(text: body)).to eq 'Hello.'
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

    expect(body_from_email({ text: body }, charsets)).to eq 'Hello.'
  end

  it 'should preserve empty lines' do
    body = "Hello.\n\nWhat's up?"

    expect(body_from_email(text: body)).to eq body
  end

  it 'preserves blockquotes' do
    body = "> Hello.\n\n>another line"

    expect(body_from_email(text: body)).to eq body
  end

  it 'handles empty body values' do
    expect(body_from_email(text: '')).to eq ''
  end

  it 'handles missing body keys' do
    expect(body_from_email(text: nil)).to eq ''
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

    email = Griddler::Email.new(params)
    email.body
  end
end

describe Griddler::Email, 'multipart emails' do
  it 'allows raw access to text and html bodies' do
    email = email_with_params(
      html: '<b>hello there</b>',
      text: 'hello there'
    )
    expect(email.raw_html).to eq '<b>hello there</b>'
    expect(email.raw_text).to eq 'hello there'
  end

  it 'uses text as raw_body if both text and html are present' do
    email = email_with_params(
      html: '<b>hello there</b>',
      text: 'hello there'
    )
    expect(email.raw_body).to eq 'hello there'
  end

  it 'uses text as raw_body' do
    email = email_with_params(
      text: 'hello there'
    )
    expect(email.raw_body).to eq 'hello there'
  end

  it 'uses html as raw_body if text is not present' do
    email = email_with_params(
      html: '<b>hello there</b>'
    )
    expect(email.raw_body).to eq '<b>hello there</b>'
  end

  it 'uses html as raw_body if text is empty' do
    email = email_with_params(
      html: '<b>hello there</b>',
      text: ''
    )
    expect(email.raw_body).to eq '<b>hello there</b>'
  end

  def email_with_params(params)
    params = {
      to: ['hi@example.com'],
      from: 'bye@example.com'
    }.merge(params)

    Griddler::Email.new(params)
  end
end

describe Griddler::Email, 'extracting email headers' do
  it 'extracts header names and values as a hash' do
    header_name = 'Arbitrary-Header'
    header_value = 'Arbitrary-Value'
    header = "#{header_name}: #{header_value}"

    headers = header_from_email(header)
    expect(headers[header_name]).to eq header_value
  end

  it 'handles no matched headers' do
    headers = header_from_email('')
    expect(headers).to eq({})
  end

  it 'handles nil headers' do
    headers = header_from_email(nil)
    expect(headers).to eq({})
  end

  def header_from_email(header)
    params = {
      headers: header,
      to: ['hi@example.com'],
      from: 'bye@example.com',
      text: ''
    }

    email = Griddler::Email.new(params)
    email.headers
  end
end

describe Griddler::Email, 'extracting email addresses' do
  before do
    @address_components = {
      full: 'Bob <bob@example.com>',
      email: 'bob@example.com',
      token: 'bob',
      host: 'example.com',
      name: 'Bob',
    }
    @full_address= @address_components[:full]
  end

  it 'extracts the name' do
    email = Griddler::Email.new(
      to: [@full_address],
      from: @full_address,
    )
    expect(email.to).to eq [@address_components.merge(name: 'Bob')]
  end

  it 'handles normal e-mail address' do
    email = Griddler::Email.new(
      text: 'hi',
      to: [@address_components[:email]],
      from: @full_address,
    )
    expected = @address_components.merge(
      full: @address_components[:email],
      name: nil,
    )
    expect(email.to).to eq [expected]
    expect(email.from).to eq @address_components
  end

  it 'handles new lines' do
    email = Griddler::Email.new(text: 'hi', to: ["#{@full_address}\n"],
      from: "#{@full_address}\n")
    expected = @address_components.merge(full: "#{@full_address}\n")
    expect(email.to).to eq [expected]
    expect(email.from).to eq expected
  end

  it 'handles angle brackets around address' do
    email = Griddler::Email.new(
      text: 'hi',
      to: ["<#{@address_components[:email]}>"],
      from: "<#{@address_components[:email]}>"
    )
    expected = @address_components.merge(
      full: "<#{@address_components[:email]}>",
      name: nil)
    expect(email.to).to eq [expected]
    expect(email.from).to eq expected
  end

  it 'handles name and angle brackets around address' do
    email = Griddler::Email.new(
      text: 'hi',
      to: [@full_address],
      from: @full_address
    )
    expect(email.to).to eq [@address_components]
    expect(email.from).to eq @address_components
  end

  it 'handles multiple e-mails, with priority to the bracketed' do
    email = Griddler::Email.new(
      text: 'hi',
      to: ["fake@example.com <#{@address_components[:email]}>"],
      from: "fake@example.com <#{@address_components[:email]}>"
    )
    expected = @address_components.merge(
      full: "fake@example.com <#{@address_components[:email]}>",
      name: 'fake@example.com'
    )

    expect(email.to).to eq [expected]
    expect(email.from).to eq expected
  end
end

describe Griddler::Email, 'extracting email addresses from CC field' do
  before do
    @address = 'bob@example.com'
    @cc = 'Charles Conway <charles+123@example.com>'
  end

  it 'uses the cc from the adapter' do
    email = Griddler::Email.new(to: [@address], from: @address, cc: [@cc], headers: @headers)
    expect(email.cc).to eq [{
      token: 'charles+123',
      host: 'example.com',
      email: 'charles+123@example.com',
      full: 'Charles Conway <charles+123@example.com>',
      name: 'Charles Conway',
    }]
  end

  it 'returns an empty array when no CC address is added' do
    email = Griddler::Email.new(to: [@address], from: @address)
    expect(email.cc).to be_empty
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
      allow(Griddler.configuration).to receive_messages(reply_delimiter: 'Stuff and things')
      email = Griddler::Email.new(params)

      expect(email.body).to eq params[:text]
    end

    it 'splits at custom delimeter' do
      params[:text] = <<-EOS.strip_heredoc.strip
        trolololo

        -- reply above --

        wut
      EOS

      allow(Griddler.configuration).to receive_messages(reply_delimiter: '-- reply above --')
      email = Griddler::Email.new(params)
      expect(email.body).to eq 'trolololo'
    end
  end

  describe 'accepts and works with an array of reply delimiters' do
    before do
      allow(Griddler.configuration).to receive_messages(reply_delimiter: ['-- old reply above --', '-- new reply above --'])
    end

    it 'splits with old delimiter' do
      params[:text] = <<-EOS.strip_heredoc.strip
        Hey, split me with the old one!

        -- old reply above --

        wut
      EOS

      email = Griddler::Email.new(params)
      expect(email.body).to eq 'Hey, split me with the old one!'
    end

    it 'splits with the new delimiter' do
      params[:text] = <<-EOS.strip_heredoc.strip
        Hey, split me with the new one!

        -- new reply above --

        wut
      EOS

      email = Griddler::Email.new(params)
      expect(email.body).to eq 'Hey, split me with the new one!'
    end
  end

  describe 'parsing with gmail reply header with newlines' do
    it 'only keeps the message above the reply header' do
      params[:text]= <<-EOS.strip_heredoc
This is the real text\r\n\r\n\r\nOn Fri, Mar 21, 2014 at 3:11 PM, Someone <\r\nsomeone@example.com> wrote:\r\n\r\n>  -- REPLY ABOVE THIS LINE --\r\n>\r\n> The Old message!\r\n>\r\n> Another line! *\r\n>\n
      EOS
      email = Griddler::Email.new(params)
      expect(email.body).to eq 'This is the real text'
    end
  end

  context 'with multiple recipients in to field' do
    it 'includes all of the emails' do
      recipients = ['caleb@example.com', '<joel@example.com>', 'Swift <swift@example.com>']
      params = { to: recipients, from: 'ralph@example.com', text: 'hi guys' }

      email = Griddler::Email.new(params)

      expect(email.to.map { |to| to[:full] }).to eq recipients
    end
  end
end
