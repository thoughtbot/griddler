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

    body_from_email(:html, body).should eq 'Hello.'
  end

  it 'handles invalid utf-8 bytes in html' do
    body_from_email(:html, "Hell\xC0.").should eq 'HellÀ.'
  end

  it 'handles invalid utf-8 bytes in text' do
    body_from_email(:text, "Hell\xF6.").should eq 'Hellö.'
  end

  it 'handles valid utf-8 bytes in html' do
    body_from_email(:html, "Hell\xF1.").should eq 'Hellñ.'
  end

  it 'handles valid utf-8 bytes in text' do
    body_from_email(:text, "Hell\xF2.").should eq 'Hellò.'
  end

  it 'handles valid utf-8 char in html' do
    body_from_email(:html, "Hellö.").should eq 'Hellö.'
  end

  it 'handles valid utf-8 char in text' do
    body_from_email(:text, "Hellö.").should eq 'Hellö.'
  end

  it 'does not remove invalid utf-8 bytes if charset is set' do
    charsets = {
      to: 'UTF-8',
      html: 'utf-8',
      subject: 'UTF-8',
      from: 'UTF-8',
      text: 'iso-8859-1'
    }

    body_from_email(:text, "Helló.", charsets).should eq 'Helló.'
  end

  it 'handles everything on one line' do
    body = <<-EOF
      Hello. On 01/12/13, Tristan <email@example.com> wrote: Reply ABOVE THIS LINE or visit your website to respond.
    EOF

    body_from_email(:text, body).should eq 'Hello.'
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

    body_from_email(:text, body).should eq 'Hello.'
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

    body_from_email(:text, body).should eq 'Hello.'
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

    body_from_email(:text, body).should eq 'Hello.'
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

    body_from_email(:text, body).should eq 'Hello.'
  end

  it 'handles "-----Original Message-----" format without a preceding body' do
    body = <<-EOF
      -----Original Message-----
      From: bob@example.com
      Sent: Today
      Subject: Awesome report.

      Check out this report!
    EOF

    body_from_email(:text, body).should eq ''
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

    body_from_email(:text, body).should eq 'Hello.'
  end

  it 'handles "-----Original message-----" case insensitively without a preceding body' do
    body = <<-EOF
      -----Original message-----
      From: bob@example.com
      Sent: Today
      Subject: Awesome report.

      Check out this report!
    EOF

    body_from_email(:text, body).should eq ''
  end

  it 'handles "Reply ABOVE THIS LINE" format' do
    body = <<-EOF
      Hello.

      Reply ABOVE THIS LINE

      Hey!
    EOF

    body_from_email(:text, body).should eq 'Hello.'
  end

  it 'removes > in "> Reply ABOVE THIS LINE" ' do
    body = <<-EOF
      Hello.

      > Reply ABOVE THIS LINE
    EOF

    body_from_email(:text, body).should eq 'Hello.'
  end

  it 'removes any non-content things above Reply ABOVE THIS LINE' do
    body = <<-EOF
      Hello.

      On 2010-01-01 12:00:00 Tristan wrote:

      > Reply ABOVE THIS LINE

      Hey!
    EOF

    body_from_email(:text, body).should eq 'Hello.'
  end

  it 'removes any iphone things above Reply ABOVE THIS LINE' do
    body = <<-EOF
      Hello.

      Sent from my iPhone

      > Reply ABOVE THIS LINE

      Hey!
    EOF

    body_from_email(:text, body).should eq 'Hello.'
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

    body_from_email(:text, body).should eq 'Hello.'
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

    body_from_email(:text, body).should eq 'Hello.'
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

    body_from_email(:text, body, charsets).should eq 'Hello.'
  end

  it 'should preserve empty lines' do
    body = "Hello.\n\nWhat's up?"

    body_from_email(:text, body).should eq body
  end

  it 'preserves blockquotes' do
    body = "> Hello.\n\n>another line"

    body_from_email(:text, body).should eq body
  end

  it 'handles empty body values' do
    body_from_email(:text, "").should eq ""
  end

  it 'handles missing body keys' do
    body_from_email(:text, nil).should eq ""
  end

  def body_from_email(format, text, charsets = {})
    if charsets.present?
      text = text.encode(charsets[format])
    end

    params = {
      to: ['hi@example.com'],
      from: 'bye@example.com'
    }

    if text
      params.merge!({ format => text.force_encoding('utf-8') })
    end

    if charsets.present?
      params[:charsets] = charsets.to_json
    end

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

  it 'allows access to stripped text and html bodies' do
    html_body = <<-EOF
      <blink>hello there</blink>

      <div>
      -----Original message-----
      From: bob@example.com
      Sent: Today
      Subject: Awesome report.
      </div>
    EOF

    text_body = <<-EOF
      Hello there

      -----Original message-----
      From: bob@example.com
      Sent: Today
      Subject: Awesome report.
    EOF
    email = email_with_params(html: html_body, text: text_body)
    email.body_html.should eq 'hello there'
    email.body_text.should eq 'Hello there'
  end

  it 'allows access to signature / replies block' do
    html_body = <<-EOF
      <blink>hello there</blink>

      <div>
      -----Original message-----
      From: bob@example.com
      Sent: Today
      Subject: Awesome report.
      </div>
    EOF

    email = email_with_params(html: html_body)
    email.signature.should eq <<-EOF

      From: bob@example.com
      Sent: Today
      Subject: Awesome report.
      
    EOF
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
      original_email: 'bob@example.com',
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

  it 'handles outlook-bounce formatted emails' do
    bounce_email = "bounce+b6da78.7d2ee-person=example.com@domain.com"
    email = Griddler::Email.new(
      text: 'hi',
      to: [bounce_email],
      from: "fake@example.com <#{@hash[:email]}>"
    ).process
    expected = { full: bounce_email, 
      email: "person@example.com", 
      original_email: bounce_email, 
      token: 'person', 
      name: nil, 
      host: 'example.com'
    }
    email.to.should eq [expected]
  end

  it 'handles outlook vacation responder formatted emails' do
    auto_email = "person=example.com@domain.com"
    email = Griddler::Email.new(
      text: 'hi',
      to: [auto_email],
      from: "fake@example.com <#{@hash[:email]}>"
    ).process
    expected = { full: auto_email, 
      email: "person@example.com", 
      original_email: auto_email, 
      token: 'person', 
      name: nil, 
      host: 'example.com'
    }
    email.to.should eq [expected]
  end

  context 'with secondary emails' do
    let :johnson do
      {
        full: 'Wat Johnson <wat@corporate.com>',
        email: 'wat@corporate.com',
        token: 'wat',
        host: 'corporate.com',
        original_email: 'wat@corporate.com',
        name: 'Wat Johnson'
      }
    end

    let :karl do
      {
        full: 'Karl the Fog <karlthefog@sffog.com>',
        email: 'karlthefog@sffog.com',
        token: 'karlthefog',
        host: 'sffog.com',
        original_email: 'karlthefog@sffog.com',
        name: 'Karl the Fog'
      }
    end

    it 'stores cc information' do
      email = Griddler::Email.new(
        text: 'hi',
        to: ['person@example.com'],
        from: "fake@example.com <#{@hash[:email]}>",
        cc: [johnson[:full], karl[:full]]
      ).process

      email.cc.should eq [johnson, karl]
    end

    it 'stores bcc information' do
      email = Griddler::Email.new(
        text: 'hi',
        to: ['person@example.com'],
        from: "fake@example.com <#{@hash[:email]}>",
        bcc: [johnson[:full], karl[:full]]
      ).process

      email.bcc.should eq [johnson, karl]
    end
  end

  it 'stores smtp info in stripped format' do
    email = Griddler::Email.new(text: 'hi', to: ["<#{@hash[:email]}>"], from: "<#{@hash[:email]}>", smtp: '<1234@company.com>').process
    email.smtp.should eq '1234@company.com'
  end

  it 'extracts smtp info from headers' do
    email = Griddler::Email.new(
      text: 'hi', 
      to: ["<#{@hash[:email]}>"], 
      from: "<#{@hash[:email]}>", 
      headers: {'Message-ID' => '<1234@company.com>'}
    ).process
    email.smtp.should eq '1234@company.com'
  end

  it 'stores reply_to info in stripped format' do
    email = Griddler::Email.new(text: 'hi', to: ["<#{@hash[:email]}>"], from: "<#{@hash[:email]}>", in_reply_to: '<1234@company.com>').process
    email.in_reply_to.should eq '1234@company.com'
  end

  it 'extracts reply_to info from headers' do
    email = Griddler::Email.new(
      text: 'hi', 
      to: ["<#{@hash[:email]}>"], 
      from: "<#{@hash[:email]}>", 
      headers: {'In-Reply-To' => '<1234@company.com>'}
    ).process
    email.in_reply_to.should eq '1234@company.com'
  end
