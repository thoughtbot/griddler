# encoding: utf-8

require 'spec_helper'

def header_from_email(header)
  params = {
    headers: header,
    to:      ['hi@example.com'],
    from:    'bye@example.com',
    text:    ''
  }

  email = Griddler::Email.new(params)
  email.headers
end

def email_with_params(params)
  params = {
    to:   ['hi@example.com'],
    from: 'bye@example.com'
  }.merge(params)

  Griddler::Email.new(params)
end

def body_from_email(raw_body, charsets = {})
  raw_body.each do |format, text|
    text.encode!(charsets[format]) if charsets[format]
  end

  params = {
    to:       ['hi@example.com'],
    from:     'bye@example.com',
    charsets: charsets.to_json
  }

  raw_body.select! do |format, text|
    text.force_encoding('utf-8') if text
  end

  params.merge!(raw_body)

  email = Griddler::Email.new(params)
  email.body
end

describe Griddler::Email, 'body formatting' do
  it 'uses the html field and sanitizes it when text param missing' do
    body = <<-EOF
      <p>Hello.</p><span>-- REPLY ABOVE THIS LINE --</span><p>original message</p>
    EOF

    expect(body_from_email(html: body)).to eq 'Hello.'
  end

  it 'uses the html field and sanitizes it when text param is empty' do
    body = <<-EOF
      <p>Hello.</p><span>-- REPLY ABOVE THIS LINE --</span><p>original message</p>
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
      to:      'UTF-8',
      html:    'utf-8',
      subject: 'UTF-8',
      from:    'UTF-8',
      text:    'iso-8859-1'
    }

    expect(body_from_email({ text: 'Helló.' }, charsets)).to eq 'Helló.'
  end

  it 'handles everything on one line' do
    body = <<-EOF
      Hello. On 01/12/13, Tristan <email@example.com> wrote: -- REPLY ABOVE THIS LINE -- or visit your website to respond.
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

  it 'handles "[date] [soandso] <email@example.com>:" format' do
    body = <<-EOF
      Hello.

      2016-03-03 11:35 GMT+01:00 Bob <email@example.com>:
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Tristan
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'handles "On [date] [soandso]<\nverylongemailaddress@longdomain.com>\nwrote:" format' do
    body = <<-EOF.strip_heredoc
      Hello.

      On Jan 1, 2020 at 12:00 PM, Peter <
      peterhasasuperlongemailthatforcesanewline@longdomain.com>
      wrote:
      > My name is Peter
      >
      > Sorry, but my email address is very long
      >
      > and adds extra newlines to the delimiter
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

  it 'handles french format: "Le [date], [soandso] <email@example.com> a écrit :"' do
    body = <<-EOF.strip_heredoc
      Hello.

      Le 11 mars 2016, at 18:00, Tristan <email@example.com> a écrit :
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Tristan
      >
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'handles LONG french format: "Le [date], [soandso] <email@example.com> a écrit :"' do
    body = <<-EOF.strip_heredoc
      Hello.

      Le 11 mars 2016, at 18:00, Tristan With A Really Really Long Name <
      tristanhasasuperlongemailthatforcesanewline@candidates.welcomekit.co> a
      écrit :
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Tristan
      >
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'handles spanish format: "El [date], [soandso] <email@example.com> escribió:"' do
    body = <<-EOF.strip_heredoc
      Hello.

      El 11/03/2016 11:34, Pedro Pérez <email@example.com> escribió:
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Pedro
      >
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'handles LONG spanish format: "El [date], [soandso] <email@example.com> escribió:"' do
    body = <<-EOF.strip_heredoc
      Hello.

      El 11/03/2016 11:34, Pedro Pérez <
      pedrohasasuperlongemailthatforcesanewline@example.com> escribió:
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Pedro
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

  it 'handles "*From:* email@email.com" format' do
    body = <<-EOF
      Hello.

      *From:* bob@example.com
      *Sent:* Today
      *Subject:* Awesome report.

      Check out this report!
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'handles "De : Firstname <email@email.com>" format (french Outlook)' do
    body = <<-EOF
      Hello.

      ________________________________
      De : Bob <bob@example.com>
      Envoyé : mercredi 15 juin 2016 07:24
      À : robert@example.com
      Objet : Awesome report.

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

  it 'handles "-- REPLY ABOVE THIS LINE --" format' do
    body = <<-EOF
      Hello.

      -- REPLY ABOVE THIS LINE --

      Hey!
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'removes > in "> -- REPLY ABOVE THIS LINE --" ' do
    body = <<-EOF
      Hello.

      > -- REPLY ABOVE THIS LINE --
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'removes any non-content things above -- REPLY ABOVE THIS LINE --' do
    body = <<-EOF
      Hello.

      On 2010-01-01 12:00:00 Tristan wrote:

      > -- REPLY ABOVE THIS LINE --

      Hey!
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'removes any iphone things above -- REPLY ABOVE THIS LINE --' do
    body = <<-EOF
      Hello.

      Sent from my iPhone

      > -- REPLY ABOVE THIS LINE --

      Hey!
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'should remove any signature above -- REPLY ABOVE THIS LINE --' do
    body = <<-EOF
      Hello.

      --
      Mr. Smith
      CEO, company
      t: 6174821300

      > -- REPLY ABOVE THIS LINE --

      > Hey!
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'should trim signature with non-breaking space after hyphens' do
    body = <<-EOF
      Hello.

      --\xC2\xA0
      Mr. Smith
      CEO, company
      t: 6174821300
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'should remove any signature without space above -- REPLY ABOVE THIS LINE --' do
    body = <<-EOF
      Hello.

      --
      Mr. Smith
      CEO, company
      t: 6174821300

      > -- REPLY ABOVE THIS LINE --

      > Hey!
    EOF

    expect(body_from_email(text: body)).to eq 'Hello.'
  end

  it 'allows paragraphs to begin with "On"' do
    body = <<-EOF
      On the counter.

      On Tue, Sep 30, 2014 at 9:13 PM Tristan <email@example.com> wrote:
      > Where's that report?
      >
      > Thanks, Tristen
    EOF

    expect(body_from_email(text: body)).to eq 'On the counter.'
  end

  it 'properly handles a json charsets' do
    body = <<-EOF
      Hello.

      --
      Mr. Smith
      CEO, company
      t: 6174821300

      > -- REPLY ABOVE THIS LINE --

      > Hey!
    EOF

    charsets = {
      to:      'UTF-8',
      html:    'utf-8',
      subject: 'UTF-8',
      from:    'UTF-8',
      text:    'utf-8'
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

  context 'prefer_html: true' do
    before(:each) {
      Griddler.configure do |config|
        config.prefer_html = true
      end
      allow(Griddler::EmailParser).to receive_messages(email_client: :outlook_web)
    }

    it 'split html part as body' do
      expect(body_from_email(html: "<div id='divtagdefaultwrapper'>Hellö.</div>kajkjkj")).to eq '<div id="divtagdefaultwrapper">Hellö.</div>'
    end

    it 'raw_body is html' do
      expect(email_with_params(
               html: "<div id='divtagdefaultwrapper'>Hellö.</div>apple_mail",
               text: 'Hellö.apple_mail').raw_body
      ).to eq "<div id='divtagdefaultwrapper'>Hellö.</div>apple_mail"
    end
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
end

describe Griddler::Email, 'extracting email headers' do
  it 'extracts header names and values as a hash' do
    header_name  = 'Arbitrary-Header'
    header_value = 'Arbitrary-Value'
    header       = "#{header_name}: #{header_value}"

    headers = header_from_email(header)
    expect(headers[header_name]).to eq header_value
  end

  it 'handles a hash being submitted' do
    header  = {
      "X-Mailer"     => "Airmail (271)",
      "Mime-Version" => "1.0"
    }
    headers = header_from_email(header)
    expect(headers["X-Mailer"]).to eq("Airmail (271)")
  end

  it 'cleans invalid UTF-8 bytes from a hash when it is submitted' do
    header_name  = 'Arbitrary-Header'
    header_value = "invalid utf-8 bytes are \xc0\xc1\xf5\xfa\xfe\xff."
    header       = { header_name => header_value }
    headers      = header_from_email(header)

    expect(headers[header_name]).to eq "invalid utf-8 bytes are ÀÁõúþÿ."
  end

  it 'deeply cleans invalid UTF-8 bytes from a hash when it is submitted' do
    header_name  = 'Arbitrary-Header'
    header_value = "invalid utf-8 bytes are \xc0\xc1\xf5\xfa\xfe\xff."
    header       = { header_name => { "a" => [header_value] } }
    headers      = header_from_email(header)

    expect(headers[header_name]).to eq({ "a" => ["invalid utf-8 bytes are ÀÁõúþÿ."] })
  end

  it 'deeply cleans invalid UTF-8 bytes from an array when it is submitted' do
    header_name  = 'Arbitrary-Header'
    header_value = "invalid utf-8 bytes are \xc0\xc1\xf5\xfa\xfe\xff."
    header       = [{ header_name => { "a" => [header_value] } }]
    headers      = header_from_email(header)

    expect(headers[0][header_name]).to eq({ "a" => ["invalid utf-8 bytes are ÀÁõúþÿ."] })
  end

  it 'handles no matched headers' do
    headers = header_from_email('')
    expect(headers).to eq({})
  end

  it 'handles nil headers' do
    headers = header_from_email(nil)
    expect(headers).to eq({})
  end

  it 'handles invalid utf-8 bytes in headers' do
    header_name  = 'Arbitrary-Header'
    header_value = "invalid utf-8 bytes are \xc0\xc1\xf5\xfa\xfe\xff."
    header       = "#{header_name}: #{header_value}"

    headers = header_from_email(header)
    expect(headers[header_name]).to eq "invalid utf-8 bytes are ÀÁõúþÿ."
  end

  it 'handles valid utf-8 bytes in headers' do
    header_name  = 'Arbitrary-Header'
    header_value = "valid utf-8 bytes are ÀÁõÿ."
    header       = "#{header_name}: #{header_value}"

    headers = header_from_email(header)
    expect(headers[header_name]).to eq "valid utf-8 bytes are ÀÁõÿ."
  end
end

describe Griddler::Email, 'extracting email addresses' do
  before do
    @address_components     = {
      full:  'Bob <bob@example.com>',
      email: 'bob@example.com',
      token: 'bob',
      host:  'example.com',
      name:  'Bob',
    }
    @full_address           = @address_components[:full]
    @bcc_address_components = {
      full:  'Johny <johny@example.com>',
      email: 'johny@example.com',
      token: 'johny',
      host:  'example.com',
      name:  'Johny',
    }
    @full_bcc_address       = @bcc_address_components[:full]
  end

  it 'extracts the name' do
    email = Griddler::Email.new(
      to:   [@full_address],
      from: @full_address,
    )
    expect(email.to).to eq [@address_components.merge(name: 'Bob')]
  end

  it 'handles normal e-mail address' do
    email    = Griddler::Email.new(
      text: 'hi',
      to:   [@address_components[:email]],
      from: @full_address
    )
    expected = @address_components.merge(
      full: @address_components[:email],
      name: nil,
    )
    expect(email.to).to eq [expected]
    expect(email.from).to eq @address_components

  end

  it 'returns the BCC email' do
    email = Griddler::Email.new(
      text: 'hi',
      to:   [@address_components[:email]],
      from: @full_address,
      bcc:  [@full_bcc_address],
    )
    expect(email.bcc).to eq [@bcc_address_components]
  end

  it 'handles new lines' do
    email    = Griddler::Email.new(text: 'hi', to: ["#{@full_address}\n"],
                                   from: "#{@full_address}\n")
    expected = @address_components.merge(full: "#{@full_address}\n")
    expect(email.to).to eq [expected]
    expect(email.from).to eq expected
  end

  it 'handles angle brackets around address' do
    email    = Griddler::Email.new(
      text: 'hi',
      to:   ["<#{@address_components[:email]}>"],
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
      to:   [@full_address],
      from: @full_address
    )
    expect(email.to).to eq [@address_components]
    expect(email.from).to eq @address_components
  end

  it 'handles multiple e-mails, with priority to the bracketed' do
    email    = Griddler::Email.new(
      text: 'hi',
      to:   ["fake@example.com <#{@address_components[:email]}>"],
      from: "fake@example.com <#{@address_components[:email]}>"
    )
    expected = @address_components.merge(
      full: "fake@example.com <#{@address_components[:email]}>",
      name: 'fake@example.com'
    )

    expect(email.to).to eq [expected]
    expect(email.from).to eq expected
  end

  it 'handles invalid UTF-8 characters' do
    email    = Griddler::Email.new(
      text: 'hi',
      to:   ["\xc0\xc1\xf5\xfa\xfe\xff #{@full_address}"],
      from: "\xc0\xc1\xf5\xfa\xfe\xff #{@full_address}")
    expected = @address_components.merge(
      full: "ÀÁõúþÿ Bob <bob@example.com>",
      name: "ÀÁõúþÿ Bob"
    )
    expect(email.to).to eq [expected]
    expect(email.from).to eq expected
  end

  it 'ignores blank email addresses' do
    expected = @address_components
    email    = Griddler::Email.new(to: ['', @full_address])
    expect(email.to).to eq [expected]
  end

  it 'ignores emails without @' do
    expected = @address_components
    email    = Griddler::Email.new(to: ['johndoe', @full_address])
    expect(email.to).to eq [expected]
  end

  it 'returns the original recipient' do
    expected = @address_components
    email = Griddler::Email.new(original_recipient: @full_address)
    expect(email.original_recipient).to eq expected
  end

  it 'returns the reply to' do
    expected = @address_components
    email = Griddler::Email.new(reply_to: @full_address)
    expect(email.reply_to).to eq expected
  end
end

describe Griddler::Email, 'extracting email subject' do
  before do
    @address = 'bob@example.com'
    @subject = 'A very interesting email'
  end

  it 'handles normal characters' do
    email = Griddler::Email.new(
      to:      [@address],
      from:    @address,
      subject: @subject,
    )
    expect(email.subject).to eq @subject
  end

  it 'handles invalid UTF-8 characters' do
    email    = Griddler::Email.new(
      to:      [@address],
      from:    @address,
      subject: "\xc0\xc1\xf5\xfa\xfe\xff #{@subject}",
    )
    expected = "ÀÁõúþÿ #{@subject}"
    expect(email.subject).to eq expected
  end
end

describe Griddler::Email, 'extracting email addresses from CC field' do
  before do
    @address = 'bob@example.com'
    @cc      = 'Charles Conway <charles+123@example.com>'
  end

  it 'uses the cc from the adapter' do
    email = Griddler::Email.new(to: [@address], from: @address, cc: [@cc], headers: @headers)
    expect(email.cc).to eq [{
                              token: 'charles+123',
                              host:  'example.com',
                              email: 'charles+123@example.com',
                              full:  'Charles Conway <charles+123@example.com>',
                              name:  'Charles Conway',
                            }]
  end

  it 'returns an empty array when no CC address is added' do
    email = Griddler::Email.new(to: [@address], from: @address)
    expect(email.cc).to be_empty
  end

  it 'removes empty cc addresses' do
    email = Griddler::Email.new(to: [@address], from: @address, cc: ['', @cc])
    expect(email.cc.size).to eq(1)
  end
end

describe Griddler::Email, 'with custom configuration' do
  before do
    Griddler.configure
  end

  let(:params) do
    {
      to:      ['Some Identifier <some-identifier@example.com>'],
      from:    'Joe User <joeuser@example.com>',
      subject: 'Re: [ThisApp] That thing',
      text:    <<-EOS.strip_heredoc.strip
        lololololo hi

        -- REPLY ABOVE THIS LINE --

        hey sup
      EOS
    }
  end

  describe 'accepts and works with a string reply delimiter' do
    it 'does not split on -- REPLY ABOVE THIS LINE --' do
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

  describe 'parsing with gmail reply header with newlines and long email' do
    it 'only keeps the message above the reply header' do
      params[:text] = <<-EOS.strip_heredoc
This is the real text\r\n\r\nOn Tue, Jun 14, 2016 at 10:25 AM Someone <\r\nverylongemailaddress@longdomain.com>\r\nwrote:\r\n\r\n> -- REPLY ABOVE THIS LINE --\r\n>\r\n> The Old message!\r\n>\r\n> Another line! *\r\n>\n
      EOS
      email = Griddler::Email.new(params)
      expect(email.body).to eq 'This is the real text'
    end
  end

  context 'with multiple recipients in to field' do
    it 'includes all of the emails' do
      recipients = ['caleb@example.com', '<joel@example.com>', 'Swift <swift@example.com>']
      params     = { to: recipients, from: 'ralph@example.com', text: 'hi guys' }

      email = Griddler::Email.new(params)

      expect(email.to.map { |to| to[:full] }).to eq recipients
    end
  end

  context 'with an empty recipient in to field' do
    it 'includes all of the emails' do
      recipients =
        ['caleb@example.com',
         '',
         '<joel@example.com>',
         'Swift <swift@example.com>']
      params     = { to: recipients, from: 'ralph@example.com', text: 'hi guys' }

      email = Griddler::Email.new(params)

      expect(email.to.map { |to| to[:full] }).to eq recipients.reject(&:empty?)
    end
  end
end

describe Griddler::Email, 'extracting vendor specific' do
  it 'extracts a hash of vendor specific data' do
    meeting_info = {
      name: 'Weekly Stand Up',
      date: '01/01/2015',
      time: '8:00am'
    }
    params = {
      vendor_specific: {
        body_calendar: meeting_info
      }
    }
    email = Griddler::Email.new(params)

    expect(email.vendor_specific).to eq({ body_calendar: meeting_info })
  end

  it 'defaults to an empty hash' do
    email = Griddler::Email.new({})

    expect(email.vendor_specific).to eq({})
  end
end

describe Griddler::Email, 'methods' do
  describe '#to_h' do
    it 'returns an indifferent access hash of Griddler::Email attributes' do
      params = {
        to: ['Some Identifier <some-identifier@example.com>'],
        from: 'Joe User <joeuser@example.com>',
        subject: 'Re: [ThisApp] That thing',
        spam_report: {
          score: 10,
        },
        text: <<-EOS.strip_heredoc.strip
          lololololo hi

          -- REPLY ABOVE THIS LINE --

          hey sup
        EOS
      }
      email = Griddler::Email.new(params)

      hash = email.to_h

      expect(hash).to eq(
        to: email.to,
        from: email.from,
        cc: email.cc,
        bcc: email.bcc,
        subject: email.subject,
        body: email.body,
        raw_body: email.raw_body,
        raw_text: email.raw_text,
        raw_html: email.raw_html,
        headers: email.headers,
        raw_headers: email.raw_headers,
        attachments: email.attachments,
        vendor_specific: {},
        spam_report: email.spam_report,
        spam_score: email.spam_score,
      )
    end
  end
end

describe Griddler::Email, 'extracting spam score' do
  let(:params) do
    {
      to: ['Some Identifier <some-identifier@example.com>'],
      from: 'Joe User <joeuser@example.com>',
      subject: 'Re: [ThisApp] That thing',
      text: 'lololololo hi',
    }
  end

  describe 'spam_score' do
    subject { Griddler::Email.new(params) }

    context 'With no spam report' do
      it { expect(subject.spam_score).to be nil }
    end

    context 'With a spam report but no score' do
      before do
        params[:spam_report] = { other_key: 'value' }
      end
      it { expect(subject.spam_score).to be nil }
    end

    context 'With a score symbol key' do
      before do
        params[:spam_report] = { score: 42 }
      end
      it { expect(subject.spam_score).to eq 42 }
    end
  end
end
