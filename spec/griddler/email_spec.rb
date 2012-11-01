require 'spec_helper'

describe Griddler::Email do
  it 'should handle "On [date] [soandso] wrote:" format' do
    body = <<-EOF
      Hello.

      On 2010-01-01 12:00:00 Tristan wrote:
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Tristan
    EOF

    email = Griddler::Email.new(text: body, to: 'hi@e.com', from: 'bye@e.com')
    email.body.should == 'Hello.'
  end

  it 'should handle "On [date] [soandso] <email@example.com> wrote:" format' do
    body = <<-EOF
      Hello.

      On 2010-01-01 12:00:00 Tristan <email@example.com> wrote:
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Tristan
    EOF

    email = Griddler::Email.new(text: body, to: 'hi@e.com', from: 'bye@e.com')
    email.body.should == 'Hello.'
  end

  it 'should handle "On [date] [soandso]\n<email@example.com> wrote:" format' do
    body = <<-EOF
      Hello.

      On 2010-01-01 12:00:00 Tristan\n <email@example.com> wrote:
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Tristan
    EOF

    email = Griddler::Email.new(text: body, to: 'hi@e.com', from: 'bye@e.com')
    email.body.should == 'Hello.'
  end

  it 'should handle "-----Original Message-----" format' do
    body = <<-EOF
      Hello.

      -----Original Message-----
      From: bob@example.com
      Sent: Today
      Subject: Awesome report.

      Check out this report!
    EOF

    email = Griddler::Email.new(text: body, to: 'hi@e.com', from: 'bye@e.com')
    email.body.should == 'Hello.'
  end

  it 'should handle "Reply ABOVE THIS LINE" format' do
    body = <<-EOF
      Hello.

      Reply ABOVE THIS LINE

      Hey!
    EOF

    email = Griddler::Email.new(text: body, to: 'hi@e.com', from: 'bye@e.com')
    email.body.should == 'Hello.'
  end

  it 'should remove any noncontent things above Reply ABOVE THIS LINE' do
    body = <<-EOF
      Hello.

      On 2010-01-01 12:00:00 Tristan wrote:

      > Reply ABOVE THIS LINE

      Hey!
    EOF

    email = Griddler::Email.new(text: body, to: 'hi@e.com', from: 'bye@e.com')
    email.body.should == 'Hello.'
  end

  it 'should remove any iphone things above Reply ABOVE THIS LINE' do
    body = <<-EOF
      Hello.

      Sent from my iPhone

      > Reply ABOVE THIS LINE

      Hey!
    EOF

    email = Griddler::Email.new(text: body, to: 'hi@e.com', from: 'bye@e.com')
    email.body.should == 'Hello.'
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

    email = Griddler::Email.new(text: body, to: 'hi@e.com', from: 'bye@e.com')
    email.body.should == 'Hello.'
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

    email = Griddler::Email.new(text: body, to: 'hi@e.com', from: 'bye@e.com')
    email.body.should == 'Hello.'
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
      to: 'hi@e.com',
      from: 'bye@e.com',
      charsets: charsets
    )

    email.body.should == 'Hello.'
  end

  it 'should preserve empty lines' do
    body = "Hello.\n\nWhat's up?"

    email = Griddler::Email.new(text: body, to: 'hi@e.com', from: 'bye@e.com')
    email.body.should == body
  end

  describe 'extracting email address' do
    before do
      @address = 'bob@example.com'
      @token = 'bob'
    end

    it 'should handle normal e-mail address' do
      email = Griddler::Email.new(to: @address, from: @address)
      email.to.should == @token
      email.from.should == @address
    end

    it 'should handle new lines' do
      email = Griddler::Email.new(to: "#{@address}\n", from: "#{@address}\n")
      email.to.should == @token
      email.from.should == @address
    end

    it 'should handle angle brackets around address' do
      email = Griddler::Email.new(to: "<#{@address}>", from: "<#{@address}>")
      email.to.should == @token
      email.from.should == @address
    end

    it 'should handle name and angle brackets around address' do
      email = Griddler::Email.new(to: "Bob <#{@address}>", from: "Bob <#{@address}>")
      email.to.should == @token
      email.from.should == @address
    end

    it 'should handle multiple e-mails, with priority to the bracketed' do
      email = Griddler::Email.new(to: "fake@example.com <#{@address}>", from: "fake@example.com <#{@address}>")
      email.to.should == @token
      email.from.should == @address
    end
  end

  describe 'with custom configuration' do
    let(:params) do
      {
        to: 'Some Identifier <some-identifier@thisapp.com>',
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

    describe 'raw_body = true' do
      it 'should not modify the body' do
        Griddler.configuration.stub(raw_body: true)
        email = Griddler::Email.new(params)

        email.body.should == params[:text]
      end
    end

    describe 'reply_delimiter = "Stuff and things"' do
      it 'should not split on Reply ABOVE THIS LINE' do
        Griddler.configuration.stub(reply_delimiter: 'Stuff and things')
        email = Griddler::Email.new(params)

        email.body.should == params[:text]
      end

      it 'splits at custom delimeter' do
        params[:text] = <<-EOS.strip_heredoc.strip
          trolololo

          -- reply above --

          wut
        EOS

        Griddler.configuration.stub(reply_delimiter: '-- reply above --')
        email = Griddler::Email.new(params)
        email.body.should == 'trolololo'
      end
    end

    describe 'to = :hash' do
      it 'returns a hash for email.to' do
        Griddler.configuration.stub(to: :hash)
        email = Griddler::Email.new(params)

        email.to.should be_an_instance_of(Hash)
        email.to.should == {
          token: 'some-identifier',
          host: 'thisapp.com',
          email: 'some-identifier@thisapp.com',
          full: 'Some Identifier <some-identifier@thisapp.com>',
        }
      end
    end

    describe 'to = :full' do
      it 'returns the full to for email.to' do
        Griddler.configuration.stub(to: :full)
        email = Griddler::Email.new(params)

        email.to.should == params[:to]
      end
    end

    describe 'to = :email' do
      it 'returns just the email address for email.to' do
        Griddler.configuration.stub(to: :email)
        email = Griddler::Email.new(params)

        email.to.should == 'some-identifier@thisapp.com'
      end
    end

    describe 'to = :token' do
      it 'returns the local portion of the email for email.to' do
        Griddler.configuration.stub(to: :token)
        email = Griddler::Email.new(params)

        email.to.should == 'some-identifier'
      end
    end

    describe 'handler_class' do
      before do
        class MyHandler; end
      end

      it 'calls process on the custom handler class' do
        MyHandler.stub(:process).and_return('success')
        Griddler.configuration.stub(:handler_class).and_return(MyHandler)
        MyHandler.should_receive(:process)

        email = Griddler::Email.new(params)
      end
    end

    describe 'handler_method' do
      it 'calls the custom handler method on implied EmailProcessor' do
        EmailProcessor.stub(:foo_bar).and_return('success')
        Griddler.configuration.stub(:handler_method).and_return(:foo_bar)
        EmailProcessor.should_receive(:foo_bar)

        email = Griddler::Email.new(params)
      end
    end
  end
end