end

describe Griddler::Email, 'classifying emails' do
  before do
    @hash = {
      full: 'Bob <bob@example.com>',
      email: 'bob@company.com',
      token: 'bob',
      host: 'company.com',
      original_email: 'bob=company.com@example.com',
      name: 'Bob',
    }
    @address = @hash[:original_email]
  end

  it 'inferences bounce from email format' do
    bounce_email = "bounce+b6da78.7d2ee-person=example.com@domain.com"
    email = Griddler::Email.new(
      text: 'hi',
      to: [bounce_email],
      from: "fake@example.com <#{@hash[:email]}>"
    ).process
    email.bounced?.should eq true
  end

  it "inferences auto replies from email address" do
    email = Griddler::Email.new(
      text: 'hi',
      to: [@address],
      from: 'fake@example.com'
    ).process
    email.autoreply?.should eq true
  end

  it "inferences auto replies from header info" do
    hash = {
      text: 'hi',
      to: ['fake@example.com'],
      from: 'fake@example.com'
    }
    email = Griddler::Email.new(hash.merge(headers: {'x-auto-response-suppress' => true})).process
    email.autoreply?.should eq true

    email = Griddler::Email.new(hash.merge(headers: {'x-autorespond' => true})).process
    email.autoreply?.should eq true

    email = Griddler::Email.new(hash.merge(headers: {'precedence' => 'bulk'})).process
    email.autoreply?.should eq true

    email = Griddler::Email.new(hash.merge(headers: {'auto-submitted' => 'auto-replied'})).process
    email.autoreply?.should eq true

    email = Griddler::Email.new(hash.merge(subject: "Auto: this is an automatic reply")).process
    email.autoreply?.should eq true
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
