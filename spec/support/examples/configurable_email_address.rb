shared_examples_for 'configurable email address' do |address|
  describe '#{address} = :hash' do
    it 'returns a hash for email.#{address}' do
      email = new_email_with_config(address => :hash)

      returned_address = email.send(address)
      if address == :to
        returned_address = returned_address.first
      end

      returned_address.should eq expected_hash
    end

    def expected_hash
      {
        token: 'caleb',
        host: 'example.com',
        email: 'caleb@example.com',
        full: 'Caleb Thompson <caleb@example.com>',
      }
    end
  end

  describe '#{address} = :full' do
    it 'returns the full #{address} for email.#{address}' do
      email = new_email_with_config(address => :full)

      email.send(address).should eq params[address]
    end
  end

  describe '#{address} = :email' do
    it 'returns just the email address for email.#{address}' do
      email = new_email_with_config(address => :email)

      if address == :to
        email.send(address).should eq ['caleb@example.com']
      else
        email.send(address).should eq 'caleb@example.com'
      end
    end
  end

  describe '#{address} = :token' do
    it 'returns the local portion of the email for email.#{address}' do
      email = new_email_with_config(address => :token)

      if address == :to
        email.send(address).should eq ['caleb']
      else
        email.send(address).should eq 'caleb'
      end
    end
  end

  def params
    {
      to: ['Caleb Thompson <caleb@example.com>'],
      from: 'Caleb Thompson <caleb@example.com>',
      subject: 'Remember that thing?',
      text: 'You know, the thing.',
    }
  end

  def new_email_with_config(config)
    Griddler.configuration.stub(config)
    Griddler::Email.new(params).process
  end
end
