require 'spec_helper'

describe Griddler::Email, 'body formatting' do
  it 'uses the html field and sanitizes it when text param missing' do
    body = <<-EOF
      <p>Hello.</p><span>Reply ABOVE THIS LINE</span><p>original message</p>
    EOF

    body_from_email(:html, body).should eq 'Hello.'
  end

  it 'handles invalid utf-8 bytes in html' do
    body_from_email(:html, "Hello.\xF5").should eq 'Hello.'
  end

  it 'handles invalid utf-8 bytes in text' do
    body_from_email(:text, "Hello.\xF5").should eq 'Hello.'
  end

  it 'raises error when no body is provided' do
    expect { Griddler::Email.new(to: 'hi@example.com', from: 'bye@example.com').process }.
      to raise_error(Griddler::Errors::EmailBodyNotFound)
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

  it 'handles "Reply ABOVE THIS LINE" format' do
    body = <<-EOF
      Hello.

      Reply ABOVE THIS LINE

      Hey!
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
    }.to_json

    email = Griddler::Email.new(
      text: body,
      to: 'hi@example.com',
      from: 'bye@example.com',
      charsets: charsets
    ).process

    email.body.should eq 'Hello.'
  end

  it 'should preserve empty lines' do
    body = "Hello.\n\nWhat's up?"

    body_from_email(:text, body).should eq body
  end

  def body_from_email(format, text)
    email = Griddler::Email.new(
      format => text.force_encoding('UTF-8'),
      to: 'hi@example.com',
      from: 'bye@example.com'
    ).process
    email.body
  end
end

describe Griddler::Email, 'extracting email addresses' do
  before do
    @address = 'bob@example.com'
    @token = 'bob'
  end

  it 'handles normal e-mail address' do
    email = Griddler::Email.new(text: 'hi', to: @address, from: @address).process
    email.to.should eq @token
    email.from.should eq @address
  end

  it 'handles new lines' do
    email = Griddler::Email.new(text: 'hi', to: "#{@address}\n",
      from: "#{@address}\n").process
    email.to.should eq @token
    email.from.should eq @address
  end

  it 'handles angle brackets around address' do
    email = Griddler::Email.new(text: 'hi', to: "<#{@address}>",
      from: "<#{@address}>").process
    email.to.should eq @token
    email.from.should eq @address
  end

  it 'handles name and angle brackets around address' do
    email = Griddler::Email.new(text: 'hi', to: "Bob <#{@address}>",
      from: "Bob <#{@address}>").process
    email.to.should eq @token
    email.from.should eq @address
  end

  it 'handles multiple e-mails, with priority to the bracketed' do
    email = Griddler::Email.new(
      text: 'hi',
      to: "fake@example.com <#{@address}>",
      from: "fake@example.com <#{@address}>"
    ).process
    email.to.should eq @token
    email.from.should eq @address
  end
end

describe Griddler::Email, 'with custom configuration' do
  let(:params) do
    {
      to: 'Some Identifier <some-identifier@example.com>',
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

  describe 'reply_delimiter = "Stuff and things"' do
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

  describe 'to = :hash' do
    it 'returns a hash for email.to' do
      Griddler.configuration.stub(to: :hash)
      email = Griddler::Email.new(params).process
      expected_hash = {
        token: 'some-identifier',
        host: 'example.com',
        email: 'some-identifier@example.com',
        full: 'Some Identifier <some-identifier@example.com>',
      }

      email.to.should be_an_instance_of(Hash)
      email.to.should eq expected_hash
    end
  end

  describe 'to = :full' do
    it 'returns the full to for email.to' do
      Griddler.configuration.stub(to: :full)
      email = Griddler::Email.new(params).process

      email.to.should eq params[:to]
    end
  end

  describe 'to = :email' do
    it 'returns just the email address for email.to' do
      Griddler.configuration.stub(to: :email)
      email = Griddler::Email.new(params).process

      email.to.should eq 'some-identifier@example.com'
    end
  end

  describe 'to = :token' do
    it 'returns the local portion of the email for email.to' do
      Griddler.configuration.stub(to: :token)
      email = Griddler::Email.new(params).process

      email.to.should eq 'some-identifier'
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
end

describe Griddler::Email, '#attachments' do
  it 'assigns 2 attachments' do
    params = {
      text: 'hi',
      to: 'hi@example.com',
      from: 'there@example.com',
      attachments: '2',
      attachment1: upload_1,
      attachment2: upload_2,
     'attachment-info' => <<-eojson
        {
          'attachment2': {
            'filename': 'photo2.jpg',
            'name': 'photo2.jpg',
            'type': 'image/jpeg'
          },
          'attachment1': {
            'filename': 'photo1.jpg',
            'name': 'photo1.jpg',
            'type': 'image/jpeg'
          }
        }
      eojson
    }
    email = Griddler::Email.new(params)

    email.attachments.should eq [upload_1, upload_2]
  end

  it 'has no attachments' do
    params = {
      text: 'hi',
      to: 'hi@example.com',
      from: 'there@example.com',
      attachments: '0'
    }
    email = Griddler::Email.new(params)

    email.attachments.should be_empty
  end

  def cwd
    File.expand_path File.dirname(__FILE__)
  end

  def upload_1
    @upload_1 ||= ActionDispatch::Http::UploadedFile.new({
      filename: 'photo1.jpg',
      type: 'image/jpeg',
      tempfile: File.new("#{cwd}/../../spec/fixtures/photo1.jpg")
    })
  end

  def upload_2
    @upload_2 ||= ActionDispatch::Http::UploadedFile.new({
      filename: 'photo2.jpg',
      type: 'image/jpeg',
      tempfile: File.new("#{cwd}/../../spec/fixtures/photo2.jpg")
    })
  end
end
